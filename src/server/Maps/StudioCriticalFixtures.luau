--!strict
-- Visible mechanisms for two chapter-critical objects. This file never
-- replaces the original collidable Objectives; ProximityPrompts and all
-- chapter state stay attached to those same BaseParts.
local Kit = require(script.Parent.StudioDecorKit)
local C = Kit.palette
local Details = {}

local function mountedFace(parent: Instance, name: string,
	body: BasePart, inset: number, color: Color3): Part
	return Kit.box(parent,name,body.Position.X,body.Position.Y,
		body.Position.Z+body.Size.Z/2+inset,body.Size.X-0.22,
		body.Size.Y-0.25,0.085,color,Enum.Material.Metal)
end

local function patchbay(parent: Instance, body: BasePart)
	local face=body.Position.Z+body.Size.Z/2
	mountedFace(parent,"PatchPanelFace",body,0.05,C.dark)
	for row=1,4 do
		local y=body.Position.Y-1.63+(row-1)*0.98
		Kit.box(parent,"PatchRackStrip",body.Position.X,y,face+0.12,
			3.62,0.53,0.12,C.metal,Enum.Material.Metal)
		for col=1,8 do
			local x=body.Position.X-1.54+(col-1)*0.44
			local jack=Kit.box(parent,"PatchSocket",x,y,face+0.205,
				0.18,0.18,0.07,C.steel,Enum.Material.Metal)
			jack.Shape=Enum.PartType.Ball
		end
	end
	-- Three patch cords connect actual panel sockets. Their middle
	-- segments dip under their own weight rather than hovering in air.
	for _, pair in {{-1.32,-0.44},{0.0,1.32},{-0.44,0.88}} do
		local x0=body.Position.X+pair[1]
		local x1=body.Position.X+pair[2]
		local y0=body.Position.Y-0.65
		local y1=body.Position.Y+0.33
		local cableZ=face+0.29
		local droop=math.min(y0,y1)-0.62
		local mid=(x0+x1)/2
		Kit.rod(parent,"PatchCordLeft",
			Vector3.new(x0,y0,cableZ),Vector3.new(mid,droop,cableZ+0.22),
			0.085,C.gold)
		Kit.rod(parent,"PatchCordRight",
			Vector3.new(mid,droop,cableZ+0.22),Vector3.new(x1,y1,cableZ),
			0.085,C.gold)
		for _, coord in {{x0,y0},{x1,y1}} do
			Kit.box(parent,"PatchPlug",coord[1],coord[2],cableZ,
				0.17,0.17,0.22,C.black,Enum.Material.Metal)
		end
	end
	Kit.sign(parent,"LINE / TAPE / BUS",CFrame.new(body.Position.X,
		body.Position.Y+2.1,face+0.15),Vector3.new(3.4,0.27,0.07),
		Enum.NormalId.Front,C.cream,C.dark)
end

local function safe(parent: Instance, body: BasePart)
	local front=body.Position.Z+body.Size.Z/2
	mountedFace(parent,"SafeSteelDoor",body,0.065,C.metal)
	for _, x in {body.Position.X-body.Size.X/2+0.22,
		body.Position.X+body.Size.X/2-0.22} do
		Kit.box(parent,"SafeDoorSideTrim",x,body.Position.Y,front+0.16,
			0.11,body.Size.Y-0.3,0.12,C.steel,Enum.Material.Metal)
	end
	for _, y in {body.Position.Y-1.15,body.Position.Y+1.15} do
		Kit.box(parent,"SafeHinge",body.Position.X-1.72,y,front+0.19,
			0.28,0.58,0.25,C.black,Enum.Material.Metal)
	end
	Kit.disc(parent,"SafeCombinationWheel",body.Position.X,
		body.Position.Y+0.3,front+0.26,1.2,0.18,C.steel)
	Kit.disc(parent,"SafeCombinationHub",body.Position.X,
		body.Position.Y+0.3,front+0.39,0.47,0.1,C.dark)
	for i=1,8 do
		local a=2*math.pi*i/8
		Kit.box(parent,"SafeDialMark",
			body.Position.X+math.cos(a)*0.47,
			body.Position.Y+0.3+math.sin(a)*0.47,front+0.385,
			0.065,0.065,0.06,C.gold,Enum.Material.Metal)
	end
	Kit.rod(parent,"SafeDoorLever",
		Vector3.new(body.Position.X+1.07,body.Position.Y-0.48,front+0.30),
		Vector3.new(body.Position.X+1.07,body.Position.Y+0.65,front+0.30),
		0.14,C.steel)
	Kit.sign(parent,"STAFF / MASTER",CFrame.new(body.Position.X,
		body.Position.Y-1.67,front+0.24),Vector3.new(2.8,0.42,0.07),
		Enum.NormalId.Front,C.paper,C.dark)
end

function Details.apply(map: Model)
	local objectives=map:FindFirstChild("Objectives")
	local props=map:FindFirstChild("Props")
	assert(objectives and props,"Critical equipment needs objectives and props")
	local root=Kit.group(props,"CriticalEquipmentFinishing")
	local patch=objectives:FindFirstChild("PatchBay")
	local vault=objectives:FindFirstChild("Safe")
	assert(patch and patch:IsA("BasePart"),"Missing authoritative PatchBay")
	assert(vault and vault:IsA("BasePart"),"Missing authoritative Safe")
	patchbay(root,patch)
	safe(root,vault)
	root:SetAttribute("Purpose","1987 signal routing and staff master security")
end

return Details
