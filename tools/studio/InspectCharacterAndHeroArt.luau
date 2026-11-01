-- Non-destructive Roblox Studio health probe for the segmented Engineer rig,
-- four hero rooms and optional player operator equipment.
-- Run the entire file in the SERVER Command Bar while F5 Play is running.
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")
local Players=game:GetService("Players")
assert(RunService:IsRunning(),"Run this during Play mode (F5), server Command Bar")
local library=ServerStorage:FindFirstChild("ArtLibrary")
local required={
    "EngineerRigTorso","EngineerRigHead",
    "EngineerRigArmLeft","EngineerRigArmRight",
    "EngineerRigLegLeft","EngineerRigLegRight",
}
local absent={}
for _,name in required do
    if not library or not library:FindFirstChild(name) then
        table.insert(absent,name)
    end
end
if #absent>0 then
    warn("[ART QA] Segmented Engineer rig not installed: "..table.concat(absent,", "))
    print("[ART QA] Existing Engineer / rigid-body fallback remains supported.")
else
    print("[ART QA] All six segmented Engineer GLBs present in ArtLibrary")
end
local monster=Workspace:FindFirstChild("Monster")
if not monster or not monster:IsA("Model") then
    warn("[ART QA] Engineer has not spawned yet; resume after its arrival")
else
    local root=monster:FindFirstChild("HumanoidRootPart")
    local joints=0
    if root and root:IsA("BasePart") then
        for _,name in {"RigTorso","RigHead","RigArmLeft","RigArmRight",
                        "RigLegLeft","RigLegRight"} do
            local motor=root:FindFirstChild(name)
            if motor and motor:IsA("Motor6D") and motor.Part0==root
                and motor.Part1 and motor.Part1.CanCollide==false then
                joints+=1
            else
                warn("[ART QA] Joint absent or invalid: "..name)
            end
        end
        if root.Anchored then
            warn("[ART QA] Monster root anchored: server pathfinding cannot walk normally")
        end
    end
    local glows=0
    local collidingImported=0
    for _,part in monster:GetDescendants() do
        if part:IsA("PointLight") then
            glows+=1
        elseif part:IsA("BasePart") and part~=root and part.CanCollide then
            collidingImported+=1
        end
    end
    print(("[ART QA] Engineer visual tier=%s, joints=%d/6, PointLights=%d, solid accessory parts=%d"):format(
        tostring(monster:GetAttribute("CharacterVisualTier")),joints,glows,collidingImported))
    if joints==6 and monster:GetAttribute("RigVersion")==1 then
        print("[ART QA] Articulated body assembled. Verify MOVEMENT on a client:"
            .." roaming -> listening -> hunt -> lunge.")
    end
end
for _,player in Players:GetPlayers() do
    local character=player.Character
    if character then
        print(("[ART QA] Player %s: %s, optional visuals=%s"):format(
            player.Name,tostring(character:GetAttribute("DeadAirAppearanceStatus")),
            tostring(character:GetAttribute("DeadAirAppearancePieces"))))
    end
end
local map=Workspace:FindFirstChild("Map")
if map and map:GetAttribute("MapId")=="studio" then
    local details=map:FindFirstChild("Details")
    local count=0
    if details then
        for _,child in details:GetDescendants() do
            if child:IsA("BasePart") and child:GetAttribute("ArtPass")=="BlacklineHero01" then
                count+=1
                if child.CanCollide or child.CanQuery then
                    warn("[ART QA] Hero decorative geometry changed gameplay: "..child.Name)
                end
            end
        end
    end
    print("[ART QA] Blackline hero-pass noncolliding detail Parts: "..count)
end
print("[ART QA] SOURCE CHECK COMPLETE; FPS, animation clipping, visual grade and acoustics need manual playtesting.")
