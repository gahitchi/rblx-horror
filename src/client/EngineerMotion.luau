--!strict
-- Purely visual client-side animation of the Engineer's segmented cosmetic rig.
-- We never move HumanoidRootPart or change collision, pathfinding, AI or attacks.
-- Motor6D.Transform is evaluated every PreSimulation frame for smooth blending;
-- Roblox's default Humanoid networking/rig ownership remains authoritative.
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")

local EngineerMotion={}
type Joints={torso:Motor6D,head:Motor6D,leftArm:Motor6D,rightArm:Motor6D,
    leftLeg:Motor6D,rightLeg:Motor6D}
type Subject={model:Model,root:BasePart,joints:Joints,phase:number,breath:number}
local subjects:{[Model]:Subject}={}

local function joint(root:BasePart,name:string):Motor6D?
    local obj=root:FindFirstChild(name)
    return if obj and obj:IsA("Motor6D") then obj else nil
end

local function register(model:Model)
    if model.Name~="Monster" or model:GetAttribute("RigVersion")~=1 then
        return
    end
    if subjects[model] then return end
    local root=model:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return end
    local torso=joint(root,"RigTorso")
    local head=joint(root,"RigHead")
    local leftArm=joint(root,"RigArmLeft")
    local rightArm=joint(root,"RigArmRight")
    local leftLeg=joint(root,"RigLegLeft")
    local rightLeg=joint(root,"RigLegRight")
    if not torso or not head or not leftArm or not rightArm
        or not leftLeg or not rightLeg then return end
    subjects[model]={
        model=model,root=root,phase=0,breath=0,
        joints={torso=torso,head=head,leftArm=leftArm,rightArm=rightArm,
            leftLeg=leftLeg,rightLeg=rightLeg},
    }
end

local function update(subject:Subject,dt:number)
    local root=subject.root
    local model=subject.model
    local v=root.AssemblyLinearVelocity
    local speed=Vector3.new(v.X,0,v.Z).Magnitude
    local state=model:GetAttribute("State")
    local aggressive=state=="Hunt"
    local listening=state=="Listen"
    local searching=state=="Search" or state=="Investigate"
    local lunging=model:GetAttribute("Lunging")==true
    local moving=math.clamp((speed-1.5)/9,0,1)
    subject.phase+=dt*(3.0+math.min(speed,20)*0.42)
    subject.breath+=dt*(if aggressive then 2.4 else 1.1)
    local swing=math.sin(subject.phase)*moving
    local counter=math.cos(subject.phase)*moving
    local armSwing=(if aggressive then .62 else .27)*swing
    local legSwing=.48*swing
    local idle=math.sin(subject.breath)*.022
    -- Distinct poses communicate its AI state before the player sees any UI.
    local hunch=if lunging then .52 else if aggressive then .27 else .10
    local neckPitch=if listening then -.20 else if lunging then -.31
        else if aggressive then -.17 else .025
    local yaw=if listening or searching then math.sin(subject.breath*.71)*.25
        else math.sin(subject.breath*.40)*.035
    local reach=if lunging then -.94 else if aggressive then -.42 else .075
    local targetTorso=CFrame.new(0,idle,0)*CFrame.Angles(hunch,0,-.045*counter)
    local targetHead=CFrame.Angles(neckPitch, yaw, math.sin(subject.breath*.62)*.03)
    local targetLA=CFrame.Angles(reach+armSwing,0,
        if listening then -.19 else .08)
    local targetRA=CFrame.Angles(reach-armSwing,0,
        if listening then .19 else -.08)
    local targetLL=CFrame.Angles(-legSwing,0,.025*counter)
    local targetRL=CFrame.Angles(legSwing,0,-.025*counter)
    if speed<1.5 then
        targetLL=CFrame.Angles(0,0,0)
        targetRL=CFrame.Angles(0,0,0)
    end
    local alpha=1-math.exp(-math.min(dt,.08)*(if lunging then 15 else 9))
    local j=subject.joints
    j.torso.Transform=j.torso.Transform:Lerp(targetTorso,alpha)
    j.head.Transform=j.head.Transform:Lerp(targetHead,alpha)
    j.leftArm.Transform=j.leftArm.Transform:Lerp(targetLA,alpha)
    j.rightArm.Transform=j.rightArm.Transform:Lerp(targetRA,alpha)
    j.leftLeg.Transform=j.leftLeg.Transform:Lerp(targetLL,alpha)
    j.rightLeg.Transform=j.rightLeg.Transform:Lerp(targetRL,alpha)
end

function EngineerMotion.start()
    for _,child in Workspace:GetChildren() do
        if child:IsA("Model") then register(child) end
    end
    Workspace.ChildAdded:Connect(function(child)
        if not child:IsA("Model") then return end
        -- The model is parented after its rig is built, but replicate timing
        -- can deliver its attributes after ChildAdded on the client.
        register(child)
        child:GetAttributeChangedSignal("RigVersion"):Connect(function()
            register(child)
        end)
    end)
    RunService.PreSimulation:Connect(function(dt:number)
        for model,subject in subjects do
            if model.Parent==nil then
                subjects[model]=nil
            else
                update(subject,dt)
            end
        end
    end)
end

return EngineerMotion
