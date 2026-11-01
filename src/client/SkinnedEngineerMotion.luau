--!strict
-- Client-only animation for imported *weighted skinned* Engineer GLB.
-- Bone.Transform moves vertex-weighted surface; server AI root/hitbox stays
-- authoritative. No external AnimationIds or purchased movement assets.
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")

local SkinnedEngineerMotion={}
type Subject={model:Model,root:BasePart,bones:{[string]:{Bone}},stride:number,breath:number}
local active:{[Model]:Subject}={}

local REQUIRED={
    "Spine","Neck","Head",
    "LeftShoulder","LeftElbow","LeftWrist",
    "RightShoulder","RightElbow","RightWrist",
    "LeftHip","LeftKnee","LeftAnkle",
    "RightHip","RightKnee","RightAnkle",
}

local function register(model:Model)
    if model.Name~="Monster" or model:GetAttribute("RigVersion")~=2
        or active[model]~=nil then return end
    local root=model:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart") then return end
    local found:{[string]:{Bone}}={}
    for _,name in REQUIRED do
        found[name]={}
    end
    -- glTF's multi-material scene may import one skinned MeshPart per primitive.
    -- Drive all matching names, not only the first Bone returned in Explorer.
    local imported=root:FindFirstChild("EngineerSkinned")
    if not imported then return end
    for _,child in imported:GetDescendants() do
        if child:IsA("Bone") and found[child.Name] then
            table.insert(found[child.Name],child)
        end
    end
    for _,name in REQUIRED do
        if #found[name]==0 then return end
    end
    active[model]={model=model,root=root,bones=found,stride=0,breath=0}
end

local function apply(subject:Subject,name:string,pose:CFrame,alpha:number)
    for _,bone in subject.bones[name] do
        bone.Transform=bone.Transform:Lerp(pose,alpha)
    end
end

local function animate(subject:Subject,dt:number)
    local root=subject.root
    local m=subject.model
    local velocity=root.AssemblyLinearVelocity
    local speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
    local state=m:GetAttribute("State")
    local listening=state=="Listen"
    local hunting=state=="Hunt"
    local searching=state=="Search" or state=="Investigate"
    local lunging=m:GetAttribute("Lunging")==true
    local motion=math.clamp((speed-1.0)/9.0,0,1)
    subject.stride+=dt*(2.6+math.min(speed,20)*.38)
    subject.breath+=dt*(if hunting then 2.2 else .97)
    local step=math.sin(subject.stride)*motion
    local breath=math.sin(subject.breath)
    local counter=math.cos(subject.stride)*motion
    local alpha=1-math.exp(-math.min(dt,.06)*(if lunging then 16 else 9))
    local hunch=if lunging then .42 else if hunting then .24 else .07
    local scan=if searching or listening then math.sin(subject.breath*.8)*.28
        else math.sin(subject.breath*.4)*.03
    local reach=if lunging then -1.02 else if hunting then -.38 else .08
    local stride=.52*step
    apply(subject,"Spine",
        CFrame.new(0,breath*.018,0)*CFrame.Angles(hunch,0,counter*.035),alpha)
    apply(subject,"Neck",
        CFrame.Angles(if listening then -.15 else -.02,scan*.41,0),alpha)
    apply(subject,"Head",
        CFrame.Angles(if lunging then -.30 else if listening then -.22 else -.03,
            scan,math.sin(subject.breath*.5)*.035),alpha)
    apply(subject,"LeftShoulder",
        CFrame.Angles(reach+.50*step,0,if listening then -.14 else .07),alpha)
    apply(subject,"RightShoulder",
        CFrame.Angles(reach-.50*step,0,if listening then .14 else -.07),alpha)
    apply(subject,"LeftElbow",
        CFrame.Angles(if lunging then -.47 else if hunting then -.26 else -.12,
            0,-.03),alpha)
    apply(subject,"RightElbow",
        CFrame.Angles(if lunging then -.47 else if hunting then -.26 else -.12,
            0,.03),alpha)
    apply(subject,"LeftWrist",CFrame.Angles(.12+breath*.025,0,-.10),alpha)
    apply(subject,"RightWrist",CFrame.Angles(.12+breath*.025,0,.10),alpha)
    apply(subject,"LeftHip",CFrame.Angles(-stride,0,counter*.025),alpha)
    apply(subject,"RightHip",CFrame.Angles(stride,0,-counter*.025),alpha)
    apply(subject,"LeftKnee",
        CFrame.Angles(math.max(0,stride)*.51,0,0),alpha)
    apply(subject,"RightKnee",
        CFrame.Angles(math.max(0,-stride)*.51,0,0),alpha)
    apply(subject,"LeftAnkle",CFrame.Angles(-math.max(0,stride)*.26,0,0),alpha)
    apply(subject,"RightAnkle",CFrame.Angles(-math.max(0,-stride)*.26,0,0),alpha)
end

function SkinnedEngineerMotion.start()
    local observed:{[Model]:boolean}={}
    local function observe(child:Instance)
        if not child:IsA("Model") or child.Name~="Monster" then return end
        if observed[child] then return end
        observed[child]=true
        register(child)
        child:GetAttributeChangedSignal("RigVersion"):Connect(function()
            register(child)
        end)
        child.DescendantAdded:Connect(function()
            if not active[child] then
                register(child)
            end
        end)
    end
    for _,child in Workspace:GetChildren() do
        observe(child)
    end
    Workspace.ChildAdded:Connect(observe)
    Workspace.ChildRemoved:Connect(function(child)
        if child:IsA("Model") then
            active[child]=nil
            observed[child]=nil
        end
    end)
    RunService.PreSimulation:Connect(function(dt:number)
        for model,subject in active do
            if model.Parent==nil then
                active[model]=nil
            else
                animate(subject,dt)
            end
        end
    end)
end

return SkinnedEngineerMotion
