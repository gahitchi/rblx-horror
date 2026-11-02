-- Studio Command Bar staging utility. Run ONLY in edit mode.
--
-- 1. Insert a model using Toolbox > Creator Store > Models.
-- 2. Inspect its creator, visual fidelity, triangle count and contents.
-- 3. Select the model (not its script) in Explorer.
-- 4. Set SLOT below to one of the keys listed here, then paste/run this file
--    from the Studio Command Bar. The clean copy is placed in ServerStorage,
--    separate from the source. Delete the untrusted source model afterwards.
--
-- CAUTION: this does NOT guarantee an asset is safe or licensed. It strips
-- scripts before staging, but you must still vet its content and creator.
-- All staged models are static decoration. Interactive gameplay remains in
-- our own Lua modules.

local SLOT = "VintageRecordPlayer" -- CHANGE THIS to the selected prefab slot.
local ASSET_ID = "" -- Optional actual Creator Store model ID for your audit.
local CREATOR = "" -- Optional creator name as listed on the Store.

local allowedSlots = {
	AnalogConsole = true,
	ReelToReel = true,
	DrumKit = true,
	VintageMicrophone = true,
	ElectricKeyboard = true,
	Guitar = true,
	VintageRecordPlayer = true,
	AnalogRack = true,
}

assert(allowedSlots[SLOT], "Unsupported asset slot: " .. SLOT)
assert(not game:GetService("RunService"):IsRunning(), "Run in Studio EDIT mode, not Play.")

local Selection = game:GetService("Selection")
local ServerStorage = game:GetService("ServerStorage")
local chosen = Selection:Get()
assert(#chosen == 1, "Select exactly one store Model or MeshPart in Explorer.")
local item = chosen[1]
assert(item:IsA("Model") or item:IsA("BasePart"), "Select a Model or BasePart.")

local prepared: Model
if item:IsA("Model") then
	prepared = item:Clone()
else
	prepared = Instance.new("Model")
	item:Clone().Parent = prepared
end
prepared.Name = SLOT
prepared.Parent = nil

local allowed = {
	Model = true, Folder = true,
	Part = true, MeshPart = true, WedgePart = true,
	CornerWedgePart = true, UnionOperation = true, TrussPart = true,
	Seat = true, VehicleSeat = true, SpecialMesh = true,
	SurfaceAppearance = true, Decal = true, Texture = true,
}
for _, descendant in prepared:GetDescendants() do
	if not allowed[descendant.ClassName] then
		descendant:Destroy()
	elseif descendant:IsA("BasePart") then
		descendant.Anchored = true
		descendant.CanCollide = false
		descendant.CanTouch = false
		descendant.CanQuery = false
	end
end

local parts = 0
local meshes = 0
for _, descendant in prepared:GetDescendants() do
	if descendant:IsA("BasePart") then
		parts += 1
		if descendant:IsA("MeshPart") then
			meshes += 1
		end
	end
end
assert(parts > 0, "The selected asset has no visual geometry after sanitizing.")
assert(parts <= 220 and meshes <= 50,
	"Too many parts or mesh parts for a mobile-target asset: " .. parts .. " parts / " .. meshes .. " meshes")

if ASSET_ID ~= "" then
	assert(tonumber(ASSET_ID) ~= nil, "ASSET_ID must be numeric if supplied.")
	prepared:SetAttribute("CreatorStoreAssetId", ASSET_ID)
end
if CREATOR ~= "" then
	prepared:SetAttribute("CreatorStoreCreator", CREATOR)
end
prepared:SetAttribute("StagedFor", "WrenmouthStudioV2")
prepared:SetAttribute("ScriptFree", true)

local approved = ServerStorage:FindFirstChild("StudioApprovedAssets")
if not approved then
	approved = Instance.new("Folder")
	approved.Name = "StudioApprovedAssets"
	approved.Parent = ServerStorage
end
local old = approved:FindFirstChild(SLOT)
if old then
	old:Destroy()
end
prepared.Parent = approved
print(("[Studio assets] Staged %s: %d parts, %d MeshParts (edit mode only)")
	:format(SLOT, parts, meshes))
print("[Studio assets] Delete the original inserted Toolbox model, then press Play to preview.")

-- When using Rojo, this folder is stored in the .rbxl place, not Git.
-- Keep the place file / assets backed up. The code-based native fallbacks
-- will render automatically if this folder is absent.
