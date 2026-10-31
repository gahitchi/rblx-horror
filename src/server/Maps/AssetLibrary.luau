--!strict
-- Reusable original environment models created from native solids.
-- The kit is usable without imported meshes or asset IDs. It provides differentiated
-- studio, broadcast and foundry silhouettes, while an authored mesh/PBR pass follows.
-- Decorative meshes never contribute to collision, navigation or sound occlusion.
local Assets={}

local function shape(parent: Instance, name: string, size: Vector3, cf: CFrame,
    color: Color3, material: Enum.Material, cylinder: boolean?): Part
    local p=Instance.new("Part")
    p.Name=name
    p.Size=size
    p.CFrame=cf
    p.Material=material
    p.Color=color
    p.Anchored=true
    p.CanCollide=false
    p.CanQuery=false
    p.CanTouch=false
    p.CastShadow=size.Magnitude>2.8
    if cylinder then
        p.Shape=Enum.PartType.Cylinder
    end
    p.Parent=parent
    return p
end
local function slab(parent: Instance,name: string,x: number,y: number,z: number,
    sx: number,sy: number,sz: number,color: Color3,material: Enum.Material): Part
    return shape(parent,name,Vector3.new(sx,sy,sz),CFrame.new(x,y,z),color,material)
end
local function rod(parent: Instance,name: string,at: Vector3,length: number,diameter: number,
    color: Color3,vertical: boolean?): Part
    return shape(parent,name,Vector3.new(length,diameter,diameter),
        CFrame.new(at)*(if vertical then CFrame.Angles(0,0,math.rad(90)) else CFrame.identity),
        color,Enum.Material.Metal,true)
end
local function meshSpeaker(parent: Instance,x: number,y: number,z: number,p: any)
    slab(parent,"MonitorCabinet",x,y,z,2.3,3.6,1.5,p.steel,Enum.Material.Wood)
    for _,height in { -0.9, 0.8 } do
        shape(parent,"MonitorCone",Vector3.new(0.14,1.05,1.05),
            CFrame.new(x,y+height,z-0.78)*CFrame.Angles(0,math.rad(90),0),
            p.trim,Enum.Material.Metal,true)
        shape(parent,"DriverDustCap",Vector3.new(0.15,0.43,0.43),
            CFrame.new(x,y+height,z-0.9)*CFrame.Angles(0,math.rad(90),0),
            p.steel,Enum.Material.SmoothPlastic,true)
    end
end
local function analogRack(parent: Instance,x: number,z: number,p: any)
    slab(parent,"SteelRack",x,4.1,z,3.5,8.0,2.0,p.steel,Enum.Material.Metal)
    for j=0,9 do
        local y=0.85+j*0.7
        slab(parent,"RackModule",x,y,z-1.07,3.13,0.55,0.1,p.trim,Enum.Material.Metal)
        for k=0,3 do
            slab(parent,"RackButton",x-1.3+k*0.64,y,z-1.16,0.13,0.14,0.05,
                if j%3==0 then p.accent else p.steel,Enum.Material.Metal)
        end
    end
end
local function tapeReel(parent: Instance,x: number,y: number,z: number,p: any)
    local rot=CFrame.Angles(0,math.rad(90),0)
    shape(parent,"ReelFlange",Vector3.new(0.18,1.7,1.7),CFrame.new(x,y,z)*rot,p.steel,Enum.Material.Metal,true)
    shape(parent,"ReelHub",Vector3.new(0.23,0.47,0.47),CFrame.new(x,y,z-0.13)*rot,p.trim,Enum.Material.Metal,true)
end
local function oldMicrophone(parent: Instance,x: number,z: number,p: any)
    rod(parent,"MicColumn",Vector3.new(x,2.7,z),5.1,0.12,p.steel,true)
    rod(parent,"MicCrossbar",Vector3.new(x+0.45,5.15,z),1.15,0.13,p.steel)
    slab(parent,"CapsuleHousing",x+0.9,5.13,z,0.45,0.64,0.42,p.trim,Enum.Material.Metal)
    for j=0,3 do
        slab(parent,"MicGrille",x+0.9,4.91+j*0.14,z-0.23,0.34,0.045,0.025,p.steel,Enum.Material.Metal)
    end
    rod(parent,"WeightedFoot",Vector3.new(x,0.1,z),1.6,0.16,p.trim)
end
local function foundryBell(parent: Instance,x: number,z: number,p: any)
    -- Stepped die-cast bell, a distant landmark, not a single undifferentiated cylinder.
    local bronze=Color3.fromRGB(133,91,54)
    local bands={ {y=1.1,r=5.4,h=1.4},{y=2.5,r=4.7,h=1.4},{y=3.85,r=3.6,h=1.2},
        {y=5.0,r=2.75,h=1.1},{y=5.85,r=1.7,h=0.8} }
    for _,b in bands do
        rod(parent,"BronzeBellSegment",Vector3.new(x,b.y,z),b.h,b.r,bronze,true)
    end
    rod(parent,"BellShoulder",Vector3.new(x,6.4,z),0.4,2.4,p.accent,true)
    rod(parent,"BellCrownPin",Vector3.new(x,7.2,z),1.1,0.55,p.steel,true)
    for _,h in {1.0,1.85,3.0} do
        rod(parent,"CastReliefRing",Vector3.new(x,h,z),0.16,5.0-h*0.22,p.accent,true)
    end
end
local function foundryPipe(parent: Instance,x: number,z: number,p: any)
    rod(parent,"IndustrialSteamPipe",Vector3.new(x,9.4,z),12.5,0.78,p.steel,true)
    rod(parent,"PipeFlange",Vector3.new(x,4.1,z),0.34,1.4,p.trim,true)
    rod(parent,"PipeFlange",Vector3.new(x,12.6,z),0.34,1.4,p.trim,true)
    for i=0,3 do
        slab(parent,"PressureGauge",x+0.48,6+i*0.5,z,0.18,0.2,0.1,p.accent,Enum.Material.Metal)
    end
end
local function acousticWall(parent: Instance, x: number, z: number, length: number, p: any)
    for i=0,5 do
        local zz=z+i*(length/6)
        slab(parent,"AbsorberPanel",x,7,zz,0.22,8.5,length/7,p.trim,Enum.Material.Fabric)
        for k=0,2 do
            slab(parent,"AbsorberGroove",x+0.13,4+k*2.3,zz,0.07,0.09,length/8,p.steel,Enum.Material.Wood)
        end
    end
end
function Assets.decorate(parent: Instance, role: string, id: string,
    x1: number,x2: number,z1: number,z2: number,height: number,p: any)
    local x=(x1+x2)/2
    local z=(z1+z2)/2
    local left=x1+3.1
    local north=z1+3.1
    local right=x2-3.1
    local south=z2-3.1

    -- Cove lighting, realistic baseboards and metal ceiling-service trays are shared across maps.
    for _,y in {0.35,height-0.6} do
        slab(parent,"WallCove",x1+0.75,y,z,0.14,0.5,z2-z1-2,p.trim,Enum.Material.Wood)
        slab(parent,"WallCove",x2-0.75,y,z,0.14,0.5,z2-z1-2,p.trim,Enum.Material.Wood)
    end
    for _,zz in {z1+4,z2-4} do
        slab(parent,"CeilingCrossmember",x,height-0.7,zz,x2-x1-4,0.33,0.55,
            p.steel,Enum.Material.Metal)
    end

    if id=="studio" then
        if role=="control" or role=="master" then
            meshSpeaker(parent,right-4,2.35,north,p)
            meshSpeaker(parent,left+4,2.35,north,p)
            analogRack(parent,right-2,north+5,p)
            acousticWall(parent,x2-0.85,z1+4,z2-z1-9,p)
        elseif role=="live" or role=="stage" then
            oldMicrophone(parent,right-8,south-4,p)
            slab(parent,"FloorCableRoute",x,0.07,z,8,0.04,0.15,p.steel,Enum.Material.Metal)
            acousticWall(parent,x1+0.85,z1+4,z2-z1-10,p)
        elseif role=="archive" or role=="store" then
            for j=0,2 do
                tapeReel(parent,right-7,3.2+j*1.9,north+2,p)
            end
        elseif role=="booth" then
            acousticWall(parent,x2-0.9,z1+4,z2-z1-9,p)
            oldMicrophone(parent,right-7,south-5,p)
        end
    elseif id=="radio" then
        if role=="broadcast" or role=="control" or role=="master" then
            analogRack(parent,right-2,north+4,p)
            oldMicrophone(parent,right-8,south-5,p)
            for j=0,5 do
                slab(parent,"ControlRoomVU",right-8+j*0.65,6,north+0.3,0.45,0.55,0.08,
                    if j%2==0 then p.accent else p.trim,Enum.Material.Glass)
            end
        elseif role=="machine" then
            analogRack(parent,right-2,north+4,p)
            analogRack(parent,left+2,south-5,p)
        elseif role=="archive" then
            for j=0,3 do
                tapeReel(parent,right-6,1.8+j*1.8,north+4,p)
            end
        elseif role=="booth" then
            acousticWall(parent,x1+0.9,z1+4,z2-z1-9,p)
            oldMicrophone(parent,right-7,south-6,p)
        end
    elseif id=="foundry" then
        if role=="stage" or role=="machine" or role=="boiler" then
            if role=="stage" then
                foundryBell(parent,right-8,north+7,p)
            end
            foundryPipe(parent,left+3,south-4,p)
            slab(parent,"OverheadCraneRail",x,height-2.2,north+4,x2-x1-3,0.8,1.7,
                p.steel,Enum.Material.Metal)
        elseif role=="mold" or role=="store" then
            foundryBell(parent,right-8,north+6,p)
        elseif role=="control" then
            analogRack(parent,right-4,north+5,p)
        end
    end
end
return Assets
