--!strict
-- Per-player skyline progress. Saved chapter clears illuminate the windows
-- locally: one crew's achievements never turn on another player's town lights.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Chapters = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Chapters"))
local player = Players.LocalPlayer

local hub = Workspace:WaitForChild("Hub", 20)
if not hub then
	return
end
local windows = hub:FindFirstChild("TownLights")
if not windows then
	return
end

local amber = Color3.fromRGB(232, 162, 74)
local dark = Color3.fromRGB(34, 46, 56)
local red = Color3.fromRGB(186, 53, 48)

local function redraw()
	local cleared = Chapters.clearedBy(player)
	for _, part in windows:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end
		local id = part.Name
		local isMast = id == "RadioMast"
		local unlocked = table.find(cleared, if isMast then "studio3" else id) ~= nil
		part.Material = if unlocked then Enum.Material.Neon else Enum.Material.Glass
		part.Color = if not unlocked then dark elseif isMast then red else amber
		local light = part:FindFirstChildOfClass("PointLight")
		if light then
			light.Enabled = unlocked
		end
	end
end

player:GetAttributeChangedSignal("ChaptersCleared"):Connect(redraw)
redraw()
