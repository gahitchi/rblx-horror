--!strict
-- Keys for the items. The server checks everything; this only sends what the player pressed.
--   V (hold)  talk on the walkie        N  walkie on/off
--   1 to 4    walkie callouts           R  tape recorder: record, or set it down
--   G         put down what you're holding (a reel, spare parts)
--   T         throw what you're holding (bottles, cans, pipes) where you're looking
--   Space     hold your breath, while hiding with the monster close

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local ItemController = {}

local CALLOUT_KEYS = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }

local function onTalk(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		Remotes.WalkieTalk:FireServer(true)
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		Remotes.WalkieTalk:FireServer(false)
	end
	return Enum.ContextActionResult.Pass
end

local function onPower(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		Remotes.WalkiePower:FireServer()
	end
	return Enum.ContextActionResult.Pass
end

local function onCallout(
	_: string,
	state: Enum.UserInputState,
	input: InputObject
): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		local index = table.find(CALLOUT_KEYS, input.KeyCode)
		if index then
			Remotes.WalkieCallout:FireServer(index)
		end
	end
	return Enum.ContextActionResult.Pass
end

local function onTape(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		Remotes.TapeAction:FireServer()
	end
	return Enum.ContextActionResult.Pass
end

local function onDrop(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		local roundState = ReplicatedStorage:FindFirstChild("RoundState")
		if roundState and roundState:GetAttribute("Phase") == "Playing" then
			Remotes.DropItem:FireServer()
		end
	end
	return Enum.ContextActionResult.Pass
end

local function onThrow(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		local camera = Workspace.CurrentCamera
		if camera then
			Remotes.Throw:FireServer(camera.CFrame.LookVector)
		end
	end
	return Enum.ContextActionResult.Pass
end

local holdingBreath = false

local function onBreath(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	local holding = state == Enum.UserInputState.Begin
	if holding ~= holdingBreath then
		holdingBreath = holding
		Remotes.HoldBreath:FireServer(holding)
	end
	return Enum.ContextActionResult.Sink
end

local function onLeaveHiding(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		Remotes.LeaveHiding:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

function ItemController.start()
	-- Throw: only shown (on touch screens) while holding something throwable.
	-- Hold breath: only bound while hiding, so Space is a jump again outside.
	local player = Players.LocalPlayer
	local throwBound = false
	local breathBound = false
	RunService.Heartbeat:Connect(function()
		local canThrow = player:GetAttribute("CanThrow") == true
		if canThrow ~= throwBound then
			throwBound = canThrow
			if canThrow then
				ContextActionService:BindAction(
					"DeadAirThrow",
					onThrow,
					true,
					Enum.KeyCode.T,
					Enum.KeyCode.DPadUp
				)
				ContextActionService:SetTitle("DeadAirThrow", "Throw")
				ContextActionService:SetPosition("DeadAirThrow", UDim2.new(1, -100, 1, -230))
			else
				ContextActionService:UnbindAction("DeadAirThrow")
			end
		end
		local hiding = player:GetAttribute("Hiding") == true
		if hiding ~= breathBound then
			breathBound = hiding
			if hiding then
				ContextActionService:BindAction(
					"DeadAirHoldBreath",
					onBreath,
					true,
					Enum.KeyCode.Space,
					Enum.KeyCode.ButtonA
				)
				ContextActionService:SetTitle("DeadAirHoldBreath", "Hold breath")
				ContextActionService:SetPosition("DeadAirHoldBreath", UDim2.new(1, -170, 1, -170))
				ContextActionService:BindAction(
					"DeadAirLeaveHiding",
					onLeaveHiding,
					true,
					Enum.KeyCode.E,
					Enum.KeyCode.ButtonX
				)
				ContextActionService:SetTitle("DeadAirLeaveHiding", "Step out")
				ContextActionService:SetPosition("DeadAirLeaveHiding", UDim2.new(1, -250, 1, -110))
			else
				ContextActionService:UnbindAction("DeadAirHoldBreath")
				ContextActionService:UnbindAction("DeadAirLeaveHiding")
				if holdingBreath then
					holdingBreath = false
					Remotes.HoldBreath:FireServer(false)
				end
			end
		end
	end)

	ContextActionService:BindAction(
		"DeadAirDrop",
		onDrop,
		false,
		Enum.KeyCode.G,
		Enum.KeyCode.DPadLeft
	)
	if Config.FEATURES.WALKIE then
		ContextActionService:BindAction(
			"DeadAirTalk",
			onTalk,
			true,
			Enum.KeyCode.V,
			Enum.KeyCode.ButtonR1
		)
		ContextActionService:SetTitle("DeadAirTalk", "Talk")
		ContextActionService:SetPosition("DeadAirTalk", UDim2.new(1, -240, 1, -230))
		ContextActionService:BindAction("DeadAirWalkiePower", onPower, false, Enum.KeyCode.N)
		ContextActionService:BindAction(
			"DeadAirCallout",
			onCallout,
			false,
			table.unpack(CALLOUT_KEYS)
		)
	end
	if Config.FEATURES.TAPE then
		ContextActionService:BindAction(
			"DeadAirTape",
			onTape,
			true,
			Enum.KeyCode.R,
			Enum.KeyCode.ButtonX
		)
		ContextActionService:SetTitle("DeadAirTape", "Tape")
		ContextActionService:SetPosition("DeadAirTape", UDim2.new(1, -170, 1, -300))
	end
end

return ItemController
