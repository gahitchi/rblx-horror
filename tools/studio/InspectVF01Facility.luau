-- Blackline VF-01: non-destructive objective-linked facility status audit.
-- Run from the SERVER Command Bar during Play (F5).
-- Re-run at power-off, generator-on, fuses-complete, tape-playing and unlocked.
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local ServerScriptService=game:GetService("ServerScriptService")
assert(RunService:IsRunning(),"Start F5 Play before running facility diagnostics")
local map=assert(Workspace:FindFirstChild("Map"),"Workspace.Map missing")
assert(map:GetAttribute("MapId")=="studio","This diagnostic is Blackline-only")
local folder=assert(map:FindFirstChild("FacilitySystems"),"FacilitySystems missing")
local roundState=require(assert(ServerScriptService:FindFirstChild("Server")):WaitForChild("RoundState"))
local Config=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local power=roundState.get("PowerOn")==true
local fuses=roundState.get("FusesPlaced") or 0
local broadcasting=roundState.get("TapeProgress") or 0
local released=roundState.get("DoorsOpen")==true
local expected=if not power then "Dead"
    else if released then "Released"
    else if broadcasting>0 then "Broadcast"
    else if fuses>=Config.FUSES_NEEDED then "Routed"
    else "Powered"
local actual=map:GetAttribute("FacilityPhase")
local errors=0
local number=0
for _,name in {"Reception","StaffGallery","ControlA","LiveHall"} do
    local node=folder:FindFirstChild("VF01_"..name)
    if not node or not node:IsA("Model") then
        warn("[VF01] Missing status instrument: "..name)
        errors+=1
        continue
    end
    number+=1
    local status=node:FindFirstChild("SignalStatus",true)
    local note=node:FindFirstChild("OperatorNote",true)
    local glass=node:FindFirstChild("InsetSignalGlass",true)
    local lens=node:FindFirstChild("CircuitLens",true)
    local state=node:GetAttribute("FacilityPhase")
    if not status or not status:IsA("TextLabel")
        or not note or not note:IsA("TextLabel")
        or not glass or not glass:IsA("BasePart")
        or not lens or not lens:IsA("BasePart") then
        warn("[VF01] Incomplete display geometry or labels: "..name)
        errors+=1
        continue
    end
    if state~=actual then
        warn("[VF01] Station state mismatch: "..name.." "..tostring(state))
        errors+=1
    end
    if lens.CanCollide or lens.CanQuery or glass.CanCollide or glass.CanQuery then
        warn("[VF01] Cosmetic display alters player / sound collision: "..name)
        errors+=1
    end
    print(("[VF01] %s: %s / %s / %s"):format(name,
        tostring(state),status.Text,note.Text))
end
if number~=4 or actual~=expected then
    warn("[VF01] Expected "..expected.."; displayed "..tostring(actual))
    errors+=1
end
print(("[VF01] %d instruments; %d errors; Power=%s; Fuses=%d/%d; Tape=%.2f; Exit=%s"):format(
    number,errors,tostring(power),fuses,Config.FUSES_NEEDED,
    broadcasting,tostring(released)))
if broadcasting==0 and expected=="Routed" then
    print("[VF01] During the first instant of playback, tape progression may still be 0; rerun after its first alarm interval")
end
print("[VF01] Repeat after each real objective transition. Visual readability, FPS and screenshots still require client inspection.")
