--!strict
-- Physical studio flight cases. Carefully authored rigid body + independent
-- HingeConstraint wheels. These are genuine Roblox simulated assemblies:
-- players can shove them, they collide with the room, and their wheels turn.
-- Only two cases are dynamic, away from primary escape routes.
--
-- No fake CFrame-loop movement, arbitrary random clutter or client-only
-- physics. A real non-anchored case is gameplay-neutral equipment; objective
-- RoadCase remains static and authoritative.
local Workspace = game:GetService("Workspace")
local Kit = require(script.Parent.StudioDecorKit)

local PhysicalAssets = {}

local W = Color3.fromRGB(45, 51, 53)
local RIM = Color3.fromRGB(112, 119, 120)
local EDGE = Color3.fromRGB(163, 166, 157)
local PANEL = Color3.fromRGB(69, 77, 81)
local RUBBER = Color3.fromRGB(35, 37, 37)
local LABEL = Color3.fromRGB(190, 173, 132)

-- Exact visual geometry around one physically accurate colliding body.
local function detail(
	model: Model, root: BasePart, name: string, at: CFrame,
	size: Vector3, color: Color3, material: Enum.Material, fixed: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = at
	p.Color = color
	p.Material = material
	p.Anchored = fixed == true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	if not fixed then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = p
		weld.Parent = p
	end
	return p
end

-- Creates an optional, noncolliding readable side label. On static decor,
-- every child stays fixed; on moving props the printed panel is welded.
local function emboss(model: Model, body: BasePart, base: CFrame, name: string, fixed: boolean)
	for _, side in { -1, 1 } do
		local face = detail(model, body, name .. "SidePanel", base * CFrame.new(
			side * (body.Size.X / 2 + 0.025), 0, 0),
			Vector3.new(0.06, body.Size.Y * 0.74, body.Size.Z * 0.75), PANEL,
			Enum.Material.Metal, fixed)
		face.Transparency = 0.12
		-- Handle bars are not collision hulls; the body handles physics.
		local handle = detail(model, body, name .. "Handle",
			base * CFrame.new(side * (body.Size.X / 2 + 0.12), 0.16, 0),
			Vector3.new(0.15, 0.20, math.min(1.1, body.Size.Z * 0.37)),
			EDGE, Enum.Material.Metal, fixed)
		handle.Shape = Enum.PartType.Block
	end
	local metal = Enum.Material.Metal
	-- Continuous metal edge extrusions, rather than disconnected decals.
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			detail(model, body, name .. "CornerVertical",
				base * CFrame.new(sx * (body.Size.X / 2 - 0.11), 0,
				sy * (body.Size.Z / 2 - 0.11)),
				Vector3.new(0.19, body.Size.Y + 0.09, 0.19), RIM, metal, fixed)
		end
	end
	for _, sy in { -1, 1 } do
		for _, sz in { -1, 1 } do
			detail(model, body, name .. "EdgeHorizontal", base * CFrame.new(
				0, sy * (body.Size.Y / 2 - 0.13),
				sz * (body.Size.Z / 2 - 0.08)),
				Vector3.new(body.Size.X - 0.2, 0.17, 0.18),
				EDGE, metal, fixed)
		end
	end
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			detail(model, body, name .. "SideEdge",
				base * CFrame.new(sx * (body.Size.X / 2 - 0.1),
				sy * (body.Size.Y / 2 - 0.13), 0),
				Vector3.new(0.17, 0.17, body.Size.Z - 0.2),
				EDGE, metal, fixed)
		end
	end
	local mainPlate = detail(model, body, name .. "CaseLabel",
		base * CFrame.new(0, 0.18, -body.Size.Z / 2 - 0.035),
		Vector3.new(body.Size.X * 0.54, 0.42, 0.045), LABEL,
		Enum.Material.SmoothPlastic, fixed)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "CasePrint"
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0.3
	gui.Parent = mainPlate
	local text = Instance.new("TextLabel")
	text.Name = "ID"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.Code
	text.Text = "WRENMOUTH  /  " .. name
	text.TextScaled = true
	text.TextColor3 = RUBBER
	text.Parent = gui
end

-- Dynamic wheeled flight case: body is collidable, four individual rolling
-- wheels are collidable; small metal details do not multiply collision cost.
function PhysicalAssets.roadCase(parent: Instance, name: string, x: number, z: number, yaw: number): Model
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("PhysicalAsset", "WheeledFlightCase")
	model:SetAttribute("PhysicsVersion", 1)
	model.Parent = parent
	local basis = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	local center = basis * CFrame.new(0, 1.78, 0)
	local root = Instance.new("Part")
	root.Name = "CaseBodyCollider"
	root.Size = Vector3.new(4.4, 2.7, 3.1)
	root.CFrame = center
	root.Material = Enum.Material.Metal
	root.Color = W
	root.Anchored = true -- released after the map is under Workspace
	root.CanCollide = true
	root.CanQuery = true
	root.CanTouch = false
	root.RootPriority = 127
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.68, 0.06, 90, 100)
	root.Parent = model
	model.PrimaryPart = root
	emboss(model, root, center, name, false)
	local wheels: { BasePart } = {}
	for _, dx in { -1.7, 1.7 } do
		for _, dz in { -1.17, 1.17 } do
			-- Cylinder's long axis is X. Hinges spin around that same axis,
			-- so the cases roll along local Z when shoved by a player.
			local wheel = Instance.new("Part")
			wheel.Name = "RollingCaster"
			wheel.Shape = Enum.PartType.Cylinder
			wheel.Size = Vector3.new(0.41, 0.98, 0.98)
			wheel.CFrame = basis * CFrame.new(dx, 0.53, dz)
			wheel.Material = Enum.Material.Rubber
			wheel.Color = RUBBER
			wheel.Anchored = true
			wheel.CanCollide = true
			wheel.CanQuery = true
			wheel.CanTouch = false
			wheel.CustomPhysicalProperties = PhysicalProperties.new(0.45, 0.95, 0.05, 90, 90)
			wheel.Parent = model
			local hub = Instance.new("Attachment")
			hub.Name = "ChassisAxle"
			hub.Position = Vector3.new(dx, -1.25, dz)
			hub.Parent = root
			local axle = Instance.new("Attachment")
			axle.Name = "WheelAxle"
			axle.Parent = wheel
			local hinge = Instance.new("HingeConstraint")
			hinge.Name = "RollingAxle"
			hinge.Attachment0 = hub
			hinge.Attachment1 = axle
			hinge.Parent = wheel
			table.insert(wheels, wheel)
		end
	end
	task.defer(function()
		if not model.Parent then return end
		-- A world assembly cannot be simulated or assigned network ownership
		-- before StudioGroundFloor has inserted Map into Workspace.
		local deadline = os.clock() + 4
		while model.Parent and not model:IsDescendantOf(Workspace) and os.clock() < deadline do
			task.wait()
		end
		if not model:IsDescendantOf(Workspace) then return end
		for _, wheel in wheels do wheel.Anchored = false end
		root.Anchored = false
		local candidates: { BasePart } = { root }
		for _, wheel in wheels do table.insert(candidates, wheel) end
		for _, body in candidates do
			local permitted = body:CanSetNetworkOwnership()
			if permitted then body:SetNetworkOwner(nil) end
		end
	end)
	return model
end

-- Chapter-critical RoadCase objective remains anchored and accessible to
-- prompts, but receives realistic latches and reinforced flight-case trim.
function PhysicalAssets.finishObjectiveRoadCase(parent: Instance, body: BasePart)
	local existing = parent:FindFirstChild("RoadCaseFurniture")
	if existing then existing:Destroy() end
	local model = Instance.new("Model")
	model.Name = "RoadCaseFurniture"
	model:SetAttribute("AssetVersion", 1)
	model.Parent = parent
	emboss(model, body, body.CFrame, "SESSION 04", true)
	for _, dx in { -body.Size.X * 0.28, body.Size.X * 0.28 } do
		local latch = detail(model, body, "Latch", body.CFrame
			* CFrame.new(dx, body.Size.Y * 0.18, -body.Size.Z / 2 - 0.055),
			Vector3.new(0.40, 0.48, 0.16), RIM, Enum.Material.Metal, true)
		latch.CanQuery = false
	end
end

return PhysicalAssets
