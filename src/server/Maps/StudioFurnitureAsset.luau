--!strict
-- Reusable 1987 studio furniture, built from coherent assemblies.
-- Large form follows function; a small number of accurately fitted colliders
-- represent real seat/table/rack geometry. Cosmetic buttons, trim, seams,
-- screws and handles are visible but do not block player or AI navigation.
--
-- These heavy fixtures are intentionally ANCHORED: an installed console rack,
-- reception sofa or desk should not slide when a player walks against it.
-- Movable equipment uses StudioPhysicalAssets and actual Roblox physics.
local Furniture = {}

local C = {
	wood = Color3.fromRGB(107, 71, 48),
	woodEdge = Color3.fromRGB(166, 112, 71),
	woodDark = Color3.fromRGB(54, 40, 34),
	metal = Color3.fromRGB(82, 91, 94),
	steel = Color3.fromRGB(165, 169, 163),
	dark = Color3.fromRGB(30, 37, 40),
	black = Color3.fromRGB(22, 26, 27),
	leather = Color3.fromRGB(78, 53, 43),
	stitch = Color3.fromRGB(138, 113, 90),
	brass = Color3.fromRGB(189, 153, 95),
	paper = Color3.fromRGB(211, 197, 169),
	glow = Color3.fromRGB(132, 158, 116),
}

local function piece(
	parent: Instance, name: string, basis: CFrame, localOffset: Vector3,
	size: Vector3, color: Color3, material: Enum.Material,
	collides: boolean, shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = collides
	p.CanQuery = collides
	p.CanTouch = false
	p.CastShadow = collides
	p.Material = material
	p.Color = color
	p.Shape = shape or Enum.PartType.Block
	p.CFrame = basis * CFrame.new(localOffset)
	p.Size = size
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function cylinder(
	parent: Instance, name: string, basis: CFrame,
	offset: Vector3, radius: number, length: number,
	color: Color3, collide: boolean?
)
	-- Cylinder long axis is local X. Rotate to vertical (Y) for leg/hardware.
	local cf = basis * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90))
	local p = piece(parent, name, cf, Vector3.zero,
		Vector3.new(length, radius * 2, radius * 2), color,
		Enum.Material.Metal, collide == true, Enum.PartType.Cylinder)
	return p
end

local function assembly(parent: Instance, name: string, kind: string): Model
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("FurnitureType", kind)
	model:SetAttribute("AssetDetailVersion", 1)
	model.Parent = parent
	return model
end

-- Rectangular 1987 writing/production table: real independent tabletop,
-- four sturdy leg colliders, perimeter apron, hardwood trim, cross braces.
-- No solid filled-in middle: players can walk up to chairs and knee space.
function Furniture.table(
	parent: Instance, name: string,
	x: number, z: number, w: number, d: number,
	h: number, topColor: Color3
)
	local m = assembly(parent, name, "WorkingTable")
	local basis = CFrame.new(x, 0, z)
	local wood = Enum.Material.Wood
	local metal = Enum.Material.Metal
	piece(m, "HardwoodTopCollider", basis, Vector3.new(0,h,0),
		Vector3.new(w,0.27,d), topColor,wood,true)
	for _, sign in { -1, 1 } do
		piece(m, "LongTopBevel", basis, Vector3.new(0,h-0.17,sign*(d/2-0.09)),
			Vector3.new(w-0.15,0.075,0.15),C.woodEdge,wood,false)
		piece(m, "ShortTopBevel", basis, Vector3.new(sign*(w/2-0.09),h-0.17,0),
			Vector3.new(0.15,0.075,d-0.15),C.woodEdge,wood,false)
	end
	local legX=w/2-0.43
	local legZ=d/2-0.43
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			cylinder(m,"SolidSteelLeg",basis,Vector3.new(sx*legX,(h-0.22)/2,sz*legZ),
				0.18,h-0.22,C.metal,true)
			piece(m,"Foot",basis,Vector3.new(sx*legX,0.10,sz*legZ),
				Vector3.new(0.52,0.2,0.52),C.black,Enum.Material.Rubber,false)
		end
		piece(m,"ApronSide",basis,Vector3.new(sx*(w/2-0.20),h-0.45,0),
			Vector3.new(0.14,0.57,d-0.62),C.woodDark,wood,false)
	end
	for _, sz in { -1, 1 } do
		piece(m,"ApronFrontBack",basis,Vector3.new(0,h-0.45,sz*(d/2-0.18)),
			Vector3.new(w-0.46,0.56,0.15),C.woodDark,wood,false)
	end
	return m
end

-- Floor-supported chair with swivel post and defined seat/back collisions.
-- Not dynamic: stability and accessible prompt clearance near the desk matter.
-- Moving wheel-cases use real physics in dedicated non-critical rooms.
function Furniture.chair(parent: Instance, x: number, z: number, yaw: number, fabric: Color3?): Model
	local m=assembly(parent,"OperatorChair","StudioChair")
	local basis=CFrame.new(x,0,z)*CFrame.Angles(0,math.rad(yaw),0)
	local upholstery=fabric or C.leather
	piece(m,"SeatFrame",basis,Vector3.new(0,1.85,0),
		Vector3.new(2.66,0.32,2.65),C.metal,Enum.Material.Metal,true)
	local cushion=piece(m,"UpholsteredSeat",basis,Vector3.new(0,2.09,-0.05),
		Vector3.new(2.53,0.37,2.43),upholstery,Enum.Material.Fabric,true)
	-- A rounded front edge softens the silhouette, no block extending into path.
	piece(m,"SeatFrontRoll",basis,Vector3.new(0,2.07,-1.17),
		Vector3.new(2.45,0.33,0.32),upholstery,Enum.Material.Fabric,false)
	-- Backrest on real posts: not floating at head height.
	for _, dx in { -1.02, 1.02 } do
		cylinder(m,"BackSupport",basis,Vector3.new(dx,3.08,1.04),
			0.12,1.85,C.steel,true)
	end
	piece(m,"PaddedBack",basis,Vector3.new(0,3.35,1.14),
		Vector3.new(2.60,2.10,0.48),upholstery,Enum.Material.Fabric,true)
	piece(m,"BackPanel",basis,Vector3.new(0,3.35,1.48),
		Vector3.new(2.50,1.9,0.12),C.woodDark,Enum.Material.Wood,false)
	-- Upholstery seams and metal-adjustable height mechanisms.
	for _, dx in { -0.74, 0.74 } do
		piece(m,"SeatStitch",basis,Vector3.new(dx,2.294,0.05),
			Vector3.new(0.025,0.018,1.72),C.stitch,Enum.Material.Fabric,false)
	end
	cylinder(m,"SwivelPost",basis,Vector3.new(0,0.90,0.10),
		0.20,1.42,C.steel,true)
	cylinder(m,"SwivelCollar",basis,Vector3.new(0,0.42,0.10),
		0.30,0.18,C.metal,false)
	for _, direction in { 0, 90, 180, 270 } do
		local a=math.rad(direction)
		local cf=basis*CFrame.Angles(0,a,0)
		piece(m,"CasterFoot",cf,Vector3.new(0,0.23,-0.74),
			Vector3.new(0.29,0.19,1.44),C.metal,Enum.Material.Metal,true)
		local wheel=piece(m,"CasterWheel",cf,Vector3.new(0,0.20,-1.30),
			Vector3.new(0.19,0.32,0.32),C.black,Enum.Material.Rubber,false,
			Enum.PartType.Cylinder)
		wheel.CastShadow=false
	end
	m.PrimaryPart=cushion
	return m
end

function Furniture.sofa(parent: Instance, x: number, z: number, w: number, yaw: number): Model
	local m=assembly(parent,"WaitingRoomSofa","UpholsteredSofa")
	local basis=CFrame.new(x,0,z)*CFrame.Angles(0,math.rad(yaw),0)
	local wood=Enum.Material.Wood
	local fabric=Enum.Material.Fabric
	local seatWidth=math.max(2.5,w-1.3)
	-- Lower wooden carcass and visible sculpted upholstered seating.
	piece(m,"HardwoodLowerFrame",basis,Vector3.new(0,0.77,0.05),
		Vector3.new(w,1.25,3.36),C.woodDark,wood,true)
	piece(m,"SeatPlatform",basis,Vector3.new(0,1.49,-0.26),
		Vector3.new(seatWidth,0.24,2.72),C.wood,wood,true)
	piece(m,"SolidBack",basis,Vector3.new(0,2.49,1.41),
		Vector3.new(w,2.78,0.57),C.leather,fabric,true)
	piece(m,"BackRail",basis,Vector3.new(0,3.88,1.44),
		Vector3.new(w-0.12,0.15,0.60),C.wood,wood,false)
	for _, sx in { -1, 1 } do
		piece(m,"SolidArm",basis,Vector3.new(sx*(w/2-0.39),1.94,0),
			Vector3.new(0.75,1.25,3.36),C.wood,wood,true)
		piece(m,"ArmCushion",basis,Vector3.new(sx*(w/2-0.39),2.65,-0.06),
			Vector3.new(0.61,0.24,2.66),C.leather,fabric,false)
	end
	local segments=if w>6 then 3 else 2
	for i=1,segments do
		local sw=seatWidth/segments
		local dx=-seatWidth/2+(i-0.5)*sw
		piece(m,"SeatCushion",basis,Vector3.new(dx,1.85,-0.29),
			Vector3.new(sw-0.06,0.52,2.44),C.leather,fabric,true)
		piece(m,"BackPillow",basis,Vector3.new(dx,2.73,1.00),
			Vector3.new(sw-0.09,1.62,0.28),C.leather,fabric,false)
		piece(m,"Piping",basis,Vector3.new(dx,2.14,-1.44),
			Vector3.new(sw-0.16,0.035,0.05),C.stitch,fabric,false)
	end
	for _, sx in { -1,1 } do
		for _, sz in { -1,1 } do
			piece(m,"FloorFoot",basis,Vector3.new(sx*(w/2-0.5),0.17,sz*1.22),
				Vector3.new(0.4,0.35,0.4),C.woodDark,wood,true)
		end
	end
	return m
end

-- Rack bodies are continuous, installed collision assets. All panels/rivets
-- are cosmetic so sight rays do not hit invisible "floating details".
function Furniture.rack(
	parent: Instance, name: string,
	x: number, z: number, width: number, height: number, yaw: number
): Model
	local m=assembly(parent,name,"AnalogueRack")
	local basis=CFrame.new(x,0,z)*CFrame.Angles(0,math.rad(yaw),0)
	local metal=Enum.Material.Metal
	piece(m,"RackChassisCollider",basis,Vector3.new(0,height/2,0),
		Vector3.new(width,height,1.75),C.dark,metal,true)
	piece(m,"InlaidRackFace",basis,Vector3.new(0,height/2,-0.906),
		Vector3.new(width-0.28,height-0.26,0.075),C.black,metal,false)
	for _, dx in { -width/2+0.13,width/2-0.13 } do
		piece(m,"ExtrudedRail",basis,Vector3.new(dx,height/2,-0.99),
			Vector3.new(0.18,height-0.16,0.17),C.steel,metal,false)
		for i=1,math.floor(height/1.1) do
			local y=0.24+i*1.04
			local screw=piece(m,"RackScrew",basis,Vector3.new(dx,y,-1.10),
				Vector3.new(0.10,0.10,0.05),C.brass,metal,false,
				Enum.PartType.Ball)
			screw.CastShadow=false
		end
	end
	local units=math.floor((height-0.55)/1.05)
	for j=1,units do
		local y=0.16+j*1.03
		piece(m,"RemovableOutboardUnit",basis,Vector3.new(0,y,-1.00),
			Vector3.new(width-0.5,0.79,0.12),
			if j%3==0 then C.metal else C.dark,metal,false)
		-- One large knob and a justified signal meter per module.
		cylinder(m,"Potentiometer",basis*CFrame.Angles(math.rad(90),0,0),
			Vector3.new(-width/2+0.8,1.13,y),0.16,0.15,C.steel,false)
		piece(m,"SignalWindow",basis,Vector3.new(width*0.18,y,-1.077),
			Vector3.new(0.52,0.16,0.04),
			if j%4==0 then C.brass else C.glow,
			Enum.Material.Glass,false)
		for k=1,3 do
			piece(m,"VentSlot",basis,Vector3.new(width/2-0.72,y-0.19+k*0.12,-1.08),
				Vector3.new(0.65,0.025,0.04),C.black,metal,false)
		end
	end
	piece(m,"RackFoot",basis,Vector3.new(0,0.17,0.2),
		Vector3.new(width-0.12,0.34,1.65),C.black,metal,true)
	return m
end

return Furniture
