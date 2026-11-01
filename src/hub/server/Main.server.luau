--!strict
-- Hub entry point: a place to gather, and the lobbies that send groups into matches.
-- A dedicated original HubEnvironment model builds an authored waiting concourse; a hand-made
-- Workspace.Hub with HubSpawn overrides it without affecting LobbyService.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local LobbyService = require(script.Parent.LobbyService)
local HubEnvironment = require(script.Parent.HubEnvironment)

local existing = Workspace:FindFirstChild("Hub")
local spawnPart = existing and existing:FindFirstChild("HubSpawn", true)
local spawnAt: BasePart = if spawnPart and spawnPart:IsA("BasePart") then spawnPart else HubEnvironment.build()

-- High-quality lighting style and priority belong to hub.project.json / Studio,
-- not gameplay scripts (both properties are restricted at runtime).
Lighting.GlobalShadows = true
Lighting.EnvironmentSpecularScale = 0.75
Lighting.Brightness = 0.35
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
