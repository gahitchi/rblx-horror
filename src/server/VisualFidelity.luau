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
    -- The studio's art is laid out at the coordinates of the contract greybox.
    if map:GetAttribute("MapName") ~= "Recording studio (greybox)"
        and map:GetAttribute("StudioArtPass") ~= true then
        return
    end

    -- Realistic = Roblox's highest-fidelity lighting style, not real-time path tracing.
    Lighting.LightingStyle = Enum.LightingStyle.Realistic
    Lighting.PrioritizeLightingQuality = true
    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.26

    -- Dark environment, without aggressively crushing the midtones: the player must read
    -- practical-light pools and equipment surfaces. Keep the flashlight meaningful.
    Lighting.Brightness = 0
    Lighting.ClockTime = 0
    Lighting.Ambient = Color3.fromRGB(2, 3, 4)
    Lighting.OutdoorAmbient = Color3.fromRGB(8, 9, 11)
    Lighting.EnvironmentDiffuseScale = 0.08
    Lighting.EnvironmentSpecularScale = 0.85
    Lighting.ExposureCompensation = -0.06
    Lighting.FogColor = Color3.fromRGB(4, 5, 6)
    Lighting.FogStart = 35
    Lighting.FogEnd = 220

    local grade = ownedEffect("ColorCorrectionEffect", "StudioPhotometricGrade") :: ColorCorrectionEffect
    grade.Enabled = true
    grade.Brightness = 0.005
    grade.Contrast = 0.06
    grade.Saturation = -0.10
    grade.TintColor = Color3.fromRGB(245, 242, 235)

    -- Small halos around genuine emissive fixtures; no exaggerated "horror glow."
    local bloom = ownedEffect("BloomEffect", "StudioLensBloom") :: BloomEffect
    bloom.Enabled = true
    bloom.Intensity = 0.09
    bloom.Size = 16
    bloom.Threshold = 1.55

    -- Deliberately omit always-on depth of field, chromatic aberration, motion blur and
    -- screen noise. First-person focus should remain readable during monster chases.
end

return VisualFidelity
