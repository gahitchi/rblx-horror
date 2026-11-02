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

	local skin = Color3.fromRGB(32, 30, 30)
	local function limb(
		name: string,
		size: Vector3,
		offset: Vector3,
		color: Color3?,
		material: Enum.Material?,
		animated: boolean?,
		attachedTo: BasePart?
	): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = hrp.CFrame * CFrame.new(offset)
		p.Color = color or skin
		p.Material = material or Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.Massless = true
		p.Parent = m
		if animated then
			-- Exposed joints allow believable listening, searching and recoils
			-- without a heavy animation asset; move them from the server.
			local joint = Instance.new("Motor6D")
			joint.Name = name .. "Joint"
			joint.Part0 = hrp
			joint.Part1 = p
			-- Rotate around the neck, shoulder or hip rather than spinning
			-- each part around its midpoint. Neutral pose remains unchanged.
			local pivotY = if name == "Head" then -size.Y * 0.42 else size.Y * 0.45
			joint.C0 = CFrame.new(offset + Vector3.new(0, pivotY, 0))
			joint.C1 = CFrame.new(0, pivotY, 0)
			joint.Parent = hrp
		else
			weld(p, attachedTo or hrp)
		end
		return p
	end

	limb("Torso", Vector3.new(2.2, 3.6, 1.1), Vector3.new(0, 1, 0))
	local head = limb("Head", Vector3.new(1.4, 1.6, 1.4), Vector3.new(0, 3.6, 0), nil, nil, true)
	limb("LeftLeg", Vector3.new(0.7, 4, 0.7), Vector3.new(-0.6, -2, 0), nil, nil, true)
	limb("RightLeg", Vector3.new(0.7, 4, 0.7), Vector3.new(0.6, -2, 0), nil, nil, true)
	limb("LeftArm", Vector3.new(0.5, 4.8, 0.5), Vector3.new(-1.45, 0.4, 0), nil, nil, true)
	limb("RightArm", Vector3.new(0.5, 4.8, 0.5), Vector3.new(1.45, 0.4, 0), nil, nil, true)
	limb(
		"HeadphoneBand",
		Vector3.new(1.9, 0.3, 0.4),
		Vector3.new(0, 4.55, 0),
		Color3.fromRGB(20, 20, 20),
		Enum.Material.Metal,
		false,
		head
	)
	for _, side in { -1, 1 } do
		local cup = limb(
			"Earcup",
			Vector3.new(0.5, 1, 1),
			Vector3.new(side * 0.95, 3.6, 0),
			Color3.fromRGB(18, 18, 18),
			Enum.Material.Metal,
			false,
			head
		)
		-- A faint red glow from the earcups: just enough to glimpse it in the dark.
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 40, 30)
		glow.Brightness = 0.8
		glow.Range = 7
		glow.Parent = cup
		table.insert(glows, glow)
	end
	head:SetAttribute("Blind", true)

	-- Weld the headphone pieces to Head, not the invisible root:
	-- head turns now carry both earcups and the band with them.
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
