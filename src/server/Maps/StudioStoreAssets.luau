--!strict
-- Opt-in mesh upgrades. Asset content is never downloaded during a match.
-- Artists pre-approve static models in ServerStorage/StudioApprovedAssets in edit mode.
-- This module displays only sanitized geometry and preserves existing objective proxies.
local ServerStorage = game:GetService("ServerStorage")

local Store = {}

type Slot = {
	key: string,
	pos: Vector3,
	size: Vector3,
	yaw: number,
	fallback: { string }?,
	radius: number?,
	objective: string?,
}

-- Positions use the actual 0.7.3 chapter-one layout. Size is an envelope, not
-- an instruction to distort the source mesh (uniform scale only).
local SLOTS: { Slot } = {
	{
		key = "AnalogConsole", pos = Vector3.new(-56, 0, -78),
		size = Vector3.new(11, 5.7, 4.2), yaw = 0,
		fallback = { "MixFader", "DeskMeterBridge", "ChannelVU", "ChannelNeedle", "Potentiometer" },
		radius = 9, objective = "MixingDesk",
	},
	{
		key = "ReelToReel", pos = Vector3.new(-73, 0, -94),
		size = Vector3.new(6.9, 6.8, 3.0), yaw = 0,
		fallback = { "ReelGuide", "AnodizedTapeSpool", "SpoolHub", "TransportButton",
			"TapeCounter", "MagneticTapePath", "Sign_TASCAM / 1987 MULTITRACK" },
		radius = 6, objective = "TapeMachine",
	},
	{
		key = "DrumKit", pos = Vector3.new(-18, 0, -96),
		size = Vector3.new(10, 6.5, 9), yaw = 0,
		fallback = { "DrumKitRug", "BassDrumSkin", "BassFront", "RackTom",
			"CymbalPost", "Cymbal", "StudioChairSeat", "StudioChairBack", "ChairStem", "ChairFoot" },
		radius = 7,
	},
	{
		key = "DrumKit", pos = Vector3.new(31, 0, -127),
		size = Vector3.new(9, 6, 8.5), yaw = 0,
		fallback = { "DrumKitRug", "BassDrumSkin", "BassFront", "RackTom",
			"CymbalPost", "Cymbal", "StudioChairSeat", "StudioChairBack", "ChairStem", "ChairFoot" },
		radius = 7,
	},
	{
		key = "VintageMicrophone", pos = Vector3.new(5, 0, -127),
		size = Vector3.new(2.4, 6.8, 2.4), yaw = 0,
		fallback = { "MicStand", "MicCapsule", "MicGrille", "MicFoot", "PopFilter" },
		radius = 2.7,
	},
	{
		key = "VintageMicrophone", pos = Vector3.new(-8, 0, -83),
		size = Vector3.new(2.4, 6.8, 2.4), yaw = 0,
		fallback = { "MicStand", "MicCapsule", "MicGrille", "MicFoot", "MicrophoneBoom" },
		radius = 2.7,
	},
	{
		key = "VintageMicrophone", pos = Vector3.new(12, 0, -75),
		size = Vector3.new(2.4, 6.8, 2.4), yaw = 0,
		fallback = { "MicStand", "MicCapsule", "MicGrille", "MicFoot", "MicrophoneBoom" },
		radius = 2.7,
	},
	{
		key = "ElectricKeyboard", pos = Vector3.new(28, 0, -98),
		size = Vector3.new(8, 5, 4), yaw = 0,
		fallback = { "ElectricPianoCase", "PianoKeys", "PianoBlackKey", "PianoLeg" },
		radius = 6.5,
	},
	{
		key = "Guitar", pos = Vector3.new(36, 0, -101),
		size = Vector3.new(2.4, 5.8, 1.8), yaw = 0,
		fallback = { "GuitarBody", "GuitarNeck" },
		radius = 4,
	},
	{
		key = "VintageRecordPlayer", pos = Vector3.new(-9, 1.95, 12),
		size = Vector3.new(2.7, 2.0, 2.0), yaw = 180,
		fallback = { "VisitorMagazine", "OldMusicMagazineStack" },
		radius = 3,
	},
	{
		key = "AnalogRack", pos = Vector3.new(61, 0, -127),
		size = Vector3.new(4, 8.4, 2.5), yaw = 0,
		fallback = { "MachineRack", "MachineRackFace", "TapeStatusMeter" },
		radius = 4.5,
	},
}

local ALLOWED = {
	Model = true, Folder = true,
	Part = true, MeshPart = true, WedgePart = true,
	CornerWedgePart = true, UnionOperation = true,
	TrussPart = true, Seat = true, VehicleSeat = true,
	SpecialMesh = true, SurfaceAppearance = true,
	Decal = true, Texture = true,
}

local function clean(model: Model): boolean
	local count = 0
	local meshes = 0
	-- Validate before changing anything. Never trust a model stored by someone else.
	for _, child in model:GetDescendants() do
		if child:IsA("BasePart") then
			count += 1
			if child:IsA("MeshPart") then
				meshes += 1
			end
		end
	end
	if count == 0 or count > 220 or meshes > 50 then
		return false
	end
	for _, child in model:GetDescendants() do
		if not ALLOWED[child.ClassName] then
			child:Destroy()
		elseif child:IsA("BasePart") then
			child.Anchored = true
			child.CanCollide = false
			child.CanQuery = false
			child.CanTouch = false
			child.CastShadow = true
		end
	end
	return true
end

local function match(model: Model, slot: Slot): boolean
	local _, initialSize = model:GetBoundingBox()
	local sx, sy, sz = initialSize.X, initialSize.Y, initialSize.Z
	if sx < 0.01 or sy < 0.01 or sz < 0.01 then
		return false
	end
	-- Imported models have many wildly different default scales; preserve proportions.
	local k = math.min(slot.size.X / sx, slot.size.Y / sy, slot.size.Z / sz)
	if k <= 0 or k > 10 then
		return false
	end
	local ok = pcall(function()
		model:ScaleTo(k)
	end)
	if not ok then
		return false
	end
	local boundsCF, size = model:GetBoundingBox()
	local pivotOffset = model:GetPivot():ToObjectSpace(boundsCF)
	local finalBounds = CFrame.new(slot.pos + Vector3.new(0, size.Y / 2, 0))
		* CFrame.Angles(0, math.rad(slot.yaw), 0)
	model:PivotTo(finalBounds * pivotOffset:Inverse())
	return true
end

local function hideFallback(
	map: Model, folder: Folder, slot: Slot
)
	local props = map:FindFirstChild("Props")
	if not props then
		return
	end
	local candidates: { [string]: boolean } = {}
	for _, name in slot.fallback or {} do
		candidates[name] = true
	end
	-- Disable only native visual parts matching the exact expected name AND
	-- coordinate. Do not touch doors, zones, chapter targets, or imported assets.
	for _, descendant in props:GetDescendants() do
		if descendant:IsA("BasePart")
			and not descendant:IsDescendantOf(folder)
			and candidates[descendant.Name]
			and (descendant.Position - slot.pos).Magnitude < (slot.radius or 7) + 4 then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CastShadow = false
		end
	end
	local obj = slot.objective and map:FindFirstChild("Objectives")
	local hit = obj and obj:FindFirstChild(slot.objective :: string)
	if hit and hit:IsA("BasePart") then
		-- Keep collision and ProximityPrompt exactly as gameplay requires.
		hit.Transparency = 1
		hit.CastShadow = false
	end
end

function Store.apply(map: Model)
	local approved = ServerStorage:FindFirstChild("StudioApprovedAssets")
	if not approved then
		return
	end
	local props = map:FindFirstChild("Props")
	if not props then
		return
	end
	local installed = Instance.new("Folder")
	installed.Name = "ApprovedStoreVisuals"
	installed.Parent = props
	local applied = 0
	for _, slot in SLOTS do
		local source = approved:FindFirstChild(slot.key)
		if not source then
			continue
		end
		if not source:IsA("Model") then
			warn("[Studio assets] " .. slot.key .. " must be a Model, not " .. source.ClassName)
			continue
		end
		local asset = source:Clone()
		asset.Name = "Store_" .. slot.key
		if not clean(asset) or not match(asset, slot) then
			warn("[Studio assets] rejected malformed or excessive model: " .. slot.key)
			asset:Destroy()
			continue
		end
		asset:SetAttribute("SourceSlot", slot.key)
		asset.Parent = installed
		hideFallback(map, installed, slot)
		applied += 1
	end
	if applied > 0 then
		print(string.format("[Studio assets] %d approved visual placements installed.", applied))
	else
		installed:Destroy()
	end
end

return Store
