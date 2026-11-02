--!strict
-- Compact, untextured 1987 studio dressing primitives.
-- Decorative pieces do not collide or block rays: only deliberately large furniture
-- blocks navigation. This protects mobile movement, acoustic occlusion and patrol spots.
local Kit = {}

Kit.palette = {
	wood = Color3.fromRGB(102, 71, 51),
	woodLight = Color3.fromRGB(158, 116, 79),
	leather = Color3.fromRGB(82, 57, 48),
	foam = Color3.fromRGB(92, 64, 56),
	fabric = Color3.fromRGB(55, 104, 105),
	teal = Color3.fromRGB(46, 105, 111),
	cream = Color3.fromRGB(217, 196, 158),
	gold = Color3.fromRGB(202, 159, 79),
	metal = Color3.fromRGB(78, 87, 89),
	steel = Color3.fromRGB(116, 126, 128),
	dark = Color3.fromRGB(32, 38, 41),
	black = Color3.fromRGB(23, 26, 29),
	paper = Color3.fromRGB(222, 202, 161),
	green = Color3.fromRGB(66, 113, 85),
	amber = Color3.fromRGB(255, 181, 79),
	red = Color3.fromRGB(172, 51, 48),
	glass = Color3.fromRGB(123, 168, 166),
}

function Kit.group(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function Kit.block(
	parent: Instance, name: string, cf: CFrame, size: Vector3,
	color: Color3, material: Enum.Material?, solid: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = solid == true
	p.CanQuery = solid == true
	p.CanTouch = false
	p.CastShadow = solid == true or size.Magnitude > 6
	p.Parent = parent
	return p
end

function Kit.box(
	parent: Instance, name: string, x: number, y: number, z: number,
	w: number, h: number, d: number, color: Color3, material: Enum.Material?, solid: boolean?
): Part
	return Kit.block(parent, name, CFrame.new(x, y, z), Vector3.new(w, h, d), color, material, solid)
end

function Kit.rod(
	parent: Instance, name: string, from: Vector3, to: Vector3,
	radius: number, color: Color3
): Part
	local mid = (from + to) / 2
	return Kit.block(parent, name, CFrame.lookAt(mid, to),
		Vector3.new(radius, radius, (to - from).Magnitude), color, Enum.Material.Metal)
end

function Kit.disc(
	parent: Instance, name: string, x: number, y: number, z: number,
	diameter: number, thickness: number, color: Color3
): Part
	local p = Kit.block(parent, name,
		CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(90), 0),
		Vector3.new(thickness, diameter, diameter), color, Enum.Material.Metal)
	p.Shape = Enum.PartType.Cylinder
	return p
end

function Kit.sign(
	parent: Instance, caption: string, cf: CFrame, size: Vector3,
	face: Enum.NormalId?, ink: Color3?, background: Color3?
): Part
	local plaque = Kit.block(parent, "Sign_" .. caption, cf, size,
		background or Kit.palette.dark, Enum.Material.SmoothPlastic)
	local ui = Instance.new("SurfaceGui")
	ui.Name = "PrintedSign"
	ui.Face = face or Enum.NormalId.Front
	ui.PixelsPerStud = 28
	ui.LightInfluence = 0.15
	ui.Parent = plaque
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = caption
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.TextColor3 = ink or Kit.palette.cream
	t.TextStrokeTransparency = 0.75
	t.Parent = ui
	return plaque
end

function Kit.stripe(
	parent: Instance, x: number, y: number, z: number,
	width: number, color: Color3
)
	Kit.box(parent, "InlaidTrim", x, y, z, width, 0.08, 0.12, color, Enum.Material.Metal)
end

function Kit.table(
	parent: Instance, name: string, x: number, z: number,
	w: number, d: number, h: number, topColor: Color3
)
	local c = Kit.palette
	Kit.box(parent, name .. "Top", x, h, z, w, 0.32, d, topColor, Enum.Material.Wood, true)
	for _, dx in { -w / 2 + 0.5, w / 2 - 0.5 } do
		for _, dz in { -d / 2 + 0.5, d / 2 - 0.5 } do
			Kit.box(parent, name .. "Leg", x + dx, h / 2, z + dz,
				0.45, h - 0.3, 0.45, c.metal, Enum.Material.Metal)
		end
	end
end

function Kit.chair(parent: Instance, x: number, z: number, yaw: number, fabric: Color3?)
	local c = Kit.palette
	local basis = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	Kit.block(parent, "StudioChairSeat", basis * CFrame.new(0, 2, 0),
		Vector3.new(2.9, 0.4, 2.8), fabric or c.leather, Enum.Material.Fabric)
	Kit.block(parent, "StudioChairBack", basis * CFrame.new(0, 3.5, 1.25),
		Vector3.new(2.9, 2.8, 0.4), fabric or c.leather, Enum.Material.Fabric)
	Kit.block(parent, "ChairStem", basis * CFrame.new(0, 1, 0),
		Vector3.new(0.35, 1.7, 0.35), c.metal, Enum.Material.Metal)
	for _, dx in { -1, 1 } do
		Kit.block(parent, "ChairFoot", basis * CFrame.new(dx * 0.85, 0.18, 0),
			Vector3.new(1.8, 0.25, 0.35), c.dark, Enum.Material.Metal)
	end
end

function Kit.rack(
	parent: Instance, name: string, x: number, z: number,
	width: number, height: number, yaw: number
)
	local c = Kit.palette
	local basis = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	Kit.block(parent, name .. "Body", basis * CFrame.new(0, height / 2, 0),
		Vector3.new(width, height, 1.75), c.black, Enum.Material.Metal, true)
	Kit.block(parent, "RackFace", basis * CFrame.new(0, height / 2, -0.9),
		Vector3.new(width - 0.35, height - 0.4, 0.12), c.metal, Enum.Material.Metal)
	for j = 1, math.floor((height - 0.5) / 1.1) do
		local y = 0.28 + j * 1.05
		Kit.block(parent, "RackUnit", basis * CFrame.new(0, y, -0.99),
			Vector3.new(width - 0.5, 0.77, 0.09), c.dark, Enum.Material.Metal)
		for i = 1, 3 do
			Kit.block(parent, "RackIndicator", basis * CFrame.new(-width / 2 + 0.4 + i * 0.28, y, -1.06),
				Vector3.new(0.09, 0.12, 0.07), if i == 1 then c.amber else c.green, Enum.Material.Neon)
		end
	end
end

function Kit.sofa(parent: Instance, x: number, z: number, width: number, yaw: number)
	local c = Kit.palette
	local basis = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	Kit.block(parent, "SofaBase", basis * CFrame.new(0, 1.1, 0),
		Vector3.new(width, 1.6, 3.2), c.wood, Enum.Material.Wood, true)
	Kit.block(parent, "SofaCushion", basis * CFrame.new(0, 2, -0.35),
		Vector3.new(width - 0.6, 0.55, 2.3), c.leather, Enum.Material.Fabric)
	Kit.block(parent, "SofaBack", basis * CFrame.new(0, 3.1, 1.45),
		Vector3.new(width, 2.9, 0.6), c.leather, Enum.Material.Fabric)
	for _, dx in { -width / 2 + 0.45, width / 2 - 0.45 } do
		Kit.block(parent, "SofaArm", basis * CFrame.new(dx, 2.2, 0),
			Vector3.new(0.8, 2, 3.2), c.wood, Enum.Material.Wood)
	end
end

function Kit.vent(parent: Instance, x: number, y: number, z: number, width: number)
	local c = Kit.palette
	Kit.box(parent, "VentPlate", x, y, z, width, 2.2, 0.2, c.metal, Enum.Material.Metal)
	for i = 1, 4 do
		Kit.box(parent, "VentLouvre", x, y - 0.85 + i * 0.32, z - 0.15,
			width - 0.35, 0.12, 0.12, c.dark, Enum.Material.Metal)
	end
end

function Kit.poster(parent: Instance, caption: string, x: number, y: number, z: number, width: number)
	local c = Kit.palette
	Kit.box(parent, "PosterFrame", x, y, z, width + 0.4, width * 1.3 + 0.4,
		0.16, c.wood, Enum.Material.Wood)
	Kit.sign(parent, caption, CFrame.new(x, y, z - 0.12),
		Vector3.new(width, width * 1.3, 0.1), Enum.NormalId.Front,
		c.dark, c.paper)
end

return Kit
