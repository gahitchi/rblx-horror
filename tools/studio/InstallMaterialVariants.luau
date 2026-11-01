-- Studio Command Bar material installer: paste after uploading the PNG maps in Asset Manager.
-- Insert *real image asset IDs from your own creator account* below.
-- All 4 maps are required per material, otherwise that variant is left unchanged.
-- Do not publish or run this script as a normal ServerScript.
local MaterialService = game:GetService("MaterialService")

-- EXAMPLE FORMAT (replace 0 with approved Roblox image asset IDs):
-- aged_oak = { color=123456789, normal=123456790, roughness=123456791, metalness=123456792 }
local MAPS = {
    aged_oak = { color=97244363878569, normal=85421494786995, roughness=77700775674119, metalness=90726372414976 },
    old_plaster = { color=72728932791485, normal=132441366278455, roughness=75547635259800, metalness=76884033826561 },
    oxidized_steel = { color=76293301928216, normal=86957883179573, roughness=103166159706547, metalness=118241271486095 },
    acoustic_weave = { color=126189349954361, normal=100592484093211, roughness=133073112123944, metalness=98288851413784 },
}
local VARIANTS = {
    { name="DA_Plaster_Concrete", base=Enum.Material.Concrete, family="old_plaster", tile=9 },
    { name="DA_Acoustic_Fabric", base=Enum.Material.Fabric, family="acoustic_weave", tile=6 },
    { name="DA_Oak_Wood", base=Enum.Material.Wood, family="aged_oak", tile=11 },
    { name="DA_Oak_WoodPlanks", base=Enum.Material.WoodPlanks, family="aged_oak", tile=11 },
    { name="DA_Oxidized_Metal", base=Enum.Material.Metal, family="oxidized_steel", tile=8 },
    { name="DA_Oxidized_DiamondPlate", base=Enum.Material.DiamondPlate, family="oxidized_steel", tile=8 },
}
local function uri(id)
    return "rbxassetid://" .. tostring(id)
end
local function valid(family)
    local imageSet=MAPS[family]
    if not imageSet then
        return false
    end
    for _,key in {"color","normal","roughness","metalness"} do
        local id=imageSet[key]
        if type(id)~="number" or id<=0 or math.floor(id)~=id then
            return false
        end
    end
    return true
end
local installed=0
for _,def in VARIANTS do
    if not valid(def.family) then
        warn("[Dead Air] Skipping " .. def.name .. ": supply all four approved image IDs")
        continue
    end
    local existing=MaterialService:FindFirstChild(def.name)
    if existing and not existing:IsA("MaterialVariant") then
        warn("[Dead Air] " .. def.name .. " is not a MaterialVariant; skipped")
        continue
    end
    local variant=existing
    if not variant then
        variant=Instance.new("MaterialVariant")
        variant.Name=def.name
        variant.Parent=MaterialService
    end
    variant.BaseMaterial=def.base
    variant.StudsPerTile=def.tile
    local ids=MAPS[def.family]
    variant.ColorMap=uri(ids.color)
    variant.NormalMap=uri(ids.normal)
    variant.RoughnessMap=uri(ids.roughness)
    variant.MetalnessMap=uri(ids.metalness)
    installed+=1
    print("[Dead Air] Installed/updated " .. def.name .. " (" .. def.family .. ")")
end
print(("[Dead Air] MaterialVariants ready: %d of %d"):format(installed,#VARIANTS))
-- This changes the Studio place. Save it after checking appearance in Play mode.
