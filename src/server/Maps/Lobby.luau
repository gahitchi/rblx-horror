--!strict
local Workspace=game:GetService("Workspace")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Lobby={}
local function part(parent: Instance,name: string,size: Vector3,at: Vector3,
    material: Enum.Material,color: Color3,solid: boolean): Part
    local p=Instance.new("Part")
    p.Name=name
    p.Size=size
    p.Position=at
    p.Anchored=true
    p.Material=material
    p.Color=color
    p.CanCollide=solid
    p.CanQuery=solid
    p.CanTouch=solid
    p.Parent=parent
    return p
end
function Lobby.build(): CFrame
    local previous=Workspace:FindFirstChild("Lobby")
    if previous then previous:Destroy() end
    local root=Instance.new("Model")
    root.Name="Lobby"
    local o=Config.LOBBY_ORIGIN
    part(root,"StudioWaitingRoomFloor",Vector3.new(56,2,42),o+Vector3.new(0,-1,0),
        Enum.Material.WoodPlanks,Color3.fromRGB(64,50,43),true)
    part(root,"ConcreteCeiling",Vector3.new(56,1,42),o+Vector3.new(0,15.5,0),
        Enum.Material.Concrete,Color3.fromRGB(31,33,35),true)
    for _,x in {-28,28} do
        part(root,"ThickWall",Vector3.new(1.4,15,42),o+Vector3.new(x,7.5,0),
            Enum.Material.Concrete,Color3.fromRGB(70,69,67),true)
    end
    for _,z in {-21,21} do
        part(root,"ThickWall",Vector3.new(56,15,1.4),o+Vector3.new(0,7.5,z),
            Enum.Material.Concrete,Color3.fromRGB(70,69,67),true)
    end
    part(root,"CheckInDesk",Vector3.new(17,3.5,4),o+Vector3.new(0,1.75,-13),
        Enum.Material.Wood,Color3.fromRGB(75,55,43),true)
    part(root,"CounterTrim",Vector3.new(18,0.3,5),o+Vector3.new(0,3.7,-13),
        Enum.Material.Wood,Color3.fromRGB(114,80,57),false)
    for _,x in {-21,21} do
        part(root,"WaitingBench",Vector3.new(7,1.8,3.4),o+Vector3.new(x*0.8,1,4),
            Enum.Material.Fabric,Color3.fromRGB(57,58,58),true)
        part(root,"AcousticPanel",Vector3.new(0.2,7,8),o+Vector3.new(if x<0 then -27.15 else 27.15,8,-7),
            Enum.Material.Fabric,Color3.fromRGB(36,41,44),false)
    end
    local fixture=part(root,"OnAirIndicator",Vector3.new(8,0.65,0.3),o+Vector3.new(0,12,-20.1),
        Enum.Material.Neon,Color3.fromRGB(160,36,31),false)
    local red=Instance.new("PointLight")
    red.Color=Color3.fromRGB(255,82,58)
    red.Brightness=0.4
    red.Range=12
    red.Shadows=false
    red.Parent=fixture
    for _,x in {-17,0,17} do
        local lamp=part(root,"WarmPractical",Vector3.new(3.2,0.2,1.2),o+Vector3.new(x,14,1),
            Enum.Material.Metal,Color3.fromRGB(76,72,66),false)
        local spot=Instance.new("SpotLight")
        spot.Face=Enum.NormalId.Bottom
        spot.Angle=105
        spot.Range=27
        spot.Brightness=1
        spot.Shadows=(x==0)
        spot.Color=Color3.fromRGB(250,194,144)
        spot.Parent=lamp
    end
    local plaque=part(root,"DeadAirStudioSign",Vector3.new(16,3.2,0.2),
        o+Vector3.new(0,9,-20.12),Enum.Material.Metal,Color3.fromRGB(30,30,32),false)
    local gui=Instance.new("SurfaceGui")
    gui.Face=Enum.NormalId.Back
    gui.PixelsPerStud=40
    gui.LightInfluence=0.35
    gui.Parent=plaque
    local label=Instance.new("TextLabel")
    label.Size=UDim2.fromScale(1,1)
    label.Text="DEAD AIR   /   SESSIONS"
    label.Font=Enum.Font.RobotoMono
    label.TextScaled=true
    label.TextColor3=Color3.fromRGB(209,190,156)
    label.BackgroundTransparency=1
    label.Parent=gui
    root.Parent=Workspace
    return CFrame.lookAt(o+Vector3.new(0,3,11),o+Vector3.new(0,3,-13))
end
return Lobby
