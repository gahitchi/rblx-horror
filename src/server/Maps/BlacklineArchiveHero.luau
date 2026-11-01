--!strict
-- Blackline's archive hero vignette. An analog master-storage cabinet, not an
-- objective or a set of randomly placed futuristic props. The rear is recessed
-- against the north wall, away from the three actual archive doorways.
-- Imported GLB and native fallback share the same ground-level pivot.
local PrefabLibrary=require(script.Parent.Parent.PrefabLibrary)
local ArchiveHero={}

type Room={name:string,role:string,x1:number,x2:number,z1:number,z2:number,
    height:number,center:Vector3}

local IRON=Color3.fromRGB(71,76,76)
local TRIM=Color3.fromRGB(104,101,91)
local DARK=Color3.fromRGB(34,37,39)
local LINER=Color3.fromRGB(48,50,50)
local LABEL=Color3.fromRGB(187,177,151)
local MISSING=Color3.fromRGB(135,93,59)

local function piece(parent:Instance,name:string,cf:CFrame,size:Vector3,
    tint:Color3,material:Enum.Material?):Part
    local p=Instance.new("Part")
    p.Name=name
    p.CFrame=cf
    p.Size=size
    p.Color=tint
    p.Material=material or Enum.Material.SmoothPlastic
    p.Anchored=true
    p.CanCollide=false
    p.CanTouch=false
    p.CanQuery=false
    p.CastShadow=false
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p:SetAttribute("DisablePBR",true)
    p:SetAttribute("ArtPass","BlacklineArchiveHero02")
    p.Parent=parent
    return p
end

local function plate(parent:Instance,name:string,base:CFrame,
    x:number,y:number,z:number,width:number,height:number,legend:string)
    local p=piece(parent,name,base*CFrame.new(x,y,z),
        Vector3.new(width,height,.035),DARK)
    local surface=Instance.new("SurfaceGui")
    surface.Name="EngravedLegend"
    surface.Face=Enum.NormalId.Front
    surface.PixelsPerStud=70
    surface.LightInfluence=.35
    surface.Parent=p
    local text=Instance.new("TextLabel")
    text.Name="InventoryText"
    text.Size=UDim2.fromScale(.94,.84)
    text.Position=UDim2.fromScale(.03,.08)
    text.BackgroundTransparency=1
    text.Font=Enum.Font.RobotoMono
    text.TextColor3=LABEL
    text.TextScaled=true
    text.TextWrapped=false
    text.TextXAlignment=Enum.TextXAlignment.Center
    text.Text=legend
    text.Parent=surface
    p:SetAttribute("StoryText",legend)
end

local function reel(parent:Instance,base:CFrame,x:number,y:number,number:number)
    -- One shallow steel reel behind each intact compartment's retaining lip.
    -- Front -Z on the prefab becomes +Z into the archive after placement.
    local at=base*CFrame.new(x,y,-1.08)*CFrame.Angles(0,math.pi/2,0)
    local disk=piece(parent,"ArchivedMasterReel_"..tostring(number),at,
        Vector3.new(.12,1.32,1.32),IRON,Enum.Material.Metal)
    disk.Shape=Enum.PartType.Cylinder
    local hub=piece(parent,"ReelLockHub",base*CFrame.new(x,y,-1.175)*
        CFrame.Angles(0,math.pi/2,0),Vector3.new(.11,.32,.32),TRIM,Enum.Material.Metal)
    hub.Shape=Enum.PartType.Cylinder
    for spoke=0,3 do
        piece(parent,"ReelSpoke",base*CFrame.new(x,y,-1.165)*
            CFrame.Angles(0,0,math.rad(spoke*45)),
            Vector3.new(1.08,.08,.065),LINER,Enum.Material.Metal)
    end
end

local function nativeCabinet(parent:Instance,base:CFrame)
    -- Large shapes first. Small repeated features are limited to the eight
    -- actual reel positions and their protective machining details.
    piece(parent,"VaultShell",base*CFrame.new(0,4.25,0),
        Vector3.new(11.8,8.5,1.95),IRON,Enum.Material.Metal)
    piece(parent,"RearInset",base*CFrame.new(0,4.0,-1.002),
        Vector3.new(11.28,7.3,.06),DARK)
    for _,x in {-5.74,5.74} do
        piece(parent,"StampedUpright",base*CFrame.new(x,4.2,-1.06),
            Vector3.new(.19,8.35,.20),TRIM,Enum.Material.Metal)
        for _,y in {.36,7.54} do
            piece(parent,"FlushFastener",base*CFrame.new(x,y,-1.185),
                Vector3.new(.07,.07,.045),LABEL,Enum.Material.Metal)
        end
    end
    piece(parent,"HeaderRail",base*CFrame.new(0,7.54,-1.10),
        Vector3.new(11.46,.24,.13),TRIM,Enum.Material.Metal)
    plate(parent,"ArchiveIdentity",base,0,8.05,-1.17,9.6,.48,
        "BLACKLINE  /  MASTER STORAGE   M-08")
    for row=0,1 do
        for col=0,3 do
            local index=row*4+col+1
            local x=-4.20+col*2.80
            local y=5.51-row*3.15
            piece(parent,"TrayBack_"..index,base*CFrame.new(x,y,-1.02),
                Vector3.new(2.50,2.53,.10),DARK)
            piece(parent,"TrayLip_"..index,base*CFrame.new(x,y-1.10,-1.14),
                Vector3.new(2.50,.14,.13),TRIM,Enum.Material.Metal)
            for _,side in {-1,1} do
                piece(parent,"TrayGuide",base*CFrame.new(x+side*1.24,y,-1.11),
                    Vector3.new(.08,2.42,.12),LINER,Enum.Material.Metal)
            end
            if index~=8 then
                reel(parent,base,x,y,index)
            else
                -- Absence is the story clue; do not invent a pickup or prompt.
                piece(parent,"EmptyRetentionBracket",base*CFrame.new(x,y,-1.16),
                    Vector3.new(1.35,.12,.10),MISSING,Enum.Material.Metal)
                piece(parent,"EmptyRetentionTab",base*CFrame.new(x,y,-1.18),
                    Vector3.new(.12,1.13,.12),MISSING,Enum.Material.Metal)
            end
            plate(parent,"SlotSerial_"..index,base,x,y-1.26,-1.22,2.15,.30,
                if index==8 then "08  /  NOT RETURNED"
                else string.format("%02d  /  SEALED",index))
        end
    end
    piece(parent,"LowerKick",base*CFrame.new(0,.17,-1.08),
        Vector3.new(11.7,.27,.14),LINER,Enum.Material.Metal)
end

function ArchiveHero.decorate(parent:Instance,r:Room)
    if r.name~="TapeArchive" then return end
    local scene=Instance.new("Model")
    scene.Name="ArchiveMasterEvidence"
    scene:SetAttribute("ArtPass","BlacklineArchiveHero02")
    scene:SetAttribute("Narrative","Seven accounted-for masters, one empty slot")
    scene.Parent=parent
    -- The north wall has no portal; south/side entries and the existing
    -- TapeArchiveCart, shelf collider and patrol positions remain untouched.
    local base=CFrame.new(r.center.X,0,r.z1+1.16)*CFrame.Angles(0,math.pi,0)
    if PrefabLibrary.place(scene,"BlacklineArchiveCabinet",base) then
        scene:SetAttribute("VisualTier","ImportedPBR")
    else
        nativeCabinet(scene,base)
        scene:SetAttribute("VisualTier","NativeFallback")
    end
end

return ArchiveHero
