--!strict
-- Deliberate, material-specific finishing for surfaces seen close to the player.
-- No new uploaded textures or IDs are required. All finish pieces are decorative;
-- gameplay collision remains on the original stable invisible proxy Parts.
-- Our art direction avoids globally tiled rust/wood PBR on small door fields and desks.

local FinishDetail = {}

type Palette = {
    wall: Color3, floor: Color3, ceiling: Color3,
    trim: Color3, steel: Color3, accent: Color3,
}
type Finish = {
    case: Color3, front: Color3, inset: Color3, edge: Color3,
    worktop: Color3, endGrain: Color3, hardware: Color3,
}

local FINISHES: { [string]: Finish } = {
    studio = {
        case=Color3.fromRGB(42,43,44),
        front=Color3.fromRGB(58,55,52),
        inset=Color3.fromRGB(49,48,46),
        edge=Color3.fromRGB(83,77,68),
        worktop=Color3.fromRGB(58,54,51),
        endGrain=Color3.fromRGB(76,68,60),
        hardware=Color3.fromRGB(113,104,94),
    },
    radio = {
        case=Color3.fromRGB(36,46,50),
        front=Color3.fromRGB(49,60,63),
        inset=Color3.fromRGB(39,51,55),
        edge=Color3.fromRGB(77,91,93),
        worktop=Color3.fromRGB(49,57,58),
        endGrain=Color3.fromRGB(67,80,81),
        hardware=Color3.fromRGB(99,117,120),
    },
    foundry = {
        case=Color3.fromRGB(49,48,45),
        front=Color3.fromRGB(65,62,57),
        inset=Color3.fromRGB(54,53,49),
        edge=Color3.fromRGB(90,84,74),
        worktop=Color3.fromRGB(66,65,59),
        endGrain=Color3.fromRGB(85,79,69),
        hardware=Color3.fromRGB(126,107,84),
    },
}

local function colors(mapId: string): Finish
    return FINISHES[mapId] or FINISHES.studio
end

local function shape(parent: Instance, name: string, size: Vector3, cf: CFrame,
    tint: Color3, material: Enum.Material?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Color = tint
    p.Material = material or Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    -- Prevent global wall/wood/metal tiling from corrupting these deliberately
    -- low-frequency painted and laminated surfaces.
    p:SetAttribute("DisablePBR",true)
    p.Parent = parent
    return p
end

-- All door detail is attached through Kit's welded Part factory.
-- The root door is always the single collision/audio leaf; no separate moving physics.
function FinishDetail.doorFields(leaf: BasePart, mapId: string, kind: string,
    attach: (string, Vector3, Vector3, Color3, Enum.Material) -> Part)
    local f = colors(mapId)
    local w = leaf.Size.X
    local face = if kind=="booth" then Color3.fromRGB(43,45,44) else f.front
    local field = if kind=="booth" then Color3.fromRGB(33,36,36) else f.inset
    local rim = if kind=="booth" then Color3.fromRGB(64,65,61) else f.edge

    for _, side in {-1,1} do
        -- Two shallow stamped recesses, not generic high-frequency wooden/rusty tiles.
        -- Depth is in local door coordinates: shell faces at +/-0.275 studs.
        for _, panel in {
            { y=1.55, height=2.14 },
            { y=-2.02, height=2.77 },
        } do
            local h=panel.height
            local y=panel.y
            attach("PressedFieldBacking",Vector3.new(w-1.26,h+0.16,0.09),
                Vector3.new(0,y,side*0.330),rim,Enum.Material.SmoothPlastic)
            attach("PressedField",Vector3.new(w-1.54,h-0.10,0.08),
                Vector3.new(0,y,side*0.415),field,Enum.Material.SmoothPlastic)
            -- Short, low-contrast wear occurs at physical boundaries rather than
            -- covering the whole panel with obviously repeated photographic rust.
            attach("InsetShadowLine",Vector3.new(w-1.60,0.075,0.025),
                Vector3.new(0,y+h/2-0.11,side*0.461),f.case,Enum.Material.SmoothPlastic)
        end
        -- Thin pressed crown, middle stiffener and bottom kick are visible from afar.
        for _,y in {3.06,-0.16,-3.83} do
            attach("PressedCrossmember",Vector3.new(w-0.68,0.15,0.115),
                Vector3.new(0,y,side*0.405),face,Enum.Material.SmoothPlastic)
        end
        for _,x in {-w/2+0.39,w/2-0.39} do
            attach("PressedStile",Vector3.new(0.15,8.08,0.10),
                Vector3.new(x,0,side*0.39),face,Enum.Material.SmoothPlastic)
        end
        -- An understated metal identification plate belongs above the panel,
        -- not as a brightly glowing rectangle in the middle of the door.
        attach("DoorNumberBlank",Vector3.new(0.84,0.25,0.045),
            Vector3.new(-w/2+1.12,3.67,side*0.40),f.hardware,Enum.Material.SmoothPlastic)
    end
end

-- This facade lies inside the original counter collision hull. Decorative pieces
-- are deliberately less prominent than the worktop and never obstruct walkways.
function FinishDetail.counter(parent: Instance,mapId: string,style: string,
    x1: number,z1: number,x2: number,z2: number,height: number,palette: Palette)
    local f=colors(mapId)
    local cx=(x1+x2)/2
    local cz=(z1+z2)/2
    local w=x2-x1
    local d=z2-z1
    local face=z2-0.15
    local baseHeight=height-0.30

    -- Recessed kick and narrow steel ground runner create a clear shadow break.
    shape(parent,"CounterShadowKick",Vector3.new(w-0.58,0.41,0.12),
        CFrame.new(cx,0.29,z2-0.50),f.case)
    shape(parent,"CounterToeRunner",Vector3.new(w-0.55,0.09,0.14),
        CFrame.new(cx,0.11,z2-0.44),f.hardware,Enum.Material.Metal)

    -- Structural shell and two return panels, instead of a giant wood-patterned box.
    shape(parent,"CounterFrontFacade",Vector3.new(w-0.48,baseHeight-0.58,0.18),
        CFrame.new(cx,(baseHeight+0.62)/2,face),f.front)
    for _,x in {x1+0.19,x2-0.19} do
        shape(parent,"CounterEndReturn",Vector3.new(0.21,baseHeight-0.45,d-0.66),
            CFrame.new(x,(baseHeight+0.57)/2,cz),f.case)
    end
    shape(parent,"CounterRearPanel",Vector3.new(w-0.54,baseHeight-0.65,0.11),
        CFrame.new(cx,(baseHeight+0.65)/2,z1+0.15),f.case)

    -- Restrained drawer and access-panel seams are visible at human scale.
    local n=if style=="reception" then 3 else 2
    for i=1,n do
        local center=x1+(i-0.5)*w/n
        shape(parent,"CounterAccessField",Vector3.new(w/n-0.48,1.25,0.04),
            CFrame.new(center,baseHeight-0.89,z2-0.031),f.inset)
        shape(parent,"CounterAccessLip",Vector3.new(w/n-0.65,0.055,0.05),
            CFrame.new(center,baseHeight-0.19,z2-0.006),f.edge)
        if i<n then
            shape(parent,"CounterVerticalJoint",Vector3.new(0.045,baseHeight-0.74,0.042),
                CFrame.new(x1+i*w/n,(baseHeight+0.61)/2,z2-0.017),f.case)
        end
    end

    -- Low-sheen laminate / powder coat replaces broad rusty-steel and repeated
    -- oak texture on tabletops. Layered edge banding preserves the physical feel.
    local worktop=if style=="reception" then f.worktop else f.case
    shape(parent,"CounterWorktop",Vector3.new(w+0.52,0.23,d+0.54),
        CFrame.new(cx,height+0.15,cz),worktop)
    shape(parent,"CounterEdgeBand",Vector3.new(w+0.54,0.11,0.085),
        CFrame.new(cx,height+0.105,z2+0.283),f.endGrain)
    for _,x in {x1-0.26,x2+0.26} do
        shape(parent,"CounterEndBand",Vector3.new(0.08,0.11,d+0.54),
            CFrame.new(x,height+0.105,cz),f.endGrain)
    end
    -- Subtle dark cable-management groove near the back of a control desk.
    if style=="control" then
        shape(parent,"ConsoleCableChannel",Vector3.new(w-1.0,0.025,0.12),
            CFrame.new(cx,height+0.276,z1+0.52),f.inset)
    end
    -- Small counters use the same material family as their corresponding map.
    -- Do not use a white/light emissive stripe: the flashlight should define form.
    if style=="reception" then
        for _,x in {x1+0.7,x2-0.7} do
            shape(parent,"CounterCornerGuard",Vector3.new(0.09,baseHeight-0.51,0.14),
                CFrame.new(x,(baseHeight+0.58)/2,z2-0.025),palette.steel)
        end
    end
end

return FinishDetail
