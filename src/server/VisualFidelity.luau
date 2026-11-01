--!strict
-- Studio-specific rendering grade. Roblox does not expose RTX/path tracing to experiences:
-- use LightingStyle.Realistic, curated local lights and restrained post-processing instead.
-- No unbounded per-frame raycasts, fake global illumination, or global depth-of-field blur.

local Lighting = game:GetService("Lighting")
local MapBuilder = require(script.Parent.MapBuilder)

local VisualFidelity = {}

local function ownedEffect(className: string, name: string): Instance
    local old = Lighting:FindFirstChild(name)
    if old then
        if old.ClassName == className then
            return old
        end
        old:Destroy()
    end
    local effect = Instance.new(className)
    effect.Name = name
    effect.Parent = Lighting
    return effect
end

function VisualFidelity.apply(layout: MapBuilder.Layout)
    local map = layout.map
    if map:GetAttribute("OwnsLighting") == true then
        return -- Never overwrite an authored map's own lighting treatment.
    end
    -- Each production map is complete and opts into the same restrained camera grade.
    if map:GetAttribute("ProductionGeometry") ~= true then
        return
    end

    -- LightingStyle and PrioritizeLightingQuality are Studio/place configuration.
    -- Roblox does not allow ordinary gameplay scripts to assign them. Both are
    -- already set in the Rojo place projects and should be checked in Studio
    -- after importing the match place.
    local blackline = map:GetAttribute("MapId") == "studio"
    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.26

    -- Dark environment, without aggressively crushing the midtones: the player must read
    -- practical-light pools and equipment surfaces. Keep the flashlight meaningful.
    Lighting.Brightness = 0
    Lighting.ClockTime = 0
    Lighting.Ambient = Color3.fromRGB(2, 3, 4)
    Lighting.OutdoorAmbient = Color3.fromRGB(8, 9, 11)
    Lighting.EnvironmentDiffuseScale = 0.08
    -- An institution with painted steel should not look like uniform wet rust.
    -- Existing maps retain their approved baseline until separate review.
    Lighting.EnvironmentSpecularScale = if blackline then 0.59 else 0.85
    Lighting.ExposureCompensation = -0.06
    Lighting.FogColor = Color3.fromRGB(4, 5, 6)
    Lighting.FogStart = if blackline then 48 else 35
    Lighting.FogEnd = if blackline then 250 else 220

    local grade = ownedEffect("ColorCorrectionEffect", "StudioPhotometricGrade") :: ColorCorrectionEffect
    grade.Enabled = true
    grade.Brightness = 0.005
    grade.Contrast = 0.06
    grade.Saturation = if blackline then -0.065 else -0.10
    grade.TintColor = Color3.fromRGB(245, 242, 235)

    -- Small halos around genuine emissive fixtures; no exaggerated "horror glow."
    local bloom = ownedEffect("BloomEffect", "StudioLensBloom") :: BloomEffect
    bloom.Enabled = true
    bloom.Intensity = if blackline then 0.065 else 0.09
    bloom.Size = 16
    bloom.Threshold = 1.55

    -- Deliberately omit always-on depth of field, chromatic aberration, motion blur and
    -- screen noise. First-person focus should remain readable during monster chases.
end

return VisualFidelity
