--!strict
-- The toolkit every chapter is built from, so a chapter module only says what happens in it:
--   prompts, documents and puzzles on the map's objective parts
--   hand items (one at a time: a reel, spare parts) that drop where you're caught
--   the evidence cassette (pocketed; the chapter is cleared only if it leaves the building)
--   optional story tapes, delivered through the front doors' mail slot
--   the two shocks (on progress, with a fallback time if the crew stalls)
--   dubbing onto the cassette while riding the faders
--   quarantine shutters, and Last Call
-- Everything made during a round lives in one folder and is cleared at the next round.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))
local StoryTapes = require(Shared:WaitForChild("StoryTapes"))

local DoorService = require(script.Parent.Parent.DoorService)
local LightingService = require(script.Parent.Parent.LightingService)
local MapContract = require(script.Parent.Parent.MapContract)
local MonsterService = require(script.Parent.Parent.MonsterService)
local NoiseService = require(script.Parent.Parent.NoiseService)
local ProgressService = require(script.Parent.Parent.ProgressService)
local RoundState = require(script.Parent.Parent.RoundState)

export type Hooks = {
	isTarget: (Player) -> boolean,
	participants: () -> { Player },
	catchInside: () -> (), -- Last Call is over: everyone still inside is caught
}

export type StoryTape = StoryTapes.Tape

-- `throw` is how it lands when thrown ("light", "glass", "heavy"), or nil if it can't be thrown.
type ItemSpec = {
	id: string,
	name: string,
	color: Color3,
	size: Vector3,
	weight: number,
	throw: string?,
}
type OpenPuzzle = { kind: string, part: BasePart }
type Dub = {
	part: BasePart,
	holder: Player?,
	progress: number,
	level: number,
	push: number,
	lastSpike: number,
	onDone: (Player) -> (),
	prompt: ProximityPrompt,
}

local PROMPT_RANGE = 8
local PUZZLE_RANGE = 12 -- walk farther than this from a puzzle and it closes
local HAND_ITEMS: { [string]: ItemSpec } = {}

local Kit = {}

local layout: MapContract.Layout
local hooks: Hooks
local folder: Folder -- everything spawned this round
local roundPrompts: { ProximityPrompt } = {}
local answerHandlers: { [string]: (Player, any) -> () } = {}
local openPuzzles: { [Player]: OpenPuzzle } = {}
local carriedTapes: { [Player]: { StoryTape } } = {}
local cassetteHolder: Player? = nil
local cleared = false
local roundId = 0
local roundStart = 0
local shocksFired = 0
local shockQueued = 0
local lastShockAt = 0
local shockHandlers: { () -> () } = {}
local dub: Dub? = nil
local lastCallRunning = false
local rng = Random.new()

-- ===== Talking to players =====

function Kit.notify(player: Player, message: string)
	Remotes.Notify:FireClient(player, message)
end

function Kit.notifyAll(message: string)
	Remotes.Notify:FireAllClients(message)
end

-- The handler, on everyone's walkie from his van outside.
function Kit.radio(text: string)
	for _, player in hooks.participants() do
		Remotes.Radio:FireClient(player, "Handler", "", text)
	end
end

-- A fragment of the 1987 broadcast bleeding through the walkies.
function Kit.broadcast(text: string)
	for _, player in hooks.participants() do
		Remotes.Radio:FireClient(player, "1987 broadcast", "", text)
	end
end

function Kit.document(player: Player, title: string, body: string)
	Remotes.Document:FireClient(player, title, body)
end

function Kit.setObjectives(lines: { string })
	RoundState.set("ObjectiveText", table.concat(lines, "\n"))
end

-- ===== Sound =====

function Kit.noise(position: Vector3, loudness: number, kind: string, source: Player?)
	NoiseService.emit(position, loudness, kind, source)
end

function Kit.sound(
	soundId: string,
	position: Vector3,
	volume: number?,
	maxDistance: number?,
	speed: number?
)
	Sounds.playAt(soundId, position, volume, maxDistance, speed)
end

-- A sound through every one of the building's speakers.
function Kit.speakers(soundId: string, volume: number?, speed: number?)
	for _, speaker in layout.speakers do
		Sounds.playAt(soundId, speaker, volume or 0.9, 300, speed)
	end
end

function Kit.randomSpeaker(): Vector3
	return layout.speakers[rng:NextInteger(1, #layout.speakers)]
end

-- ===== Map =====

function Kit.layout(): MapContract.Layout
	return layout
end

function Kit.objective(name: string): BasePart
	local found = layout.objectives[name]
	assert(found, "objective missing: " .. name) -- chapters list what they need, checked at start
	return found
end

function Kit.roundId(): number
	return roundId
end

function Kit.elapsed(): number
	return os.clock() - roundStart
end

function Kit.random(): Random
	return rng
end

-- ===== Prompts =====

-- A prompt for this round only (removed at the next round). `onTrigger` runs for players in the round.
function Kit.prompt(
	parent: BasePart,
	action: string,
	object: string,
	hold: number,
	onTrigger: (Player) -> ()
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = hold
	prompt.MaxActivationDistance = PROMPT_RANGE
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	prompt.Triggered:Connect(function(player)
		if hooks.isTarget(player) then
			onTrigger(player)
		end
	end)
	table.insert(roundPrompts, prompt)
	return prompt
end

-- A small part for this round (a reel on a shelf, clutter on the road case).
function Kit.spawnPart(
	name: string,
	cframe: CFrame,
	size: Vector3,
	color: Color3,
	material: Enum.Material?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Parent = folder
	return p
end

-- ===== Puzzles =====

-- Opens a puzzle on `player`'s screen, tied to `part` (walk away and it closes).
function Kit.openPuzzle(player: Player, kind: string, part: BasePart, data: any)
	openPuzzles[player] = { kind = kind, part = part }
	Remotes.Puzzle:FireClient(player, kind, data)
end

function Kit.closePuzzle(player: Player)
	if openPuzzles[player] then
		openPuzzles[player] = nil
		Remotes.Puzzle:FireClient(player, "", nil)
	end
end

-- `handler(player, answer)` gets answers to puzzles of `kind`, only from players who have it open
-- and are still at it.
function Kit.onAnswer(kind: string, handler: (Player, any) -> ())
	answerHandlers[kind] = handler
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	return nil
end

local function near(player: Player, part: BasePart, range: number): boolean
	local r = rootOf(player)
	return r ~= nil and (r.Position - part.Position).Magnitude <= range
end

local function onPuzzleAnswer(player: Player, kind: unknown, answer: unknown)
	local open = openPuzzles[player]
	if type(kind) ~= "string" or not open or open.kind ~= kind then
		return
	end
	if not hooks.isTarget(player) or not near(player, open.part, PUZZLE_RANGE) then
		Kit.closePuzzle(player)
		return
	end
	local handler = answerHandlers[kind]
	if handler then
		handler(player, answer)
	end
end

-- ===== Hand items =====

-- Registers a kind of thing players carry in their hands (one at a time). `weight` (0 to 1) slows
-- the sprint; `throw` makes it throwable ("light", "glass" or "heavy").
function Kit.defineItem(
	id: string,
	name: string,
	color: Color3,
	size: Vector3,
	weight: number?,
	throw: string?
)
	HAND_ITEMS[id] =
		{ id = id, name = name, color = color, size = size, weight = weight or 0, throw = throw }
end

function Kit.holding(player: Player): string?
	local held = player:GetAttribute("Holding")
	return if type(held) == "string" and held ~= "" then held else nil
end

local function setHolding(player: Player, id: string?)
	local spec = if id then HAND_ITEMS[id] else nil
	player:SetAttribute("Holding", id or "")
	player:SetAttribute("HoldingName", if spec then spec.name else "")
	player:SetAttribute("HoldWeight", if spec then spec.weight else 0)
	player:SetAttribute("CanThrow", spec ~= nil and spec.throw ~= nil)
end

local spawnHandItem: (string, Vector3) -> ()

-- Gives `player` an item, or leaves it at `fallback` (where it was) if their hands are full.
function Kit.give(player: Player, id: string, fallback: Vector3): boolean
	if Kit.holding(player) then
		spawnHandItem(id, fallback)
		Kit.notify(
			player,
			"Your hands are full. It's left where it was (G puts down what you hold)."
		)
		return false
	end
	setHolding(player, id)
	return true
end

function Kit.take(player: Player)
	setHolding(player, nil)
end

spawnHandItem = function(id: string, position: Vector3)
	local spec = HAND_ITEMS[id]
	if not spec then
		return
	end
	local item = Kit.spawnPart(spec.name, CFrame.new(position), spec.size, spec.color)
	if not spec.throw then
		-- Objective items glow faintly so they can be found in the dark; junk doesn't.
		local light = Instance.new("PointLight")
		light.Color = spec.color
		light.Brightness = 0.4
		light.Range = 4
		light.Parent = item
	end
	local prompt = Kit.prompt(item, "Pick up", spec.name, 0, function(player)
		if not item.Parent then
			return
		end
		if Kit.holding(player) then
			Kit.notify(player, "Your hands are full (G puts down what you hold).")
			return
		end
		item:Destroy()
		setHolding(player, id)
	end)
	prompt.MaxActivationDistance = 7
end

-- Puts a hand item on the floor under a position.
local function floorUnder(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { layout.map }
	local hit = Workspace:Raycast(position + Vector3.new(0, 1, 0), Vector3.new(0, -12, 0), params)
	return if hit then hit.Position + Vector3.new(0, 0.3, 0) else position
end

local function dropHeld(player: Player, position: Vector3)
	local held = Kit.holding(player)
	if held then
		setHolding(player, nil)
		spawnHandItem(held, floorUnder(position))
	end
end

-- Throwing what you hold: it flies in an arc and makes noise where it lands (a decoy). Bottles
-- smash; cans and pipes can be picked up again.
local THROW_NOISE: { [string]: { loudness: number, sound: string } } = {
	light = { loudness = Config.NOISE.THROW_LIGHT, sound = Sounds.TAPE_CLUNK },
	glass = { loudness = Config.NOISE.THROW_GLASS, sound = Sounds.LANDING },
	heavy = { loudness = Config.NOISE.THROW_HEAVY, sound = Sounds.CLUTTER },
}

local function onThrow(player: Player, direction: unknown)
	local held = Kit.holding(player)
	local spec = if held then HAND_ITEMS[held] else nil
	local r = rootOf(player)
	if
		not spec
		or not spec.throw
		or not r
		or not hooks.isTarget(player)
		or typeof(direction) ~= "Vector3"
		or direction.Magnitude < 0.1
		or direction ~= direction
	then
		return
	end
	setHolding(player, nil)
	local throwKind = spec.throw :: string
	local C = Config.CARRY
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { layout.map }
	local position = r.Position + Vector3.new(0, 1.5, 0) + direction.Unit * 1.5
	local velocity = direction.Unit * C.THROW_SPEED
	local flying = Kit.spawnPart(spec.name, CFrame.new(position), spec.size, spec.color)
	local myRound = roundId
	task.spawn(function()
		local step = 1 / 30
		local landed = position
		for _ = 1, 90 do
			local nextPosition = position + velocity * step
			velocity -= Vector3.new(0, C.THROW_GRAVITY * step, 0)
			local hit = Workspace:Raycast(position, nextPosition - position, params)
			if hit then
				landed = hit.Position + hit.Normal * 0.3
				break
			end
			position = nextPosition
			landed = position
			flying.CFrame = CFrame.new(position)
			task.wait(step)
			if roundId ~= myRound then
				return
			end
		end
		flying:Destroy()
		local noise = THROW_NOISE[throwKind]
		Kit.sound(noise.sound, landed, 0.9, 120)
		Kit.noise(landed, noise.loudness, "throw", nil)
		if throwKind ~= "glass" then
			spawnHandItem(spec.id, landed)
		end
	end)
end

local function onDropItem(player: Player)
	local r = rootOf(player)
	if r and hooks.isTarget(player) then
		dropHeld(player, r.Position + r.CFrame.LookVector * 2)
	end
end

-- ===== The evidence cassette =====

local function setCassetteState(stateName: string)
	RoundState.set("Cassette", stateName)
end

function Kit.giveCassette(player: Player)
	cassetteHolder = player
	player:SetAttribute("HasCassette", true)
	setCassetteState("carried")
end

function Kit.hasCassette(player: Player): boolean
	return cassetteHolder == player
end

local function dropCassette(position: Vector3)
	local holder = cassetteHolder
	if holder then
		holder:SetAttribute("HasCassette", false)
	end
	cassetteHolder = nil
	setCassetteState("dropped")
	local tape = Kit.spawnPart(
		"Cassette",
		CFrame.new(floorUnder(position)),
		Vector3.new(0.8, 0.25, 0.55),
		Color3.fromRGB(240, 230, 210),
		Enum.Material.Neon
	)
	Kit.prompt(tape, "Take the cassette", "Evidence", 0, function(player)
		if tape.Parent then
			tape:Destroy()
			Kit.giveCassette(player)
			Kit.notifyAll(player.DisplayName .. " has the cassette.")
		end
	end)
end

function Kit.cleared(): boolean
	return cleared
end

-- ===== Optional story tapes =====

function Kit.spawnTapes(tapes: { StoryTape }, count: number)
	local spots = table.clone(layout.tapeSpots)
	local pool = table.clone(tapes)
	for _ = 1, math.min(count, #spots, #pool) do
		local spot = table.remove(spots, rng:NextInteger(1, #spots)) :: Vector3
		local tapeData = table.remove(pool, rng:NextInteger(1, #pool)) :: StoryTape
		local tape = Kit.spawnPart(
			"StoryTape",
			CFrame.new(spot),
			Vector3.new(0.7, 0.2, 0.45),
			Color3.fromRGB(70, 60, 50)
		)
		Kit.prompt(tape, "Pick up", "Old tape", 0, function(player)
			if not tape.Parent then
				return
			end
			tape:Destroy()
			local list = carriedTapes[player] or {}
			table.insert(list, tapeData)
			carriedTapes[player] = list
			player:SetAttribute("TapesCarried", #list)
			Kit.notify(
				player,
				string.format(
					'Tape: "%s". Push it through the mail slot in the front doors to keep it.',
					tapeData.title
				)
			)
		end)
	end
end

local function deliverTapes(player: Player)
	local list = carriedTapes[player]
	if not list or #list == 0 then
		Kit.notify(
			player,
			"The mail slot. Tapes pushed through it reach the handler's van outside."
		)
		return
	end
	local slot = Kit.objective("MailSlot")
	Kit.sound(Sounds.TAPE_CLUNK, slot.Position, 0.6)
	Kit.noise(slot.Position, Config.NOISE.MAIL_SLOT, "mail", player)
	for _, tapeData in list do
		for _, member in hooks.participants() do
			ProgressService.addStoryTape(member, tapeData.id)
		end
		ProgressService.award(player, "Delivered a tape", Config.REWARDS.TAPE_DELIVERED)
		Kit.notifyAll(string.format('Tape delivered: "%s".', tapeData.title))
	end
	carriedTapes[player] = {}
	player:SetAttribute("TapesCarried", 0)
end

local function dropTapes(player: Player, position: Vector3)
	local list = carriedTapes[player]
	carriedTapes[player] = nil
	player:SetAttribute("TapesCarried", 0)
	if not list then
		return
	end
	for i, tapeData in list do
		local tape = Kit.spawnPart(
			"StoryTape",
			CFrame.new(floorUnder(position + Vector3.new(i * 0.8, 0, 0))),
			Vector3.new(0.7, 0.2, 0.45),
			Color3.fromRGB(70, 60, 50)
		)
		Kit.prompt(tape, "Pick up", "Old tape", 0, function(by)
			if not tape.Parent then
				return
			end
			tape:Destroy()
			local carried = carriedTapes[by] or {}
			table.insert(carried, tapeData)
			carriedTapes[by] = carried
			by:SetAttribute("TapesCarried", #carried)
		end)
	end
end

-- ===== Shocks =====

-- `handlers[n]` runs for shock n (1 or 2). Progress calls Kit.shock(n); stalling fires it anyway.
function Kit.setShocks(handlers: { () -> () })
	shockHandlers = handlers
end

function Kit.shocksFired(): number
	return shocksFired
end

local function fire(n: number)
	if n ~= shocksFired + 1 or n > #shockHandlers then
		return
	end
	shocksFired = n
	lastShockAt = os.clock()
	RoundState.set("Shocks", shocksFired)
	task.spawn(shockHandlers[n])
end

-- Progress asks for shock `n`. The second never follows the first sooner than SHOCK_MIN_GAP.
function Kit.shock(n: number)
	if n <= shocksFired then
		return
	end
	if n == 2 and shocksFired < 1 then
		fire(1) -- a fast crew skipped ahead: the first shock comes first
	end
	if n == 2 and os.clock() - lastShockAt < Config.PACING.SHOCK_MIN_GAP then
		shockQueued = math.max(shockQueued, n)
		return
	end
	fire(n)
end

local function updateShocks()
	local elapsed = os.clock() - roundStart
	if shocksFired < 1 and elapsed >= Config.PACING.SHOCK1_FALLBACK then
		fire(1)
	end
	local gapOk = os.clock() - lastShockAt >= Config.PACING.SHOCK_MIN_GAP
	if shocksFired == 1 and gapOk then
		if shockQueued >= 2 or elapsed >= Config.PACING.SHOCK2_FALLBACK then
			fire(2)
		end
	end
end

-- ===== Dubbing onto the cassette =====

-- A hold at `part`: whoever holds it rides the faders while the sound plays through the building
-- (pulling the monster in). Stepping away pauses it; anyone can take over. `onDone(holder)` runs
-- when it reaches the end. `firstHolder` starts holding at once.
function Kit.startDub(part: BasePart, action: string, onDone: (Player) -> (), firstHolder: Player?)
	local prompt: ProximityPrompt
	local function beginHold(player: Player)
		local d = dub
		if not d or d.holder then
			return
		end
		d.holder = player
		d.push = 0
		prompt.Enabled = false
		player:SetAttribute("DubLevel", d.level)
		Kit.openPuzzle(player, "faders", part, { band = Config.DUB.BAND })
	end
	prompt = Kit.prompt(part, action, part.Name, 0, beginHold)
	dub = {
		part = part,
		holder = nil,
		progress = 0,
		level = 0.5,
		push = 0,
		lastSpike = 0,
		onDone = onDone,
		prompt = prompt,
	}
	RoundState.set("DubProgress", 0)
	if firstHolder then
		beginHold(firstHolder)
	end
end

local function releaseDub(d: Dub)
	local holder = d.holder
	if holder then
		holder:SetAttribute("DubLevel", nil)
		Kit.closePuzzle(holder)
	end
	d.holder = nil
	d.prompt.Enabled = true
end

local recordingPulse = 0

local function updateDub(dt: number)
	local d = dub
	if not d then
		return
	end
	local holder = d.holder
	if holder and (not hooks.isTarget(holder) or not near(holder, d.part, Config.DUB.RANGE)) then
		Kit.notify(holder, "You left the desk. Someone has to hold it.")
		releaseDub(d)
		holder = nil
	end
	if not holder then
		return
	end
	-- The level wanders; the holder pushes it back toward the middle.
	local D = Config.DUB
	d.level = math.clamp(
		d.level + (rng:NextNumber() - 0.5) * 2 * D.DRIFT * dt + d.push * D.NUDGE * dt,
		0,
		1
	)
	holder:SetAttribute("DubLevel", d.level)
	local now = os.clock()
	if math.abs(d.level - 0.5) > D.BAND and now - d.lastSpike >= D.SPIKE_COOLDOWN then
		d.lastSpike = now
		Kit.speakers(Sounds.RECORDING, 1, 0.8)
		Kit.noise(d.part.Position, Config.NOISE.FADER_SPIKE, "spike", holder)
	end
	-- The recording itself, through the building, about once a second.
	recordingPulse += dt
	if recordingPulse >= 1 then
		recordingPulse = 0
		Kit.speakers(Sounds.RECORDING, 0.7, 0.5)
		Kit.noise(d.part.Position, Config.NOISE.RECORDING, "recording", nil)
	end
	d.progress = math.min(1, d.progress + dt / D.SECONDS)
	RoundState.set("DubProgress", d.progress)
	if d.progress >= 1 then
		dub = nil
		holder:SetAttribute("DubLevel", nil)
		Kit.closePuzzle(holder)
		d.prompt:Destroy()
		d.onDone(holder)
	end
end

local function onFader(player: Player, push: unknown)
	local d = dub
	if d and d.holder == player and typeof(push) == "number" and push == push then
		d.push = math.clamp(push, -1, 1)
	end
end

-- ===== Shutters =====

function Kit.setShutters(route: string, closed: boolean)
	for _, shutter in layout.shutters do
		if shutter.route == route then
			local p = shutter.part
			p.CanCollide = closed
			p.CanQuery = closed
			TweenService:Create(
				p,
				TweenInfo.new(if closed then 0.6 else 1.5, Enum.EasingStyle.Quad),
				{ CFrame = if closed then shutter.closed else shutter.opened }
			):Play()
			if closed then
				Kit.sound(Sounds.SHUTTER, shutter.closed.Position, 1, 150)
				Kit.noise(shutter.closed.Position, Config.NOISE.SHUTTER, "shutter", nil)
			end
		end
	end
end

local function resetShutters()
	for _, shutter in layout.shutters do
		local open = shutter.startsOpen
		shutter.part.CFrame = if open then shutter.opened else shutter.closed
		shutter.part.CanCollide = not open
		shutter.part.CanQuery = not open
	end
end

-- ===== Last Call =====

-- The complete sound wakes every machine: the front door locks release for a while, the short-route
-- shutter drops, and the monster frenzies. When the locks re-engage, everyone inside is caught.
function Kit.lastCall()
	if lastCallRunning then
		return
	end
	lastCallRunning = true
	local myRound = roundId
	local LC = Config.LAST_CALL
	RoundState.set("LastCall", true)
	RoundState.set("LastCallEnds", Workspace:GetServerTimeNow() + LC.DOORS_OPEN)
	RoundState.set("DoorsOpen", true)
	DoorService.set(layout.frontDoor, true)
	Kit.sound(Sounds.LOCK_SLAM, layout.frontDoor.Position, 1, 200, 1.3)
	Kit.setShutters("short", true)
	MonsterService.holdFrenzy(true, LC.FRENZY_HEARING)
	Kit.notifyAll("The locks released. GET OUT.")
	task.delay(LC.DOORS_OPEN, function()
		if roundId ~= myRound or RoundState.get("Phase") ~= "Playing" then
			return
		end
		RoundState.set("LastCall", false)
		RoundState.set("DoorsOpen", false)
		DoorService.set(layout.frontDoor, false)
		Kit.sound(Sounds.LOCK_SLAM, layout.frontDoor.Position, 1, 200)
		MonsterService.holdFrenzy(false)
		hooks.catchInside()
	end)
end

-- ===== Round hooks (called by ChapterService) =====

-- A player escaped through the exit. Returns true if they carried the cassette out.
function Kit.onEscape(player: Player): boolean
	-- Tapes still in their pocket are delivered by hand.
	local list = carriedTapes[player]
	if list and #list > 0 then
		for _, tapeData in list do
			for _, member in hooks.participants() do
				ProgressService.addStoryTape(member, tapeData.id)
			end
		end
		carriedTapes[player] = nil
		player:SetAttribute("TapesCarried", 0)
	end
	setHolding(player, nil)
	if cassetteHolder == player then
		cassetteHolder = nil
		player:SetAttribute("HasCassette", false)
		cleared = true
		setCassetteState("out")
		RoundState.set("ChapterCleared", true)
		ProgressService.award(player, "Carried the evidence out", Config.REWARDS.CASSETTE_OUT)
		return true
	end
	return false
end

-- A player was caught (or left) at `position`: what they carried stays behind.
function Kit.onLost(player: Player, position: Vector3)
	Kit.closePuzzle(player)
	local d = dub
	if d and d.holder == player then
		releaseDub(d)
	end
	dropHeld(player, position)
	dropTapes(player, position)
	if cassetteHolder == player then
		dropCassette(position)
	end
end

function Kit.reset()
	roundId += 1
	roundStart = os.clock()
	for _, prompt in roundPrompts do
		prompt:Destroy()
	end
	roundPrompts = {}
	answerHandlers = {}
	for player in openPuzzles do
		Kit.closePuzzle(player)
	end
	openPuzzles = {}
	folder:ClearAllChildren()
	carriedTapes = {}
	cassetteHolder = nil
	cleared = false
	shocksFired = 0
	shockQueued = 0
	lastShockAt = 0
	shockHandlers = {}
	dub = nil
	lastCallRunning = false
	for _, player in Players:GetPlayers() do
		setHolding(player, nil)
		player:SetAttribute("HasCassette", false)
		player:SetAttribute("TapesCarried", 0)
		player:SetAttribute("DubLevel", nil)
	end
	RoundState.set("ObjectiveText", "")
	RoundState.set("Cassette", "none")
	RoundState.set("ChapterCleared", false)
	RoundState.set("Shocks", 0)
	RoundState.set("DubProgress", 0)
	RoundState.set("LastCall", false)
	RoundState.set("DoorsOpen", false)
	DoorService.set(layout.frontDoor, false)
	resetShutters()
	LightingService.reset()
	-- Loose things to throw, where the map put them.
	local kinds = { "bottle", "can", "pipe" }
	for _, spot in layout.throwableSpots do
		local item = spot:GetAttribute("Item")
		local id = if type(item) == "string" and HAND_ITEMS[item]
			then item
			else kinds[rng:NextInteger(1, #kinds)]
		spawnHandItem(id, spot.Position)
	end
	Kit.prompt(Kit.objective("MailSlot"), "Push tapes through", "Mail slot", 0.6, deliverTapes)
end

function Kit.init(map: MapContract.Layout, roundHooks: Hooks)
	layout = map
	hooks = roundHooks
	folder = Instance.new("Folder")
	folder.Name = "ChapterItems"
	folder.Parent = Workspace
	Remotes.PuzzleAnswer.OnServerEvent:Connect(onPuzzleAnswer)
	Remotes.Fader.OnServerEvent:Connect(onFader)
	Remotes.DropItem.OnServerEvent:Connect(onDropItem)
	Remotes.Throw.OnServerEvent:Connect(onThrow)
	Kit.defineItem(
		"bottle",
		"Glass bottle",
		Color3.fromRGB(70, 110, 80),
		Vector3.new(0.4, 1, 0.4),
		0.1,
		"glass"
	)
	Kit.defineItem(
		"can",
		"Tin can",
		Color3.fromRGB(170, 170, 160),
		Vector3.new(0.4, 0.6, 0.4),
		0.05,
		"light"
	)
	Kit.defineItem(
		"pipe",
		"Metal pipe",
		Color3.fromRGB(110, 100, 90),
		Vector3.new(0.3, 0.3, 2.4),
		0.7,
		"heavy"
	)

	-- Puzzles close when their player walks away; the dub and the shocks tick here too.
	local last = os.clock()
	task.spawn(function()
		while true do
			task.wait(0.1)
			local now = os.clock()
			local dt = now - last
			last = now
			for player, open in openPuzzles do
				if
					player.Parent ~= Players
					or not hooks.isTarget(player)
					or not near(player, open.part, PUZZLE_RANGE)
				then
					Kit.closePuzzle(player)
				end
			end
			if RoundState.get("Phase") == "Playing" then
				updateDub(dt)
				updateShocks()
			end
		end
	end)
end

return Kit
