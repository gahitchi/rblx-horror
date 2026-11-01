--!strict
-- Optional PBR asset binding for Studio-authored MaterialVariants.
-- Artists import PNGs using Material Manager, then name the installed variants as below.
-- Without a matching variant the original Roblox material remains active.
-- MaterialVariant assets must be created/approved in Studio; fake content IDs are never used.
local MaterialService=game:GetService("MaterialService")
local PBRMaterials={}
local BY_MATERIAL: { [Enum.Material]: string } = {
    [Enum.Material.Concrete]="DA_Plaster_Concrete",
    [Enum.Material.Fabric]="DA_Acoustic_Fabric",
    [Enum.Material.Wood]="DA_Oak_Wood",
    [Enum.Material.WoodPlanks]="DA_Oak_WoodPlanks",
    [Enum.Material.Metal]="DA_Oxidized_Metal",
    [Enum.Material.DiamondPlate]="DA_Oxidized_DiamondPlate",
}
-- Environment-specific finishes are opt-in. They never replace creator-
-- approved GLB SurfaceAppearances, game collider doors, or all studio metal.
local BLACKLINE_BY_NAME: { [string]: string } = {
    MasteringVaultFloor = "DA_Blackline_SealedSlate",
    ViewingGalleryFloor = "DA_Blackline_SealedSlate",
    TapeArchiveFloor = "DA_Blackline_ArchiveConcrete",
}
local BLACKLINE_FINISH_TAGS: { [string]: string } = {
    PowderCoatedSteel = "DA_Blackline_PowderSteel",
}
local function approved(name: string, material: Enum.Material): boolean
    local variant=MaterialService:FindFirstChild(name)
    return variant~=nil and variant:IsA("MaterialVariant")
        and variant.BaseMaterial==material
end

function PBRMaterials.apply(map: Instance): number
    local installed: { [Enum.Material]: string }={}
    local seen: { [string]: boolean }={}
    for material,name in BY_MATERIAL do
        local variant=MaterialService:FindFirstChild(name)
        if variant and variant:IsA("MaterialVariant") and variant.BaseMaterial==material then
            installed[material]=name
            seen[name]=true
        end
    end
    local changed=0
    for _,part in map:GetDescendants() do
        if part:IsA("BasePart") and part:GetAttribute("DisablePBR")~=true
            and part:FindFirstChildOfClass("SurfaceAppearance")==nil then
            local chosen=installed[part.Material]
            if map:GetAttribute("MapId")=="studio" then
                local special=BLACKLINE_BY_NAME[part.Name]
                local family=part:GetAttribute("FinishFamily")
                if type(family)=="string" then
                    special=BLACKLINE_FINISH_TAGS[family] or special
                end
                if special and approved(special,part.Material) then
                    chosen=special
                end
            end
            -- Sub-stud bolts, wires and narrow trim are poor receivers for a
            -- tiled 1024px PBR atlas: distance filtering creates noisy glints.
            -- Only the two largest physical dimensions must form a readable face.
            local size=part.Size
            local median=math.max(math.min(size.X,size.Y),
                math.min(size.X,size.Z),math.min(size.Y,size.Z))
            if chosen and median>=0.6 and part.MaterialVariant~=chosen then
                part.MaterialVariant=chosen
                changed+=1
            end
        end
    end
    if changed>0 then
        print(string.format("[Dead Air] PBR: assigned %d parts from %d approved MaterialVariants",
            changed, (function()
                local total=0
                for _ in seen do
                    total+=1
                end
                return total
            end)()))
    else
        print("[Dead Air] PBR: no approved MaterialVariants installed; using built-in materials")
    end
    return changed
end
return PBRMaterials
