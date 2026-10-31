--!strict
-- The closer the monster, the darker the edges of the screen and the colder the colours;
-- stronger still when it is chasing. A feeling, not a radar: it doesn't say which way.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local FEEL_DISTANCE = 60
local EDGE_SIZE = 0.35 -- share of the screen each dark edge covers

local DangerEffect = {}

local intensity = 0

function DangerEffect.getIntensity(): number
	return intensity
end

local function makeEdge(parent: Instance, rotation: number, size: UDim2, position: UDim2): Frame
	local edge = Instance.new("Frame")
	edge.BackgroundColor3 = Color3.new(0, 0, 0)
	edge.BorderSizePixel = 0
	edge.Size = size
	edge.Position = position
	edge.BackgroundTransparency = 0
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Transparency = NumberSequence.new(0, 1)
	gradient.Parent = edge
	edge.Parent = parent
	return edge
end

function DangerEffect.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "DangerEffect"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -1 -- under the HUD
	gui.Parent = player:WaitForChild("PlayerGui")

	local holder = Instance.new("CanvasGroup")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.GroupTransparency = 1
	holder.Parent = gui

	-- Each edge is dark at the screen border and fades toward the centre.
	makeEdge(holder, 0, UDim2.fromScale(EDGE_SIZE, 1), UDim2.fromScale(0, 0))
	makeEdge(holder, 180, UDim2.fromScale(EDGE_SIZE, 1), UDim2.fromScale(1 - EDGE_SIZE, 0))
	makeEdge(holder, 90, UDim2.fromScale(1, EDGE_SIZE), UDim2.fromScale(0, 0))
	makeEdge(holder, 270, UDim2.fromScale(1, EDGE_SIZE), UDim2.fromScale(0, 1 - EDGE_SIZE))

	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "DeadAirDanger"
	grade.Parent = Lighting

	RunService.RenderStepped:Connect(function(dt: number)
		local target = 0
		local monster = Workspace:FindFirstChild("Monster")
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local monsterRoot = monster and monster:FindFirstChild("HumanoidRootPart")
		if
			monster
			and root
			and root:IsA("BasePart")
			and monsterRoot
			and monsterRoot:IsA("BasePart")
			and character
			and character:GetAttribute("InRound") == true
		then
			local distance = (monsterRoot.Position - root.Position).Magnitude
			target = math.clamp(1 - distance / FEEL_DISTANCE, 0, 1)
			if monster:GetAttribute("State") == "Chase" then
				target = math.min(1, target * 1.5 + 0.15)
			end
		end
		intensity += (target - intensity) * math.min(1, dt * 3)

		holder.GroupTransparency = 1 - intensity * 0.85
		grade.Saturation = -0.7 * intensity
		grade.Contrast = 0.15 * intensity
		grade.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(205, 215, 235), intensity)
	end)
end

return DangerEffect
