--!strict
-- Builds map 1, the recording studio, as a greybox: simple shapes that set the layout, scale and
-- routes before any real art exists. Also builds the lobby. Everything here is placeholder art.
--
-- It builds Workspace.Map exactly as docs/MAP_CONTRACT.md describes, the same way a hand-made map
-- must be laid out, and MapContract reads it. Main only builds this when no hand-made Map exists.
--
-- Layout (ground floor at y = 0, basement at y = -14; x grows east, z grows south):
--   reception (exit doors on its south wall) -> main corridor north -> control rooms A (west) and B (east)
--   -> cross corridor -> live room (north) with three soundproof booths on its west side and the
--   tape archive on its east side; break room off the cross corridor; stairwell down to the basement
--   (generator room and electrical room), plus rear mastering, east service and deep utilities.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapContract = require(script.Parent.MapContract)

-- Kept so code written against the old names (the art pass) still type-checks.
export type Layout = MapContract.Layout
export type Area = MapContract.Area
export type Zone = MapContract.Zone

type Gap = { center: number, width: number, header: boolean? }

local T = 1 -- wall thickness
local H = 12 -- standard room height
local LIVE_H = 20 -- the live room is taller
local DOOR_H = 9
local BASEMENT_Y = -14
local BASEMENT_H = 13
local DOOR_W = 6 -- wide enough for the monster's pathfinding agent with room to spare

local COLORS = table.freeze({
	wall = Color3.fromRGB(88, 84, 80),
	foam = Color3.fromRGB(46, 50, 60),
	carpet = Color3.fromRGB(60, 48, 44),
	tile = Color3.fromRGB(120, 118, 112),
	wood = Color3.fromRGB(104, 76, 52),
	concrete = Color3.fromRGB(78, 78, 80),
	ceiling = Color3.fromRGB(40, 40, 42),
	prop = Color3.fromRGB(58, 56, 54),
	metal = Color3.fromRGB(70, 72, 76),
	door = Color3.fromRGB(92, 66, 46),
	boothDoor = Color3.fromRGB(70, 40, 40),
	fuse = Color3.fromRGB(230, 190, 60),
})

local MapBuilder = {}

-- An invisible helper part for scripts (markers, volumes). MapContract hides them anyway.
local function helper(name: string, cframe: CFrame, size: Vector3, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Parent = parent
	return p
end

local function marker(name: string, position: Vector3, parent: Instance): Part
	return helper(name, CFrame.new(position), Vector3.one, parent)
end

-- One room in Areas: a Bounds box over the room and Spot markers where the monster can stand.
local function area(
	parent: Instance,
	name: string,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	floorY: number,
	spots: { { number } }
)
	local folder = Instance.new("Folder")
	folder.Name = name
	local lo = Vector3.new(math.min(x1, x2), floorY - 2, math.min(z1, z2))
	local hi = Vector3.new(math.max(x1, x2), floorY + 11, math.max(z1, z2))
	helper("Bounds", CFrame.new((lo + hi) / 2), hi - lo, folder)
	for _, spot in spots do
		marker("Spot", Vector3.new(spot[1], floorY + 3, spot[2]), folder)
	end
	folder.Parent = parent
end

-- The rooms as the monster knows them. Spots avoid the props placed in build().
local function buildAreas(parent: Instance)
	local B = BASEMENT_Y
	area(parent, "Reception", -20, 0, 20, 30, 0, { { 0, 15 }, { -14, 22 }, { 14, 8 }, { 0, 4 } })
	area(parent, "Corridor", -5, -60, 5, 0, 0, { { 0, -10 }, { 0, -30 }, { 0, -50 } })
	area(
		parent,
		"ControlA",
		-35,
		-40,
		-5,
		-10,
		0,
		{ { -20, -22 }, { -30, -14 }, { -10, -14 }, { -29, -31 } }
	)
	area(
		parent,
		"ControlB",
		5,
		-40,
		35,
		-10,
		0,
		{ { 20, -22 }, { 30, -14 }, { 10, -14 }, { 29, -31 } }
	)
	area(
		parent,
		"CrossCorridor",
		-60,
		-70,
		60,
		-60,
		0,
		{ { -45, -65 }, { -20, -65 }, { 20, -65 }, { 45, -65 } }
	)
	area(parent, "LiveRoom", -40, -130, 40, -70, 0, {
		{ 0, -80 },
		{ -25, -82 },
		{ 28, -84 },
		{ -32, -100 },
		{ 0, -110 },
		{ 30, -106 },
		{ 0, -123 },
		{ -34, -124 },
		{ 12, -123 },
	})
	area(parent, "Booth1", -55, -130, -40, -110, 0, { { -48, -120 } })
	area(parent, "Booth2", -55, -110, -40, -90, 0, { { -48, -100 } })
	area(parent, "Booth3", -55, -90, -40, -70, 0, { { -48, -80 } })
	area(
		parent,
		"Archive",
		40,
		-130,
		70,
		-70,
		0,
		{ { 55, -76 }, { 55, -87 }, { 55, -102 }, { 55, -117 }, { 55, -127 } }
	)
	area(parent, "BreakRoom", 35, -60, 60, -35, 0, { { 42, -42 }, { 42, -55 }, { 55, -53 } })
	-- The two rear-gallery doors form a safe-looking loop; the vault at its end does not.
	area(parent, "RearGallery", -40, -146, 40, -130, 0, { { -30, -139 }, { 0, -139 }, { 30, -139 } })
	area(parent, "MasteringSuite", -40, -178, -5, -146, 0, { { -30, -152 }, { -30, -170 }, { -12, -165 } })
	area(parent, "NorthSpine", -5, -178, 5, -146, 0, { { 0, -154 }, { 0, -170 } })
	area(parent, "MachineShop", 5, -178, 40, -146, 0, { { 13, -154 }, { 30, -165 }, { 15, -162 } })
	area(parent, "TapeVault", -18, -201, 18, -178, 0, { { 0, -188 }, { -12, -193 }, { 12, -193 } })
	-- Archive -> service hall -> archive is a second independent chase loop.
	area(parent, "EastServiceHall", 70, -130, 90, -70, 0, { { 80, -80 }, { 80, -100 }, { 80, -120 } })
	area(parent, "LoadingBay", 90, -130, 122, -90, 0, { { 99, -106 }, { 115, -112 }, { 104, -123 } })
	area(parent, "QuietStore", 90, -90, 122, -70, 0, { { 100, -79 }, { 114, -84 } })
	area(
		parent,
		"GeneratorRoom",
		-60,
		-40,
		-20,
		-15,
		B,
		{ { -38, -26 }, { -53, -21 }, { -28, -35 }, { -28, -20 } }
	)
	area(
		parent,
		"ElectricalRoom",
		-60,
		-15,
		-20,
		10,
		B,
		{ { -40, 0 }, { -52, 5 }, { -28, -6 }, { -50, -8 } }
	)
	-- A long, intentionally hazardous lower-level branch: rooms are searchable, not safe lockers.
	area(parent, "ServiceTunnel", -46, 10, -34, 43, B, { { -40, 18 }, { -40, 35 } })
	area(parent, "CompressorRoom", -76, 14, -46, 43, B, { { -55, 28 }, { -65, 20 } })
	area(parent, "ColdStore", -34, 14, -4, 43, B, { { -25, 28 }, { -18, 36 } })
	area(parent, "BoilerRoom", -55, 43, -25, 66, B, { { -40, 54 }, { -49, 61 }, { -29, 60 } })
end

local function newPart(
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- A box from one corner to the opposite corner.
local function box(
	name: string,
	x1: number,
	y1: number,
	z1: number,
	x2: number,
	y2: number,
	z2: number,
	color: Color3,
	material: Enum.Material,
	parent: Instance
): Part
	local lo = Vector3.new(math.min(x1, x2), math.min(y1, y2), math.min(z1, z2))
	local hi = Vector3.new(math.max(x1, x2), math.max(y1, y2), math.max(z1, z2))
	return newPart(name, hi - lo, CFrame.new((lo + hi) / 2), color, material, parent)
end

-- A wall running along X at a fixed z, with gaps for doors and openings.
local function wallX(
	parent: Instance,
	z: number,
	x1: number,
	x2: number,
	y0: number,
	h: number,
	gaps: { Gap }?,
	color: Color3?
)
	local c = color or COLORS.wall
	local cursor = x1
	local sorted: { Gap } = table.clone(gaps or {})
	table.sort(sorted, function(a: Gap, b: Gap)
		return a.center < b.center
	end)
	for _, gap: Gap in sorted do
		local gStart, gEnd = gap.center - gap.width / 2, gap.center + gap.width / 2
		if gStart > cursor then
			box(
				"Wall",
				cursor,
				y0,
				z - T / 2,
				gStart,
				y0 + h,
				z + T / 2,
				c,
				Enum.Material.SmoothPlastic,
				parent
			)
		end
		if gap.header ~= false and DOOR_H < h then
			box(
				"Header",
				gStart,
				y0 + DOOR_H,
				z - T / 2,
				gEnd,
				y0 + h,
				z + T / 2,
				c,
				Enum.Material.SmoothPlastic,
				parent
			)
		end
		cursor = gEnd
	end
	if x2 > cursor then
		box(
			"Wall",
			cursor,
			y0,
			z - T / 2,
			x2,
			y0 + h,
			z + T / 2,
			c,
			Enum.Material.SmoothPlastic,
			parent
		)
	end
end

-- A wall running along Z at a fixed x, with gaps for doors and openings.
local function wallZ(
	parent: Instance,
	x: number,
	z1: number,
	z2: number,
	y0: number,
	h: number,
	gaps: { Gap }?,
	color: Color3?
)
	local c = color or COLORS.wall
	local cursor = z1
	local sorted: { Gap } = table.clone(gaps or {})
	table.sort(sorted, function(a: Gap, b: Gap)
		return a.center < b.center
	end)
	for _, gap: Gap in sorted do
		local gStart, gEnd = gap.center - gap.width / 2, gap.center + gap.width / 2
		if gStart > cursor then
			box(
				"Wall",
				x - T / 2,
				y0,
				cursor,
				x + T / 2,
				y0 + h,
				gStart,
				c,
				Enum.Material.SmoothPlastic,
				parent
			)
		end
		if gap.header ~= false and DOOR_H < h then
			box(
				"Header",
				x - T / 2,
				y0 + DOOR_H,
				gStart,
				x + T / 2,
				y0 + h,
				gEnd,
				c,
				Enum.Material.SmoothPlastic,
				parent
			)
		end
		cursor = gEnd
	end
	if z2 > cursor then
		box(
			"Wall",
			x - T / 2,
			y0,
			cursor,
			x + T / 2,
			y0 + h,
			z2,
			c,
			Enum.Material.SmoothPlastic,
			parent
		)
	end
end

local function room(
	parent: Instance,
	name: string,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	y0: number,
	h: number,
	floorColor: Color3,
	floorMaterial: Enum.Material
)
	box(name .. "Floor", x1, y0 - 1, z1, x2, y0, z2, floorColor, floorMaterial, parent)
	box(
		name .. "Ceiling",
		x1,
		y0 + h,
		z1,
		x2,
		y0 + h + 1,
		z2,
		COLORS.ceiling,
		Enum.Material.SmoothPlastic,
		parent
	)
end

-- A prop resting on the floor at (x, z), with its base at y.
local function prop(
	parent: Instance,
	name: string,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	color: Color3?,
	material: Enum.Material?
): Part
	return newPart(
		name,
		Vector3.new(sx, sy, sz),
		CFrame.new(x, y + sy / 2, z),
		color or COLORS.prop,
		material or Enum.Material.SmoothPlastic,
		parent
	)
end

-- A door filling a gap. `alongZ` doors lie along the Z axis. DoorService makes them open and close.
local function door(
	parent: Instance,
	name: string,
	x: number,
	y0: number,
	z: number,
	width: number,
	alongZ: boolean,
	kind: string
): Part
	local rotation = if alongZ then CFrame.Angles(0, math.rad(90), 0) else CFrame.identity
	local color = if kind == "booth" then COLORS.boothDoor else COLORS.door
	local part = newPart(
		name,
		Vector3.new(width - 0.2, DOOR_H, 0.5),
		CFrame.new(x, y0 + DOOR_H / 2, z) * rotation,
		color,
		Enum.Material.WoodPlanks,
		parent
	)
	part:SetAttribute("Kind", kind)
	part:SetAttribute("Open", false)
	-- Lets the monster plan paths through closed doors; it opens them when it gets there.
	local modifier = Instance.new("PathfindingModifier")
	modifier.PassThrough = true
	modifier.Parent = part
	return part
end

local function powerLight(parent: Instance, position: Vector3)
	local lamp = newPart(
		"EmergencyLamp",
		Vector3.new(1.2, 0.4, 1.2),
		CFrame.new(position),
		Color3.fromRGB(60, 30, 26),
		Enum.Material.SmoothPlastic,
		parent
	)
	lamp.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 110, 80)
	light.Brightness = 1.2
	light.Range = 24
	light.Shadows = true
	light.Enabled = false
	light.Parent = lamp
	lamp:SetAttribute("OnColor", Color3.fromRGB(255, 120, 90))
end


-- Structural extension built with the same Map contract as the original. It does not add
-- hidden teleports, jumps, or solid clutter in pathways. Areas are declared in buildAreas().
local function buildExpansion(
	structure: Folder, props: Folder, markers: Folder, doorsFolder: Folder, lightsFolder: Folder
)
	-- Rear mastering circuit: two doors from the live floor to a gallery. Both rooms beside the
	-- central spine have doors to the gallery AND to the spine. A vault beyond is a dead end.
	room(structure, "RearGallery", -40, -146, 40, -130, 0, H, COLORS.carpet, Enum.Material.Fabric)
	room(structure, "MasteringSuite", -40, -178, -5, -146, 0, H, COLORS.wood, Enum.Material.WoodPlanks)
	room(structure, "NorthSpine", -5, -178, 5, -146, 0, H, COLORS.concrete, Enum.Material.Concrete)
	room(structure, "MachineShop", 5, -178, 40, -146, 0, H, COLORS.concrete, Enum.Material.Concrete)
	room(structure, "TapeVault", -18, -201, 18, -178, 0, H, COLORS.concrete, Enum.Material.Concrete)
	wallZ(structure, -40, -146, -130, 0, H)
	wallZ(structure, 40, -146, -130, 0, H)
	wallX(structure, -146, -40, 40, 0, H, {
		{ center = -22, width = DOOR_W }, { center = 0, width = 10, header = false },
		{ center = 22, width = DOOR_W },
	})
	wallX(structure, -178, -40, -5, 0, H)
	wallX(structure, -178, -5, 5, 0, H, { { center = 0, width = 8 } })
	wallX(structure, -178, 5, 40, 0, H)
	wallZ(structure, -40, -178, -146, 0, H)
	wallZ(structure, -5, -178, -146, 0, H, { { center = -164, width = DOOR_W } })
	wallZ(structure, 5, -178, -146, 0, H, { { center = -164, width = DOOR_W } })
	wallZ(structure, 40, -178, -146, 0, H)
	wallX(structure, -201, -18, 18, 0, H)
	wallX(structure, -178, -18, -5, 0, H)
	wallX(structure, -178, 5, 18, 0, H)
	wallZ(structure, -18, -201, -178, 0, H)
	wallZ(structure, 18, -201, -178, 0, H)
	-- All doors are existing DoorService leaves; their real frame openings remain >= six studs.
	door(doorsFolder, "RearWestDoor", -25, 0, -130, DOOR_W, false, "normal")
	door(doorsFolder, "RearEastDoor", 25, 0, -130, DOOR_W, false, "normal")
	door(doorsFolder, "MasteringDoor", -22, 0, -146, DOOR_W, false, "normal")
	door(doorsFolder, "WorkshopDoor", 22, 0, -146, DOOR_W, false, "normal")
	door(doorsFolder, "MasteringSpineDoor", -5, 0, -164, DOOR_W, true, "normal")
	door(doorsFolder, "WorkshopSpineDoor", 5, 0, -164, DOOR_W, true, "normal")
	door(doorsFolder, "TapeVaultDoor", 0, 0, -178, 8, false, "normal")

	-- East exterior service route circles the archive. Loading and quiet storage each have one
	-- entrance only; crossing their threshold is a calculated risk while the Engineer is nearby.
	room(structure, "EastServiceHall", 70, -130, 90, -70, 0, H, COLORS.concrete, Enum.Material.Concrete)
	room(structure, "LoadingBay", 90, -130, 122, -90, 0, H, COLORS.concrete, Enum.Material.Concrete)
	room(structure, "QuietStore", 90, -90, 122, -70, 0, H, COLORS.tile, Enum.Material.Slate)
	wallX(structure, -130, 70, 122, 0, H)
	wallX(structure, -90, 90, 122, 0, H)
	wallX(structure, -70, 70, 122, 0, H)
	wallZ(structure, 90, -130, -70, 0, H, {
		{ center = -108, width = DOOR_W }, { center = -80, width = DOOR_W },
	})
	wallZ(structure, 122, -130, -70, 0, H)
	door(doorsFolder, "ServiceHallNorth", 70, 0, -116, DOOR_W, true, "normal")
	door(doorsFolder, "ServiceHallSouth", 70, 0, -84, DOOR_W, true, "normal")
	door(doorsFolder, "LoadingBayDoor", 90, 0, -108, DOOR_W, true, "normal")
	door(doorsFolder, "QuietStoreDoor", 90, 0, -80, DOOR_W, true, "normal")

	-- Beyond the electrical room is a long utility corridor with branches. Each branch is a true
	-- dead end: the player can get out only through the door used to enter.
	room(structure, "ServiceTunnel", -46, 10, -34, 43, BASEMENT_Y, BASEMENT_H, COLORS.concrete, Enum.Material.Concrete)
	room(structure, "CompressorRoom", -76, 14, -46, 43, BASEMENT_Y, BASEMENT_H, COLORS.concrete, Enum.Material.Concrete)
	room(structure, "ColdStore", -34, 14, -4, 43, BASEMENT_Y, BASEMENT_H, COLORS.concrete, Enum.Material.Concrete)
	room(structure, "BoilerRoom", -55, 43, -25, 66, BASEMENT_Y, BASEMENT_H, COLORS.concrete, Enum.Material.Concrete)
	wallZ(structure, -46, 10, 43, BASEMENT_Y, BASEMENT_H, { { center = 28, width = DOOR_W } })
	wallZ(structure, -34, 10, 43, BASEMENT_Y, BASEMENT_H, { { center = 28, width = DOOR_W } })
	wallX(structure, 14, -76, -46, BASEMENT_Y, BASEMENT_H)
	wallX(structure, 14, -34, -4, BASEMENT_Y, BASEMENT_H)
	wallX(structure, 43, -76, -46, BASEMENT_Y, BASEMENT_H)
	wallX(structure, 43, -46, -34, BASEMENT_Y, BASEMENT_H, { { center = -40, width = 8 } })
	wallX(structure, 43, -34, -4, BASEMENT_Y, BASEMENT_H)
	wallZ(structure, -76, 14, 43, BASEMENT_Y, BASEMENT_H)
	wallZ(structure, -4, 14, 43, BASEMENT_Y, BASEMENT_H)
	wallX(structure, 66, -55, -25, BASEMENT_Y, BASEMENT_H)
	wallZ(structure, -55, 43, 66, BASEMENT_Y, BASEMENT_H)
	wallZ(structure, -25, 43, 66, BASEMENT_Y, BASEMENT_H)
	-- Boiler front-wall edges; the centre is the only approach from the service tunnel.
	wallX(structure, 43, -55, -46, BASEMENT_Y, BASEMENT_H)
	wallX(structure, 43, -34, -25, BASEMENT_Y, BASEMENT_H)
	door(doorsFolder, "ElectricalExtensionDoor", -40, BASEMENT_Y, 10, 10, false, "normal")
	door(doorsFolder, "CompressorDoor", -46, BASEMENT_Y, 28, DOOR_W, true, "normal")
	door(doorsFolder, "ColdStoreDoor", -34, BASEMENT_Y, 28, DOOR_W, true, "normal")
	door(doorsFolder, "BoilerDoor", -40, BASEMENT_Y, 43, 8, false, "normal")

	-- Collision-equipped furniture creates silhouette hiding without closing routes. Small floor
	-- clutter remains decorative only; the floor is included in the map's onFloor raycasts.
	prop(props, "MasteringDesk", -28, 0, -173, 11, 3, 3, COLORS.wood, Enum.Material.Wood)
	prop(props, "MasteringCabinet", -37, 0, -161, 3, 7, 5, COLORS.metal, Enum.Material.Metal)
	prop(props, "WorkshopBench", 31, 0, -174, 12, 3.3, 3, COLORS.metal, Enum.Material.Metal)
	prop(props, "MachineRack", 36, 0, -156, 3, 8, 5, COLORS.prop, Enum.Material.Metal)
	prop(props, "VaultShelves", -12, 0, -197, 3, 8, 5, COLORS.metal, Enum.Material.Metal)
	prop(props, "LoadingPallets", 116, 0, -123, 8, 2.7, 6, COLORS.wood, Enum.Material.WoodPlanks)
	prop(props, "LoadingForklift", 116, 0, -96, 6, 6, 3, COLORS.metal, Enum.Material.Metal)
	prop(props, "StoreCupboard", 117, 0, -83, 4, 7, 6, COLORS.prop, Enum.Material.Wood)
	prop(props, "Compressor", -70, BASEMENT_Y, 34, 7, 6, 5, COLORS.metal, Enum.Material.DiamondPlate)
	prop(props, "CoolingUnit", -8, BASEMENT_Y, 36, 7, 6, 5, COLORS.metal, Enum.Material.Metal)
	prop(props, "Boiler", -40, BASEMENT_Y, 62, 7, 7, 4, COLORS.metal, Enum.Material.DiamondPlate)
	-- Open-bottom industrial worktable. A player can take shelter beneath or behind it;
	-- unlike box props it has four legs and no collision in its middle.
	local function coverTable(name: string, x: number, y: number, z: number)
		box(name .. "Top", x - 4.8, y + 6.0, z - 2.4, x + 4.8, y + 6.4, z + 2.4, COLORS.metal, Enum.Material.Metal, props)
		for _, dx in { -4.3, 4.3 } do
			for _, dz in { -1.9, 1.9 } do
				box(name .. "Leg", x + dx - 0.2, y, z + dz - 0.2, x + dx + 0.2, y + 6.0, z + dz + 0.2, COLORS.metal, Enum.Material.Metal, props)
			end
		end
	end
	coverTable("MasteringUnderTable", -17, 0, -173)
	coverTable("WorkshopUnderTable", 17, 0, -173)
	coverTable("UtilityUnderTable", -33, BASEMENT_Y, 51)

	for _, p in {
		Vector3.new(-27, 0.25, -172), Vector3.new(-11, 0.25, -190),
		Vector3.new(28, 0.25, -166), Vector3.new(80, 0.25, -125),
		Vector3.new(116, 0.25, -116), Vector3.new(114, 0.25, -77),
		Vector3.new(-69, BASEMENT_Y + 0.25, 22), Vector3.new(-12, BASEMENT_Y + 0.25, 23),
		Vector3.new(-47, BASEMENT_Y + 0.25, 59),
	} do
		marker("FuseSpot", p, markers)
	end
	for _, p in {
		Vector3.new(-22, 10, -154), Vector3.new(25, 10, -167),
		Vector3.new(0, 10, -190), Vector3.new(80, 10, -101),
		Vector3.new(112, 10, -113), Vector3.new(-40, -3, 27),
		Vector3.new(-40, -3, 58),
	} do
		marker("Speaker", p, markers)
	end
	for _, p in {
		Vector3.new(-20, H - 0.3, -140), Vector3.new(-22, H - 0.3, -164),
		Vector3.new(22, H - 0.3, -164), Vector3.new(0, H - 0.3, -189),
		Vector3.new(80, H - 0.3, -103), Vector3.new(110, H - 0.3, -109),
		Vector3.new(-40, -1.8, 31), Vector3.new(-40, -1.8, 55),
	} do
		powerLight(lightsFolder, p)
	end
end

-- A waiting area above the playable map. Quiet, legible, and unsettling: the place looks like
-- a studio that still expects the next session, not a disconnected bright spawn box.
function MapBuilder.buildLobby(): CFrame
	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	local o = Config.LOBBY_ORIGIN
	local function localPart(
		name: string, pos: Vector3, size: Vector3, color: Color3,
		material: Enum.Material, solid: boolean?
	): Part
		local p = newPart(name, size, CFrame.new(o + pos), color, material, lobby)
		p.CanCollide = solid == true
		p.CanQuery = solid == true
		p.CanTouch = false
		return p
	end
	local function plaque(text: string, pos: Vector3, size: Vector3, yaw: number, red: boolean?)
		local p = localPart("LobbyPlaque", pos, size, Color3.fromRGB(28, 28, 29), Enum.Material.Metal)
		p.CFrame = CFrame.new(o + pos) * CFrame.Angles(0, math.rad(yaw), 0)
		local surface = Instance.new("SurfaceGui")
		surface.Face = Enum.NormalId.Back
		surface.PixelsPerStud = 42
		surface.LightInfluence = 0.45
		surface.Parent = p
		local letters = Instance.new("TextLabel")
		letters.Size = UDim2.fromScale(1, 1)
		letters.BackgroundTransparency = 1
		letters.Text = text
		letters.TextWrapped = true
		letters.TextColor3 = if red then Color3.fromRGB(228, 77, 62) else Color3.fromRGB(205, 191, 165)
		letters.Font = Enum.Font.RobotoMono
		letters.TextScaled = true
		letters.Parent = surface
	end
	box("Floor", o.X - 20, o.Y - 1, o.Z - 20, o.X + 20, o.Y, o.Z + 20,
		Color3.fromRGB(57, 46, 43), Enum.Material.WoodPlanks, lobby)
	box("Ceiling", o.X - 20, o.Y + H, o.Z - 20, o.X + 20, o.Y + H + 1, o.Z + 20,
		Color3.fromRGB(27, 30, 32), Enum.Material.Concrete, lobby)
	wallX(lobby, o.Z - 20, o.X - 20, o.X + 20, o.Y, H)
	wallX(lobby, o.Z + 20, o.X - 20, o.X + 20, o.Y, H)
	wallZ(lobby, o.X - 20, o.Z - 20, o.Z + 20, o.Y, H)
	wallZ(lobby, o.X + 20, o.Z - 20, o.Z + 20, o.Y, H)
	-- The quiet red "ON AIR" signature is deliberately visible at spawn.
	plaque("D E A D   A I R", Vector3.new(0, 8.4, -19.34), Vector3.new(17, 3.7, 0.15), 0, true)
	plaque("RECORDING SESSION   /   IN PROGRESS", Vector3.new(0, 5.4, -19.3),
		Vector3.new(17, 1.4, 0.15), 0)
	plaque("WAITING ROOM\nPlease keep your voice down.\nThe Engineer is listening.",
		Vector3.new(-19.32, 6.4, -3), Vector3.new(9, 4.8, 0.15), 90)
	plaque("SESSION RULES\nFind the generator.\nRecover the fuses.\nPlay the emergency master.\nReach the front doors.",
		Vector3.new(19.32, 6.1, -4), Vector3.new(10.5, 5.8, 0.15), -90)
	-- Narrow floor runners orient the camera toward the sign and keep the centre unobstructed.
	localPart("LobbyRunner", Vector3.new(0, 0.04, -4),
		Vector3.new(6, 0.06, 21), Color3.fromRGB(42, 36, 38), Enum.Material.Fabric)
	for _, side in { -1, 1 } do
		local x = side * 13
		localPart("WaitingBench", Vector3.new(x, 1.55, 5.5),
			Vector3.new(8, 0.4, 3.1), Color3.fromRGB(84, 54, 43), Enum.Material.Wood)
		localPart("WaitingBenchBack", Vector3.new(x, 2.5, 6.8),
			Vector3.new(8, 2, 0.4), Color3.fromRGB(72, 52, 45), Enum.Material.Wood)
		for _, dx in { -3.5, 3.5 } do
			localPart("BenchLeg", Vector3.new(x + dx, 0.8, 6),
				Vector3.new(0.32, 1.4, 2.5), Color3.fromRGB(36, 40, 42), Enum.Material.Metal)
		end
		for _, z in { -15, -7, 1 } do
			localPart("AcousticWallPanel", Vector3.new(side * 19.2, 6, z),
				Vector3.new(0.25, 6, 5), Color3.fromRGB(43, 47, 49), Enum.Material.Fabric)
		end
	end
	-- Reception counter at the north wall; a cold monitor is the only sign of life.
	localPart("WaitingCounter", Vector3.new(0, 1.9, -14.5),
		Vector3.new(12, 3.8, 2.5), Color3.fromRGB(65, 48, 40), Enum.Material.Wood, true)
	localPart("CounterTop", Vector3.new(0, 3.9, -14.5),
		Vector3.new(12.4, 0.24, 2.7), Color3.fromRGB(117, 92, 67), Enum.Material.Wood)
	localPart("FrontTerminal", Vector3.new(0, 5.15, -15.2),
		Vector3.new(2.5, 2, 0.27), Color3.fromRGB(34, 41, 40), Enum.Material.Metal)
	localPart("TerminalScreen", Vector3.new(0, 5.15, -15.03),
		Vector3.new(2.15, 1.62, 0.04), Color3.fromRGB(36, 92, 77), Enum.Material.Glass)
	-- Hanging incandescent emergency practicals: enough to read signs without erasing contrast.
	for _, x in { -13, 0, 13 } do
		local lamp = localPart("LobbyHangingLamp", Vector3.new(x, H - 1, 3),
			Vector3.new(3.2, 0.22, 3.2), Color3.fromRGB(135, 88, 57), Enum.Material.Metal)
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(242, 170, 105)
		light.Brightness = if x == 0 then 1.1 else 0.75
		light.Range = 24
		light.Shadows = false
		light.Parent = lamp
	end
	-- One red pilot indicator above the desk, deliberately not a disorienting strobe.
	local pilot = localPart("OnAirLamp", Vector3.new(0, 10.9, -18.9),
		Vector3.new(4, 0.7, 0.15), Color3.fromRGB(172, 44, 37), Enum.Material.Neon)
	local pilotLight = Instance.new("PointLight")
	pilotLight.Color = Color3.fromRGB(226, 65, 47)
	pilotLight.Range = 9
	pilotLight.Brightness = 0.45
	pilotLight.Parent = pilot
	lobby.Parent = Workspace
	return CFrame.lookAt(o + Vector3.new(0, 3, 11), o + Vector3.new(0, 3, -20))
end

-- Builds the greybox studio as Workspace.Map and returns it.
function MapBuilder.build(): Model
	local studio = Instance.new("Model")
	studio.Name = "Map"
	studio:SetAttribute("MapName", "Recording studio (greybox)")
	local function folder(name: string, parent: Instance): Folder
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
		return f
	end
	local structure = folder("Structure", studio)
	local props = folder("Props", studio)
	local markers = folder("Markers", studio)
	local doorsFolder = folder("Doors", studio)
	local booths = folder("Booths", studio)
	local objectives = folder("Objectives", studio)
	local lightsFolder = folder("PowerLights", studio)
	buildAreas(folder("Areas", studio))

	-- Floors and ceilings
	room(structure, "Reception", -20, 0, 20, 30, 0, H, COLORS.tile, Enum.Material.Marble)
	room(structure, "Corridor", -5, -60, 5, 0, 0, H, COLORS.carpet, Enum.Material.Fabric)
	room(structure, "ControlA", -35, -40, -5, -10, 0, H, COLORS.carpet, Enum.Material.Fabric)
	room(structure, "ControlB", 5, -40, 35, -10, 0, H, COLORS.carpet, Enum.Material.Fabric)
	room(structure, "CrossCorridor", -60, -70, 60, -60, 0, H, COLORS.carpet, Enum.Material.Fabric)
	room(
		structure,
		"LiveRoom",
		-40,
		-130,
		40,
		-70,
		0,
		LIVE_H,
		COLORS.wood,
		Enum.Material.WoodPlanks
	)
	room(structure, "Booths", -55, -130, -40, -70, 0, H, COLORS.foam, Enum.Material.Fabric)
	room(structure, "Archive", 40, -130, 70, -70, 0, H, COLORS.concrete, Enum.Material.Concrete)
	room(structure, "BreakRoom", 35, -60, 60, -35, 0, H, COLORS.tile, Enum.Material.Marble)
	box(
		"StairwellCeiling",
		-60,
		H,
		-60,
		-40,
		H + 1,
		-40,
		COLORS.ceiling,
		Enum.Material.SmoothPlastic,
		structure
	)
	-- Basement: floor, and a thin ceiling under the ground-floor rooms above it
	box(
		"BasementFloor",
		-60,
		BASEMENT_Y - 1,
		-40,
		-20,
		BASEMENT_Y,
		10,
		COLORS.concrete,
		Enum.Material.Concrete,
		structure
	)
	box(
		"BasementCeiling",
		-60,
		-1.5,
		-40,
		-20,
		-1,
		10,
		COLORS.ceiling,
		Enum.Material.SmoothPlastic,
		structure
	)

	-- Walls along X
	wallX(structure, 30, -20, 20, 0, H, { { center = 0, width = 10 } }) -- reception south: the exit doors
	wallX(structure, 0, -20, 20, 0, H, { { center = 0, width = 10, header = false } }) -- reception into corridor
	wallX(structure, -10, -35, -5, 0, H)
	wallX(structure, -10, 5, 35, 0, H)
	wallX(structure, -40, -35, -5, 0, H)
	wallX(structure, -40, 5, 35, 0, H)
	wallX(structure, -60, -60, -5, 0, H, { { center = -50, width = DOOR_W } }) -- stairwell door
	wallX(structure, -60, 5, 60, 0, H, { { center = 47.5, width = DOOR_W } }) -- break room door
	wallX(structure, -70, -60, -40, 0, H)
	wallX(structure, -70, -40, 40, 0, LIVE_H, { { center = 0, width = 8 } }) -- live room doors
	wallX(structure, -70, 40, 60, 0, H, { { center = 55, width = DOOR_W } }) -- archive door
	wallX(structure, -70, 60, 70, 0, H)
	wallX(structure, -130, -55, -40, 0, H, nil, COLORS.foam)
	wallX(structure, -130, -40, 40, 0, LIVE_H, {
		{ center = -25, width = DOOR_W },
		{ center = 25, width = DOOR_W },
	}) -- rear gallery escape loop
	wallX(structure, -130, 40, 70, 0, H)
	wallX(structure, -110, -55, -40, 0, H, nil, COLORS.foam) -- booth separators
	wallX(structure, -90, -55, -40, 0, H, nil, COLORS.foam)
	wallX(structure, -35, 35, 60, 0, H) -- break room south
	wallX(structure, -40, -60, -40, 0, H) -- stairwell south, above the basement

	-- Walls along Z
	wallZ(structure, -20, 0, 30, 0, H)
	wallZ(structure, 20, 0, 30, 0, H)
	wallZ(structure, -5, -60, 0, 0, H, { { center = -25, width = DOOR_W } }) -- control room A door
	wallZ(structure, 5, -60, 0, 0, H, { { center = -25, width = DOOR_W } }) -- control room B door
	wallZ(structure, -35, -40, -10, 0, H)
	wallZ(structure, 35, -60, -10, 0, H)
	wallZ(structure, -60, -70, -60, 0, H)
	wallZ(structure, -60, -60, -40, BASEMENT_Y, H - BASEMENT_Y) -- stairwell sides reach down to the basement
	wallZ(structure, -40, -60, -40, BASEMENT_Y, H - BASEMENT_Y)
	wallZ(structure, -40, -130, -70, 0, LIVE_H, { -- booth doors
		{ center = -120, width = DOOR_W },
		{ center = -100, width = DOOR_W },
		{ center = -80, width = DOOR_W },
	})
	wallZ(structure, -55, -130, -70, 0, H, nil, COLORS.foam)
	wallZ(structure, 40, -130, -70, 0, LIVE_H, { { center = -100, width = DOOR_W } }) -- live room to archive
	wallZ(structure, 70, -130, -70, 0, H, {
		{ center = -116, width = DOOR_W },
		{ center = -84, width = DOOR_W },
	}) -- two entrances to east service loop
	wallZ(structure, 60, -70, -35, 0, H)

	-- Basement walls
	wallZ(structure, -60, -40, 10, BASEMENT_Y, BASEMENT_H)
	wallZ(structure, -20, -40, 10, BASEMENT_Y, BASEMENT_H)
	wallX(structure, 10, -60, -20, BASEMENT_Y, BASEMENT_H, { { center = -40, width = 10 } })
	wallX(structure, -40, -40, -20, BASEMENT_Y, BASEMENT_H)
	wallX(structure, -15, -60, -20, BASEMENT_Y, BASEMENT_H, { { center = -40, width = DOOR_W } })

	-- The stairs: a tilted slab from the stairwell door (floor level, north, z = -60) down to the
	-- basement (south, z = -40). A plain slab, so its direction is exact (a wedge's slope side is easy
	-- to get backwards). Its top surface runs along the line between those two edges.
	do
		local top = Vector3.new(-50, 0, -60)
		local bottom = Vector3.new(-50, BASEMENT_Y, -40)
		local slope = CFrame.lookAt((top + bottom) / 2, bottom)
		newPart(
			"Stairs",
			Vector3.new(20, 1, (bottom - top).Magnitude + 0.6),
			slope * CFrame.new(0, -0.5, 0),
			COLORS.concrete,
			Enum.Material.Concrete,
			structure
		)
	end

	-- Outside the front doors: a small step and the exit zone
	box("Outside", -8, -1, 30, 8, 0, 44, COLORS.concrete, Enum.Material.Concrete, structure)
	local exitZone = box(
		"ExitZone",
		-5,
		0.5,
		31,
		5,
		9,
		40,
		Color3.new(0, 1, 0),
		Enum.Material.SmoothPlastic,
		objectives
	)
	exitZone.Transparency = 1
	exitZone.CanCollide = false
	exitZone.CanQuery = false

	-- Props: furniture to hide behind, block sight lines and knock into
	prop(props, "FrontDesk", -12, 0, 10, 10, 3.5, 3)
	prop(props, "Sofa", 12, 0, 18, 8, 2.5, 3, Color3.fromRGB(70, 50, 50), Enum.Material.Fabric)
	prop(props, "MixingDeskA", -20, 0, -36, 16, 3.5, 3)
	prop(props, "MixingDeskB", 20, 0, -36, 16, 3.5, 3)
	prop(props, "SpeakerA", -32, 0, -12, 2.5, 6, 2.5, Color3.fromRGB(30, 30, 30))
	prop(props, "SpeakerB", 32, 0, -12, 2.5, 6, 2.5, Color3.fromRGB(30, 30, 30))
	prop(props, "DrumRiser", -22, 0, -116, 12, 1, 10, COLORS.wood, Enum.Material.WoodPlanks)
	prop(props, "BassDrum", -22, 1, -117, 3, 3, 3, Color3.fromRGB(120, 30, 30))
	prop(props, "AmpStack1", -8, 0, -126, 4, 7, 3, Color3.fromRGB(28, 28, 28))
	prop(props, "AmpStack2", 8, 0, -126, 4, 7, 3, Color3.fromRGB(28, 28, 28))
	prop(
		props,
		"Piano",
		22,
		0,
		-118,
		7,
		4,
		4,
		Color3.fromRGB(20, 18, 18),
		Enum.Material.SmoothPlastic
	)
	prop(props, "Gobo1", -5, 0, -100, 8, 6, 1, COLORS.foam, Enum.Material.Fabric)
	prop(props, "Gobo2", 12, 0, -92, 1, 6, 8, COLORS.foam, Enum.Material.Fabric)
	prop(props, "ChairStack", 30, 0, -80, 3, 5, 3, Color3.fromRGB(60, 60, 64), Enum.Material.Metal)
	for i, z in { -122, -112, -92, -82 } do
		local west = i % 2 == 1
		local x = if west then 50 else 60 -- leave >= 10-stud passages around both ends
		prop(props, "Shelf", x, 0, z, 10, 9, 2, COLORS.metal, Enum.Material.Metal)
	end
	prop(props, "BreakTable", 50, 0, -47, 6, 3, 4, COLORS.wood, Enum.Material.WoodPlanks)
	prop(props, "Fridge", 57, 0, -38, 3, 7, 3, Color3.fromRGB(200, 200, 196))

	-- Objectives
	prop(
		objectives,
		"Generator",
		-45,
		BASEMENT_Y,
		-32,
		6,
		5,
		4,
		Color3.fromRGB(110, 90, 40),
		Enum.Material.DiamondPlate
	)
	prop(
		objectives,
		"FuseBox",
		-59,
		BASEMENT_Y + 3,
		-2,
		0.8,
		4,
		3,
		COLORS.metal,
		Enum.Material.Metal
	)
	prop(
		objectives,
		"TapeDeck",
		-16,
		3.5,
		-36,
		3,
		1.2,
		2,
		Color3.fromRGB(40, 40, 40),
		Enum.Material.Metal
	)

	-- Doors
	local function addDoor(
		name: string,
		x: number,
		z: number,
		width: number,
		alongZ: boolean,
		kind: string
	): Part
		return door(doorsFolder, name, x, 0, z, width, alongZ, kind)
	end
	local frontDoor = door(doorsFolder, "FrontDoors", 0, 0, 30, 10, false, "front")
	frontDoor.Color = Color3.fromRGB(60, 62, 66)
	frontDoor.Material = Enum.Material.Metal
	addDoor("ControlADoor", -5, -25, DOOR_W, true, "normal")
	addDoor("ControlBDoor", 5, -25, DOOR_W, true, "normal")
	addDoor("StairwellDoor", -50, -60, DOOR_W, false, "normal")
	addDoor("BreakRoomDoor", 47.5, -60, DOOR_W, false, "normal")
	addDoor("LiveRoomDoors", 0, -70, 8, false, "normal")
	addDoor("ArchiveDoor", 55, -70, DOOR_W, false, "normal")
	addDoor("ArchiveLiveDoor", 40, -100, DOOR_W, true, "normal")
	addDoor("Booth1Door", -40, -120, DOOR_W, true, "booth")
	addDoor("Booth2Door", -40, -100, DOOR_W, true, "booth")
	addDoor("Booth3Door", -40, -80, DOOR_W, true, "booth")

	-- Soundproof booth volumes, each linked to its door by name
	for i, z in { -120, -100, -80 } do
		local volume =
			helper("Booth" .. i, CFrame.new(-47.5, H / 2, z), Vector3.new(15, H, 20), booths)
		volume:SetAttribute("Door", "Booth" .. i .. "Door")
	end

	-- Emergency lights: off until the generator runs
	for _, p in
		{
			Vector3.new(0, H - 0.3, 15),
			Vector3.new(0, H - 0.3, -30),
			Vector3.new(-30, H - 0.3, -65),
			Vector3.new(30, H - 0.3, -65),
			Vector3.new(0, LIVE_H - 0.3, -100),
			Vector3.new(-20, H - 0.3, -25),
			Vector3.new(20, H - 0.3, -25),
			Vector3.new(55, H - 0.3, -100),
			Vector3.new(47, H - 0.3, -47),
			Vector3.new(-40, -1.8, -28),
			Vector3.new(-40, -1.8, 0),
		}
	do
		powerLight(lightsFolder, p)
	end

	-- Script markers
	local spawnMarker = marker("PlayerSpawn", Vector3.new(0, 3, 24), markers)
	spawnMarker.CFrame = CFrame.lookAt(spawnMarker.Position, Vector3.new(0, 3, 0))
	marker("MonsterSpawn", Vector3.new(0, 3, -118), markers)
	for _, p in
		{
			Vector3.new(-15, 3.75, 10),
			Vector3.new(-26, 3.75, -36),
			Vector3.new(26, 3.75, -36),
			Vector3.new(30, 0.25, -125),
			Vector3.new(-25, 0.25, -78),
			Vector3.new(66, 0.25, -127),
			Vector3.new(45, 0.25, -86),
			Vector3.new(52, 3.25, -47),
			Vector3.new(-48, 0.25, -100),
			Vector3.new(-56, BASEMENT_Y + 0.25, -37),
			Vector3.new(-25, BASEMENT_Y + 0.25, 6),
			Vector3.new(-56, 0.25, -66),
		}
	do
		marker("FuseSpot", p, markers)
	end
	for _, p in
		{
			Vector3.new(0, 10, 20),
			Vector3.new(0, 10, -35),
			Vector3.new(0, 18, -100),
			Vector3.new(40, 10, -65),
			Vector3.new(-40, 10, -65),
			Vector3.new(-40, -3, -25),
		}
	do
		marker("Speaker", p, markers)
	end

	buildExpansion(structure, props, markers, doorsFolder, lightsFolder)
	studio.Parent = Workspace
	return studio
end

MapBuilder.FUSE_COLOR = COLORS.fuse

return MapBuilder
