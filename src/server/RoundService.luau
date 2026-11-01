--!strict
-- The round loop: lobby countdown -> playing (a chapter) -> results -> lobby.
-- Players are spawned by this service only (automatic respawning is off), so it always knows
-- who is in the round, who was caught and who escaped.
--
-- There is no round timer: a round ends when nobody is left inside, because everyone escaped or
-- the monster caught everyone (a last survivor can still win alone). Instead of a clock, soft
-- pressure builds the longer the round runs: thicker fog, sharper hearing, a monster that comes
-- looking sooner. Caught players become echoes and stay in the round until it ends.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local ChapterService = require(script.Parent.ChapterService)
local DoorService = require(script.Parent.DoorService)
local EchoService = require(script.Parent.EchoService)
local LightingService = require(script.Parent.LightingService)
local MapContract = require(script.Parent.MapContract)
local MonsterService = require(script.Parent.MonsterService)
local ProgressService = require(script.Parent.ProgressService)
local RoundState = require(script.Parent.RoundState)

type Status = "alive" | "caught" | "escaped"

local RoundService = {}

local layout: MapContract.Layout
local phase = "Lobby"
local participants: { [Player]: Status } = {}
local roundId = 0
local rng = Random.new()

-- For the results: how close the monster came, seconds left on the doors, who rescued whom.
local closest: { [Player]: number } = {}
local doorsLeft: { [Player]: number } = {}
local rescues: { [Player]: { string } } = {}

local function notifyAll(message: string)
	Remotes.Notify:FireAllClients(message)
end

local function setPhase(newPhase: string)
	phase = newPhase
	RoundState.set("Phase", newPhase)
end

local function countAlive(): number
	local alive = 0
	for _, status in participants do
		if status == "alive" then
			alive += 1
		end
	end
	RoundState.set("Alive", alive)
	return alive
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	return nil
end

function RoundService.isTarget(player: Player): boolean
	local character = player.Character
	return phase == "Playing"
		and participants[player] == "alive"
		and character ~= nil
		and character:GetAttribute("InRound") == true
end

-- Everyone playing this round (alive, caught or escaped) who is still in the server.
function RoundService.participants(): { Player }
	local list: { Player } = {}
	for player in participants do
		if player.Parent == Players then
			table.insert(list, player)
		end
	end
	return list
end

local onDied: (Player) -> ()

-- Other systems (items) hear about spawns and new rounds through these.
local spawnListeners: { (Player, Model, boolean) -> () } = {}
local roundStartListeners: { () -> () } = {}

-- `callback(player, character, inRound)` runs after every spawn, in the round or in the lobby.
function RoundService.onSpawn(callback: (Player, Model, boolean) -> ())
	table.insert(spawnListeners, callback)
end

local caughtListeners: { (Player, Vector3) -> () } = {}
local roundEndListeners: { () -> () } = {}

-- `callback(player, position)` runs when a player is caught, with where it happened.
function RoundService.onCaught(callback: (Player, Vector3) -> ())
	table.insert(caughtListeners, callback)
end

-- `callback()` runs when a round ends, before results are shown.
function RoundService.onRoundEnd(callback: () -> ())
	table.insert(roundEndListeners, callback)
end

local afterResultsListeners: { ({ Player }) -> () } = {}

-- `callback(players)` runs after the results, before the next lobby; it may wait (the replay vote).
function RoundService.afterResults(callback: ({ Player }) -> ())
	table.insert(afterResultsListeners, callback)
end

-- `callback()` runs when a round starts, before anyone is spawned into it.
function RoundService.onRoundStart(callback: () -> ())
	table.insert(roundStartListeners, callback)
end

-- Spawns a fresh character at `cframe`, inside the round or not.
local function spawnAt(player: Player, cframe: CFrame, inRound: boolean)
	if player.Parent ~= Players then
		return
	end
	player:LoadCharacterAsync()
	local character = player.Character
	if not character then
		return
	end
	player:SetAttribute("Echo", false)
	character:SetAttribute("InRound", inRound)
	character:SetAttribute("FlashlightOn", true) -- everyone starts with the torch lit
	local spread = Vector3.new(rng:NextNumber(-4, 4), 0, rng:NextNumber(-3, 3))
	character:PivotTo(cframe + spread)
	for _, callback in spawnListeners do
		task.spawn(callback, player, character, inRound)
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.WALK_SPEED
		humanoid.Died:Once(function()
			-- Only the current body counts: a replaced character (escape, results) isn't a death.
			if player.Character == character then
				onDied(player)
			end
		end)
	end
end

local function sendToLobby(player: Player)
	spawnAt(player, layout.lobbySpawn, false)
end

-- Marks a player caught where they are: what they carried stays behind, the team is told.
local function markCaught(player: Player, position: Vector3)
	participants[player] = "caught"
	ChapterService.onLost(player, position)
	for _, callback in caughtListeners do
		task.spawn(callback, player, position)
	end
	notifyAll(player.DisplayName .. " was caught.")
	countAlive()
end

-- Called by the monster when it reaches someone: it rips their headset off, and they're an echo.
function RoundService.catch(player: Player)
	if phase ~= "Playing" or participants[player] ~= "alive" then
		return
	end
	local r = rootOf(player)
	local position = if r then r.Position else layout.spawn.Position
	markCaught(player, position)
	EchoService.entrance(player)
end

-- A body lost some other way (a fall, a reset): caught there, and back as an entranced body.
onDied = function(player: Player)
	local r = rootOf(player)
	local position = if r then r.Position else layout.spawn.Position
	if phase == "Playing" and participants[player] == "alive" then
		markCaught(player, position)
		task.delay(2, function()
			if
				phase == "Playing"
				and participants[player] == "caught"
				and player.Parent == Players
			then
				spawnAt(player, CFrame.new(position + Vector3.new(0, 3, 0)), true)
				EchoService.entrance(player)
			end
		end)
		return
	end
	task.delay(3, function()
		if player.Parent == Players and participants[player] ~= "alive" then
			sendToLobby(player)
		end
	end)
end

local revived: { [Player]: boolean } = {}

-- Whether a caught player may come back now: once per round, while someone is still inside.
function RoundService.canRevive(player: Player): boolean
	return phase == "Playing"
		and participants[player] == "caught"
		and not revived[player]
		and not RoundState.get("LastCallOver")
		and countAlive() > 0
end

-- Brings a caught player back at `where` (default: the entrance). The price is already paid.
function RoundService.revive(player: Player, where: CFrame?, by: Player?): boolean
	if not RoundService.canRevive(player) then
		return false
	end
	revived[player] = true
	participants[player] = "alive"
	player:SetAttribute("CanRevive", false)
	spawnAt(player, where or layout.spawn, true)
	countAlive()
	notifyAll(player.DisplayName .. " is back.")
	if by then
		local list = rescues[by] or {}
		table.insert(list, player.DisplayName)
		rescues[by] = list
	end
	return true
end

-- Last Call is over: the locks re-engaged with these players still inside.
local function catchInside()
	RoundState.set("LastCallOver", true)
	for player, status in participants do
		if status == "alive" then
			RoundService.catch(player)
		end
	end
	notifyAll("The locks re-engaged.")
end

local function onExitTouched(hit: BasePart)
	if phase ~= "Playing" or not RoundState.get("DoorsOpen") then
		return
	end
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if player and participants[player] == "alive" and RoundService.isTarget(player) then
		participants[player] = "escaped"
		local ends = RoundState.get("LastCallEnds")
		if type(ends) == "number" then
			doorsLeft[player] = math.max(0, ends - Workspace:GetServerTimeNow())
		end
		local carriedOut = ChapterService.onEscape(player)
		ProgressService.award(player, "Escaped", Config.REWARDS.ESCAPE)
		RoundState.set("Escaped", (RoundState.get("Escaped") or 0) + 1)
		Sounds.playAt(Sounds.STINGER, layout.exitZone.Position, 1, 80)
		notifyAll(
			if carriedOut
				then player.DisplayName .. " escaped with the cassette!"
				else player.DisplayName .. " escaped!"
		)
		countAlive()
		sendToLobby(player)
	end
end

local function runLobby()
	setPhase("Lobby")
	while true do
		while #Players:GetPlayers() < Config.MIN_PLAYERS do
			RoundState.set("Countdown", -1)
			task.wait(1)
		end
		local remaining = Config.LOBBY_COUNTDOWN
		while remaining > 0 and #Players:GetPlayers() >= Config.MIN_PLAYERS do
			-- Everyone ready: no need to wait out the whole countdown.
			local players = Players:GetPlayers()
			local ready = 0
			for _, player in players do
				if player:GetAttribute("Ready") == true then
					ready += 1
				end
			end
			RoundState.set("Ready", ready)
			if ready == #players then
				remaining = math.min(remaining, Config.READY_COUNTDOWN)
			end
			RoundState.set("Countdown", remaining)
			task.wait(1)
			remaining -= 1
		end
		if remaining <= 0 then
			return
		end
	end
end

-- Soft pressure: 0 until PRESSURE_START, rising to 1 at PRESSURE_FULL.
local function pressureAt(elapsed: number): number
	local P = Config.PACING
	return math.clamp((elapsed - P.PRESSURE_START) / (P.PRESSURE_FULL - P.PRESSURE_START), 0, 1)
end

local function runRound()
	roundId += 1
	local myRound = roundId
	participants = {}
	closest = {}
	doorsLeft = {}
	rescues = {}
	revived = {}
	for _, player in Players:GetPlayers() do
		participants[player] = "alive"
	end
	RoundState.set("Escaped", 0)
	RoundState.set("LastCallOver", false)
	ProgressService.startRound()
	for player in participants do
		player:SetAttribute("Ready", false)
		ProgressService.award(player, "Played a round", Config.REWARDS.ROUND)
	end
	DoorService.resetAll()
	MonsterService.despawn()
	MonsterService.setPressure(0)
	EchoService.reset()
	ChapterService.startRound()
	for _, callback in roundStartListeners do
		task.spawn(callback)
	end
	setPhase("Playing")
	countAlive()

	for player in participants do
		spawnAt(player, layout.spawn, true)
	end

	task.delay(Config.MONSTER.ARRIVAL_DELAY, function()
		if roundId == myRound and phase == "Playing" then
			MonsterService.spawn(layout.monsterSpawn)
		end
	end)

	-- How close the monster comes to each living player, for the results.
	local sampler = RunService.Heartbeat:Connect(function()
		local monster = MonsterService.position()
		if not monster then
			return
		end
		for player, status in participants do
			if status == "alive" then
				local r = rootOf(player)
				if r then
					local d = (r.Position - monster).Magnitude
					if d < (closest[player] or math.huge) then
						closest[player] = d
					end
				end
			end
		end
	end)

	local started = os.clock()
	while countAlive() > 0 and roundId == myRound do
		local pressure = pressureAt(os.clock() - started)
		MonsterService.setPressure(pressure)
		LightingService.setPressure(pressure)
		RoundState.set("Pressure", pressure)
		for player in participants do
			player:SetAttribute("CanRevive", RoundService.canRevive(player))
		end
		task.wait(1)
	end
	sampler:Disconnect()
end

local function resultLines(player: Player): { string }
	local lines: { string } = {}
	local d = closest[player]
	if d then
		table.insert(lines, string.format("Closest call: %d studs from it", math.floor(d + 0.5)))
	end
	local left = doorsLeft[player]
	if left then
		table.insert(
			lines,
			string.format("Out with %d seconds left on the doors", math.floor(left))
		)
	end
	local saved = rescues[player]
	if saved and #saved > 0 then
		table.insert(lines, "Brought back " .. table.concat(saved, ", "))
	end
	return lines
end

local function runResults()
	for _, callback in roundEndListeners do
		callback()
	end
	setPhase("Results")
	for player in participants do
		player:SetAttribute("CanRevive", false)
	end
	MonsterService.despawn()
	local escaped = RoundState.get("Escaped") or 0
	local total = 0
	for _ in participants do
		total += 1
	end
	local cleared = ChapterService.cleared()
	notifyAll(
		string.format(
			"%d of %d escaped. %s",
			escaped,
			total,
			if cleared
				then "The cassette is out: chapter cleared."
				else "The cassette stayed inside."
		)
	)

	-- Everyone sees everyone's outcome and what they earned.
	local rows = {}
	for player, status in participants do
		if cleared and player.Parent == Players then
			ProgressService.clearChapter(player, ChapterService.chapterId())
		end
		local gain = ProgressService.finishRound(player, status == "escaped")
		local lines = table.clone(gain.lines)
		for _, line in resultLines(player) do
			table.insert(lines, line)
		end
		table.insert(rows, {
			name = player.DisplayName,
			outcome = status,
			xp = gain.xp,
			coins = gain.coins,
			lines = lines,
		})
	end
	Remotes.Results:FireAllClients(rows)
	ProgressService.saveAll()
	task.wait(Config.RESULTS_TIME)
	participants = {}
	EchoService.reset()
	for _, player in Players:GetPlayers() do
		sendToLobby(player)
	end
end

function RoundService.init(map: MapContract.Layout, chapterId: string)
	layout = map
	Players.CharacterAutoLoads = false
	ChapterService.init(layout, chapterId, {
		isTarget = RoundService.isTarget,
		participants = RoundService.participants,
		catchInside = catchInside,
	})
	EchoService.init(layout, RoundService.isTarget)

	Players.PlayerAdded:Connect(sendToLobby)
	Remotes.SetReady.OnServerEvent:Connect(function(player, ready)
		if type(ready) == "boolean" and phase == "Lobby" then
			player:SetAttribute("Ready", ready)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if phase == "Playing" and participants[player] == "alive" then
			local r = rootOf(player)
			ChapterService.onLost(player, if r then r.Position else layout.spawn.Position)
		end
		participants[player] = nil
		closest[player] = nil
		doorsLeft[player] = nil
		rescues[player] = nil
	end)
	-- Anyone who joined before this ran (common in Studio) may have an auto-loaded character.
	for _, player in Players:GetPlayers() do
		task.spawn(sendToLobby, player)
	end

	layout.exitZone.Touched:Connect(onExitTouched)

	task.spawn(function()
		while true do
			runLobby()
			runRound()
			local played: { Player } = {}
			for player in participants do
				table.insert(played, player)
			end
			runResults()
			for _, callback in afterResultsListeners do
				callback(played)
			end
		end
	end)
end

return RoundService
