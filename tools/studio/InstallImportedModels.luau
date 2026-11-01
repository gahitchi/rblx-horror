-- Studio Command Bar installer (run only inside your own Roblox Studio, not in a live server).
-- Import the nine GLBs through Studio's 3D Importer, rename their root Models or MeshParts
-- exactly as the asset pack lists, select them in Explorer, then run this script.
-- The installer preserves already-uploaded MeshIds and SurfaceAppearance children.
local ServerStorage = game:GetService("ServerStorage")
local Selection = game:GetService("Selection")

local EXPECTED = {
    MixingConsole = true,
    BroadcastMicrophone = true,
    FoundryBell = true,
    CassetteRecorder = true,
    EngineerHeadset = true,
    WalkieTalkie = true,
    AnalogRack = true,
    NearfieldMonitor = true,
    TapeReel = true,
}
-- A second, optional wave of four original hero props. No need to reinstall the
-- nine existing models; if these are absent the procedural art still works.
local OPTIONAL = {
    ReceptionTerminal = true,
    TapeArchiveCart = true,
    ServiceIntercom = true,
    StudioWallClock = true,
}
-- Original, optional third wave: game-specific character presentation.
local CHARACTER = {
    EngineerBody = true,
    FieldOperatorVest = true,
    FieldOperatorMask = true,
    FieldOperatorPack = true,
}
local ROOT_NAME = "ArtLibrary"

local target = ServerStorage:FindFirstChild(ROOT_NAME)
if not target then
    target = Instance.new("Folder")
    target.Name = ROOT_NAME
    target.Parent = ServerStorage
end
assert(target:IsA("Folder"), "ServerStorage.ArtLibrary must be a Folder")

local installed = {}
local skipped = {}
for _, candidate in Selection:Get() do
    if not EXPECTED[candidate.Name] and not OPTIONAL[candidate.Name] and not CHARACTER[candidate.Name] then
        table.insert(skipped, candidate.Name .. ": name not recognized")
        continue
    end
    if not (candidate:IsA("Model") or candidate:IsA("BasePart")) then
        table.insert(skipped, candidate.Name .. ": expected Model or BasePart")
        continue
    end
    local meshCount = 0
    if candidate:IsA("MeshPart") then
        meshCount += 1
    end
    for _,descendant in candidate:GetDescendants() do
        if descendant:IsA("MeshPart") then
            meshCount += 1
        end
    end
    if meshCount == 0 then
        table.insert(skipped, candidate.Name .. ": contains no MeshPart; import the GLB first")
        continue
    end
    local existing = target:FindFirstChild(candidate.Name)
    if existing then
        -- Non-destructive: do not silently overwrite already approved assets.
        table.insert(skipped, candidate.Name .. ": already installed; remove old copy to replace")
        continue
    end
    -- The authored object's pivot defines the root at which the runtime places it.
    local copy = candidate:Clone()
    copy:SetAttribute("SourceGLB", candidate.Name .. ".glb")
    copy:SetAttribute("ImportedBy", "DeadAirStudioInstaller")
    copy.Parent = target
    table.insert(installed, candidate.Name)
end

print(("[Dead Air] Installed %d approved GLB prefabs in ServerStorage.ArtLibrary"):format(#installed))
for _, name in installed do
    print("  installed: " .. name)
end
for _, msg in skipped do
    warn("  skipped: " .. msg)
end

local missing = {}
for name in EXPECTED do
    if not target:FindFirstChild(name) then
        table.insert(missing, name)
    end
end
table.sort(missing)
if #missing > 0 then
    warn("[Dead Air] Missing imported meshes: " .. table.concat(missing, ", "))
else
    print("[Dead Air] All nine core imported meshes are available to the game")
end
local extraMissing = {}
for name in OPTIONAL do
    if not target:FindFirstChild(name) then
        table.insert(extraMissing,name)
    end
end
table.sort(extraMissing)
if #extraMissing>0 then
    print("[Dead Air] Optional Blackline mesh upgrades not yet imported: "
        .. table.concat(extraMissing,", ") .. " (fallbacks available)")
else
    print("[Dead Air] All four additional Blackline meshes are installed")
end
local characterMissing = {}
for name in CHARACTER do
    if not target:FindFirstChild(name) then
        table.insert(characterMissing,name)
    end
end
table.sort(characterMissing)
if #characterMissing > 0 then
    print("[Dead Air] Optional character/monster meshes awaiting import: "
        ..table.concat(characterMissing,", "))
else
    print("[Dead Air] All four character/monster meshes installed")
end
-- Save the Studio place after successful import. The code-only Rojo build does not
-- contain creator-owned MeshIds; do not replace the prefab with a plain Part.
