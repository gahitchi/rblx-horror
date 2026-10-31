--!strict
-- The flashlight (F). The server owns the on/off state (character attribute FlashlightOn) because
-- the click makes noise; each client draws the lights. Your own beam follows your camera exactly;
-- other players' beams come from their heads.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local player = Players.LocalPlayer

local BEAM_COLOR = Color3.fromRGB(255, 244, 222) -- warm, like an old incandescent torch

local FlashlightController = {}

-- The beam colour of a player's chosen flashlight look (a reward-track cosmetic).
local function colorOf(owner: Player?): Color3
	local id = owner and owner:GetAttribute("FlashlightSkin")
	local skin = if type(id) == "string" then Config.FLASHLIGHT_SKINS[id] else nil
	return if skin then skin.color else BEAM_COLOR
end

local function makeBeam(parent: Instance): SpotLight
	local light = Instance.new("SpotLight")
	light.Name = "DeadAirFlashlight"
	light.Color = BEAM_COLOR
	light.Brightness = 2.2
	light.Range = 45
	light.Angle = 55
	light.Shadows = true
	light.Face = Enum.NormalId.Front
	light.Enabled = false
	light.Parent = parent
	return light
end

-- Your own beam: an invisible part that sits on the camera every frame.
local function startOwnBeam()
	local holder = Instance.new("Part")
	holder.Name = "FlashlightHolder"
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.Transparency = 1
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.CastShadow = false
	holder.Parent = Workspace -- a local part: only this client has it

	local beam = makeBeam(holder)
	-- A faint fill so the near walls aren't pitch black around the beam's edge.
	local fill = Instance.new("PointLight")
	fill.Color = BEAM_COLOR
	fill.Brightness = 0.25
	fill.Range = 8
	fill.Shadows = false
	fill.Enabled = false
	fill.Parent = holder

	RunService:BindToRenderStep(
		"DeadAirFlashlight",
		Enum.RenderPriority.Camera.Value + 1,
		function()
			local camera = Workspace.CurrentCamera
			local character = player.Character
			local own = character and character:FindFirstChildOfClass("Humanoid")
			-- Only while the camera is your own eyes (not while spectating someone else).
			local on = character ~= nil
				and character:GetAttribute("FlashlightOn") == true
				and camera ~= nil
				and camera.CameraSubject == own
			beam.Enabled = on
			fill.Enabled = on
			beam.Color = colorOf(player)
			fill.Color = beam.Color
			if camera then
				-- At the eye, a touch low and to the right. Never in front of it: up against a wall,
				-- a light placed ahead of the camera ends up inside the wall and everything goes dark.
				holder.CFrame = camera.CFrame * CFrame.new(0.3, -0.25, 0)
			end
		end
	)
end

-- Other players' beams, from their heads.
local function watchCharacter(character: Model)
	local head = character:WaitForChild("Head", 10)
	if not head or not head:IsA("BasePart") then
		return
	end
	local beam = makeBeam(head)
	local owner = Players:GetPlayerFromCharacter(character)
	local function refresh()
		beam.Enabled = character:GetAttribute("FlashlightOn") == true
		beam.Color = colorOf(owner)
	end
	if owner then
		owner:GetAttributeChangedSignal("FlashlightSkin"):Connect(refresh)
	end
	character:GetAttributeChangedSignal("FlashlightOn"):Connect(refresh)
	refresh()
end

local function watchPlayer(other: Player)
	if other == player then
		return
	end
	other.CharacterAdded:Connect(watchCharacter)
	if other.Character then
		task.spawn(watchCharacter, other.Character)
	end
end

local function onToggle(_: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state == Enum.UserInputState.Begin then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			Sounds.playAt(Sounds.FLASHLIGHT, root.Position, 0.4, 30)
		end
		Remotes.ToggleFlashlight:FireServer()
	end
	return Enum.ContextActionResult.Pass
end

-- The beam starts inside your own (invisible, first-person) head, so your own body must not cast
-- shadows from it. This only changes your view; other players still see your shadow.
local function noSelfShadow(character: Model)
	local function apply(descendant: Instance)
		if descendant:IsA("BasePart") then
			descendant.CastShadow = false
		end
	end
	for _, descendant in character:GetDescendants() do
		apply(descendant)
	end
	character.DescendantAdded:Connect(apply)
end

function FlashlightController.start()
	player.CharacterAdded:Connect(noSelfShadow)
	if player.Character then
		noSelfShadow(player.Character)
	end
	startOwnBeam()
	for _, other in Players:GetPlayers() do
		watchPlayer(other)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	ContextActionService:BindAction(
		"DeadAirFlashlight",
		onToggle,
		true,
		Enum.KeyCode.F,
		Enum.KeyCode.ButtonY
	)
	ContextActionService:SetTitle("DeadAirFlashlight", "Light")
	ContextActionService:SetPosition("DeadAirFlashlight", UDim2.new(1, -100, 1, -230))
end

return FlashlightController
