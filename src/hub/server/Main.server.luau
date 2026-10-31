--!strict
-- Hub entry point: a place to gather, and the lobbies that send groups into matches.
-- The hub room here is a plain placeholder; a hand-made one can replace it (a Model named "Hub" in
-- Workspace with a part named "HubSpawn" is used as it is).

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local LobbyService = require(script.Parent.LobbyService)

local function part(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	parent: Instance
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Anchored = true
	p.Material = Enum.Material.Concrete
	p.Parent = parent
	return p
end

-- A dim, quiet waiting room: the calm before the studio.
local function buildHub(): BasePart
	local hub = Instance.new("Model")
	hub.Name = "Hub"
	local floor = Color3.fromRGB(52, 48, 46)
	local wall = Color3.fromRGB(70, 66, 62)
	part("Floor", Vector3.new(80, 1, 80), CFrame.new(0, -0.5, 0), floor, hub)
	part("Ceiling", Vector3.new(80, 1, 80), CFrame.new(0, 16.5, 0), Color3.fromRGB(30, 30, 32), hub)
	for _, side in { -1, 1 } do
		part("Wall", Vector3.new(1, 16, 80), CFrame.new(side * 40, 8, 0), wall, hub)
		part("Wall", Vector3.new(80, 16, 1), CFrame.new(0, 8, side * 40), wall, hub)
	end
	for _, x in { -20, 20 } do
		for _, z in { -20, 20 } do
			local lamp = part(
				"Lamp",
				Vector3.new(3, 0.3, 3),
				CFrame.new(x, 16, z),
				Color3.fromRGB(255, 214, 160),
				hub
			)
			lamp.Material = Enum.Material.Neon
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(255, 200, 150)
			light.Range = 30
			light.Brightness = 1.2
			light.Parent = lamp
		end
	end
	local spawn = part("HubSpawn", Vector3.new(4, 1, 4), CFrame.new(0, 0.5, 20), floor, hub)
	spawn.Transparency = 1
	spawn.CanCollide = false
	hub.Parent = Workspace
	return spawn
end

local existing = Workspace:FindFirstChild("Hub")
local spawnPart = existing and existing:FindFirstChild("HubSpawn", true)
local spawnAt: BasePart = if spawnPart and spawnPart:IsA("BasePart") then spawnPart else buildHub()

Lighting.Brightness = 0.5
Lighting.ClockTime = 0
Lighting.Ambient = Color3.fromRGB(20, 18, 18)
Lighting.OutdoorAmbient = Color3.fromRGB(20, 18, 18)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			character:PivotTo(
				spawnAt.CFrame + Vector3.new(math.random(-6, 6), 3, math.random(-4, 4))
			)
		end)
	end)
end)

LobbyService.init()
print(string.format("[%s] hub running, v%s", Config.GAME_NAME, Config.VERSION))
