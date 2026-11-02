--!strict
-- The studio, chapter 1: The Last Session (design doc, "Chapter 1").
--
--   1. Arrival: the locks slam, the foghorn sounds, the handler comes on the walkies.
--   2. The booking diary points to control room A. The session log there names three reels.
--   3. The tape machine's path is broken: spares from the break room, then rethread it by hand.
--   4. Three reels, three ways: the archive (card index, then the shelf), the live room (a road case
--      under instruments that must be moved), control room B (a safe; the combination is the date
--      on the memorial programme in the break room). Loading a reel plays its track out loud.
--   5. First shock at the first reel (the building wakes), second at the second (blackout, fog,
--      the team's own sounds thrown back, a frenzy, red lights). Both fire anyway if the crew stalls.
--   6. After the second shock the desk gets no signal: patch it by hand from the log's notes.
--   7. With three reels in and the desk patched: hold the desk through the last session (ride the
--      faders) while it dubs onto the cassette.
--   8. Last Call. The cassette has to leave the building.
-- Optional: three townspeople's tapes, delivered through the mail slot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("Sounds"))
local StoryTapes = require(Shared:WaitForChild("StoryTapes"))

local Kit = require(script.Parent.Kit)
local Text = require(script.Parent.Studio1Text)
local StudioTension = require(script.Parent.StudioTension)
local LightingService = require(script.Parent.Parent.LightingService)
local MonsterService = require(script.Parent.Parent.MonsterService)
local ProgressService = require(script.Parent.Parent.ProgressService)
local Mimicry = require(script.Parent.Parent.Monster.Mimicry)

local S = Config.STUDIO1
local REELS = { "A", "B", "C" }
local REEL_COLOR = Color3.fromRGB(150, 120, 70)

local Studio1 = {}

Studio1.id = "studio1"
Studio1.requires = {
	"BookingDiary",
	"SessionLog",
	"TapeMachine",
	"Spares",
	"CardIndex",
	"RoadCase",
	"Safe",
	"MemorialProgramme",
	"PatchBay",
	"MixingDesk",
	"MailSlot",
}

type State = {
	diaryRead: boolean,
	logRead: boolean,
	fixed: boolean,
	numbers: { string },
	inputs: { number },
	shelf: string,
	shelfLabels: { [string]: string },
	clutterLeft: number,
	caseOpened: boolean,
	safeOpened: boolean,
	safeWrong: number,
	safeLockedUntil: number,
	loaded: { [string]: boolean },
	loadedCount: number,
	patched: boolean,
	dubbing: boolean,
	dubbed: boolean,
}

local state: State

local function objectiveLines()
	local done = '<font color="#78C88C">done</font>'
	local dim = function(text: string): string
		return '<font color="#827D76">' .. text .. "</font>"
	end
	local lines = { "<b>THE LAST SESSION</b>" }
	if state.dubbed then
		if Kit.cleared() then
			table.insert(lines, "The cassette is out. " .. done)
		else
			table.insert(lines, "<b>GET OUT WITH THE CASSETTE</b>")
		end
		Kit.setObjectives(lines)
		return
	end
	if not state.diaryRead then
		table.insert(lines, "Find the booking diary (reception)")
		Kit.setObjectives(lines)
		return
	end
	table.insert(lines, "Booking diary  " .. done)
	if not state.logRead then
		table.insert(lines, "Read the session log (control A)")
		Kit.setObjectives(lines)
		return
	end
	table.insert(lines, "Session log  " .. done)
	if state.fixed then
		table.insert(lines, "Tape machine (control A)  " .. done)
	else
		table.insert(lines, "Fix the tape machine (control A)")
		table.insert(lines, dim("   spare parts: break room cupboard"))
	end
	table.insert(lines, string.format("Reels A, B, C loaded  %d/3", state.loadedCount))
	if Kit.shocksFired() >= 2 then
		table.insert(
			lines,
			if state.patched
				then "Desk patched  " .. done
				else "Patch the desk (patch bay, control A)"
		)
	end
	if state.dubbing then
		table.insert(lines, "<b>HOLD THE DESK</b>")
	elseif state.loadedCount >= 3 and state.patched then
		table.insert(lines, "<b>Hold the desk for the last session</b>")
	end
	table.insert(lines, dim("Optional tapes: push them through the mail slot"))
	Kit.setObjectives(lines)
end

-- ===== The shocks =====

local function shock1()
	LightingService.set("woken")
	Kit.speakers(Sounds.WALKIE_CRACKLE, 0.8, 0.4)
	for _, door in Kit.layout().sealedDoors do
		if door:GetAttribute("Kind") == "barricaded" then
			Kit.sound(Sounds.THUMP, door.Position, 1, 120, 0.7)
		end
	end
	MonsterService.callTo(Kit.objective("TapeMachine").Position)
	Kit.radio(if state.loadedCount > 0 then Text.RADIO.shock1 else Text.RADIO.shock1Stalled)
	objectiveLines()
end

local function shock2()
	local SH = Config.SHOCK
	-- The tracks start playing by themselves; the machines go wild.
	Kit.speakers(Sounds.REEL_TRACK, 1, 0.6)
	LightingService.set("red")
	LightingService.blackout(SH.BLACKOUT)
	LightingService.fogIn(SH.FOG_SECONDS)
	MonsterService.frenzyFor(SH.FRENZY)
	-- Every speaker throws back sounds the team made earlier.
	local heard = Mimicry.heard()
	if #heard == 0 then
		heard = { "footsteps", "door", "voice" }
	end
	local rng = Kit.random()
	for i = 1, SH.REPLAYED_SOUNDS do
		task.delay(0.6 + i * 0.9, function()
			Mimicry.playAt(heard[rng:NextInteger(1, #heard)], Kit.randomSpeaker())
		end)
	end
	task.delay(SH.BLACKOUT + 1, function()
		Kit.radio(Text.RADIO.shock2)
	end)
	objectiveLines()
end

-- ===== Reels =====

local function reelId(letter: string): string
	return "reel" .. letter
end

local function heldReel(player: Player): string?
	local held = Kit.holding(player)
	for _, letter in REELS do
		if held == reelId(letter) then
			return letter
		end
	end
	return nil
end

local function onLoadReel(player: Player)
	local machine = Kit.objective("TapeMachine")
	local letter = heldReel(player)
	if not letter then
		return
	end
	if state.loaded[letter] then
		Kit.notify(player, "Reel " .. letter .. " is already on the machine.")
		return
	end
	Kit.take(player)
	state.loaded[letter] = true
	state.loadedCount += 1
	ProgressService.award(player, "Loaded a reel", Config.REWARDS.REEL_LOADED)
	-- The 1987 console can't mute its speakers: the track plays through the building.
	Kit.sound(Sounds.REEL_TRACK, machine.Position, 1, 250, 0.7)
	Kit.speakers(Sounds.REEL_TRACK, 0.8, 0.7)
	Kit.noise(machine.Position, Config.NOISE.REEL_PLAYBACK, "reel", player)
	Kit.notifyAll(string.format("Reel %s is on the machine (%d/3).", letter, state.loadedCount))
	if state.loadedCount == 1 then
		Kit.shock(1)
	elseif state.loadedCount == 2 then
		Kit.shock(2)
	end
	objectiveLines()
end

local function onMachine(player: Player)
	local machine = Kit.objective("TapeMachine")
	if not state.fixed then
		if Kit.holding(player) ~= "spares" then
			Kit.notify(player, "The tape path is broken: a pinch roller and a belt are missing.")
			Kit.radio(Text.RADIO.machineBroken)
			return
		end
		Kit.openPuzzle(player, "rethread", machine, { parts = Text.THREAD_ORDER })
		return
	end
	if heldReel(player) then
		onLoadReel(player)
	else
		Kit.notify(
			player,
			string.format("The machine is ready. Reels loaded: %d/3.", state.loadedCount)
		)
	end
end

local function giveReel(player: Player, letter: string, where: Vector3): boolean
	-- Do not consume a unique reel or award XP if the player's hands are full.
	-- Dropped items are handled by Kit when a carrier is lost.
	if Kit.holding(player) then
		Kit.notify(player, "Your hands are full. Put your item down (G) to take this reel.")
		return false
	end
	if not Kit.give(player, reelId(letter), where) then
		return false
	end
	Kit.notify(player, "Reel " .. letter .. " acquired. Bring it to control room A.")
	ProgressService.award(player, "Found a reel", Config.REWARDS.REEL_FOUND)
	return true
end

-- ===== Setup each round =====

local function randomNumbers(count: number, excluded: { [string]: boolean }?): { string }
	local rng = Kit.random()
	local used: { [string]: boolean } = table.clone(excluded or {})
	local list: { string } = {}
	while #list < count do
		local number = string.format("WS-%04d", rng:NextInteger(1000, 8999))
		if not used[number] then
			used[number] = true
			table.insert(list, number)
		end
	end
	return list
end

local function cardIndexText(): string
	local rng = Kit.random()
	local cards: { { number: string, text: string } } = {}
	local titles = table.clone(Text.DECOY_TITLES)
	local used: { [string]: boolean } = {}
	for _, number in state.numbers do
		used[number] = true
	end

	-- The visible labels on ordinary reels must agree with the archive ledger.
	-- Their shelf numbers are reserved *before* generating additional decoy cards.
	for shelf, number in state.shelfLabels do
		used[number] = true
		local title = table.remove(titles, rng:NextInteger(1, #titles)) :: string
		table.insert(cards, {
			number = number,
			text = Text.cardOrdinary(number, title, shelf),
		})
	end
	local extra = math.max(0, S.DECOY_CARDS - #cards)
	for _, number in randomNumbers(extra, used) do
		local title = table.remove(titles, rng:NextInteger(1, #titles)) :: string
		table.insert(cards, {
			number = number,
			text = Text.cardOrdinary(number, title,
				tostring(rng:NextInteger(1, math.max(1, #Kit.layout().reelSpots)))),
		})
	end

	table.insert(cards, {
		number = state.numbers[1],
		text = Text.cardArchive(state.numbers[1], state.shelf),
	})
	table.insert(cards, {
		number = state.numbers[2],
		text = Text.cardRoadCase(state.numbers[2]),
	})
	table.insert(cards, {
		number = state.numbers[3],
		text = Text.cardSafe(state.numbers[3]),
	})
	table.sort(cards, function(a, b)
		return a.number < b.number
	end)
	local lines: { string } = {}
	for _, card in cards do
		table.insert(lines, card.text)
	end
	return table.concat(lines, "\n")
end

local function setUpArchiveReel()
	local layout = Kit.layout()
	local rng = Kit.random()
	if #layout.reelSpots == 0 then
		-- A map without shelf spots: the reel waits on the card index itself.
		state.shelf = "?"
		local index = Kit.objective("CardIndex")
		local reel = Kit.spawnPart(
			"ReelA",
			CFrame.new(index.Position + Vector3.new(0, index.Size.Y / 2 + 0.3, 0)),
			Vector3.new(1.6, 0.4, 1.6),
			REEL_COLOR
		)
		Kit.prompt(reel, "Take", "Reel A", 0, function(player)
			if reel.Parent and giveReel(player, "A", reel.Position) then
				reel:Destroy()
			end
		end)
		return
	end
	local spot = layout.reelSpots[rng:NextInteger(1, #layout.reelSpots)]
	local shelf = spot:GetAttribute("Shelf")
	state.shelf = if type(shelf) == "string"
		then shelf
		else tostring(table.find(layout.reelSpots, spot))
	local reel = Kit.spawnPart(
		"ReelA",
		CFrame.new(spot.Position) * CFrame.Angles(math.rad(90), 0, 0),
		Vector3.new(1.6, 0.4, 1.6),
		REEL_COLOR
	)
	Kit.prompt(reel, "Take", "Reel " .. state.numbers[1], 0, function(player)
		if reel.Parent and giveReel(player, "A", reel.Position) then
			reel:Destroy()
		end
	end)
	-- Every other shelf spot holds an ordinary reel with a matching card-index entry.
	local used: { [string]: boolean } = {}
	for _, number in state.numbers do
		used[number] = true
	end
	for _, other in layout.reelSpots do
		if other ~= spot then
			local decoy = Kit.spawnPart(
				"Reel",
				CFrame.new(other.Position) * CFrame.Angles(math.rad(90), 0, 0),
				Vector3.new(1.6, 0.4, 1.6),
				Color3.fromRGB(90, 80, 70)
			)
			local otherNumber = randomNumbers(1, used)[1]
			used[otherNumber] = true
			local shelfId = other:GetAttribute("Shelf")
			local shelfName = if type(shelfId) == "string"
				then shelfId else tostring(table.find(layout.reelSpots, other))
			state.shelfLabels[shelfName] = otherNumber
			Kit.prompt(decoy, "Read the label", otherNumber, 0, function(player)
				Kit.notify(player, "Reel " .. otherNumber .. ". Not one of the three.")
			end)
		end
	end
end

local function setUpRoadCase()
	local case = Kit.objective("RoadCase")
	local top = case.Position + Vector3.new(0, case.Size.Y / 2, 0)
	local shapes = {
		{
			name = "Snare drum",
			size = Vector3.new(1.6, 0.8, 1.6),
			color = Color3.fromRGB(170, 160, 150),
		},
		{
			name = "Amp head",
			size = Vector3.new(2.4, 1.2, 1.2),
			color = Color3.fromRGB(30, 30, 30),
		},
		{
			name = "Cymbal stand",
			size = Vector3.new(0.4, 2.6, 0.4),
			color = Color3.fromRGB(180, 160, 90),
		},
		{
			name = "Guitar case",
			size = Vector3.new(3.4, 0.5, 1.2),
			color = Color3.fromRGB(40, 30, 26),
		},
	}
	state.clutterLeft = math.min(S.ROAD_CASE_CLUTTER, #shapes)
	local casePrompt: ProximityPrompt
	casePrompt = Kit.prompt(case, "Open", "Road case", 1, function(player)
		if state.clutterLeft > 0 then
			Kit.notify(player, "There's too much piled on it. Move the instruments off first.")
			return
		end
		if state.caseOpened then
			return
		end
		if not giveReel(player, "B", top + Vector3.new(0, 0.4, 0)) then
			return
		end
		state.caseOpened = true
		casePrompt.Enabled = false
		Kit.sound(Sounds.TAPE_CLUNK, case.Position, 0.8)
	end)
	for i = 1, state.clutterLeft do
		local shape = shapes[i]
		local offset = Vector3.new((i - 2) * 1.4, shape.size.Y / 2, 0)
		local item = Kit.spawnPart(shape.name, CFrame.new(top + offset), shape.size, shape.color)
		item.CanCollide = true
		Kit.prompt(item, "Move", shape.name, 0.8, function(player)
			if not item:GetAttribute("Moved") then
				item:SetAttribute("Moved", true)
				-- Off the case onto the floor beside it. It's never quiet.
				item.CFrame = CFrame.new(
					case.Position
						+ Vector3.new(
							case.Size.X / 2 + 1.2,
							-case.Size.Y / 2 + shape.size.Y / 2,
							(i - 2) * 1.6
						)
				)
				Kit.sound(Sounds.CLUTTER, item.Position, 0.9)
				Kit.noise(item.Position, Config.NOISE.CLUTTER, "clutter", player)
				state.clutterLeft -= 1
				local prompt = item:FindFirstChildOfClass("ProximityPrompt")
				if prompt then
					prompt.Enabled = false
				end
			end
		end)
	end
end

local function setUpSafe()
	local safe = Kit.objective("Safe")
	Kit.prompt(safe, "Try the combination", "Desk safe", 0, function(player)
		if state.safeOpened then
			Kit.notify(player, "The safe is empty now.")
			return
		end
		if os.clock() < state.safeLockedUntil then
			Kit.notify(player, "The dial is jammed for a moment. Try again shortly.")
			return
		end
		Kit.openPuzzle(player, "safe", safe, { digits = #S.SAFE_COMBO })
	end)
	Kit.onAnswer("safe", function(player, answer)
		if state.safeOpened or os.clock() < state.safeLockedUntil or type(answer) ~= "string" then
			return
		end
		if answer == S.SAFE_COMBO then
			if not giveReel(player, "C", safe.Position + Vector3.new(0, safe.Size.Y / 2 + 0.3, 0)) then
				return
			end
			state.safeOpened = true
			Kit.closePuzzle(player)
			Kit.sound(Sounds.SAFE_CLICK, safe.Position, 1)
		else
			state.safeWrong += 1
			Kit.sound(Sounds.SAFE_CLICK, safe.Position, 1, 60, 0.6)
			Kit.noise(safe.Position, Config.NOISE.SAFE_CLUNK, "safe", player)
			if state.safeWrong % 3 == 0 then
				state.safeLockedUntil = os.clock() + S.SAFE_LOCKOUT
				Kit.closePuzzle(player)
				Kit.notify(player, "Three wrong tries. The dial jams for a moment.")
			else
				Kit.notify(player, "Wrong combination.")
			end
		end
	end)
end

local function setUpMachine()
	local machine = Kit.objective("TapeMachine")
	Kit.prompt(machine, "Use", "Tape machine", 0, onMachine)
	Kit.onAnswer("rethread", function(player, answer)
		if state.fixed or type(answer) ~= "table" then
			return
		end
		local correct = #answer == #Text.THREAD_ORDER
		if correct then
			for i, name in Text.THREAD_ORDER do
				if answer[i] ~= name then
					correct = false
					break
				end
			end
		end
		if not correct then
			-- The tape clatters off a guide: a small noise, and start again.
			Kit.sound(Sounds.TAPE_SLIP, machine.Position, 0.7)
			Kit.noise(machine.Position, Config.NOISE.TAPE_SLIP, "slip", player)
			return
		end
		if Kit.holding(player) ~= "spares" then
			Kit.closePuzzle(player)
			return
		end
		Kit.take(player)
		state.fixed = true
		Kit.closePuzzle(player)
		Kit.sound(Sounds.TAPE_THREAD, machine.Position, 0.8)
		ProgressService.award(player, "Fixed the tape machine", Config.REWARDS.MACHINE_FIXED)
		Kit.notifyAll("The tape machine is fixed.")
		Kit.radio(Text.RADIO.machineFixed)
		objectiveLines()
	end)
end

local function setUpPatchBay()
	local bay = Kit.objective("PatchBay")
	local desk = Kit.objective("MixingDesk")
	Kit.prompt(bay, "Patch", "Patch bay", 0, function(player)
		if state.patched then
			Kit.notify(player, "The desk is patched.")
			return
		end
		if Kit.shocksFired() < 2 then
			Kit.notify(player, "The desk already has signal. Nothing to patch.")
			return
		end
		Kit.openPuzzle(player, "patchbay", bay, { tracks = REELS, inputs = S.PATCH_INPUTS })
	end)
	Kit.onAnswer("patchbay", function(player, answer)
		if state.patched or Kit.shocksFired() < 2 or type(answer) ~= "table" then
			return
		end
		local right = 0
		for i, letter in REELS do
			if answer[letter] == state.inputs[i] then
				right += 1
			end
		end
		if right == #REELS then
			state.patched = true
			Kit.closePuzzle(player)
			Kit.sound(Sounds.TAPE_THREAD, bay.Position, 0.8)
			ProgressService.award(player, "Patched the desk", Config.REWARDS.PATCHED)
			Kit.notifyAll("The desk is patched.")
			Kit.radio(Text.RADIO.patched)
			objectiveLines()
		else
			-- A wrong patch buzzes through the speakers.
			Kit.speakers(Sounds.BUZZ, 0.8, 0.3)
			Kit.noise(desk.Position, Config.NOISE.BUZZ, "buzz", player)
			Kit.notify(player, string.format("BZZZ. %d of 3 patched right.", right))
		end
	end)
end

local function setUpDesk()
	local desk = Kit.objective("MixingDesk")
	local deskPrompt: ProximityPrompt
	deskPrompt = Kit.prompt(desk, "Hold the desk", "Mixing desk", 0, function(player)
		if state.loadedCount < 3 then
			Kit.notify(
				player,
				string.format("Only %d of 3 reels are on the machine.", state.loadedCount)
			)
			return
		end
		if not state.patched then
			Kit.notify(
				player,
				if Kit.shocksFired() < 2
					then "The desk can't take all three tracks yet."
					else "No signal. Patch the desk at the patch bay first."
			)
			return
		end
		if state.dubbing then
			return
		end
		state.dubbing = true
		deskPrompt.Enabled = false
		Kit.radio(Text.RADIO.dubStart)
		Kit.startDub(desk, "Hold the desk", function(holder)
			state.dubbing = false
			state.dubbed = true
			ProgressService.award(holder, "Held the last session", Config.REWARDS.LAST_SESSION)
			Kit.giveCassette(holder)
			Kit.notifyAll(holder.DisplayName .. " has the cassette.")
			Kit.radio(Text.RADIO.lastCall)
			objectiveLines()
			Kit.lastCall()
		end, player)
		objectiveLines()
	end)
end

-- Something moves behind the flat's barricaded door now and then.
local function barricadeThumps(myRound: number)
	task.spawn(function()
		local rng = Kit.random()
		while Kit.roundId() == myRound do
			task.wait(rng:NextNumber(45, 95))
			if Kit.roundId() ~= myRound then
				return
			end
			for _, door in Kit.layout().sealedDoors do
				if door:GetAttribute("Kind") == "barricaded" then
					Kit.sound(Sounds.THUMP, door.Position, 0.8, 90, rng:NextNumber(0.6, 0.9))
				end
			end
		end
	end)
end

-- The 1987 broadcast bleeds through the walkies now and then.
local function broadcastFragments(myRound: number)
	task.spawn(function()
		local rng = Kit.random()
		local lines = table.clone(Text.BROADCAST)
		task.wait(rng:NextNumber(60, 100))
		while Kit.roundId() == myRound and #lines > 0 do
			Kit.broadcast(table.remove(lines, rng:NextInteger(1, #lines)) :: string)
			task.wait(rng:NextNumber(120, 220))
		end
	end)
end

function Studio1.start()
	Kit.defineItem(
		"spares",
		"Spare parts",
		Color3.fromRGB(150, 150, 140),
		Vector3.new(1.2, 0.6, 0.8),
		0.3
	)
	for _, letter in REELS do
		-- Two-inch tape on a metal reel: heavy enough to slow a sprint.
		Kit.defineItem(
			reelId(letter),
			"Reel " .. letter,
			REEL_COLOR,
			Vector3.new(1.6, 0.4, 1.6),
			0.6
		)
	end
	local rng = Kit.random()
	local inputs: { number } = {}
	local pool: { number } = {}
	for i = 1, S.PATCH_INPUTS do
		table.insert(pool, i)
	end
	for _ = 1, #REELS do
		table.insert(inputs, table.remove(pool, rng:NextInteger(1, #pool)) :: number)
	end
	state = {
		diaryRead = false,
		logRead = false,
		fixed = false,
		numbers = randomNumbers(3),
		inputs = inputs,
		shelf = "?",
		shelfLabels = {},
		clutterLeft = 0,
		caseOpened = false,
		safeOpened = false,
		safeWrong = 0,
		safeLockedUntil = 0,
		loaded = {},
		loadedCount = 0,
		patched = false,
		dubbing = false,
		dubbed = false,
	}
	Kit.setShocks({ shock1, shock2 })

	-- Optional 1987 paper trail: a map without our visual notes skips these.
	-- Every read is server-delivered, so the field notebook only files
	-- pages that the individual player actually examined.
	local props = Kit.layout().map:FindFirstChild("Props")
	local evidence = props and props:FindFirstChild("RecordedEvidence")
	if evidence then
		for _, entry in Text.EVIDENCE do
			local paper = evidence:FindFirstChild(entry.id)
			if paper and paper:IsA("BasePart") then
				Kit.prompt(paper, "Read", entry.label, 0.2, function(player)
					Kit.document(player, entry.title, entry.body)
				end)
			end
		end
	end

	-- Documents
	Kit.prompt(Kit.objective("BookingDiary"), "Read", "Booking diary", 0, function(player)
		Kit.document(player, Text.DIARY_TITLE, Text.DIARY)
		if not state.diaryRead then
			state.diaryRead = true
			objectiveLines()
		end
	end)
	Kit.prompt(Kit.objective("SessionLog"), "Read", "Session log", 0, function(player)
		Kit.document(player, Text.LOG_TITLE, Text.log(state.numbers, state.inputs))
		if not state.logRead then
			state.logRead = true
			Kit.radio(Text.RADIO.logRead)
			objectiveLines()
		end
	end)
	Kit.prompt(Kit.objective("MemorialProgramme"), "Read", "Order of service", 0, function(player)
		Kit.document(player, Text.PROGRAMME_TITLE, Text.PROGRAMME)
	end)
	Kit.prompt(
		Kit.objective("Spares"),
		"Take spare parts",
		"Maintenance cupboard",
		0.8,
		function(player)
			if state.fixed then
				Kit.notify(player, "Nothing else in here you need.")
				return
			end
			if Kit.holding(player) then
				Kit.notify(player, "Your hands are full (G puts down what you hold).")
				return
			end
			if Kit.give(player, "spares", Kit.objective("Spares").Position) then
				ProgressService.award(player, "Found spare parts", Config.REWARDS.SPARES)
				Kit.notify(
					player,
					"A pinch roller and a belt. The tape machine is in control room A."
				)
			end
		end
	)

	setUpMachine()
	setUpArchiveReel()
	-- After the archive reel has picked its shelf, so the card points to the right one.
	local cards = cardIndexText()
	Kit.prompt(Kit.objective("CardIndex"), "Search", "Card index", 0.6, function(player)
		Kit.document(player, Text.CARD_TITLE, cards)
	end)
	setUpRoadCase()
	setUpSafe()
	setUpPatchBay()
	setUpDesk()
	Kit.spawnTapes(StoryTapes.optional(Studio1.id), S.OPTIONAL_TAPES)

	-- Arrival: the locks slam behind the crew as the building wakes; the foghorn outside.
	local layout = Kit.layout()
	Kit.sound(Sounds.LOCK_SLAM, layout.frontDoor.Position, 1, 200)
	Kit.sound(Sounds.FOGHORN, layout.exitZone.Position + Vector3.new(0, 20, 30), 1, 600, 0.2)
	local myRound = Kit.roundId()
	task.delay(3, function()
		if Kit.roundId() == myRound then
			Kit.radio(Text.RADIO.arrival)
		end
	end)
	task.delay(9, function()
		if Kit.roundId() == myRound then
			Kit.radio(Text.RADIO.arrival2)
		end
	end)
	-- Quiet positional tension while exploring; stops on shocks, Last Call or round reset.
	StudioTension.start(myRound)
	barricadeThumps(myRound)
	broadcastFragments(myRound)
	objectiveLines()
end

-- Called when the cassette leaves the building.
function Studio1.onCleared()
	Kit.radio(Text.RADIO.cleared)
	objectiveLines()
end

return Studio1
