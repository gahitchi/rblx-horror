--!strict
-- Low-cost silhouette vista beyond the fence. This cannot be reached by players:
-- distant buildings communicate which chapters have been recovered.
local Vista = {}
local night = Color3.fromRGB(15, 26, 34)
local slate = Color3.fromRGB(34, 46, 56)
local roof = Color3.fromRGB(23, 34, 42)
local window = Color3.fromRGB(135, 155, 164)
local pale = Color3.fromRGB(201, 219, 230)
local sea = Color3.fromRGB(13, 28, 40)
local stone = Color3.fromRGB(53, 63, 67)

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function p(parent: Instance, name: string, x: number, y: number, z: number,
	w: number, h: number, d: number, color: Color3,
	material: Enum.Material?, transparent: number?): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = Vector3.new(w, h, d)
	item.CFrame = CFrame.new(x, y, z)
	item.Color = color
	item.Anchored = true
	item.CanCollide = false
	item.CanTouch = false
	item.CanQuery = false
	item.CastShadow = false
	item.Material = material or Enum.Material.SmoothPlastic
	item.Transparency = transparent or 0
	item.Parent = parent
	return item
end

local function roofline(parent: Instance, x: number, y: number, z: number,
	width: number, length: number, height: number)
	local left = p(parent, "SaltWindRoof", x - width / 4, y + height / 2, z,
		width / 2 + 0.6, 0.55, length + 1.3, roof, Enum.Material.Slate)
	left.CFrame = CFrame.new(left.Position) * CFrame.Angles(0, 0, math.rad(27))
	local right = p(parent, "SaltWindRoof", x + width / 4, y + height / 2, z,
		width / 2 + 0.6, 0.55, length + 1.3, roof, Enum.Material.Slate)
	right.CFrame = CFrame.new(right.Position) * CFrame.Angles(0, 0, math.rad(-27))
end

local function townWindow(parent: Folder, id: string, pos: Vector3, size: Vector3): Part
	local panel = p(parent, id, pos.X, pos.Y, pos.Z,
		size.X, size.Y, size.Z, slate, Enum.Material.Glass)
	local glow = Instance.new("PointLight")
	glow.Name = "ChapterWindow"
	glow.Enabled = false
	glow.Brightness = 1.1
	glow.Range = 23
	glow.Color = Color3.fromRGB(232, 162, 74)
	glow.Shadows = false
	glow.Parent = panel
	panel:SetAttribute("ProgressLight", true)
	return panel
end

local function house(parent: Instance, x: number, z: number,
	w: number, d: number, h: number, base: number)
	p(parent, "WrenmouthHouse", x, base + h / 2, z,
		w, h, d, slate, Enum.Material.Concrete)
	roofline(parent, x, base + h, z, w, d, math.min(4, h / 4))
	for _, side in { -1, 1 } do
		p(parent, "BlindWindow", x - w / 3, base + 0.65 * h,
			z + side * (d / 2 + 0.12), 1.65, 2.3, 0.19, window, Enum.Material.Glass, 0.73)
		p(parent, "BlindWindow", x + w / 3, base + 0.65 * h,
			z + side * (d / 2 + 0.12), 1.65, 2.3, 0.19, window, Enum.Material.Glass, 0.73)
	end
	p(parent, "Chimney", x + w / 3, base + h + 4, z - d / 3,
		2.2, 8, 2.2, roof, Enum.Material.Brick)
end

local function vistaLand(vista: Folder)
	-- Below a cliff road that falls into the town. Hilltops float above the sea.
	p(vista, "TownHeadland", 158, -34, -3, 145, 12, 112,
		stone, Enum.Material.Rock)
	p(vista, "HillBehindRadio", 194, -21, 2, 44, 30, 52,
		stone, Enum.Material.Slate)
	p(vista, "CanneryQuay", 160, -32, 47, 71, 5, 19,
		night, Enum.Material.Concrete)
	for _, row in {
		{ x = 112, z = -26, w = 15, d = 14, h = 16 },
		{ x = 130, z = 20, w = 14, d = 16, h = 20 },
		{ x = 152, z = -14, w = 16, d = 16, h = 14 },
		{ x = 170, z = 16, w = 17, d = 15, h = 19 },
		{ x = 183, z = 33, w = 14, d = 17, h = 14 },
		{ x = 204, z = 25, w = 18, d = 18, h = 18 },
	} do
		house(vista, row.x, row.z, row.w, row.d, row.h, -27)
	end
	-- Studio: broad two-storey building with one roofline. The basement is below.
	p(vista, "StudioBlock", 112, -20, -2, 28, 21, 28, slate, Enum.Material.Concrete)
	roofline(vista, 112, -8.6, -2, 29, 28, 5)
	p(vista, "StudioControlWindow", 109, -17.5, -16.2,
		11, 3.4, 0.22, window, Enum.Material.Glass, 0.62)
	-- Cannery: three distinct sawtooth industrial roofs and a tall stack.
	for _, x in { 142, 157, 172 } do
		p(vista, "CanneryShed", x, -18, 45, 14, 15, 22,
			slate, Enum.Material.Metal)
		roofline(vista, x, -10, 45, 14, 21, 2.7)
	end
	p(vista, "CannerySmokestack", 181, -4, 51, 3.2, 47, 3.2,
		roof, Enum.Material.Brick)
	-- Listening station: the low bunker on the headland, separated from the town.
	p(vista, "NavyListeningStation", 189, -23, -44, 24, 10, 18,
		roof, Enum.Material.Concrete)
	for _, x in { 183, 193 } do
		p(vista, "BunkerSlit", x, -22, -53.2, 4, 0.65, 0.16,
			pale, Enum.Material.Glass, 0.75)
	end
	-- Radio station's high mast on the hill and two guy-wires.
	p(vista, "RadioHillBuilding", 203, -1.5, 0, 20, 15, 13,
		slate, Enum.Material.Concrete)
	local mast = p(vista, "BroadcastMast", 208, 26, 3,
		1, 49, 1, window, Enum.Material.Metal)
	for _, dx in { -13, 13 } do
		local wire = p(vista, "GuyWire", 208 + dx / 2, 15, 3,
			0.11, 29, 0.1, window, Enum.Material.Metal, 0.2)
		wire.CFrame = CFrame.new(wire.Position) * CFrame.Angles(0, 0,
			math.rad(if dx > 0 then 20 else -20))
	end
	-- The Choir is only a suggestion of pale vertical fog.
	for _, offset in { -8, -2, 6, 14 } do
		p(vista, "AlmostInvisibleChoir", 155 + offset, 45, 35,
			2.8, 53 + offset / 2, 1.7, pale, Enum.Material.Neon, 0.975)
	end
end

local function lighthouse(parent: Folder)
	-- A classic two-band lighthouse across the bay; beam driven by a tiny server loop.
	p(parent, "HeadlandUnderLighthouse", 159, -30, -107, 45, 18, 42,
		stone, Enum.Material.Rock)
	local tower = p(parent, "LighthouseTower", 160, -12, -108,
		38, 11, 11, Color3.fromRGB(209, 210, 197), Enum.Material.Concrete)
	tower.Shape = Enum.PartType.Cylinder
	tower.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	for _, y in { -21, -8 } do
		local stripe = p(parent, "LighthouseRedBand", 160, y, -108,
			3.1, 11.4, 11.4, Color3.fromRGB(145, 66, 55),
			Enum.Material.Concrete)
		stripe.Shape = Enum.PartType.Cylinder
		stripe.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	end
	local gallery = p(parent, "LighthouseGallery", 160, 8, -108,
		1.1, 16.5, 16.5, roof, Enum.Material.Metal)
	gallery.Shape = Enum.PartType.Cylinder
	gallery.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	local lantern = p(parent, "LighthouseLampHouse", 160, 11.2, -108,
		6.2, 9.8, 9.8, window, Enum.Material.Glass, 0.6)
	lantern.Shape = Enum.PartType.Cylinder
	lantern.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	local beacon = p(parent, "SweepingLighthouseBeacon", 160, 11.3, -108,
		2.3, 2.3, 2.3, pale, Enum.Material.Neon)
	beacon.Shape = Enum.PartType.Ball
	local beam = Instance.new("SpotLight")
	beam.Name = "LighthouseBeam"
	beam.Face = Enum.NormalId.Front
	beam.Angle = 28
	beam.Range = 110
	beam.Brightness = 2.1
	beam.Shadows = false
	beam.Color = pale
	beam.Parent = beacon
	local cap = p(parent, "BeaconCap", 160, 15.3, -108,
		2.0, 13, 13, roof, Enum.Material.Metal)
	cap.Shape = Enum.PartType.Cylinder
	cap.CFrame *= CFrame.Angles(0, 0, math.rad(90))
end

function Vista.build(hub: Model)
	local vista = folder(hub, "DistantWrenmouth")
	local lights = folder(hub, "TownLights")
	vistaLand(vista)
	lighthouse(vista)
	-- Position progress lights on the silhouettes visible from the cliff:
	-- client switches these *locally*, based on its own progress save.
	townWindow(lights, "studio1", Vector3.new(111, -16, -16.35),
		Vector3.new(3, 3.7, 0.18))
	townWindow(lights, "studio2", Vector3.new(117, -16, -16.35),
		Vector3.new(3, 3.7, 0.18))
	townWindow(lights, "studio3", Vector3.new(111, -9.8, -16.35),
		Vector3.new(3, 2.6, 0.18))
	townWindow(lights, "radio1", Vector3.new(199, 0, -6.75),
		Vector3.new(3, 4, 0.18))
	townWindow(lights, "sonar1", Vector3.new(190, -21, -53.25),
		Vector3.new(5.2, 1.8, 0.18))
	local mast = townWindow(lights, "RadioMast", Vector3.new(208, 51.5, 3),
		Vector3.new(2, 2, 2))
	mast.Shape = Enum.PartType.Ball
	mast.Color = night
	-- Chapter-three progress gets to reveal the mast's red warning light.
	local bulb = mast:FindFirstChildOfClass("PointLight")
	if bulb then
		bulb.Color = Color3.fromRGB(186, 53, 48)
	end
end

return Vista
