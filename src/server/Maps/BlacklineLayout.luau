--!strict
-- Blackline: nonuniform, deliberately connected recording facility.
-- Built around a 24-stud-high live hall, public reception, observation gallery,
-- isolated recording wings and a service loop. Coordinates are authored;
-- these are not randomly placed or the shared five-by-four map grid.
local Blackline = {}

function Blackline.make()
    local rooms={
        {name="IsolationWest",role="booth",x1=-116,x2=-72,z1=-192,z2=-160,height=14},
        {name="MasteringVault",role="master",x1=-72,x2=-24,z1=-192,z2=-160,height=14},
        {name="TapeArchive",role="archive",x1=-24,x2=30,z1=-192,z2=-160,height=15},
        {name="IsolationEast",role="booth",x1=30,x2=84,z1=-192,z2=-160,height=14},
        {name="DrumRoom",role="live",x1=-116,x2=-72,z1=-160,z2=-128,height=17},
        {name="ViewingGallery",role="corridor",x1=-72,x2=30,z1=-160,z2=-128,height=18},
        {name="ServiceGallery",role="corridor",x1=30,x2=84,z1=-160,z2=-128,height=17},
        {name="ControlA",role="control",x1=-116,x2=-72,z1=-128,z2=-94,height=16},
        {name="LiveHall",role="live",x1=-72,x2=30,z1=-128,z2=-60,height=24},
        {name="TrackingStage",role="stage",x1=30,x2=84,z1=-128,z2=-94,height=19},
        {name="ControlB",role="control",x1=-116,x2=-72,z1=-94,z2=-60,height=16},
        {name="PatchBay",role="machine",x1=30,x2=84,z1=-94,z2=-60,height=17},
        {name="StaffPassage",role="corridor",x1=-116,x2=-72,z1=-60,z2=-30,height=15},
        {name="StaffGallery",role="corridor",x1=-72,x2=30,z1=-60,z2=-30,height=18},
        {name="Maintenance",role="machine",x1=30,x2=84,z1=-60,z2=-30,height=17},
        {name="Lounge",role="lounge",x1=-116,x2=-72,z1=-30,z2=0,height=15},
        {name="Reception",role="reception",x1=-72,x2=30,z1=-30,z2=0,height=20},
        {name="GeneratorRoom",role="generator",x1=30,x2=84,z1=-30,z2=0,height=18},
        {name="LoadingDock",role="store",x1=30,x2=84,z1=0,z2=34,height=17},
    }
    -- An edge means a traversable portal, not merely two rooms touching.
    -- Acoustic booths are deliberate one-door dead ends, whereas the public,
    -- technical and production wings have independently useful return loops.
    local links={
        {"IsolationWest","MasteringVault","booth"},
        {"MasteringVault","TapeArchive"},
        {"TapeArchive","IsolationEast","booth"},
        {"MasteringVault","ViewingGallery"},
        {"TapeArchive","ViewingGallery"},
        {"DrumRoom","ViewingGallery"},
        {"ViewingGallery","ServiceGallery"},
        {"DrumRoom","ControlA"},
        {"ViewingGallery","LiveHall","open"},
        {"ServiceGallery","TrackingStage"},
        {"ControlA","LiveHall"},
        {"ControlB","LiveHall"},
        {"LiveHall","TrackingStage","open"},
        {"LiveHall","PatchBay"},
        {"ControlA","ControlB"},
        {"TrackingStage","PatchBay"},
        {"ControlB","StaffPassage"},
        {"LiveHall","StaffGallery","open"},
        {"PatchBay","Maintenance"},
        {"StaffPassage","StaffGallery"},
        {"StaffGallery","Maintenance"},
        {"StaffPassage","Lounge"},
        {"StaffGallery","Reception","open"},
        {"Maintenance","GeneratorRoom"},
        -- Fire-rated plant access from the public entry: a real emergency/service
        -- alternative, not a second invented corridor or a teleport.
        {"Reception","GeneratorRoom"},
        {"Lounge","Reception"},
        {"GeneratorRoom","LoadingDock"},
    }
    return {
        id="studio",
        name="Blackline Recording Complex",
        authored=true,
        height=17,
        x={},z={},
        rooms=rooms,links=links,
        windows={
            {"ControlA","LiveHall"},
            {"ControlB","LiveHall"},
            {"ViewingGallery","LiveHall"},
        },
        booths={"IsolationWest","IsolationEast"},
        fuseRooms={"MasteringVault","TapeArchive","DrumRoom","TrackingStage",
            "ViewingGallery","ControlB","Maintenance","PatchBay",
            "StaffPassage","Lounge","ServiceGallery","LoadingDock"},
        generator="GeneratorRoom",fuseBox="PatchBay",tape="ControlA",
        spawn="Reception",monster="TapeArchive",
        palette={
            wall=Color3.fromRGB(67,68,69),floor=Color3.fromRGB(73,60,51),
            ceiling=Color3.fromRGB(35,38,40),trim=Color3.fromRGB(44,39,38),
            steel=Color3.fromRGB(65,70,71),accent=Color3.fromRGB(214,157,110),
        },
    }
end

return Blackline
