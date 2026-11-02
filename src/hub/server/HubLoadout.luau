--!strict
-- Cosmetic loadout in the safe hub, using the same Progress_v1 record as the match.
-- No real-money gear; level rewards remain authoritative and server-validated.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local HubLoadout = {}
local saving: { [Player]: boolean } = {}
local dataStore: DataStore?

local function levelFor(xp: number): number
	local current, need, total = 1, 100, 0
	while xp >= total + need do
		total += need
		current += 1
		need += 100
	end
	return current
end

local function unlocked(level: number, key: string): boolean
	if key == "warm" then
		return true
	end
	for _, reward in Config.TRACK do
		if reward.kind == "skin" and reward.id == key and level >= reward.level then
			return true
		end
	end
	return false
end

local function notify(player: Player, text: string)
	if player.Parent == Players then
		Remotes.Notify:FireClient(player, text)
	end
end

local function onSetSkin(player: Player, requested: unknown)
	if type(requested) ~= "string" or Config.FLASHLIGHT_SKINS[requested] == nil then
		return
	end
	if saving[player] then
		return
	end
	local level = player:GetAttribute("Level")
	if type(level) ~= "number" or not unlocked(level, requested) then
		notify(player, "This flashlight look unlocks on the free reward track.")
		return
	end
	if player:GetAttribute("ProgressSaved") ~= true or not dataStore then
		notify(player, "Your saved progress is unavailable. Try again after reconnecting.")
		return
	end
	saving[player] = true
	local accepted = false
	local ok, message = pcall(function()
		(dataStore :: DataStore):UpdateAsync("player_" .. player.UserId, function(previous: any)
			if type(previous) ~= "table" then
				return nil
			end
			-- Recheck the *saved* level in case an old client attribute is stale.
			if not unlocked(levelFor(math.max(0, tonumber(previous.xp) or 0)), requested) then
				return nil
			end
			local updated = table.clone(previous)
			updated.skin = requested
			accepted = true
			return updated
		end)
	end)
	saving[player] = nil
	if player.Parent ~= Players then
		return
	end
	if ok and accepted then
		player:SetAttribute("FlashlightSkin", requested)
		notify(player, "Equipped " .. Config.FLASHLIGHT_SKINS[requested].name .. " flashlight.")
	else
		if not ok then
			warn("[Hub loadout] couldn't save skin: " .. tostring(message))
		end
		notify(player, "Could not save that loadout. Please try again.")
	end
end

function HubLoadout.init()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore("Progress_v1")
	end)
	if ok then
		dataStore = store
	end
	Remotes.SetSkin.OnServerEvent:Connect(onSetSkin)
	Players.PlayerRemoving:Connect(function(player)
		saving[player] = nil
	end)
end

return HubLoadout
