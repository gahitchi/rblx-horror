--!strict
-- Small per-player actions that aren't objectives: for now, the flashlight.
-- The light itself is drawn on each client; the server only keeps the on/off state and the click noise.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local NoiseService = require(script.Parent.NoiseService)

local COOLDOWN = 0.25

local lastToggle: { [Player]: number } = {}

local PlayerService = {}

local function onToggleFlashlight(player: Player)
	local now = os.clock()
	if now - (lastToggle[player] or 0) < COOLDOWN then
		return
	end
	lastToggle[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not root or not root:IsA("BasePart") then
		return
	end
	character:SetAttribute("FlashlightOn", not character:GetAttribute("FlashlightOn"))
	if character:GetAttribute("InRound") then
		NoiseService.emit(root.Position, Config.NOISE.FLASHLIGHT, "flashlight", player)
	end
end

function PlayerService.init()
	Remotes.ToggleFlashlight.OnServerEvent:Connect(onToggleFlashlight)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastToggle[player] = nil
	end)
end

return PlayerService
