-- Q02 The Last Listener: SERVER Command Bar, F5 Play, read-only Studio probe.
-- Run with the updated imported EngineerSkinned after saving old ArtLibrary
-- assets as backups elsewhere. This script never edits gameplay or lighting.
local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
assert(RunService:IsRunning(),"Enter Play (F5) and use SERVER Command Bar")
local MONSTER=Workspace:FindFirstChild("Monster")
assert(MONSTER and MONSTER:IsA("Model"),"Engineer Monster has not spawned")
local root=assert(MONSTER:FindFirstChild("HumanoidRootPart"),"Root missing")
assert(root:IsA("BasePart"),"Invalid root")
local humanoid=assert(MONSTER:FindFirstChildOfClass("Humanoid"),"Humanoid missing")
local library=ServerStorage:FindFirstChild("ArtLibrary")
local source=library and library:FindFirstChild("EngineerSkinned")
local errors=0
local function fail(msg:string)
    errors+=1
    warn("[Engineer Q02] FAIL: "..msg)
end
if root.Size~=Vector3.new(2,2,1) then
    fail("AI/hitbox root dimensions were changed")
end
if humanoid.HipHeight~=3 then
    fail("original navigation root height was changed")
end
local glows=0
for _,d in MONSTER:GetDescendants() do
    if d:IsA("PointLight") then
        glows+=1
    end
end
if glows~=2 then
    fail("expected exactly two preserved earcup warning lights")
end
if source==nil then
    warn("[Engineer Q02] No skinned Engineer in ArtLibrary: old fallback is visible.")
else
    local imported=root:FindFirstChild("EngineerSkinned")
    if imported==nil then
        warn("[Engineer Q02] Imported model exists but not attached. "..
            "Review required named Bones, R15 glTF import and old ArtLibrary copy.")
    else
        local bones=0
        local meshes=0
        local pbr=0
        local blocked=0
        for _,d in imported:GetDescendants() do
            if d:IsA("Bone") then bones+=1 end
            if d:IsA("BasePart") then
                if d.CanCollide or d.CanQuery or d.CanTouch then
                    blocked+=1
                end
                if d:IsA("MeshPart") then
                    meshes+=1
                    if d:FindFirstChildOfClass("SurfaceAppearance") then
                        pbr+=1
                    end
                end
            end
        end
        if blocked>0 then fail("imported body changed navigation or raycasts") end
        if bones<15 then fail("weighted source lost required 15-bone structure") end
        if pbr<2 then fail("real embedded material maps missing") end
        local size
        if imported:IsA("Model") then
            local _,extent=imported:GetBoundingBox()
            size=extent
        elseif imported:IsA("BasePart") then
            size=imported.Size
        else
            fail("imported Engineer is neither a Model nor a BasePart")
        end
        if size and (size.Y<7.5 or size.Y>8.9 or size.X>4.2) then
            fail("new human-scale silhouette did not survive source pivot import: "..tostring(size))
        end
        print(("[Engineer Q02] Weighted visual: %d meshes, %d PBR meshes, "..
            "%d bones, size %s"):format(meshes,pbr,bones,tostring(size)))
    end
end
print("[Engineer Q02] Visual tier: ",MONSTER:GetAttribute("CharacterVisualTier"))
print("[Engineer Q02] Design version: ",MONSTER:GetAttribute("VisualDesign"))
print("[Engineer Q02] Check first person 3/12/25 studs, face and headset, "..
    "standing/Listen/Investigate/Hunt transitions, idle wrists, clipping "..
    "in doorways, flashlight off/on, graphics medium/high, real frame times.")
print("[Engineer Q02] Read-only checks complete. Errors:",errors)
