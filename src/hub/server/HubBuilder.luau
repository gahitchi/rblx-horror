--!strict
-- The edge of Wrenmouth, 2026. A hand-built-feeling playable hub made from
-- native geometry: warm lay-by / van in the west, navy fence and town in the east.
-- This is deliberately separate from Workspace.Map, chapter AI and match scripts.

local HubBuilder = {}

local C = {
	night = Color3.fromRGB(15, 26, 34),
	stone = Color3.fromRGB(39, 48, 51),
	gravel = Color3.fromRGB(69, 67, 62),
	asphalt = Color3.fromRGB(48, 52, 54),
	roadWear = Color3.fromRGB(68, 69, 67),
	cream = Color3.fromRGB(205, 187, 154),
	rust = Color3.fromRGB(138, 74, 42),
	amber = Color3.fromRGB(232, 162, 74),
	wood = Color3.fromRGB(102, 79, 57),
	darkWood = Color3.fromRGB(63, 53, 46),
	navy = Color3.fromRGB(91, 99, 107),
	navyDark = Color3.fromRGB(46, 58, 67),
	yellow = Color3.fromRGB(217, 179, 58),
	fog = Color3.fromRGB(61, 74, 85),
	pale = Color3.fromRGB(201, 219, 230),
	sea = Color3.fromRGB(13, 28, 40),
	glass = Color3.fromRGB(91, 112, 121),
	moss = Color3.fromRGB(50, 63, 53),
	black = Color3.fromRGB(22, 26, 30),
}

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function block(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = solid == true
	p.CanQuery = solid == true
	p.CanTouch = false
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function box(
	parent: Instance,
	name: string,
	x: number,
	y: number,
	z: number,
	sx: number,
	sy: number,
	sz: number,
	color: Color3,
	material: Enum.Material?,
	solid: boolean?
): Part
	return block(parent, name, CFrame.new(x, y, z), Vector3.new(sx, sy, sz), color, material, solid)
end

local function helper(parent: Instance, name: string, cf: CFrame, size: Vector3): Part
	local p = block(parent, name, cf, size, C.pale, nil, false)
	p.Transparency = 1
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	return p
end

local function rod(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	thickness: number,
	color: Color3
): Part
	return block(
		parent,
		name,
		CFrame.lookAt((a + b) / 2, b),
		Vector3.new(thickness, thickness, (b - a).Magnitude),
		color,
		Enum.Material.Metal
	)
end

local function sign(
	parent: Instance,
	text: string,
	cf: CFrame,
	size: Vector3,
	bg: Color3?,
	ink: Color3?,
	face: Enum.NormalId?
): Part
	local p = block(parent, "Notice", cf, size, bg or C.navyDark)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "PaintedLettering"
	gui.Face = face or Enum.NormalId.Front
	gui.PixelsPerStud = 32
	gui.LightInfluence = 0.25
	gui.Parent = p
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Caption"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextScaled = true
	textLabel.TextWrapped = true
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextColor3 = ink or C.cream
	textLabel.TextStrokeTransparency = 0.8
	textLabel.Parent = gui
	return p
end

local function light(
	parent: Instance,
	x: number,
	y: number,
	z: number,
	brightness: number,
	range: number,
	color: Color3
): Part
	local p = box(parent, "SteadyTungstenLamp", x, y, z, 1.7, 0.45, 1.4, color, Enum.Material.Neon)
	local point = Instance.new("PointLight")
	point.Color = color
	point.Brightness = brightness
	point.Range = range
	point.Shadows = false
	point.Parent = p
	return p
end

local function cylinder(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3
): Part
	local p = block(parent, name, cf, size, color, Enum.Material.Metal)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function roadAndTerrain(hub: Model, ground: Folder)
	box(ground, "Moorland", -5, -2, 0, 178, 4, 132, C.stone, Enum.Material.Ground, true)
	-- The north side drops away: the playable moor ends at the railing.
	box(ground, "CoastRoad", -8, 0.13, 9, 144, 0.26, 26, C.asphalt, Enum.Material.Asphalt, true)
	box(ground, "GravelLayby", -26, 0.13, -24, 106, 0.26, 37, C.gravel, Enum.Material.Pebble, true)
	for x = -69, 49, 13 do
		box(
			ground,
			"FadedRoadCentreLine",
			x,
			0.29,
			9,
			7.5,
			0.07,
			0.24,
			C.cream,
			Enum.Material.Concrete
		)
	end
	for _, z in { -4.4, 22.2 } do
		box(ground, "BrokenEdgePaint", -8, 0.28, z, 141, 0.05, 0.12, C.roadWear)
	end
	for i = 1, 25 do
		local x = -72 + ((i * 43) % 128)
		local z = -39 + ((i * 17) % 30)
		box(
			ground,
			"GravelWear",
			x,
			0.29,
			z,
			1.4 + i % 5,
			0.05,
			0.5 + i % 3,
			C.roadWear,
			Enum.Material.Slate
		)
	end
	-- Small stone and low bracken clusters on the southern moorland.
	for i = 1, 16 do
		local x = -74 + ((i * 27) % 140)
		local z = 32 + ((i * 13) % 28)
		local rock = box(
			ground,
			"MoorlandStone",
			x,
			0.46,
			z,
			1.6 + (i % 4),
			0.9,
			2.2 + (i % 3),
			if i % 2 == 0 then C.gravel else C.moss,
			Enum.Material.Slate
		)
		rock.CFrame *= CFrame.Angles(0, math.rad(i * 23), math.rad(i % 3 * 8))
	end
	-- A narrow, physical stop at the cliff; the sea is much lower than the lay-by.
	box(ground, "NorthCliffRockFace", 0, -15, -66, 184, 30, 7, C.stone, Enum.Material.Rock, true)
	box(ground, "Sea", 45, -40, -148, 430, 1.2, 180, C.sea, Enum.Material.SmoothPlastic, false)
	for _, z in { -87, -115, -145 } do
		box(ground, "SeaFoam", 40, -39.3, z, 95, 0.08, 0.45, C.fog, Enum.Material.SmoothPlastic)
	end
	for x = -76, 76, 10 do
		box(
			ground,
			"CliffSafetyPost",
			x,
			2.2,
			-59,
			0.5,
			4.4,
			0.5,
			C.navy,
			Enum.Material.Metal,
			true
		)
	end
	for _, y in { 1.5, 3.6 } do
		rod(
			ground,
			"CliffGuardRail",
			Vector3.new(-78, y, -59),
			Vector3.new(78, y, -59),
			0.26,
			C.navy
		)
	end
	-- Natural moorland bounds; discreet blocking walls prevent leaving the hub.
	for _, spec in
		{
			{ x = -88, z = 0, sx = 2, sz = 132 },
			{ x = 0, z = 66, sx = 178, sz = 2 },
			{ x = 0, z = -62.4, sx = 178, sz = 1.6 },
		}
	do
		local wall = box(
			ground,
			"SoftPlayBoundary",
			spec.x,
			5,
			spec.z,
			spec.sx,
			12,
			spec.sz,
			C.night,
			nil,
			true
		)
		wall.Transparency = 1
		wall.CanQuery = false
	end
end

local function makeGate(hub: Model, ground: Folder, markers: Folder)
	local fence = folder(hub, "NavyFence")
	local fenceX = 58
	for _, span in
		{
			{ from = -61, to = -12 },
			{ from = 12, to = 63 },
		}
	do
		-- A chain-link impression made with a dark, translucent fence sheet
		-- and a few larger crossed wires, not hundreds of physics parts.
		local centre = (span.from + span.to) / 2
		local len = span.to - span.from
		local sheet = box(
			fence,
			"PerforatedFence",
			fenceX,
			5.8,
			centre,
			0.15,
			11.6,
			len,
			C.glass,
			Enum.Material.Metal,
			true
		)
		sheet.Transparency = 0.57
		for z = span.from, span.to, 7.5 do
			box(
				fence,
				"SteelFencePost",
				fenceX,
				6.3,
				z,
				0.7,
				12.6,
				0.7,
				C.navy,
				Enum.Material.Metal,
				true
			)
		end
		for _, y in { 1.0, 6.0, 11.5 } do
			rod(
				fence,
				"FenceRail",
				Vector3.new(fenceX, y, span.from),
				Vector3.new(fenceX, y, span.to),
				0.18,
				C.navy
			)
		end
		-- A sparse diagonal wire weave gives the sheet a chain-link read at
		-- gameplay distance without hundreds of collidable mesh pieces.
		for z = span.from + 2, span.to - 1, 6 do
			for _, pair in
				{
					{ from = 1.6, to = 5.5 },
					{ from = 6.2, to = 10.1 },
				}
			do
				local left = rod(
					fence,
					"ChainLinkDiagonal",
					Vector3.new(fenceX - 0.13, pair.from, z - 2),
					Vector3.new(fenceX - 0.13, pair.to, z + 2),
					0.07,
					C.navy
				)
				left.CanCollide = false
				left.CanQuery = false
				local right = rod(
					fence,
					"ChainLinkDiagonal",
					Vector3.new(fenceX - 0.13, pair.from, z + 2),
					Vector3.new(fenceX - 0.13, pair.to, z - 2),
					0.07,
					C.navy
				)
				right.CanCollide = false
				right.CanQuery = false
			end
		end
	end
	for _, z in { -13, 13 } do
		box(
			fence,
			"QuarantineGatePost",
			fenceX,
			7.3,
			z,
			1.8,
			14.6,
			1.8,
			C.navyDark,
			Enum.Material.Metal,
			true
		)
	end
	sign(
		fence,
		"NAVY  ·  QUARANTINE  ·  NO ENTRY",
		CFrame.new(57.2, 8, 32),
		Vector3.new(0.2, 3.4, 25),
		C.navyDark,
		C.yellow,
		Enum.NormalId.Left
	)
	sign(
		fence,
		"WRENMOUTH  /  CLOSED 1987",
		CFrame.new(57.2, 8, -37),
		Vector3.new(0.2, 3, 25),
		C.navyDark,
		C.yellow,
		Enum.NormalId.Left
	)
	-- A liftable striped arm; actual collision is the invisible barrier below.
	local gate = Instance.new("Model")
	gate.Name = "Gate"
	gate.Parent = hub
	local hinge = helper(gate, "Hinge", CFrame.new(fenceX - 1.4, 5.3, -12), Vector3.new(1, 1, 1))
	local arm = box(
		gate,
		"BarrierArm",
		fenceX - 1.4,
		5.3,
		0,
		0.65,
		0.7,
		24,
		C.cream,
		Enum.Material.Metal,
		true
	)
	for z = -10.8, 10.5, 3 do
		local stripe = box(
			gate,
			"BarrierStripe",
			fenceX - 1.4,
			5.72,
			z,
			0.72,
			0.12,
			1.25,
			C.rust,
			Enum.Material.SmoothPlastic
		)
		stripe.CanCollide = false
		stripe.CanQuery = false
	end
	local blocker = box(gate, "GateBlocker", fenceX, 5, 0, 1.8, 10, 25.3, C.navyDark, nil, true)
	blocker.Transparency = 1
	blocker.CanQuery = false
	-- The gate's physical gap is enough for four players side by side once lifted.
	helper(markers, "GatePath", CFrame.new(60, 3.8, 0), Vector3.new(9, 7.6, 24))
	-- Even during the short crew-departure animation, the distant town is
	-- scenery rather than a playable level. Nobody can run off the ledge.
	local safety = box(ground, "FarSideSafetyBoundary", 78, 5, 0, 1.5, 15, 128, C.night, nil, true)
	safety.Transparency = 1
	safety.CanQuery = false
	-- The road on the far side runs downhill and disappears into fog.
	for i = 0, 4 do
		local x = 72 + i * 20
		local y = -2 - i * 3.2
		local strip = box(
			ground,
			"DescendingTownRoad",
			x,
			y,
			9,
			22,
			0.32,
			22,
			C.asphalt,
			Enum.Material.Asphalt
		)
		strip.CFrame *= CFrame.Angles(0, 0, math.rad(-9.1))
	end
	return hinge, arm
end

local function makeVan(hub: Model, markers: Folder, ground: Folder)
	local van = folder(hub, "HandlersVan")
	-- Original design, no real-world brand. The rear opens toward the crew at x=-44.
	-- Hollow shell, not a single obstructing block: players can inspect the
	-- rear workbench and the recovered tapes inside the open van.
	box(van, "VanCabFront", -13, 4.5, -25, 4.2, 8.4, 13.5, C.cream, Enum.Material.Metal, true)
	box(van, "VanUnderbody", -25, 0.85, -25, 25.8, 1.6, 13.5, C.cream, Enum.Material.Metal, true)
	for _, z in { -31.7, -18.3 } do
		box(van, "VanSidePanel", -26, 4.5, z, 23.8, 7.8, 0.48, C.cream, Enum.Material.Metal, true)
	end
	for _, z in { -31.9, -18.1 } do
		box(van, "RustSideStripe", -24, 4.25, z, 26.9, 2, 0.11, C.rust, Enum.Material.Metal)
		local window =
			box(van, "SideVanWindow", -23, 6.65, z, 9.2, 2.7, 0.13, C.glass, Enum.Material.Glass)
		window.Transparency = 0.25
	end
	box(van, "VanRoof", -24, 8.9, -25, 27.8, 0.65, 13.9, C.cream, Enum.Material.Metal, true)
	box(van, "Windscreen", -10.4, 6.55, -25, 0.18, 3.45, 9, C.glass, Enum.Material.Glass).Transparency =
		0.34
	-- No opaque wall at the open rear: the tape deck and filter electronics
	-- must remain visible when players approach the van from the lay-by.
	for _, z in { -30.9, -19.1 } do
		box(van, "RearDoorframeJamb", -37.6, 4.5, z, 0.34, 7.7, 0.4, C.darkWood, Enum.Material.Wood)
	end
	box(van, "RearDoorframeLintel", -37.6, 8.35, -25, 0.34, 0.3, 12, C.darkWood, Enum.Material.Wood)
	for _, z in { -29.8, -20.2 } do
		local doorPanel =
			box(van, "RearDoorOpen", -39, 4.8, z, 0.46, 7.0, 3.2, C.cream, Enum.Material.Metal)
		doorPanel.CFrame *= CFrame.Angles(0, math.rad(if z < -25 then -60 else 60), 0)
	end
	for _, x in { -32.8, -15.2 } do
		for _, z in { -31, -19 } do
			local tyre = cylinder(
				van,
				"Tyre",
				CFrame.new(x, 1.5, z) * CFrame.Angles(0, math.rad(90), 0),
				Vector3.new(1.15, 3.65, 3.65),
				C.black
			)
			tyre.CanCollide = false
			cylinder(
				van,
				"SteelHubcap",
				CFrame.new(x, 1.5, z + (if z < -25 then -0.65 else 0.65))
					* CFrame.Angles(0, math.rad(90), 0),
				Vector3.new(0.2, 1.9, 1.9),
				C.navy
			)
		end
	end
	box(van, "FrontBumper", -10, 1.9, -25, 1, 0.9, 14.2, C.navyDark, Enum.Material.Metal)
	box(van, "RearStep", -39.8, 0.85, -25, 3.5, 0.36, 9, C.navy, Enum.Material.Metal, true)
	-- Luminous van interior is visible as a doorway into the ordinary human world.
	box(van, "InteriorWoodFloor", -29, 0.5, -25, 15, 0.26, 10, C.wood, Enum.Material.WoodPlanks)
	light(van, -34.6, 7.3, -24.8, 1.9, 26, C.amber)
	for _, dx in { -35, -30, -25 } do
		box(van, "Workbench", dx, 2.3, -29.4, 4.4, 0.36, 2.6, C.darkWood, Enum.Material.Wood, true)
		box(van, "FilterRack", dx, 3.5, -30.6, 3.1, 1.8, 0.9, C.navyDark, Enum.Material.Metal)
		for _, ox in { -0.85, -0.2, 0.55 } do
			local led = box(
				van,
				"GreenFilterIndicator",
				dx + ox,
				3.9,
				-30.06,
				0.15,
				0.16,
				0.07,
				C.moss,
				Enum.Material.Neon
			)
			led.CastShadow = false
		end
	end
	-- An actual pinned working map; the family home, studio and navy
	-- listening station have been marked by the handler's hand.
	box(
		van,
		"WrenmouthMapBacking",
		-27.5,
		5.6,
		-18.04,
		12.4,
		5.5,
		0.13,
		C.darkWood,
		Enum.Material.Wood
	)
	box(
		van,
		"WrenmouthChartPaper",
		-27.5,
		5.6,
		-17.94,
		11.7,
		4.9,
		0.07,
		C.cream,
		Enum.Material.SmoothPlastic
	)
	for _, point in
		{
			{ x = -31.8, y = 6.3 },
			{ x = -29.2, y = 6.2 },
			{ x = -27.8, y = 5.2 },
			{ x = -25.1, y = 4.9 },
			{ x = -23.2, y = 6.6 },
		}
	do
		local pin = box(
			van,
			"SurveyPin",
			point.x,
			point.y,
			-17.82,
			0.23,
			0.23,
			0.12,
			C.rust,
			Enum.Material.Metal
		)
		pin.CastShadow = false
	end
	for _, path in
		{
			{ ax = -32, ay = 6.0, bx = -28, by = 5.2 },
			{ ax = -28, ay = 5.2, bx = -23.4, by = 6.4 },
			{ ax = -29.2, ay = 6.2, bx = -25.1, by = 4.9 },
		}
	do
		-- Strips are entirely decorative and flush to the chart paper.
		local centerX, centerY = (path.ax + path.bx) / 2, (path.ay + path.by) / 2
		local angle = math.atan2(path.by - path.ay, path.bx - path.ax)
		local length = math.sqrt((path.bx - path.ax) ^ 2 + (path.by - path.ay) ^ 2)
		local stringLine =
			box(van, "HarbourRouteString", centerX, centerY, -17.83, length, 0.07, 0.07, C.rust)
		stringLine.CFrame *= CFrame.Angles(0, 0, angle)
	end
	sign(
		van,
		"WRENMOUTH  /  COASTAL SURVEY",
		CFrame.new(-27.6, 7.8, -17.79),
		Vector3.new(11.3, 0.55, 0.08),
		C.darkWood,
		C.cream,
		Enum.NormalId.Front
	)
	-- The deck is an interactable visual marker, not a usable audio source yet.
	box(van, "TapeDeckBody", -34.1, 2.7, -23.0, 4.0, 1.4, 3.0, C.navyDark, Enum.Material.Metal)
	for _, x in { -35.2, -33 } do
		cylinder(van, "TapeSpool", CFrame.new(x, 3.43, -22.8), Vector3.new(0.16, 1.5, 1.5), C.cream)
	end
	box(van, "FoldoutTable", -42.5, 2.4, -25, 4.3, 0.3, 6.5, C.wood, Enum.Material.Wood)
	helper(
		markers,
		"VanDoors",
		CFrame.lookAt(Vector3.new(-44.2, 3.2, -25), Vector3.new(-25, 3.2, -25)),
		Vector3.new(5, 6, 8)
	)
	sign(
		van,
		"THE HANDLER / TAPE DECK",
		CFrame.new(-38.2, 8.3, -25),
		Vector3.new(0.12, 1.2, 10),
		C.navyDark,
		C.amber,
		Enum.NormalId.Left
	)
end

local function makeCrewAndCrate(hub: Model, markers: Folder)
	local hut = folder(hub, "CheckpointHut")
	box(hut, "HutConcretePad", 32, 0.15, -25, 27, 0.3, 20, C.asphalt, Enum.Material.Concrete, true)
	box(hut, "HutShell", 37.6, 4.5, -29, 16, 9, 12, C.navyDark, Enum.Material.Concrete, true)
	box(hut, "HutRoof", 37.6, 9.55, -29, 19, 1.1, 14, C.navy, Enum.Material.Metal)
	box(hut, "DarkHutWindow", 37.6, 6.8, -22.93, 8, 3, 0.15, C.black, Enum.Material.Glass)
	-- Noticeboard is free-standing by the hut, looking west along the lay-by.
	box(hut, "CrewBoardPosts", 21.5, 3.3, -20, 0.6, 6.6, 9.4, C.wood, Enum.Material.Wood)
	box(hut, "CrewBoardCork", 20.8, 6.4, -20, 0.32, 5.2, 10, C.darkWood, Enum.Material.Wood)
	sign(
		hut,
		"CREWS  /  SIGN IN",
		CFrame.new(20.58, 7.8, -20),
		Vector3.new(0.18, 1.6, 9),
		C.navyDark,
		C.amber,
		Enum.NormalId.Left
	)
	for _, z in { -23.5, -20, -16.5 } do
		box(
			hut,
			"CrewRosterSheet",
			20.56,
			5.6,
			z,
			0.16,
			1.5,
			2.5,
			C.cream,
			Enum.Material.SmoothPlastic
		)
	end
	helper(
		markers,
		"CrewBoard",
		CFrame.lookAt(Vector3.new(16.6, 3.7, -20), Vector3.new(22, 3.7, -20)),
		Vector3.new(3, 6, 7)
	)
	-- At the rear of the van: all crew equipment has a reason to be there.
	local crate = folder(hub, "EquipmentCrate")
	box(crate, "KitTrunk", -48, 1.05, -9, 7.0, 2.1, 5.2, C.darkWood, Enum.Material.Wood, true)
	box(crate, "TrunkLidOpen", -48, 3.2, -11.4, 7.2, 0.3, 4.5, C.rust, Enum.Material.Wood)
	for _, x in { -50.3, -48, -45.7 } do
		box(crate, "Flashlight", x, 2.35, -9.7, 0.55, 0.9, 2.2, C.navy, Enum.Material.Metal)
		box(crate, "Headset", x, 2.6, -7.8, 1.4, 0.5, 0.8, C.black, Enum.Material.Metal)
	end
	sign(
		crate,
		"CREW KIT / GEAR",
		CFrame.new(-48, 1.1, -6.29),
		Vector3.new(5.6, 1.0, 0.12),
		C.navyDark,
		C.yellow
	)
	helper(markers, "KitCrate", CFrame.new(-48, 2.9, -5), Vector3.new(6, 5, 5))
end

local function makeLookout(hub: Model, markers: Folder)
	local lookout = folder(hub, "Lookout")
	box(
		lookout,
		"LookoutSlab",
		-53,
		0.2,
		-47.8,
		29,
		0.4,
		18,
		C.gravel,
		Enum.Material.Concrete,
		true
	)
	for _, x in { -64, -55, -46 } do
		box(
			lookout,
			"LookoutFencePost",
			x,
			2.4,
			-56.9,
			0.6,
			4.8,
			0.6,
			C.wood,
			Enum.Material.Wood,
			true
		)
	end
	-- Facing east toward the town and lighthouse.
	box(lookout, "ViewBenchSeat", -62, 1.8, -49, 8, 0.4, 3, C.wood, Enum.Material.Wood, true)
	box(lookout, "ViewBenchBack", -62, 3.0, -50.35, 8.2, 2.2, 0.45, C.wood, Enum.Material.Wood)
	for _, x in { -65, -59 } do
		box(lookout, "ViewBenchFoot", x, 0.85, -49, 0.5, 1.7, 2.5, C.navy, Enum.Material.Metal)
	end
	local scope = cylinder(
		lookout,
		"TelescopePedestal",
		CFrame.new(-48, 2.5, -50) * CFrame.Angles(0, 0, math.rad(90)),
		Vector3.new(5, 0.9, 0.9),
		C.navy
	)
	scope.CanCollide = false
	local look = CFrame.lookAt(Vector3.new(-48, 5.2, -50), Vector3.new(155, -18, -10))
	cylinder(
		lookout,
		"BrassLookoutTelescope",
		look * CFrame.Angles(0, math.rad(90), 0),
		Vector3.new(6.2, 2.1, 2.1),
		C.wood
	)
	cylinder(lookout, "Eyepiece", look * CFrame.new(0, 0, 3.4), Vector3.new(1.2, 1.2, 1.2), C.black)
	helper(
		markers,
		"Telescope",
		CFrame.lookAt(Vector3.new(-50, 3.2, -47), Vector3.new(152, -20, -13)),
		Vector3.new(4, 6, 3)
	)
	sign(
		lookout,
		"WRENMOUTH  /  BELOW THE FOG",
		CFrame.new(-60.5, 4.4, -55.5),
		Vector3.new(13, 1.3, 0.12),
		C.darkWood,
		C.cream
	)
end

function HubBuilder.build(): Model
	local hub = Instance.new("Model")
	hub.Name = "Hub"
	hub:SetAttribute("Scene", "Wrenmouth Coast Checkpoint")
	hub:SetAttribute("SafeZone", true)
	local ground = folder(hub, "Landscape")
	local markers = folder(hub, "Markers")
	roadAndTerrain(hub, ground)
	makeGate(hub, ground, markers)
	makeVan(hub, markers, ground)
	makeCrewAndCrate(hub, markers)
	makeLookout(hub, markers)
	-- Client-only progress lights and distant landmark skyline are added by
	-- HubVista to avoid mixing gameplay markers into scenery.
	local HubVista = require(script.Parent.HubVista)
	HubVista.build(hub)
	helper(
		hub,
		"HubSpawn",
		CFrame.lookAt(Vector3.new(-68, 3.1, 9), Vector3.new(-21, 3.1, -18)),
		Vector3.new(4, 1, 4)
	)
	helper(markers, "Foghorn", CFrame.new(154, 12, -116), Vector3.one)
	-- Keep the scene free of accidental StarterPlace baseplate spawns.
	hub.Parent = workspace
	return hub
end

return HubBuilder
