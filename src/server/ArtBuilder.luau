--!strict
-- Recording studio: first environment-art pass.
-- This module adds visual detail WITHOUT replacing MapBuilder's geometry or gameplay anchors.
-- All decorative parts are non-collidable, non-queryable and non-touchable: the Engineer's
-- navigation, sound occlusion, objective prompts and door swings remain owned by existing code.
-- The active map comes from layout.map (see docs/MAP_CONTRACT.md). The details replicate at server start.
--
-- The assets are all native Roblox Parts/SurfaceGuis; no marketplace dependencies or asset IDs.
-- Room accents intentionally leave central walkways and every door threshold unobstructed.

local Lighting = game:GetService("Lighting")

local MapBuilder = require(script.Parent.MapBuilder)

local ArtBuilder = {}

local C = table.freeze({
    plaster = Color3.fromRGB(66, 65, 62),
    trim = Color3.fromRGB(30, 34, 35),
    timber = Color3.fromRGB(82, 54, 40),
    timberEdge = Color3.fromRGB(39, 30, 27),
    brass = Color3.fromRGB(113, 94, 62),
    steel = Color3.fromRGB(48, 54, 58),
    darkSteel = Color3.fromRGB(22, 25, 28),
    acoustic = Color3.fromRGB(39, 46, 49),
    acousticAlt = Color3.fromRGB(53, 57, 55),
    paper = Color3.fromRGB(170, 150, 118),
    glass = Color3.fromRGB(57, 83, 86),
    red = Color3.fromRGB(143, 48, 39),
    amber = Color3.fromRGB(181, 105, 49),
    screen = Color3.fromRGB(30, 91, 73),
    label = Color3.fromRGB(202, 191, 165),
})

local art: Folder
local built = false
local partCount = 0

local function detail(
    name: string, size: Vector3, transform: CFrame, color: Color3,
    material: Enum.Material?, parent: Instance?
): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = transform
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent or art
    partCount += 1
    return p
end

local function block(
    name: string, x: number, y: number, z: number,
    sx: number, sy: number, sz: number, color: Color3,
    material: Enum.Material?
): Part
    return detail(name, Vector3.new(sx, sy, sz), CFrame.new(x, y, z), color, material)
end

-- Cylinders are oriented along their local X axis.
local function cylinder(
    name: string, position: Vector3, length: number, diameter: number,
    color: Color3, vertical: boolean?
): Part
    local rotation = if vertical then CFrame.Angles(0, 0, math.rad(90)) else CFrame.identity
    local p = detail(
        name, Vector3.new(length, diameter, diameter),
        CFrame.new(position) * rotation, color, Enum.Material.Metal
    )
    p.Shape = Enum.PartType.Cylinder
    return p
end

-- An in-world, legible plaque. The local Back face points toward the viewer.
local function sign(
    name: string, text: string, position: Vector3, yaw: number,
    width: number, height: number, color: Color3, ink: Color3?
)
    local board = detail(
        name, Vector3.new(width, height, 0.16),
        CFrame.new(position) * CFrame.Angles(0, math.rad(yaw), 0),
        color, Enum.Material.Metal
    )
    local gui = Instance.new("SurfaceGui")
    gui.Name = "PrintedLettering"
    gui.Face = Enum.NormalId.Back
    gui.PixelsPerStud = 44
    gui.LightInfluence = 0.6
    gui.Parent = board
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Lettering"
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.RobotoMono
    textLabel.TextColor3 = ink or C.label
    textLabel.TextScaled = true
    textLabel.TextWrapped = true
    textLabel.Text = text
    textLabel.Parent = gui
end

local function colourStructure(studio: Instance)
    local structure = studio:FindFirstChild("Structure")
    if not structure then
        return
    end
    for _, child in structure:GetDescendants() do
        if not child:IsA("BasePart") then
            continue
        end
        if child.Name == "Wall" or child.Name == "Header" then
            local foamWall = child.Position.X < -39 and child.Position.Z < -71
            child.Color = if foamWall then C.acoustic else C.plaster
            child.Material = if foamWall then Enum.Material.Fabric else Enum.Material.Concrete
        elseif string.find(child.Name, "Ceiling") then
            child.Color = C.darkSteel
            child.Material = Enum.Material.Concrete
        elseif string.find(child.Name, "Floor") then
            if string.find(child.Name, "Reception") then
                child.Color = Color3.fromRGB(83, 79, 70)
                child.Material = Enum.Material.Slate
            elseif string.find(child.Name, "Live") then
                child.Color = C.timber
                child.Material = Enum.Material.WoodPlanks
            elseif string.find(child.Name, "Basement") or string.find(child.Name, "Archive") then
                child.Color = Color3.fromRGB(57, 59, 58)
                child.Material = Enum.Material.Concrete
            else
                child.Color = Color3.fromRGB(54, 48, 45)
                child.Material = Enum.Material.Fabric
            end
        end
    end
end

local function trimX(x1: number, x2: number, z: number, floorY: number)
    block("WallSkirting", (x1 + x2) / 2, floorY + 0.45, z, x2 - x1, 0.9, 0.16, C.timberEdge, Enum.Material.Wood)
end

local function trimZ(x: number, z1: number, z2: number, floorY: number)
    block("WallSkirting", x, floorY + 0.45, (z1 + z2) / 2, 0.16, 0.9, z2 - z1, C.timberEdge, Enum.Material.Wood)
end

local function acousticPanel(x: number, y: number, z: number, yaw: number, width: number, height: number, variant: number)
    detail(
        "AcousticAbsorber", Vector3.new(width, height, 0.24),
        CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0),
        if variant % 2 == 0 then C.acoustic else C.acousticAlt,
        Enum.Material.Fabric
    )
    -- Vertical seams imply layered absorption rather than a flat rectangle.
    for j = 1, 3 do
        local localX = -width / 2 + j * width / 4
        detail(
            "FoamGroove", Vector3.new(0.04, height - 0.25, 0.02),
            CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0)
                * CFrame.new(localX, 0, 0.14),
            C.trim
        )
    end
end

local function tubeLight(
    layout: MapBuilder.Layout, name: string, x: number, y: number, z: number
)
    local lamp = block(name, x, y, z, 2.2, 0.16, 0.55, C.darkSteel, Enum.Material.Metal)
    local fixture = Instance.new("PointLight")
    fixture.Color = Color3.fromRGB(255, 104, 73)
    fixture.Range = 14
    fixture.Brightness = 0.55
    fixture.Shadows = false
    fixture.Enabled = false
    fixture.Parent = lamp
    table.insert(layout.powerLights, fixture)
    table.insert(layout.powerLamps, lamp)
end

local function reception()
    trimX(-19, 19, 29.4, 0)
    trimZ(-19.4, 1, 28, 0)
    trimZ(19.4, 1, 28, 0)

    -- Existing FrontDesk is the collision shape; these pieces are visual dressing.
    block("ReceptionDesktop", -12, 3.55, 10, 10.8, 0.22, 3.5, C.timber, Enum.Material.Wood)
    block("DeskBrassEdge", -12, 3.51, 11.8, 10.8, 0.1, 0.1, C.brass, Enum.Material.Metal)
    block("ReceptionMonitor", -12.5, 5.1, 8.8, 3.1, 2.3, 0.25, C.darkSteel)
    block("MonitorGlass", -12.5, 5.1, 8.95, 2.7, 1.8, 0.04, C.screen, Enum.Material.Glass)
    block("Keyboard", -12.2, 3.72, 10.6, 3, 0.14, 0.85, C.darkSteel)
    for i = 0, 3 do
        block("ReceptionFloorSeam", -17 + i * 10, 0.035, 14.5, 0.04, 0.04, 28, C.trim)
    end
    sign("StudioIdentity", "BLACKLINE\nRECORDING", Vector3.new(0, 7.5, 0.61), 0, 10, 3, C.timberEdge)
    sign("ExitWarning", "FIRE EXIT  /  RECEPTION", Vector3.new(0, 9.7, 29.38), 180, 10, 1.25, C.darkSteel, C.red)
    sign("RecordingSchedule", "SESSION LOG\n04 / 17    23:40\nROOM A    ACTIVE\nENGINEER  ON DUTY", Vector3.new(19.37, 6.5, 17), -90, 5, 4, C.timberEdge)
    -- Waiting area, anchored to the existing sofa silhouette.
    block("SofaBack", 12, 2.65, 19.25, 8.3, 2.2, 0.55, Color3.fromRGB(67, 46, 47), Enum.Material.Fabric)
    for _, x in { 9.4, 12, 14.6 } do
        block("SofaCushion", x, 2.6, 17.6, 2.35, 0.18, 2.3, Color3.fromRGB(86, 62, 59), Enum.Material.Fabric)
    end
    block("WaitingMagazine", 12, 2.8, 17.4, 0.7, 0.08, 1.1, C.paper)
end

local function studioConsole(x: number, suffix: string)
    -- Existing MixingDeskA/B stays collidable and occupies x +/- 8, z -37.5..-34.5.
    block("ConsoleTop" .. suffix, x, 3.59, -36, 16.2, 0.22, 3.4, C.darkSteel, Enum.Material.Metal)
    for i = 1, 11 do
        local px = x - 7.1 + (i - 1) * 1.39
        block("Channel" .. suffix, px, 3.73, -35.85, 0.95, 0.035, 2.6, C.steel, Enum.Material.Metal)
        block("FaderSlot" .. suffix, px, 3.77, -35.25, 0.09, 0.03, 1.05, C.trim)
        block("FaderCap" .. suffix, px, 3.81, -35.35 - (i % 3) * 0.18, 0.42, 0.08, 0.23, C.paper)
        block("Indicator" .. suffix, px, 3.77, -36.93, 0.15, 0.04, 0.15,
            if i % 4 == 0 then C.red else C.screen, Enum.Material.Neon)
    end
    for _, dx in { -4.8, 0, 4.8 } do
        block("DisplayHousing" .. suffix, x + dx, 5.1, -38.0, 3.5, 2.5, 0.35, C.darkSteel, Enum.Material.Metal)
        block("Display" .. suffix, x + dx, 5.1, -37.79, 3.1, 2.05, 0.035, C.screen, Enum.Material.Glass)
    end
    -- Hardwood slat panels on control-room north wall.
    for i = 0, 4 do
        acousticPanel(x - 12 + i * 6, 6.5, -39.35, 0, 4.4, 6, i)
    end
    sign("ConsoleRackLabel" .. suffix, suffix .. " / CONTROL", Vector3.new(x, 9.5, -10.62), 180, 9, 1.3, C.darkSteel)
end

local function liveRoom()
    -- Acoustic baffles on rear wall and side walls; no free-standing new collision.
    for i = 0, 8 do
        acousticPanel(-33 + i * 8.2, 7.4, -129.36, 0, 5.8, 9, i)
    end
    for i = 0, 4 do
        acousticPanel(39.3, 6.8, -122 + i * 11, -90, 6, 8, i)
    end
    -- A convincing drum-kit silhouette around the already collidable drum riser.
    cylinder("KickRim", Vector3.new(-22, 3.2, -116), 2.7, 3.2, C.darkSteel)
    for _, offset in { Vector3.new(-3, 0, -2), Vector3.new(3, 0, -2) } do
        cylinder("DrumStand", Vector3.new(-22, 2, -116) + offset, 2.2, 0.14, C.steel, true)
        cylinder("DrumTop", Vector3.new(-22, 3.2, -116) + offset, 0.28, 2.8, C.brass, true)
    end
    for _, pos in { Vector3.new(-13, 2.7, -108), Vector3.new(12, 2.7, -112), Vector3.new(5, 2.7, -84) } do
        cylinder("MicrophoneStand", pos, 5.1, 0.14, C.steel, true)
        cylinder("MicBoom", pos + Vector3.new(0.5, 2.3, 0), 1.3, 0.1, C.steel)
        block("MicCapsule", pos.X + 1.1, pos.Y + 2.3, pos.Z, 0.35, 0.3, 0.45, C.darkSteel, Enum.Material.Metal)
        cylinder("StandFoot", Vector3.new(pos.X, 0.13, pos.Z), 2.2, 0.13, C.darkSteel)
    end
    -- Tiny overhead rig: visual only, never occludes monster hearing.
    for z = -119, -84, 17.5 do
        block("CeilingRail", 0, 19.25, z, 67, 0.15, 0.2, C.steel, Enum.Material.Metal)
        for _, x in { -25, 0, 25 } do
            block("RigSpot", x, 18.9, z, 1.5, 0.65, 1.2, C.darkSteel, Enum.Material.Metal)
        end
    end
    sign("LiveRoomSign", "LIVE FLOOR  /  QUIET ON SET", Vector3.new(0, 14, -70.6), 180, 20, 1.4, C.darkSteel)
end

local function booths()
    for index, z in { -120, -100, -80 } do
        -- Padded surfaces and a few real acoustic details inside each enclosed booth.
        for _, offset in { -6, 0, 6 } do
            acousticPanel(-54.36, 5.5, z + offset, 90, 4.6, 7.8, index + offset)
        end
        for _, offset in { -4.5, 0, 4.5 } do
            acousticPanel(-48, 6.2, z - 9.38, 0, 3.6, 6, index + offset)
            acousticPanel(-48, 6.2, z + 9.38, 180, 3.6, 6, index + offset)
        end
        block("BoothCarpet", -48.5, 0.045, z, 11, 0.07, 16, Color3.fromRGB(31, 33, 35), Enum.Material.Fabric)
        cylinder("BoothMicStand", Vector3.new(-51, 2.6, z), 4.8, 0.13, C.steel, true)
        block("BoothMicrophone", -51, 5.2, z, 0.42, 0.55, 0.42, C.darkSteel, Enum.Material.Metal)
        sign("BoothNumber", "ISO " .. string.format("%02d", index),
            Vector3.new(-39.33, 8.8, z + 3.4), 90, 3.2, 1.1, C.darkSteel, C.paper)
        -- Door and its "sealed" state remain managed by DoorService and NoiseService.
    end
end

local function corridors()
    trimZ(-4.4, -59, -3, 0)
    trimZ(4.4, -59, -3, 0)
    trimX(-59, 59, -69.42, 0)
    for _, z in { -6, -16, -39, -52 } do
        block("CorridorCableTray", -3.8, 10.6, z, 0.4, 0.5, 4, C.steel, Enum.Material.Metal)
        block("CorridorCableTray", 3.8, 10.6, z, 0.4, 0.5, 4, C.steel, Enum.Material.Metal)
    end
    sign("WestDirection", "A  /  CONTROL", Vector3.new(-4.35, 8, -16), 90, 4, 1.2, C.darkSteel)
    sign("EastDirection", "B  /  CONTROL", Vector3.new(4.35, 8, -16), -90, 4, 1.2, C.darkSteel)
    sign("BasementDirection", "GENERATOR  /  LOWER LEVEL", Vector3.new(-50, 9.7, -60.62), 180, 9, 1.1, C.darkSteel, C.amber)
    sign("BreakDirection", "STAFF ONLY", Vector3.new(47.5, 9.7, -60.62), 180, 7.5, 1.1, C.darkSteel)
    for _, x in { -34, -15, 15, 34 } do
        block("CrossPassageDado", x, 3.3, -69.38, 9, 0.15, 0.15, C.brass, Enum.Material.Metal)
    end
end

local function archive()
    sign("ArchiveInventory", "ARCHIVE / DO NOT DISCARD\nREELS  1978–2004", Vector3.new(69.35, 8, -108), -90, 9, 2.4, C.timberEdge)
    -- Tape spines on the faces of the existing Shelf collision shapes.
    for shelfIndex, z in { -122, -112, -92, -82 } do
        local xCenter = if shelfIndex % 2 == 1 then 51 else 59
        for i = 1, 14 do
            local x = xCenter - 9 + i * 1.2
            for _, y in { 3.1, 6.4 } do
                block("ReelCase", x, y, z + 1.08, 0.82, 2.15, 0.14,
                    if i % 5 == 0 then C.timber else C.darkSteel)
                block("TapeSpine", x, y - 0.32, z + 1.17, 0.61, 0.35, 0.04,
                    if i % 4 == 0 then C.amber else C.paper)
            end
        end
    end
    block("ArchiveWallStrip", 69.35, 3.8, -98, 0.15, 0.12, 40, C.brass)
end

local function breakRoom()
    -- Keep the center clear: the existing table and fridge are the solid collision shapes.
    block("TableSurface", 50, 3.06, -47, 6.4, 0.18, 4.3, C.timber, Enum.Material.Wood)
    block("Cup", 48.4, 3.25, -47, 0.52, 0.37, 0.52, C.paper, Enum.Material.SmoothPlastic)
    block("CoffeeStain", 49.2, 3.16, -45.8, 0.7, 0.025, 0.7, Color3.fromRGB(67, 48, 34))
    block("FridgeHandle", 55.35, 4.8, -36.5, 0.16, 2.2, 0.17, C.darkSteel, Enum.Material.Metal)
    sign("StaffNotice", "STAFF ROOM\nKEEP ALL DOORS SHUT\nDO NOT USE THE INTERCOM", Vector3.new(59.39, 7, -48), -90, 7.5, 4.5, C.timberEdge)
    for _, x in { 40, 44, 48 } do
        block("BreakRoomWallCabinet", x, 9.2, -35.63, 3, 2, 1, C.timber, Enum.Material.Wood)
    end
end

local function basement(layout: MapBuilder.Layout)
    -- The huge generator collision block, fuse box and stair ramp remain unchanged.
    local g = layout.generator.Position
    for _, dx in { -2.1, 0, 2.1 } do
        cylinder("GeneratorPiston", g + Vector3.new(dx, 0.8, -2.12), 2.3, 0.7, C.steel, true)
        cylinder("GeneratorCap", g + Vector3.new(dx, 2.0, -2.12), 0.3, 1.1, C.brass, true)
    end
    block("GeneratorCaution", g.X, g.Y + 2.1, g.Z + 2.06, 4, 1.1, 0.05, C.amber)
    for _, x in { -56, -45, -32 } do
        cylinder("BasementPipe", Vector3.new(x, -3.1, -39.45), 13, 0.45, C.steel)
        block("PipeBracket", x, -2.8, -39.38, 1.3, 0.6, 0.55, C.darkSteel, Enum.Material.Metal)
    end
    -- Fuse-box fascia is on the original interaction part, not a replacement.
    local f = layout.fuseBox.Position
    block("FusePanelInset", f.X + 0.43, f.Y, f.Z, 0.04, 2.9, 2.45, C.darkSteel, Enum.Material.Metal)
    for _, z in { -2.7, -2, -1.3 } do
        block("FuseSlot", f.X + 0.48, f.Y + 0.5, z, 0.05, 0.35, 0.3, C.amber)
    end
    sign("BasementWarning", "ELECTRICAL / AUTHORIZED PERSONNEL\nISOLATE POWER BEFORE SERVICE",
        Vector3.new(-20.6, -5, -25), -90, 14, 2.2, C.darkSteel, C.amber)
    sign("GeneratorWarning", "STANDBY GENERATOR\nMANUAL START ONLY", Vector3.new(-45, -4, 9.4), 180, 10, 2, C.timberEdge)
end

local function objectives(layout: MapBuilder.Layout)
    local t = layout.tapeDeck.Position
    -- Decoration must not alter the tape deck's ProximityPrompt or its physics.
    block("TapeSpoolL", t.X - 0.6, t.Y + 0.65, t.Z, 0.7, 0.12, 0.7, C.brass, Enum.Material.Metal)
    block("TapeSpoolR", t.X + 0.6, t.Y + 0.65, t.Z, 0.7, 0.12, 0.7, C.brass, Enum.Material.Metal)
    block("TapeStatus", t.X, t.Y + 0.65, t.Z + 0.7, 0.9, 0.08, 0.15, C.red, Enum.Material.Neon)
    sign("TapeInstruction", "EMERGENCY MASTER\nPLAY TO RELEASE THE EXIT",
        Vector3.new(-10, 7.9, -39.38), 0, 8.8, 2.1, C.timberEdge, C.amber)
end

function ArtBuilder.build(layout: MapBuilder.Layout)
    if built then
        return
    end
    local studio = layout.map
    if not (studio:IsA("Model") or studio:IsA("Folder")) then
        warn("[Dead Air] ArtBuilder: loaded map must be a Model or Folder")
        return
    end
    built = true
    art = Instance.new("Folder")
    art.Name = "ArtPass01"
    art.Parent = studio

    colourStructure(studio)
    reception()
    studioConsole(-20, "A")
    studioConsole(20, "B")
    corridors()
    liveRoom()
    booths()
    archive()
    breakRoom()
    basement(layout)
    objectives(layout)

    -- Additional powered fixture accents use ObjectiveService's existing power lifecycle.
    for _, p in {
        Vector3.new(-20, 11.4, -25), Vector3.new(20, 11.4, -25),
        Vector3.new(-48, 11.4, -120), Vector3.new(-48, 11.4, -100),
        Vector3.new(-48, 11.4, -80), Vector3.new(-40, -2.0, -10),
        Vector3.new(0, 11.4, 7),
    } do
        tubeLight(layout, "PoweredStudioFixture", p.X, p.Y, p.Z)
    end

    local grade = Instance.new("ColorCorrectionEffect")
    grade.Name = "StudioEnvironmentGrade"
    grade.Brightness = -0.025
    grade.Contrast = 0.08
    grade.Saturation = -0.18
    grade.TintColor = Color3.fromRGB(225, 220, 210)
    grade.Parent = Lighting

    print(string.format("[Dead Air] recording-studio ArtPass01: %d decorative parts", partCount))
end

return ArtBuilder
