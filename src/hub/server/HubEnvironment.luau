--!strict
-- Hub-only built environment. It is deliberately separate from match-map contract code;
-- hand-authored Workspace.Hub with HubSpawn can replace it without modifying matchmaking.
local Workspace=game:GetService("Workspace")
local HubEnvironment={}
local c={
    concrete=Color3.fromRGB(77,73,70),
    floor=Color3.fromRGB(58,46,42),
    bronze=Color3.fromRGB(112,82,56),
    steel=Color3.fromRGB(47,53,57),
    trim=Color3.fromRGB(30,35,38),
    fabric=Color3.fromRGB(43,46,47),
    amber=Color3.fromRGB(235,182,129)
}
local function part(m: Instance,name: string,size: Vector3,cf: CFrame,
    color: Color3,material: Enum.Material,solid: boolean): Part
    local p=Instance.new("Part")
    p.Name=name
    p.Size=size
    p.CFrame=cf
    p.Color=color
    p.Material=material
    p.Anchored=true
    p.CanCollide=solid
    p.CanQuery=solid
    p.CanTouch=solid
    p.Parent=m
    return p
end
local function plate(m: Instance,name: string,x1: number,y1: number,z1: number,
    x2: number,y2: number,z2: number,color: Color3,material: Enum.Material,solid: boolean): Part
    local lo=Vector3.new(math.min(x1,x2),math.min(y1,y2),math.min(z1,z2))
    local hi=Vector3.new(math.max(x1,x2),math.max(y1,y2),math.max(z1,z2))
    return part(m,name,hi-lo,CFrame.new((lo+hi)/2),color,material,solid)
end
local function plaque(m: Instance,text: string,at: Vector3,w: number,h: number)
    local sign=part(m,"WornNameplate",Vector3.new(w,h,0.22),CFrame.new(at),c.trim,Enum.Material.Metal,false)
    local ui=Instance.new("SurfaceGui")
    ui.Face=Enum.NormalId.Back
    ui.PixelsPerStud=42
    ui.LightInfluence=0.4
    ui.Parent=sign
    local label=Instance.new("TextLabel")
    label.Text=text
    label.Size=UDim2.fromScale(1,1)
    label.TextScaled=true
    label.TextWrapped=true
    label.Font=Enum.Font.RobotoMono
    label.TextColor3=c.amber
    label.BackgroundTransparency=1
    label.Parent=ui
end
local function lamp(m: Instance,at: Vector3,hero: boolean)
    part(m,"IndustrialPendantHousing",Vector3.new(4.2,0.32,1.7),CFrame.new(at),
        c.steel,Enum.Material.Metal,false)
    local lens=part(m,"PendantLens",Vector3.new(3.8,0.08,1.2),
        CFrame.new(at+Vector3.new(0,-0.22,0)),Color3.fromRGB(166,132,96),Enum.Material.Glass,false)
    local spot=Instance.new("SpotLight")
    spot.Face=Enum.NormalId.Bottom
    spot.Brightness=if hero then 1.4 else 0.8
    spot.Range=27
    spot.Angle=115
    spot.Color=c.amber
    spot.Shadows=hero
    spot.Parent=lens
end
function HubEnvironment.build(): BasePart
    local hub=Instance.new("Model")
    hub.Name="Hub"
    -- Wider acoustically insulated concourse with intentional sightlines, not a blank box.
    plate(hub,"OakCompositeFloor",-50,-1,-39,50,0,39,c.floor,Enum.Material.WoodPlanks,true)
    plate(hub,"SuspendedSlab",-50,16,-39,50,17,39,c.trim,Enum.Material.Concrete,true)
    for _,x in {-50,50} do
        plate(hub,"ReinforcedPartition",x-0.8,0,-39,x+0.8,16,39,c.concrete,Enum.Material.Concrete,true)
    end
    for _,z in {-39,39} do
        plate(hub,"ReinforcedPartition",-50,0,z-0.8,50,16,z+0.8,c.concrete,Enum.Material.Concrete,true)
    end
    -- Reception counter, short metal grille and waiting wings.
    plate(hub,"ReceptionOakDesk",-14,0,-31,14,3.8,-24,c.bronze,Enum.Material.Wood,true)
    plate(hub,"ReceptionTop",-14.6,3.8,-31.4,14.6,4.05,-23.6,c.floor,Enum.Material.Wood,false)
    for _,x in {-12,-6,0,6,12} do
        plate(hub,"FrontDeskPanel",x-1,0.45,-23.5,x+1,3.2,-23.3,c.trim,Enum.Material.Metal,false)
    end
    for _,side in {-1,1} do
        local x=side*36
        for _,z in {-20,-8,4,16} do
            plate(hub,"AcousticWallPanel",x-0.14,3.2,z-3.3,x+0.14,12,z+3.3,
                c.fabric,Enum.Material.Fabric,false)
            plate(hub,"WaitingSeating",x-side*5-3,0,z-1.8,x-side*5+3,1.7,z+1.8,
                c.fabric,Enum.Material.Fabric,true)
            plate(hub,"BenchBack",x-side*5-3,1.7,z+1.35,x-side*5+3,3.2,z+1.7,
                c.steel,Enum.Material.Metal,false)
        end
    end
    -- Overhead machine tracks and emergency illuminated exit strips.
    for _,x in {-30,-15,0,15,30} do
        plate(hub,"OverheadCableRack",x-0.25,14.7,-35,x+0.25,15.25,34,c.steel,Enum.Material.Metal,false)
        lamp(hub,Vector3.new(x,15.1,6),x==0)
    end
    plate(hub,"ExitStrip",-4,10.5,38.1,4,11.1,38.3,Color3.fromRGB(103,43,34),Enum.Material.Neon,false)
    plaque(hub,"BLACKLINE / DEAD AIR",Vector3.new(0,10,-38.15),24,3)
    plaque(hub,"SESSIONS  /  STAND BY",Vector3.new(0,6.5,-38.15),20,1.8)
    -- Original rack equipment behind the counter reinforces the studio context.
    for _,x in {-28,28} do
        plate(hub,"Cabinet",x-2,0,-35,x+2,7,-32,c.steel,Enum.Material.Metal,true)
        for j=0,7 do
            plate(hub,"RackKnobs",x-1.6,1+j*0.65,-31.95,x+1.6,1.2+j*0.65,-31.9,
                if j%3==0 then c.bronze else c.trim,Enum.Material.Metal,false)
        end
    end
    local spawn=part(hub,"HubSpawn",Vector3.new(4,0.2,4),
        CFrame.lookAt(Vector3.new(0,0.2,24),Vector3.new(0,0.2,-25)),
        Color3.new(1,1,1),Enum.Material.SmoothPlastic,false)
    spawn.Transparency=1
    hub.Parent=Workspace
    return spawn
end
return HubEnvironment
