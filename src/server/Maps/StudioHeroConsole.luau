--!strict
-- Wrenmouth studio's hero mixing desk. Native, source-built geometry:
-- restrained late-1980s analog recording console, no Creator Store dependencies.
--
-- VISUAL ONLY: the original Objectives.MixingDesk remains the sole solid
-- interaction volume and Chapter 1's authoritative puzzle target.
-- All new detail is noncolliding, non-queryable and designed around
-- Control A's existing warm desk/softbox lighting.
local ServerStorage = game:GetService("ServerStorage")
local HeroConsole = {}

local PALETTE = {
	wood = Color3.fromRGB(96, 58, 38),
	woodEdge = Color3.fromRGB(157, 101, 57),
	woodDark = Color3.fromRGB(59, 40, 30),
	chassis = Color3.fromRGB(48, 54, 54),
	panel = Color3.fromRGB(84, 91, 89),
	strip = Color3.fromRGB(71, 78, 79),
	matte = Color3.fromRGB(33, 39, 42),
	shadow = Color3.fromRGB(18, 22, 25),
	steel = Color3.fromRGB(165, 168, 155),
	champagne = Color3.fromRGB(194, 182, 148),
	cream = Color3.fromRGB(220, 208, 177),
	fader = Color3.fromRGB(201, 194, 169),
	oxide = Color3.fromRGB(145, 92, 57),
	tape = Color3.fromRGB(194, 151, 85),
	glass = Color3.fromRGB(214, 196, 146),
	needle = Color3.fromRGB(147, 39, 37),
	live = Color3.fromRGB(180, 108, 68),
	signal = Color3.fromRGB(124, 151, 105),
}

-- Existing invisible objective top = 3.2 studs, x -56, z -78.
-- The positive-Z edge faces the player's chair at (-56,-71).
local WIDTH = 10.7
local SLOPE = math.rad(7.5)
local DESK = CFrame.new(-56, 3.48, -78) * CFrame.Angles(SLOPE, 0, 0)
local CHANNELS = 16
local CHANNEL_PITCH = 0.505
local CHANNEL_FIRST = -4.8
local MODULE_NAME = "HeroMixConsole"

local function part(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	shadow: boolean?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = shadow == true
	p.Size = size
	p.CFrame = cf
	p.Material = material
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function block(
	parent: Instance,
	name: string,
	basis: CFrame,
	x: number,
	y: number,
	z: number,
	w: number,
	h: number,
	d: number,
	color: Color3,
	material: Enum.Material,
	shadow: boolean?
): Part
	return part(
		parent,
		name,
		basis * CFrame.new(x, y, z),
		Vector3.new(w, h, d),
		color,
		material,
		shadow
	)
end

local function cyl(
	parent: Instance,
	name: string,
	basis: CFrame,
	x: number,
	y: number,
	z: number,
	diameter: number,
	height: number,
	color: Color3
): Part
	-- Cylinder axis is X; turn it upward to align with the tilted control deck.
	local p = part(
		parent,
		name,
		basis * CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(90)),
		Vector3.new(height, diameter, diameter),
		color,
		Enum.Material.Metal
	)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function surfaceLabel(
	part_: BasePart,
	text_: string,
	face: Enum.NormalId,
	textColor: Color3,
	bg: Color3?,
	fontSize: number?
)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Print"
	gui.Face = face
	gui.PixelsPerStud = 72
	gui.LightInfluence = 0.45
	gui.AlwaysOnTop = false
	gui.Parent = part_
	local label = Instance.new("TextLabel")
	label.Name = "Ink"
	label.BackgroundTransparency = if bg then 0 else 1
	label.BackgroundColor3 = bg or PALETTE.panel
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Code
	label.Text = text_
	label.TextScaled = true
	label.TextColor3 = textColor
	label.TextStrokeTransparency = 0.94
	label.Parent = gui
	return gui
end

local function meter(parent: Instance, x: number, id: number)
	local basis = CFrame.new(-56 + x, 4.64, -79.15)
	-- Front face points toward operator, positive Z.
	local case = block(
		parent,
		"VUHousing_" .. id,
		basis,
		0,
		0,
		0,
		1.00,
		1.04,
		0.20,
		PALETTE.shadow,
		Enum.Material.Metal
	)
	local glass = block(
		parent,
		"VULens_" .. id,
		basis,
		0,
		0.06,
		0.118,
		0.86,
		0.76,
		0.05,
		PALETTE.glass,
		Enum.Material.Glass
	)
	glass.Transparency = 0.17
	surfaceLabel(
		glass,
		"VU   " .. string.format("%02d", id) .. "\n−20  −7   0  +3",
		Enum.NormalId.Front,
		PALETTE.matte,
		nil
	)
	-- A physical needle is easier to see at oblique angles than a printed line.
	local needle = block(
		parent,
		"VUNeedle_" .. id,
		basis,
		0.08,
		-0.12,
		0.153,
		0.025,
		0.56,
		0.023,
		PALETTE.needle,
		Enum.Material.Metal
	)
	needle.CFrame *= CFrame.Angles(0, 0, math.rad(10 + (id * 7) % 31))
	block(
		parent,
		"VUFrameLip_" .. id,
		basis,
		0,
		0.46,
		0.14,
		0.96,
		0.06,
		0.12,
		PALETTE.champagne,
		Enum.Material.Metal
	)
	return case
end

local function channel(parent: Instance, i: number)
	local x = CHANNEL_FIRST + (i - 1) * CHANNEL_PITCH
	local id = string.format("%02d", i)
	-- Sloped but individually inset channel strips; no full-coverage neon.
	block(
		parent,
		"ChannelPlate_" .. id,
		DESK,
		x,
		0.075,
		0.03,
		0.463,
		0.10,
		3.29,
		if i % 4 == 0 then PALETTE.panel else PALETTE.strip,
		Enum.Material.Metal
	)
	block(
		parent,
		"ChannelDivider_" .. id,
		DESK,
		x + 0.241,
		0.135,
		0.03,
		0.018,
		0.055,
		3.25,
		PALETTE.shadow,
		Enum.Material.Metal
	)
	-- Three grouped EQ / gain trims, slightly varied knobs and aligned centers.
	for j = 1, 3 do
		local z = -1.20 + (j - 1) * 0.38
		local knob = cyl(
			parent,
			"EQKnob_" .. id .. "_" .. j,
			DESK,
			x,
			0.205,
			z,
			0.24,
			0.16,
			if j == 1 then PALETTE.champagne else PALETTE.matte
		)
		knob:SetAttribute("EQGroup", j)
		block(
			parent,
			"EQNotch_" .. id .. "_" .. j,
			DESK,
			x,
			0.298,
			z - 0.055,
			0.025,
			0.018,
			0.075,
			PALETTE.cream,
			Enum.Material.SmoothPlastic
		)
	end
	-- Tiny power/track-arm button is matte until the lighting state wakes.
	local arm = block(
		parent,
		"ArmButton_" .. id,
		DESK,
		x,
		0.16,
		0.115,
		0.18,
		0.11,
		0.23,
		PALETTE.shadow,
		Enum.Material.SmoothPlastic
	)
	arm:SetAttribute("ConsoleIndicator", if i == 1 or i == 2 then "record" else "signal")
	-- Long, readable mechanical fader throw.
	block(
		parent,
		"FaderSlot_" .. id,
		DESK,
		x,
		0.146,
		0.82,
		0.095,
		0.03,
		1.13,
		PALETTE.shadow,
		Enum.Material.Metal
	)
	local z = 0.45 + ((i * 7) % 13) / 13 * 0.64
	local fader = block(
		parent,
		"FaderCap_" .. id,
		DESK,
		x,
		0.24,
		z,
		0.36,
		0.18,
		0.26,
		PALETTE.fader,
		Enum.Material.Metal
	)
	block(
		parent,
		"FaderGrip_" .. id,
		DESK,
		x,
		0.343,
		z,
		0.28,
		0.012,
		0.038,
		PALETTE.shadow,
		Enum.Material.Metal
	)
	fader:SetAttribute("ConsoleFader", i)
	-- Channel numbers are screen-space typography mounted to actual geometry.
	local tag = block(
		parent,
		"ChannelNumber_" .. id,
		DESK,
		x,
		0.155,
		1.56,
		0.35,
		0.018,
		0.20,
		PALETTE.matte,
		Enum.Material.SmoothPlastic
	)
	surfaceLabel(tag, id, Enum.NormalId.Top, PALETTE.cream)
end

local function buildMaster(parent: Instance)
	-- 2-channel group/master section at the right of the sixteen input strips.
	local x = 3.92
	block(
		parent,
		"MasterPanel",
		DESK,
		x,
		0.075,
		0.02,
		2.30,
		0.095,
		3.30,
		PALETTE.matte,
		Enum.Material.Metal
	)
	for j, label in { "L", "R" } do
		local shift = x - 0.43 + (j - 1) * 0.88
		block(
			parent,
			"MasterThrow_" .. label,
			DESK,
			shift,
			0.17,
			0.59,
			0.13,
			0.035,
			1.75,
			PALETTE.shadow,
			Enum.Material.Metal
		)
		block(
			parent,
			"MasterCap_" .. label,
			DESK,
			shift,
			0.255,
			0.50 + (j - 1) * 0.12,
			0.44,
			0.17,
			0.30,
			PALETTE.cream,
			Enum.Material.Metal
		)
		cyl(parent, "PanKnob_" .. label, DESK, shift, 0.22, -0.83, 0.36, 0.18, PALETTE.champagne)
		local plate = block(
			parent,
			"MasterLabel_" .. label,
			DESK,
			shift,
			0.16,
			1.48,
			0.63,
			0.023,
			0.24,
			PALETTE.shadow,
			Enum.Material.SmoothPlastic
		)
		surfaceLabel(plate, "MASTER " .. label, Enum.NormalId.Top, PALETTE.cream)
	end
	for j = 1, 6 do
		local dx = x - 0.79 + ((j - 1) % 3) * 0.76
		local dz = -1.43 + math.floor((j - 1) / 3) * 0.42
		local led = block(
			parent,
			"BusLamp_" .. j,
			DESK,
			dx,
			0.15,
			dz,
			0.22,
			0.06,
			0.12,
			PALETTE.shadow,
			Enum.Material.SmoothPlastic
		)
		led:SetAttribute("ConsoleIndicator", if j == 6 then "record" else "signal")
	end
end

local IMPORTED_WIDTH = 11.01
local IMPORTED_CENTER = Vector3.new(-56, 2.815, -77.585)

local function buildImported(parent: Instance, objectives: Instance?): Model?
	local template = ServerStorage:FindFirstChild("WrenmouthDA16", true)
	if not template or not template:IsA("Model") then
		return nil
	end
	local clone = template:Clone()
	clone.Name = MODULE_NAME
	clone:SetAttribute("ConsoleBuild", "DA-16/1987-imported-glb")
	clone:SetAttribute("Channels", CHANNELS)
	clone:SetAttribute("DetailOnly", true)
	clone:SetAttribute("ImportedQualityMesh", true)
	local count = 0
	for _, item in clone:GetDescendants() do
		if item:IsA("BasePart") then
			count += 1
			item.Anchored = true
			item.CanCollide = false
			item.CanQuery = false
			item.CanTouch = false
			local parentName = if item.Parent then item.Parent.Name else ""
			-- glTF importer adds one wrapper Model per node on some Studio versions.
			-- Read either MeshPart or parent name to find our channel identities.
			item.CastShadow = string.find(item.Name, "DA16_WOOD", 1, true) ~= nil
				or string.find(parentName, "DA16_WOOD", 1, true) ~= nil
				or string.find(item.Name, "DA16_METAL", 1, true) ~= nil
				or string.find(parentName, "DA16_METAL", 1, true) ~= nil
			local channelId = string.match(item.Name, "ArmButton_(%d%d)")
				or string.match(parentName, "ArmButton_(%d%d)")
			local busId = string.match(item.Name, "BusLamp_(%d%d)")
				or string.match(parentName, "BusLamp_(%d%d)")
			if channelId or busId then
				local isRecord = channelId == "01" or channelId == "02" or busId == "06"
				item:SetAttribute("ConsoleIndicator", if isRecord then "record" else "signal")
				item:SetAttribute("UseOpacityForPower", true)
			end
		end
	end
	if count < 50 then
		warn("[DeadAir] Imported DA-16 incomplete; verify the glTF mesh hierarchy.")
	end
	clone.Parent = parent
	local extents = clone:GetExtentsSize()
	if extents.X > 0.1 then
		clone:ScaleTo(clone:GetScale() * (IMPORTED_WIDTH / extents.X))
	end
	-- The glTF import faces away from the operator at +Z. Rotate about
	-- its bounds center so the bridge sits behind the faders and the paper
	-- shelf aligns with the existing SessionLog interaction.
	local bounds = clone:GetBoundingBox()
	local placement = CFrame.new(IMPORTED_CENTER)
		* CFrame.Angles(0, math.pi, 0)
		* CFrame.new(-bounds.Position)
	clone:PivotTo(placement * clone:GetPivot())
	local log = objectives and objectives:FindFirstChild("SessionLog")
	if log and log:IsA("BasePart") then
		log.Transparency = 1
	end
	return clone
end

function HeroConsole.build(parent: Instance, map: Model): Model
	local objectives = map:FindFirstChild("Objectives")
	local interaction = objectives and objectives:FindFirstChild("MixingDesk")
	if interaction and interaction:IsA("BasePart") then
		-- Invisible collision/prompt body; all visible construction is below.
		interaction.Transparency = 1
	end
	local existing = parent:FindFirstChild(MODULE_NAME)
	if existing then
		existing:Destroy()
	end
	local imported = buildImported(parent, objectives)
	if imported then
		return imported
	end
	local model = Instance.new("Model")
	model.Name = MODULE_NAME
	model:SetAttribute("ConsoleBuild", "DA-16/1987")
	model:SetAttribute("Channels", CHANNELS)
	model:SetAttribute("DetailOnly", true)
	model.Parent = parent

	-- Solid visual shell follows the old objective envelope, but casts no
	-- new collision rays and keeps the mixing desk puzzle unchanged.
	local stand = block(
		model,
		"HardwoodConsoleBody",
		CFrame.new(-56, 1.58, -78),
		0,
		0,
		0,
		WIDTH + 0.25,
		2.92,
		3.94,
		PALETTE.woodDark,
		Enum.Material.Wood,
		true
	)
	block(
		model,
		"FrontKneePanel",
		stand.CFrame,
		0,
		-0.4,
		1.998,
		WIDTH - 0.33,
		1.62,
		0.13,
		PALETTE.wood,
		Enum.Material.Wood
	)
	block(
		model,
		"DeskTopShell",
		DESK,
		0,
		-0.12,
		0,
		WIDTH,
		0.30,
		3.86,
		PALETTE.chassis,
		Enum.Material.Metal,
		true
	)
	for _, side in { -1, 1 } do
		block(
			model,
			"WoodSideCheek",
			DESK,
			side * (WIDTH / 2 - 0.05),
			0.08,
			0,
			0.32,
			0.52,
			4.02,
			PALETTE.wood,
			Enum.Material.Wood,
			true
		)
		block(
			model,
			"SideCheekInlay",
			DESK,
			side * (WIDTH / 2 - 0.05),
			0.36,
			-0.12,
			0.08,
			0.035,
			3.55,
			PALETTE.woodEdge,
			Enum.Material.Wood
		)
	end
	block(
		model,
		"FrontHandRest",
		DESK,
		0,
		0.10,
		1.85,
		WIDTH - 0.35,
		0.38,
		0.55,
		PALETTE.woodEdge,
		Enum.Material.Wood
	)
	block(
		model,
		"FrontTrimLine",
		DESK,
		0,
		0.32,
		1.53,
		WIDTH - 0.40,
		0.038,
		0.085,
		PALETTE.champagne,
		Enum.Material.Metal
	)
	block(
		model,
		"RearPanelRail",
		DESK,
		0,
		0.13,
		-1.82,
		WIDTH - 0.4,
		0.20,
		0.21,
		PALETTE.wood,
		Enum.Material.Wood
	)

	for i = 1, CHANNELS do
		channel(model, i)
	end
	buildMaster(model)

	-- This is a coherent meter bridge, not seven extra floating glowing boxes.
	local frame = CFrame.new(-56, 4.52, -79.62)
	block(
		model,
		"MeterBridgeCabinet",
		frame,
		0,
		0,
		-0.10,
		WIDTH + 0.18,
		2.14,
		0.78,
		PALETTE.wood,
		Enum.Material.Wood,
		true
	)
	block(
		model,
		"MeterBridgeBlackFace",
		frame,
		0,
		0,
		0.30,
		WIDTH - 0.18,
		1.71,
		0.085,
		PALETTE.shadow,
		Enum.Material.Metal
	)
	for i = 1, 8 do
		meter(model, -4.30 + (i - 1) * 1.22, i)
	end
	block(
		model,
		"MeterBridgeUpperLip",
		frame,
		0,
		1.01,
		0.36,
		WIDTH - 0.12,
		0.09,
		0.24,
		PALETTE.woodEdge,
		Enum.Material.Wood
	)
	local crest = block(
		model,
		"ManufacturerPlate",
		frame,
		0,
		-0.94,
		0.47,
		4.6,
		0.26,
		0.05,
		PALETTE.matte,
		Enum.Material.Metal
	)
	surfaceLabel(
		crest,
		"WRENMOUTH  •  DA-16  /  ANALOGUE",
		Enum.NormalId.Front,
		PALETTE.champagne
	)

	-- A safe paper-reading shelf immediately in front of the existing console.
	-- The original SessionLog objective is moved here by StudioGroundFloor,
	-- maintaining the same read prompt and authority.
	block(
		model,
		"SessionLogReadingShelf",
		CFrame.new(-57, 3.48, -75.68),
		0,
		0,
		0,
		2.52,
		0.13,
		1.32,
		PALETTE.wood,
		Enum.Material.Wood
	)
	block(
		model,
		"SessionLogTrayLip",
		CFrame.new(-57, 3.54, -75.03),
		0,
		0,
		0,
		2.47,
		0.11,
		0.13,
		PALETTE.woodEdge,
		Enum.Material.Wood
	)

	return model
end

return HeroConsole
