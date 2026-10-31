--!strict
-- Experience, levels and coins, kept between sessions in a DataStore. Rewards come from what a
-- player does in a round (objectives, decoys, escaping), not only from surviving.
-- In Studio without "Enable Studio Access to API Services" it still works, for the session only.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

type Data = { xp: number, coins: number, rounds: number, escapes: number }
export type Gain = { xp: number, coins: number, lines: { string } }

local ProgressService = {}

local store: DataStore? = nil
local data: { [Player]: Data } = {}
local loadedOk: { [Player]: boolean } = {} -- never overwrite saved data we failed to read
local gains: { [Player]: Gain } = {}

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

local function publish(player: Player)
	local d = data[player]
	if d then
		player:SetAttribute("XP", d.xp)
		player:SetAttribute("Level", ProgressService.levelFor(d.xp))
		player:SetAttribute("Coins", d.coins)
	end
end

local function load(player: Player)
	local d: Data = { xp = 0, coins = 0, rounds = 0, escapes = 0 }
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

-- Gives `xp` (and a fifth of it in coins) for something done this round.
function ProgressService.award(player: Player, reason: string, xp: number)
	local d = data[player]
	if not d then
		return
	end
	local coins = math.floor(xp / 5)
	d.xp += xp
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
