--!strict
-- Real Roblox MeshParts cannot have MeshId assigned by ordinary runtime scripts.
-- Keep approved imported assets in ServerStorage/ArtLibrary, with their MeshIds,
-- UVs and SurfaceAppearances already resolved by Studio's 3D Importer.
-- This module clones and places those prefabs without touching gameplay collision.
local ServerStorage = game:GetService("ServerStorage")

local PrefabLibrary = {}

local warned: { [string]: boolean } = {}

local function sourceFor(name: string): PVInstance?
    local root = ServerStorage:FindFirstChild("ArtLibrary")
    if not root then
        return nil
    end
    local source = root:FindFirstChild(name)
    if source and (source:IsA("Model") or source:IsA("BasePart")) then
        return source
    end
    if source and not warned[name] then
        warned[name] = true
        warn("[Dead Air] Prefab '" .. name .. "' must be a Model or BasePart")
    end
    return nil
end

local function everyPart(root: Instance, callback: (BasePart) -> ())
    if root:IsA("BasePart") then
        callback(root)
    end
    for _,descendant in root:GetDescendants() do
        if descendant:IsA("BasePart") then
            callback(descendant)
        end
    end
end

local function placed(source: PVInstance, parent: Instance, cf: CFrame): PVInstance
    local clone = source:Clone()
    clone:PivotTo(cf)
    clone:SetAttribute("ImportedArt",true)
    everyPart(clone, function(p)
        p.Anchored = true
        p.CanCollide = false
        p.CanTouch = false
        p.CanQuery = false
        p.CastShadow = true
        -- Preserve the creator's imported GLB material / SurfaceAppearance.
        -- Broad environment PBR variants are only for procedural architecture,
        -- never for externally authored hero meshes or their separate submeshes.
        p:SetAttribute("DisablePBR",true)
    end)
    clone.Parent = parent
    return clone
end

-- Static set dressing. The supplied CFrame is the authored asset's ground-level pivot.
-- Returns false if no asset has been imported. Callers provide a visual-only fallback.
function PrefabLibrary.place(parent: Instance, name: string, cf: CFrame): boolean
    local source = sourceFor(name)
    if not source then
        return false
    end
    placed(source, parent, cf)
    return true
end

-- Moving items / monster: preserve the original invisible root, prompts, and animation.
-- The supplied offset is local to that gameplay root.
-- All mesh parts are massless, non-solid, and welded to the original root.
function PrefabLibrary.attach(root: BasePart, name: string, offset: CFrame): boolean
    local source = sourceFor(name)
    if not source then
        return false
    end
    local clone = placed(source, root, root.CFrame * offset)
    everyPart(clone, function(p)
        p.Massless = true
        p.Anchored = false
        local joint = Instance.new("WeldConstraint")
        joint.Name = "VisualOnlyWeld"
        joint.Part0 = root
        joint.Part1 = p
        joint.Parent = p
    end)
    return true
end

function PrefabLibrary.has(name: string): boolean
    return sourceFor(name) ~= nil
end

function PrefabLibrary.report()
    local root = ServerStorage:FindFirstChild("ArtLibrary")
    if not root then
        print("[Dead Air] Importable visuals: Studio ArtLibrary absent; procedural fallbacks active")
        return
    end
    local count = 0
    for _,asset in root:GetChildren() do
        if asset:IsA("Model") or asset:IsA("BasePart") then
            count += 1
        end
    end
    print(string.format("[Dead Air] Importable visuals: %d approved prefabs ready", count))
end

return PrefabLibrary
