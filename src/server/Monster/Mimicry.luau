--!strict
-- The Engineer's trick: it remembers the sounds players made (a door, footsteps, a voice, a walkie
-- crackle) and now and then plays one back somewhere near itself, where a player can hear it, then
-- stands still and listens for whoever comes to check. Players can never fully trust what they hear.
--
-- Mimicked sounds are only sounds: they're not noise events, so the monster doesn't react to its
-- own lure and tape recorders don't pick them up. The tell is that nothing is there: no door moves.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local MapContract = require(script.Parent.Parent.MapContract)

local MIMIC = Config.MIMIC

-- Only sounds a person makes are worth copying.
local COPYABLE: { [string]: boolean } =
	{ footsteps = true, door = true, voice = true, walkie = true, landing = true }

local Mimicry = {}

local memory: { string } = {} -- kinds of sound heard, newest last
local nextAt = 0
local generation = 0
local rng = Random.new()

function Mimicry.reset(now: number)
	generation += 1 -- cancel delayed mimic footsteps from the previous round
	memory = {}
	nextAt = now + rng:NextNumber(MIMIC.MIN_INTERVAL, MIMIC.MAX_INTERVAL)
end

function Mimicry.remember(kind: string, fromPlayer: boolean)
	if not fromPlayer or not COPYABLE[kind] then
		return
	end
	table.insert(memory, kind)
	if #memory > MIMIC.MEMORY then
		table.remove(memory, 1)
	end
end

local function play(kind: string, spot: Vector3)
	local myGeneration = generation
	local soundId, speed = Sounds.forKind(kind)
	if kind == "footsteps" then
		-- A few steps walking away from the spot, like someone moving.
		local angle = rng:NextNumber(0, math.pi * 2)
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		for i = 0, 5 do
			task.delay(i * 0.42, function()
				if generation ~= myGeneration then
					return
				end
				Sounds.playAt(
					soundId,
					spot + direction * i * 1.6 - Vector3.new(0, 2.5, 0),
					0.7,
					60,
					speed
				)
			end)
		end
	elseif kind == "walkie" then
		for i = 0, 2 do
			task.delay(i * 0.6, function()
				if generation ~= myGeneration then
					return
				end
				Sounds.playAt(soundId, spot, 0.35, 45, speed)
			end)
		end
	else
		Sounds.playAt(soundId, spot, 0.8, 70, speed)
	end
end

-- The kinds of sound it has heard players make lately (newest last).
function Mimicry.heard(): { string }
	return table.clone(memory)
end

-- Plays one sound of `kind` at `spot` (used by the second shock to throw the team's sounds back).
function Mimicry.playAt(kind: string, spot: Vector3)
	play(kind, spot)
end

-- If it's time and there's a good spot, plays a remembered sound and returns where; otherwise nil.
function Mimicry.tryPerform(
	now: number,
	monster: Vector3,
	areas: { MapContract.Area },
	players: { Vector3 }
): Vector3?
	if not Config.FEATURES.MIMICRY or now < nextAt or #memory == 0 or #players == 0 then
		return nil
	end
	local here = MapContract.areaAt(areas, monster)
	local candidates: { Vector3 } = {}
	local fallback: { Vector3 } = {}
	for _, area in areas do
		for _, point in area.points do
			local d = (point - monster).Magnitude
			if
				d >= MIMIC.MIN_DISTANCE
				and d <= MIMIC.MAX_DISTANCE
				and math.abs(point.Y - monster.Y) < 8
			then
				local heard = false
				for _, position in players do
					if (position - point).Magnitude <= MIMIC.PLAYER_RANGE then
						heard = true
						break
					end
				end
				if heard then
					-- Best from another room: the lure seems to come from somewhere it isn't.
					table.insert(if area ~= here then candidates else fallback, point)
				end
			end
		end
	end
	local pool = if #candidates > 0 then candidates else fallback
	if #pool == 0 then
		nextAt = now + 8 -- nobody in earshot: try again soon
		return nil
	end
	local spot = pool[rng:NextInteger(1, #pool)]
	play(memory[rng:NextInteger(1, #memory)], spot)
	nextAt = now + rng:NextNumber(MIMIC.MIN_INTERVAL, MIMIC.MAX_INTERVAL)
	return spot
end

return Mimicry
