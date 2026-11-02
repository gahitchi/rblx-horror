--!strict
-- Quiet narrative cues: this was a welcoming family-run business until a 1987 navy seal.
-- Non-interactive so the chapter's twelve objective prompts remain unambiguous.
local Kit = require(script.Parent.StudioDecorKit)
local C = Kit.palette
local Story = {}

local function plant(parent: Instance, x: number, z: number, height: number)
	local pot = Kit.box(parent, "TerracottaPot", x, 0.85, z,
		1.8, 1.7, 1.8, C.woodLight, Enum.Material.SmoothPlastic)
	pot.Shape = Enum.PartType.Cylinder
	pot.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	for i = 1, 5 do
		local dx = math.cos(i * 1.3)
		local dz = math.sin(i * 1.3)
		Kit.rod(parent, "PlantStem", Vector3.new(x, 1.5, z),
			Vector3.new(x + dx * 1.3, height * 0.8, z + dz * 1.3), 0.09, C.green)
		local leaf = Kit.box(parent, "PlantFrond",
			x + dx * 1.3, height * 0.8, z + dz * 1.3,
			1.25, 0.5, 0.8, C.green, Enum.Material.Grass)
		leaf.Shape = Enum.PartType.Ball
	end
end

local function setOfTapes(parent: Instance, x: number, y: number, z: number)
	for i = 1, 6 do
		Kit.box(parent, "HomeTape", x + (i - 3.5) * 0.48,
			y, z, 0.42, 0.65, 0.22,
			if i % 2 == 0 then C.teal else C.woodLight)
		Kit.box(parent, "HandWrittenLabel", x + (i - 3.5) * 0.48,
			y, z - 0.14, 0.35, 0.32, 0.05, C.paper)
	end
end

local function incidentClue(parent: Instance, x: number, y: number, z: number,
	heading: string, detail: string)
	Kit.box(parent, "PinnedPaper", x, y, z, 5.3, 4.4, 0.09,
		C.paper, Enum.Material.SmoothPlastic)
	Kit.sign(parent, heading, CFrame.new(x, y + 1, z - 0.06),
		Vector3.new(4.9, 1, 0.05), Enum.NormalId.Front, C.dark, C.paper)
	Kit.sign(parent, detail, CFrame.new(x, y - 0.8, z - 0.06),
		Vector3.new(4.8, 2.0, 0.05), Enum.NormalId.Front, C.dark, C.paper)
	Kit.box(parent, "PaperPin", x, y + 2.1, z - 0.15,
		0.2, 0.25, 0.11, C.red, Enum.Material.Metal)
end

local function navyTape(parent: Instance, x: number, y: number, z: number, width: number)
	Kit.box(parent, "QuarantineStripe", x, y, z, width, 0.5, 0.13,
		C.gold)
	for i = 1, 6 do
		Kit.block(parent, "WarningChevrons",
			CFrame.new(x - width / 2 + i * width / 7, y, z - 0.11)
				* CFrame.Angles(0, 0, math.rad(30)),
			Vector3.new(0.28, 0.7, 0.08), C.black)
	end
end

function Story.apply(map: Model)
	local props = map:FindFirstChild("Props")
	assert(props, "Props are required")
	local root = Kit.group(props, "FamilyAndQuarantineClues")

	-- Entry: lingering evidence that the studio hosted local people, not a military lab.
	plant(root, -78, 19, 6.4)
	plant(root, -18, 18.7, 5.8)
	plant(root, 39, 18, 4.4)
	Kit.box(root, "OldMusicMagazineStack", -9, 1.95, 12,
		2.6, 0.35, 1.6, C.woodLight)
	Kit.sign(root, "STUDIO BOOKINGS / 1987", CFrame.new(-34, 10.7, 23.6),
		Vector3.new(16, 1.25, 0.15), Enum.NormalId.Front, C.cream)
	incidentClue(root, -31, 7, -6.48, "STAFF NOTE / OCT 15",
		"FINAL CHOIR SESSION\nDO NOT ERASE THE MASTER")
	-- Break room: Eleanor's remembrance beside a household routine abandoned in haste.
	Kit.box(root, "MemorialVase", -61, 3.45, -17.5, 0.9, 1.1, 0.9, C.teal)
	for _, dx in { -0.4, 0, 0.35 } do
		Kit.rod(root, "MemorialFlowerStem",
			Vector3.new(-61, 4.1, -17.5),
			Vector3.new(-61 + dx, 5.1, -17.5), 0.07, C.green)
		local flower = Kit.box(root, "WhiteFlower", -61 + dx, 5.15, -17.5,
			0.6, 0.5, 0.6, C.cream)
		flower.Shape = Enum.PartType.Ball
	end
	Kit.box(root, "CoffeeMug", -49, 3.42, -28,
		0.8, 0.75, 0.75, C.cream)
	setOfTapes(root, -58, 3.5, -16)

	-- Backstage: the unfinished session and suspicious naval work are different stories.
	incidentClue(root, -41, 8, -106.47, "TAKE 04 / DO NOT CUT",
		"THE ROOM DID NOT GO SILENT\nTHE TAPE KEPT TURNING")
	incidentClue(root, 74, 9, -133.5, "MAINTENANCE",
		"RACK 03 TUNED TO SEA TRAFFIC\nORDER: KEEP LISTENING")
	Kit.sign(root, "WRENMOUTH HARBOUR / 15 OCTOBER 1987",
		CFrame.new(99, 9.5, -106.44), Vector3.new(21, 1.4, 0.12),
		Enum.NormalId.Front, C.cream)
	for _, x in { 85, 96, 105 } do
		navyTape(root, x, 3.6, -106.4, 3.8)
	end

	-- Public wing: state seals, a folded plan of the house, and reason to fear the flat.
	incidentClue(root, 25, 8.7, 23.56, "QUARANTINE ORDER 27",
		"US NAVY / AUTHORISED ENTRY ONLY\nUPPER RESIDENCE SEALED")
	Kit.sign(root, "WRENMOUTH / ALL SIGNALS CEASED 00:17",
		CFrame.new(50, 9.5, -7.55), Vector3.new(13, 1.6, 0.1),
		Enum.NormalId.Front, C.cream, C.dark)
	navyTape(root, 71, 5.3, 6.57, 7.3)
	navyTape(root, 71, 7.6, 23.53, 7.3)
end

return Story
