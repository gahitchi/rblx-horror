--!strict
-- Production wing: visual storytelling around real chapter props, not replacement objectives.
-- The central paths, objective tops and booth thresholds are left accessible.
local Kit = require(script.Parent.StudioDecorKit)
local StudioHeroConsole = require(script.Parent.StudioHeroConsole)
local C = Kit.palette
local Detail = {}

local function speaker(parent: Instance, x: number, y: number, z: number)
	Kit.box(parent, "MonitorSpeakerCabinet", x, y, z, 2.7, 4.4, 1.3, C.wood, Enum.Material.Wood)
	Kit.disc(parent, "MonitorWoofer", x, y - 0.65, z - 0.73, 1.7, 0.15, C.black)
	Kit.disc(parent, "MonitorTweeter", x, y + 1.2, z - 0.73, 0.65, 0.13, C.dark)
end

local function tape(parent: Instance, x: number, y: number, z: number, color: Color3)
	Kit.box(parent, "CassetteBox", x, y, z, 0.55, 0.83, 0.24, color, Enum.Material.SmoothPlastic)
	Kit.box(parent, "CassetteLabel", x, y, z - 0.14, 0.44, 0.48, 0.07, C.paper)
end

local function acoustic(
	parent: Instance,
	x: number,
	y: number,
	z: number,
	yaw: number,
	width: number
)
	local basis = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
	Kit.block(
		parent,
		"PaddedAcousticFrame",
		basis,
		Vector3.new(width, 5.6, 0.28),
		C.wood,
		Enum.Material.Wood
	)
	for i = 1, 3 do
		Kit.block(
			parent,
			"FabricAbsorber",
			basis * CFrame.new(0, (i - 2) * 1.6, -0.18),
			Vector3.new(width - 0.3, 1.4, 0.18),
			if i % 2 == 0 then C.woodLight else C.foam,
			Enum.Material.Fabric
		)
	end
end

local function mic(parent: Instance, x: number, z: number, height: number)
	Kit.rod(parent, "MicStand", Vector3.new(x, 0.3, z), Vector3.new(x, height, z), 0.2, C.metal)
	Kit.box(parent, "MicCapsule", x, height + 0.3, z, 0.72, 0.95, 0.7, C.steel, Enum.Material.Metal)
	Kit.box(
		parent,
		"MicGrille",
		x,
		height + 0.44,
		z - 0.39,
		0.57,
		0.62,
		0.09,
		C.dark,
		Enum.Material.Metal
	)
	Kit.box(parent, "MicFoot", x, 0.11, z, 1.3, 0.16, 1.3, C.dark, Enum.Material.Metal)
end

local function drum(parent: Instance, x: number, z: number)
	Kit.box(parent, "DrumKitRug", x, 0.06, z, 10, 0.09, 8.5, C.leather, Enum.Material.Fabric)
	Kit.disc(parent, "BassDrumSkin", x, 2, z - 1.3, 3.4, 1.8, C.wood)
	Kit.disc(parent, "BassFront", x, 2, z - 2.3, 3.1, 0.1, C.cream)
	for _, dx in { -2.8, 2.8 } do
		Kit.disc(parent, "RackTom", x + dx, 3.4, z + 0.4, 1.6, 1.3, C.wood)
		Kit.rod(
			parent,
			"CymbalPost",
			Vector3.new(x + dx * 1.4, 0.2, z),
			Vector3.new(x + dx * 1.4, 4.5, z),
			0.12,
			C.steel
		)
		Kit.box(
			parent,
			"Cymbal",
			x + dx * 1.4,
			4.55,
			z,
			2.3,
			0.12,
			2.3,
			C.gold,
			Enum.Material.Metal
		)
	end
	Kit.chair(parent, x, z + 3.4, 180, C.dark)
end

local function keyboard(parent: Instance, x: number, z: number)
	Kit.box(parent, "ElectricPianoCase", x, 3, z, 7.7, 1.2, 3.1, C.wood, Enum.Material.Wood)
	Kit.box(parent, "PianoKeys", x, 3.67, z - 0.75, 7, 0.08, 1.4, C.cream)
	for i = 1, 10 do
		Kit.box(
			parent,
			"PianoBlackKey",
			x - 3.05 + i * 0.56,
			3.75,
			z - 0.95,
			0.27,
			0.13,
			0.75,
			C.black
		)
	end
	for _, dx in { -3.3, 3.3 } do
		Kit.box(parent, "PianoLeg", x + dx, 1.1, z + 0.65, 0.4, 2.3, 0.4, C.dark)
	end
end

local function amplifier(parent: Instance, x: number, z: number, width: number)
	Kit.box(parent, "GuitarAmplifier", x, 2.3, z, width, 4.6, 2, C.dark, Enum.Material.Fabric)
	Kit.box(
		parent,
		"AmpCloth",
		x,
		2.05,
		z - 1.04,
		width - 0.4,
		2.9,
		0.1,
		C.foam,
		Enum.Material.Fabric
	)
	Kit.box(parent, "AmpControlStrip", x, 4.12, z - 1.06, width - 0.5, 0.43, 0.08, C.gold)
	for i = 1, 4 do
		Kit.box(
			parent,
			"AmplifierKnob",
			x - width / 2 + 0.6 + i * 0.5,
			4.12,
			z - 1.15,
			0.15,
			0.15,
			0.08,
			C.black
		)
	end
end

local function console(parent: Instance, x: number, z: number, width: number)
	-- Visual desk with no collision; the existing chapter desk stays the only interaction part.
	Kit.box(parent, "WoodConsoleStand", x, 1.4, z, width, 2.8, 3.6, C.wood, Enum.Material.Wood)
	Kit.box(
		parent,
		"SlopedConsoleTop",
		x,
		3.1,
		z - 0.25,
		width - 0.3,
		0.55,
		3.2,
		C.metal,
		Enum.Material.Metal
	)
	for i = 1, math.floor(width / 0.7) do
		local dx = -width / 2 + i * 0.68
		Kit.box(parent, "FaderTrack", x + dx, 3.46, z - 0.7, 0.13, 0.12, 1.3, C.black)
		Kit.box(
			parent,
			"FaderCap",
			x + dx,
			3.54,
			z - 0.7 + (i % 4) * 0.22,
			0.27,
			0.15,
			0.25,
			C.cream
		)
		if i % 2 == 0 then
			Kit.box(parent, "ChannelLamp", x + dx, 3.47, z + 0.42, 0.14, 0.07, 0.14, C.amber)
		end
	end
	Kit.box(parent, "MeterBridge", x, 4.8, z + 1.25, width, 2.7, 0.75, C.wood, Enum.Material.Wood)
	for i = 1, math.floor(width / 1.7) do
		local dx = -width / 2 + i * 1.5
		Kit.box(parent, "VUDisplay", x + dx, 4.95, z + 0.8, 1, 1.1, 0.08, C.gold)
		Kit.box(parent, "VU_Needle", x + dx - 0.1, 4.8, z + 0.74, 0.07, 0.72, 0.1, C.red)
	end
end

local function reelMachineDetail(parent: Instance)
	-- Exact TapeMachine objective is retained untouched.
	for _, x in { -75, -72, -69 } do
		Kit.disc(parent, "AnodizedTapeSpool", x, 5.8, -92.18, 2.1, 0.19, C.steel)
		Kit.disc(parent, "SpoolHub", x, 5.8, -92.04, 0.62, 0.12, C.black)
	end
	for i = 1, 5 do
		Kit.box(
			parent,
			"TransportButton",
			-75.2 + i * 0.83,
			2.75,
			-92.08,
			0.5,
			0.25,
			0.12,
			if i == 5 then C.red else C.gold
		)
	end
	Kit.box(parent, "TapeCounter", -72, 4, -92.06, 3.2, 0.7, 0.11, C.black)
	Kit.sign(
		parent,
		"TASCAM / 1987 MULTITRACK",
		CFrame.new(-73, 1.35, -92.07),
		Vector3.new(6, 0.7, 0.08),
		Enum.NormalId.Front,
		C.cream,
		C.dark
	)
	Kit.rod(
		parent,
		"MagneticTapePath",
		Vector3.new(-75, 5.45, -91.98),
		Vector3.new(-69, 5.45, -91.98),
		0.08,
		C.leather
	)
end

local function wallAward(parent: Instance, x: number, y: number, z: number, title: string)
	Kit.box(parent, "AwardBoard", x, y, z, 3.7, 4.2, 0.25, C.wood, Enum.Material.Wood)
	Kit.box(
		parent,
		"GoldRecord",
		x,
		y + 0.45,
		z - 0.18,
		2.4,
		2.4,
		0.08,
		C.gold,
		Enum.Material.Metal
	)
	Kit.sign(
		parent,
		title,
		CFrame.new(x, y - 1.42, z - 0.18),
		Vector3.new(3.1, 0.64, 0.08),
		Enum.NormalId.Front,
		C.cream
	)
end

function Detail.apply(map: Model)
	local parent = map:FindFirstChild("Props")
	assert(parent, "studio props missing")
	local production = Kit.group(parent, "ProductionDressing")
	local archive = Kit.group(production, "Archive")
	local ctrl = Kit.group(production, "ControlA")
	local edit = Kit.group(production, "ControlB")
	local live = Kit.group(production, "LiveRoom")
	local iso = Kit.group(production, "IsolationBooths")
	local mastering = Kit.group(production, "MasteringSuite")

	-- Control A: 1980s acoustic timber, line of sight to the tracking hall.
	for _, z in { -100, -91, -72, -63 } do
		acoustic(ctrl, -83.6, 8.2, z, 90, 7.4)
	end
	acoustic(ctrl, -53, 9.2, -106.6, 0, 9)
	acoustic(ctrl, -43, 9.2, -106.6, 0, 8)
	speaker(ctrl, -66, 6, -74)
	speaker(ctrl, -47, 6, -74)
	reelMachineDetail(ctrl)
	-- Single authored hero console: 16 channels, meters and masters share the
	-- original gameplay collision/interaction. No duplicate boxy fader layer.
	StudioHeroConsole.build(ctrl, map)
	Kit.chair(ctrl, -56, -71, 180, C.leather)
	for _, x in { -49, -44, -39.8 } do
		Kit.rod(
			ctrl,
			"PatchCable",
			Vector3.new(x, 4.5, -95.5),
			Vector3.new(x - 0.5, 2.5, -95.5),
			0.07,
			C.gold
		)
	end
	wallAward(ctrl, -77, 11, -106.45, "WRENMOUTH / 1986")
	Kit.poster(ctrl, "THE LAST SESSION / 2 NOV 1987", -69, 9, -106.5, 4.2)
	Kit.sign(ctrl, "STUDIO A / RECORD", CFrame.new(-45, 12, -106.5), Vector3.new(15, 1.2, 0.1))

	-- Control B: editing, small tape and duplicate monitor chain.
	Kit.table(edit, "EditCounter", -52, -52, 10, 3.7, 2.8, C.wood)
	Kit.box(edit, "EditingDeck", -52, 3.6, -52, 5.6, 1, 2.5, C.metal, Enum.Material.Metal)
	for _, x in { -53.5, -50.5 } do
		Kit.disc(edit, "EditSpool", x, 4.22, -52, 1.8, 0.16, C.cream)
	end
	speaker(edit, -65, 5, -54)
	Kit.chair(edit, -52, -46, 180, C.foam)
	Kit.poster(edit, "MIX / B / STAFF ONLY", -41, 8, -57.5, 3.4)
	Kit.box(edit, "SafeDial", -75, 3.3, -46.4, 1.1, 1.1, 0.19, C.gold, Enum.Material.Metal)
	for i = 1, 3 do
		Kit.box(
			edit,
			"PaperFiling",
			-62 + i * 1.5,
			2,
			-35,
			1,
			3.2,
			0.55,
			if i % 2 == 0 then C.cream else C.woodLight
		)
	end

	-- Archive: shelves, labelled cassette spines and dust covers, without reel prompt occlusion.
	for j = 1, 3 do
		local z = -131.6 + j * 4
		for i = 1, 9 do
			tape(
				archive,
				-83 + i * 0.55,
				2.2 + (j % 2) * 1.7,
				z,
				if i % 3 == 0 then C.teal elseif i % 2 == 0 then C.woodLight else C.leather
			)
		end
	end
	for _, x in { -77, -72, -67, -62 } do
		Kit.box(archive, "ShelfLedge", x, 3.8, -128.1, 4, 0.13, 0.45, C.gold, Enum.Material.Metal)
		Kit.box(archive, "ShelfClip", x, 4.45, -128.09, 1.1, 0.5, 0.09, C.paper)
	end
	Kit.sign(
		archive,
		"MASTER TAPES / RETURN TO SHELF",
		CFrame.new(-69, 10, -133.55),
		Vector3.new(21, 1.5, 0.1),
		Enum.NormalId.Front,
		C.gold,
		C.dark
	)
	Kit.poster(archive, "SESSION CARDS / OCT 1987", -60.5, 8, -116, 3.5)

	-- Mastering suite: a smaller technical workstation tucked beside the archive.
	console(mastering, -45.5, -129, 8.7)
	Kit.chair(mastering, -45.5, -124.5, 180, C.fabric)
	Kit.rack(mastering, "MasteringOutboard", -54, -131, 3.3, 7.3, 90)
	speaker(mastering, -37, 5.2, -131)
	Kit.sign(
		mastering,
		"CUTTING / MASTER TRANSFER",
		CFrame.new(-46, 11.5, -133.55),
		Vector3.new(17, 1.1, 0.1)
	)

	-- Live room: keep the long Last Call diagonal unobstructed.
	Kit.box(live, "WornPersianCarpet", 5, 0.055, -82, 22, 0.1, 13, C.leather, Enum.Material.Fabric)
	Kit.box(
		live,
		"CarpetInnerBorder",
		5,
		0.12,
		-82,
		19.5,
		0.05,
		10.5,
		C.woodLight,
		Enum.Material.Fabric
	)
	drum(live, -18, -96)
	keyboard(live, 28, -98)
	amplifier(live, 35, -62, 4.3)
	amplifier(live, -28, -67, 3.6)
	mic(live, -8, -83, 4.9)
	mic(live, 12, -75, 4.9)
	Kit.rod(
		live,
		"MicrophoneBoom",
		Vector3.new(-8, 4.7, -83),
		Vector3.new(-5, 5.3, -83),
		0.13,
		C.steel
	)
	-- Visual instrument cases, easy to read at a distance; no physics or path blocks.
	Kit.block(
		live,
		"GuitarCase",
		CFrame.new(38.5, 1.6, -95) * CFrame.Angles(0, math.rad(20), 0),
		Vector3.new(1.6, 3.2, 0.5),
		C.black,
		Enum.Material.Fabric
	)
	Kit.block(
		live,
		"GuitarNeck",
		CFrame.new(36, 3.1, -101) * CFrame.Angles(0, 0, math.rad(12)),
		Vector3.new(0.42, 4.4, 0.37),
		C.wood,
		Enum.Material.Wood
	)
	Kit.disc(live, "GuitarBody", 36, 1.4, -101, 2.1, 0.45, C.woodLight)
	for _, data in
		{
			{ -30, 10, -78, 90 },
			{ -30, 10, -91, 90 },
			{ 42, 11, -86, -90 },
			{ 8, 10, -106.4, 0 },
		}
	do
		acoustic(live, data[1], data[2], data[3], data[4], 8)
	end
	Kit.sign(
		live,
		"WRENMOUTH CHOIR / TAKE 04",
		CFrame.new(-12, 14, -106.5),
		Vector3.new(15, 1.4, 0.12)
	)
	-- Tracking gobos, well off primary movement lanes.
	for _, data in { { -24, -101, 25 }, { 38, -103, -25 } } do
		local basis = CFrame.new(data[1], 3.4, data[2]) * CFrame.Angles(0, math.rad(data[3]), 0)
		Kit.block(
			live,
			"PortableGobo",
			basis,
			Vector3.new(5.7, 6.8, 0.32),
			C.foam,
			Enum.Material.Fabric
		)
		Kit.block(
			live,
			"GoboTrim",
			basis * CFrame.new(0, 0, -0.2),
			Vector3.new(5.9, 0.23, 0.18),
			C.woodLight,
			Enum.Material.Wood
		)
	end

	-- Three booths: instrument-specific silhouettes with no solid obstacles near the doors.
	for _, room in
		{
			{ name = "West", x = -21, z = -123 },
			{ name = "Vocal", x = 5, z = -123 },
			{ name = "Drums", x = 31, z = -123 },
		}
	do
		acoustic(iso, room.x, 8, -133.2, 0, 15)
		acoustic(iso, room.x - 11.3, 8, -120, 90, 8)
		acoustic(iso, room.x + 11.3, 8, -120, 90, 8)
	end
	mic(iso, 5, -127, 5.3)
	Kit.disc(iso, "PopFilter", 5, 5.2, -125.7, 1.4, 0.09, C.dark)
	Kit.box(iso, "MusicStand", 8, 3.45, -127.2, 2.7, 1.8, 0.2, C.black, Enum.Material.Metal)
	amplifier(iso, -22, -129, 4.8)
	Kit.table(iso, "GuitarCaseShelf", -12, -129, 4, 2.2, 1.8, C.woodLight)
	drum(iso, 31, -127)
	Kit.sign(iso, "LIVE / 1", CFrame.new(-21, 11, -133.5), Vector3.new(10, 1.1, 0.12))
	Kit.sign(iso, "VOCAL / 2", CFrame.new(5, 11, -133.5), Vector3.new(10, 1.1, 0.12))
	Kit.sign(iso, "DRUMS / 3", CFrame.new(31, 11, -133.5), Vector3.new(10, 1.1, 0.12))
end

return Detail
