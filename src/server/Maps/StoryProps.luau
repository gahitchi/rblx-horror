--!strict
-- Environmental storytelling for Blackline's *specific* rooms. Each object belongs to
-- an architectural workflow, incident record, or human routine. No random scatter.
-- These are lightweight, non-queryable scenery: gameplay navigation, acoustic walls
-- and objective interaction remain under the main Map contract.
local PrefabLibrary=require(script.Parent.Parent.PrefabLibrary)
local StoryProps={}

type Palette={wall:Color3,floor:Color3,ceiling:Color3,trim:Color3,steel:Color3,accent:Color3}
type Room={name:string,role:string,x1:number,x2:number,z1:number,z2:number,height:number,center:Vector3}

local dark=Color3.fromRGB(35,38,40)
local steel=Color3.fromRGB(78,85,86)
local paper=Color3.fromRGB(179,169,144)
local amber=Color3.fromRGB(164,101,60)
local caution=Color3.fromRGB(166,124,68)
local mint=Color3.fromRGB(89,125,107)

local function slab(parent:Instance,name:string,cf:CFrame,size:Vector3,
    color:Color3,material:Enum.Material?):Part
    local p=Instance.new("Part")
    p.Name=name
    p.CFrame=cf
    p.Size=size
    p.Anchored=true
    p.CanCollide=false
    p.CanQuery=false
    p.CanTouch=false
    p.CastShadow=false
    p.Material=material or Enum.Material.SmoothPlastic
    p.Color=color
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p:SetAttribute("DisablePBR",true)
    p.Parent=parent
    return p
end

local function title(parent:Instance,name:string,txt:string,cf:CFrame,
    width:number,height:number,face:Enum.NormalId?,color:Color3?)
    local backing=slab(parent,name,cf,Vector3.new(width,height,0.12),dark)
    local gui=Instance.new("SurfaceGui")
    gui.Name="AuthoredSign"
    gui.Face=face or Enum.NormalId.Back
    gui.PixelsPerStud=45
    gui.LightInfluence=0.35
    gui.Parent=backing
    local caption=Instance.new("TextLabel")
    caption.Name="Legend"
    caption.Size=UDim2.fromScale(0.93,0.88)
    caption.Position=UDim2.fromScale(0.035,0.06)
    caption.BackgroundTransparency=1
    caption.Font=Enum.Font.RobotoMono
    caption.Text=txt
    caption.TextColor3=color or paper
    caption.TextScaled=true
    caption.TextWrapped=true
    caption.TextXAlignment=Enum.TextXAlignment.Left
    caption.Parent=gui
    backing:SetAttribute("StoryText",txt)
    return backing
end

local function trimWall(parent:Instance,name:string,x:number,y:number,z:number,
    width:number,height:number,color:Color3)
    slab(parent,name,CFrame.new(x,y,z),Vector3.new(width,height,0.22),color)
end

local function directory(parent:Instance,x:number,z:number)
    -- Exactly the kind of orientation board a real studio's staff needs.
    slab(parent,"DirectoryCase",CFrame.new(x,8.8,z),Vector3.new(14,8.7,0.34),steel)
    title(parent,"BlacklineDirectory",
        "BLACKLINE  /  RECEPTION\n\n01   RECORDING & CONTROL\n02   LIVE FLOOR / TRACKING\n03   TAPE ARCHIVE / MASTERING\n04   ENGINEERING / GENERATOR",
        CFrame.new(x,8.8,z+0.26),13,7.5,Enum.NormalId.Back,paper)
    slab(parent,"DirectoryAccentBar",CFrame.new(x,13.08,z+0.36),
        Vector3.new(13,0.14,0.06),amber)
    for i=1,3 do
        slab(parent,"ReceptionFloorGuide",CFrame.new(x-3+i*1.7,0.06,z+5.0),
            Vector3.new(0.23,0.04,6.7),Color3.fromRGB(99,91,81))
    end
end

local function workplace(parent:Instance,r:Room,brief:string,tag:string)
    -- Wall-facing document rail and clock-out notice, never inside a doorway.
    local x=r.x1+9
    local z=r.z1+0.92
    slab(parent,"ShiftBoardBacking",CFrame.new(x,7.3,z),
        Vector3.new(10.3,5.2,0.20),steel)
    title(parent,tag,brief,CFrame.new(x,7.3,z+0.15),
        9.3,4.4,Enum.NormalId.Back,paper)
    for i=0,3 do
        slab(parent,"FiledCardTab",CFrame.new(x-3.5+i*2.35,4.95,z+0.23),
            Vector3.new(1.1,0.15,0.06),if i==2 then amber else mint)
    end
end

local function serviceRack(parent:Instance,x:number,z:number,tag:string)
    -- Raised industrial control cabinet with actual recessed modules and hardware.
    -- Only the original room equipment remains a navigation obstacle.
    slab(parent,tag,CFrame.new(x,4.6,z),Vector3.new(5.0,8.5,1.55),steel)
    slab(parent,"ServiceCabinetInset",CFrame.new(x,5.45,z+0.81),
        Vector3.new(4.5,5.8,0.10),dark)
    for i=0,5 do
        slab(parent,"InstrumentCartridge",CFrame.new(x,3.25+i*0.78,z+0.90),
            Vector3.new(3.84,0.56,0.12),Color3.fromRGB(61,65,65))
        for j=0,3 do
            slab(parent,"LiveRackButton",CFrame.new(x-1.38+j*0.9,
                3.25+i*0.78,z+0.98),Vector3.new(0.15,0.12,0.06),
                if i==3 and j==0 then amber else mint)
        end
    end
    slab(parent,"RackNameplate",CFrame.new(x,8.26,z+0.9),
        Vector3.new(3.7,0.17,0.13),caution)
end

local function liveHall(parent:Instance,r:Room,p:Palette)
    local cx=r.center.X
    local cz=r.center.Z
    -- Monumental volume is built from *functional* acoustic/lighting construction.
    -- The layout stays open through its center for both the Engineer and the player.
    for i=0,4 do
        local x=cx-36+i*18
        slab(parent,"AcousticRoofBaffle",CFrame.new(x,r.height-3.0,cz),
            Vector3.new(1.3,4.2,42),if i%2==0 then p.trim else p.steel)
        slab(parent,"BaffleSuspension",CFrame.new(x,r.height-0.75,cz),
            Vector3.new(0.12,2.1,39),dark)
    end
    for _,z in {r.z1+8,r.z2-8} do
        slab(parent,"RecordingFloorCableTrench",CFrame.new(cx,0.045,z),
            Vector3.new(66,0.08,0.42),Color3.fromRGB(57,55,50))
    end
    for _,x in {r.x1+7,r.x2-7} do
        slab(parent,"BoundaryAcousticMass",CFrame.new(x,6.8,cz),
            Vector3.new(1.15,8.0,24),p.trim)
        for i=0,5 do
            slab(parent,"AcousticMassRelief",CFrame.new(x+0.61,6.8,cz-10+i*4),
                Vector3.new(0.06,6.8,1.3),p.accent)
        end
    end
    title(parent,"LiveFloorSafety","STUDIO A / LIVE ROOM\nALL CHANNELS OPEN ON SESSION ONLY",
        CFrame.new(cx,9.0,r.z1+1.2),17,2.0)
end

local function evidence(parent:Instance,r:Room)
    PrefabLibrary.place(parent,"TapeArchiveCart",
        CFrame.new(r.x2-12,0,r.z2-8))
    workplace(parent,r,
        "MASTER TRANSFER REGISTRY\n\n27 / 09 - TRACKS 01-07 RESTORED\n28 / 09 - 08 LOST AT 03:17\n29 / 09 - QUIET ZONE SEALED\n\nDO NOT PLAY THE MASTER REEL",
        "TransferLog")
    for i=0,5 do
        local x=r.x2-7-i*1.2
        slab(parent,"TapeCatalogDrawer",CFrame.new(x,2.7,r.z1+8),
            Vector3.new(0.92,2.4,2.5),if i==2 then dark else steel)
        slab(parent,"CatalogLabel",CFrame.new(x,3.23,r.z1+9.3),
            Vector3.new(0.67,0.24,0.05),if i==2 then amber else paper)
    end
end

local function reception(parent:Instance,r:Room,p:Palette)
    -- Keep the main StaffGallery/Reception threshold unobstructed.
    local x=r.x2-18
    local z=r.z1+2.4
    -- Oversized, near-monolithic institution frontage; recognizable from across
    -- the building, but identity and wayfinding are original to Blackline.
    trimWall(parent,"BlacklineMonolith",x,10,z,27,11.5,p.steel)
    title(parent,"BlacklineWordmark","BLACKLINE\nRECORDING COMPLEX",
        CFrame.new(x,10.4,z+0.21),25,7.1)
    directory(parent,r.x1+15,r.z1+1.8)
    if not PrefabLibrary.place(parent,"ReceptionTerminal",
        CFrame.new(r.x2-8,0,r.z2-8)*CFrame.Angles(0,math.pi,0)) then
        -- Small readable fallback while the additional GLB is awaiting import.
        slab(parent,"VisitorRegistryPedestal",CFrame.new(r.x2-8,1.8,r.z2-8),
            Vector3.new(2.8,3.6,1.8),dark)
        slab(parent,"VisitorRegistryScreen",CFrame.new(r.x2-8,2.6,r.z2-9),
            Vector3.new(2.2,0.9,0.1),mint)
    end
    slab(parent,"ReceptionSafetyLine",CFrame.new(r.center.X,0.055,r.z2-4.4),
        Vector3.new(38,0.06,0.22),caution)
    workplace(parent,r,
        "GUEST ACCESS  /  CHECK-IN\n\nAFTER-HOURS PROTOCOL\nNO ENTRY TO MASTERING\nASSISTANCE: CONTROL A\nIN EMERGENCY FOLLOW HALL MARKERS",
        "VisitorProtocol")
end

local function generatorRoom(parent:Instance,r:Room)
    workplace(parent,r,
        "GENERATING PLANT\n\nSTARTER SEQUENCE: 1 / 2 / 3\nDISCHARGE VENTS BEFORE RESTART\nELECTRICIAN SIGN-OFF REQUIRED",
        "GeneratorProcedure")
    for _,x in {r.x1+9,r.x2-8} do
        slab(parent,"GeneratorExhaustHousing",CFrame.new(x,11,r.center.Z),
            Vector3.new(4.0,9.3,3.8),steel)
        for i=0,4 do
            slab(parent,"ExhaustLouver",CFrame.new(x,8.0+i*1.25,r.center.Z+1.96),
                Vector3.new(3.7,0.15,0.18),dark)
        end
    end
end

-- The production facility should respond to the player's real generator state,
-- not simulate activity with an unrelated timer. MapContract collects Light
-- descendants from PowerLights and ObjectiveService toggles them on/off.
local function powerIndicator(lights:Instance,r:Room,message:string,tint:Color3)
    local lens=slab(lights,"PoweredStatus_"..r.name,
        CFrame.new(r.center.X,r.height-3.1,r.z1+1.45),
        Vector3.new(5.6,0.7,0.17),dark)
    lens:SetAttribute("OnColor",tint)
    local gui=Instance.new("SurfaceGui")
    gui.Name="StatusFace"
    gui.Face=Enum.NormalId.Back
    gui.PixelsPerStud=42
    gui.LightInfluence=0.1
    gui.Parent=lens
    local label=Instance.new("TextLabel")
    label.Size=UDim2.fromScale(1,1)
    label.BackgroundTransparency=1
    label.Font=Enum.Font.RobotoMono
    label.TextColor3=paper
    label.TextScaled=true
    label.Text=message
    label.Parent=gui
    local glow=Instance.new("SurfaceLight")
    glow.Face=Enum.NormalId.Back
    glow.Brightness=0.32
    glow.Range=9
    glow.Angle=110
    glow.Color=tint
    glow.Enabled=false
    glow.Shadows=false
    glow.Parent=lens
end

function StoryProps.decorate(parent:Instance, r:Room, palette:Palette, lights:Instance)
    if r.name=="ControlA" or r.name=="ControlB" or r.name=="LiveHall" then
        powerIndicator(lights,r,"SIGNAL  /  CONTROL",Color3.fromRGB(129,44,41))
    elseif r.name=="PatchBay" or r.name=="GeneratorRoom" then
        powerIndicator(lights,r,"FACILITY POWER",Color3.fromRGB(88,116,78))
    end
    if r.name=="Reception" then
        reception(parent,r,palette)
    elseif r.name=="LiveHall" then
        liveHall(parent,r,palette)
    elseif r.name=="TapeArchive" then
        evidence(parent,r)
    elseif r.name=="GeneratorRoom" then
        generatorRoom(parent,r)
    elseif r.name=="ControlA" then
        PrefabLibrary.place(parent,"StudioWallClock",
            CFrame.new(r.x1+13,r.height-4,r.z1+1.25)*CFrame.Angles(0,math.pi,0))
        workplace(parent,r,
            "A CONTROL  /  SESSION NOTES\n\nCHANNEL 08 REQUIRES ISOLATION\nTHE TAPE DECK IS CONNECTED TO P.A.\nENGINEERING SIGNATURE MISSING",
            "ControlALog")
        serviceRack(parent,r.x2-6,r.z1+8,"BackupPatchFrame")
    elseif r.name=="ControlB" then
        workplace(parent,r,
            "B CONTROL  /  MIX REVISION\n\nALL CHANNELS NORMAL EXCEPT 08\nCALL MAINTENANCE BEFORE ROUTING\nAUX BUS STILL RECEIVING AUDIO",
            "ControlBLog")
    elseif r.name=="Maintenance" then
        if not PrefabLibrary.place(parent,"ServiceIntercom",
            CFrame.new(r.x2-1.4,4.2,r.center.Z)*CFrame.Angles(0,math.pi/2,0)) then
            title(parent,"MaintenanceCallPoint","CALL ENGINEERING",
                CFrame.new(r.center.X,8,r.z1+1.1),13,1.1)
        end
        workplace(parent,r,
            "SHIFT HANDOVER   03:17\n\nGENERATOR - INCOMPLETE\nARCHIVE - DOOR SEAL REQUESTED\nSERVICE RADIO - NO RESPONSE",
            "MaintenanceHandover")
        serviceRack(parent,r.x2-7,r.z2-8,"ServiceCalibrationRack")
    elseif r.name=="PatchBay" then
        workplace(parent,r,
            "PATCH DISTRIBUTION\n\nFEED 01 - ACTIVE\nFEED 02 - BYPASS\nFEED 08 - DO NOT BRIDGE\nSTANDBY POWER: ISOLATED",
            "PatchBayDiagram")
        if not PrefabLibrary.place(parent,"BlacklinePatchMatrix",
            CFrame.new(r.x2-8,0,r.z1+9)) then
            serviceRack(parent,r.x2-8,r.z1+9,"PowerRoutingRack")
        end
    elseif r.name=="ViewingGallery" then
        title(parent,"GalleryDirection",
            "CONTROL ROOMS  <\nLIVE FLOOR      v\nMASTERING / ARCHIVE ^",
            CFrame.new(r.center.X,9.7,r.z1+0.95),17,2.6)
    elseif r.name=="StaffGallery" then
        title(parent,"GalleryWingDirectory",
            "PUBLIC / RECEPTION  v\nRECORDING     ^\nENGINEERING        >",
            CFrame.new(r.x1+22,10,r.z1+0.95),18,3)
    elseif r.name=="StaffPassage" then
        title(parent,"ServiceRouteWayfinding",
            "SILENT ACCESS / TECHNICAL STAFF\nSERVICE SPINE  >\nRECEPTION       v",
            CFrame.new(r.center.X,9.3,r.z1+1.1),19,2.8)
    elseif r.name=="ServiceGallery" then
        workplace(parent,r,
            "AUDIO PLANT  /  QUIET HOURS\n\nKEEP FIRE DOORS CLEAR\nARCHIVE VENTILATION 02 OFF\nSIGNAL LOSS REPORTED 03:17",
            "ServiceNotice")
    elseif r.name=="MasteringVault" then
        -- Full-size original reel-to-reel mastering transfer deck. Keep the
        -- existing authored route through the room unobstructed; the asset is
        -- cosmetic pending physical cover/navmesh review in Studio.
        if not PrefabLibrary.place(parent,"BlacklineTransferDeck",
            CFrame.new(r.x1+13,0,r.z1+12)) then
            serviceRack(parent,r.x1+13,r.z1+12,"ArchiveTransferFallback")
        end
        workplace(parent,r,
            "MASTERING SUITE\n\nMAGNETIC SOURCE CONTROL\nNO SECONDARY RECORDINGS\nVERIFY ISOLATION BEFORE ENTRY",
            "MasteringProtocol")
    elseif r.name=="LoadingDock" then
        workplace(parent,r,
            "DELIVERY MANIFEST\n\nMAGNETIC STOCK  -  RECEIVED\nREEL SHIPPING CASE - UNCLAIMED\nNO PICKUPS AUTHORIZED AFTER 03:00",
            "ShippingManifest")
        for i=0,4 do
            local x=r.x1+7+i*6.0
            slab(parent,"SealedMediaCrate",CFrame.new(x,1.4,r.z1+8.6),
                Vector3.new(4.2,2.8,4.4),Color3.fromRGB(77,69,57))
            slab(parent,"CrateSteelBand",CFrame.new(x,2.7,r.z1+8.6),
                Vector3.new(4.4,0.13,4.55),steel)
        end
    elseif r.name=="Lounge" then
        workplace(parent,r,
            "STAFF NOTICE\n\nNIGHT SHIFT ENDS AT 04:00\nDO NOT LEAVE RECORDERS RUNNING\nVISITORS MUST RETURN TO RECEPTION",
            "StaffNotice")
    elseif r.name=="DrumRoom" or r.name=="TrackingStage" then
        title(parent,"RecordingSilenceNotice",
            "SESSION IN PROGRESS\nDO NOT INTERRUPT",
            CFrame.new(r.x1+11,8,r.z1+0.85),14,2.3)
    elseif r.name=="IsolationWest" or r.name=="IsolationEast" then
        title(parent,"AcousticNotice",
            "ISOLATION CHAMBER\nAUDIO SEAL / KEEP SHUT",
            CFrame.new(r.center.X,8,r.z1+0.85),13,2.3)
    end
end

return StoryProps
