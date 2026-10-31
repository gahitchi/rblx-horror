--!strict
-- Experience, levels and coins, kept between sessions in a DataStore. Rewards come from what a
-- player does in a round (objectives, decoys, escaping), not only from surviving.
-- In Studio without "Enable Studio Access to API Services" it still works, for the session only.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

-- Track rewards follow the current level: a level lost to a revive relocks its rewards until it's
-- reached again. `peak` is kept for the record. `reviveTokens` are Robux revives not used yet.
type Data = {
	xp: number,
	coins: number,
	rounds: number,
	escapes: number,
	peak: number,
	skin: string,
	reviveTokens: number,
}
export type Gain = { xp: number, coins: number, lines: { string } }

local ProgressService = {}

local store: DataStore? = nil
local data: { [Player]: Data } = {}
local loadedOk: { [Player]: boolean } = {} -- never overwrite saved data we failed to read
local gains: { [Player]: Gain } = {}

-- Total XP at which `level` starts (level 1 starts at 0; each level needs 100 more than the last).
function ProgressService.levelStart(level: number): number
	return 50 * (level - 1) * level
end

-- Level 1 at 0 XP; each level needs 100 XP more than the one before.
function ProgressService.levelFor(xp: number): number
	local level, need, total = 1, 100, 0
	while xp >= total + need do
		total += need
		level += 1
		need += 100
	end
	return level
end

-- The XP bonus from the track rewards up to `level`.
local function boostFor(level: number): number
	local boost = 0
	for _, reward in Config.TRACK do
		if reward.kind == "boost" and level >= reward.level then
			boost += reward.value :: number
		end
	end
	return boost
end

local function skinUnlocked(d: Data, skin: string): boolean
	if skin == "warm" then
		return true
	end
	for _, reward in Config.TRACK do
		if
			reward.kind == "skin"
			and reward.id == skin
			and ProgressService.levelFor(d.xp) >= reward.level
		then
			return true
		end
	end
	return false
end

local function publish(player: Player)
	local d = data[player]
	if d then
		player:SetAttribute("XP", d.xp)
		player:SetAttribute("Level", ProgressService.levelFor(d.xp))
		player:SetAttribute("PeakLevel", d.peak)
		player:SetAttribute("Coins", d.coins)
		player:SetAttribute("XPBoost", boostFor(ProgressService.levelFor(d.xp)))
		player:SetAttribute("FlashlightSkin", d.skin)
		player:SetAttribute("ReviveTokens", d.reviveTokens)
	end
end

local function load(player: Player)
	local d: Data =
		{ xp = 0, coins = 0, rounds = 0, escapes = 0, peak = 1, skin = "warm", reviveTokens = 0 }
	local ok = false
	if store then
		for _ = 1, 3 do
			local success, result = pcall(function()
				return (store :: DataStore):GetAsync("player_" .. player.UserId)
			end)
			if success then
				ok = true
				if type(result) == "table" then
					d.xp = tonumber(result.xp) or 0
					d.coins = tonumber(result.coins) or 0
					d.rounds = tonumber(result.rounds) or 0
					d.escapes = tonumber(result.escapes) or 0
					d.reviveTokens = tonumber(result.reviveTokens) or 0
					d.peak = math.max(tonumber(result.peak) or 1, ProgressService.levelFor(d.xp))
					local skin = result.skin
					d.skin = if type(skin) == "string" and skinUnlocked(d, skin)
						then skin
						else "warm"
				end
				break
			end
			task.wait(1)
		end
	end
	if player.Parent ~= Players then
		return
	end
	data[player] = d
	loadedOk[player] = ok
	player:SetAttribute("ProgressSaved", ok)
	publish(player)
end

local function save(player: Player)
	local d = data[player]
	if not store or not d or not loadedOk[player] then
		return
	end
	local snapshot = table.clone(d)
	pcall(function()
		(store :: DataStore):SetAsync("player_" .. player.UserId, snapshot)
	end)
end

-- Gives `xp` (plus the track's XP boost, and a fifth of the base in coins) for something done this round.
function ProgressService.award(player: Player, reason: string, baseXp: number)
	local d = data[player]
	if not d then
		return
	end
	local before = ProgressService.levelFor(d.xp)
	local xp = math.floor(baseXp * (1 + boostFor(before)) + 0.5)
	local coins = math.floor(baseXp / 5)
	d.xp += xp
	local level = ProgressService.levelFor(d.xp)
	if level > before then
		-- Announce what the new level unlocks (again, if it was lost to a revive).
		for reached = before + 1, level do
			for _, reward in Config.TRACK do
				if reward.level == reached then
					Remotes.Notify:FireClient(
						player,
						string.format("Level %d! Unlocked: %s", reached, reward.name)
					)
				end
			end
		end
		d.peak = math.max(d.peak, level)
	end
	d.coins += coins
	local gain = gains[player]
	if not gain then
		gain = { xp = 0, coins = 0, lines = {} }
		gains[player] = gain
	end
	gain.xp += xp
	gain.coins += coins
	table.insert(gain.lines, string.format("%s +%d", reason, xp))
	publish(player)
end

-- A revive's price: back to the start of the previous level. False if already at level 1.
function ProgressService.loseLevel(player: Player): boolean
	local d = data[player]
	if not d then
		return false
	end
	local level = ProgressService.levelFor(d.xp)
	if level < 2 then
		return false
	end
	d.xp = ProgressService.levelStart(level - 1)
	if not skinUnlocked(d, d.skin) then
		d.skin = "warm" -- that look's level is gone for now
	end
	publish(player)
	return true
end

-- Puts XP back to an earlier value (refunding a revive nobody came for).
function ProgressService.restoreXp(player: Player, xp: number)
	local d = data[player]
	if d then
		d.xp = xp
		publish(player)
	end
end

function ProgressService.xpOf(player: Player): number
	local d = data[player]
	return if d then d.xp else 0
end

-- Robux revives: stored first, so a purchase is never lost even if the round ended meanwhile.
function ProgressService.addReviveToken(player: Player): boolean
	local d = data[player]
	if not d then
		return false
	end
	d.reviveTokens += 1
	publish(player)
	return true
end

function ProgressService.useReviveToken(player: Player): boolean
	local d = data[player]
	if not d or d.reviveTokens < 1 then
		return false
	end
	d.reviveTokens -= 1
	publish(player)
	return true
end

-- Saves now (used right after a purchase). Returns whether it was written.
function ProgressService.saveNow(player: Player): boolean
	local d = data[player]
	if not store or not d or not loadedOk[player] then
		return false
	end
	local snapshot = table.clone(d)
	local ok = pcall(function()
		(store :: DataStore):SetAsync("player_" .. player.UserId, snapshot)
	end)
	return ok
end

local function onSetSkin(player: Player, skin: unknown)
	local d = data[player]
	if d and type(skin) == "string" and Config.FLASHLIGHT_SKINS[skin] and skinUnlocked(d, skin) then
		d.skin = skin
		publish(player)
	end
end

function ProgressService.startRound()
	gains = {}
end

-- What `player` earned this round, and the round counted in their totals.
function ProgressService.finishRound(player: Player, escaped: boolean): Gain
	local d = data[player]
	if d then
		d.rounds += 1
		if escaped then
			d.escapes += 1
		end
	end
	return gains[player] or { xp = 0, coins = 0, lines = {} }
end

function ProgressService.saveAll()
	for player in data do
		task.spawn(save, player)
	end
end

function ProgressService.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("Progress_v1")
	end)
	if ok then
		store = result
	else
		warn("[Progress] DataStore unavailable; progress lasts this session only")
	end
	Remotes.SetSkin.OnServerEvent:Connect(onSetSkin)
	Players.PlayerAdded:Connect(load)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		save(player)
		data[player] = nil
		loadedOk[player] = nil
		gains[player] = nil
	end)
	game:BindToClose(function()
		for player in data do
			save(player)
		end
	end)
end

return ProgressService
