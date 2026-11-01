--!strict
-- The building's lamps and fog. Nothing in Wrenmouth has had power since 1987: the lamps only wake
-- near the sound (the story's third rule), so the state follows the chapter:
--   dead   pitch dark, flashlights only (the round's start)
--   woken  dim, warm and flickering (after the first shock)
--   red    emergency red (after the second shock, to the end of the round)
-- Blackouts switch everything off for a moment and back to the current state. The fog thickens with
-- the round's soft pressure, and a shock can push a thick fog in for a while.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local MapContract = require(script.Parent.MapContract)
local RoundState = require(script.Parent.RoundState)

export type State = "dead" | "woken" | "red"

local WOKEN_COLOR = Color3.fromRGB(255, 196, 140)
local RED_COLOR = Color3.fromRGB(255, 50, 40)
local WOKEN_BRIGHTNESS = 0.55
local RED_BRIGHTNESS = 0.9

local LightingService = {}

local lamps: { MapContract.Lamp } = {}
local ownsLighting = false
local state: State = "dead"
local blackoutUntil = 0
local generation = 0 -- bumps on every change, so old flicker loops and fog timers stop
local pressureFog = Config.PACING.FOG_END_CALM
local shockFogUntil = 0
local rng = Random.new()

-- How each lamp part looked as built, so "dead" can put it back.
local builtLook: { [BasePart]: { material: Enum.Material, color: Color3 } } = {}

local function apply(on: boolean, color: Color3, brightness: number)
	for _, lamp in lamps do
		for _, light in lamp.lights do
			light.Enabled = on
			light.Color = color
			light.Brightness = brightness
		end
		local p = lamp.part
		if p then
			local look = builtLook[p]
			if not look then
				look = { material = p.Material, color = p.Color }
				builtLook[p] = look
			end
			p.Material = if on then Enum.Material.Neon else look.material
			p.Color = if on then color:Lerp(Color3.new(0, 0, 0), 0.3) else look.color
		end
	end
end

local function show()
	if os.clock() < blackoutUntil or state == "dead" then
		apply(false, WOKEN_COLOR, 0)
	elseif state == "woken" then
		apply(true, WOKEN_COLOR, WOKEN_BRIGHTNESS)
	else
		apply(true, RED_COLOR, RED_BRIGHTNESS)
	end
end

local function applyFog()
	if ownsLighting then
		return
	end
	local fogEnd = pressureFog
	if os.clock() < shockFogUntil then
		fogEnd = math.min(fogEnd, Config.SHOCK.FOG_END)
	end
	Lighting.FogEnd = fogEnd
	Lighting.FogStart = math.min(20, fogEnd * 0.4)
end

-- One lamp at a time dips out for a moment: the building's power is unreliable.
local function startFlicker(myGeneration: number)
	task.spawn(function()
		while generation == myGeneration and state ~= "dead" do
			task.wait(rng:NextNumber(1.5, 5))
			if generation ~= myGeneration or #lamps == 0 or os.clock() < blackoutUntil then
				continue
			end
			local lamp = lamps[rng:NextInteger(1, #lamps)]
			for _, light in lamp.lights do
				light.Enabled = false
			end
			task.wait(rng:NextNumber(0.05, 0.35))
			if generation == myGeneration and os.clock() >= blackoutUntil then
				for _, light in lamp.lights do
					light.Enabled = true
				end
			end
		end
	end)
end

function LightingService.set(newState: State)
	state = newState
	generation += 1
	RoundState.set("Lights", newState)
	show()
	if newState ~= "dead" then
		startFlicker(generation)
	end
end

function LightingService.state(): State
	return state
end

-- Everything off for `seconds`, then back to the current state.
function LightingService.blackout(seconds: number)
	blackoutUntil = os.clock() + seconds
	show()
	local myGeneration = generation
	task.delay(seconds + 0.05, function()
		if generation == myGeneration then
			show()
		end
	end)
end

-- Soft pressure, 0 (calm) to 1 (full): the fog closes in.
function LightingService.setPressure(pressure: number)
	local P = Config.PACING
	pressureFog = P.FOG_END_CALM + (P.FOG_END_FULL - P.FOG_END_CALM) * math.clamp(pressure, 0, 1)
	applyFog()
end

-- A thick fog seeps in for `seconds` (the second shock).
function LightingService.fogIn(seconds: number)
	shockFogUntil = os.clock() + seconds
	applyFog()
	task.delay(seconds + 0.1, applyFog)
end

function LightingService.reset()
	blackoutUntil = 0
	shockFogUntil = 0
	pressureFog = Config.PACING.FOG_END_CALM
	LightingService.set("dead")
	applyFog()
end

function LightingService.init(layout: MapContract.Layout)
	lamps = layout.lamps
	ownsLighting = layout.map:GetAttribute("OwnsLighting") == true
	LightingService.reset()
end

return LightingService
