--!strict
-- Sprint (Shift) and crouch (C or Ctrl), with stamina.
-- The server doesn't trust any of this: it judges noise from how fast the character really moves.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer

local MovementController = {}

local wantsSprint = false
local crouching = false
local stamina = 1 -- 0 to 1
local exhausted = false -- after emptying stamina, sprint waits until it's back to 30%
local cameraDrop = 0

function MovementController.getStamina(): number
	return stamina
end

function MovementController.isCrouching(): boolean
	return crouching
end

function MovementController.isSprinting(): boolean
	return wantsSprint and not crouching and not exhausted
end

local function onSprint(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		wantsSprint = true
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		wantsSprint = false
	end
	return Enum.ContextActionResult.Pass
end

local function onCrouch(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		crouching = not crouching
	end
	return Enum.ContextActionResult.Pass
end

local function update(dt: number)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local moving = humanoid.MoveDirection.Magnitude > 0.1
	local sprinting = MovementController.isSprinting() and moving and stamina > 0

	if sprinting then
		stamina = math.max(0, stamina - dt / Config.STAMINA_SECONDS)
		if stamina <= 0 then
			exhausted = true
		end
	else
		stamina = math.min(1, stamina + dt / Config.STAMINA_REFILL_SECONDS)
		if exhausted and stamina >= 0.3 then
			exhausted = false
		end
	end

	if crouching then
		humanoid.WalkSpeed = Config.CROUCH_SPEED
	elseif sprinting then
		humanoid.WalkSpeed = Config.SPRINT_SPEED
	else
		humanoid.WalkSpeed = Config.WALK_SPEED
	end

	-- Ease the camera down and up rather than snapping.
	local target = if crouching then Config.CROUCH_CAMERA_DROP else 0
	cameraDrop += (target - cameraDrop) * math.min(1, dt * 10)
	humanoid.CameraOffset = Vector3.new(0, -cameraDrop, 0)
end

function MovementController.start()
	ContextActionService:BindAction(
		"DeadAirSprint",
		onSprint,
		true,
		Enum.KeyCode.LeftShift,
		Enum.KeyCode.ButtonL3
	)
	ContextActionService:BindAction(
		"DeadAirCrouch",
		onCrouch,
		true,
		Enum.KeyCode.C,
		Enum.KeyCode.LeftControl,
		Enum.KeyCode.ButtonB
	)
	ContextActionService:SetTitle("DeadAirSprint", "Run")
	ContextActionService:SetTitle("DeadAirCrouch", "Crouch")
	ContextActionService:SetPosition("DeadAirSprint", UDim2.new(1, -170, 1, -170))
	ContextActionService:SetPosition("DeadAirCrouch", UDim2.new(1, -230, 1, -100))

	-- A fresh character starts standing with full stamina.
	player.CharacterAdded:Connect(function()
		crouching = false
		stamina = 1
		exhausted = false
		cameraDrop = 0
	end)

	RunService.RenderStepped:Connect(update)
end

return MovementController
