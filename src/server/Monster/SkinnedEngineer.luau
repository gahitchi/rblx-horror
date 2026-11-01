--!strict
-- Import-gated, genuinely weighted Engineer. Bone verification is mandatory.
-- Only replaces visuals: never replaces HumanoidRootPart, AI, hitbox, sounds,
-- earcup glow instances, navigation, animation networking or fallback geometry.
local PrefabLibrary=require(script.Parent.Parent.PrefabLibrary)

local SkinnedEngineer={}
local REQUIRED={
    "Spine","Neck","Head",
    "LeftShoulder","LeftElbow","LeftWrist",
    "RightShoulder","RightElbow","RightWrist",
    "LeftHip","LeftKnee","LeftAnkle",
    "RightHip","RightKnee","RightAnkle",
}

function SkinnedEngineer.ready():boolean
    return PrefabLibrary.hasBones("EngineerSkinned",REQUIRED)
end

function SkinnedEngineer.mount(model:Model,root:BasePart,glows:{PointLight}):boolean
    if not SkinnedEngineer.ready() then
        return false
    end
    -- PrefabLibrary welds the visual MeshParts only; imported Bone instances
    -- remain inside each MeshPart and retain their skinning weights.
    if not PrefabLibrary.attach(root,"EngineerSkinned",CFrame.identity) then
        return false
    end
    local imported=root:FindFirstChild("EngineerSkinned")
    if not imported then
        return false
    end
    local head=imported:FindFirstChild("Head",true)
    if not head or not head:IsA("Bone") then
        imported:Destroy()
        return false
    end
    -- Distinguish the NEW 33-section anatomical source from the previously
    -- installed 10-section prototype. The installer never replaces existing
    -- ArtLibrary items automatically; prevent false Q02 claims and preserve
    -- previous ear locations when users have not yet imported new GLBs.
    local sourceMeshCount=0
    for _,d in imported:GetDescendants() do
        if d:IsA("MeshPart") then sourceMeshCount+=1 end
    end
    local q02Anatomical=sourceMeshCount>=28
    -- The same two PointLights remain referenced by MonsterService.glows.
    -- Parenting them under Attachments on the moving Head Bone follows
    -- skin motion while preserving alert / lunge brightness controls.
    for index,light in glows do
        local attachment=Instance.new("Attachment")
        attachment.Name=if index==1 then "LeftEarcupEmitter"
            else "RightEarcupEmitter"
        attachment.Position=if q02Anatomical then Vector3.new(if index==1 then -0.47 else 0.47,-0.01,0.05)
            else Vector3.new(if index==1 then -1.13 else 1.13,0,-0.04)
        attachment.Parent=head
        light.Parent=attachment
    end
    model:SetAttribute("CharacterVisualTier",if q02Anatomical
        then "Q02AnatomicalTechnicianCC0" else "WeightedSkinPrototype")
    if q02Anatomical then
        model:SetAttribute("VisualDesign","BlacklineLastListenerAnatomical")
    end
    model:SetAttribute("RigVersion",2)
    model:SetAttribute("SkinBoneCount",#REQUIRED)
    return true
end

return SkinnedEngineer
