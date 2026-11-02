--!strict
-- Developer-only Studio Server Command Bar test. DO NOT add to live scripts.
-- Run after the MATCH place has generated Workspace.Map.
-- This checks state switching, not visual realism or device performance.
local ServerScriptService = game:GetService("ServerScriptService")
local server = ServerScriptService:WaitForChild("Server")
local LightingService = require(server:WaitForChild("LightingService"))
local map = workspace:WaitForChild("Map")
local fixtureFolder = map:FindFirstChild("Lamps")
assert(fixtureFolder, "[Lighting test] Map.Lamps not found")
assert(map:GetAttribute("StudioLightingRig") == 1, "[Lighting test] authored studio rig not present")
assert(map:GetAttribute("StudioAddedFixtures") == 40, "[Lighting test] incorrect fixture count")

local originalState = LightingService.state()
local testCount = 0
local function check(cond: boolean, message: string)
	testCount += 1
	assert(cond, "[Lighting test " .. testCount .. "] " .. message)
end

local function lightFor(name: string): Light
	local part = fixtureFolder:FindFirstChild("Light_" .. name)
	assert(part and part:IsA("BasePart"), "[Lighting test] missing fixture " .. name)
	local light = part:FindFirstChild("ActualIllumination")
	assert(light and light:IsA("Light"), "[Lighting test] source lacks light " .. name)
	return light :: Light
end

local desk = lightFor("DeskWritingLamp")
local pilot = lightFor("TapeTransportPilot")
local emergency = lightFor("FrontDoorSecurity")
local fault = lightFor("ControlACircuitFault")
local bounce = lightFor("DeskToWallBounce")
local softbox = lightFor("ControlASoftboxReturn")
local pulse = lightFor("LiveRoomWideSoftbox")

LightingService.set("dead")
check(not desk.Enabled, "desk must be dark before the first shock")
check(pilot.Enabled, "guide pilot must exist in early exploration")
check(not bounce.Enabled, "bounced fill must not fake active power when dead")
LightingService.set("woken")
check(desk.Enabled, "desk task light must wake")
check(bounce.Enabled, "bounce proxy must track live desk power")
check(softbox.Enabled and pulse.Enabled, "broad surface lights must activate")
check(not fault.Enabled or fault.Brightness < 0.1,
	"fault light must remain restrained until emergency")
LightingService.set("red")
check(emergency.Enabled and fault.Enabled,
	"red state must be carried by visible emergency/fault fixtures")
check(desk.Enabled and desk.Brightness > 0,
	"task lights must remain dim but usable during red emergency")
LightingService.blackout(0.16)
check(not desk.Enabled and not pilot.Enabled, "blackout suppresses all practicals")
-- Intentionally switch state during blackout to exercise the restore guard.
LightingService.set("woken")
task.wait(0.28)
check(desk.Enabled and pilot.Enabled, "changing state during blackout must recover")
LightingService.set(originalState)
print("PASS: " .. tostring(testCount) ..
	" lighting-state and blackout checks. Original state restored: " .. originalState)
