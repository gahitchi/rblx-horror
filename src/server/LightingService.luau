--!strict
-- Chapter 1 practical lighting controller.
-- "dead" is PARTIAL POWER: readable routes and a few working practicals,
-- "woken" restores full warm work lighting, and "red" keeps emergency routes
-- pools while navy fault/emergency fittings pulse red. No full-screen red wash.
-- Also handles manual/greybox maps without the authored studio fixture tags.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapContract = require(script.Parent.MapContract)
local RoundState = require(script.Parent.RoundState)

export type State = "dead" | "woken" | "red"

local LightingService = {}

local STYLE_WARM = Color3.fromRGB(247, 194, 133)
local STYLE_SOFT = Color3.fromRGB(215, 192, 156)
local STYLE_NEUTRAL = Color3.fromRGB(193, 204, 200)
local STYLE_COOL = Color3.fromRGB(150, 188, 211)
local STYLE_RED = Color3.fromRGB(232, 78, 61)
local STYLE_PILOT = Color3.fromRGB(187, 178, 141)
local STYLE_DEAD = Color3.fromRGB(153, 164, 157)

type Look = {
	material: Enum.Material,
	color: Color3,
}
local lamps: { MapContract.Lamp } = {}
local original: { [BasePart]: Look } = {}
local ownsLighting = false
local authored = false
local state: State = "dead"
local blackoutUntil = 0
local generation = 0
local pressureFog = Config.PACING.FOG_END_CALM
local shockFogUntil = 0
local rng = Random.new()
local correction: ColorCorrectionEffect? = nil
local bloom: BloomEffect? = nil
local consoleIndicators: { BasePart } = {}

local WARM_ROOMS: { [string]: boolean } = {
	ControlA = true,
	ControlB = true,
	MasteringSuite = true,
	Reception = true,
	BreakRoom = true,
}
local MUSIC_ROOMS: { [string]: boolean } = {
	LiveHall = true,
	IsolationWest = true,
	IsolationVocal = true,
	IsolationDrums = true,
	TapeArchive = true,
}
local COLD_ROOMS: { [string]: boolean } = {
	ServicePass = true,
	ServiceHall = true,
	MachineRoom = true,
	LoadingBay = true,
	JanitorCloset = true,
	Stairwell = true,
	StaffWC = true,
	PublicWC = true,
}

local function colorFor(room: string, role: string): Color3
	if role == "Fault" then
		return STYLE_RED
	end
	if state == "dead" and role == "Fault" then
		return STYLE_DEAD
	end
	if role == "Emergency" then
		return if state == "red" then STYLE_RED else STYLE_NEUTRAL
	end
	if role == "Guide" then
		return if state == "red" then STYLE_PILOT else STYLE_SOFT
	end
	if COLD_ROOMS[room] then
		return STYLE_COOL
	end
	if MUSIC_ROOMS[room] then
		return STYLE_SOFT
	end
	if WARM_ROOMS[room] then
		return STYLE_WARM
	end
	return STYLE_NEUTRAL
end

-- "dead" remains the story's pre-shock phase, but electrical circuits in
-- an abandoned building need not all be dead. A readable route is paramount.
-- Scaling is local per fixture; the original base brightness is not mutated.
local function intensityFor(role: string, base: number): number
	if state == "dead" then
		if role == "Route" then return base * 0.95
		elseif role == "Ceiling" then return base * 0.58
		elseif role == "Task" then return base * 0.60
		elseif role == "Guide" then return base * 0.87
		elseif role == "Threshold" then return base * 0.72
		elseif role == "Accent" then return base * 0.50
		elseif role == "Bounce" then return base * 0.52
		elseif role == "Emergency" then return base * 0.60
		elseif role == "Fault" then return base * 0.10
		end
		return base * 0.55
	elseif state == "woken" then
		if role == "Fault" then return base * 0.14
		elseif role == "Emergency" then return base * 0.42
		end
		return base
	else
		-- A red alert is a change in priorities, not a monochrome blackout.
		if role == "Fault" or role == "Emergency" then return base * 0.90
		elseif role == "Route" then return base * 0.88
		elseif role == "Guide" then return base * 0.85
		elseif role == "Task" then return base * 0.72
		elseif role == "Ceiling" then return base * 0.58
		elseif role == "Threshold" then return base * 0.75
		elseif role == "Accent" then return base * 0.60
		elseif role == "Bounce" then return base * 0.52
		end
		return base * 0.60
	end
end

local function remember(part: BasePart): Look
	local look = original[part]
	if not look then
		look = { material = part.Material, color = part.Color }
		original[part] = look
	end
	return look
end

local function applyOne(lamp: MapContract.Lamp, suppressed: boolean)
	local p = lamp.part
	local tagged = authored and p ~= nil and p:GetAttribute("LightRole") ~= nil
	if not tagged then
		-- An untagged greybox must also be readable on its first frame.
		-- Preserve hand-authored light ownership (handled above in init).
		local on = not suppressed
		local color = if state == "red" then STYLE_RED else STYLE_WARM
		for _, light in lamp.lights do
			light.Enabled = on
			light.Color = color
			light.Brightness = if state == "dead" then 0.42
				elseif state == "red" then 0.65 else 0.65
		end
		if p then
			local look = remember(p)
			p.Material = if on then Enum.Material.Neon else look.material
			p.Color = if on then color:Lerp(Color3.new(), 0.35) else look.color
		end
		return
	end

	local part = p :: BasePart
	local role = part:GetAttribute("LightRole") :: string
	local room = part:GetAttribute("LightRoom")
	local place = if type(room) == "string" then room else ""
	local base = part:GetAttribute("LightBase")
	local range = part:GetAttribute("LightRange")
	local nominal = if type(base) == "number" then base else 0.4
	local intensity = intensityFor(role, nominal)
	if suppressed then
		-- The main breakers trip, but battery-backed corridors, EXIT fixtures
		-- and tiny pilots persist. Gameplay never becomes a black void.
		intensity = if role == "Route" then nominal * 0.35
			elseif role == "Guide" then nominal * 0.25
			elseif role == "Emergency" then nominal * 0.25
			else 0
	end
	local on = intensity > 0
	local color = colorFor(place, role)
	for _, light in lamp.lights do
		light.Enabled = on
		light.Color = color
		light.Brightness = intensity
		if type(range) == "number" then
			if light:IsA("PointLight") then
				light.Range = range
			elseif light:IsA("SpotLight") then
				light.Range = range
			elseif light:IsA("SurfaceLight") then
				light.Range = range
			end
		end
	end

	local appearance = remember(part)
	local diffuser = part:FindFirstChild("FrostedDiffuser")
	if diffuser and diffuser:IsA("BasePart") then
		-- The housing stays physically metallic; only the inset glass emits.
		part.Material = appearance.material
		part.Color = appearance.color
		local lensLook = remember(diffuser)
		diffuser.Material = if on then Enum.Material.Neon else lensLook.material
		diffuser.Color = if on then color:Lerp(Color3.new(), 0.36) else lensLook.color
	else
		-- Original map-mounted ceiling or accent practical, with no separate lens.
		part.Material = if on then Enum.Material.Neon else appearance.material
		part.Color = if on then color:Lerp(Color3.new(), 0.47) else appearance.color
	end
end

local function show()
	local suppressed = os.clock() < blackoutUntil
	for _, lamp in lamps do
		applyOne(lamp, suppressed)
	end
	-- Decorative desk LEDs must obey the chapter's power states too.
	-- The hero console adds no extra PointLights for every channel.
	for _, led in consoleIndicators do
		if led.Parent then
			local kind = led:GetAttribute("ConsoleIndicator")
			local on = not suppressed and state ~= "dead"
			-- PBR SurfaceAppearance can override Color/Material. For imported
			-- MeshPart lenses, use opacity as the robust on/off control.
			if led:GetAttribute("UseOpacityForPower") == true then
				led.Transparency = if on then 0 else 1
			end
			led.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
			if not on then
				led.Color = Color3.fromRGB(29, 32, 30)
			elseif kind == "record" then
				led.Color = if state == "red"
					then Color3.fromRGB(222, 68, 52)
					else Color3.fromRGB(159, 86, 52)
			else
				led.Color = if state == "red"
					then Color3.fromRGB(83, 112, 93)
					else Color3.fromRGB(120, 151, 102)
			end
		end
	end
end

local function grade()
	if ownsLighting then
		return
	end
	Lighting.ExposureCompensation = if state == "dead"
		then 0.15
		elseif state == "woken" then 0.08
		else 0.06
	Lighting.Ambient = if state == "dead"
		then Color3.fromRGB(39, 42, 46)
		elseif state == "woken" then Color3.fromRGB(37, 39, 41)
		else Color3.fromRGB(33, 38, 43)
	Lighting.OutdoorAmbient = Color3.fromRGB(40, 46, 50)
	if correction then
		correction.Brightness = if state == "red" then 0.012 else 0.020
		correction.Contrast = if state == "red" then 0.09 else 0.055
		correction.Saturation = if state == "red" then -0.13 else -0.07
		correction.TintColor = if state == "red"
			then Color3.fromRGB(232, 239, 245)
			else Color3.fromRGB(251, 246, 237)
	end
	if bloom then
		-- A controlled hint of glow around lamps and indicator lenses only.
		bloom.Intensity = if state == "woken" then 0.09 else 0.06
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
	Lighting.FogStart = math.min(26, fogEnd * 0.42)
end

-- One non-critical fixture drops out briefly, never all of Control A's
-- task lighting and never the tiny wayfinding/pilot glows.
local function startFlicker(myGeneration: number)
	task.spawn(function()
		while generation == myGeneration and state ~= "dead" do
			task.wait(rng:NextNumber(3.8, 8.5))
			if generation ~= myGeneration or os.clock() < blackoutUntil then
				continue
			end
			local candidates: { MapContract.Lamp } = {}
			for _, lamp in lamps do
				local p = lamp.part
				local role = if p then p:GetAttribute("LightRole") else nil
				if
					role ~= "Guide"
					and role ~= "Route"
					and role ~= "Task"
					and role ~= "Emergency"
					and #lamp.lights > 0
					and lamp.lights[1].Enabled
				then
					table.insert(candidates, lamp)
				end
			end
			if #candidates == 0 then
				continue
			end
			local chosen = candidates[rng:NextInteger(1, #candidates)]
			for _, light in chosen.lights do
				light.Enabled = false
			end
			task.wait(rng:NextNumber(0.06, 0.20))
			if generation == myGeneration then
				applyOne(chosen, os.clock() < blackoutUntil)
			end
		end
	end)
end

function LightingService.set(newState: State)
	state = newState
	generation += 1
	RoundState.set("Lights", newState)
	grade()
	show()
	if newState ~= "dead" then
		startFlicker(generation)
	end
end

function LightingService.state(): State
	return state
end

function LightingService.blackout(seconds: number)
	local untilTime = os.clock() + math.max(0, seconds)
	blackoutUntil = math.max(blackoutUntil, untilTime)
	show()
	task.delay(math.max(0, seconds) + 0.06, function()
		-- A state switch during a blackout must not leave lamps off forever;
		-- newer blackout calls have their own later restoration callback.
		if os.clock() >= blackoutUntil then
			show()
		end
	end)
end

function LightingService.setPressure(pressure: number)
	local P = Config.PACING
	pressureFog = P.FOG_END_CALM + (P.FOG_END_FULL - P.FOG_END_CALM) * math.clamp(pressure, 0, 1)
	applyFog()
end

function LightingService.fogIn(seconds: number)
	shockFogUntil = math.max(shockFogUntil, os.clock() + math.max(0, seconds))
	applyFog()
	task.delay(seconds + 0.12, applyFog)
end

function LightingService.reset()
	blackoutUntil = 0
	shockFogUntil = 0
	pressureFog = Config.PACING.FOG_END_CALM
	LightingService.set("dead")
	applyFog()
end

local function configureGlobal()
	-- Roblox's current unified lighting API. The deprecated Technology
	-- property is deliberately not used here.
	-- Renderer quality is set once in default.project.json / Studio rather
	-- than changed per-round. API write access has varied across versions.
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.43
	Lighting.ClockTime = 0
	Lighting.Brightness = 1.20
	Lighting.EnvironmentDiffuseScale = 0.25
	Lighting.EnvironmentSpecularScale = 0.25
	Lighting.FogColor = Color3.fromRGB(29, 39, 47)
	local prevCorrection = Lighting:FindFirstChild("DeadAirStudioGrade")
	if prevCorrection and prevCorrection:IsA("ColorCorrectionEffect") then
		correction = prevCorrection
	else
		local effect = Instance.new("ColorCorrectionEffect")
		effect.Name = "DeadAirStudioGrade"
		effect.Parent = Lighting
		correction = effect
	end
	local prevBloom = Lighting:FindFirstChild("DeadAirStudioBloom")
	if prevBloom and prevBloom:IsA("BloomEffect") then
		bloom = prevBloom
	else
		local effect = Instance.new("BloomEffect")
		effect.Name = "DeadAirStudioBloom"
		effect.Parent = Lighting
		bloom = effect
	end
	if correction then
		correction.Enabled = true
	end
	if bloom then
		bloom.Enabled = true
		bloom.Size = 12
		bloom.Threshold = 0.93
	end
end

function LightingService.init(layout: MapContract.Layout)
	lamps = layout.lamps
	table.clear(consoleIndicators)
	local console = layout.map:FindFirstChild("HeroMixConsole", true)
	if console then
		for _, descendant in console:GetDescendants() do
			if
				descendant:IsA("BasePart")
				and descendant:GetAttribute("ConsoleIndicator") ~= nil
			then
				table.insert(consoleIndicators, descendant)
			end
		end
	end
	ownsLighting = layout.map:GetAttribute("OwnsLighting") == true
	authored = layout.map:GetAttribute("StudioLightingRig") == 1
	table.clear(original)
	if not ownsLighting then
		-- The greybox fallback must never inherit the place's uninitialized
		-- zero-brightness defaults when a studio generator error occurs.
		configureGlobal()
	end
	LightingService.reset()
end

return LightingService
