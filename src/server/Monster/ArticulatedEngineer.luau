--!strict
-- Rigid articulated Engineer prototype, entirely cosmetic.
-- The original HumanoidRootPart, Humanoid, AI, attack distance, collision,
-- network authority and ability to hear remain untouched. The six Blender/
-- glTF-equivalent authored MeshParts are mounted on local Motor6D pivots.
-- This is not a weighted skinned mesh or a claimed production-grade animation.
local PrefabLibrary=require(script.Parent.Parent.PrefabLibrary)

local ArticulatedEngineer={}

type PieceSpec={name:string,asset:string,offset:Vector3}
local PARTS: {PieceSpec}={
    {name="RigTorso",asset="EngineerRigTorso",offset=Vector3.new(0,0,0)},
    {name="RigHead",asset="EngineerRigHead",offset=Vector3.new(0,3.70,-0.08)},
    {name="RigArmLeft",asset="EngineerRigArmLeft",offset=Vector3.new(-1.38,1.70,0)},
    {name="RigArmRight",asset="EngineerRigArmRight",offset=Vector3.new(1.38,1.70,0)},
    {name="RigLegLeft",asset="EngineerRigLegLeft",offset=Vector3.new(-0.54,-1.43,0)},
    {name="RigLegRight",asset="EngineerRigLegRight",offset=Vector3.new(0.54,-1.43,0)},
}

function ArticulatedEngineer.ready():boolean
    for _,spec in PARTS do
        if not PrefabLibrary.has(spec.asset) then
            return false
        end
    end
    return true
end

function ArticulatedEngineer.mount(model:Model,root:BasePart,glows:{PointLight}):boolean
    if not ArticulatedEngineer.ready() then
        return false
    end
    local boneByName:{[string]:BasePart}={}
    for _,spec in PARTS do
        local bone=Instance.new("Part")
        bone.Name=spec.name.."Bone"
        bone.Size=Vector3.new(.18,.18,.18)
        bone.Transparency=1
        bone.Anchored=false
        bone.CanCollide=false
        bone.CanQuery=false
        bone.CanTouch=false
        bone.CastShadow=false
        bone.Massless=true
        bone.CFrame=root.CFrame*CFrame.new(spec.offset)
        bone:SetAttribute("EngineerRigBone",true)
        bone.Parent=model
        -- Move the imported prefab with its Motor6D's visual segment,
        -- not with the server-owned navigation root.
        local success=PrefabLibrary.attach(bone,spec.asset,CFrame.identity)
        assert(success,"ArtLibrary changed while mounting "..spec.asset)
        local joint=Instance.new("Motor6D")
        joint.Name=spec.name
        joint.Part0=root
        joint.Part1=bone
        joint.C0=CFrame.new(spec.offset)
        joint.C1=CFrame.identity
        joint.Parent=root
        boneByName[spec.name]=bone
    end
    -- Migrate *existing* gameplay-controlled earcup lights to the articulated
    -- headset, while retaining the PointLight instances in MonsterService's
    -- original glows[] table (no changed brightness/lunge semantics).
    local head=assert(boneByName.RigHead,"Missing articulated head")
    for i,light in glows do
        local side=if i==1 then -1 else 1
        local host=Instance.new("Part")
        host.Name="EarcupLightHost"
        host.Size=Vector3.new(.1,.1,.1)
        host.Transparency=1
        host.Anchored=false
        host.CanCollide=false
        host.CanTouch=false
        host.CanQuery=false
        host.CastShadow=false
        host.Massless=true
        host.CFrame=head.CFrame*CFrame.new(side*1.14,0,0)
        host.Parent=model
        local weld=Instance.new("WeldConstraint")
        weld.Part0=head
        weld.Part1=host
        weld.Parent=host
        light.Parent=host
    end
    model:SetAttribute("CharacterVisualTier","ArticulatedPrototype")
    model:SetAttribute("RigVersion",1)
    return true
end

return ArticulatedEngineer
