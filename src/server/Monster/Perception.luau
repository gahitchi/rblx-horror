--!strict
-- What the monster hears and how sure it is. Every noise that reaches its ears raises its awareness
-- (0 to 100) and becomes a stimulus: where it thinks the sound came from, and how clearly it heard
-- it. Faint or muffled sounds give only a rough position, so it searches near where you were, not
-- exactly on you. Awareness drains back over time when things are quiet.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local NoiseService = require(script.Parent.Parent.NoiseService)

local M = Config.MONSTER

export type Stimulus = {
	kind: string,
	source: Player?,
	exact: Vector3, -- where the sound really was (for logs and debug only)
	estimate: Vector3, -- where the monster thinks it was
	clarity: number, -- 0 (at the edge of hearing) to 1 (right next to it)
	distance: number,
	loud: boolean, -- an objective or alarm: impossible to ignore
	time: number,
}

-- How much awareness each kind of sound adds when heard clearly. Footsteps and voice scale with
-- how loud they were instead.
local KIND_GAIN: { [string]: number } = {
	landing = 25,
	door = 30,
	flashlight = 8,
	generator = 100,
	fuse = 70,
	alarm = 100,
}
local LOUD_KINDS: { [string]: boolean } = { generator = true, fuse = true, alarm = true }

local Perception = {}

local awareness = 0
local rng = Random.new()

function Perception.reset()
	awareness = 0
end

function Perception.awareness(): number
	return awareness
end

function Perception.set(value: number)
	awareness = math.clamp(value, 0, 100)
end

function Perception.decay(dt: number)
	awareness = math.max(0, awareness - M.AWARENESS_DECAY * dt)
end

function Perception.isLoud(kind: string): boolean
	return LOUD_KINDS[kind] == true
end

-- Hears `noise` with ears at `ear`, hearing range scaled by `hearing` (its own movement masks quiet
-- sounds). Returns nil when the sound doesn't reach it.
function Perception.hear(noise: NoiseService.Noise, ear: Vector3, hearing: number): Stimulus?
	if noise.kind == "monster" then
		return nil -- its own doors and steps
	end
	local distance = (noise.position - ear).Magnitude
	if distance > noise.loudness * hearing then
		return nil -- too far even in open air: skip the wall checks
	end
	local reach = NoiseService.effectiveLoudness(noise, ear) * hearing
	if reach <= 0 or distance > reach then
		return nil
	end

	local clarity = math.clamp(1 - distance / reach, 0, 1)
	local errorRadius = M.MAX_LOCATION_ERROR * (1 - clarity) ^ 1.5
	local angle = rng:NextNumber(0, math.pi * 2)
	local offset = Vector3.new(math.cos(angle), 0, math.sin(angle))
		* errorRadius
		* math.sqrt(rng:NextNumber())

	local base = KIND_GAIN[noise.kind]
	if not base then
		base = noise.loudness * 0.75 -- footsteps (walk ~12, sprint ~28), voice (up to ~45)
	end
	awareness = math.min(100, awareness + base * (0.4 + 0.6 * clarity))

	return {
		kind = noise.kind,
		source = noise.source,
		exact = noise.position,
		estimate = noise.position + offset,
		clarity = clarity,
		distance = distance,
		loud = LOUD_KINDS[noise.kind] == true,
		time = os.clock(),
	}
end

return Perception
