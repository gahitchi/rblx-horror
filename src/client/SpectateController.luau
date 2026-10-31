--!strict
-- After you're caught (or once you've escaped), you watch a teammate who's still in, over their
-- shoulder, until the round ends. Q and E switch between them.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer

local SpectateController = {}

local spectating = false
local target: Player? = nil
local step = 0 -- pending switch from Q/E: -1, 0 or 1

function SpectateController.getTarget(): Player?
	return if spectating then target else nil
end

local function humanoidOf(p: Player): Humanoid?
	local character = p.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

local function inRound(p: Player): boolean
	local character = p.Character
	return character ~= nil and character:GetAttribute("InRound") == true and humanoidOf(p) ~= nil
end

local function stillIn(): { Player }
	local list: { Player } = {}
	for _, other in Players:GetPlayers() do
		if other ~= player and inRound(other) then
			table.insert(list, other)
		end
	end
	table.sort(list, function(a, b)
		return a.UserId < b.UserId
	end)
	return list
end

local function onSwitch(name: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		step = if name == "DeadAirSpectatePrev" then -1 else 1
	end
	return Enum.ContextActionResult.Sink
end

local function begin()
	spectating = true
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = 7
	player.CameraMaxZoomDistance = 14
	ContextActionService:BindAction(
		"DeadAirSpectatePrev",
		onSwitch,
		true,
		Enum.KeyCode.Q,
		Enum.KeyCode.ButtonL1
	)
	ContextActionService:BindAction(
		"DeadAirSpectateNext",
		onSwitch,
		true,
		Enum.KeyCode.E,
		Enum.KeyCode.ButtonR1
	)
	ContextActionService:SetTitle("DeadAirSpectatePrev", "<")
	ContextActionService:SetTitle("DeadAirSpectateNext", ">")
end

local function finish()
	spectating = false
	target = nil
	ContextActionService:UnbindAction("DeadAirSpectatePrev")
	ContextActionService:UnbindAction("DeadAirSpectateNext")
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 400 -- the defaults; first-person mode ignores zoom anyway
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	local own = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local camera = Workspace.CurrentCamera
	if own and camera then
		camera.CameraSubject = own
	end
end

local function update()
	local state = ReplicatedStorage:FindFirstChild("RoundState")
	local playing = state ~= nil and state:GetAttribute("Phase") == "Playing"
	local out = playing and not inRound(player)
	local list = if out then stillIn() else {}

	if not Config.FEATURES.SPECTATE or not out or #list == 0 then
		if spectating then
			finish()
		end
		return
	end
	if not spectating then
		begin()
	end

	local found = if target then table.find(list, target) else nil
	local index: number = found or 1
	if step ~= 0 then
		index = (index - 1 + step) % #list + 1
		step = 0
	end
	target = list[index]
	local humanoid = humanoidOf(list[index])
	local camera = Workspace.CurrentCamera
	if humanoid and camera and camera.CameraSubject ~= humanoid then
		camera.CameraSubject = humanoid
	end
end

function SpectateController.start()
	RunService.Heartbeat:Connect(update)
end

return SpectateController
