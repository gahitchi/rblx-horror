--!strict
-- Reads a map from the world. Any map (the code-built greybox or a hand-made one) is a Model or
-- Folder named "Map" in Workspace, laid out as docs/MAP_CONTRACT.md describes. This turns it into
-- the Layout the game systems use, and lists every problem it finds in plain words.
--
-- The scripts never hard-code positions: everything they need comes from here.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

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

export type Layout = {
	map: Instance,
	spawn: CFrame,
	lobbySpawn: CFrame,
	monsterSpawn: Vector3,
	areas: { Area },
	fuseSpots: { Vector3 },
	speakers: { Vector3 },
	generator: BasePart,
	fuseBox: BasePart,
	tapeDeck: BasePart,
	exitZone: BasePart,
	frontDoor: BasePart,
	doors: { BasePart },
	zones: { Zone },
	powerLights: { Light },
	powerLamps: { BasePart },
}

local MIN_DOOR_WIDTH = 6
local MIN_DOOR_HEIGHT = 9
local ROOT_HEIGHT = 3 -- spots and spawns are this far above the floor

local MapContract = {}

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
	local objectives = map:FindFirstChild("Objectives")
	local lightsFolder = map:FindFirstChild("PowerLights")
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
	local fuseSpots: { Vector3 } = {}
	for _, spot in partsNamed(markers, "FuseSpot") do
		makeHelper(spot)
		table.insert(fuseSpots, spot.Position)
	end
	if #fuseSpots < Config.FUSES_NEEDED then
		err(
			string.format(
				"needs at least %d Markers/FuseSpot parts, found %d",
				Config.FUSES_NEEDED,
				#fuseSpots
			)
		)
	end
	local speakers: { Vector3 } = {}
	for _, speaker in partsNamed(markers, "Speaker") do
		makeHelper(speaker)
		table.insert(speakers, speaker.Position)
	end
	if #speakers == 0 then
		err("needs at least one Markers/Speaker part (where the alarm plays)")
	end

	-- Areas
	local areas: { Area } = {}
	if areasFolder then
		for _, room in areasFolder:GetChildren() do
			local box = part(room, "Bounds")
			if not box then
				warnAbout(describe(room) .. " has no Bounds part; skipped")
				continue
			end
			makeHelper(box)
			local lo, hi = bounds(box)
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
			if kind ~= "normal" and kind ~= "booth" and kind ~= "front" then
				warnAbout(
					describe(child)
						.. " has no valid Kind attribute (normal, booth or front); treated as normal"
				)
				kind = "normal"
				child:SetAttribute("Kind", kind)
			end
			child.Anchored = true
			child:SetAttribute("Open", false)
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

	-- Objectives
	local generator = part(objectives, "Generator")
	local fuseBox = part(objectives, "FuseBox")
	local tapeDeck = part(objectives, "TapeDeck")
	local exitZone = part(objectives, "ExitZone")
	for _, name in { "Generator", "FuseBox", "TapeDeck", "ExitZone" } do
		if not part(objectives, name) then
			err("Objectives/" .. name .. " is missing")
		end
	end
	if exitZone then
		makeHelper(exitZone)
		exitZone.CanTouch = true -- players escape by touching it
	end

	-- Emergency lights
	local powerLights: { Light } = {}
	local powerLamps: { BasePart } = {}
	if lightsFolder then
		for _, lamp in lightsFolder:GetChildren() do
			if lamp:IsA("BasePart") then
				table.insert(powerLamps, lamp)
			end
			for _, descendant in lamp:GetDescendants() do
				if descendant:IsA("Light") then
					table.insert(powerLights, descendant)
				end
			end
			if lamp:IsA("Light") then
				table.insert(powerLights, lamp)
			end
		end
	end
	if #powerLights == 0 then
		warnAbout("no PowerLights: starting the generator won't light anything")
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

	return {
		map = map,
		spawn = CFrame.lookAt(spawnAt, spawnAt + flatLook),
		lobbySpawn = lobbySpawn,
		monsterSpawn = monsterAt + Vector3.new(0, 1.5, 0), -- the monster's root sits a bit higher
		areas = areas,
		fuseSpots = fuseSpots,
		speakers = speakers,
		generator = generator :: BasePart,
		fuseBox = fuseBox :: BasePart,
		tapeDeck = tapeDeck :: BasePart,
		exitZone = exitZone :: BasePart,
		frontDoor = frontDoor :: BasePart,
		doors = doors,
		zones = zones,
		powerLights = powerLights,
		powerLamps = powerLamps,
	},
		problems
end

return MapContract
