--!strict
-- Being an echo. When the monster catches you your body stays where it fell, and you float free
-- through the building: move with the usual controls (forward follows where you look, so you can
-- rise and sink). You see the monster through walls. P (or the button) marks it for the living,
-- with a cooldown; the whisper buttons (or 5 to 8) send a short line to living players nearby.
-- The server checks everything; this moves the camera and sends what you pressed.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local E = Config.ECHO
local WHISPER_KEYS = { Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight }

local EchoController = {}

local active = false
local focus: Part? = nil
local highlight: Highlight? = nil
local controls: any = nil
local lastSent = 0

function EchoController.isActive(): boolean
	return active
end

local function getControls(): any
	if controls then
		return controls
	end
	local ok, result = pcall(function()
		local module = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
		return (require :: any)(module):GetControls()
	end)
	if ok then
		controls = result
	end
	return controls
end

local function onPing(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		Remotes.EchoPing:FireServer()
	end
	return Enum.ContextActionResult.Pass
end

local function onWhisperKey(
	_: string,
	state: Enum.UserInputState,
	input: InputObject
): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		local index = table.find(WHISPER_KEYS, input.KeyCode)
		if index then
			Remotes.EchoWhisper:FireServer(index)
		end
	end
	return Enum.ContextActionResult.Pass
end

function EchoController.whisper(index: number)
	if active then
		Remotes.EchoWhisper:FireServer(index)
	end
end

function EchoController.ping()
	if active then
		Remotes.EchoPing:FireServer()
	end
end

local function begin()
	active = true
	local camera = Workspace.CurrentCamera
	local start = camera.CFrame.Position
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		start = head.Position + Vector3.new(0, 2, 0)
	end
	local p = Instance.new("Part")
	p.Name = "EchoFocus"
	p.Size = Vector3.new(0.5, 0.5, 0.5)
	p.Transparency = 1
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CFrame = CFrame.new(start)
	p.Parent = Workspace
	focus = p
	camera.CameraSubject = p
	ContextActionService:BindAction(
		"DeadAirEchoPing",
		onPing,
		true,
		Enum.KeyCode.P,
		Enum.KeyCode.ButtonY
	)
	ContextActionService:SetTitle("DeadAirEchoPing", "Mark")
	ContextActionService:SetPosition("DeadAirEchoPing", UDim2.new(1, -170, 1, -170))
	ContextActionService:BindAction(
		"DeadAirEchoWhisper",
		onWhisperKey,
		false,
		table.unpack(WHISPER_KEYS)
	)
end

local function finish()
	active = false
	ContextActionService:UnbindAction("DeadAirEchoPing")
	ContextActionService:UnbindAction("DeadAirEchoWhisper")
	if focus then
		focus:Destroy()
		focus = nil
	end
	if highlight then
		highlight:Destroy()
		highlight = nil
	end
	local camera = Workspace.CurrentCamera
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if camera and humanoid then
		camera.CameraSubject = humanoid
	end
end

local function update(dt: number)
	local state = ReplicatedStorage:FindFirstChild("RoundState")
	local playing = state ~= nil and state:GetAttribute("Phase") == "Playing"
	local isEcho = playing and player:GetAttribute("Echo") == true
	if isEcho ~= active then
		if isEcho then
			begin()
		else
			finish()
		end
	end
	local p = focus
	if not active or not p or not state then
		return
	end

	-- Float where the controls point, relative to where the camera looks.
	local camera = Workspace.CurrentCamera
	local move = Vector3.zero
	local c = getControls()
	if c then
		local ok, vector = pcall(function()
			return c:GetMoveVector()
		end)
		if ok and typeof(vector) == "Vector3" then
			move = vector
		end
	end
	local position = p.Position
	if move.Magnitude > 0.05 then
		local direction = camera.CFrame:VectorToWorldSpace(Vector3.new(move.X, 0, move.Z))
		position += direction.Unit * math.min(move.Magnitude, 1) * E.SPEED * dt
	end
	local lo = state:GetAttribute("BoundsMin")
	local hi = state:GetAttribute("BoundsMax")
	if typeof(lo) == "Vector3" and typeof(hi) == "Vector3" then
		position = position:Max(lo):Min(hi)
	end
	p.CFrame = CFrame.new(position)
	if camera.CameraSubject ~= p then
		camera.CameraSubject = p
	end

	local now = os.clock()
	if now - lastSent >= E.SEND_INTERVAL then
		lastSent = now
		Remotes.EchoMove:FireServer(position)
	end

	-- The monster, seen through walls.
	local monster = Workspace:FindFirstChild("Monster")
	if monster and monster:IsA("Model") then
		if not highlight or highlight.Parent ~= monster then
			if highlight then
				highlight:Destroy()
			end
			local h = Instance.new("Highlight")
			h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			h.FillColor = Color3.fromRGB(200, 40, 30)
			h.FillTransparency = 0.75
			h.OutlineColor = Color3.fromRGB(255, 90, 70)
			h.Parent = monster
			highlight = h
		end
	elseif highlight then
		highlight:Destroy()
		highlight = nil
	end
end

function EchoController.start()
	RunService.RenderStepped:Connect(update)
end

return EchoController
