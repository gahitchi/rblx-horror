-- Q02 read-only Studio reality check for the NEW human/CC0 Last Listener.
-- Run F5 Play, Server Command Bar. No gameplay / scene changes.
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")
local ServerStorage=game:GetService("ServerStorage")
assert(RunService:IsRunning(),"Enter Play before inspecting Engineer")
local m=Workspace:FindFirstChild("Monster")
assert(m and m:IsA("Model"),"No active Monster; use a map with Engineer")
local root=assert(m:FindFirstChild("HumanoidRootPart"),"HRP missing")
assert(root:IsA("BasePart"),"Invalid HRP")
local human=assert(m:FindFirstChildOfClass("Humanoid"),"Humanoid missing")
local art=ServerStorage:FindFirstChild("ArtLibrary")
local source=art and art:FindFirstChild("EngineerSkinned")
local found=root:FindFirstChild("EngineerSkinned")
local issues=0
local function bad(x)
    issues+=1
    warn("[LastListener Q02] FAIL: "..x)
end
if root.Size~=Vector3.new(2,2,1) then
    bad("Gameplay root dimensions changed")
end
if human.HipHeight~=3 then
    bad("Monster root HipHeight changed")
end
local lights=0
for _,d in m:GetDescendants() do
    if d:IsA("PointLight") then lights+=1 end
end
if lights~=2 then
    bad("Expected exactly two existing warning PointLights")
end
if source==nil then
    warn("[LastListener Q02] New GLB missing from ServerStorage.ArtLibrary."..
        " Old character fallback is active until manual Studio import.")
elseif found==nil then
    bad("New import exists but not attached; verify skinned Bone names.")
else
    local bones,meshes,surfaces,blocking=0,0,0,0
    for _,d in found:GetDescendants() do
        if d:IsA("Bone") then
            bones+=1
        elseif d:IsA("BasePart") then
            if d.CanCollide or d.CanQuery or d.CanTouch then blocking+=1 end
            if d:IsA("MeshPart") then
                meshes+=1
                if d:FindFirstChildOfClass("SurfaceAppearance") then
                    surfaces+=1
                end
            end
        end
    end
    if blocking>0 then bad("Cosmetic mesh interferes with movement or raycasts") end
    if bones<15 then bad("Imported GLB lost required 15 bone names") end
    if surfaces==0 then bad("PBR texture maps not imported") end
    if m:GetAttribute("CharacterVisualTier")~="Q02AnatomicalTechnicianCC0" then
        bad("Wrong visual tier / stale Engineered placeholder installed")
    end
    print("[LastListener Q02] MeshParts",meshes,"PBR MeshParts",surfaces,
        "Bones",bones,"Blocked Parts",blocking)
end
print("[LastListener Q02] Visual and lighting review still needed:")
print("Face 3/12/25 studs, ears headset, neck seam, hands, cuff folds,")
print("idle/listen/hunt/lunge deformations; lights off/on; real fps tests")
print("[LastListener Q02] Check complete. Problems:",issues)
