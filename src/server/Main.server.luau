--!strict
-- Server entry point: builds the map, wires the systems together, and starts the round loop.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ArtBuilder = require(script.Parent.ArtBuilder)
local DoorService = require(script.Parent.DoorService)
local MapBuilder = require(script.Parent.MapBuilder)
local MapContract = require(script.Parent.MapContract)
local MonsterService = require(script.Parent.MonsterService)
local NoiseService = require(script.Parent.NoiseService)
local ObjectiveService = require(script.Parent.ObjectiveService)
local PlayerService = require(script.Parent.PlayerService)
local RoundService = require(script.Parent.RoundService)

local TapeService = require(script.Parent.Items.TapeService)
local WalkieService = require(script.Parent.Items.WalkieService)

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

-- The map: a hand-made Workspace.Map if there is one (see docs/MAP_CONTRACT.md), otherwise the
-- code-built greybox, which follows the same contract.
local lobbySpawn = MapBuilder.buildLobby()
local map = Workspace:FindFirstChild("Map")
if not map then
	map = MapBuilder.build()
end
local loaded, problems = MapContract.read(map :: Instance, lobbySpawn)
for _, problem in problems do
	warn("[Map] " .. problem)
end
if not loaded then
	-- Unusable: keep it in the world for inspection, but play on the greybox.
	warn("[Map] Workspace.Map doesn't follow docs/MAP_CONTRACT.md; using the greybox instead")
	local broken = map :: Instance
	broken.Name = "Map (unusable)"
	local greybox, greyboxProblems = MapContract.read(MapBuilder.build(), lobbySpawn)
	for _, problem in greyboxProblems do
		warn("[Map] greybox: " .. problem)
	end
	loaded = greybox
end
assert(loaded, "the greybox map failed its own contract")
local layout = loaded
ArtBuilder.build(layout)

-- Darkness, unless the map has its own lighting (attribute OwnsLighting on the Map).
-- (Lighting technology is set to Future in the project file.)
if layout.map:GetAttribute("OwnsLighting") ~= true then
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
end

NoiseService.init()
NoiseService.setZones(layout.zones)
DoorService.register(layout.frontDoor, false)
for _, door in layout.doors do
	DoorService.register(door, true)
end

MonsterService.init(layout.areas, RoundService.isTarget, RoundService.catch)
ObjectiveService.init(layout, RoundService.isTarget)
PlayerService.init()
WalkieService.init(layout.areas)
TapeService.init()
RoundService.init(layout)

print(string.format("[%s] server running, v%s", Config.GAME_NAME, Config.VERSION))
