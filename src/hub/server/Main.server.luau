--!strict
-- Wrenmouth coast checkpoint: a warm, playable safe-zone above the sealed town.
-- If a hand-built Workspace.Hub already exists it takes precedence over this source map.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local HubBuilder = require(script.Parent.HubBuilder)
local HubDynamics = require(script.Parent.HubDynamics)
local LobbyService = require(script.Parent.LobbyService)
local HubLoadout = require(script.Parent.HubLoadout)

local function fallback(): Model
	local model = Instance.new("Model")
	model.Name = "Hub"
	local floor = Instance.new("Part")
	floor.Name = "TemporaryCoastPlatform"
	floor.Size = Vector3.new(110, 1, 100)
	floor.Position = Vector3.new(0, -0.5, 0)
	floor.Anchored = true
	floor.Color = Color3.fromRGB(65, 64, 63)
	floor.Parent = model
	local spawn = Instance.new("Part")
	spawn.Name = "HubSpawn"
	spawn.Size = Vector3.new(4, 1, 4)
	spawn.CFrame = CFrame.new(-20, 3, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Anchored = true
	spawn.Parent = model
	model.Parent = Workspace
	return model
end

local existing = Workspace:FindFirstChild("Hub")
local hub: Model
if existing and existing:IsA("Model") and existing:FindFirstChild("HubSpawn", true) then
	hub = existing
else
	if existing then
		warn("[Hub] existing Hub has no HubSpawn; replacing with generated scene")
		existing:Destroy()
	end
	local ok, result = pcall(HubBuilder.build)
	if ok then
		hub = result :: Model
	else
		warn("[Hub] generated Wrenmouth scene failed: " .. tostring(result))
		hub = fallback()
	end
end

-- A warm last safe place. The town and sea remain blue-grey and fogged.
Lighting.ClockTime = 0
Lighting.Brightness = 1.4
Lighting.Ambient = Color3.fromRGB(31, 39, 48)
Lighting.OutdoorAmbient = Color3.fromRGB(19, 26, 35)
Lighting.FogColor = Color3.fromRGB(36, 49, 61)
Lighting.FogStart = 60
Lighting.FogEnd = 240
Lighting.EnvironmentDiffuseScale = 0.28
Lighting.EnvironmentSpecularScale = 0.16
Lighting.GlobalShadows = true

-- Default Baseplate/SpawnLocations are from the Studio template, not the hub.
for _, child in Workspace:GetChildren() do
	if child.Name == "Baseplate" and child:IsA("BasePart") then
		child:Destroy()
	elseif child:IsA("SpawnLocation") then
		child:Destroy()
	end
end

local spawn = hub:FindFirstChild("HubSpawn", true)
assert(spawn and spawn:IsA("BasePart"), "Hub must contain HubSpawn")
local spawnPart = spawn :: BasePart
local function attachPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			if character.Parent then
				character:PivotTo(spawnPart.CFrame
					+ Vector3.new(math.random(-2, 2), 2.6, math.random(-2, 2)))
			end
		end)
	end)
	if player.Character then
		task.defer(function()
			local character = player.Character
			if character and character.Parent then
				character:PivotTo(spawnPart.CFrame + Vector3.new(0, 2.6, 0))
			end
		end)
	end
end
Players.PlayerAdded:Connect(attachPlayer)
for _, player in Players:GetPlayers() do
	attachPlayer(player)
end

HubDynamics.init(hub)
LobbyService.onDeparture(function()
	HubDynamics.departure(hub)
end)
LobbyService.init()
HubLoadout.init()
print(string.format("[%s] Wrenmouth hub running, v%s", Config.GAME_NAME, Config.VERSION))
