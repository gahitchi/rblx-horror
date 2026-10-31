--!strict
-- The closer the monster, the more the edges of the screen close in and the colder the colours;
-- stronger when it is chasing you, strongest when it lunges. A feeling, not a radar: it doesn't say
-- which way, and it is weaker when there's a wall between you.
--
-- The vignette is a soft oval: a stack of rounded frames whose thick black strokes overlap more and
-- more toward the screen edges. Only their opacity changes, so the shape never moves.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local FEEL_DISTANCE = 70
local LAYERS = 10
local LAYER_OPACITY = 0.17 -- all layers together reach about 85% black at the very edge
local OUTER_SCALE = 1.3 -- the outermost layer only touches the corners...
local INNER_SCALE = 0.55 -- ...the innermost leaves a clear oval in the middle
local BEHIND_WALL = 0.55 -- how much of the feeling gets through a wall
local RISE_RATE = 1.2 -- per second; slow, so it creeps in rather than flickers
local FALL_RATE = 0.7

local DangerEffect = {}

local intensity = 0

function DangerEffect.getIntensity(): number
	return intensity
end

local function buildVignette(parent: Instance): { UIStroke }
	local strokes: { UIStroke } = {}
	for i = 1, LAYERS do
		local t = (i - 1) / (LAYERS - 1)
		local scale = OUTER_SCALE + (INNER_SCALE - OUTER_SCALE) * t
		local frame = Instance.new("Frame")
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
		frame.Size = UDim2.fromScale(scale, scale)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Parent = parent
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = frame
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Thickness = 3000 -- reaches past any screen edge
		stroke.Transparency = 1
		stroke.Parent = frame
		table.insert(strokes, stroke)
	end
	return strokes
end

-- 0 to 1: how strongly this player should feel the monster right now.
local function measure(): number
	local monster = Workspace:FindFirstChild("Monster")
	local character = player.Character
	if not monster or not character or character:GetAttribute("InRound") ~= true then
		return 0
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local monsterRoot = monster:FindFirstChild("HumanoidRootPart")
	if
		not root
		or not root:IsA("BasePart")
		or not monsterRoot
		or not monsterRoot:IsA("BasePart")
	then
		return 0
	end
	if monster:GetAttribute("Lunging") then
		return 1
	end

	local offset = monsterRoot.Position - root.Position
	local closeness = math.clamp(1 - offset.Magnitude / FEEL_DISTANCE, 0, 1)
	closeness = closeness * closeness -- gentle far away, sharp up close
	if closeness <= 0 then
		return 0
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, monster }
	if Workspace:Raycast(root.Position, offset, params) then
		closeness *= BEHIND_WALL
	end

	if monster:GetAttribute("State") == "Chase" then
		closeness = math.min(1, closeness * 1.4 + 0.15)
	end
	return closeness
end

function DangerEffect.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "DangerEffect"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = -1 -- under the HUD
	gui.Parent = player:WaitForChild("PlayerGui")
	local strokes = buildVignette(gui)

	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "DeadAirDanger"
	grade.Parent = Lighting

	RunService.RenderStepped:Connect(function(dt: number)
		local target = measure()
		local rate = if target > intensity then RISE_RATE else FALL_RATE
		local step = rate * dt
		intensity = if math.abs(target - intensity) <= step
			then target
			else intensity + math.sign(target - intensity) * step

		local transparency = 1 - LAYER_OPACITY * intensity
		for _, stroke in strokes do
			stroke.Transparency = transparency
		end
		grade.Saturation = -0.6 * intensity
		grade.TintColor = Color3.new(1, 1, 1):Lerp(Color3.fromRGB(210, 220, 240), intensity)
	end)
end

return DangerEffect
