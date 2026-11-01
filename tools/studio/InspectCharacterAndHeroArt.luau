-- Non-destructive Roblox Studio health probe for the weighted or segmented Engineer rig,
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
if library then
    local weighted=library:FindFirstChild("EngineerSkinned")
    local n=0
    if weighted then
        for _,descendant in weighted:GetDescendants() do
            if descendant:IsA("Bone") then
                n+=1
            end
        end
    end
    print("[ART QA] Optional weighted Engineer imported Bones: "..n
        .." (require all 15 animation joints to activate)")
end
local monster=Workspace:FindFirstChild("Monster")
if not monster or not monster:IsA("Model") then
    warn("[ART QA] Engineer has not spawned yet; resume after its arrival")
else
    local root=monster:FindFirstChild("HumanoidRootPart")
    local tier=monster:GetAttribute("CharacterVisualTier")
    local version=monster:GetAttribute("RigVersion")
    local joints=0
    local expected=if version==2 then 15 else 6
    if root and root:IsA("BasePart") then
        if version==2 then
            local imported=root:FindFirstChild("EngineerSkinned")
            local found={}
            if imported then
                for _,child in imported:GetDescendants() do
                    if child:IsA("Bone") then
                        found[child.Name]=true
                    end
                end
            end
            for _,name in {
                "Spine","Neck","Head",
                "LeftShoulder","LeftElbow","LeftWrist",
                "RightShoulder","RightElbow","RightWrist",
                "LeftHip","LeftKnee","LeftAnkle",
                "RightHip","RightKnee","RightAnkle",
            } do
                if found[name] then
                    joints+=1
                else
                    warn("[ART QA] Weighted Bone missing: "..name)
                end
            end
        elseif version==1 then
            for _,name in {"RigTorso","RigHead","RigArmLeft","RigArmRight",
                            "RigLegLeft","RigLegRight"} do
                local motor=root:FindFirstChild(name)
                if motor and motor:IsA("Motor6D") and motor.Part0==root
                    and motor.Part1 and motor.Part1.CanCollide==false then
                    joints+=1
                else
                    warn("[ART QA] Motor6D missing or invalid: "..name)
                end
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
    print(("[ART QA] Engineer tier=%s; rig=%s; joints=%d/%d; PointLights=%d; solid accessory parts=%d"):format(
        tostring(tier),tostring(version),joints,expected,glows,collidingImported))
    if version==2 and joints==15 then
        print("[ART QA] Weighted skeleton present in Studio. Verify bending,"
            .." bone transforms and actual motion from a CLIENT, not server.")
    elseif version==1 and joints==6 then
        print("[ART QA] Segmented fallback ready. Verify roaming/listening/hunt animation on client.")
    elseif version==nil then
        print("[ART QA] Procedural or rigid fallback active (no imported animation rig).")
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
    local details=map:FindFirstChild("EnvironmentArt")
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
