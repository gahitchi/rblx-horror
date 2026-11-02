--!strict
-- Guest-facing studio interiors and naval service additions.
-- All dress-up parts sit in Props/ServiceDressing (except the state's accent lamps).
-- Route centers, restroom doors, chapter prompts and the flat/basement seals stay clear.
local Kit = require(script.Parent.StudioDecorKit)
local C = Kit.palette
local Detail = {}

local function lightFixture(lamps: Instance, x: number, y: number, z: number, size: number)
	local frame = Kit.box(lamps, "StudioAccentPractical", x, y, z,
		size, 0.28, 0.8, C.gold, Enum.Material.Metal)
	local glow = Instance.new("PointLight")
	glow.Enabled = false
	glow.Range = 16
	glow.Brightness = 0.45
	glow.Shadows = false
	glow.Parent = frame
end

local function folderSign(parent: Instance, name: string, x: number, y: number, z: number, width: number)
	Kit.sign(parent, name, CFrame.new(x, y, z),
		Vector3.new(width, 1.15, 0.13), Enum.NormalId.Front, C.cream)
end

local function framedPhoto(parent: Instance, x: number, y: number, z: number, name: string)
	Kit.box(parent, "PhotographFrame", x, y, z, 4.1, 3, 0.18, C.wood, Enum.Material.Wood)
	Kit.box(parent, "PhotographSepia", x, y + 0.12, z - 0.12, 3.6, 2.35, 0.09,
		C.woodLight, Enum.Material.SmoothPlastic)
	Kit.sign(parent, name, CFrame.new(x, y - 0.92, z - 0.24),
		Vector3.new(3.5, 0.53, 0.1), Enum.NormalId.Front, C.dark, C.paper)
end

local function phone(parent: Instance, x: number, y: number, z: number)
	Kit.box(parent, "RotaryTelephone", x, y, z, 1.8, 0.7, 1.6, C.dark)
	Kit.disc(parent, "PhoneDial", x, y + 0.34, z - 0.1, 1.1, 0.12, C.cream)
	Kit.box(parent, "PhoneReceiver", x, y + 0.65, z + 0.18,
		2, 0.32, 0.55, C.black)
end

local function wallClock(parent: Instance, x: number, y: number, z: number)
	Kit.disc(parent, "ClockDial", x, y, z, 2.7, 0.25, C.cream)
	Kit.rod(parent, "ClockHour", Vector3.new(x, y, z - 0.2),
		Vector3.new(x - 0.65, y + 0.6, z - 0.2), 0.1, C.dark)
	Kit.rod(parent, "ClockMinute", Vector3.new(x, y, z - 0.24),
		Vector3.new(x + 0.1, y + 0.95, z - 0.24), 0.09, C.dark)
end

local function tileFloor(parent: Instance, x1: number, x2: number, z1: number, z2: number)
	-- Stylized vinyl checker tiles in larger 3.2-stud pieces, not tiny PBR tiles.
	local step = 3.2
	local ix = 0
	for x = x1 + step / 2, x2 - step / 2, step do
		ix += 1
		local iz = 0
		for z = z1 + step / 2, z2 - step / 2, step do
			iz += 1
			Kit.box(parent, "VinylTile", x, 0.035, z, step - 0.07, 0.06,
				step - 0.07, if (ix + iz) % 2 == 0 then C.cream else C.glass)
		end
	end
end

local function toilet(parent: Instance, x: number, z: number)
	Kit.box(parent, "ToiletTank", x, 2, z + 0.95, 2.4, 2.2, 0.9,
		C.cream, Enum.Material.SmoothPlastic)
	Kit.box(parent, "CeramicBase", x, 0.72, z - 0.35, 1.9, 1.4, 2.3,
		C.cream, Enum.Material.SmoothPlastic)
	Kit.box(parent, "ToiletSeat", x, 1.5, z - 0.35, 2, 0.17, 2.3, C.paper)
	Kit.box(parent, "FlushLever", x + 1.06, 2.4, z + 0.98,
		0.5, 0.17, 0.3, C.steel, Enum.Material.Metal)
end

local function sink(parent: Instance, x: number, z: number, mirrorZ: number)
	Kit.box(parent, "SinkBasin", x, 2.4, z, 3.3, 0.5, 1.9,
		C.cream, Enum.Material.SmoothPlastic)
	Kit.box(parent, "SinkPedestal", x, 1.1, z + 0.1, 0.9, 2.2, 0.75,
		C.cream, Enum.Material.SmoothPlastic)
	Kit.rod(parent, "FaucetSpout", Vector3.new(x, 2.85, z + 0.5),
		Vector3.new(x, 3.4, z + 0.15), 0.16, C.steel)
	Kit.box(parent, "MirrorFrame", x, 6.4, mirrorZ, 3.7, 4.3, 0.18,
		C.metal, Enum.Material.Metal)
	local glass = Kit.box(parent, "WashroomMirror", x, 6.4, mirrorZ - 0.13,
		3.35, 3.95, 0.06, C.glass, Enum.Material.Glass)
	glass.Reflectance = 0.15
end

local function safetyStripe(parent: Instance, x: number, y: number, z: number, horizontal: boolean)
	Kit.block(parent, "QuarantineWarningStripe",
		CFrame.new(x, y, z) * CFrame.Angles(0, 0, if horizontal then 0 else math.rad(35)),
		if horizontal then Vector3.new(6, 0.24, 0.12) else Vector3.new(0.38, 4.8, 0.12),
		C.gold, Enum.Material.SmoothPlastic)
end

local function broom(parent: Instance, x: number, z: number, red: boolean)
	Kit.rod(parent, "BroomHandle", Vector3.new(x, 0.85, z),
		Vector3.new(x + 0.65, 6.6, z), 0.16, C.woodLight)
	Kit.box(parent, "BrushHead", x, 0.75, z, 2.3, 0.65, 0.65,
		if red then C.red else C.wood, Enum.Material.Fabric)
end

local function boxLabel(parent: Instance, x: number, y: number, z: number, text: string)
	Kit.box(parent, "ShippingCase", x, y, z, 5.3, 2.5, 3.1,
		C.dark, Enum.Material.Metal)
	Kit.box(parent, "RoadCaseCorner", x, y + 1.2, z - 1.61, 5.25, 0.17, 0.14,
		C.steel, Enum.Material.Metal)
	Kit.sign(parent, text, CFrame.new(x, y, z - 1.68),
		Vector3.new(4, 0.9, 0.1), Enum.NormalId.Front, C.cream)
end

function Detail.apply(map: Model)
	local props = map:FindFirstChild("Props")
	local lamps = map:FindFirstChild("Lamps")
	assert(props and lamps, "studio needs Props and Lamps")
	local root = Kit.group(props, "ServiceDressing")
	local public = Kit.group(root, "ReceptionAndEntry")
	local breakRoom = Kit.group(root, "StaffLounge")
	local bathrooms = Kit.group(root, "Restrooms")
	local janitor = Kit.group(root, "Janitor")
	local tech = Kit.group(root, "MachineAndDelivery")
	local transit = Kit.group(root, "CorridorsAndNavy")

	-- Reception should read as an actual family-run music business at the entrance.
	Kit.box(public, "ReceptionCounterGlass", -52, 3.7, 11, 10.5, 0.16, 2.3,
		C.glass, Enum.Material.Glass)
	Kit.box(public, "DeskBell", -50, 3.86, 10.1, 0.65, 0.28, 0.65,
		C.gold, Enum.Material.Metal)
	phone(public, -56, 3.95, 11)
	Kit.box(public, "PencilCup", -48.5, 4, 12, 0.7, 0.65, 0.7, C.wood)
	for _, dx in { -0.1, 0.13, 0.32 } do
		Kit.rod(public, "DeskPencil", Vector3.new(-48.5 + dx, 4.1, 12),
			Vector3.new(-48.5 + dx, 5, 12), 0.07, C.gold)
	end
	Kit.sofa(public, -3, 16, 8.2, 90)
	Kit.table(public, "ReceptionCoffeeTable", -9, 12, 4.5, 3.2, 1.7, C.woodLight)
	Kit.box(public, "VisitorMagazine", -8, 1.92, 12,
		2.1, 0.12, 1.4, C.paper)
	Kit.sign(public, "ENQUIRIES / SESSION BOOKINGS", CFrame.new(-52, 9.3, -6.55),
		Vector3.new(18, 1.2, 0.16))
	framedPhoto(public, -71, 10, -6.55, "THE WRENMOUTH CHOIR")
	framedPhoto(public, -28, 10, -6.55, "FAMILY STUDIO / 1985")
	Kit.poster(public, "TOWN CHOIR / AUTUMN CONCERT", -19, 8, 23.55, 3.5)
	Kit.poster(public, "FISHERMEN'S SONGS / 1986", -9, 8, 23.55, 3.4)
	wallClock(public, -42, 12, -6.5)
	for _, x in { -77, -73, -69 } do
		Kit.box(public, "RecordSleeve", x, 5, 23.45, 2.3, 3.2, 0.2,
			if x == -73 then C.teal else C.woodLight)
	end
	-- Clue: work stopped abruptly, not a derelict warehouse full of random scrap.
	Kit.sign(public, "BOOKED TONIGHT: CHOIR / 21:30",
		CFrame.new(-37, 7.7, -6.53), Vector3.new(17, 1.4, 0.16),
		Enum.NormalId.Front, C.gold)

	-- Entry hall has legible arrows, wall-mounted rather than blocking routes.
	folderSign(public, "RECEPTION  <    |    WC / STAIRS  >", 31, 10, 23.6, 36)
	Kit.box(public, "OldCoatRail", 18, 8, 23.4, 7.8, 0.4, 0.45,
		C.wood, Enum.Material.Wood)
	for _, x in { 15, 18, 21 } do
		Kit.rod(public, "CoatHook", Vector3.new(x, 7.85, 23.2),
			Vector3.new(x, 7.1, 22.8), 0.15, C.gold)
	end
	Kit.box(public, "PublicNoticeboard", 52, 9, 23.5, 12, 6.5, 0.3,
		C.woodLight, Enum.Material.Wood)
	Kit.sign(public, "FIRE EXIT / FRONT DOOR ONLY",
		CFrame.new(52, 10, 23.25), Vector3.new(10.5, 1.2, 0.12), Enum.NormalId.Front,
		C.dark, C.paper)
	Kit.sign(public, "NO ACCESS / BASEMENT 1987",
		CFrame.new(52, 7.8, 23.25), Vector3.new(10.5, 1.2, 0.12), Enum.NormalId.Front,
		C.red, C.paper)
	for _, z in { 20, 21, 22 } do
		Kit.box(public, "NavyThresholdTape", -43, 0.06, z, 11, 0.1, 0.1,
			C.gold, Enum.Material.SmoothPlastic)
	end

	-- The break room feels used by choir members and engineers, rather than just a puzzle closet.
	Kit.sofa(breakRoom, -44, -12, 7.5, 180)
	Kit.box(breakRoom, "CoffeeMachine", -41, 3.5, -27,
		2.6, 2, 2, C.metal, Enum.Material.Metal)
	Kit.box(breakRoom, "BreakCounter", -45, 1.5, -28.5,
		8, 3, 2.1, C.wood, Enum.Material.Wood)
	Kit.box(breakRoom, "StaffFridge", -36.9, 3.7, -27.7,
		3, 7.4, 4, C.cream, Enum.Material.Metal)
	Kit.box(breakRoom, "FridgeHandle", -38.55, 4.2, -25.65,
		0.3, 2.5, 0.1, C.metal)
	Kit.box(breakRoom, "SmallTeaTin", -46, 3.22, -28.4,
		1, 0.8, 0.8, C.teal)
	Kit.chair(breakRoom, -63, -18, 45, C.fabric)
	Kit.chair(breakRoom, -53, -23, -45, C.fabric)
	Kit.sign(breakRoom, "IN MEMORY OF ELEANOR / WRENMOUTH CHOIR",
		CFrame.new(-67, 9.8, -30.55), Vector3.new(24, 1.8, 0.12),
		Enum.NormalId.Front, C.gold)
	framedPhoto(breakRoom, -54, 9.8, -30.52, "CHOIR / 1985")
	Kit.poster(breakRoom, "KITCHEN / PLEASE CLEAN UP", -75, 9, -30.55, 3.1)

	-- Both WCs use broad 1980s ceramic/vinyl details; never alter playable door parts.
	tileFloor(bathrooms, 59.4, 79, -56.8, -32.2)
	tileFloor(bathrooms, 63.5, 78.8, -5.7, 4.9)
	toilet(bathrooms, 74, -49)
	toilet(bathrooms, 75, -4)
	sink(bathrooms, 65, -42, -40.65)
	sink(bathrooms, 66, 3, 5.55)
	Kit.box(bathrooms, "StaffWC_Partition", 78, 3.8, -53,
		0.15, 7, 7, C.cream, Enum.Material.SmoothPlastic)
	Kit.box(bathrooms, "PaperTowelDispenser", 60.1, 5.4, -33.2,
		1, 1.7, 0.6, C.cream)
	Kit.box(bathrooms, "PublicSoapDispenser", 66, 3.65, 3.8,
		0.7, 1.2, 0.5, C.teal)
	Kit.sign(bathrooms, "GUEST WC", CFrame.new(71, 10.4, 5.5),
		Vector3.new(10, 1.3, 0.14), Enum.NormalId.Front, C.dark, C.paper)
	Kit.sign(bathrooms, "STAFF WC", CFrame.new(69, 10.5, -57.55),
		Vector3.new(12, 1.3, 0.14), Enum.NormalId.Front, C.dark, C.paper)
	for _, z in { -55, -52, -36 } do
		Kit.box(bathrooms, "WallTileWainscot", 78.8, 3.3, z, 0.1, 6.5, 3,
			C.glass, Enum.Material.Concrete)
	end

	-- Janitor closet: purposeful maintenance kit, no new gameplay item.
	for _, x in { 63, 66, 69 } do
		broom(janitor, x, -27, x == 66)
	end
	for _, y in { 2, 5.7, 8 } do
		Kit.box(janitor, "CleaningShelf", 74, y, -29.4, 9, 0.22, 1.1,
			C.steel, Enum.Material.Metal)
	end
	for i = 1, 6 do
		Kit.box(janitor, "CleaningBottle", 70.5 + (i % 3) * 2.7,
			2.7 + math.floor((i - 1) / 3) * 3.7, -29.1,
			0.8, 1.25, 0.8, if i % 2 == 0 then C.cream else C.teal)
	end
	Kit.box(janitor, "YellowBucket", 76, 0.8, -21, 2.4, 1.6, 2.4,
		C.gold, Enum.Material.Plastic)
	Kit.sign(janitor, "WET FLOOR / STAFF", CFrame.new(68, 9.9, -7.45),
		Vector3.new(11, 1.3, 0.12), Enum.NormalId.Front, C.dark, C.gold)

	-- Service route: cold paint, pipework and freight hardware separate from studio warmth.
	for _, z in { -124, -113 } do
		Kit.rod(tech, "CableConduit", Vector3.new(46, 11, z),
			Vector3.new(79, 11, z), 0.19, C.steel)
	end
	for _, x in { 51, 61, 71 } do
		Kit.box(tech, "MachineRackFace", x, 5, -125.89,
			3.5, 6.2, 0.12, C.metal, Enum.Material.Metal)
		for i = 1, 5 do
			Kit.box(tech, "TapeStatusMeter", x, 2.3 + i * 0.88, -125.94,
				2.7, 0.33, 0.1, if i % 2 == 0 then C.gold else C.dark)
		end
	end
	Kit.sign(tech, "TAPE TRANSPORTS / MAINTENANCE ONLY", CFrame.new(61, 11, -133.55),
		Vector3.new(29, 1.5, 0.12))
	for _, z in { -99, -83, -65 } do
		Kit.rod(tech, "ServiceMainConduit", Vector3.new(77.6, 12.5, z - 7),
			Vector3.new(77.6, 12.5, z + 7), 0.21, C.steel)
	end
	Kit.box(tech, "FireHoseCabinet", 78.9, 5, -91,
		0.45, 6.4, 3.6, C.red, Enum.Material.Metal)
	Kit.sign(tech, "FIRE HOSE", CFrame.new(78.6, 6, -91) * CFrame.Angles(0, math.rad(-90), 0),
		Vector3.new(3.3, 1.1, 0.1), Enum.NormalId.Front, C.cream)
	for i = 1, 3 do
		boxLabel(tech, 104, 1.6 + (i - 1) * 2.7, -88 - i * 4, "WRENMOUTH / GEAR")
	end
	for _, x in { 86, 107 } do
		safetyStripe(tech, x, 4, -105.7, false)
	end
	Kit.sign(tech, "LOAD IN / QUARANTINE INSPECTED", CFrame.new(94, 12, -106.5),
		Vector3.new(24, 1.5, 0.1), Enum.NormalId.Front, C.gold)
	Kit.box(tech, "ClosedLoadingRollerDoor", 109.65, 7.4, -80,
		0.21, 12.5, 19, C.metal, Enum.Material.Metal)
	for _, y in { 2, 5, 8, 11 } do
		Kit.box(tech, "RollerDoorRib", 109.45, y, -80,
			0.22, 0.2, 18.7, C.steel, Enum.Material.Metal)
	end
	Kit.box(tech, "FreightTrolley", 92, 1.35, -99,
		5, 0.7, 4, C.dark, Enum.Material.Metal)
	for _, x in { 90.3, 93.7 } do
		Kit.box(tech, "TrolleyWheel", x, 0.5, -99,
			0.8, 0.8, 0.8, C.metal, Enum.Material.Metal)
	end
	Kit.box(tech, "UnopenedRoadCase", 92, 3.1, -99,
		4.5, 2.8, 3.7, C.leather, Enum.Material.Metal)

	-- Route reading at phone size, with understated story about the navy closure.
	for _, spec in {
		{ x = -22, y = 11, z = -31.55, text = "SOUND LOCK / STUDIO" },
		{ x = 17, y = 12.5, z = -31.55, text = "TO CONTROL / LIVE" },
		{ x = -59, y = 11, z = -30.5, text = "ENGINEER'S LOUNGE" },
		{ x = 51, y = 11.5, z = -7.55, text = "SERVICE ACCESS / STAFF" },
	} do
		Kit.sign(transit, spec.text, CFrame.new(spec.x, spec.y, spec.z),
			Vector3.new(17, 1.25, 0.11), Enum.NormalId.Front, C.cream)
	end
	for _, z in { -47, -40 } do
		Kit.box(transit, "SoundLockAbsorber", -33.5, 7, z, 0.24, 8, 4.4,
			C.foam, Enum.Material.Fabric)
	end
	for _, x in { -9, 4, 17, 30, 43 } do
		Kit.box(transit, "GalleryBench", x, 1, -35.5, 4.5, 1.7, 2.2,
			C.wood, Enum.Material.Wood)
	end
	Kit.sign(transit, "DO NOT DISTURB A LIVE SESSION", CFrame.new(17, 11, -30.55),
		Vector3.new(22, 1.2, 0.1), Enum.NormalId.Front, C.gold)
	Kit.sign(transit, "US NAVY / SEALED NOV 1987", CFrame.new(71, 11.3, 6.58),
		Vector3.new(13, 1.3, 0.12), Enum.NormalId.Front, C.red, C.cream)
	Kit.sign(transit, "UP: FAMILY FLAT / NO ENTRY", CFrame.new(71, 17.7, 23.5),
		Vector3.new(12, 1.2, 0.12), Enum.NormalId.Front, C.gold)
	for _, y in { 3.8, 6.1 } do
		Kit.rod(transit, "BasementQuarantineChain", Vector3.new(67.5, y, 6.7),
			Vector3.new(74.5, y + 1, 6.7), 0.2, C.steel)
	end
	for _, x in { 68, 72, 76 } do
		Kit.box(transit, "FlatBarricadeTimber", x, 13, 23.68, 0.33, 5.1, 0.24,
			C.wood, Enum.Material.Wood)
	end
	for _, x in { -72, -43, 18, 48, 69 } do
		Kit.vent(transit, x, 12.5, -30.55, 3.4)
	end

	-- Use the chapter's existing dead / woken / red lighting, never permanent bright effects.
	for _, item in {
		{ x = -52, y = 6, z = 11, size = 3.5 },
		{ x = -58, y = 12, z = -79, size = 4 },
		{ x = -70, y = 11, z = -125, size = 3 },
		{ x = -56, y = 9, z = -17, size = 3 },
		{ x = 71, y = 11, z = -44, size = 2.5 },
		{ x = 93, y = 11, z = -90, size = 4 },
	} do
		lightFixture(lamps, item.x, item.y, item.z, item.size)
	end
end

return Detail
