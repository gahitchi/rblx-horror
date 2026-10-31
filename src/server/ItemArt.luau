--!strict
-- Item appearance only. Claude's gameplay scripts own the walkie channel, tape recording,
-- playback, battery and prompts. Returned Parts and their geometry are the stable API.

local ItemArt = {}

local CHASSIS = Color3.fromRGB(36, 42, 42)
local RUBBER = Color3.fromRGB(22, 26, 26)
local STEEL = Color3.fromRGB(99, 105, 100)
local LABEL = Color3.fromRGB(171, 165, 139)
local AMBER = Color3.fromRGB(207, 134, 59)
local GLASS = Color3.fromRGB(33, 70, 65)

local function part(
    name: string, size: Vector3, color: Color3, material: Enum.Material, parent: Instance?
): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material
    p.Anchored = false
    p.Massless = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function accent(
    root: Part, name: string, size: Vector3, offset: Vector3,
    color: Color3, material: Enum.Material?, rotation: CFrame?, shape: Enum.PartType?
): Part
    local p = part(name, size, color, material or Enum.Material.SmoothPlastic, root)
    p.CFrame = root.CFrame * CFrame.new(offset) * (rotation or CFrame.identity)
    if shape then
        p.Shape = shape
    end
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = p
    weld.Parent = p
    return p
end

-- Wearable pocket walkie: return the root, one non-solid Massless Part for belt welding.
function ItemArt.makeWalkie(): Part
    local body = part("Walkie", Vector3.new(0.38, 0.75, 0.21), CHASSIS, Enum.Material.Metal)
    -- Antenna housing extends above the chassis but remains in the same rigid assembly.
    accent(body, "RubberAntenna", Vector3.new(0.067, 0.49, 0.067),
        Vector3.new(0.13, 0.59, 0), RUBBER)
    accent(body, "AntennaBoot", Vector3.new(0.16, 0.16, 0.16),
        Vector3.new(0.13, 0.39, 0), STEEL, Enum.Material.Metal)
    accent(body, "FrontBezel", Vector3.new(0.32, 0.52, 0.035),
        Vector3.new(0, 0.08, -0.12), RUBBER)
    accent(body, "TinyRadioScreen", Vector3.new(0.23, 0.13, 0.025),
        Vector3.new(0, 0.23, -0.145), GLASS, Enum.Material.Glass)
    for i = 1, 5 do
        accent(body, "SpeakerSlot", Vector3.new(0.24, 0.018, 0.028),
            Vector3.new(0, 0.085 - (i - 1) * 0.045, -0.151), STEEL, Enum.Material.Metal)
    end
    accent(body, "PushToTalk", Vector3.new(0.055, 0.21, 0.11),
        Vector3.new(-0.213, 0.08, -0.018), AMBER, Enum.Material.SmoothPlastic)
    accent(body, "VolumeDial", Vector3.new(0.10, 0.07, 0.1),
        Vector3.new(-0.11, 0.405, 0), RUBBER)
    accent(body, "ChannelSelector", Vector3.new(0.08, 0.09, 0.09),
        Vector3.new(-0.035, 0.405, 0), STEEL, Enum.Material.Metal)
    for i = 0, 3 do
        accent(body, "GripRib", Vector3.new(0.315, 0.025, 0.02),
            Vector3.new(0, -0.21 - i * 0.043, -0.112), RUBBER)
    end
    accent(body, "BeltClip", Vector3.new(0.13, 0.44, 0.08),
        Vector3.new(0, -0.03, 0.15), STEEL, Enum.Material.Metal)
    return body
end

-- Portable cassette deck: root MUST be anchored and the root's position is its geometric
-- centre, matching Roblox Part placement. Caller adds the pickup prompt and light to the root.
function ItemArt.makeTapeRecorder(): Part
    local body = part("TapeRecorder", Vector3.new(1.25, 0.48, 0.87),
        Color3.fromRGB(92, 86, 73), Enum.Material.Metal)
    body.Anchored = true
    accent(body, "Faceplate", Vector3.new(1.15, 0.09, 0.75),
        Vector3.new(0, 0.25, 0), CHASSIS, Enum.Material.Metal)
    accent(body, "CassetteWindow", Vector3.new(0.63, 0.023, 0.43),
        Vector3.new(-0.1, 0.305, 0.02), GLASS, Enum.Material.Glass)
    local turn = CFrame.Angles(0, 0, math.rad(90))
    for _, x in { -0.28, 0.11 } do
        accent(body, "TapeReel", Vector3.new(0.034, 0.28, 0.28),
            Vector3.new(x, 0.33, 0.02), LABEL, Enum.Material.Metal, turn, Enum.PartType.Cylinder)
        accent(body, "TapeReelHub", Vector3.new(0.044, 0.07, 0.07),
            Vector3.new(x, 0.356, 0.02), RUBBER, Enum.Material.Metal, turn, Enum.PartType.Cylinder)
    end
    for i = 0, 7 do
        accent(body, "SpeakerGrille", Vector3.new(0.25, 0.017, 0.017),
            Vector3.new(0.38, 0.302, -0.3 + i * 0.08), RUBBER, Enum.Material.Metal)
    end
    for i = 0, 3 do
        accent(body, "TransportKey", Vector3.new(0.13, 0.08, 0.12),
            Vector3.new(-0.42 + i * 0.27, 0.315, 0.36),
            if i == 2 then AMBER else STEEL, Enum.Material.Metal)
    end
    accent(body, "RecordLampLens", Vector3.new(0.075, 0.04, 0.075),
        Vector3.new(0.52, 0.313, 0.28), Color3.fromRGB(125, 35, 31), Enum.Material.Glass)
    accent(body, "MicrophoneGrille", Vector3.new(0.27, 0.015, 0.27),
        Vector3.new(0.38, 0.308, -0.28), RUBBER, Enum.Material.Metal)
    for _, side in { -1, 1 } do
        accent(body, "CarryHandleStem", Vector3.new(0.085, 0.22, 0.085),
            Vector3.new(side * 0.48, 0.29, -0.36), STEEL, Enum.Material.Metal)
    end
    accent(body, "CarryHandle", Vector3.new(1.05, 0.075, 0.1),
        Vector3.new(0, 0.43, -0.36), RUBBER)
    return body
end

return ItemArt
