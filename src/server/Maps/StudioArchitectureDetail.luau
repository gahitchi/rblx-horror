--!strict
-- Architectural finish tied to the actual room graph. No mesh assets or PBR textures.
-- Door frames are non-solid and do not narrow the contract's nine-stud portals.
local StudioLayout = require(script.Parent.StudioLayout)
local Kit = require(script.Parent.StudioDecorKit)
local C = Kit.palette

local Detail = {}

local function portal(a: StudioLayout.Room, b: StudioLayout.Room): (string, number, number)
	if a.x2 == b.x1 then
		return "x", a.x2, (math.max(a.z1, b.z1) + math.min(a.z2, b.z2)) / 2
	elseif b.x2 == a.x1 then
		return "x", b.x2, (math.max(a.z1, b.z1) + math.min(a.z2, b.z2)) / 2
	elseif a.z2 == b.z1 then
		return "z", a.z2, (math.max(a.x1, b.x1) + math.min(a.x2, b.x2)) / 2
	end
	return "z", b.z2, (math.max(a.x1, b.x1) + math.min(a.x2, b.x2)) / 2
end

local function doorFrame(
	parent: Instance, axis: string, at: number, along: number,
	width: number, kind: string
)
	if kind == "open" then
		return
	end
	local color = if kind == "booth" then C.wood
		elseif kind == "short" then C.gold else C.metal
	local sideDistance = width / 2 + 0.26
	for _, sign in { -1, 1 } do
		local pos = along + sideDistance * sign
		if axis == "x" then
			Kit.box(parent, "DoorFrameJamb", at, 5.15, pos, 0.65, 10.3, 0.44,
				color, Enum.Material.Metal)
		else
			Kit.box(parent, "DoorFrameJamb", pos, 5.15, at, 0.44, 10.3, 0.65,
				color, Enum.Material.Metal)
		end
	end
	if axis == "x" then
		Kit.box(parent, "DoorFrameLintel", at, 10.5, along, 0.65, 0.45,
			width + 1, color, Enum.Material.Metal)
	else
		Kit.box(parent, "DoorFrameLintel", along, 10.5, at, width + 1,
			0.45, 0.65, color, Enum.Material.Metal)
	end
	-- Distinct navy staff gates; a visible frame communicates closure before Last Call.
	if kind == "short" then
		if axis == "x" then
			Kit.box(parent, "ShutterWarningBand", at - 0.45, 10.4, along,
				0.14, 0.45, width - 0.8, C.red)
		else
			Kit.box(parent, "ShutterWarningBand", along, 10.4, at - 0.45,
				width - 0.8, 0.45, 0.14, C.red)
		end
	end
end

local function glassMullion(parent: Instance, axis: string, at: number, along: number, width: number)
	local color = C.woodLight
	local left, right = along - width / 2, along + width / 2
	for _, v in { left, (left + right) / 2, right } do
		if axis == "x" then
			Kit.box(parent, "GlazedStudioMullion", at - 0.27, 9, v,
				0.2, 7.1, 0.26, color, Enum.Material.Wood)
		else
			Kit.box(parent, "GlazedStudioMullion", v, 9, at - 0.27,
				0.26, 7.1, 0.2, color, Enum.Material.Wood)
		end
	end
	for _, y in { 5.4, 12.6 } do
		if axis == "x" then
			Kit.box(parent, "GlazedStudioRail", at - 0.27, y, along,
				0.3, 0.23, width + 0.3, color, Enum.Material.Wood)
		else
			Kit.box(parent, "GlazedStudioRail", along, y, at - 0.27,
				width + 0.3, 0.23, 0.3, color, Enum.Material.Wood)
		end
	end
end

local function wallTrim(parent: Instance, room: StudioLayout.Room)
	-- Low, paper-thin baseboards make the 1980s rooms feel finished without
	-- making extra CanQuery acoustic barriers or physical steps at doors.
	local x = (room.x1 + room.x2) / 2
	local z = (room.z1 + room.z2) / 2
	local w, d = room.x2 - room.x1, room.z2 - room.z1
	local trim = if room.role == "washroom" then C.teal
		elseif room.role == "service" or room.role == "stair" then C.steel
		else C.wood
	Kit.box(parent, "FloorSkirtingWest", room.x1 + 0.46, 0.22, z,
		0.15, 0.44, d - 0.9, trim, Enum.Material.Wood)
	Kit.box(parent, "FloorSkirtingEast", room.x2 - 0.46, 0.22, z,
		0.15, 0.44, d - 0.9, trim, Enum.Material.Wood)
	Kit.box(parent, "FloorSkirtingNorth", x, 0.22, room.z1 + 0.46,
		w - 0.9, 0.44, 0.15, trim, Enum.Material.Wood)
	Kit.box(parent, "FloorSkirtingSouth", x, 0.22, room.z2 - 0.46,
		w - 0.9, 0.44, 0.15, trim, Enum.Material.Wood)
	-- A restrained trim line near the ceiling leads the eye around the floor.
	local h = room.height - 1.25
	Kit.box(parent, "UpperTrimWest", room.x1 + 0.47, h, z,
		0.1, 0.18, d - 1, trim, Enum.Material.Wood)
	Kit.box(parent, "UpperTrimNorth", x, h, room.z1 + 0.46,
		w - 1, 0.18, 0.1, trim, Enum.Material.Wood)
	if room.role == "live" or room.role == "control" or room.role == "booth" then
		-- Acoustic treatment above head height, not on the gameplay path.
		for _, i in { 0.23, 0.77 } do
			local xx = room.x1 + i * w
			Kit.box(parent, "CeilingTimberRib", xx, room.height - 0.38, z,
				0.4, 0.48, d - 1.3, C.wood, Enum.Material.Wood)
		end
	end
end

local function mainFacade(parent: Instance)
	local porch = Kit.group(parent, "Frontage")
	for _, x in { -57, -29 } do
		Kit.box(porch, "PorticoColumn", x, 5.8, 31.5, 1.1, 11.6, 1.2,
			C.wood, Enum.Material.Wood)
		Kit.box(porch, "PorchLanternHousing", x, 10.8, 30.6,
			2.4, 2.5, 0.8, C.metal, Enum.Material.Metal)
	end
	Kit.box(porch, "PorchLintel", -43, 12.1, 31.5, 30, 0.7, 1.1,
		C.woodLight, Enum.Material.Wood)
	Kit.sign(porch, "WRENMOUTH RECORDING HOUSE", CFrame.new(-43, 15.6, 24.65),
		Vector3.new(35, 2.4, 0.17), Enum.NormalId.Back, C.cream)
	Kit.sign(porch, "CLOSED BY ORDER OF THE NAVY - OCTOBER 1987",
		CFrame.new(-43, 10.5, 24.7), Vector3.new(23, 1.25, 0.15),
		Enum.NormalId.Back, C.red, C.paper)
	for _, x in { -50, -36 } do
		Kit.box(porch, "FrontLockShield", x, 5.1, 24.48,
			1.1, 7.7, 0.28, C.metal, Enum.Material.Metal)
		for _, y in { 2.7, 5.1, 7.5 } do
			Kit.box(porch, "LockBoltHead", x, y, 24.7, 0.35, 0.35, 0.12,
				C.gold, Enum.Material.Metal)
		end
	end
end

function Detail.apply(map: Model)
	local props = map:FindFirstChild("Props")
	assert(props, "missing Props for architectural detail")
	local root = Kit.group(props, "ArchitecturalDressing")
	local rooms, links = StudioLayout.make()
	local byName: { [string]: StudioLayout.Room } = {}
	for _, room in rooms do
		byName[room.name] = room
		wallTrim(root, room)
	end
	for _, entry in links do
		local a = byName[entry[1]]
		local b = byName[entry[2]]
		assert(a and b, "invalid room link for dressing")
		local axis, at, along = portal(a, b)
		doorFrame(root, axis, at, along, if entry[3] == "open" then 15 else 9, entry[3])
	end
	doorFrame(root, "z", 24, -43, 11, "front")
	glassMullion(root, "x", -34, -97, 10)
	glassMullion(root, "z", -58, 29, 15)
	mainFacade(root)
end

return Detail
