--!strict
-- Data-driven production-map geometry. One contract-compliant model, independent of the old greybox.
-- Every map owns its geometry, patrol spots, doors, markers, power state and a visual theme.
-- Deliberately no free-floating "ray tracing": Roblox lighting is handled by VisualFidelity.
local Workspace = game:GetService("Workspace")
local AssetLibrary = require(script.Parent.AssetLibrary)
local ArchitecturalDetail = require(script.Parent.ArchitecturalDetail)
local FinishDetail = require(script.Parent.FinishDetail)
local PBRMaterials = require(script.Parent.PBRMaterials)
local PrefabLibrary = require(script.Parent.Parent.PrefabLibrary)

local Kit = {}
export type Room = {
    name: string, role: string,
    col: number?, row: number?,
    x1: number?, x2: number?, z1: number?, z2: number?,
    height: number?,
}
export type Specification = {
    id: string, name: string, palette: { wall: Color3, floor: Color3, ceiling: Color3, trim: Color3, steel: Color3, accent: Color3 },
    x: { number }, z: { number }, height: number, rooms: { Room }, authored: boolean?,
    links: { { number | string } }, booths: { string }, windows: { { string } }?, fuseRooms: { string },
    generator: string, fuseBox: string, tape: string, spawn: string, monster: string,
}
type AreaInfo = { name: string, role: string, x1: number, x2: number, z1: number, z2: number, height: number, center: Vector3 }
type Portal = { axis: string, at: number, along: number, width: number, kind: string, name: string }
local function folder(name: string, parent: Instance): Folder
    local f = Instance.new("Folder")
    f.Name = name
    f.Parent = parent
    return f
end
local function piece(
    parent: Instance, name: string, size: Vector3, cf: CFrame,
    color: Color3, material: Enum.Material, solid: boolean
): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material
    p.Anchored = true
    p.CanCollide = solid
    p.CanQuery = solid
    p.CanTouch = solid
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end
local function box(parent: Instance, name: string, x1: number, y1: number, z1: number,
    x2: number, y2: number, z2: number, color: Color3, material: Enum.Material, solid: boolean): Part
    local lo = Vector3.new(math.min(x1,x2),math.min(y1,y2),math.min(z1,z2))
    local hi = Vector3.new(math.max(x1,x2),math.max(y1,y2),math.max(z1,z2))
    return piece(parent, name, hi-lo, CFrame.new((lo+hi)/2), color, material, solid)
end
local function mark(parent: Instance, name: string, pos: Vector3): Part
    local p = piece(parent,name,Vector3.one,CFrame.new(pos),Color3.fromRGB(40,210,90),Enum.Material.SmoothPlastic,false)
    p.Transparency = 1
    return p
end
local function sign(parent: Instance, text: string, position: Vector3, faceYaw: number, w: number)
    local p=piece(parent,"Sign",Vector3.new(w,1.25,0.13),CFrame.new(position)*CFrame.Angles(0,math.rad(faceYaw),0),
        Color3.fromRGB(30,32,33),Enum.Material.Metal,false)
    local gui=Instance.new("SurfaceGui")
    gui.Face=Enum.NormalId.Back
    gui.PixelsPerStud=40
    gui.LightInfluence=0.4
    gui.Parent=p
    local label=Instance.new("TextLabel")
    label.Size=UDim2.fromScale(1,1)
    label.BackgroundTransparency=1
    label.Font=Enum.Font.RobotoMono
    label.TextColor3=Color3.fromRGB(208,202,181)
    label.TextScaled=true
    label.Text=text
    label.Parent=gui
end

local function rectangle(r: AreaInfo, a: number, y: number, b: number, color: Color3, material: Enum.Material, parent: Instance)
    box(parent,"Equipment",r.center.X+a-2.4,y,r.center.Z+b-1.6,
        r.center.X+a+2.4,y+3.1,r.center.Z+b+1.6,color,material,true)
end
local function furnishing(r: AreaInfo, theme: Specification, parent: Instance)
    local p=theme.palette
    local x,z=r.center.X,r.center.Z
    local hw=(r.x2-r.x1)/2
    local hd=(r.z2-r.z1)/2
    -- Place collision props along outer corners, not over monster's central Spots or doorways.
    local left=x-hw+4.5
    local right=x+hw-4.5
    local back=z-hd+4.5
    local front=z+hd-4.5
    local role=r.role
    if role=="control" or role=="broadcast" or role=="master" then
        -- Exactly one invisible collision proxy. Visual worktops, cabinet framing
        -- and imported consoles are separate from navigation and sound occlusion.
        local collider=box(parent,"DeskPlinth",left-2,0,back-1,left+5,2.7,back+2.5,
            p.steel,Enum.Material.Metal,true)
        collider.Transparency=1
        collider.CastShadow=false
        collider:SetAttribute("DisablePBR",true)
        if PrefabLibrary.place(parent,"MixingConsole",CFrame.new(left+1.5,0,back+0.7)) then
            -- The uploaded GLB owns its cabinet, top and controls. A second
            -- procedural tabletop would intersect and shimmer under lighting.
            FinishDetail.consoleMount(parent,theme.id,left-2,back-1,left+5,back+2.5)
        else
            FinishDetail.counter(parent,theme.id,"control",left-2,back-1,
                left+5,back+2.5,2.7,p)
            -- Native fallback uses the same worktop rather than the old noisy
            -- "ConsoleSurface" slab that covered a large area with rust tiling.
            for i=1,8 do
                local fx=left-1.8+i*0.79
                local fader=box(parent,"ConsoleFader",fx,3.01,back+0.1,fx+0.24,3.11,back+1.9,
                    p.accent,Enum.Material.SmoothPlastic,false)
                fader:SetAttribute("DisablePBR",true)
            end
            for i=0,2 do
                local frame=box(parent,"MeterFrame",left-1+i*2.4,3.45,back-1.1,
                    left+0.7+i*2.4,5.2,back-0.8,p.steel,Enum.Material.SmoothPlastic,false)
                frame:SetAttribute("DisablePBR",true)
                box(parent,"MeterGlow",left-0.9+i*2.4,3.65,back-1.17,
                    left+0.55+i*2.4,5.05,back-1.13,
                    Color3.fromRGB(36,92,72),Enum.Material.Glass,false)
            end
        end
    elseif role=="live" or role=="stage" then
        rectangle(r,-hw+5,0,-hd+5,p.steel,Enum.Material.Metal,parent)
        for i=0,2 do
            local px=left+3+i*3
            local shaft=piece(parent,"MicStand",Vector3.new(4,0.15,0.15),
                CFrame.new(px,2.9,back+7)*CFrame.Angles(0,0,math.rad(90)),
                p.steel,Enum.Material.Metal,false)
            shaft.Shape=Enum.PartType.Cylinder
            box(parent,"MicBody",px-0.25,4.6,back+6.6,px+0.25,5.1,back+7.2,p.trim,Enum.Material.Metal,false)
        end
    elseif role=="archive" or role=="store" or role=="mold" then
        for i=0,2 do
            local zz=back+2+i*6.5
            if zz<front-2 then
                box(parent,"ArchiveShelf",left-2,0,zz-0.7,left+3,7.8,zz+0.7,p.steel,Enum.Material.Metal,true)
                for j=0,6 do
                    box(parent,"CaseSpine",left-1.7+j*0.61,3.1,zz+0.75,left-1.25+j*0.61,5.5,zz+0.87,
                        if j%3==0 then p.accent else p.trim,Enum.Material.Wood,false)
                end
            end
        end
    elseif role=="booth" then
        for i=0,5 do
            local zz=back+i*3.5
            if zz<front then
                box(parent,"FabricAbsorber",r.x1+0.6,1.4,zz-1.1,r.x1+0.85,8.9,zz+1.1,
                    p.trim,Enum.Material.Fabric,false)
            end
        end
        box(parent,"BoothCarpet",r.x1+2,0.03,r.z1+2,r.x2-2,0.09,r.z2-2,p.trim,Enum.Material.Fabric,false)
    elseif role=="machine" or role=="generator" or role=="boiler" then
        box(parent,"IndustrialMachine",left-2,0,back-1,left+5,6.5,back+3,p.steel,Enum.Material.DiamondPlate,true)
        for i=0,3 do
            local pipe=piece(parent,"CopperPipe",Vector3.new(6.5,0.22,0.22),
                CFrame.new(left+1,7.8+i*0.6,back+2.1),p.accent,Enum.Material.Metal,false)
            pipe.Shape=Enum.PartType.Cylinder
        end
    elseif role=="corridor" then
        -- Restrained, believable wall-mounted cable trays, leaving at least 8 studs clear.
        box(parent,"ServiceConduit",r.x1+0.55,9.3,r.z1+3,r.x1+0.88,9.8,r.z2-3,p.steel,Enum.Material.Metal,false)
    elseif role=="reception" or role=="lounge" then
        local counterProxy=box(parent,"ReceptionCounter",left-1,0,back-1,
            left+7,3.3,back+2.6,p.trim,Enum.Material.Wood,true)
        counterProxy.Transparency=1
        counterProxy.CastShadow=false
        counterProxy:SetAttribute("DisablePBR",true)
        FinishDetail.counter(parent,theme.id,"reception",left-1,back-1,
            left+7,back+2.6,3.3,p)
        for _, sx in {right-2,right+1} do
            box(parent,"WaitingSeat",sx-1,0,front-2,sx+1,1.9,front+1,p.steel,Enum.Material.Fabric,true)
        end
    else
        -- Bed of equipment/chassis creates plausible occlusion without random debris in paths.
        box(parent,"StoragePallet",right-4,0,back-2,right+0.4,2.2,back+1.5,p.steel,Enum.Material.Wood,true)
    end
    sign(parent,string.upper(r.name),Vector3.new(x,9.7,r.z1+0.68),180,math.min(13,hw*1.15))
    for i=0,2 do
        local px=r.x1+6+i*math.max(4,(r.x2-r.x1-12)/2)
        -- Recessed linear fixture diffusers look like real hardware. They follow generator power.
        box(parent,"CableTrunk",px-0.2,theme.height-1.6,r.z1+1.6,px+0.2,theme.height-1.2,r.z2-1.6,
            p.steel,Enum.Material.Metal,false)
    end
end
local function doorLeaf(parent: Instance, portal: Portal, palette: { wall: Color3, floor: Color3, ceiling: Color3, trim: Color3, steel: Color3, accent: Color3 }, mapId: string): Part
    local x = if portal.axis=="X" then portal.along else portal.at
    local z = if portal.axis=="X" then portal.at else portal.along
    local leaf=piece(parent,portal.name,Vector3.new(portal.width-0.2,9,0.55),
        CFrame.new(x,4.5,z)*(if portal.axis=="Z" then CFrame.Angles(0,math.rad(90),0) else CFrame.identity),
        if portal.kind=="booth" then palette.steel else palette.trim,Enum.Material.SmoothPlastic,true)
    leaf:SetAttribute("Kind",portal.kind)
    leaf:SetAttribute("DisablePBR",true)
    leaf:SetAttribute("DoorArtVersion",2)
    -- Welded door trim moves with DoorService; never anchor detail to moving door.
    local handle=piece(leaf,"Handle",Vector3.new(0.2,0.38,0.2),
        leaf.CFrame*CFrame.new(leaf.Size.X*0.34,-0.5,-0.4),
        palette.accent,Enum.Material.Metal,false)
    handle.Anchored=false
    handle.Massless=true
    handle:SetAttribute("DisablePBR",true)
    handle.CastShadow=false
    local weld=Instance.new("WeldConstraint")
    weld.Part0=leaf
    weld.Part1=handle
    weld.Parent=handle
    local function attachment(name: string, size: Vector3, offset: Vector3,
        tint: Color3, material: Enum.Material)
        local item=piece(leaf,name,size,leaf.CFrame*CFrame.new(offset),
            tint,material,false)
        item.Anchored=false
        item.Massless=true
        item.CastShadow=false
        item:SetAttribute("DisablePBR",true)
        local joint=Instance.new("WeldConstraint")
        joint.Part0=leaf
        joint.Part1=item
        joint.Parent=item
        return item
    end
    -- Hardware moves with the real door leaf; the leaf remains the only collision hull.
    local hw=leaf.Size.X/2
    for _, y in {-2.8,2.5} do
        attachment("SteelHingePlate",Vector3.new(0.19,0.8,0.12),
            Vector3.new(-hw+0.2,y,-0.36),palette.steel,Enum.Material.Metal)
        attachment("HingeFastener",Vector3.new(0.06,0.12,0.08),
            Vector3.new(-hw+0.18,y+0.2,-0.43),palette.accent,Enum.Material.Metal)
    end
    attachment("HandleRosette",Vector3.new(0.66,0.66,0.08),
        Vector3.new(hw-1.05,-0.5,-0.34),palette.steel,Enum.Material.Metal)
    attachment("GripCylinder",Vector3.new(0.95,0.13,0.19),
        Vector3.new(hw-0.84,-0.51,-0.58),palette.accent,Enum.Material.Metal)
    -- A dedicated finishing pass gives door panels a map-specific painted,
    -- pressed-metal silhouette, without repeating the wall/wood/steel PBR
    -- across their small inset rectangles.
    FinishDetail.doorFields(leaf,mapId,portal.kind,attachment)
    if portal.kind=="booth" then
        attachment("AcousticDoorGasket",Vector3.new(leaf.Size.X-0.48,0.12,0.12),
            Vector3.new(0,4.15,-0.32),Color3.fromRGB(19,22,22),Enum.Material.SmoothPlastic)
        attachment("IsolationLabel",Vector3.new(2.2,0.5,0.07),
            Vector3.new(0,3.24,-0.34),palette.accent,Enum.Material.Metal)
    end
    return leaf
end
local function portalsForEdge(all: { Portal },axis: string,at: number,minAlong: number,maxAlong: number): { Portal }
    local found: { Portal }={}
    for _,p in all do
        if p.axis==axis and math.abs(p.at-at)<0.02 and p.along>minAlong and p.along<maxAlong then
            table.insert(found,p)
        end
    end
    table.sort(found,function(a,b)
        return a.along<b.along
    end)
    return found
end
local function wall(parent: Instance, axis: string, at: number, a: number, b: number, h: number, p: { wall: Color3, floor: Color3, ceiling: Color3, trim: Color3, steel: Color3, accent: Color3 }, portals: { Portal })
    local cursor=a
    local function segment(lo: number,hi: number,y0: number,y1: number)
        if hi-lo<0.1 or y1-y0<0.1 then return end
        if axis=="X" then
            box(parent,"SoundWall",lo,y0,at-0.6,hi,y1,at+0.6,p.wall,Enum.Material.Concrete,true)
            if y0==0 then
                box(parent,"WallDado",lo,0.14,at-0.72,hi,1.08,at-0.61,p.trim,Enum.Material.Wood,false)
            end
        else
            box(parent,"SoundWall",at-0.6,y0,lo,at+0.6,y1,hi,p.wall,Enum.Material.Concrete,true)
            if y0==0 then
                box(parent,"WallDado",at+0.61,0.14,lo,at+0.72,1.08,hi,p.trim,Enum.Material.Wood,false)
            end
        end
    end
    for _,portal in portals do
        local left=math.max(a,portal.along-portal.width/2)
        local right=math.min(b,portal.along+portal.width/2)
        segment(cursor,left,0,h)
        if portal.kind=="window" then
            -- Real observation glazing: no solid wall behind the glass, but sound is blocked.
            segment(left,right,0,4.2)
            segment(left,right,10.6,h)
            local pane: Part
            if axis=="X" then
                pane=box(parent,"AcousticObservationGlass",left,4.2,at-0.18,right,10.6,at+0.18,
                    Color3.fromRGB(112,137,142),Enum.Material.Glass,true)
                for _, y in {4.2,10.6} do
                    box(parent,"WindowHorizontalFrame",left-0.18,y-0.19,at-0.38,
                        right+0.18,y+0.19,at+0.38,p.trim,Enum.Material.Metal,false)
                end
                for _, x in {left,(left+right)/2,right} do
                    box(parent,"WindowVerticalMullion",x-0.13,4.1,at-0.4,
                        x+0.13,10.7,at+0.4,p.steel,Enum.Material.Metal,false)
                end
            else
                pane=box(parent,"AcousticObservationGlass",at-0.18,4.2,left,at+0.18,10.6,right,
                    Color3.fromRGB(112,137,142),Enum.Material.Glass,true)
                for _, y in {4.2,10.6} do
                    box(parent,"WindowHorizontalFrame",at-0.38,y-0.19,left-0.18,
                        at+0.38,y+0.19,right+0.18,p.trim,Enum.Material.Metal,false)
                end
                for _, z in {left,(left+right)/2,right} do
                    box(parent,"WindowVerticalMullion",at-0.4,4.1,z-0.13,
                        at+0.4,10.7,z+0.13,p.steel,Enum.Material.Metal,false)
                end
            end
            pane.Transparency=0.42
            pane.Reflectance=0.06
            pane:SetAttribute("AcousticGlazing",true)
        elseif portal.kind~="open" then
            segment(left,right,9,h)
            -- Fixed structural jambs are separate from the swinging leaf.
            if axis=="X" then
                for _,edge in {left,right} do
                    -- Keep jamb metal visually matte and outside the full leaf sweep.
                    local x=if edge==left then edge-0.22 else edge+0.22
                    box(parent,"SteelDoorJamb",x-0.15,0,at-0.76,
                        x+0.15,9.12,at+0.76,p.steel,Enum.Material.SmoothPlastic,false)
                end
                box(parent,"SteelDoorHead",left-0.19,9.01,at-0.76,
                    right+0.19,9.24,at+0.76,p.trim,Enum.Material.SmoothPlastic,false)
            else
                for _,edge in {left,right} do
                    local z=if edge==left then edge-0.22 else edge+0.22
                    box(parent,"SteelDoorJamb",at-0.76,0,z-0.15,
                        at+0.76,9.12,z+0.15,p.steel,Enum.Material.SmoothPlastic,false)
                end
                box(parent,"SteelDoorHead",at-0.76,9.01,left-0.19,
                    at+0.76,9.24,right+0.19,p.trim,Enum.Material.SmoothPlastic,false)
            end
        end
        cursor=right
    end
    segment(cursor,b,0,h)
end
function Kit.build(spec: Specification): Model
    local model=Instance.new("Model")
    model.Name="Map"
    model:SetAttribute("MapName",spec.name)
    model:SetAttribute("MapId",spec.id)
    model:SetAttribute("ProductionGeometry",true)
    local structure=folder("Structure",model)
    local detailFolder=folder("EnvironmentArt",model)
    local markers=folder("Markers",model)
    local areas=folder("Areas",model)
    local doors=folder("Doors",model)
    local booths=folder("Booths",model)
    local objectives=folder("Objectives",model)
    local lights=folder("PowerLights",model)
    local byName: { [string]: AreaInfo }={}
    local byCell: { [string]: boolean }={}
    local roomList: { AreaInfo }={}
    for _,r in spec.rooms do
        -- Production Blackline uses hand-authored nonuniform bounding rectangles.
        -- Radio and Foundry retain the independently validated grid fallback.
        local x1: number
        local x2: number
        local z1: number
        local z2: number
        if r.x1~=nil and r.x2~=nil and r.z1~=nil and r.z2~=nil then
            x1,x2,z1,z2=r.x1,r.x2,r.z1,r.z2
        else
            local col=assert(r.col, "Grid room has no col")
            local row=assert(r.row, "Grid room has no row")
            x1,x2=spec.x[col],spec.x[col+1]
            z1,z2=spec.z[row],spec.z[row+1]
            local key=tostring(row)..":"..tostring(col)
            assert(not byCell[key], "Duplicate room cell "..key)
            byCell[key]=true
        end
        assert(x2-x1>=22 and z2-z1>=22,"Undersized authored room "..r.name)
        local info: AreaInfo={name=r.name,role=r.role,x1=x1,x2=x2,z1=z1,z2=z2,
            height=r.height or spec.height,
            center=Vector3.new((x1+x2)/2,0,(z1+z2)/2)}
        assert(not byName[r.name], "Duplicate room name "..r.name)
        byName[r.name]=info
        table.insert(roomList,info)
    end
    local portals: { Portal }={}
    local portalsByRoom: { [string]: { Portal } }={}
    local function attach(roomName: string,p: Portal)
        if not portalsByRoom[roomName] then
            portalsByRoom[roomName]={}
        end
        table.insert(portalsByRoom[roomName],p)
    end
    for index,link in spec.links do
        local aName=link[1] :: string
        local bName=link[2] :: string
        local kind=(link[3] or "normal") :: string
        local a=assert(byName[aName],"Unknown area "..aName)
        local b=assert(byName[bName],"Unknown area "..bName)
        local axis,at,center,span
        if math.abs(a.x2-b.x1)<0.01 or math.abs(b.x2-a.x1)<0.01 then
            axis="Z"
            at=if a.x2==b.x1 then a.x2 else b.x2
            local low,high=math.max(a.z1,b.z1),math.min(a.z2,b.z2)
            span=high-low
            center=(high+low)/2
        elseif math.abs(a.z2-b.z1)<0.01 or math.abs(b.z2-a.z1)<0.01 then
            axis="X"
            at=if a.z2==b.z1 then a.z2 else b.z2
            local low,high=math.max(a.x1,b.x1),math.min(a.x2,b.x2)
            span=high-low
            center=(low+high)/2
        else
            error("Nonadjacent rooms: "..aName.."/"..bName)
        end
        local width=if kind=="open" then 14 else 8
        assert(span>=width+4,"Portal too wide for "..aName.."/"..bName)
        local portal: Portal={axis=axis,at=at,along=center,width=width,kind=kind,
            name="Passage"..tostring(index)}
        table.insert(portals,portal)
        attach(aName,portal)
        attach(bName,portal)
    end
    -- Viewing panels connect adjacent rooms visually while preserving acoustic isolation.
    for index, pair in spec.windows or {} do
        local a=assert(byName[pair[1]],"Unknown window room "..pair[1])
        local b=assert(byName[pair[2]],"Unknown window room "..pair[2])
        local axis: string
        local at: number
        local along: number
        local lo: number
        local hi: number
        if math.abs(a.z2-b.z1)<0.01 or math.abs(b.z2-a.z1)<0.01 then
            axis="X"
            at=if math.abs(a.z2-b.z1)<0.01 then a.z2 else b.z2
            lo=math.max(a.x1,b.x1)
            hi=math.min(a.x2,b.x2)
        elseif math.abs(a.x2-b.x1)<0.01 or math.abs(b.x2-a.x1)<0.01 then
            axis="Z"
            at=if math.abs(a.x2-b.x1)<0.01 then a.x2 else b.x2
            lo=math.max(a.z1,b.z1)
            hi=math.min(a.z2,b.z2)
        else
            error("Observation window must join adjacent rooms: "..pair[1].."/"..pair[2])
        end
        assert(hi-lo>=23,"Observation wall is too narrow")
        local width=9
        along=(lo+hi)/2
        for _, portal in portals do
            if portal.axis==axis and math.abs(portal.at-at)<0.01
                and portal.kind~="window" and math.abs(portal.along-along)<0.01 then
                along=hi-6.5
            end
        end
        for _, portal in portals do
            if portal.axis==axis and math.abs(portal.at-at)<0.01 then
                assert(math.abs(portal.along-along) >= (portal.width+width)/2+1,
                    "Observation glazing overlaps passage "..portal.name)
            end
        end
        table.insert(portals,{
            axis=axis,at=at,along=along,width=width,kind="window",
            name="ObservationWindow"..tostring(index),
        })
    end
    local entrance=assert(byName[spec.spawn],"Missing reception")
    local front: Portal={axis="X",at=entrance.z2,along=entrance.center.X,width=10,kind="front",name="FrontDoors"}
    table.insert(portals,front)
    attach(spec.spawn,front)
    local theme=spec.palette
    -- Build one shared wall per atomic collinear interval. This supports rooms
    -- with nonmatching lengths, while avoiding double wall faces/door occlusion.
    type WallBand = {
        axis: string, at: number, cuts: { number },
        spans: { { number } },
    }
    local wallBands: { [string]: WallBand }={}
    local function offerSide(axis: string, at: number, lo: number, hi: number, h: number)
        local key=axis..":"..tostring(at)
        local band=wallBands[key]
        if not band then
            band={axis=axis,at=at,cuts={},spans={}}
            wallBands[key]=band
        end
        table.insert(band.cuts,lo)
        table.insert(band.cuts,hi)
        table.insert(band.spans,{lo,hi,h})
    end
    for _,room in roomList do
        box(structure,room.name.."Floor",room.x1,-1,room.z1,room.x2,0,room.z2,
            theme.floor,Enum.Material.Concrete,true)
        box(structure,room.name.."Ceiling",room.x1,room.height,room.z1,
            room.x2,room.height+0.9,room.z2,theme.ceiling,Enum.Material.Concrete,true)
        offerSide("X",room.z1,room.x1,room.x2,room.height)
        offerSide("X",room.z2,room.x1,room.x2,room.height)
        offerSide("Z",room.x1,room.z1,room.z2,room.height)
        offerSide("Z",room.x2,room.z1,room.z2,room.height)

        local dir=folder(room.name,areas)
        mark(dir,"Bounds",(room.center+Vector3.new(0,room.height/2-0.5,0))).Size=Vector3.new(
            room.x2-room.x1,room.height+1,room.z2-room.z1)
        -- Keep three purposeful patrol positions clear of large equipment.
        for _,delta in {
            Vector3.new((room.x2-room.x1)*0.22,3,-(room.z2-room.z1)*0.22),
            Vector3.new(-(room.x2-room.x1)*0.22,3,(room.z2-room.z1)*0.22),
            Vector3.new((room.x2-room.x1)*0.22,3,(room.z2-room.z1)*0.22),
        } do
            mark(dir,"Spot",room.center+delta)
        end
        furnishing(room,spec,detailFolder)
        AssetLibrary.decorate(detailFolder,room.role,spec.id,room.x1,room.x2,
            room.z1,room.z2,room.height,theme)
        ArchitecturalDetail.decorate(detailFolder,spec.id,room.role,room.x1,room.x2,
            room.z1,room.z2,room.height,theme)
    end
    for _,band in wallBands do
        table.sort(band.cuts)
        for i=1,#band.cuts-1 do
            local lo=band.cuts[i]
            local hi=band.cuts[i+1]
            if hi-lo>=0.1 then
                local h=0
                for _,span in band.spans do
                    if span[1]<=lo+0.01 and span[2]>=hi-0.01 then
                        h=math.max(h,span[3])
                    end
                end
                if h>0 then
                    wall(structure,band.axis,band.at,lo,hi,h,theme,
                        portalsForEdge(portals,band.axis,band.at,lo,hi))
                end
            end
        end
    end
    local doorByName: { [string]: Part }={}
    for _,p in portals do
        if p.kind~="open" and p.kind~="window" then
            doorByName[p.name]=doorLeaf(doors,p,theme,spec.id)
        end
    end
    for _,roomName in spec.booths do
        local room=assert(byName[roomName],"Missing booth room")
        local doorName: string?=nil
        for _,p in portalsByRoom[roomName] or {} do
            if p.kind=="booth" then
                doorName=p.name
            end
        end
        assert(doorName,"Booth has no isolation door: "..roomName)
        local v=mark(booths,"Isolation_"..roomName,room.center+Vector3.new(0,room.height/2,0))
        v.Size=Vector3.new(room.x2-room.x1-1,room.height,room.z2-room.z1-1)
        v:SetAttribute("Door",doorName)
    end
    local function roomPos(name: string): Vector3
        return assert(byName[name],"Missing map role "..name).center
    end
    local spawn=mark(markers,"PlayerSpawn",roomPos(spec.spawn)+Vector3.new(0,3,-6))
    spawn.CFrame=CFrame.lookAt(spawn.Position,roomPos(spec.spawn)+Vector3.new(0,3,-13))
    mark(markers,"MonsterSpawn",roomPos(spec.monster)+Vector3.new(0,3,0))
    for _,name in spec.fuseRooms do
        local r=assert(byName[name],"Fuse area not found "..name)
        mark(markers,"FuseSpot",Vector3.new(r.center.X+7,0.25,r.center.Z+5))
    end
    for _,r in roomList do
        mark(markers,"Speaker",Vector3.new(r.center.X,r.height-2,r.center.Z))
        piece(detailFolder,"FixtureHousing_"..r.name,Vector3.new(2.8,0.32,1.2),
            CFrame.new(r.center.X,r.height-1.0,r.center.Z),theme.steel,Enum.Material.Metal,false)
        local housing=piece(lights,"FixtureLens_"..r.name,Vector3.new(2.4,0.07,0.95),
            CFrame.new(r.center.X,r.height-1.23,r.center.Z),theme.trim,Enum.Material.SmoothPlastic,false)
        housing:SetAttribute("OnColor",theme.accent)
        local spot=Instance.new("SpotLight")
        spot.Face=Enum.NormalId.Bottom
        spot.Color=theme.accent
        local hero=r.name==spec.spawn or r.name==spec.tape or r.name==spec.generator
        spot.Brightness=if hero then 1.1 else 0.72
        spot.Range=if hero then 30 else 22
        spot.Angle=100
        spot.Shadows=hero
        spot.Enabled=false
        spot.Parent=housing
        -- Real buildings retain a few low-intensity, battery-backed egress indicators.
        -- They do not participate in generator power state and cannot obscure the torch.
        if r.name==spec.spawn or r.role=="corridor" or r.name==spec.fuseBox then
            piece(detailFolder,"BatteryExitHousing",Vector3.new(2.5,0.6,0.22),
                CFrame.new(r.center.X,10.2,r.z1+1.4),theme.steel,Enum.Material.Metal,false)
            local lens=piece(detailFolder,"BatteryExitLens",Vector3.new(1.7,0.28,0.07),
                CFrame.new(r.center.X,10.2,r.z1+1.2),
                Color3.fromRGB(87,54,40),Enum.Material.Neon,false)
            local standby=Instance.new("PointLight")
            standby.Name="EmergencyBatteryLight"
            standby.Range=9
            standby.Brightness=0.14
            standby.Color=Color3.fromRGB(205,111,70)
            standby.Shadows=false
            standby.Parent=lens
        end
    end
    local g=roomPos(spec.generator)
    box(objectives,"Generator",g.X-3,0,g.Z-3,g.X+3,5,g.Z+1,theme.steel,Enum.Material.DiamondPlate,true)
    local f=roomPos(spec.fuseBox)
    box(objectives,"FuseBox",f.X+9,2.5,f.Z-2,f.X+10.6,6.5,f.Z+2,theme.steel,Enum.Material.Metal,true)
    local tape=roomPos(spec.tape)
    local tapeProxy=box(objectives,"TapeDeck",tape.X-1.6,3.2,tape.Z-2,tape.X+1.6,4.7,tape.Z+0.2,
        theme.trim,Enum.Material.Metal,true)
    if PrefabLibrary.place(detailFolder,"CassetteRecorder",CFrame.new(tape.X,4.69,tape.Z-0.8)) then
        tapeProxy.Transparency=1
    end
    -- All maps have a physically reachable outside floor and exit volume.
    local ex=roomPos(spec.spawn)
    box(structure,"FrontApron",ex.X-13,-1,entrance.z2,ex.X+13,0,entrance.z2+18,
        theme.floor,Enum.Material.Concrete,true)
    local exit=mark(objectives,"ExitZone",Vector3.new(ex.X,4,entrance.z2+9))
    exit.Size=Vector3.new(9,8,12)
    exit.CanTouch=true
    -- Import-approved PBR material variants are applied to the finished shell only.
    PBRMaterials.apply(model)
    PrefabLibrary.report()
    model.Parent=Workspace
    return model
end
return Kit
