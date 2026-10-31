--!strict
-- Shared architectural grid and explicit doors. No navigation changes require monster scripts.
-- Intentionally multiple loops with two remote dead ends on the upper edge.
local Layouts={}

local baseLinks: { { number | string } } = {}
local function ref(row: number,col: number): string
    return tostring(row)..":"..tostring(col)
end
local function add(a: string,b: string,kind: string?)
    table.insert(baseLinks,{a,b,kind or "normal"})
end
-- The north-west and north-east rooms terminate at their isolation/vault exits.
for col=1,3 do
    if col~=2 then add(ref(1,col),ref(1,col+1)) end
end
for row=2,5 do
    for col=1,3 do
        add(ref(row,col),ref(row,col+1),if (row==2 or row==4) and col==2 then "open" else "normal")
    end
end
for _,entry in { {1,2}, {1,4}, {2,1}, {2,3}, {2,4}, {3,1}, {3,2}, {3,3},
    {4,1},{4,2},{4,3},{4,4} } do
    add(ref(entry[1],entry[2]),ref(entry[1]+1,entry[2]))
end

local function make(spec: any)
    local rooms={}
    local namesByCell: { [string]: string }={}
    for row, names in spec.names do
        for col,name in names do
            local role=spec.roles[row][col]
            table.insert(rooms,{name=name,role=role,row=row,col=col})
            namesByCell[ref(row,col)]=name
        end
    end
    local links={}
    for _,link in baseLinks do
        local one=namesByCell[link[1] :: string]
        local two=namesByCell[link[2] :: string]
        local kind=link[3] :: string
        if spec.booths[one] or spec.booths[two] then
            kind="booth"
        end
        table.insert(links,{one,two,kind})
    end
    local booths={}
    for name,enabled in spec.booths do if enabled then table.insert(booths,name) end end
    return {
        id=spec.id,name=spec.name,palette=spec.palette,rooms=rooms,links=links,
        x=spec.x,z=spec.z,height=spec.height,booths=booths,
        fuseRooms=spec.fuseRooms,generator=spec.generator,fuseBox=spec.fuseBox,
        tape=spec.tape,spawn=spec.spawn,monster=spec.monster,
    }
end
function Layouts.studio()
    return make({
        id="studio",name="Blackline Recording Complex",height=14,
        x={-70,-35,0,35,70},z={-170,-136,-102,-68,-34,0},
        palette={
            wall=Color3.fromRGB(67,68,69),floor=Color3.fromRGB(73,60,51),
            ceiling=Color3.fromRGB(35,38,40),trim=Color3.fromRGB(44,39,38),
            steel=Color3.fromRGB(65,70,71),accent=Color3.fromRGB(214,157,110),
        },
        names={
            {"IsolationWest","MasteringVault","IsolationEast","TapeArchive"},
            {"DrumRoom","LiveHall","TrackingStage","Maintenance"},
            {"Rehearsal","ControlA","ControlB","Transfer"},
            {"Dressing","LongGallery","EquipmentSpine","PatchBay"},
            {"GeneratorPlant","StaffBreak","Reception","LoadingDock"},
        },
        roles={
            {"booth","master","booth","archive"},
            {"live","live","stage","machine"},
            {"live","control","control","store"},
            {"lounge","corridor","corridor","machine"},
            {"generator","lounge","reception","store"},
        },
        booths={IsolationWest=true,IsolationEast=true},
        fuseRooms={"MasteringVault","TapeArchive","DrumRoom","TrackingStage","Rehearsal",
            "ControlB","Maintenance","Transfer","Dressing","PatchBay","LoadingDock","StaffBreak"},
        generator="GeneratorPlant",fuseBox="PatchBay",tape="ControlA",
        spawn="Reception",monster="TapeArchive",
    })
end
function Layouts.radio()
    return make({
        id="radio",name="Wavelength Broadcast Station",height=13,
        x={-64,-32,0,32,64},z={-160,-128,-96,-64,-32,0},
        palette={
            wall=Color3.fromRGB(73,79,81),floor=Color3.fromRGB(49,59,62),
            ceiling=Color3.fromRGB(33,38,44),trim=Color3.fromRGB(27,40,43),
            steel=Color3.fromRGB(52,72,77),accent=Color3.fromRGB(136,190,193),
        },
        names={
            {"OffAirBooth","MagneticLibrary","IsolationStudio","TransmitterVault"},
            {"Newsroom","HallwayArchive","TalkStudio","BroadcastRack"},
            {"EditBay","MasterControl","LiveBroadcast","EquipmentWorkshop"},
            {"Dressing","AdminPassage","EngineeringLink","Service"},
            {"GeneratorRoom","StaffKitchen","Reception","LoadingBay"},
        },
        roles={
            {"booth","archive","booth","machine"},
            {"lounge","archive","broadcast","machine"},
            {"control","control","broadcast","machine"},
            {"lounge","corridor","corridor","store"},
            {"generator","lounge","reception","store"},
        },
        booths={OffAirBooth=true,IsolationStudio=true},
        fuseRooms={"MagneticLibrary","TransmitterVault","Newsroom","TalkStudio","BroadcastRack",
            "MasterControl","EditBay","Service","Dressing","EquipmentWorkshop","LoadingBay"},
        generator="GeneratorRoom",fuseBox="Service",tape="MasterControl",
        spawn="Reception",monster="TransmitterVault",
    })
end
function Layouts.foundry()
    return make({
        id="foundry",name="Ashbell Industrial Foundry",height=18,
        x={-80,-40,0,40,80},z={-200,-160,-120,-80,-40,0},
        palette={
            wall=Color3.fromRGB(76,70,65),floor=Color3.fromRGB(65,62,57),
            ceiling=Color3.fromRGB(35,36,37),trim=Color3.fromRGB(42,40,37),
            steel=Color3.fromRGB(77,75,69),accent=Color3.fromRGB(218,117,62),
        },
        names={
            {"PatternVault","SandMixing","BellTesting","ToolDepot"},
            {"FurnaceAnnex","CastingFloor","PouringBay","CraneGallery"},
            {"MoldWorkshop","Inspection","CastingControl","HammerShop"},
            {"CompressorRoom","ServiceGallery","QualityLab","Stores"},
            {"GeneratorHouse","StaffMess","Gatehouse","Receiving"},
        },
        roles={
            {"mold","machine","stage","store"},
            {"boiler","machine","machine","corridor"},
            {"machine","master","control","machine"},
            {"machine","corridor","control","store"},
            {"generator","lounge","reception","store"},
        },
        booths={},
        fuseRooms={"PatternVault","SandMixing","BellTesting","ToolDepot","CastingFloor",
            "FurnaceAnnex","Inspection","HammerShop","CompressorRoom","QualityLab","Receiving"},
        generator="GeneratorHouse",fuseBox="QualityLab",tape="CastingControl",
        spawn="Gatehouse",monster="ToolDepot",
    })
end
return Layouts
