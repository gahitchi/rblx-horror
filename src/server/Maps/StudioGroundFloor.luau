--!strict
-- Playable chapter 1 ground-floor blockout. Intentionally native Roblox parts:
-- broad silhouettes, warm studio finishes, cold navy closures, low part counts.
-- The old art-pass meshes, realism and asset-validation code are not dependencies.

local StudioLayout = require(script.Parent.StudioLayout)
local StudioProductionDetail = require(script.Parent.StudioProductionDetail)
local StudioCriticalFixtures = require(script.Parent.StudioCriticalFixtures)
local StudioServiceDetail = require(script.Parent.StudioServiceDetail)
local StudioArchitectureDetail = require(script.Parent.StudioArchitectureDetail)
local StudioStoryDetail = require(script.Parent.StudioStoryDetail)
local StudioEvidenceDetail = require(script.Parent.StudioEvidenceDetail)
local StudioLightingRig = require(script.Parent.StudioLightingRig)
local StudioStoreAssets = require(script.Parent.StudioStoreAssets)
local StudioPhysicalAssets = require(script.Parent.StudioPhysicalAssets)
local StudioFurnitureAsset = require(script.Parent.StudioFurnitureAsset)

type Room = StudioLayout.Room
type Portal = {
	a: string,
	b: string,
	axis: string,
	at: number,
	along: number,
	width: number,
	height: number,
	kind: string,
	name: string,
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
	parent: Instance,
	name: string,
	at: Vector3,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?
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

-- Open-front, structurally coherent desk cover. The old solid counter blocks
-- all underside space; this shape has a real hollow knee bay, grounded side
-- panels, a tabletop and a back modesty screen that blocks vision rays.
-- The actual Hide trigger is an invisible marker in Map.HidingSpots.
local function underDesk(
	props: Instance,
	hiding: Instance,
	name: string,
	x: number, z: number,
	width: number, depth: number,
	height: number,
	facing: number,
	color: Color3
)
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(facing), 0)
	-- The maintenance desk is a steel industrial station. The creative
	-- working tables are period-appropriate stained wooden joinery.
	local workMaterial = if name == "ServiceMaintenanceDesk"
		then Enum.Material.Metal else Enum.Material.Wood
	local function board(id: string, dx: number, y: number, dz: number,
		w: number, h: number, d: number, material: Enum.Material)
		local p = part(props, name .. id,
			(cf * CFrame.new(dx, y, dz)).Position, Vector3.new(w,h,d),
			color, material, true)
		p.CFrame = cf * CFrame.new(dx, y, dz)
		return p
	end
	board("Top", 0, height, 0, width, 0.28, depth, workMaterial)
	-- Four corner posts keep the knee bay open. Old full-depth side
	-- "legs" were walls that made every desk look like a box.
	for _, sx in {-1,1} do
		for _, sz in {-1,1} do
			board("Leg", sx*(width/2-0.32), (height-0.24)/2,
				sz*(depth/2-0.30), 0.44,height-0.24,0.44,workMaterial)
		end
	end
	-- Front = local negative Z. No solid panel covers the front opening;
	-- Engineer must walk over and look under the actual table.
	board("BackScreen", 0, (height - 0.24) / 2, depth / 2 - 0.16,
		width - 0.6, height - 0.24, 0.28, workMaterial)
	board("FrontLip", 0, height - 0.25, -depth / 2 + 0.12,
		width - 0.65, 0.42, 0.20, workMaterial)
	-- The furniture has a mechanical reason to stand: a real floor-mounted
	-- back screen and edge rails, not a rectangular phantom floating over
	-- an invisible hiding volume. Everything follows the exact local basis.
	local function trim(id: string, dx: number, y: number, dz: number,
		w: number, h: number, d: number, tint: Color3)
		local p = part(props, name .. id,
			(cf * CFrame.new(dx, y, dz)).Position, Vector3.new(w, h, d),
			tint, workMaterial, false)
		p.CFrame = cf * CFrame.new(dx, y, dz)
	end
	for _, side in { -1, 1 } do
		trim("TopEdgeRail", side * (width/2 - 0.10), height + 0.075, 0,
			0.14, 0.07, depth - 0.18, C.floor)
		trim("SideApron",side*(width/2-0.31),height-0.49,0,
			0.13,0.43,depth-0.6,C.floor)
	end
	trim("ToeKick", 0, 0.22, depth/2 - 0.26,
		width - 0.65, 0.23, 0.14, C.navy)
	trim("LongEdgeRail", 0, height + 0.075, -depth/2 + 0.095,
		width - 0.23, 0.07, 0.14, C.floor)
	trim("BackTopRail", 0, height + 0.075, depth/2 - 0.095,
		width - 0.23, 0.07, 0.14, C.floor)
	-- Small stationery drawer on the right, outside the central hiding bay.
	trim("DrawerFace",width/2-1.18,height-0.45,-depth/2+0.12,
		1.63,0.38,0.16,C.floor)
	trim("DrawerPull",width/2-1.18,height-0.43,-depth/2-0.006,
		0.62,0.09,0.12,C.navy)
	local marker = part(hiding, name .. "Cover", (cf * CFrame.new(0, 1.2, 0)).Position,
		Vector3.new(math.min(width - 1.2, 3.6), 2.4, math.min(depth - 0.6, 2.6)),
		C.mustard, nil, false)
	marker.CFrame = cf * CFrame.new(0, 1.2, 0)
	marker.Transparency = 1
	marker.CastShadow = false
	marker:SetAttribute("Kind", "underdesk")
	marker:SetAttribute("CoverName", name)
	marker:SetAttribute("ExitClearance", 2.5)
	return marker
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
	-- Shelf numbers and reception lettering face the aisle; security seals face the entry.
	gui.Face = if string.find(caption, "SHELF", 1, true)
			or string.find(caption, "WRENMOUTH", 1, true)
		then Enum.NormalId.Back
		else Enum.NormalId.Front
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
		assert(
			math.abs(a.z2 - b.z1) < 0.01 or math.abs(b.z2 - a.z1) < 0.01,
			a.name .. " / " .. b.name .. " are not adjacent"
		)
		axis = "z"
		at = if math.abs(a.z2 - b.z1) < 0.01 then a.z2 else b.z2
		local lo, hi = math.max(a.x1, b.x1), math.min(a.x2, b.x2)
		overlap = hi - lo
		along = (lo + hi) / 2
	end
	assert(overlap >= 12, "portal too narrow: " .. a.name .. " / " .. b.name)
	return {
		a = a.name,
		b = b.name,
		axis = axis,
		at = at,
		along = along,
		width = if kind == "open" then 15 else 9,
		height = if kind == "open" then 12 else 10.5,
		kind = kind,
		name = "Door_" .. a.name .. "_" .. b.name,
	}
end

local function wallPiece(
	parent: Instance,
	axis: string,
	at: number,
	lo: number,
	hi: number,
	bottom: number,
	top: number,
	color: Color3
)
	if hi - lo < 0.04 or top - bottom < 0.04 then
		return
	end
	if axis == "x" then
		part(
			parent,
			"Wall",
			Vector3.new(at, (bottom + top) / 2, (lo + hi) / 2),
			Vector3.new(0.8, top - bottom, hi - lo),
			color,
			Enum.Material.Concrete,
			true
		)
	else
		part(
			parent,
			"Wall",
			Vector3.new((lo + hi) / 2, (bottom + top) / 2, at),
			Vector3.new(hi - lo, top - bottom, 0.8),
			color,
			Enum.Material.Concrete,
			true
		)
	end
end

local function side(
	parent: Instance,
	room: Room,
	portals: { Portal },
	axis: string,
	at: number,
	lo: number,
	hi: number,
	color: Color3
)
	local gaps: { Portal } = {}
	for _, p in portals do
		if
			(p.a == room.name or p.b == room.name)
			and p.axis == axis
			and math.abs(p.at - at) < 0.01
			and p.along + p.width / 2 > lo
			and p.along - p.width / 2 < hi
		then
			table.insert(gaps, p)
		end
	end
	table.sort(gaps, function(a, b)
		return a.along < b.along
	end)
	local cursor = lo
	for _, gap in gaps do
		local left, right =
			math.max(lo, gap.along - gap.width / 2), math.min(hi, gap.along + gap.width / 2)
		assert(left >= cursor - 0.01, "overlapping door openings in " .. room.name)
		wallPiece(parent, axis, at, cursor, left, 0, room.height, color)
		if gap.kind == "window" then
			wallPiece(parent, axis, at, left, right, 0, 5.5, color)
		end
		wallPiece(parent, axis, at, left, right, gap.height, room.height, color)
		cursor = right
	end
	wallPiece(parent, axis, at, cursor, hi, 0, room.height, color)
end

local function door(parent: Instance, decor: Instance, p: Portal, kind: string): Part
	local center = if p.axis == "x"
		then Vector3.new(p.at, 5.08, p.along)
		else Vector3.new(p.along, 5.08, p.at)
	local leaf = part(
		parent,
		p.name,
		center,
		Vector3.new(p.width - 0.3, 9.9, 0.36),
		if kind == "booth" then C.foam else C.teal,
		Enum.Material.Wood,
		true
	)
	if p.axis == "x" then
		leaf.CFrame *= CFrame.Angles(0, math.rad(90), 0)
	end
	leaf:SetAttribute("Kind", kind)
	leaf:SetAttribute("Open", false)
	local handle = part(
		decor,
		"DoorGrip_" .. p.name,
		center + Vector3.new(0, 0, 0),
		Vector3.new(0.35, 0.8, 0.14),
		C.mustard,
		Enum.Material.Metal,
		false
	)
	handle.Anchored = false
	handle.CFrame = leaf.CFrame * CFrame.new(p.width / 2 - 1.1, -0.6, -0.27)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = leaf
	weld.Part1 = handle
	weld.Parent = handle
	return leaf
end

local function objective(
	parent: Instance,
	name: string,
	at: Vector3,
	size: Vector3,
	color: Color3,
	solid: boolean?
): Part
	return part(parent, name, at, size, color, Enum.Material.SmoothPlastic, solid)
end

local function ceilingLamp(parent: Instance, at: Vector3, castShadows: boolean?)
	local fitting = part(parent, "Practical", at, Vector3.new(4, 0.3, 2), C.pale, nil, false)
	local light = Instance.new("PointLight")
	light.Enabled = false
	light.Range = 30
	light.Brightness = 0.55
	-- Reserve expensive dynamic shadows for only a couple of landmark fixtures.
	light.Shadows = castShadows == true
	light.Parent = fitting
end

function StudioGroundFloor.build(): Model
	local map = Instance.new("Model")
	map.Name = "Map"
	map:SetAttribute("MapName", "Wrenmouth Recording House / Chapter 1")
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
	-- Acoustic sightlines: windows are not doorways. The solid glass keeps sound occlusion.
	table.insert(portals, {
		a = "ControlA",
		b = "LiveHall",
		axis = "x",
		at = -34,
		along = -97,
		width = 10,
		height = 12.5,
		kind = "window",
		name = "TrackingWindow",
	})
	table.insert(portals, {
		a = "LiveHall",
		b = "ViewingGallery",
		axis = "z",
		at = -58,
		along = 29,
		width = 15,
		height = 12.5,
		kind = "window",
		name = "ViewingWindow",
	})
	local entrance: Portal = {
		a = "Reception",
		b = "Outside",
		axis = "z",
		at = 24,
		along = -43,
		width = 11,
		height = 11,
		kind = "front",
		name = "FrontDoors",
	}
	table.insert(portals, entrance)

	-- The union of room rectangles is not a grid. When only part of an east/south
	-- edge borders a room, fill the uncovered segments rather than leaving holes.
	local function uncovered(room: Room, axis: string, at: number, startAt: number, stopAt: number)
		local intervals: { { number } } = {}
		for _, other in rooms do
			if other == room then
				continue
			end
			if axis == "x" and math.abs(other.x1 - at) < 0.01 then
				local lo = math.max(startAt, other.z1)
				local hi = math.min(stopAt, other.z2)
				if hi > lo then
					table.insert(intervals, { lo, hi })
				end
			elseif axis == "z" and math.abs(other.z1 - at) < 0.01 then
				local lo = math.max(startAt, other.x1)
				local hi = math.min(stopAt, other.x2)
				if hi > lo then
					table.insert(intervals, { lo, hi })
				end
			end
		end
		table.sort(intervals, function(a, b)
			return a[1] < b[1]
		end)
		local cursor = startAt
		for _, interval in intervals do
			if interval[1] > cursor then
				side(structure, room, portals, axis, at, cursor, interval[1], C.wall)
			end
			cursor = math.max(cursor, interval[2])
		end
		if cursor < stopAt then
			side(structure, room, portals, axis, at, cursor, stopAt, C.wall)
		end
	end

	-- Spaces are ordered by studio workflow instead of an unrelated game tile grid:
	-- public front-of-house, acoustic production, and an eastern navy service spine.
	for _, room in rooms do
		local center = Vector3.new((room.x1 + room.x2) / 2, 0, (room.z1 + room.z2) / 2)
		local width, depth = room.x2 - room.x1, room.z2 - room.z1
		local floorColor = if room.role == "live"
			then C.floor
			elseif room.role == "booth" then C.foam
			elseif room.role == "service" or room.role == "stair" then C.navy
			elseif room.role == "washroom" then C.pale
			elseif room.role == "control" then C.teal
			else C.wall
		part(
			structure,
			room.name .. "_Floor",
			Vector3.new(center.X, -0.6, center.Z),
			Vector3.new(width, 1.2, depth),
			floorColor,
			if room.role == "live" or room.role == "break"
				then Enum.Material.WoodPlanks
				else Enum.Material.Concrete,
			true
		)
		part(
			structure,
			room.name .. "_Ceiling",
			Vector3.new(center.X, room.height + 0.55, center.Z),
			Vector3.new(width, 1.1, depth),
			C.ceiling,
			nil,
			true
		)
		-- West and north walls are owned by this room; shared east/south
		-- faces are owned by their neighbors. Prevents doubled acoustic walls.
		side(structure, room, portals, "x", room.x1, room.z1, room.z2, C.wall)
		side(structure, room, portals, "z", room.z1, room.x1, room.x2, C.wall)
		uncovered(room, "x", room.x2, room.z1, room.z2)
		uncovered(room, "z", room.z2, room.x1, room.x2)

		local roomArea = folder(areas, room.name)
		helper(
			roomArea,
			"Bounds",
			Vector3.new(center.X, room.height / 2, center.Z),
			Vector3.new(width - 0.6, room.height, depth - 0.6)
		)
		-- Default unobstructed center spot plus service/large-room patrol points.
		local authoredSpots: { [string]: { Vector3 } } = {
			TapeArchive = { Vector3.new(-71, 2.5, -119), Vector3.new(-76, 2.5, -118) },
			ControlA = {
				Vector3.new(-59, 2.5, -84),
				Vector3.new(-74, 2.5, -73),
				Vector3.new(-45, 2.5, -85),
				Vector3.new(-66, 2.5, -67),
			},
			ControlB = { Vector3.new(-59, 2.5, -44), Vector3.new(-75, 2.5, -37) },
			BreakRoom = {
				Vector3.new(-67, 2.5, -23),
				Vector3.new(-44, 2.5, -11),
				Vector3.new(-74, 2.5, -15),
			},
			Reception = {
				Vector3.new(-38, 2.5, 8),
				Vector3.new(-20, 2.5, 18),
				Vector3.new(-69, 2.5, -2),
				Vector3.new(-74, 2.5, 13),
			},
			ServicePass = { Vector3.new(61, 2.5, -82), Vector3.new(70, 2.5, -76) },
			LiveHall = {
				Vector3.new(5, 2.5, -82),
				Vector3.new(-25, 2.5, -86),
				Vector3.new(-6, 2.5, -69),
				Vector3.new(24, 2.5, -99),
				Vector3.new(35, 2.5, -70),
			},
		}
		local points: { Vector3 } = authoredSpots[room.name]
			or { Vector3.new(center.X, 2.5, center.Z) }
		if
			authoredSpots[room.name] == nil
			and width >= 40
			and depth >= 24
			and room.role ~= "washroom"
		then
			table.insert(points, Vector3.new(center.X - width / 4, 2.5, center.Z - depth / 5))
			table.insert(points, Vector3.new(center.X + width / 4, 2.5, center.Z + depth / 5))
		end
		for _, at in points do
			helper(roomArea, "Spot", at)
		end
		ceilingLamp(
			lamps,
			Vector3.new(center.X, room.height - 0.6, center.Z),
			room.name == "LiveHall" or room.name == "Reception"
		)
		if room.name == "LiveHall" then
			ceilingLamp(lamps, Vector3.new(center.X - 20, room.height - 0.6, center.Z + 12))
			ceilingLamp(lamps, Vector3.new(center.X + 20, room.height - 0.6, center.Z - 12))
		end
		if room.role == "booth" then
			part(
				props,
				"AcousticDamping_" .. room.name,
				Vector3.new(center.X, 7, room.z1 + 0.8),
				Vector3.new(width - 4, 8, 0.24),
				C.foam,
				Enum.Material.Fabric,
				false
			)
		end
		if room.role == "corridor" or room.name == "LiveHall" or room.name == "Reception" then
			helper(markers, "Speaker", Vector3.new(center.X, room.height - 1.5, center.Z))
		end
	end

	for _, p in portals do
		if p.kind == "open" or p.kind == "window" then
			if p.kind == "window" then
				local centre = if p.axis == "x"
					then Vector3.new(p.at, 9, p.along)
					else Vector3.new(p.along, 9, p.at)
				local size = if p.axis == "x"
					then Vector3.new(0.4, 7, p.width)
					else Vector3.new(p.width, 7, 0.4)
				local glass = part(
					structure,
					p.name,
					centre,
					size,
					Color3.fromRGB(96, 153, 156),
					Enum.Material.Glass,
					true
				)
				glass.Transparency = 0.45
			end
			continue
		end
		if p.kind == "short" then
			local center = if p.axis == "x"
				then Vector3.new(p.at, 5.1, p.along)
				else Vector3.new(p.along, 5.1, p.at)
			local size = if p.axis == "x"
				then Vector3.new(0.5, 10.2, p.width - 0.2)
				else Vector3.new(p.width - 0.2, 10.2, 0.5)
			local shutter = part(
				shutters,
				"ShortRouteQuarantine",
				center,
				size,
				C.navy,
				Enum.Material.Metal,
				true
			)
			shutter:SetAttribute("Route", "short")
			shutter:SetAttribute("StartsOpen", true)
			continue
		end
		local kind = if p.kind == "front"
			then "front"
			elseif p.kind == "booth" then "booth"
			else "normal"
		door(doors, props, p, kind)
		if kind == "booth" then
			local room = if byName[p.a].role == "booth" then byName[p.a] else byName[p.b]
			local zone = helper(
				booths,
				room.name,
				Vector3.new((room.x1 + room.x2) / 2, room.height / 2, (room.z1 + room.z2) / 2),
				Vector3.new(room.x2 - room.x1 - 1.2, room.height, room.z2 - room.z1 - 1.2)
			)
			zone:SetAttribute("Door", p.name)
		end
		if p.a == "ServicePass" and p.b == "LoadingBay" then
			local g = part(
				shutters,
				"LoadingQuarantine",
				Vector3.new(80, 5.1, p.along),
				Vector3.new(0.5, 10.2, p.width - 0.2),
				C.navy,
				Enum.Material.Metal,
				true
			)
			g:SetAttribute("Route", "loading")
			g:SetAttribute("StartsOpen", true)
		end
	end

	-- Reception: front-of-house desk, dated records and the only round exit.
	-- The reception desk is a genuine hollow working counter rather than a
	-- rectangular collision block. Diary and dressing retain their position.
	underDesk(props, hiding, "ReceptionCounter", -52, 11, 11, 3.6, 3.1, 180, C.floor)
	objective(
		objectives,
		"BookingDiary",
		Vector3.new(-52, 3.25, 11),
		Vector3.new(2.2, 0.3, 1.5),
		C.mustard,
		false
	)
	plaque(
		props,
		"WRENMOUTH RECORDING / EST. 1974",
		Vector3.new(-43, 13, -6.5),
		Vector3.new(27, 1.9, 0.2)
	)
	local front = doors:FindFirstChild("FrontDoors") :: BasePart
	local slot = objective(
		objectives,
		"MailSlot",
		Vector3.new(-43, 3.7, 23.67),
		Vector3.new(2, 0.3, 0.16),
		C.mustard,
		false
	)
	slot.Anchored = false
	local slotWeld = Instance.new("WeldConstraint")
	slotWeld.Part0 = front
	slotWeld.Part1 = slot
	slotWeld.Parent = slot
	part(
		structure,
		"FrontStoop",
		Vector3.new(-43, -0.6, 29),
		Vector3.new(24, 1.2, 12),
		C.navy,
		Enum.Material.Concrete,
		true
	)
	helper(objectives, "ExitZone", Vector3.new(-43, 3.5, 30), Vector3.new(14, 7, 9))
	plaque(
		props,
		"1987 / MAGNETIC QUARANTINE",
		Vector3.new(-43, 12.1, 23.5),
		Vector3.new(18, 1.4, 0.2)
	)

	-- Tape/control cluster: the engineer can directly see the live performance.
	objective(
		objectives,
		"TapeMachine",
		Vector3.new(-73, 3.3, -94),
		Vector3.new(7, 6.6, 3),
		C.dark,
		true
	)
	-- TapeMachine has one consolidated detailed transport facade in
	-- StudioProductionDetail; avoid overlapping duplicate phantom reels.
	objective(
		objectives,
		"MixingDesk",
		Vector3.new(-56, 1.6, -78),
		Vector3.new(11, 3.2, 4),
		C.teal,
		true
	)
	-- The original gameplay volume is preserved. The actual 16-channel
	-- hero visual is built by StudioHeroConsole in the production dressing.
	-- Move the same SessionLog objective to a visible reader shelf in front
	-- of the desk instead of covering the EQ/faders with the paper prompt.
	objective(
		objectives,
		"SessionLog",
		Vector3.new(-57, 3.68, -75.65),
		Vector3.new(2, 0.2, 1.2),
		C.pale,
		false
	)
	objective(
		objectives,
		"PatchBay",
		Vector3.new(-39, 3.6, -96),
		Vector3.new(4, 4.8, 0.7),
		C.navy,
		true
	)
	objective(objectives, "Safe", Vector3.new(-75, 2.5, -48), Vector3.new(4, 5, 3), C.navy, true)

	-- Archive: index at the door, shelving on rear and side walls.
	local cardIndex = objective(
		objectives,
		"CardIndex",
		Vector3.new(-79, 2.6, -113),
		Vector3.new(3.2, 5.2, 2.3),
		C.teal,
		true
	)
	StudioFurnitureAsset.cardIndex(props, cardIndex)
	for i, x in { -77, -72, -67, -62 } do
		-- Rear-wall shelves stand on the floor, with real open bays and
		-- three solid decks; no solid, featureless monolithic crate.
		StudioFurnitureAsset.archiveShelf(props, "ArchiveShelf_" .. tostring(i), x, -132.65)
		-- Chapter's ReelSpot remains an actual reachable prompt from aisle.
		local mark = helper(markers, "ReelSpot", Vector3.new(x, 5.3, -130.9))
		mark:SetAttribute("Shelf", tostring(i))
		plaque(
			props, "SHELF " .. tostring(i),
			Vector3.new(x, 6.88, -131.67),
			Vector3.new(3.65, 0.64, 0.12)
		)
	end
	-- Studio live hall: central playable tracking space, not an obstacle field.
	local storyCase = objective(
		objectives,
		"RoadCase",
		Vector3.new(19, 1.6, -81),
		Vector3.new(6, 3.2, 4),
		C.dark,
		true
	)
	-- The original objective remains anchored and interactable, but its
	-- metal body now has real fitted trim, latches and visible handles.
	StudioPhysicalAssets.finishObjectiveRoadCase(props, storyCase)
	part(
		props,
		"InstrumentRiser",
		Vector3.new(-18, 0.35, -96),
		Vector3.new(10, 0.7, 7),
		C.floor,
		Enum.Material.WoodPlanks,
		true
	)
	-- No freestanding unmounted microphone poles on the tracking riser:
	-- actual supported microphone rigs are authored in ProductionDetail.
	plaque(props, "LIVE RECORDING / QUIET", Vector3.new(5, 9, -57.7), Vector3.new(16, 1.4, 0.2))

	-- Staff and visitor needs: two toilets in the correct zones and a janitor store.
	underDesk(props, hiding, "BreakTable", -55, -17.5, 7, 3.5, 3.0, 180, C.floor)
	objective(
		objectives,
		"MemorialProgramme",
		Vector3.new(-55, 3.2, -17.5),
		Vector3.new(2.3, 0.2, 1.5),
		C.pale,
		false
	)
	local spares = objective(
		objectives,
		"Spares",
		Vector3.new(-78, 3.5, -23),
		Vector3.new(4, 7, 2.7),
		C.navy,
		true
	)
	StudioFurnitureAsset.objectiveCabinet(props, spares, "SPARES / STAFF")
	-- Restroom fixtures and janitor storage are each built ONCE in
	-- StudioServiceDetail. Removed old duplicate toilets, sinks, a giant
	-- phantom JanitorShelf and redundant mop bucket.
	plaque(props, "CLEANING / STAFF ONLY", Vector3.new(65, 9, -18), Vector3.new(9, 1.1, 0.2))

	-- Load-in for instruments (no extra exterior escape) and dedicated machine racks.
	for _, x in { 51, 61, 71 } do
		-- Actual rack assemblies with aligned controls and one defined
		-- solid chassis, rather than featureless standing cuboids.
		StudioFurnitureAsset.rack(props, "MachineRack_" .. tostring(x), x, -127, 4, 8, 0)
	end
	-- Physical 4-wheel flight case in the loading zone, away from the
	-- Last Call path. Wheels turn with HingeConstraints when players push it.
	StudioPhysicalAssets.roadCase(props, "LoadingFlightCase", 97, -96, 0)

	-- Existing furniture becomes the hiding space: small under-desk bays,
	-- not a line of gigantic wardrobes randomly blocking room circulation.
	-- Reception and BreakTable were registered where their original solid
	-- furniture used to be, so clue positions stay unchanged.
	underDesk(props, hiding, "ArchiveSortingDesk", -66, -114, 7.6, 3.8, 3.15, 0, C.floor)
	underDesk(props, hiding, "ServiceMaintenanceDesk", 67, -78, 7.0, 3.9, 3.15, 90, C.navy)
	underDesk(props, hiding, "LiveRoomMusicDesk", -10, -67, 7.4, 3.8, 3.15, 180, C.floor)
	-- Control B has its own open-legged edit counter built by production
	-- dressing. Reuse the real furniture instead of building a clone.
	local editCover = helper(hiding, "ControlBEditCover",
		Vector3.new(-52, 1.2, -52), Vector3.new(3.4, 2.4, 2.6))
	editCover.CFrame = CFrame.new(-52, 1.2, -52) * CFrame.Angles(0, math.rad(180), 0)
	editCover:SetAttribute("Kind", "underdesk")
	editCover:SetAttribute("CoverName", "EditCounter")
	editCover:SetAttribute("ExitClearance", 2.5)

	for _, pos in
		{
			Vector3.new(-55, 1.4, -42),
			Vector3.new(1, 1.4, -42),
			Vector3.new(78, 1.4, -67),
			Vector3.new(-43, 3.3, -16),
			Vector3.new(91, 1.4, -81),
			Vector3.new(-63, 3.1, -118),
		}
	do
		helper(markers, "OptionalTapeSpot", pos)
	end
	for _, spec in
		{
			{ at = Vector3.new(-63, 1.1, 15), item = "bottle" },
			{ at = Vector3.new(-13, 1.1, -75), item = "can" },
			{ at = Vector3.new(67, 1.1, -91), item = "pipe" },
			{ at = Vector3.new(-50, 1.1, -23), item = "can" },
			{ at = Vector3.new(95, 1.1, -73), item = "pipe" },
		}
	do
		helper(markers, "Throwable", spec.at):SetAttribute("Item", spec.item)
	end

	-- Stairwell is visible from front-of-house, but the two later chapters remain shut.
	local ramp = part(
		structure,
		"StairCollisionRamp",
		Vector3.new(71, 3.9, 14.7),
		Vector3.new(9, 0.9, 15),
		C.navy,
		Enum.Material.Concrete,
		true
	)
	ramp.CFrame = CFrame.new(71, 3.9, 14.7) * CFrame.Angles(math.rad(-26), 0, 0)
	part(
		structure,
		"StairLanding",
		Vector3.new(71, 7.3, 21),
		Vector3.new(11, 0.9, 5),
		C.navy,
		Enum.Material.Concrete,
		true
	)
	for i = 0, 6 do
		part(
			props,
			"Step",
			Vector3.new(71, i + 0.15, 8.8 + i * 1.8),
			Vector3.new(9, 0.2, 1.8),
			C.mustard,
			Enum.Material.Concrete,
			false
		)
	end
	local sealed = part(
		doors,
		"BasementQuarantine",
		Vector3.new(71, 5.1, 7.1),
		Vector3.new(8.4, 10, 0.4),
		C.navy,
		Enum.Material.Metal,
		true
	)
	sealed:SetAttribute("Kind", "sealed")
	plaque(
		props,
		"NAVY / BASEMENT SEALED 1987",
		Vector3.new(71, 10.2, 6.8),
		Vector3.new(11, 1.1, 0.2)
	)
	local flat = part(
		doors,
		"FlatBarricade",
		Vector3.new(71, 12.3, 23.2),
		Vector3.new(8.4, 9.9, 0.4),
		C.floor,
		Enum.Material.Wood,
		true
	)
	flat:SetAttribute("Kind", "barricaded")
	plaque(props, "FLAT / BARRICADED", Vector3.new(71, 17.9, 23.5), Vector3.new(11, 1.1, 0.2))
	-- Future lift shaft from basement to flat, reached through the rear load-in.
	part(
		props,
		"NavyLiftShaftSeal",
		Vector3.new(103, 5.5, -101),
		Vector3.new(11, 11, 0.8),
		C.navy,
		Enum.Material.Metal,
		true
	)
	plaque(props, "NAVY SERVICE LIFT", Vector3.new(103, 11.5, -100.45), Vector3.new(11, 1.1, 0.2))

	local spawn = helper(markers, "PlayerSpawn", Vector3.new(-43, 2.5, 17))
	spawn.CFrame = CFrame.lookAt(spawn.Position, spawn.Position + Vector3.new(0, 0, -1))
	helper(markers, "MonsterSpawn", Vector3.new(0, 2.5, -82))

	-- Phase 1 dressing is additive: the map contract and objective parts remain authoritative.
	StudioProductionDetail.apply(map)
	StudioCriticalFixtures.apply(map)
	StudioServiceDetail.apply(map)
	StudioArchitectureDetail.apply(map)
	StudioStoryDetail.apply(map)
	StudioEvidenceDetail.apply(map)
	-- Lighting is a separately authored system. Apply after visual dressing so
	-- all original ceiling and accent fixtures receive the correct room profile.
	StudioLightingRig.apply(map)
	-- Optional saved Creator Store geometry, with native fallbacks when nothing is staged.
	StudioStoreAssets.apply(map)

	map.Parent = game:GetService("Workspace")
	return map
end

return StudioGroundFloor
