--!strict
-- The Engineer's body: how it looks, built from parts. The brain (MonsterService) only needs what
-- build() returns, so the look can change freely as long as these stay true:
--   * the model is named "Monster", with an invisible, solid HumanoidRootPart of 2 x 2 x 1;
--   * every other part is welded to that root, non-solid (CanCollide off) and Massless;
--   * the Humanoid keeps HipHeight 3 (its root floats 4 studs above the floor) and the settings below;
--   * the earcup lights are returned, so it can make them flare when it lunges.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PrefabLibrary = require(script.Parent.Parent.PrefabLibrary)
local ArticulatedEngineer = require(script.Parent.ArticulatedEngineer)
local SkinnedEngineer = require(script.Parent.SkinnedEngineer)

local M = Config.MONSTER

local EngineerModel = {}

local function weld(part: BasePart, to: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
end

-- A tall, gaunt figure with studio headphones grown into its skull. Placeholder shapes for now.
-- Returns the model, its Humanoid, its root part and the earcup lights (they flare when it lunges).
function EngineerModel.build(position: Vector3): (Model, Humanoid, BasePart, { PointLight })
	local m = Instance.new("Model")
	m.Name = "Monster"
	m:SetAttribute("MonsterName", "The Engineer")
	local glows: { PointLight } = {}

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.CFrame = CFrame.new(position)
	hrp.Parent = m
	m.PrimaryPart = hrp


	local skin = Color3.fromRGB(38, 37, 36)
	local bone = Color3.fromRGB(75, 70, 64)
	local cloth = Color3.fromRGB(27, 32, 34)
	local oxide = Color3.fromRGB(64, 49, 44)
	local iron = Color3.fromRGB(33, 36, 38)
	local rubber = Color3.fromRGB(18, 20, 21)

	-- Relative to HRP, which already rides four studs above the floor. Every piece belongs to
	-- the same rigid assembly; no separate solid obstacles are introduced for pathfinding.
	local function piece(
		name: string, size: Vector3, offset: Vector3, color: Color3,
		material: Enum.Material?, rotation: CFrame?, shape: Enum.PartType?
	): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = hrp.CFrame * CFrame.new(offset) * (rotation or CFrame.identity)
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CastShadow = true
		if shape then
			p.Shape = shape
		end
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = m
		weld(p, hrp)
		return p
	end

	-- Unnaturally thin shoulders and an old maintenance coat. The shoulder-line reads from far
	-- away under a torch beam; the inset waist makes the silhouette distinctly non-player.
	piece("NarrowChest", Vector3.new(1.85, 3.25, 0.8), Vector3.new(0, 0.75, 0), skin)
	piece("ShoulderYoke", Vector3.new(2.5, 0.32, 0.75), Vector3.new(0, 2.22, 0), cloth, Enum.Material.Fabric)
	piece("HollowWaist", Vector3.new(1.15, 1.1, 0.66), Vector3.new(0, -1.35, 0), skin)
	piece("WorkApron", Vector3.new(1.56, 2.2, 0.1), Vector3.new(0, -1.24, -0.48), cloth, Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		-- Angled upper arms, pipe-like wrists, oversized hooked hands.
		piece("Shoulder", Vector3.new(0.65, 0.75, 0.8), Vector3.new(side * 1.37, 1.7, 0), cloth)
		piece("UpperArm", Vector3.new(0.47, 2.3, 0.52), Vector3.new(side * 1.58, 0.55, 0.03),
			cloth, Enum.Material.Fabric, CFrame.Angles(0, 0, math.rad(side * 9)))
		piece("ExposedForearm", Vector3.new(0.33, 2.0, 0.36), Vector3.new(side * 1.86, -1.56, -0.05),
			bone, Enum.Material.Metal, CFrame.Angles(0, 0, math.rad(side * -7)))
		piece("WristBinding", Vector3.new(0.47, 0.19, 0.48), Vector3.new(side * 1.93, -2.29, -0.1), oxide, Enum.Material.Metal)
		piece("Palm", Vector3.new(0.39, 0.65, 0.22), Vector3.new(side * 1.98, -2.72, -0.2), skin)
		for finger = -1, 1 do
			piece("HookFinger", Vector3.new(0.09, 0.6, 0.1),
				Vector3.new(side * 1.98 + finger * 0.14, -3.17, -0.25), bone, Enum.Material.Metal)
		end
		-- Leg rigging hangs below the narrow waist; foot tips reach the floor at the default hip.
		piece("Thigh", Vector3.new(0.63, 2.2, 0.65), Vector3.new(side * 0.54, -2.2, 0), cloth, Enum.Material.Fabric)
		piece("KneeJoint", Vector3.new(0.7, 0.55, 0.68), Vector3.new(side * 0.54, -3.12, -0.06), iron, Enum.Material.Metal)
		piece("Shin", Vector3.new(0.41, 1.85, 0.44), Vector3.new(side * 0.62, -3.9, 0), skin)
		piece("LongShoe", Vector3.new(0.62, 0.35, 1.15), Vector3.new(side * 0.62, -4.56, -0.31),
			iron, Enum.Material.Metal)
	end

	-- Thin spine and improvised audio cabling. Loops run diagonally over the coat rather
	-- than presenting a human uniform: the recording hardware seems embedded in the body.
	piece("SpineHousing", Vector3.new(0.42, 3.0, 0.38), Vector3.new(0, 0.72, 0.49), iron, Enum.Material.Metal)
	for rib = 1, 5 do
		local y = 1.6 - rib * 0.55
		piece("ChestRib", Vector3.new(1.44 - rib * 0.11, 0.14, 0.11),
			Vector3.new(0, y, -0.48), bone, Enum.Material.Metal)
	end
	for _, side in { -1, 1 } do
		piece("CableRun", Vector3.new(0.1, 2.35, 0.1),
			Vector3.new(side * 0.66, 0.2, -0.52), oxide,
			Enum.Material.Metal, CFrame.Angles(0, 0, math.rad(side * 15)))
	end
	piece("ChestMeterCase", Vector3.new(0.72, 0.85, 0.22), Vector3.new(0.12, 0.45, -0.6), iron, Enum.Material.Metal)
	piece("ChestMeterDial", Vector3.new(0.47, 0.48, 0.05), Vector3.new(0.12, 0.51, -0.75), bone, Enum.Material.Metal)
	piece("DialNeedle", Vector3.new(0.05, 0.35, 0.06), Vector3.new(0.22, 0.53, -0.81), Color3.fromRGB(159, 40, 32))
	-- VF06 procedural silhouette repair. These three readable, inert elements
	-- are hidden automatically whenever imported/skinned art takes precedence.
	-- They have no emitter, prompt, sound or contact/hit registration.
	piece("HarnessInsulator",Vector3.new(.29,.88,.15),
		Vector3.new(-.57,.93,-.62),rubber,Enum.Material.SmoothPlastic)
	piece("HarnessAnchor",Vector3.new(.36,.13,.19),
		Vector3.new(-.57,.45,-.68),bone,Enum.Material.Metal)
	piece("TornCoatHem",Vector3.new(.62,.83,.16),
		Vector3.new(.58,-2.20,-.43),cloth,Enum.Material.Fabric,
		CFrame.Angles(0,0,math.rad(-12)))

	-- A high, awkward neck and bare skull. Headphones are fused with the head: metal bolts
	-- pierce the temples and earcups, with a corroded hinge and a broken microphone boom.
	piece("Neck", Vector3.new(0.55, 1.1, 0.52), Vector3.new(0, 2.68, 0), skin)
	local head = piece("Head", Vector3.new(1.35, 1.85, 1.22),
		Vector3.new(0, 3.74, -0.08), bone, Enum.Material.SmoothPlastic)
	piece("CheekJaw", Vector3.new(0.95, 0.42, 0.85), Vector3.new(0, 3.12, -0.23), skin)
	piece("ForeheadPlate", Vector3.new(1.12, 0.47, 0.23), Vector3.new(0, 4.32, -0.62), oxide, Enum.Material.Metal)
	for _, side in { -1, 1 } do
		piece("EmptyEyeSocket", Vector3.new(0.37, 0.22, 0.09),
			Vector3.new(side * 0.29, 3.91, -0.703), rubber)
	end
	piece("SealedMouth", Vector3.new(0.61, 0.08, 0.08), Vector3.new(0, 3.38, -0.69), rubber)
	-- Arc-shaped headband uses short tangential strips so it reads as worn studio hardware.
	for i = -3, 3 do
		local a = i * 0.34
		piece("HeadbandSection", Vector3.new(0.33, 0.17, 0.43),
			Vector3.new(math.sin(a) * 0.9, 4.78 + math.cos(a) * 0.24, -0.06),
			iron, Enum.Material.Metal, CFrame.Angles(0, 0, a))
	end
	for _, side in { -1, 1 } do
		piece("HeadphoneYoke", Vector3.new(0.18, 0.92, 0.32),
			Vector3.new(side * 0.94, 4.13, -0.08), oxide, Enum.Material.Metal)
		local cup = piece("Earcup", Vector3.new(0.48, 1.2, 1.06),
			Vector3.new(side * 1.07, 3.66, -0.08), iron, Enum.Material.Metal)
		piece("EarcupGrille", Vector3.new(0.12, 0.81, 0.77),
			Vector3.new(side * 1.35, 3.66, -0.08), rubber, Enum.Material.Metal)
		for j = -2, 2 do
			piece("EarcupSlot", Vector3.new(0.14, 0.05, 0.58),
				Vector3.new(side * 1.43, 3.66 + j * 0.135, -0.08), oxide, Enum.Material.Metal)
		end
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 40, 30)
		glow.Brightness = 0.8
		glow.Range = 7
		glow.Shadows = false
		glow.Parent = cup
		table.insert(glows, glow)
	end
	piece("BrokenBoomArm", Vector3.new(0.08, 0.09, 1.1),
		Vector3.new(-1.3, 3.29, -0.59), iron, Enum.Material.Metal,
		CFrame.Angles(0, math.rad(25), 0))
	piece("BoomCapsule", Vector3.new(0.23, 0.23, 0.31),
		Vector3.new(-1.34, 3.27, -1.2), rubber, Enum.Material.Metal)

	-- Imported headset lives on the same rigid HRP. The original earcup attachments
	-- remain present (and hold exactly two gameplay-controlled red PointLights).
	-- The segmented imported rig already incorporates its own moving headset.
	local skinnedReady=SkinnedEngineer.ready()
	local segmentedReady=not skinnedReady and ArticulatedEngineer.ready()
	if not skinnedReady and not segmentedReady and PrefabLibrary.attach(hrp,"EngineerHeadset",CFrame.new(0,3.7,-0.08)) then
		local replaceable = {
			HeadbandSection = true,
			HeadphoneYoke = true,
			Earcup = true,
			EarcupGrille = true,
			EarcupSlot = true,
			BrokenBoomArm = true,
			BoomCapsule = true,
		}
		for _,child in m:GetChildren() do
			if child:IsA("BasePart") and replaceable[child.Name] then
				child.Transparency = 1
			end
		end
	end
	-- Studio-imported full-body sculpt is visual-only. Keep the original welded
	-- humanoid body as a collision/behavior fallback; when the sculpt exists,
	-- hide its primitive forms but RETAIN the two earcup PointLights that the
	-- monster's lunge/audio state machine controls.
	if skinnedReady and SkinnedEngineer.mount(m,hrp,glows) then
		local hidden=0
		for _,child in m:GetChildren() do
			if child:IsA("BasePart") and child~=hrp then
				child.Transparency=1
				child.CastShadow=false
				hidden+=1
			end
		end
		m:SetAttribute("HiddenFallbackPieces",hidden)
	elseif segmentedReady and ArticulatedEngineer.mount(m,hrp,glows) then
		local hidden=0
		for _,child in m:GetChildren() do
			if child:IsA("BasePart") and child~=hrp
				and child:GetAttribute("EngineerRigBone")~=true
				and child.Name~="EarcupLightHost" then
				child.Transparency=1
				child.CastShadow=false
				hidden+=1
			end
		end
		m:SetAttribute("HiddenFallbackPieces",hidden)
	elseif PrefabLibrary.attach(hrp,"EngineerBody",CFrame.identity) then
		local hidden=0
		for _,child in m:GetChildren() do
			if child:IsA("BasePart") and child~=hrp then
				child.Transparency=1
				child.CastShadow=false
				hidden+=1
			end
		end
		m:SetAttribute("CharacterVisualTier","ImportedBodyPrototype")
		m:SetAttribute("HiddenFallbackPieces",hidden)
	else
		m:SetAttribute("CharacterVisualTier","ProceduralFallback")
	end

	head:SetAttribute("Blind", true)

	local h = Instance.new("Humanoid")
	h.RigType = Enum.HumanoidRigType.R15
	h.HipHeight = 3
	h.WalkSpeed = M.ROAM_SPEED
	h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	h.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	h:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	h:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	h.Parent = m

	m.Parent = Workspace
	hrp:SetNetworkOwner(nil) -- the server moves it, not a nearby player's client
	return m, h, hrp, glows
end

return EngineerModel
