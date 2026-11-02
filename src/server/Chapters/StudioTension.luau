--!strict
-- Chapter 1 opening atmosphere: small, diegetic cues for the first ten minutes.
-- No cutscenes, screen flashes, artificial player noise, or new monster commands.
-- Scheduled only while people explore; the core chapter and director own the danger.
-- Sounds.luau currently contains placeholders: replace the IDs there after auditioning.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Sounds = require(Shared:WaitForChild("Sounds"))
local MapContract = require(script.Parent.Parent.MapContract)
local RoundState = require(script.Parent.Parent.RoundState)
local Kit = require(script.Parent.Kit)

type Scene = {
	room: string,
	earliest: number,
	sourceArea: string,
	sound: string,
	volume: number,
	range: number,
	speed: number,
}

local Tension = {}

-- Source location is deliberately in a nearby *different* space where possible.
-- These are environmental noises only, not counterfeit pickups or voiced instructions.
local SCENES: { Scene } = {
	{
		room = "Reception", earliest = 25,
		sourceArea = "EntryHall", sound = Sounds.DOOR,
		volume = 0.22, range = 46, speed = 0.68,
	},
	{
		room = "ControlA", earliest = 45,
		sourceArea = "MasteringSuite", sound = Sounds.TAPE_THREAD,
		volume = 0.29, range = 46, speed = 0.7,
	},
	{
		room = "TapeArchive", earliest = 75,
		sourceArea = "MasteringSuite", sound = Sounds.TAPE_SLIP,
		volume = 0.24, range = 42, speed = 0.64,
	},
	{
		room = "SoundLock", earliest = 110,
		sourceArea = "ViewingGallery", sound = Sounds.WALKIE_CRACKLE,
		volume = 0.2, range = 48, speed = 0.53,
	},
	{
		room = "LiveHall", earliest = 155,
		sourceArea = "IsolationVocal", sound = Sounds.HUM,
		volume = 0.18, range = 45, speed = 0.72,
	},
	{
		room = "ServiceHall", earliest = 190,
		sourceArea = "MachineRoom", sound = Sounds.BUZZ,
		volume = 0.2, range = 55, speed = 0.55,
	},
}

local MAX_CUES_PER_ROUND = 4
local MIN_CUE_GAP = 45
local OPENING_END = 10 * 60

local function occupiedRooms(areas: { MapContract.Area }): { [string]: boolean }
	local found: { [string]: boolean } = {}
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if not char or char:GetAttribute("InRound") ~= true then
			continue
		end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			continue
		end
		local area = MapContract.areaAt(areas, root.Position)
		if area then
			found[area.name] = true
		end
	end
	return found
end

function Tension.start(myRound: number)
	local map = Kit.layout()
	local sources: { [string]: Vector3 } = {}
	for _, area in map.areas do
		sources[area.name] = area.center
	end

	-- No work if this is a fallback/alternate layout with different area names.
	-- We never create extra parts, prompts, particles or forever-running instances.
	task.spawn(function()
		local played: { [string]: boolean } = {}
		local count = 0
		local lastAt = -MIN_CUE_GAP
		while Kit.roundId() == myRound and Kit.elapsed() < OPENING_END do
			task.wait(3)
			if Kit.roundId() ~= myRound or RoundState.get("Phase") ~= "Playing" then
				continue
			end
			if RoundState.get("LastCall") == true or Kit.shocksFired() > 0 then
				return
			end
			if count >= MAX_CUES_PER_ROUND then
				return
			end
			local elapsed = Kit.elapsed()
			if elapsed - lastAt < MIN_CUE_GAP then
				continue
			end
			local present = occupiedRooms(map.areas)
			-- Evaluate in time order: a visiting player triggers at most one quiet cue.
			for _, scene in SCENES do
				if not played[scene.room]
					and present[scene.room] == true
					and elapsed >= scene.earliest then
					local at = sources[scene.sourceArea]
					if at then
						Sounds.playAt(scene.sound, at, scene.volume, scene.range, scene.speed)
						played[scene.room] = true
						count += 1
						lastAt = elapsed
					end
					break
				end
			end
		end
	end)
end

return Tension
