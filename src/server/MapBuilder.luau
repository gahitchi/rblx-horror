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
--   tape archive on its east side; break room off the cross corridor, with a back door onto a
--   service passage that runs round to reception (the long way, for when the corridor shutter drops).
--   Shut in plain sight for chapter 1: the stairwell down to the basement (sealed by the navy) and
--   the door to the engineer's flat (barricaded from inside). The basement is built for chapter 2
--   but has no Areas yet, so the monster never goes there.

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
	navy = Color3.fromRGB(70, 74, 78),
	seal = Color3.fromRGB(220, 180, 40),
	paper = Color3.fromRGB(215, 205, 180),
	reel = Color3.fromRGB(150, 120, 70),
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
	area(parent, "BreakRoom", 35, -60, 60, -35, 0, { { 42, -42 }, { 42, -55 }, { 52, -53 } })
	area(parent, "ServicePassage", 36, -35, 42, 9, 0, { { 39, -28 }, { 39, -12 }, { 39, 4 } })
	area(parent, "ServiceLeg", 20, 9, 42, 15, 0, { { 27, 12 }, { 39, 12 } })
	-- The basement (chapter 2) gets its Areas when it opens; until then the monster stays upstairs.
	local _ = B
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

-- A ceiling lamp. Dead (off) until the building wakes; LightingService switches it.
local function lamp(parent: Instance, position: Vector3)
	local fitting = newPart(
		"Lamp",
		Vector3.new(1.4, 0.4, 1.4),
		CFrame.new(position),
		Color3.fromRGB(48, 44, 40),
		Enum.Material.SmoothPlastic,
		parent
	)
	fitting.CanCollide = false
	fitting.CanQuery = false
	local light = Instance.new("PointLight")
	light.Brightness = 1
	light.Range = 26
	light.Shadows = true
	light.Enabled = false
	light.Parent = fitting
end

-- Words on one face of a part (signs, labels, the navy's notices).
local function label(part: BasePart, text: string, face: Enum.NormalId, color: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.PixelsPerStud = 40
	gui.LightInfluence = 1
	gui.Parent = part
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = color or Color3.fromRGB(20, 20, 20)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.TextWrapped = true
	textLabel.Parent = gui
end

function MapBuilder.buildLobby(): CFrame
	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	local o = Config.LOBBY_ORIGIN
	box(
		"Floor",
		o.X - 20,
		o.Y - 1,
		o.Z - 20,
		o.X + 20,
		o.Y,
		o.Z + 20,
		COLORS.carpet,
		Enum.Material.Fabric,
		lobby
	)
	box(
		"Ceiling",
		o.X - 20,
		o.Y + H,
		o.Z - 20,
		o.X + 20,
		o.Y + H + 1,
		o.Z + 20,
		COLORS.ceiling,
		Enum.Material.SmoothPlastic,
		lobby
	)
	wallX(lobby, o.Z - 20, o.X - 20, o.X + 20, o.Y, H)
	wallX(lobby, o.Z + 20, o.X - 20, o.X + 20, o.Y, H)
	wallZ(lobby, o.X - 20, o.Z - 20, o.Z + 20, o.Y, H)
	wallZ(lobby, o.X + 20, o.Z - 20, o.Z + 20, o.Y, H)

	local lamp = newPart(
		"Lamp",
		Vector3.new(4, 0.4, 4),
		CFrame.new(o + Vector3.new(0, H - 0.3, 0)),
		Color3.fromRGB(255, 220, 170),
		Enum.Material.Neon,
		lobby
	)
	lamp.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 205, 150)
	light.Brightness = 1.5
	light.Range = 40
	light.Parent = lamp

	local sign = newPart(
		"Sign",
		Vector3.new(16, 5, 0.5),
		CFrame.new(o + Vector3.new(0, 7, -19.4)),
		Color3.fromRGB(30, 26, 24),
		Enum.Material.SmoothPlastic,
		lobby
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back -- the +Z face, toward the room
	gui.PixelsPerStud = 40
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = string.upper(Config.GAME_NAME)
	label.TextColor3 = Color3.fromRGB(230, 70, 60)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = gui

	lobby.Parent = Workspace
	return CFrame.lookAt(o + Vector3.new(0, 3, 8), o + Vector3.new(0, 3, -20))
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
	local shutters = folder("Shutters", studio)
	local lampsFolder = folder("Lamps", studio)
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
	room(
		structure,
		"ServicePassage",
		36,
		-35,
		42,
		15,
		0,
		H,
		COLORS.concrete,
		Enum.Material.Concrete
	)
	room(structure, "ServiceLeg", 20, 9, 36, 15, 0, H, COLORS.concrete, Enum.Material.Concrete)
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
	-- Basement (chapter 2): floor, and a thin ceiling under the ground-floor rooms above it
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
	wallX(
		structure,
		-60,
		-60,
		-5,
		0,
		H,
		{ -- the sealed stairwell, and the barricaded stairs to the flat
			{ center = -50, width = DOOR_W },
			{ center = -25, width = DOOR_W },
		}
	)
	wallX(structure, -60, 5, 60, 0, H, { { center = 47.5, width = DOOR_W } }) -- break room door
	wallX(structure, -70, -60, -40, 0, H)
	wallX(structure, -70, -40, 40, 0, LIVE_H, { { center = 0, width = 8 } }) -- live room doors
	wallX(structure, -70, 40, 60, 0, H, { { center = 55, width = DOOR_W } }) -- archive door
	wallX(structure, -70, 60, 70, 0, H)
	wallX(structure, -130, -55, -40, 0, H, nil, COLORS.foam)
	wallX(structure, -130, -40, 40, 0, LIVE_H)
	wallX(structure, -130, 40, 70, 0, H)
	wallX(structure, -110, -55, -40, 0, H, nil, COLORS.foam) -- booth separators
	wallX(structure, -90, -55, -40, 0, H, nil, COLORS.foam)
	wallX(structure, -35, 35, 60, 0, H, { { center = 39, width = DOOR_W } }) -- break room back door
	wallX(structure, -40, -60, -40, 0, H) -- stairwell south, above the basement
	wallX(structure, 9, 20, 36, 0, H) -- service leg, north side
	wallX(structure, 15, 20, 42, 0, H) -- service leg, south side

	-- Walls along Z
	wallZ(structure, -20, 0, 30, 0, H)
	wallZ(structure, 20, 0, 30, 0, H, { { center = 12, width = DOOR_W } }) -- reception's side door
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
	wallZ(structure, 70, -130, -70, 0, H)
	wallZ(structure, 60, -70, -35, 0, H)
	wallZ(structure, 36, -35, 9, 0, H) -- service passage, west side
	wallZ(structure, 42, -35, 15, 0, H) -- service passage, east side

	-- Basement walls
	wallZ(structure, -60, -40, 10, BASEMENT_Y, BASEMENT_H)
	wallZ(structure, -20, -40, 10, BASEMENT_Y, BASEMENT_H)
	wallX(structure, 10, -60, -20, BASEMENT_Y, BASEMENT_H)
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
	local shelfNumber = 0
	for i, z in { -122, -112, -92, -82 } do
		local west = i % 2 == 1
		local x = if west then 51 else 59 -- alternate ends to make a zigzag
		local shelf = prop(props, "Shelf", x, 0, z, 20, 9, 2, COLORS.metal, Enum.Material.Metal)
		-- Two places a reel can sit on each shelf, one on each face, numbered for the card index.
		for _, side in { -1, 1 } do
			shelfNumber += 1
			local spot =
				marker("ReelSpot", Vector3.new(x + side * 5, 4.6, z + side * 1.35), markers)
			spot:SetAttribute("Shelf", tostring(shelfNumber))
			local tag = newPart(
				"ShelfTag",
				Vector3.new(1.6, 0.8, 0.1),
				CFrame.new(x + side * 5, 7.4, z + side * 1.06),
				COLORS.paper,
				Enum.Material.SmoothPlastic,
				shelf
			)
			tag.CanCollide = false
			tag.CanQuery = false
			label(
				tag,
				"SHELF " .. shelfNumber,
				if side > 0 then Enum.NormalId.Back else Enum.NormalId.Front
			)
		end
	end
	prop(props, "BreakTable", 50, 0, -47, 6, 3, 4, COLORS.wood, Enum.Material.WoodPlanks)
	prop(props, "Fridge", 57, 0, -38, 3, 7, 3, Color3.fromRGB(200, 200, 196))

	-- Chapter 1's objectives (docs/MAP_CONTRACT.md lists what each one is for)
	local function objective(
		name: string,
		x: number,
		y: number,
		z: number,
		sx: number,
		sy: number,
		sz: number,
		color: Color3,
		material: Enum.Material?
	): Part
		return prop(objectives, name, x, y, z, sx, sy, sz, color, material)
	end
	objective("BookingDiary", -13, 3.5, 10, 1.4, 0.12, 1, Color3.fromRGB(110, 30, 30))
	objective("MixingDesk", -20, 0, -36, 16, 3.5, 3, COLORS.prop)
	objective("SessionLog", -26, 3.5, -35.4, 1.2, 0.12, 1.6, COLORS.paper)
	objective(
		"TapeMachine",
		-32.5,
		0,
		-28,
		3,
		6,
		5,
		Color3.fromRGB(70, 66, 60),
		Enum.Material.Metal
	)
	objective("PatchBay", -15, 2, -10.7, 4, 3, 0.8, Color3.fromRGB(30, 30, 32), Enum.Material.Metal)
	objective("Spares", 55.5, 0, -56.5, 4, 7, 2, Color3.fromRGB(90, 96, 90), Enum.Material.Metal)
	objective("CardIndex", 65, 0, -73.5, 3, 4, 2, Color3.fromRGB(96, 80, 60), Enum.Material.Wood)
	objective("RoadCase", 24, 0, -96, 5, 2.5, 3, Color3.fromRGB(26, 26, 26), Enum.Material.Metal)
	objective("Safe", 31, 0, -30, 2.5, 3, 2.5, Color3.fromRGB(60, 62, 58), Enum.Material.Metal)
	objective("MemorialProgramme", 50, 3, -47, 1, 0.08, 1.4, Color3.fromRGB(235, 230, 220))
	local mailSlot =
		objective("MailSlot", 7.5, 3.4, 29.35, 1.8, 0.4, 0.3, COLORS.metal, Enum.Material.Metal)
	mailSlot.CanCollide = false

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
	addDoor("BreakRoomDoor", 47.5, -60, DOOR_W, false, "normal")
	addDoor("LiveRoomDoors", 0, -70, 8, false, "normal")
	addDoor("ArchiveDoor", 55, -70, DOOR_W, false, "normal")
	addDoor("ArchiveLiveDoor", 40, -100, DOOR_W, true, "normal")
	addDoor("Booth1Door", -40, -120, DOOR_W, true, "booth")
	addDoor("Booth2Door", -40, -100, DOOR_W, true, "booth")
	addDoor("Booth3Door", -40, -80, DOOR_W, true, "booth")
	addDoor("BreakRoomBackDoor", 39, -35, DOOR_W, false, "normal")
	addDoor("ServiceDoor", 20, 12, DOOR_W, true, "normal")

	-- Shut in plain sight: the navy's seal on the stairwell, and the flat's door, barricaded from inside.
	local stairwell = addDoor("StairwellDoor", -50, -60, DOOR_W, false, "sealed")
	stairwell.Color = COLORS.navy
	stairwell.Material = Enum.Material.Metal
	label(stairwell, "US NAVY\nQUARANTINE\nNO ENTRY\n1987", Enum.NormalId.Back, COLORS.seal)
	local flatDoor = addDoor("FlatDoor", -25, -60, DOOR_W, false, "barricaded")
	label(flatDoor, "PRIVATE\nstairs to the flat", Enum.NormalId.Back, COLORS.paper)

	-- Soundproof booth volumes, each linked to its door by name
	for i, z in { -120, -100, -80 } do
		local volume =
			helper("Booth" .. i, CFrame.new(-47.5, H / 2, z), Vector3.new(15, H, 20), booths)
		volume:SetAttribute("Door", "Booth" .. i .. "Door")
	end

	-- The navy's quarantine shutter in the main corridor, between the control rooms and reception.
	-- It drops in Last Call, so the run out takes the long way round (break room, service passage).
	local shutter = newPart(
		"CorridorShutter",
		Vector3.new(10, H, 0.8),
		CFrame.new(0, H / 2, -5),
		COLORS.navy,
		Enum.Material.DiamondPlate,
		shutters
	)
	shutter:SetAttribute("Route", "short")
	shutter:SetAttribute("StartsOpen", true)

	-- Lamps: dead until the building wakes
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
			Vector3.new(39, H - 0.3, -10),
			Vector3.new(-47, H - 0.3, -100),
		}
	do
		lamp(lampsFolder, p)
	end

	-- Script markers
	local spawnMarker = marker("PlayerSpawn", Vector3.new(0, 3, 24), markers)
	spawnMarker.CFrame = CFrame.lookAt(spawnMarker.Position, Vector3.new(0, 3, 0))
	marker("MonsterSpawn", Vector3.new(0, 3, -118), markers)
	for _, p in
		{
			Vector3.new(-48, 0.3, -124),
			Vector3.new(-48, 0.3, -74),
			Vector3.new(26, 3.75, -36),
			Vector3.new(-26, 1.3, -112),
			Vector3.new(12, 2.75, 18),
			Vector3.new(67, 0.3, -127),
			Vector3.new(39, 0.3, -20),
			Vector3.new(-30, 0.3, -64),
		}
	do
		marker("OptionalTapeSpot", p, markers)
	end
	for _, p in
		{
			Vector3.new(0, 10, 20),
			Vector3.new(0, 10, -35),
			Vector3.new(0, 18, -100),
			Vector3.new(40, 10, -65),
			Vector3.new(-40, 10, -65),
			Vector3.new(-20, 10, -25),
		}
	do
		marker("Speaker", p, markers)
	end

	studio.Parent = Workspace
	return studio
end

MapBuilder.REEL_COLOR = COLORS.reel
MapBuilder.PAPER_COLOR = COLORS.paper

return MapBuilder
