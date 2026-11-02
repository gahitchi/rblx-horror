--!strict
-- Developer-only Match place SERVER Command Bar test, run during Play.
-- No props are moved; checks construction and gameplay-object preservation.
local map=workspace:WaitForChild("Map")
local props=map:WaitForChild("Props")
local objectives=map:WaitForChild("Objectives")
local counts: {[string]:number}={}
local families: {[string]:number}={}
for _,item in props:GetDescendants() do
	counts[item.Name]=(counts[item.Name] or 0)+1
	if item:IsA("Model") then
		local typ=item:GetAttribute("FurnitureType")
		if type(typ)=="string" then
			families[typ]=(families[typ] or 0)+1
		end
	end
end
local function check(ok: boolean, message: string)
	assert(ok,"[Asset pass] "..message)
end
for _,stale in {"JanitorShelf","MopBucket","Staff_Toilet","Visitor_Toilet",
	"Staff_Sink","Visitor_Sink","MachineRackFace","TapeStatusMeter",
	"ReelGuide","MicrophoneStand","PaperFiling","PatchCable","SafeDial"} do
	check(not counts[stale],"Duplicate or unmounted legacy prop: "..stale)
end
check((families.GalleryBench or 0)==4,"Four gallery benches required")
check((families.StorageCabinet or 0)>=1,"Editing archive cabinet missing")
check((families.WorkingTable or 0)>=3,"Real supported worktables missing")
check((counts.SolidBenchLeg or 0)==16,"Benches must have sixteen actual legs")
check((counts.PatchSocket or 0)==32,"PatchBay must have four rows of jacks")
check((counts.PatchCordLeft or 0)==3 and (counts.PatchCordRight or 0)==3,
	"Signal patch cords must be connected to the panel")
check((counts.SafeSteelDoor or 0)==1 and (counts.SafeCombinationWheel or 0)==1,
	"Safe missing one credible mechanical face")
check((counts.CabinetDoor or 0)==2,"Control B filing cabinet lacks two doors")
check((counts.DrawerFace or 0)==4,"Archive CardIndex drawer faces missing")
check((counts.InsetDoor or 0)==2,"Spares objective cabinet finish missing")
check((counts.CeramicBase or 0)==2 and (counts.SinkBasin or 0)==2,
	"Exactly one washroom fixture set per bathroom required")
check((counts.MusicStandStem or 0)==1 and (counts.PopFilterArm or 0)==1,
	"Isolation booth equipment not grounded")
check((counts.GoboFloorFoot or 0)==4,"Tracking screens need real feet")
local reel=props:FindFirstChild("AnodizedTapeSpool",true)
check(reel~=nil and (counts.AnodizedTapeSpool or 0)==2,
	"Control A tape transport must have exactly two reels")
for _,key in {"BookingDiary","SessionLog","TapeMachine","MixingDesk",
	"PatchBay","Safe","CardIndex","Spares","MemorialProgramme","RoadCase"} do
	local part=objectives:FindFirstChild(key)
	check(part and part:IsA("BasePart"),"Authoritative objective missing: "..key)
end
for _,name in {"ToiletTank","SinkBasin","GalleryBench_-3"} do
	check(props:FindFirstChild(name,true)~=nil,"Missing "..name)
end
print("[Asset pass] PASS: reusable furniture, room-specific controls, no duplicate placeholders")
print("[Asset pass] Manual: player collision, hiding clearance, Engineer pathing, visual support and mobile performance")
