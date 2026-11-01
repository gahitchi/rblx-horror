--!strict
-- VF05-07: Blackline's small high-value surface / luminaire finishing kit.
-- Real surface finish is selected with approved, optional MaterialVariants;
-- no runtime image IDs, lights, sound emitters or objective state.
local SurfaceAndLight={}

type Room={name:string,role:string,x1:number,x2:number,z1:number,z2:number,
    height:number,center:Vector3}

local STEEL=Color3.fromRGB(73,77,76)
local TRIM=Color3.fromRGB(111,107,98)
local SHADOW=Color3.fromRGB(29,33,34)
local FELT=Color3.fromRGB(47,50,51)

local function part(parent:Instance,name:string,cf:CFrame,size:Vector3,
    color:Color3, material:Enum.Material,finish:string?):Part
    local p=Instance.new("Part")
    p.Name=name
    p.CFrame=cf
    p.Size=size
    p.Color=color
    p.Material=material
    p.Anchored=true
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.CastShadow=false
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p:SetAttribute("ArtPass","BlacklineVF05SurfaceAndLight")
    if finish then
        p:SetAttribute("FinishFamily",finish)
    else
        p:SetAttribute("DisablePBR",true)
    end
    p.Parent=parent
    return p
end

local function lightBaffle(parent:Instance,r:Room)
    -- The ONLY real lamp is the existing Kit FixtureLens in PowerLights.
    -- This source shield defines the fixture's silhouette; it emits no light.
    -- The bands flank the 0.95-stud central lens, they cannot black it out.
    local y=r.height-1.0
    for _,offset in {-0.87,0.87} do
        part(parent,"LuminaireCutoffWing",
            CFrame.new(r.center.X,y,r.center.Z+offset),
            Vector3.new(3.18,.35,.32),STEEL,Enum.Material.Metal,
            "PowderCoatedSteel")
        part(parent,"LuminaireShadowReveal",
            CFrame.new(r.center.X,y-.18,r.center.Z+offset*.98),
            Vector3.new(2.90,.055,.21),SHADOW,Enum.Material.SmoothPlastic)
    end
    for _,offset in {-1.62,1.62} do
        part(parent,"LuminaireEndCap",
            CFrame.new(r.center.X+offset,y,r.center.Z),
            Vector3.new(.12,.40,1.86),TRIM,Enum.Material.Metal,
            "PowderCoatedSteel")
    end
end

local function mastering(parent:Instance,r:Room)
    -- A true service wall datum BELOW the reference monitoring instrument.
    -- North wall is uninterrupted. Doorways remain x=-72,-24 and south z=-160.
    local cx=r.x2-12.5
    local wallZ=r.z1+1.08
    part(parent,"MasteringLowServiceRail",
        CFrame.new(cx,1.11,wallZ),
        Vector3.new(15.0,.23,.22),TRIM,Enum.Material.Metal,
        "PowderCoatedSteel")
    for _,x in {cx-4.05,cx+4.05} do
        part(parent,"MasteringAbsorberServicePanel",
            CFrame.new(x,2.15,wallZ-.12),
            Vector3.new(5.5,1.48,.12),FELT,Enum.Material.Fabric)
        part(parent,"ServicePanelLowerChannel",
            CFrame.new(x,1.37,wallZ-.16),
            Vector3.new(5.70,.11,.10),STEEL,Enum.Material.Metal,
            "PowderCoatedSteel")
    end
end

local function gallery(parent:Instance,r:Room)
    -- The north wall has two 8-stud portals. The 24-stud treatment lies
    -- strictly between them, at x=center -21; no panels across doors.
    local cx=r.center.X
    local north=r.z1+.94
    part(parent,"GalleryQuietWallBase",
        CFrame.new(cx,1.75,north),Vector3.new(24,2.90,.14),
        FELT,Enum.Material.Fabric)
    part(parent,"GalleryBaseChannel",
        CFrame.new(cx,.27,north-.13),Vector3.new(24.2,.16,.12),
        STEEL,Enum.Material.Metal,"PowderCoatedSteel")
    for _,x in {cx-11.93,cx+11.93} do
        part(parent,"GalleryPanelStile",
            CFrame.new(x,1.75,north-.13),Vector3.new(.12,3.00,.12),
            SHADOW,Enum.Material.SmoothPlastic)
    end
end

local function archive(parent:Instance,r:Room)
    -- Actual dry-store wall returns. Cabinet occupies x=center +/- 5.9;
    -- these isolated returns are more than five studs clear of its case.
    local z=r.z1+.96
    for _,x in {r.center.X-14.5,r.center.X+14.5} do
        part(parent,"ArchiveVentilationReturn",
            CFrame.new(x,5.25,z),Vector3.new(2.8,7.10,.17),
            STEEL,Enum.Material.Metal,"PowderCoatedSteel")
        part(parent,"ArchiveReturnInset",
            CFrame.new(x,5.25,z-.12),Vector3.new(2.14,5.80,.065),
            SHADOW,Enum.Material.SmoothPlastic)
        for _,y in {3.50,5.15,6.80} do
            part(parent,"ArchiveReturnSlot",
                CFrame.new(x,y,z-.17),Vector3.new(1.61,.09,.04),
                TRIM,Enum.Material.SmoothPlastic)
        end
    end
end

function SurfaceAndLight.decorate(parent:Instance,r:Room)
    if r.name~="MasteringVault" and r.name~="ViewingGallery"
        and r.name~="TapeArchive" then
        return
    end
    local scene=Instance.new("Model")
    scene.Name="BlacklineSurfaceAndLight_"..r.name
    scene:SetAttribute("ArtPass","BlacklineVF05SurfaceAndLight")
    scene:SetAttribute("PhysicalLightOwner","Kit.PowerLights")
    scene:SetAttribute("AllArtNonBlocking",true)
    scene.Parent=parent
    if r.name=="MasteringVault" then
        mastering(scene,r)
    elseif r.name=="ViewingGallery" then
        gallery(scene,r)
    elseif r.name=="TapeArchive" then
        archive(scene,r)
    end
    lightBaffle(scene,r)
end

return SurfaceAndLight
