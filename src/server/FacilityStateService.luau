--!strict
-- VF-01: deterministic visual projection of the *existing* round objectives.
-- Not a second gameplay state machine. No timers, fabricated power states,
-- fake sound emitters, extra checkpoints, or changes to player/monster AI.
-- Four authored Blackline stations change together because all observe the
-- same real generator, fuse, tape and exit state.
local FacilityStateService={}

type View={node:Model,status:TextLabel,note:TextLabel,lens:BasePart}
type Appearance={status:string,note:string}

local VIEWS:{[string]:View}={}
local map:Instance?=nil
local NODES={
    Reception=true,StaffGallery=true,ControlA=true,LiveHall=true,
}
local COPY:{[string]:{[string]:Appearance}}={
    Reception={
        Dead={status="LOCKED / EMERGENCY",note="EXIT BUS AWAITING AUTHORIZATION"},
        Powered={status="SERVICE POWER",note="EXIT RELEASE STILL INTERLOCKED"},
        Routed={status="SIGNAL ROUTED",note="EMERGENCY PLAYBACK REQUIRED"},
        Broadcast={status="EVACUATION / PENDING",note="BROADCAST CONFIRMATION ACTIVE"},
        Released={status="EGRESS RELEASED",note="FRONT DOORS AUTHORIZED"},
    },
    StaffGallery={
        Dead={status="DISTRIBUTION ISOLATED",note="NO FACILITY SUPPLY"},
        Powered={status="SERVICE BUS AVAILABLE",note="PATCH CIRCUIT INCOMPLETE"},
        Routed={status="DISTRIBUTION READY",note="CONTROL A MAY TRANSMIT"},
        Broadcast={status="P.A. / LIVE FEED",note="MASTER SIGNAL DISTRIBUTING"},
        Released={status="DISTRIBUTION STANDBY",note="EMERGENCY PROGRAM COMPLETE"},
    },
    ControlA={
        Dead={status="MASTER BUS OFFLINE",note="REQUIRES GENERATOR SUPPLY"},
        Powered={status="CHANNEL 08 / NO PATCH",note="RESTORE PATCH DISTRIBUTION"},
        Routed={status="MASTER BUS ARMED",note="EMERGENCY TAPE AVAILABLE"},
        Broadcast={status="CHANNEL 08 / ON AIR",note="PROGRAM TRANSMISSION ACTIVE"},
        Released={status="MASTER TAPE COMPLETE",note="FRONT EGRESS RELEASED"},
    },
    LiveHall={
        Dead={status="STUDIO ISOLATED",note="PROGRAM BUS DISCONNECTED"},
        Powered={status="STUDIO POWER ONLINE",note="PROGRAM FEED STILL ISOLATED"},
        Routed={status="PROGRAM FEED READY",note="WAITING FOR MASTER TAPE"},
        Broadcast={status="EMERGENCY AUDIO / LIVE",note="MASTER SIGNAL ON P.A. CIRCUIT"},
        Released={status="PROGRAM ENDED",note="STUDIO RETURNS TO STANDBY"},
    },
}
local COLORS:{[string]:Color3}={
    Dead=Color3.fromRGB(80,78,72),
    Powered=Color3.fromRGB(138,112,62),
    Routed=Color3.fromRGB(77,131,123),
    Broadcast=Color3.fromRGB(146,65,57),
    Released=Color3.fromRGB(102,135,94),
}

local function phase(power:boolean,fuses:number,broadcast:boolean,exitReleased:boolean,
    needed:number):string
    if not power then return "Dead" end
    if exitReleased then return "Released" end
    if broadcast then return "Broadcast" end
    if fuses>=needed then return "Routed" end
    return "Powered"
end

function FacilityStateService.init(sourceMap:Instance)
    VIEWS={}
    map=nil
    if sourceMap:GetAttribute("MapId")~="studio" then
        return
    end
    local folder=sourceMap:FindFirstChild("FacilitySystems")
    if not folder or not folder:IsA("Folder") then
        return
    end
    local found=0
    for _,item in folder:GetChildren() do
        if not item:IsA("Model") then continue end
        local id=item:GetAttribute("FacilityCircuit")
        if type(id)~="string" or not NODES[id] then continue end
        local status=item:FindFirstChild("SignalStatus",true)
        local note=item:FindFirstChild("OperatorNote",true)
        local lens=item:FindFirstChild("CircuitLens",true)
        if not status or not status:IsA("TextLabel")
            or not note or not note:IsA("TextLabel")
            or not lens or not lens:IsA("BasePart") then
            warn("[Dead Air] VF01 facility status station incomplete: "..id)
            continue
        end
        VIEWS[id]={node=item,status=status,note=note,lens=lens}
        found+=1
    end
    if found~=4 then
        warn("[Dead Air] VF01: expected four Blackline stations, found "..tostring(found))
    end
    map=sourceMap
end

function FacilityStateService.render(power:boolean,fuses:number,broadcast:boolean,
    exitReleased:boolean,needed:number)
    local target=map
    if not target or target.Parent==nil then
        return
    end
    local current=phase(power,fuses,broadcast,exitReleased,needed)
    if target:GetAttribute("FacilityPhase")==current then
        return -- fully idempotent and avoids reassigning Gui state on each fuse event
    end
    target:SetAttribute("FacilityPhase",current)
    local color=COLORS[current]
    for id,view in VIEWS do
        local copy=COPY[id][current]
        view.status.Text=copy.status
        view.note.Text=copy.note
        view.status.TextColor3=color
        view.lens.Material=if current=="Dead" then Enum.Material.SmoothPlastic
            else Enum.Material.Neon
        view.lens.Color=color
        view.node:SetAttribute("FacilityPhase",current)
    end
    print("[Dead Air] Blackline facility: "..current)
end

return FacilityStateService
