--!strict
-- Reads a map from the world. Any map (the code-built greybox or a hand-made one) is a Model or
-- Folder named "Map" in Workspace, laid out as docs/MAP_CONTRACT.md describes. This turns it into
-- the Layout the game systems use, and lists every problem it finds in plain words.
--
-- The scripts never hard-code positions: everything they need comes from here. Which objectives a
-- map needs depends on the chapter played on it (see Chapters/<chapter>.requires); this only reads
-- whatever the Objectives folder holds.

local Workspace = game:GetService("Workspace")

-- A soundproof room: sound inside it doesn't leave while its door is shut.
export type Zone = {
	name: string,
	min: Vector3,
	max: Vector3,
	door: BasePart,
}

-- A room the monster reasons about: where it patrols and searches.
-- `points` are standing spots at root height (3 studs above the floor).
export type Area = {
	name: string,
	min: Vector3,
	max: Vector3,
	center: Vector3,
	points: { Vector3 },
}

-- A navy quarantine shutter. `closed` is where the map built it (blocking the way); `opened` is
-- the same part lifted out of the way by its own height.
export type Shutter = {
	part: BasePart,
	route: string,
	closed: CFrame,
	opened: CFrame,
	startsOpen: boolean,
}

-- A lamp: a part with lights inside, switched by LightingService between dead, woken and red.
export type Lamp = {
	part: BasePart?,
	lights: { Light },
}

export type Layout = {
	map: Instance,
	spawn: CFrame,
	lobbySpawn: CFrame,
	monsterSpawn: Vector3,
	areas: { Area },
	speakers: { Vector3 },
	objectives: { [string]: BasePart },
	reelSpots: { BasePart },
	tapeSpots: { Vector3 },
	throwableSpots: { BasePart },
	hidingSpots: { BasePart },
	exitZone: BasePart,
	frontDoor: BasePart,
	doors: { BasePart },
	sealedDoors: { BasePart },
	zones: { Zone },
	shutters: { Shutter },
	lamps: { Lamp },
	boundsMin: Vector3, -- the whole building, a little padded (echoes float inside it)
	boundsMax: Vector3,
}

local MIN_DOOR_WIDTH = 6
local MIN_DOOR_HEIGHT = 9
local ROOT_HEIGHT = 3 -- spots and spawns are this far above the floor
local DOOR_KINDS = { normal = true, booth = true, front = true, sealed = true, barricaded = true }

local MapContract = {}

-- The area a position is in, if any.
function MapContract.areaAt(areas: { Area }, position: Vector3): Area?
	for _, area in areas do
		local lo, hi = area.min, area.max
		if
			position.X >= lo.X
			and position.X <= hi.X
			and position.Y >= lo.Y
			and position.Y <= hi.Y
			and position.Z >= lo.Z
			and position.Z <= hi.Z
		then
			return area
		end
	end
	return nil
end

-- A readable name for where a position is: its area's name, or the nearest area's.
function MapContract.placeName(areas: { Area }, position: Vector3): string
	local inside = MapContract.areaAt(areas, position)
	if inside then
		return inside.name
	end
	local best, bestDistance = "somewhere", math.huge
	for _, area in areas do
		local d = (area.center - position).Magnitude
		if d < bestDistance then
			best, bestDistance = area.name, d
		end
	end
	return best
end

-- Markers and volumes are for scripts only: invisible, intangible, never blocking sound or rays.
local function makeHelper(part: BasePart)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.CastShadow = false
end

local function partsNamed(folder: Instance?, name: string): { BasePart }
	local list: { BasePart } = {}
	if folder then
		for _, child in folder:GetChildren() do
			if child.Name == name and child:IsA("BasePart") then
				table.insert(list, child)
			end
		end
	end
	return list
end

local function part(folder: Instance?, name: string): BasePart?
	local found = folder and folder:FindFirstChild(name)
	if found and found:IsA("BasePart") then
		return found
	end
	return nil
end

-- The axis-aligned box a part covers (rotations are folded into the box).
local function bounds(box: BasePart): (Vector3, Vector3)
	local cf, size = box.CFrame, box.Size / 2
	local x = math.abs(cf.RightVector.X) * size.X
		+ math.abs(cf.UpVector.X) * size.Y
		+ math.abs(cf.LookVector.X) * size.Z
	local y = math.abs(cf.RightVector.Y) * size.X
		+ math.abs(cf.UpVector.Y) * size.Y
		+ math.abs(cf.LookVector.Y) * size.Z
	local z = math.abs(cf.RightVector.Z) * size.X
		+ math.abs(cf.UpVector.Z) * size.Y
		+ math.abs(cf.LookVector.Z) * size.Z
	local half = Vector3.new(x, y, z)
	return cf.Position - half, cf.Position + half
end

-- Puts a point at standing height above the floor below it, so authors can drop spots roughly.
local function onFloor(position: Vector3, map: Instance): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map }
	local hit = Workspace:Raycast(position + Vector3.new(0, 2, 0), Vector3.new(0, -24, 0), params)
	if not hit then
		return nil
	end
	return hit.Position + Vector3.new(0, ROOT_HEIGHT, 0)
end

local function describe(instance: Instance): string
	return instance:GetFullName()
end

local function lampOf(holder: Instance): Lamp?
	local lights: { Light } = {}
	if holder:IsA("Light") then
		table.insert(lights, holder)
	end
	for _, descendant in holder:GetDescendants() do
		if descendant:IsA("Light") then
			table.insert(lights, descendant)
		end
	end
	if #lights == 0 then
		return nil
	end
	return { part = if holder:IsA("BasePart") then holder else nil, lights = lights }
end

-- Reads `map` (normally Workspace.Map). Returns the layout, or nil when something essential is
-- missing, plus a list of problems (errors and warnings) to print.
function MapContract.read(map: Instance, lobbySpawn: CFrame): (Layout?, { string })
	local problems: { string } = {}
	local fatal = false
	local function err(message: string)
		table.insert(problems, "ERROR: " .. message)
		fatal = true
	end
	local function warnAbout(message: string)
		table.insert(problems, "warning: " .. message)
	end

	local markers = map:FindFirstChild("Markers")
	local areasFolder = map:FindFirstChild("Areas")
	local doorsFolder = map:FindFirstChild("Doors")
	local boothsFolder = map:FindFirstChild("Booths")
	local objectivesFolder = map:FindFirstChild("Objectives")
	local shuttersFolder = map:FindFirstChild("Shutters")
	local hidingFolder = map:FindFirstChild("HidingSpots")
	-- "PowerLights" was the old name of the Lamps folder; both work.
	local lampsFolder = map:FindFirstChild("Lamps") or map:FindFirstChild("PowerLights")
	for _, name in { "Markers", "Areas", "Doors", "Objectives" } do
		if not map:FindFirstChild(name) then
			err(string.format("%s has no '%s' folder", map.Name, name))
		end
	end

	-- Markers
	local spawnPart = part(markers, "PlayerSpawn")
	local monsterPart = part(markers, "MonsterSpawn")
	if not spawnPart then
		err("Markers/PlayerSpawn is missing")
	end
	if not monsterPart then
		err("Markers/MonsterSpawn is missing")
	end
	local speakers: { Vector3 } = {}
	for _, speaker in partsNamed(markers, "Speaker") do
		makeHelper(speaker)
		table.insert(speakers, speaker.Position)
	end
	if #speakers == 0 then
		err("needs at least one Markers/Speaker part (where the building's speakers are)")
	end
	local reelSpots: { BasePart } = {}
	for _, spot in partsNamed(markers, "ReelSpot") do
		makeHelper(spot)
		table.insert(reelSpots, spot)
	end
	local tapeSpots: { Vector3 } = {}
	for _, spot in partsNamed(markers, "OptionalTapeSpot") do
		makeHelper(spot)
		table.insert(tapeSpots, spot.Position)
	end
	local throwableSpots: { BasePart } = {}
	for _, spot in partsNamed(markers, "Throwable") do
		makeHelper(spot)
		table.insert(throwableSpots, spot)
	end

	-- Hiding spots: wardrobes and lockers you can step into. Each part's front face (-Z) is the door.
	local hidingSpots: { BasePart } = {}
	if hidingFolder then
		for _, child in hidingFolder:GetChildren() do
			if child:IsA("BasePart") then
				child.Anchored = true
				table.insert(hidingSpots, child)
			end
		end
	end

	-- Areas
	local areas: { Area } = {}
	local allMin = Vector3.new(math.huge, math.huge, math.huge)
	local allMax = Vector3.new(-math.huge, -math.huge, -math.huge)
	if areasFolder then
		for _, room in areasFolder:GetChildren() do
			local box = part(room, "Bounds")
			if not box then
				warnAbout(describe(room) .. " has no Bounds part; skipped")
				continue
			end
			makeHelper(box)
			local lo, hi = bounds(box)
			allMin = allMin:Min(lo)
			allMax = allMax:Max(hi)
			local points: { Vector3 } = {}
			local sum = Vector3.zero
			for _, spot in partsNamed(room, "Spot") do
				makeHelper(spot)
				local point = onFloor(spot.Position, map)
				if point then
					table.insert(points, point)
					sum += point
				else
					warnAbout(describe(spot) .. " has no floor under it; skipped")
				end
			end
			if #points == 0 then
				warnAbout(
					describe(room) .. " has no usable Spot parts; the monster won't patrol it"
				)
			end
			table.insert(areas, {
				name = room.Name,
				min = lo,
				max = hi,
				center = if #points > 0 then sum / #points else (lo + hi) / 2,
				points = points,
			})
		end
	end
	local patrolled = 0
	for _, a in areas do
		if #a.points > 0 then
			patrolled += 1
		end
	end
	if patrolled < 2 then
		err("needs at least two Areas with Spot parts for the monster to patrol between")
	end

	-- Doors
	local doors: { BasePart } = {}
	local sealedDoors: { BasePart } = {}
	local doorsByName: { [string]: BasePart } = {}
	local frontDoor: BasePart? = nil
	if doorsFolder then
		for _, child in doorsFolder:GetChildren() do
			if not child:IsA("BasePart") then
				warnAbout(
					describe(child)
						.. " is not a Part; doors must be a single part (decor can be welded to it)"
				)
				continue
			end
			local kind = child:GetAttribute("Kind")
			if type(kind) ~= "string" or not DOOR_KINDS[kind] then
				warnAbout(
					describe(child)
						.. " has no valid Kind attribute (normal, booth, front, sealed or barricaded); treated as normal"
				)
				kind = "normal"
				child:SetAttribute("Kind", kind)
			end
			child.Anchored = true
			child:SetAttribute("Open", false)
			if kind == "sealed" or kind == "barricaded" then
				-- Shut in plain sight for this chapter: a wall as far as anyone is concerned.
				local modifier = child:FindFirstChildOfClass("PathfindingModifier")
				if modifier then
					modifier:Destroy()
				end
				table.insert(sealedDoors, child)
				doorsByName[child.Name] = child
				continue
			end
			if not child:FindFirstChildOfClass("PathfindingModifier") then
				-- Lets the monster plan paths through closed doors; it opens them on arrival.
				local modifier = Instance.new("PathfindingModifier")
				modifier.PassThrough = true
				modifier.Parent = child
			end
			if child.Size.X < MIN_DOOR_WIDTH - 0.5 or child.Size.Y < MIN_DOOR_HEIGHT - 0.5 then
				warnAbout(
					string.format(
						"%s is %.1f wide and %.1f tall; doorways need at least %d by %d or the monster can't path through",
						describe(child),
						child.Size.X,
						child.Size.Y,
						MIN_DOOR_WIDTH,
						MIN_DOOR_HEIGHT
					)
				)
			end
			if kind == "front" then
				if frontDoor then
					err("more than one door has Kind = front")
				end
				frontDoor = child
			else
				table.insert(doors, child)
			end
			doorsByName[child.Name] = child
		end
	end
	if not frontDoor then
		err("no door has Kind = front (the exit)")
	end

	-- Soundproof booths
	local zones: { Zone } = {}
	if boothsFolder then
		for _, child in boothsFolder:GetChildren() do
			if not child:IsA("BasePart") then
				continue
			end
			makeHelper(child)
			local doorName = child:GetAttribute("Door")
			local boothDoor = if type(doorName) == "string" then doorsByName[doorName] else nil
			if not boothDoor then
				warnAbout(
					describe(child) .. " needs a Door attribute naming its door in Doors; skipped"
				)
				continue
			end
			local lo, hi = bounds(child)
			table.insert(zones, { name = child.Name, min = lo, max = hi, door = boothDoor })
		end
	end

	-- Objectives: every part in the folder, by name. The chapter decides which it needs.
	local objectives: { [string]: BasePart } = {}
	if objectivesFolder then
		for _, child in objectivesFolder:GetChildren() do
			if child:IsA("BasePart") then
				if objectives[child.Name] then
					warnAbout("two objectives are named " .. child.Name .. "; only one is used")
				end
				objectives[child.Name] = child
			end
		end
	end
	local exitZone = objectives.ExitZone
	if exitZone then
		makeHelper(exitZone)
		exitZone.CanTouch = true -- players escape by touching it
	else
		err("Objectives/ExitZone is missing")
	end

	-- Quarantine shutters
	local shutters: { Shutter } = {}
	if shuttersFolder then
		for _, child in shuttersFolder:GetChildren() do
			if not child:IsA("BasePart") then
				continue
			end
			child.Anchored = true
			local route = child:GetAttribute("Route")
			local startsOpen = child:GetAttribute("StartsOpen")
			table.insert(shutters, {
				part = child,
				route = if type(route) == "string" then route else "other",
				closed = child.CFrame,
				opened = child.CFrame + Vector3.new(0, child.Size.Y - 0.3, 0),
				startsOpen = startsOpen ~= false,
			})
		end
	end

	-- Lamps
	local lamps: { Lamp } = {}
	if lampsFolder then
		for _, holder in lampsFolder:GetChildren() do
			local lamp = lampOf(holder)
			if lamp then
				table.insert(lamps, lamp)
			end
		end
	end
	if #lamps == 0 then
		warnAbout("no Lamps: the building stays pitch dark even when it wakes")
	end

	if fatal or not spawnPart or not monsterPart then
		return nil, problems
	end
	makeHelper(spawnPart)
	makeHelper(monsterPart)
	local spawnAt = onFloor(spawnPart.Position, map) or spawnPart.Position
	local monsterAt = onFloor(monsterPart.Position, map) or monsterPart.Position
	local look = spawnPart.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.1 then
		flatLook = Vector3.new(0, 0, -1)
	end
	local pad = Vector3.new(6, 6, 6)

	return {
		map = map,
		spawn = CFrame.lookAt(spawnAt, spawnAt + flatLook),
		lobbySpawn = lobbySpawn,
		monsterSpawn = monsterAt + Vector3.new(0, 1.5, 0), -- the monster's root sits a bit higher
		areas = areas,
		speakers = speakers,
		objectives = objectives,
		reelSpots = reelSpots,
		tapeSpots = tapeSpots,
		throwableSpots = throwableSpots,
		hidingSpots = hidingSpots,
		exitZone = exitZone :: BasePart,
		frontDoor = frontDoor :: BasePart,
		doors = doors,
		sealedDoors = sealedDoors,
		zones = zones,
		shutters = shutters,
		lamps = lamps,
		boundsMin = allMin - pad,
		boundsMax = allMax + pad,
	},
		problems
end

return MapContract
