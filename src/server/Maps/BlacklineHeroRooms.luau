--!strict
-- Blackline first-person hero-space finish kit. Built around physical studio
-- workflow, not generic scatter: wiring, light fixtures, acoustic treatments,
-- service access and room-identifying details all have plausible owners.
-- All visual-only pieces are non-colliding and non-queryable. Real door openings
-- and game objective/collision proxies remain the sole gameplay architecture.
local Hero={}

type Room={name:string,role:string,x1:number,x2:number,z1:number,z2:number,
    height:number,center:Vector3}
type Palette={wall:Color3,floor:Color3,ceiling:Color3,trim:Color3,
    steel:Color3,accent:Color3}

local BLACK=Color3.fromRGB(28,31,33)
local OXIDE=Color3.fromRGB(69,74,73)
local METAL=Color3.fromRGB(102,105,99)
local LINER=Color3.fromRGB(49,52,51)
local BRASS=Color3.fromRGB(127,111,79)
local LENS=Color3.fromRGB(160,152,129)

local function part(parent:Instance,name:string,cf:CFrame,size:Vector3,
    color:Color3,material:Enum.Material?):Part
    local p=Instance.new("Part")
    p.Name=name
    p.CFrame=cf
    p.Size=size
    p.Color=color
    p.Material=material or Enum.Material.SmoothPlastic
    p.Anchored=true
    p.CanCollide=false
    p.CanQuery=false
    p.CanTouch=false
    p.CastShadow=false
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p:SetAttribute("DisablePBR",true)
    p:SetAttribute("ArtPass","BlacklineHero01")
    p.Parent=parent
    return p
end

local function tube(parent:Instance,name:string,start:Vector3,finish:Vector3,
    thickness:number,color:Color3)
    local difference=finish-start
    local len=difference.Magnitude
    if len<0.1 then return end
    local piece=part(parent,name,CFrame.lookAt((start+finish)/2,finish)*
        CFrame.Angles(math.pi/2,0,0),Vector3.new(thickness,len,thickness),
        color,Enum.Material.Metal)
    piece.Shape=Enum.PartType.Cylinder
end

local function luminaire(parent:Instance,lights:Instance,name:string,
    position:Vector3,width:number,tint:Color3)
    -- The actual emitter is a SurfaceLight in the existing PowerLights folder.
    -- It becomes active ONLY after the generator starts.
    part(parent,name.."Armature",CFrame.new(position),
        Vector3.new(width,.31,1.38),BLACK)
    for _,offset in {-0.49,0.49} do
        part(parent,name.."Diffuser",CFrame.new(position+Vector3.new(0,-.185,offset)),
            Vector3.new(width-.26,.06,.31),LENS)
    end
    for _,endX in {-width/2+.23,width/2-.23} do
        part(parent,name.."Fixing",CFrame.new(position+Vector3.new(endX,.15,0)),
            Vector3.new(.22,.16,1.06),METAL)
    end
    local emitter=part(lights,name.."PowerEmitter",
        CFrame.new(position+Vector3.new(0,-.235,0)),
        Vector3.new(width-.48,.08,1.08),LINER)
    local light=Instance.new("SurfaceLight")
    light.Name="PracticalFixture"
    light.Face=Enum.NormalId.Bottom
    light.Color=tint
    light.Brightness=if width>=8 then .92 else .68
    light.Range=if width>=8 then 19 else 13
    light.Angle=116
    light.Shadows=false
    light.Enabled=false
    light.Parent=emitter
end

local function reception(parent:Instance,lights:Instance,r:Room)
    -- Institution-grade architectural lighting in two independent bays.
    -- The central 14-stud public entrance is kept entirely open below 12 studs.
    for _,x in {r.x1+23,r.x2-23} do
        local y=r.height-.75
        luminaire(parent,lights,"ReceptionSuspendedFixture",
            Vector3.new(x,y,r.center.Z),8,Color3.fromRGB(220,205,177))
        for _,z in {r.center.Z-4,r.center.Z+4} do
            tube(parent,"FixtureStandoff",
                Vector3.new(x-3.0,r.height-.14,z),
                Vector3.new(x-3.0,y+.2,z),.12,METAL)
        end
    end
    -- Physical expansion joint at the threshold between public vestibule and
    -- production campus. Low-profile, no additional sound occlusion.
    for _,z in {r.z1+6,r.z2-6} do
        part(parent,"ReceptionFloorExpansionJoint",
            CFrame.new(r.center.X,.07,z),
            Vector3.new(44,.065,.14),BLACK)
        for _,x in {r.center.X-17,r.center.X+17} do
            part(parent,"ExpansionAnchor",CFrame.new(x,.12,z),
                Vector3.new(.35,.06,.35),BRASS)
        end
    end
end

local function gallery(parent:Instance,lights:Instance,r:Room)
    -- An exposed overhead service spine tracks toward recording and power,
    -- establishing an unmistakable human-scale landmark along the route.
    local y=r.height-1.22
    for _,x in {r.x1+24,r.x2-24} do
        part(parent,"GalleryServiceConduit",
            CFrame.new(x,y,r.center.Z),
            Vector3.new(.36,.28,r.z2-r.z1-9),METAL,Enum.Material.Metal)
        for i=0,3 do
            local z=r.z1+7+i*((r.z2-r.z1-14)/3)
            part(parent,"GalleryCableClamp",
                CFrame.new(x,y+.25,z),
                Vector3.new(.71,.12,.22),OXIDE)
        end
    end
    luminaire(parent,lights,"GalleryStaffFixture",
        Vector3.new(r.center.X,r.height-.67,r.center.Z),7.2,
        Color3.fromRGB(190,205,201))
    for _,x in {r.x1+13,r.x2-13} do
        part(parent,"GalleryFloorRouteIdentifier",
            CFrame.new(x,.055,r.center.Z),
            Vector3.new(.23,.06,r.z2-r.z1-14),Color3.fromRGB(100,108,98))
    end
end

local function controlA(parent:Instance,lights:Instance,r:Room)
    -- Dry acoustic geometry has varied thickness and a real spacing rhythm;
    -- no generic material tile is repeated across the control-room desk.
    -- The true Studio A observation window sits on the east wall, so all
    -- acoustic treatment here is either overhead or along the north interior.
    for i=0,7 do
        -- DrumRoom-to-ControlA doorway is centred on this shared north wall.
        -- Leave a deliberate 8+ stud visual opening for the player and Engineer.
        if i==3 or i==4 then
            continue
        end
        local x=r.x1+7+i*4.1
        local depth=if i%3==0 then .82 else if i%3==1 then .53 else .34
        part(parent,"DiffuserCell",
            CFrame.new(x,8.6,r.z1+1.1+depth/2),
            Vector3.new(3.62,10.4,depth),if i%2==0 then LINER else OXIDE,
            Enum.Material.Wood)
        part(parent,"DiffuserShadowJoint",
            CFrame.new(x+1.86,8.7,r.z1+1.06),
            Vector3.new(.10,10.2,.11),BLACK)
    end
    for i=0,2 do
        local x=r.x1+10+i*12
        luminaire(parent,lights,"ControlTaskFixture",
            Vector3.new(x,r.height-.68,r.center.Z),5.2,
            Color3.fromRGB(210,199,175))
    end
    local entryX=r.x1+7
    tube(parent,"SignalTrunk",
        Vector3.new(entryX,r.height-1.3,r.z1+2.7),
        Vector3.new(entryX,r.height-1.3,r.z2-4.1),.19,METAL)
    for i=1,4 do
        local z=r.z1+4.5+i*4.8
        part(parent,"SignalTrunkRetention",
            CFrame.new(entryX,r.height-1.08,z),
            Vector3.new(.65,.10,.25),BRASS)
    end
end

local function liveHall(parent:Instance,lights:Instance,r:Room)
    -- Suspended service tracks above the concert-scale recording floor,
    -- with fixtures whose state follows the same physical generator.
    for _,z in {r.z1+15,r.z2-15} do
        for _,x in {r.x1+20,r.x1+52,r.x2-20} do
            luminaire(parent,lights,"LiveTrackingGrid",
                Vector3.new(x,r.height-1.8,z),8.4,
                Color3.fromRGB(204,189,163))
            for _,offset in {-3.25,3.25} do
                tube(parent,"LiveGridHanger",
                    Vector3.new(x+offset,r.height-.22,z),
                    Vector3.new(x+offset,r.height-1.6,z),.12,METAL)
            end
        end
    end
    -- Floor position tracking labels are recessed, not enormous floating decals.
    for i=0,3 do
        local x=r.x1+17+i*22
        part(parent,"LiveRecordingBayMarker",
            CFrame.new(x,.07,r.z1+6),
            Vector3.new(7,.06,.22),BRASS)
    end
end

function Hero.decorate(parent:Instance,lights:Instance,r:Room,_:Palette)
    if r.name=="Reception" then
        reception(parent,lights,r)
    elseif r.name=="StaffGallery" then
        gallery(parent,lights,r)
    elseif r.name=="ControlA" then
        controlA(parent,lights,r)
    elseif r.name=="LiveHall" then
        liveHall(parent,lights,r)
    end
end

return Hero
