--!strict
-- Run in the Studio Server Command Bar AFTER pressing Play in Match.
-- Reports concrete furniture/prop support errors. No automatic movement,
-- no destructive cleanup and no changes to chapter objectives.
local map = workspace:WaitForChild("Map")
local props = map:WaitForChild("Props")
local markers = map:WaitForChild("Markers")

local checks = 0
local function check(ok: boolean, message: string)
	checks += 1
	assert(ok, "[World placement #" .. checks .. "] " .. message)
end

local function partNamed(name: string): BasePart
	local item = props:FindFirstChild(name, true)
	assert(item and item:IsA("BasePart"), "[World placement] Missing part: " .. name)
	return item :: BasePart
end

local function bottom(p: BasePart): number
	return p.Position.Y - p.Size.Y / 2
end
local function top(p: BasePart): number
	return p.Position.Y + p.Size.Y / 2
end
local function supported(p: BasePart, support: BasePart, tolerance: number?)
	local t = tolerance or 0.10
	check(math.abs(bottom(p) - top(support)) <= t,
		p.Name .. " floats above or cuts through " .. support.Name
		.. " by " .. tostring(bottom(p) - top(support)) .. " studs")
	check(math.abs(p.Position.X - support.Position.X) + p.Size.X / 2
		<= support.Size.X / 2 + t,
		p.Name .. " projects outside the supporting tabletop in X")
	check(math.abs(p.Position.Z - support.Position.Z) + p.Size.Z / 2
		<= support.Size.Z / 2 + t,
		p.Name .. " projects outside the supporting tabletop in Z")
end

-- Large installed furniture should have collidable geometry that reaches
-- the floor, not be one free-floating decorative block.
local modelCounts: { [string]: number } = {}
for _, inst in props:GetDescendants() do
	if not inst:IsA("Model") then continue end
	local kind = inst:GetAttribute("FurnitureType")
	if type(kind) ~= "string" then continue end
	modelCounts[kind] = (modelCounts[kind] or 0) + 1
	local lowest = math.huge
	for _, p in inst:GetDescendants() do
		if p:IsA("BasePart") and p.CanCollide then
			lowest = math.min(lowest, bottom(p))
		end
	end
	check(math.abs(lowest) < 0.22, "Unsupported furniture feet: " .. inst.Name
		.. " / " .. kind .. " min Y " .. tostring(lowest))
end
check((modelCounts.WorkingTable or 0) >= 2, "Working tables not constructed")
check((modelCounts.TapeArchiveShelf or 0) == 4, "Archive must have four purpose-built shelves")
check((modelCounts.AnalogueRack or 0) >= 3, "Machine-room equipment racks missing")

-- The four rear-wall archive frames must contain actual deck geometry.
local decks = {}
for _, inst in props:GetDescendants() do
	if inst:IsA("BasePart") and inst.Name == "SolidShelfDeck" then
		table.insert(decks, inst)
	end
end
check(#decks == 12, "Archive needs exactly twelve physical decks")
local cases = 0
for _, cassette in props:GetDescendants() do
	if not (cassette:IsA("BasePart") and cassette.Name == "CassetteBox") then continue end
	cases += 1
	local support: BasePart? = nil
	for _, deck in decks do
		if math.abs(cassette.Position.X - deck.Position.X) <= deck.Size.X / 2
			and math.abs(cassette.Position.Z - deck.Position.Z) <= deck.Size.Z / 2
			and math.abs(bottom(cassette) - top(deck)) < 0.06 then
			support = deck
			break
		end
	end
	check(support ~= nil, "Archive cassette is in midair: " .. tostring(cassette.Position))
end
check(cases == 48, "Archive must place exactly 48 cassettes on the physical shelves")

-- Counter glass, flowers, mugs and records were confirmed floating in the
-- previous playtest; pin their positions to exact load-bearing surfaces.
supported(partNamed("ReceptionWritingMat"), partNamed("ReceptionCounterTop"))
supported(partNamed("DeskBell"), partNamed("ReceptionCounterTop"), 0.06)
supported(partNamed("RotaryTelephone"), partNamed("ReceptionCounterTop"))
supported(partNamed("PencilCup"), partNamed("ReceptionCounterTop"))
supported(partNamed("MemorialVase"), partNamed("BreakTableTop"))
supported(partNamed("CoffeeMug"), partNamed("BreakCounter"))
supported(partNamed("RecordSleeve"), partNamed("RecordDisplayShelf"))
local coffeeTable = props:FindFirstChild("ReceptionCoffeeTable", true)
assert(coffeeTable and coffeeTable:IsA("Model"), "Reception coffee table model is missing")
local coffeeTop = coffeeTable:FindFirstChild("HardwoodTopCollider")
assert(coffeeTop and coffeeTop:IsA("BasePart"), "Reception coffee table top is missing")
supported(partNamed("VisitorMagazine"), coffeeTop :: BasePart, 0.14)

local foundReels = 0
for _, marker in markers:GetChildren() do
	if marker.Name == "ReelSpot" then
		foundReels += 1
		check(marker.Position.Z > -131, "ReelSpot must remain in the accessible aisle")
	end
end
check(foundReels == 4, "ReelSpots must remain intact for the chapter")

print("[World placement] PASS: " .. tostring(checks) ..
	" grounding, shelf, countertop, cassette and objective checks")
print("[World placement] Manual checks still required: camera-level silhouette,"
	.. " grounded wall treatment, supported instruments, player reach and pathfinding")
