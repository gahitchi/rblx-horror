--!strict
-- VF03: a coherent mastering-to-observation sequence. The reference wall has
-- one art-only optional GLB and a closely matched native fallback; the viewing
-- gallery treatment is built around Kit's REAL acoustic window.
-- No objective, audio, lighting, navmesh, or interactive state lives here.
local PrefabLibrary = require(script.Parent.Parent.PrefabLibrary)
local MasteringGallery = {}

type Room = {
    name: string, role: string, x1: number, x2: number, z1: number,
    z2: number, height: number, center: Vector3,
}

local INK = Color3.fromRGB(29,32,34)
local SHELL = Color3.fromRGB(65,70,71)
local EDGE = Color3.fromRGB(110,107,97)
local LINER = Color3.fromRGB(46,49,49)
local FELT = Color3.fromRGB(54,56,54)
local LABEL = Color3.fromRGB(194,184,157)
local AMBER = Color3.fromRGB(140,102,65)

local function piece(parent: Instance, name: string, cf: CFrame, size: Vector3,
    color: Color3, material: Enum.Material?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Material = material or Enum.Material.SmoothPlastic
    p.Color = color
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p:SetAttribute("DisablePBR", true)
    p:SetAttribute("ArtPass", "BlacklineVF03")
    p.Parent = parent
    return p
end

local function legend(parent: Instance, name: string, cf: CFrame, size: Vector3,
    title: string, tint: Color3?): Part
    local plate = piece(parent, name, cf, size, INK)
    plate:SetAttribute("StoryText", title)
    local gui = Instance.new("SurfaceGui")
    gui.Name = "EngravedLegend"
    gui.Face = Enum.NormalId.Front
    gui.PixelsPerStud = 70
    gui.LightInfluence = 0.40
    gui.Parent = plate
    local label = Instance.new("TextLabel")
    label.Name = "Caption"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(.94, .84)
    label.Position = UDim2.fromScale(.03, .08)
    label.Font = Enum.Font.RobotoMono
    label.TextColor3 = tint or LABEL
    label.TextScaled = true
    label.TextWrapped = false
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Text = title
    label.Parent = gui
    return plate
end

local function nativeReference(parent: Instance, base: CFrame)
    -- Purpose-built, wall-mounted nearfield array: 2 drivers, a dark central
    -- comparison bridge, service vents and stamped fasteners. No fake glow.
    piece(parent, "ReferenceHousing", base * CFrame.new(0, 6.40, 0),
        Vector3.new(13.3, 6.1, 1.30), SHELL, Enum.Material.Metal)
    piece(parent, "AbsorptiveFace", base * CFrame.new(0, 6.40, -.68),
        Vector3.new(12.80, 5.53, .10), FELT, Enum.Material.Fabric)
    for _, x in {-3.95, 3.95} do
        piece(parent, "DriverBaffle", base * CFrame.new(x, 6.55, -.75),
            Vector3.new(4.22, 4.44, .12), LINER)
        local axis = base * CFrame.new(x, 6.42, -.88) *
            CFrame.Angles(0, math.pi/2, 0)
        local outer = piece(parent, "LowFrequencyRollSurround", axis,
            Vector3.new(.15, 3.50, 3.50), INK, Enum.Material.SmoothPlastic)
        outer.Shape = Enum.PartType.Cylinder
        local cone = piece(parent, "ReferenceDriver", base *
            CFrame.new(x, 6.42, -1.00) * CFrame.Angles(0, math.pi/2, 0),
            Vector3.new(.13, 2.70, 2.70), SHELL, Enum.Material.Metal)
        cone.Shape = Enum.PartType.Cylinder
        local hub = piece(parent, "DustCap", base *
            CFrame.new(x, 6.42, -1.09) * CFrame.Angles(0, math.pi/2, 0),
            Vector3.new(.13, .85, .85), INK)
        hub.Shape = Enum.PartType.Cylinder
        for _, y in {4.53, 8.47} do
            piece(parent, "CabinetBracket", base * CFrame.new(x, y, -.79),
                Vector3.new(4.12, .13, .10), EDGE, Enum.Material.Metal)
        end
    end
    piece(parent, "CalibrationBridge", base * CFrame.new(0, 6.37, -.81),
        Vector3.new(2.78, 3.10, .11), INK)
    for i = 0, 4 do
        -- Realistic, unpowered scale ticks, not a live signal meter.
        piece(parent, "ReferenceScaleTick", base *
            CFrame.new(-1.01 + i * .50, 7.10, -.91),
            Vector3.new(.045, .46, .035), if i == 2 then AMBER else EDGE)
    end
    legend(parent, "ReferenceHeader", base * CFrame.new(0, 9.02, -.76),
        Vector3.new(8.4, .42, .035), "MASTERING  /  A-B REFERENCE")
    legend(parent, "ReferenceIncident", base * CFrame.new(0, 5.44, -.91),
        Vector3.new(2.48, .48, .035), "08 / RETURN UNVERIFIED", AMBER)
    for _, x in {-6.32, 6.32} do
        piece(parent, "EnclosureStile", base * CFrame.new(x, 6.40, -.75),
            Vector3.new(.14, 5.76, .12), EDGE, Enum.Material.Metal)
    end
end

local function nativeTransfer(parent: Instance, base: CFrame)
    -- The imported transfer machine points toward local -Z. The base is
    -- deliberately rotated toward the gallery / player approach. This fallback
    -- keeps a single believable deck in the same location when GLBs are absent.
    -- Its rear housing and two independent reel spindles share one floor pivot.
    piece(parent, "TransferPedestal", base * CFrame.new(0, 1.22, .12),
        Vector3.new(4.65, 2.43, 1.90), SHELL, Enum.Material.Metal)
    piece(parent, "TransportFace", base * CFrame.new(0, 2.76, -.96),
        Vector3.new(4.80, 1.65, .16), INK)
    piece(parent, "TransferTopCap", base * CFrame.new(0, 3.63, -.36),
        Vector3.new(4.93, .17, 2.18), EDGE, Enum.Material.Metal)
    piece(parent, "TransferToe", base * CFrame.new(0, .19, -1.00),
        Vector3.new(4.62, .19, .21), LINER, Enum.Material.Metal)
    for _, x in {-1.27, 1.27} do
        -- Cylinder's long axis is X in Roblox, turned so the spindle faces -Z.
        local axis=base*CFrame.new(x,2.82,-1.12)*CFrame.Angles(0,math.pi/2,0)
        local flange=piece(parent, "TransportFlange", axis,
            Vector3.new(.14, 1.57, 1.57), EDGE, Enum.Material.Metal)
        flange.Shape=Enum.PartType.Cylinder
        local platter=piece(parent, "MagneticReel", base*CFrame.new(x,2.82,-1.23)*
            CFrame.Angles(0,math.pi/2,0),
            Vector3.new(.12,1.27,1.27), INK, Enum.Material.Metal)
        platter.Shape=Enum.PartType.Cylinder
        for spoke=0,5 do
            piece(parent,"ReelSpoke",base*CFrame.new(x,2.82,-1.31)*
                CFrame.Angles(0,0,math.rad(spoke*30)),
                Vector3.new(1.08,.065,.05),EDGE,Enum.Material.Metal)
        end
        local spindle=piece(parent,"SpindleLock",
            base*CFrame.new(x,2.82,-1.36)*CFrame.Angles(0,math.pi/2,0),
            Vector3.new(.11,.32,.32),LABEL,Enum.Material.Metal)
        spindle.Shape=Enum.PartType.Cylinder
    end
    -- Tape guide path and two analog, unpowered needles; no blinking LEDs.
    piece(parent, "TapeGuideChannel", base*CFrame.new(0,1.70,-1.11),
        Vector3.new(3.8,.15,.13),EDGE,Enum.Material.Metal)
    for _, x in {-.90,.90} do
        piece(parent, "AnalogVUBezel", base*CFrame.new(x,1.13,-1.09),
            Vector3.new(1.45,.70,.10),EDGE,Enum.Material.Metal)
        piece(parent, "AnalogVUDial", base*CFrame.new(x,1.13,-1.16),
            Vector3.new(1.24,.49,.05),LABEL)
        piece(parent, "AnalogVUNeedle", base*CFrame.new(x,1.12,-1.20)*
            CFrame.Angles(0,0,math.rad(12)),Vector3.new(.74,.035,.03),AMBER)
    end
    for _, x in {-1.65,-.95,-.25,.45,1.15,1.85} do
        piece(parent, "SelectorPot", base*CFrame.new(x,.48,-1.05),
            Vector3.new(.26,.22,.15),LINER,Enum.Material.Metal)
    end
    legend(parent,"TransferNameplate",base*CFrame.new(0,.83,-1.14),
        Vector3.new(3.74,.25,.035),"BLACKLINE / M-08 TRANSFER")
end

local function transferStation(parent: Instance, room: Room)
    local model=Instance.new("Model")
    model.Name="MasteringTransferStation"
    model:SetAttribute("ArtPass","BlacklineVF04")
    model:SetAttribute("Narrative","Master tape routing and abandoned transfer")
    model.Parent=parent
    -- Former generic fallback faced a dead wall. Both render paths now share
    -- the same local pivot and face into the occupied south side of the room.
    local base=CFrame.new(room.x1+13,0,room.z1+12)*
        CFrame.Angles(0,math.pi,0)
    if PrefabLibrary.place(model,"BlacklineTransferDeck",base) then
        model:SetAttribute("VisualTier","ImportedPBR")
    else
        nativeTransfer(model,base)
        model:SetAttribute("VisualTier","NativeFallback")
    end
end

local function mastering(parent: Instance, room: Room)
    transferStation(parent,room)
    local model = Instance.new("Model")
    model.Name = "MasteringReferenceWall"
    model:SetAttribute("ArtPass", "BlacklineVF03")
    model:SetAttribute("Narrative", "Reference monitoring and unverified return of channel 08")
    model.Parent = parent

    -- The north-east wall is uninterrupted. The western log board, the
    -- existing transfer machine, and the east/ south/ west door sweeps are
    -- deliberately outside this 13.3-stud-wide fixture.
    local base = CFrame.new(room.x2 - 12.5, 0, room.z1 + 1.16) *
        CFrame.Angles(0, math.pi, 0)
    if PrefabLibrary.place(model, "BlacklineMasterReference", base) then
        model:SetAttribute("VisualTier", "ImportedPBR")
    else
        nativeReference(model, base)
        model:SetAttribute("VisualTier", "NativeFallback")
    end
end

local function gallery(parent: Instance, room: Room)
    local model = Instance.new("Model")
    model.Name = "ViewingGalleryObservation"
    model:SetAttribute("ArtPass", "BlacklineVF03")
    model:SetAttribute("Narrative", "Double-glazed observation and failed talkback return")
    model.Parent = parent
    -- The genuine Kit observation pane is 9 studs wide, centered 6.5 studs
    -- from the east end when an open portal shares the south wall. Never add
    -- replacement glass: Kit's pane alone owns sound attenuation/occlusion.
    local cx = room.x2 - 6.5
    local south = room.z2
    local inside = south - .84
    -- Threshold reveal sits below the existing aperture (glass starts y4.2).
    piece(model, "ObservationSillLip", CFrame.new(cx, 4.01, inside),
        Vector3.new(9.48, .15, .29), EDGE, Enum.Material.Metal)
    piece(model, "LowerSillRecess", CFrame.new(cx, 3.77, inside - .04),
        Vector3.new(9.20, .26, .12), INK)
    piece(model, "ObservationCrown", CFrame.new(cx, 10.84, inside),
        Vector3.new(9.43, .14, .24), SHELL, Enum.Material.Metal)
    for _, x in {cx - 4.67, cx + 4.67} do
        piece(model, "GlazingGasketReturn", CFrame.new(x, 7.48, inside),
            Vector3.new(.095, 6.63, .18), INK)
    end
    -- Talkback was removed during the incident. This is a static equipment
    -- plate on masonry LEFT of the real pane, not an interactive fake prompt.
    local callX = cx - 8.65
    piece(model, "TalkbackSocketCase", CFrame.new(callX, 6.55, south - .81),
        Vector3.new(4.0, 2.17, .18), SHELL, Enum.Material.Metal)
    piece(model, "TalkbackBlank", CFrame.new(callX, 6.46, south - .935),
        Vector3.new(3.55, 1.55, .065), INK)
    legend(model, "TalkbackNotice", CFrame.new(callX, 6.38, south - .991),
        Vector3.new(3.05, .78, .04), "TALKBACK / ISOLATED", AMBER)
    -- One real return-air plenum across the gallery, high above navigation.
    -- Articulated trim establishes the architectural axis toward the archive.
    local plenumY = room.height - 1.55
    local corridorZ = room.center.Z
    piece(model, "AcousticReturnPlenum",
        CFrame.new(room.center.X - 3, plenumY, corridorZ),
        Vector3.new(64, .49, 2.05), LINER, Enum.Material.Metal)
    for _, x in {room.x1 + 20, room.x1 + 45, room.x1 + 70} do
        piece(model, "PlenumSplicePlate", CFrame.new(x, plenumY - .275, corridorZ),
            Vector3.new(.17, .08, 2.22), EDGE, Enum.Material.Metal)
    end
    -- Visitors follow the north-side archive signs; the aperture serves a
    -- very different purpose and should not be buried under generic racks.
    model:SetAttribute("WindowCenterX", cx)
    model:SetAttribute("AcousticPaneOwnedBy", "Kit")
end

function MasteringGallery.decorate(parent: Instance, room: Room)
    if room.name == "MasteringVault" then
        mastering(parent, room)
    elseif room.name == "ViewingGallery" then
        gallery(parent, room)
    end
end

return MasteringGallery
