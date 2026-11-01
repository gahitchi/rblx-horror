--!strict
-- VF-01: four architectural status stations, not a random field of screens.
-- A small set of original, grounded devices makes the entire signal chain
-- readable through the player's objectives. They do not block sound or movement.
local FacilityDevices={}

type Room={name:string,role:string,x1:number,x2:number,z1:number,z2:number,
    height:number,center:Vector3}
local PANEL=Color3.fromRGB(51,56,56)
local RIM=Color3.fromRGB(105,102,89)
local GLASS=Color3.fromRGB(39,48,48)
local LETTER=Color3.fromRGB(201,196,176)

local labels:{[string]:string}={
    Reception="PUBLIC EGRESS / CONTROL",
    StaffGallery="SIGNAL DISTRIBUTION",
    ControlA="MASTER BUS / CHANNEL 08",
    LiveHall="RECORDING FLOOR / PROGRAM",
}
-- Keep every device away from open portals, from ControlA's diffuser wall,
-- and from existing recording equipment. All four attach at human eye height
-- to the south wall, offset toward its east side (Control A uses west side).
local function position(room:Room):Vector3
    local x=if room.name=="ControlA" then room.x1+8 else room.x2-12
    return Vector3.new(x,8.15,room.z2-1.14)
end

local function detail(parent:Instance,name:string,cf:CFrame,size:Vector3,
    color:Color3,material:Enum.Material?):Part
    local part=Instance.new("Part")
    part.Name=name
    part.Size=size
    part.CFrame=cf
    part.Color=color
    part.Material=material or Enum.Material.SmoothPlastic
    part.Anchored=true
    part.CanCollide=false
    part.CanTouch=false
    part.CanQuery=false
    part.CastShadow=false
    part.TopSurface=Enum.SurfaceType.Smooth
    part.BottomSurface=Enum.SurfaceType.Smooth
    part:SetAttribute("DisablePBR",true)
    part:SetAttribute("ArtPass","BlacklineVF01")
    part.Parent=parent
    return part
end

local function textLabel(parent:Instance,name:string,y:number,h:number,
    content:string,size:Enum.Font,color:Color3):TextLabel
    local caption=Instance.new("TextLabel")
    caption.Name=name
    caption.Position=UDim2.fromScale(.055,y)
    caption.Size=UDim2.fromScale(.88,h)
    caption.BackgroundTransparency=1
    caption.Font=size
    caption.Text=content
    caption.TextColor3=color
    caption.TextScaled=true
    caption.TextWrapped=false
    caption.TextXAlignment=Enum.TextXAlignment.Left
    caption.Parent=parent
    return caption
end

function FacilityDevices.decorate(parent:Instance,room:Room)
    local legend=labels[room.name]
    if not legend then return end
    local node=Instance.new("Model")
    node.Name="VF01_"..room.name
    node:SetAttribute("FacilityCircuit",room.name)
    node.Parent=parent
    local p=position(room)
    local frame=detail(node,"PressedSteelHousing",CFrame.new(p),
        Vector3.new(6.1,2.92,.31),PANEL)
    detail(node,"AnodizedLowerRail",CFrame.new(p+Vector3.new(0,-1.32,-.20)),
        Vector3.new(6.19,.16,.13),RIM,Enum.Material.Metal)
    local glass=detail(node,"InsetSignalGlass",CFrame.new(p+Vector3.new(0,.10,-.193)),
        Vector3.new(5.58,2.30,.07),GLASS,Enum.Material.SmoothPlastic)
    local lens=detail(node,"CircuitLens",CFrame.new(p+Vector3.new(2.30,.93,-.27)),
        Vector3.new(.31,.24,.085),Color3.fromRGB(76,73,65))
    lens:SetAttribute("FacilityStatusLens",true)
    -- Each frame has a physical matte glass display. Its copy is deliberately
    -- sparse and changes with *real* objectives, not an arbitrary timer.
    local gui=Instance.new("SurfaceGui")
    gui.Name="StatusPlate"
    gui.Face=Enum.NormalId.Front
    gui.PixelsPerStud=65
    gui.LightInfluence=.32
    gui.Parent=glass
    local inset=Instance.new("Frame")
    inset.Name="TextInset"
    inset.Position=UDim2.fromScale(.06,.12)
    inset.Size=UDim2.fromScale(.89,.74)
    inset.BorderSizePixel=0
    inset.BackgroundTransparency=1
    inset.Parent=gui
    textLabel(inset,"SystemLegend",.02,.22,legend,Enum.Font.RobotoMono,LETTER)
    textLabel(inset,"SignalStatus",.33,.33,"OFFLINE",Enum.Font.RobotoMono,
        Color3.fromRGB(154,146,128))
    textLabel(inset,"OperatorNote",.71,.19,"LOCAL POWER NOT AVAILABLE",
        Enum.Font.RobotoMono,Color3.fromRGB(126,133,126))
    node.PrimaryPart=frame
end

return FacilityDevices
