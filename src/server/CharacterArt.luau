--!strict
-- The game-specific field technician silhouette. Approved models are imported
-- through Studio into ServerStorage.ArtLibrary. All 3 assets are *cosmetic*:
-- they never replace Roblox's R15 skeleton, camera, footsteps or hit detection.
-- The player's current Roblox avatar persists if the additional art is absent.
local PrefabLibrary=require(script.Parent.PrefabLibrary)

local CharacterArt={}

function CharacterArt.apply(character: Model, inRound: boolean): number
    if not inRound or character:GetAttribute("DeadAirAppearanceApplied")==true then
        return 0
    end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.RigType~=Enum.HumanoidRigType.R15 then
        -- R6 or custom rigs retain their original visual appearance. We do not
        -- deform/sculpt arbitrary users' avatars or risk breaking animation.
        character:SetAttribute("DeadAirAppearanceStatus","DefaultAvatar")
        return 0
    end
    local torso=character:FindFirstChild("UpperTorso")
    local head=character:FindFirstChild("Head")
    if not torso or not torso:IsA("BasePart")
        or not head or not head:IsA("BasePart") then
        character:SetAttribute("DeadAirAppearanceStatus","MissingR15Parts")
        return 0
    end
    -- Scales and appearance are owned by Roblox avatar. We only weld approved
    -- lightweight vest/respirator/pack visuals to the existing animated parts.
    -- All cloned MeshParts are massless, non-solid and non-queryable.
    local count=0
    if PrefabLibrary.attach(torso,"FieldOperatorVest",CFrame.identity) then
        count+=1
    end
    if PrefabLibrary.attach(torso,"FieldOperatorPack",CFrame.identity) then
        count+=1
    end
    if PrefabLibrary.attach(head,"FieldOperatorMask",CFrame.identity) then
        count+=1
    end
    character:SetAttribute("DeadAirAppearanceApplied",true)
    character:SetAttribute("DeadAirAppearancePieces",count)
    character:SetAttribute("DeadAirAppearanceStatus",
        if count==3 then "ImportedCosmeticPrototype" else "PartialOrDefault")
    return count
end

return CharacterArt
