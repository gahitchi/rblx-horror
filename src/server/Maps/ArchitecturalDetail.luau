--!strict
-- Layered architecture: scale cues, believable ceiling systems and per-map material language.
-- Important: all pieces are purely visual and cannot alter monster navigation or sound rays.
local Detail={}
type Palette={wall: Color3,floor: Color3,ceiling: Color3,trim: Color3,steel: Color3,accent: Color3}

local function piece(parent: Instance,name: string,x: number,y: number,z: number,
    sx: number,sy: number,sz: number,color: Color3, material: Enum.Material, shadow: boolean?): Part
    local p=Instance.new("Part")
    p.Name=name
    p.Size=Vector3.new(sx,sy,sz)
    p.Position=Vector3.new(x,y,z)
    p.Anchored=true
    p.Material=material
    p.Color=color
    p.CanCollide=false
    p.CanQuery=false
    p.CanTouch=false
    p.CastShadow=shadow==true
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end
local function cylinder(parent: Instance,name: string,x: number,y: number,z: number,
    length: number,diameter: number,color: Color3,vertical: boolean?)
    local p=piece(parent,name,x,y,z,length,diameter,diameter,color,Enum.Material.Metal)
    p.Shape=Enum.PartType.Cylinder
    if vertical then p.CFrame=p.CFrame*CFrame.Angles(0,0,math.rad(90)) end
end

local function channel(parent: Instance,x: number,z: number,length: number,p: Palette,h: number)
    -- A suspended cable tray composed of a trough, two lips and discreet brackets.
    piece(parent,"SuspendedCableTrough",x,h-1.35,z,1.5,0.12,length,p.steel,Enum.Material.Metal)
    for _,dx in {-0.72,0.72} do
        piece(parent,"SuspendedCableTrayEdge",x+dx,h-1.15,z,0.11,0.37,length,p.trim,Enum.Material.Metal)
    end
    for dz=-length/2+2,length/2-2,6 do
        piece(parent,"TrunkHanger",x,h-0.55,z+dz,0.13,1.3,0.12,p.steel,Enum.Material.Metal)
    end
end
local function studioDetails(parent: Instance,role: string,x1: number,x2: number,z1: number,z2: number,h: number,p: Palette)
    local cx=(x1+x2)/2
    local cz=(z1+z2)/2
    if role=="live" or role=="stage" or role=="control" or role=="master" or role=="booth" then
        -- Alternating timber slats and deep textile absorbers: macro-geometry first,
        -- delicate woven normal details come from the uploaded acoustic MaterialVariant.
        for i=1,6 do
            local z=z1+3.4+i*(z2-z1-7)/7
            piece(parent,"VerticalOakDiffuser",x1+0.8,7,z,0.22,7.8,0.35,p.accent,Enum.Material.Wood)
            piece(parent,"AbsorptionGap",x1+0.94,7,z+0.5,0.11,7.4,0.55,p.trim,Enum.Material.Fabric)
        end
        for i=1,4 do
            local x=x1+5+i*(x2-x1-10)/5
            piece(parent,"SuspendedAcousticCloud",x,h-2.1,cz,2.1,0.23,9,
                p.trim,Enum.Material.Fabric,true)
            piece(parent,"CloudSuspensionWire",x,h-1.1,cz-3,0.035,2.1,0.035,
                p.steel,Enum.Material.Metal)
        end
    else
        channel(parent,x1+2.1,cz,z2-z1-6,p,h)
    end
    if role=="control" or role=="broadcast" or role=="master" then
        -- Rack patchbay wall with individual jack sockets; no fake neon lighting.
        piece(parent,"PatchWallPanel",x2-0.9,7,cz,0.23,6.1,10,p.steel,Enum.Material.Metal)
        for line=1,5 do
            for col=1,8 do
                piece(parent,"PatchSocket",x2-1.05,4.7+line*0.67,cz-4.1+col*0.85,
                    0.08,0.19,0.19,if (line+col)%4==0 then p.accent else p.trim,Enum.Material.Metal)
            end
        end
    end
end
local function radioDetails(parent: Instance,role: string,x1: number,x2: number,z1: number,z2: number,h: number,p: Palette)
    local cz=(z1+z2)/2
    local cx=(x1+x2)/2
    channel(parent,x2-2,cz,z2-z1-6,p,h)
    -- Directional cold-metal edge architecture and service panels reflect flashlight beams.
    for i=0,4 do
        local z=z1+5+i*(z2-z1-10)/4
        piece(parent,"VentilationBlade",x1+0.74,9,z,0.2,0.17,3.9,p.steel,Enum.Material.Metal)
    end
    if role=="broadcast" or role=="control" or role=="machine" then
        for i=0,3 do
            piece(parent,"SignalRackPanel",x2-1.1,4.3+i*1.4,cz,0.22,1.1,7.8,p.trim,Enum.Material.Metal)
            for j=0,5 do
                piece(parent,"SignalConnector",x2-1.25,4.6+i*1.4,cz-3.3+j*1.3,
                    0.08,0.22,0.28,if j%3==0 then p.accent else p.steel,Enum.Material.Metal)
            end
        end
        piece(parent,"OnAirHousing",cx,h-3,z1+1.2,6,1.1,0.19,p.steel,Enum.Material.Metal)
        piece(parent,"OnAirLens",cx,h-3,z1+1.09,4.8,0.49,0.06,
            Color3.fromRGB(93,26,25),Enum.Material.Glass)
    end
end
local function foundryDetails(parent: Instance,role: string,x1: number,x2: number,z1: number,z2: number,h: number,p: Palette)
    local cx=(x1+x2)/2
    local cz=(z1+z2)/2
    -- Shop-floor crane and steam infrastructure. The broad beams look substantial,
    -- but are above movement clearance and are never used for navigation collision.
    for _,dz in {-7,7} do
        piece(parent,"CastIronTruss",cx,h-2.3,cz+dz,x2-x1-4,0.8,1.2,p.steel,Enum.Material.Metal,true)
    end
    for _,x in {x1+2.2,x2-2.2} do
        cylinder(parent,"SteamConduit",x,7.7,cz,10,0.56,p.steel,true)
        for _,yy in {4,8,11} do
            cylinder(parent,"SteamPipeClamp",x,yy,cz,0.28,1.0,p.accent,true)
        end
    end
    if role=="machine" or role=="boiler" or role=="stage" or role=="mold" then
        -- Segmented floor drainage and caution kerbing around heavy machines.
        for i=0,5 do
            local zz=z1+5+i*(z2-z1-10)/5
            piece(parent,"ShopFloorDrain",x1+3,0.08,zz,3,0.08,0.13,p.trim,Enum.Material.Metal)
        end
        for i=0,3 do
            local xx=x1+6+i*(x2-x1-12)/4
            piece(parent,"IndustrialHazardMark",xx,0.05,z1+3,2.5,0.04,0.28,p.accent,Enum.Material.SmoothPlastic)
        end
    end
end
function Detail.decorate(parent: Instance,id: string,role: string,
    x1: number,x2: number,z1: number,z2: number,h: number,p: Palette)
    local cx=(x1+x2)/2
    local cz=(z1+z2)/2
    -- Columns and coves provide a recognizable scale without blocking portal thresholds.
    for _,x in {x1+0.95,x2-0.95} do
        for _,z in {z1+0.95,z2-0.95} do
            piece(parent,"CornerPierPlinth",x,1.15,z,1.0,2.3,1.0,p.steel,Enum.Material.Metal)
            piece(parent,"CornerPier",x,h/2+1,z,0.44,h-4,0.44,p.trim,Enum.Material.Concrete)
            piece(parent,"CornerPierCapital",x,h-0.4,z,1.1,0.7,1.1,p.steel,Enum.Material.Metal)
        end
    end
    piece(parent,"CeilingCableSoffit",cx,h-0.52,cz,x2-x1-5,0.32,0.25,p.steel,Enum.Material.Metal)
    if id=="studio" then
        studioDetails(parent,role,x1,x2,z1,z2,h,p)
    elseif id=="radio" then
        radioDetails(parent,role,x1,x2,z1,z2,h,p)
    elseif id=="foundry" then
        foundryDetails(parent,role,x1,x2,z1,z2,h,p)
    end
end
return Detail
