--!strict
-- Server entry point: builds the map, wires the systems together, and starts the round loop.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ArtBuilder = require(script.Parent.ArtBuilder)
local VisualFidelity = require(script.Parent.VisualFidelity)
local DoorService = require(script.Parent.DoorService)
local MapBuilder = require(script.Parent.MapBuilder)
local MapContract = require(script.Parent.MapContract)
local MonsterService = require(script.Parent.MonsterService)
local NoiseService = require(script.Parent.NoiseService)
local ObjectiveService = require(script.Parent.ObjectiveService)
local PlayerService = require(script.Parent.PlayerService)
local RoundService = require(script.Parent.RoundService)

local FeedbackService = require(script.Parent.FeedbackService)
local ProgressService = require(script.Parent.ProgressService)
local ReplayService = require(script.Parent.ReplayService)
local ReviveService = require(script.Parent.ReviveService)
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
-- Which map: the one the hub lobby (or the replay vote) picked, sent with the teleport. A reserved
-- server starts because players are on their way, so wait for the first one to read it.
local function chosenMap(): string
	if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
		local deadline = os.clock() + 20
		while #Players:GetPlayers() == 0 and os.clock() < deadline do
			task.wait(0.1)
		end
		local first = Players:GetPlayers()[1]
		local joinData = if first then first:GetJoinData() else nil
		local data: any = joinData and joinData.TeleportData
		local wanted = if type(data) == "table" then data.map else nil
		for _, entry in Config.MAPS do
			if entry.id == wanted then
				return entry.id
			end
		end
	end
	return Config.MAPS[1].id
end
local mapId = chosenMap()

-- A hand-made map: Workspace.Map (testing in Studio), or ServerStorage.Maps.<id> for that map.
-- Otherwise the code-built greybox (the recording studio).
local lobbySpawn = MapBuilder.buildLobby()
local map = Workspace:FindFirstChild("Map")
if not map then
	local stored = ServerStorage:FindFirstChild("Maps")
	local source = stored and stored:FindFirstChild(mapId)
	if source then
		local copy = source:Clone()
		copy.Name = "Map"
		copy.Parent = Workspace
		map = copy
	else
		map = MapBuilder.build()
	end
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

-- Studio-specific realistic rendering; does not override hand-authored maps that own lighting.
VisualFidelity.apply(layout)

NoiseService.init()
NoiseService.setZones(layout.zones)
DoorService.register(layout.frontDoor, false)
for _, door in layout.doors do
	DoorService.register(door, true)
end

MonsterService.init(layout.areas, RoundService.isTarget, RoundService.catch)
ObjectiveService.init(layout, RoundService.isTarget)
PlayerService.init()
ProgressService.init()
FeedbackService.init()
ReviveService.init(layout.areas)
WalkieService.init(layout.areas)
TapeService.init()
ReplayService.init(mapId)
RoundService.afterResults(ReplayService.run)
RoundService.init(layout)

print(string.format("[%s] server running, v%s", Config.GAME_NAME, Config.VERSION))
