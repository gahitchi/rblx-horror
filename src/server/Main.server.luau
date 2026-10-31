--!strict
-- Server entry point: builds the map, wires the systems together, and starts the round loop.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ArtBuilder = require(script.Parent.ArtBuilder)
local DoorService = require(script.Parent.DoorService)
local MapBuilder = require(script.Parent.MapBuilder)
local MonsterService = require(script.Parent.MonsterService)
local NoiseService = require(script.Parent.NoiseService)
local ObjectiveService = require(script.Parent.ObjectiveService)
local PlayerService = require(script.Parent.PlayerService)
local RoundService = require(script.Parent.RoundService)

-- The Baseplate template's baseplate and spawn don't belong here; removed only while running.
local baseplate = Workspace:FindFirstChild("Baseplate")
if baseplate then
	baseplate:Destroy()
end
for _, descendant in Workspace:GetDescendants() do
	if descendant:IsA("SpawnLocation") then
		descendant:Destroy()
	end
end

-- Darkness. (Lighting technology is set to Future in the project file.)
Lighting.Brightness = 0
Lighting.ClockTime = 0
Lighting.Ambient = Color3.new(0, 0, 0)
Lighting.OutdoorAmbient = Color3.fromRGB(5, 5, 7)
Lighting.FogColor = Color3.new(0, 0, 0)
Lighting.FogStart = 20
Lighting.FogEnd = 160
for _, child in Lighting:GetChildren() do
	if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("Clouds") then
		child:Destroy()
	end
end

local layout = MapBuilder.build()
-- Pure visual detail; gameplay anchors and collision remain owned by MapBuilder.
ArtBuilder.build(layout)

NoiseService.init()
NoiseService.setZones(layout.zones)
DoorService.register(layout.frontDoor, false)
for _, door in layout.doors do
	DoorService.register(door, true)
end

MonsterService.init(layout.areas, RoundService.isTarget, RoundService.catch)
ObjectiveService.init(layout, RoundService.isTarget)
PlayerService.init()
RoundService.init(layout)

print(string.format("[%s] server running, v%s", Config.GAME_NAME, Config.VERSION))
