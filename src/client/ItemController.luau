--!strict
-- Keys for the items. The server checks everything; this only sends what the player pressed.
--   V (hold)  talk on the walkie        N  walkie on/off
--   1 to 4    walkie callouts           R  tape recorder: record, or set it down
--   G         put down what you're holding (a reel, spare parts)

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

function ItemController.start()
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
