--!strict
-- Playable chapter 1 ground-floor blockout. Intentionally native Roblox parts:
-- broad silhouettes, warm studio finishes, cold navy closures, low part counts.
-- The old art-pass meshes, realism and asset-validation code are not dependencies.

local StudioLayout = require(script.Parent.StudioLayout)

type Room = StudioLayout.Room
type Portal = {
	a: string, b: string, axis: string, at: number, along: number,
	width: number, height: number, kind: string, name: string,
}

local StudioGroundFloor = {}

local C = {
	wall = Color3.fromRGB(169, 152, 129),
	floor = Color3.fromRGB(89, 73, 60),
	ceiling = Color3.fromRGB(63, 60, 58),
	foam = Color3.fromRGB(87, 63, 53),
	teal = Color3.fromRGB(48, 107, 111),
	mustard = Color3.fromRGB(200, 151, 67),
	navy = Color3.fromRGB(77, 90, 99),
	pale = Color3.fromRGB(226, 207, 164),
	dark = Color3.fromRGB(35, 38, 42),
	red = Color3.fromRGB(137, 44, 44),
}

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function part(
	parent: Instance, name: string, at: Vector3, size: Vector3,
	color: Color3, material: Enum.Material?, solid: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = CFrame.new(at)
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = solid == true
	p.CanQuery = solid == true
	p.CanTouch = solid == true
	p.Parent = parent
	return p
end

local function helper(parent: Instance, name: string, at: Vector3, size: Vector3?): Part
	local p = part(parent, name, at, size or Vector3.one, C.mustard, nil, false)
	p.Transparency = 1
	p.CanTouch = false
	p.CastShadow = false
	return p
end

local function plaque(parent: Instance, caption: string, at: Vector3, size: Vector3)
	local backing = part(parent, "Sign_" .. caption, at, size, C.dark, nil, false)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 28
	gui.LightInfluence = 0.2
	gui.Parent = backing
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = caption
	t.Font = Enum.Font.GothamBold
	t.TextColor3 = C.pale
	t.TextScaled = true
	t.Parent = gui
end

local function locatePortal(a: Room, b: Room, kind: string): Portal
	local axis: string
	local at: number
	local along: number
	local overlap: number
	if math.abs(a.x2 - b.x1) < 0.01 or math.abs(b.x2 - a.x1) < 0.01 then
		axis = "x"
		at = if math.abs(a.x2 - b.x1) < 0.01 then a.x2 else b.x2
		local lo, hi = math.max(a.z1, b.z1), math.min(a.z2, b.z2)
		overlap = hi - lo
		along = (lo + hi) / 2
	else
		assert(math.abs(a.z2 - b.z1) < 0.01 or math.abs(b.z2 - a.z1) < 0.01,
			a.name .. " / " .. b.name .. " are not adjacent")
		axis = "z"
		at = if math.abs(a.z2 - b.z1) < 0.01 then a.z2 else b.z2
		local lo, hi = math.max(a.x1, b.x1), math.min(a.x2, b.x2)
		overlap = hi - lo
		along = (lo + hi) / 2
	end
	assert(overlap >= 14, "portal too narrow: " .. a.name .. " / " .. b.name)
	return {
		a = a.name, b = b.name, axis = axis, at = at, along = along,
		width = if kind == "open" then 15 else 9,
		height = if kind == "open" then 12 else 10.5,
		kind = kind, name = "Door_" .. a.name .. "_" .. b.name,
	}
end

local function wallPiece(
	parent: Instance, axis: string, at: number, lo: number, hi: number,
	bottom: number, top: number, color: Color3
)
	if hi - lo < 0.04 or top - bottom < 0.04 then
		return
	end
	if axis == "x" then
		part(parent, "Wall", Vector3.new(at, (bottom + top) / 2, (lo + hi) / 2),
			Vector3.new(0.8, top - bottom, hi - lo), color, Enum.Material.Concrete, true)
	else
		part(parent, "Wall", Vector3.new((lo + hi) / 2, (bottom + top) / 2, at),
			Vector3.new(hi - lo, top - bottom, 0.8), color, Enum.Material.Concrete, true)
	end
end

local function side(
	parent: Instance, room: Room, portals: { Portal }, axis: string,
	at: number, lo: number, hi: number, color: Color3
)
	local gaps: { Portal } = {}
	for _, p in portals do
		if (p.a == room.name or p.b == room.name) and p.axis == axis and math.abs(p.at - at) < 0.01 then
			table.insert(gaps, p)
		end
	end
	table.sort(gaps, function(a, b)
		return a.along < b.along
	end)
	local cursor = lo
	for _, gap in gaps do
		local left, right = math.max(lo, gap.along - gap.width / 2), math.min(hi, gap.along + gap.width / 2)
		assert(left >= cursor - 0.01, "overlapping door openings in " .. room.name)
		wallPiece(parent, axis, at, cursor, left, 0, room.height, color)
		wallPiece(parent, axis, at, left, right, gap.height, room.height, color)
		cursor = right
	end
	wallPiece(parent, axis, at, cursor, hi, 0, room.height, color)
end

local function door(parent: Instance, p: Portal, kind: string): Part
	local center = if p.axis == "x"
		then Vector3.new(p.at, 5.08, p.along)
		else Vector3.new(p.along, 5.08, p.at)
	local leaf = part(parent, p.name, center, Vector3.new(p.width - 0.3, 9.9, 0.36),
		if kind == "booth" then C.foam else C.teal, Enum.Material.Wood, true)
	if p.axis == "x" then
		leaf.CFrame *= CFrame.Angles(0, math.rad(90), 0)
	end
	leaf:SetAttribute("Kind", kind)
	leaf:SetAttribute("Open", false)
	local handle = part(parent, "DoorGrip_" .. p.name,
		center + Vector3.new(0, 0, 0), Vector3.new(0.35, 0.8, 0.14), C.mustard,
		Enum.Material.Metal, false)
	handle.Anchored = false
	handle.CFrame = leaf.CFrame * CFrame.new(p.width / 2 - 1.1, -0.6, -0.27)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = leaf
	weld.Part1 = handle
	weld.Parent = handle
	return leaf
end

local function objective(
	parent: Instance, name: string, at: Vector3, size: Vector3,
	color: Color3, solid: boolean?
): Part
	return part(parent, name, at, size, color, Enum.Material.SmoothPlastic, solid)
end

local function ceilingLamp(parent: Instance, at: Vector3)
	local fitting = part(parent, "Practical", at, Vector3.new(4, 0.3, 2), C.pale, nil, false)
	local light = Instance.new("PointLight")
	light.Enabled = false
	light.Range = 30
	light.Brightness = 0.55
	light.Shadows = true
	light.Parent = fitting
end

function StudioGroundFloor.build(): Model
	local map = Instance.new("Model")
	map.Name = "Map"
	map:SetAttribute("MapName", "Wrenmouth Recording Studio / Chapter 1")
	map:SetAttribute("Blockout", true)
	local structure = folder(map, "Structure")
	local props = folder(map, "Props")
	local markers = folder(map, "Markers")
	local areas = folder(map, "Areas")
	local doors = folder(map, "Doors")
	local booths = folder(map, "Booths")
	local shutters = folder(map, "Shutters")
	local lamps = folder(map, "Lamps")
	local hiding = folder(map, "HidingSpots")
	local objectives = folder(map, "Objectives")

	local rooms, links = StudioLayout.make()
	local byName: { [string]: Room } = {}
	for _, room in rooms do
		byName[room.name] = room
	end
	local portals: { Portal } = {}
	for _, link in links do
		table.insert(portals, locatePortal(byName[link[1]], byName[link[2]], link[3] or "normal"))
	end
	-- The only route outside is the locked magnetic front door, not LoadingBay.
	local entrance: Portal = {
		a = "Reception", b = "Outside", axis = "z", at = 0, along = -20,
		width = 11, height = 11, kind = "front", name = "FrontDoors",
	}
	table.insert(portals, entrance)

	for _, room in rooms do
		local center = Vector3.new((room.x1 + room.x2) / 2, 0, (room.z1 + room.z2) / 2)
		local width, depth = room.x2 - room.x1, room.z2 - room.z1
		local floorColor = if room.role == "live" then C.floor
			elseif room.role == "booth" then C.foam
			elseif room.role == "service" or room.role == "stair" then C.navy
			else C.teal
		part(structure, room.name .. "_Floor", center - Vector3.new(0, 0.6, 0),
			Vector3.new(width, 1.2, depth), floorColor,
			if room.role == "live" then Enum.Material.WoodPlanks else Enum.Material.Concrete, true)
		part(structure, room.name .. "_Ceiling", center + Vector3.new(0, room.height + 0.55, 0),
			Vector3.new(width, 1.1, depth), C.ceiling, Enum.Material.SmoothPlastic, true)
		side(structure, room, portals, "x", room.x1, room.z1, room.z2, C.wall)
		side(structure, room, portals, "x", room.x2, room.z1, room.z2, C.wall)
		side(structure, room, portals, "z", room.z1, room.x1, room.x2, C.wall)
		side(structure, room, portals, "z", room.z2, room.x1, room.x2, C.wall)

		local roomArea = folder(areas, room.name)
		helper(roomArea, "Bounds", Vector3.new(center.X, room.height / 2, center.Z),
			Vector3.new(width - 0.6, room.height, depth - 0.6))
		helper(roomArea, "Spot", Vector3.new(center.X, 2.5, center.Z))
		if room.role ~= "booth" then
			helper(roomArea, "Spot", Vector3.new(center.X - math.min(width / 4, 12), 2.5, center.Z + math.min(depth / 5, 8)))
			helper(roomArea, "Spot", Vector3.new(center.X + math.min(width / 4, 12), 2.5, center.Z - math.min(depth / 5, 8)))
		end
		if room.name == "LiveHall" or room.name == "ViewingGallery" then
			helper(roomArea, "Spot", Vector3.new(center.X - 24, 2.5, center.Z - 12))
			helper(roomArea, "Spot", Vector3.new(center.X + 24, 2.5, center.Z + 12))
		end

		if room.role == "booth" then
			part(props, "AcousticPanel_" .. room.name, Vector3.new(center.X, 7, room.z1 + 0.9),
				Vector3.new(math.min(width - 5, 24), 8, 0.3), C.foam, Enum.Material.Fabric, false)
		end
		ceilingLamp(lamps, Vector3.new(center.X, room.height - 0.55, center.Z))
		if room.name == "LiveHall" then
			ceilingLamp(lamps, Vector3.new(center.X - 24, room.height - 0.55, center.Z - 17))
			ceilingLamp(lamps, Vector3.new(center.X + 24, room.height - 0.55, center.Z + 17))
		end
		if room.role == "corridor" or room.name == "LiveHall" or room.name == "Reception" then
			helper(markers, "Speaker", Vector3.new(center.X, room.height - 1.5, center.Z))
		end
	end

	for _, p in portals do
		if p.kind == "open" then
			continue
		end
		if p.kind == "short" then
			local gatePos = if p.axis == "x"
				then Vector3.new(p.at, 5.1, p.along) else Vector3.new(p.along, 5.1, p.at)
			local gate = part(shutters, "ShortRouteQuarantine", gatePos,
				if p.axis == "x" then Vector3.new(0.5, 10.2, p.width - 0.2)
					else Vector3.new(p.width - 0.2, 10.2, 0.5), C.navy, Enum.Material.Metal, true)
			gate:SetAttribute("Route", "short")
			gate:SetAttribute("StartsOpen", true)
		else
			local kind = if p.kind == "front" then "front"
				elseif p.kind == "booth" then "booth" else "normal"
			door(doors, p, kind)
			if kind == "booth" then
				local room = if byName[p.a].role == "booth" then byName[p.a] else byName[p.b]
				local zone = helper(booths, room.name, Vector3.new(
					(room.x1 + room.x2) / 2, room.height / 2, (room.z1 + room.z2) / 2),
					Vector3.new(room.x2 - room.x1 - 1.2, room.height, room.z2 - room.z1 - 1.2))
				zone:SetAttribute("Door", p.name)
			end
			-- A second naval quarantine gate marks the production wing; only 'short' drops in Last Call.
			if p.a == "ServiceGallery" and p.b == "LiveAnnex" then
				local at = if p.axis == "x"
					then Vector3.new(p.at, 5.1, p.along) else Vector3.new(p.along, 5.1, p.at)
				local gate = part(shutters, "ProductionWingQuarantine", at,
					if p.axis == "x" then Vector3.new(0.5, 10.2, p.width - 0.1)
						else Vector3.new(p.width - 0.1, 10.2, 0.5), C.navy, Enum.Material.Metal, true)
				gate:SetAttribute("Route", "production")
				gate:SetAttribute("StartsOpen", true)
			end
		end
	end

	-- Entrance threshold and escape volume: players can actually run into it.
	part(structure, "FrontStoop", Vector3.new(-20, -0.6, 6),
		Vector3.new(24, 1.2, 12), C.navy, Enum.Material.Concrete, true)
	helper(objectives, "ExitZone", Vector3.new(-20, 3.5, 5),
		Vector3.new(13, 7, 8))
	local front = doors:FindFirstChild("FrontDoors") :: BasePart
	local slot = objective(objectives, "MailSlot", Vector3.new(-20, 3.7, -0.32),
		Vector3.new(1.9, 0.35, 0.16), C.mustard, false)
	slot.Anchored = false
	local slotWeld = Instance.new("WeldConstraint")
	slotWeld.Part0 = front
	slotWeld.Part1 = slot
	slotWeld.Parent = slot
	part(props, "MagneticLockLeft", Vector3.new(-26.3, 6, -0.5),
		Vector3.new(0.8, 6, 0.8), C.navy, Enum.Material.Metal, false)
	part(props, "MagneticLockRight", Vector3.new(-13.7, 6, -0.5),
		Vector3.new(0.8, 6, 0.8), C.navy, Enum.Material.Metal, false)
	plaque(props, "NAVY QUARANTINE / 1987", Vector3.new(-20, 12, -0.6), Vector3.new(13, 1.5, 0.25))

	-- Objective landmarks (twelve exact names, one Part each).
	part(props, "ReceptionCounter", Vector3.new(-23, 1.5, -15),
		Vector3.new(12, 3, 3), C.floor, Enum.Material.Wood, true)
	objective(objectives, "BookingDiary", Vector3.new(-22, 3.15, -15),
		Vector3.new(2.7, 0.3, 1.7), C.mustard, false)
	plaque(props, "WRENMOUTH / RECORDING", Vector3.new(-21, 10, -29.4), Vector3.new(17, 2, 0.2))

	objective(objectives, "TapeMachine", Vector3.new(-105, 3.3, -117),
		Vector3.new(7, 6.6, 3.2), C.dark, true)
	for i = 1, 3 do
		local reel = part(props, "TapeMachine_ReelGuide", Vector3.new(-107.6 + i * 1.7, 5.2, -115.25),
			Vector3.new(1.5, 1.5, 0.25), C.mustard, Enum.Material.Metal, false)
		reel.Shape = Enum.PartType.Cylinder
	end
	objective(objectives, "MixingDesk", Vector3.new(-97, 1.7, -109),
		Vector3.new(10, 3.4, 3.8), C.teal, true)
	for i = 1, 7 do
		part(props, "DeskFader", Vector3.new(-102 + i * 1.2, 3.45, -108.8),
			Vector3.new(0.25, 0.15, 1.3), C.mustard, nil, false)
	end
	objective(objectives, "PatchBay", Vector3.new(-87, 4, -123),
		Vector3.new(4.5, 5, 0.6), C.navy, true)
	objective(objectives, "SessionLog", Vector3.new(-97, 3.55, -109),
		Vector3.new(2.5, 0.25, 1.5), C.pale, false)

	part(props, "BreakTable", Vector3.new(-92, 1.5, -17),
		Vector3.new(7, 3, 3.5), C.floor, Enum.Material.Wood, true)
	objective(objectives, "Spares", Vector3.new(-109, 3.5, -22),
		Vector3.new(4.8, 7, 3), C.navy, true)
	objective(objectives, "MemorialProgramme", Vector3.new(-92, 3.15, -17),
		Vector3.new(2.2, 0.25, 1.7), C.pale, false)
	objective(objectives, "Safe", Vector3.new(-107, 2.4, -83),
		Vector3.new(4, 4.8, 3.2), C.navy, true)

	-- Archive shelving at the rear wall: four labelled shelf positions, unobstructed aisle.
	for i, x in { -14, -2, 10, 22 } do
		part(props, "ArchiveShelf_" .. tostring(i), Vector3.new(x, 3.5, -185),
			Vector3.new(7.5, 7, 2.2), C.floor, Enum.Material.Wood, true)
		local shelf = helper(markers, "ReelSpot", Vector3.new(x, 4.8, -183.6))
		shelf:SetAttribute("Shelf", tostring(i))
		plaque(props, "SHELF " .. tostring(i), Vector3.new(x, 7.4, -183.6),
			Vector3.new(6, 1.1, 0.2))
	end
	objective(objectives, "CardIndex", Vector3.new(23, 2.75, -169),
		Vector3.new(3.5, 5.5, 2.5), C.teal, true)

	objective(objectives, "RoadCase", Vector3.new(6, 1.55, -103),
		Vector3.new(7, 3.1, 4), C.dark, true)
	part(props, "DrumRiser", Vector3.new(-47, 0.4, -113),
		Vector3.new(11, 0.8, 10), C.floor, Enum.Material.Wood, true)
	for _, x in { -50, -44, -37 } do
		part(props, "MicStand", Vector3.new(x, 3, -112),
			Vector3.new(0.3, 6, 0.3), C.navy, Enum.Material.Metal, false)
	end

	-- Six functional hiding containers; clear approach from their -Z faces.
	local hideData = {
		{ "ArchiveLocker", -14, -168, "locker" },
		{ "ControlAWardrobe", -110, -101, "wardrobe" },
		{ "ControlBLocker", -110, -67, "locker" },
		{ "BreakWardrobe", -108, -7, "wardrobe" },
		{ "ReceptionLocker", 20, -7, "locker" },
		{ "ServiceLocker", 74, -37, "locker" },
		{ "LiveWardrobe", 20, -68, "wardrobe" },
	}
	for _, info in hideData do
		local obj = part(hiding, info[1], Vector3.new(info[2], 3.85, info[3]),
			Vector3.new(3.7, 7.7, 3.4), if info[4] == "locker" then C.navy else C.floor,
			Enum.Material.Wood, true)
		obj:SetAttribute("Kind", info[4])
	end

	for _, at in {
		Vector3.new(-92, 2, -86), Vector3.new(-18, 2, -148),
		Vector3.new(62, 2, -42), Vector3.new(-91, 2, -15),
		Vector3.new(46, 2, 12),
	} do
		helper(markers, "OptionalTapeSpot", at)
	end
	for _, item in {
		{ pos = Vector3.new(-17, 1.2, -19), kind = "bottle" },
		{ pos = Vector3.new(-44, 1.2, -104), kind = "can" },
		{ pos = Vector3.new(45, 1.2, -79), kind = "pipe" },
		{ pos = Vector3.new(-89, 1.2, -10), kind = "can" },
		{ pos = Vector3.new(-9, 1.2, -142), kind = "bottle" },
	} do
		local marker = helper(markers, "Throwable", item.pos)
		marker:SetAttribute("Item", item.kind)
	end

	-- Accessible stair ramp: decorative steps have no collision, closed doors no patrol Areas behind them.
	local ramp = part(structure, "StairCollisionRamp", Vector3.new(57, 4.1, -16),
		Vector3.new(32, 0.8, 8), C.navy, Enum.Material.Concrete, true)
	ramp.CFrame = CFrame.new(57, 4.1, -16) * CFrame.Angles(0, 0, math.rad(14))
	part(structure, "UpperLanding", Vector3.new(75, 7.7, -16),
		Vector3.new(16, 1, 10), C.navy, Enum.Material.Concrete, true)
	for i = 0, 9 do
		part(props, "StairTread", Vector3.new(42 + i * 3.1, i * 0.8 + 0.15, -16),
			Vector3.new(3.1, 0.25, 8), C.mustard, Enum.Material.Concrete, false)
	end
	local down = part(doors, "BasementQuarantine", Vector3.new(46, 5.08, -7),
		Vector3.new(8.5, 9.9, 0.4), C.navy, Enum.Material.Metal, true)
	down:SetAttribute("Kind", "sealed")
	part(props, "BasementSeal", Vector3.new(46, 5.5, -7.25),
		Vector3.new(7, 1.4, 0.2), C.mustard, nil, false)
	local up = part(doors, "FlatBarricade", Vector3.new(83, 13, -16),
		Vector3.new(8.5, 9.9, 0.4), C.floor, Enum.Material.Wood, true)
	up.CFrame *= CFrame.Angles(0, math.rad(90), 0)
	up:SetAttribute("Kind", "barricaded")
	part(props, "BarricadeSilhouette", Vector3.new(83.35, 12.5, -16),
		Vector3.new(0.5, 5, 7), C.dark, Enum.Material.Wood, false)
	plaque(props, "PRIVATE / FLAT", Vector3.new(81.3, 18.9, -16),
		Vector3.new(0.2, 1.1, 7))
	-- Leave the vertical service-lift position reserved for basement/flat chapters.
	part(props, "SealedServiceLift", Vector3.new(67, 5.5, 23),
		Vector3.new(12, 11, 1), C.navy, Enum.Material.Metal, true)
	plaque(props, "NAVY SERVICE LIFT", Vector3.new(67, 11.5, 22.4),
		Vector3.new(10, 1.5, 0.2))

	local playerSpawn = helper(markers, "PlayerSpawn", Vector3.new(-20, 2.5, -8))
	playerSpawn.CFrame = CFrame.lookAt(playerSpawn.Position, playerSpawn.Position + Vector3.new(0, 0, -1))
	helper(markers, "MonsterSpawn", Vector3.new(17, 2.5, -174))

	map.Parent = game:GetService("Workspace")
	return map
end

return StudioGroundFloor
