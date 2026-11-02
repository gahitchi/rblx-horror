--!strict
-- Wrenmouth Recording House lighting design, version 1.
-- Procedural lighting ONLY: no furniture, collision, objectives or AI geometry.
-- Adds layered practicals and tags existing fixtures for the LightingService.
-- One room-specific palette, explicit roles, and a hard shadow-casting budget.
local StudioLayout = require(script.Parent.StudioLayout)
local StudioLightingRig = {}

local METAL = Color3.fromRGB(57, 61, 63)
local CERAMIC = Color3.fromRGB(161, 151, 128)
local GLASS = Color3.fromRGB(207, 200, 169)
local RED = Color3.fromRGB(138, 47, 41)

type Room = StudioLayout.Room
type Fixture = {
	name: string, room: string, at: Vector3, role: string,
	range: number, intensity: number, kind: string?, angle: number?,
	shadows: boolean?,
}

-- Every fixture below must remain inside its named room, not on a doorway.
-- A "Guide" is an unexplained residual glow, not a full-powered lamp.
-- Work lights do not activate until the building wakes with shock one.
local FIXTURES: { Fixture } = {
	-- GOLD-STANDARD ROOM: Control A, the heart of the final recording.
	{ name = "DeskWritingLamp", room = "ControlA", at = Vector3.new(-57, 7.8, -79),
		role = "Task", range = 16, intensity = 0.82, kind = "Spot", angle = 84, shadows = true },
	{ name = "TapeTransportPilot", room = "ControlA", at = Vector3.new(-73, 6.8, -94),
		role = "Guide", range = 10, intensity = 0.24 },
	{ name = "MixingDeskScaleLight", room = "ControlA", at = Vector3.new(-55, 4.7, -78),
		role = "Accent", range = 10, intensity = 0.27 },
	{ name = "PatchBayInspection", room = "ControlA", at = Vector3.new(-40, 8.2, -96),
		role = "Task", range = 13, intensity = 0.50, kind = "Spot", angle = 80 },
	{ name = "TrackingGlassRim", room = "ControlA", at = Vector3.new(-36.5, 10.0, -98),
		role = "Threshold", range = 14, intensity = 0.35 },
	{ name = "ControlACircuitFault", room = "ControlA", at = Vector3.new(-77, 11, -73),
		role = "Fault", range = 12, intensity = 0.36 },

	-- Fixed secondary reflections emulate *some* bounced tungsten light:
	-- narrow range + low intensity, no dynamic shadows or expensive tracers.
	-- These are artistic bounce proxies, not actual ray/path tracing.
	{ name = "DeskToWallBounce", room = "ControlA", at = Vector3.new(-61, 4.4, -83),
		role = "Bounce", range = 11, intensity = 0.15 },
	{ name = "DeskToCeilingBounce", room = "ControlA", at = Vector3.new(-57, 11.8, -79),
		role = "Bounce", range = 12, intensity = 0.10 },
	{ name = "TapeMetalReflection", room = "ControlA", at = Vector3.new(-72, 4.0, -89),
		role = "Bounce", range = 9, intensity = 0.09 },
	{ name = "TrackingGlassReturn", room = "ControlA", at = Vector3.new(-38, 7.1, -97),
		role = "Bounce", range = 12, intensity = 0.11 },

	-- Authentic work areas, limited to a readable local pool rather than bright fill.
	{ name = "MasteringDeskPool", room = "MasteringSuite", at = Vector3.new(-48, 8.4, -122),
		role = "Task", range = 14, intensity = 0.58, kind = "Spot", angle = 80 },
	{ name = "ArchiveIndexPilot", room = "TapeArchive", at = Vector3.new(-79, 6.8, -114),
		role = "Guide", range = 11, intensity = 0.23 },
	{ name = "ArchiveShelfRim", room = "TapeArchive", at = Vector3.new(-69, 10.2, -128),
		role = "Task", range = 14, intensity = 0.32, kind = "Spot", angle = 88 },
	{ name = "ArchivePaperBounce", room = "TapeArchive", at = Vector3.new(-76, 3.3, -117),
		role = "Bounce", range = 10, intensity = 0.10 },
	{ name = "ControlBSafePilot", room = "ControlB", at = Vector3.new(-75, 6.6, -48),
		role = "Guide", range = 11, intensity = 0.22 },
	{ name = "ControlBDeskPool", room = "ControlB", at = Vector3.new(-59, 8.6, -43),
		role = "Task", range = 15, intensity = 0.52, kind = "Spot", angle = 82 },
	{ name = "LiveRoomCueLamp", room = "LiveHall", at = Vector3.new(9, 13, -81),
		role = "Task", range = 20, intensity = 0.45, kind = "Spot", angle = 92 },
	{ name = "LiveRoomLowMarker", room = "LiveHall", at = Vector3.new(18, 6.6, -81),
		role = "Guide", range = 9, intensity = 0.20 },
	{ name = "TrackingWindowSpill", room = "LiveHall", at = Vector3.new(-31, 7.2, -98),
		role = "Bounce", range = 14, intensity = 0.13 },
	{ name = "BoothWestSessionLamp", room = "IsolationWest", at = Vector3.new(-21, 9, -119),
		role = "Task", range = 13, intensity = 0.43, kind = "Spot", angle = 82 },
	{ name = "BoothVocalSessionLamp", room = "IsolationVocal", at = Vector3.new(4, 9, -119),
		role = "Task", range = 13, intensity = 0.42, kind = "Spot", angle = 82 },
	{ name = "BoothDrumSessionLamp", room = "IsolationDrums", at = Vector3.new(31, 10, -119),
		role = "Task", range = 15, intensity = 0.44, kind = "Spot", angle = 84 },

	-- Safe navigation anchor points: not hundreds of fairy lights or neon.
	{ name = "ReceptionLedgerPilot", room = "Reception", at = Vector3.new(-52, 6.0, 11),
		role = "Guide", range = 11, intensity = 0.22 },
	{ name = "ReceptionCounterShade", room = "Reception", at = Vector3.new(-52, 10.5, 9),
		role = "Task", range = 17, intensity = 0.55, kind = "Spot", angle = 95 },
	{ name = "ReceptionCounterReturn", room = "Reception", at = Vector3.new(-53, 4.6, 8),
		role = "Bounce", range = 12, intensity = 0.13 },
	{ name = "FrontDoorSecurity", room = "Reception", at = Vector3.new(-43, 11, 21),
		role = "Emergency", range = 13, intensity = 0.36 },
	{ name = "ReceptionToStairway", room = "EntryHall", at = Vector3.new(35, 11.2, 9),
		role = "Emergency", range = 16, intensity = 0.36 },
	{ name = "BreakRoomProgrammePilot", room = "BreakRoom", at = Vector3.new(-55, 6.9, -18),
		role = "Guide", range = 11, intensity = 0.21 },
	{ name = "StaffHallPassageRim", room = "StaffPassage", at = Vector3.new(-13, 10.6, -18),
		role = "Threshold", range = 16, intensity = 0.35 },
	{ name = "SoundLockDoorRim", room = "SoundLock", at = Vector3.new(-20, 10.2, -42),
		role = "Threshold", range = 12, intensity = 0.29 },
	{ name = "ViewingGalleryWeakFill", room = "ViewingGallery", at = Vector3.new(16, 11.3, -43),
		role = "Threshold", range = 17, intensity = 0.32 },

	-- Later navy retrofit: colder, sharper and visibly less welcoming.
	{ name = "ServicePassCaution", room = "ServicePass", at = Vector3.new(61, 10, -84),
		role = "Emergency", range = 13, intensity = 0.39 },
	{ name = "ServiceConcreteReturn", room = "ServicePass", at = Vector3.new(64, 4.1, -80),
		role = "Bounce", range = 11, intensity = 0.10 },
	{ name = "ServiceHallCaution", room = "ServiceHall", at = Vector3.new(51, 10, -37),
		role = "Emergency", range = 13, intensity = 0.36 },
	{ name = "MachineRoomFault", room = "MachineRoom", at = Vector3.new(60, 10, -119),
		role = "Fault", range = 13, intensity = 0.42 },
	{ name = "LoadingDockInspection", room = "LoadingBay", at = Vector3.new(92, 12.4, -83),
		role = "Task", range = 18, intensity = 0.55, kind = "Spot", angle = 90 },
	{ name = "NavyStairWarning", room = "Stairwell", at = Vector3.new(70, 11.6, 10),
		role = "Emergency", range = 13, intensity = 0.38 },
	{ name = "InnerHallLeak", room = "InnerHall", at = Vector3.new(25, 10.2, -21),
		role = "Threshold", range = 15, intensity = 0.29 },
}

local function colorFor(role: string): Color3
	if role == "Emergency" or role == "Fault" then
		return RED
	elseif role == "Guide" then
		return GLASS
	else
		return CERAMIC
	end
end

local function roomFor(rooms: { Room }, pos: Vector3): Room?
	for _, room in rooms do
		if pos.X >= room.x1 and pos.X <= room.x2
			and pos.Z >= room.z1 and pos.Z <= room.z2 then
			return room
		end
	end
	return nil
end

local function decorate(
	holders: Instance, spec: Fixture
)
	local anchor = Instance.new("Part")
	anchor.Name = "Light_" .. spec.name
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Size = if spec.kind == "Spot"
		then Vector3.new(2.4, 0.36, 1.5) else Vector3.new(1.15, 0.3, 0.9)
	anchor.Color = if spec.role == "Emergency" then RED else METAL
	anchor.Material = Enum.Material.Metal
	anchor.CFrame = CFrame.new(spec.at)
	anchor:SetAttribute("LightRole", spec.role)
	anchor:SetAttribute("LightRoom", spec.room)
	anchor:SetAttribute("LightBase", spec.intensity)
	anchor:SetAttribute("LightRange", spec.range)
	anchor:SetAttribute("LightShadow", spec.shadows == true)
	anchor.Parent = holders

	-- A discreet frosted lens means the fixture still reads in its off state.
	-- It is not an extra Light instance, so costs only one dynamic light.
	local lens = Instance.new("Part")
	lens.Name = "FrostedDiffuser"
	lens.Anchored = true
	lens.CanCollide, lens.CanQuery, lens.CanTouch = false, false, false
	lens.CastShadow = false
	lens.Size = Vector3.new(anchor.Size.X * 0.75, 0.07, anchor.Size.Z * 0.67)
	lens.CFrame = anchor.CFrame * CFrame.new(0, -anchor.Size.Y / 2 - 0.04, 0)
	lens.Color = colorFor(spec.role)
	lens.Material = Enum.Material.Glass
	lens.Transparency = 0.3
	lens.Parent = anchor

	local light: Light
	if spec.kind == "Spot" then
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom
		spot.Angle = spec.angle or 90
		light = spot
	else
		light = Instance.new("PointLight")
	end
	light.Name = "ActualIllumination"
	light.Enabled = false
	light.Color = colorFor(spec.role)
	light.Brightness = spec.intensity
	light.Range = spec.range
	light.Shadows = spec.shadows == true
	light.Parent = anchor
end

function StudioLightingRig.apply(map: Model)
	local holders = map:FindFirstChild("Lamps")
	assert(holders, "Lighting rig requires Map.Lamps")
	local rooms = StudioLayout.make()

	-- Every original ceiling or service accent fixture receives a deterministic
	-- room profile; no global "turn everything red" defaults.
	for _, holder in holders:GetChildren() do
		if holder:IsA("BasePart") then
			local room = roomFor(rooms, holder.Position)
			if room then
				holder:SetAttribute("LightRoom", room.name)
				holder:SetAttribute("LightRole",
					if holder.Name == "Practical" then "Ceiling" else "Accent")
				holder:SetAttribute("LightBase",
					if holder.Name == "Practical" then 0.56 else 0.28)
				holder:SetAttribute("LightRange",
					if holder.Name == "Practical" then 23 else 13)
			end
		end
	end

	local shadows = 0
	for _, fixture in FIXTURES do
		local room: Room? = nil
		for _, candidate in rooms do
			if candidate.name == fixture.room then
				room = candidate
				break
			end
		end
		assert(room ~= nil, "Unknown lighting room: " .. fixture.room)
		local bounds = room :: Room
		assert(fixture.at.X > bounds.x1 + 0.5 and fixture.at.X < bounds.x2 - 0.5
			and fixture.at.Z > bounds.z1 + 0.5 and fixture.at.Z < bounds.z2 - 0.5
			and fixture.at.Y > 2 and fixture.at.Y < bounds.height - 0.5,
			"Misplaced lighting fixture: " .. fixture.name)
		if fixture.shadows then
			shadows += 1
		end
		decorate(holders, fixture)
	end
	assert(shadows <= 1, "Lighting art budget: only the Control A desk casts an added shadow")
	map:SetAttribute("StudioLightingRig", 1)
	map:SetAttribute("StudioAddedFixtures", #FIXTURES)
end

return StudioLightingRig
