--!strict
-- The round loop: lobby countdown -> playing (escape the studio) -> results -> lobby.
-- Players are spawned by this service only (automatic respawning is off), so it always knows
-- who is in the round, who was caught and who escaped.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local DoorService = require(script.Parent.DoorService)
local MapContract = require(script.Parent.MapContract)
local MonsterService = require(script.Parent.MonsterService)
local ObjectiveService = require(script.Parent.ObjectiveService)
local ProgressService = require(script.Parent.ProgressService)
local RoundState = require(script.Parent.RoundState)

type Status = "alive" | "caught" | "escaped"

local RoundService = {}

local layout: MapContract.Layout
local phase = "Lobby"
local participants: { [Player]: Status } = {}
local roundId = 0
local rng = Random.new()

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

onDied = function(player: Player)
	local r = rootOf(player)
	if phase == "Playing" and participants[player] == "alive" then
		participants[player] = "caught"
		if r then
			ObjectiveService.dropFuse(player, r.Position - Vector3.new(0, 2.7, 0))
			for _, callback in caughtListeners do
				task.spawn(callback, player, r.Position)
			end
		end
		notifyAll(player.DisplayName .. " was caught.")
		countAlive()
	end
	task.delay(Config.RESPAWN_DELAY, function()
		-- Not if they were revived in the meantime.
		if player.Parent == Players and participants[player] ~= "alive" then
			sendToLobby(player)
		end
	end)
end

local revived: { [Player]: boolean } = {}

-- Whether a caught player may come back now: once per round, while someone is still inside,
-- and not in the round's last seconds.
function RoundService.canRevive(player: Player): boolean
	return phase == "Playing"
		and participants[player] == "caught"
		and not revived[player]
		and countAlive() > 0
		and (RoundState.get("TimeLeft") or 0) >= Config.REVIVE.MIN_TIME_LEFT
end

-- Brings a caught player back at `where` (default: the entrance). The price is already paid.
function RoundService.revive(player: Player, where: CFrame?): boolean
	if not RoundService.canRevive(player) then
		return false
	end
	revived[player] = true
	participants[player] = "alive"
	player:SetAttribute("CanRevive", false)
	spawnAt(player, where or layout.spawn, true)
	countAlive()
	notifyAll(player.DisplayName .. " is back.")
	return true
end

-- Called by the monster when it reaches someone.
function RoundService.catch(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end
end

local function onExitTouched(hit: BasePart)
	if phase ~= "Playing" or not RoundState.get("DoorsOpen") then
		return
	end
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if player and participants[player] == "alive" then
		participants[player] = "escaped"
		ProgressService.award(player, "Escaped", Config.REWARDS.ESCAPE)
		RoundState.set("Escaped", (RoundState.get("Escaped") or 0) + 1)
		notifyAll(player.DisplayName .. " escaped!")
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

local function runRound()
	roundId += 1
	local myRound = roundId
	participants = {}
	for _, player in Players:GetPlayers() do
		participants[player] = "alive"
	end
	RoundState.set("Escaped", 0)
	ProgressService.startRound()
	for player in participants do
		player:SetAttribute("Ready", false)
		ProgressService.award(player, "Played a round", Config.REWARDS.ROUND)
	end
	DoorService.resetAll()
	ObjectiveService.reset()
	MonsterService.despawn()
	for _, callback in roundStartListeners do
		task.spawn(callback)
	end
	setPhase("Playing")
	countAlive()

	for player in participants do
		spawnAt(player, layout.spawn, true)
	end
	notifyAll("Find a way out. Stay quiet. It hears everything.")

	task.delay(Config.MONSTER.ARRIVAL_DELAY, function()
		if roundId == myRound and phase == "Playing" then
			MonsterService.spawn(layout.monsterSpawn)
		end
	end)

	local timeLeft = Config.ROUND_TIME
	revived = {}
	while timeLeft > 0 and countAlive() > 0 do
		RoundState.set("TimeLeft", timeLeft)
		for player in participants do
			player:SetAttribute("CanRevive", RoundService.canRevive(player))
		end
		task.wait(1)
		timeLeft -= 1
	end
	if timeLeft <= 0 then
		for player, status in participants do
			if status == "alive" then
				participants[player] = "caught"
			end
		end
		notifyAll("Time's up. The studio keeps you.")
	end
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
	notifyAll(string.format("%d of %d escaped.", escaped, total))

	-- Everyone sees everyone's outcome and what they earned.
	local rows = {}
	for player, status in participants do
		local gain = ProgressService.finishRound(player, status == "escaped")
		table.insert(rows, {
			name = player.DisplayName,
			outcome = status,
			xp = gain.xp,
			coins = gain.coins,
			lines = gain.lines,
		})
	end
	Remotes.Results:FireAllClients(rows)
	ProgressService.saveAll()
	task.wait(Config.RESULTS_TIME)
	participants = {}
	for _, player in Players:GetPlayers() do
		sendToLobby(player)
	end
end

function RoundService.init(map: MapContract.Layout)
	layout = map
	Players.CharacterAutoLoads = false

	Players.PlayerAdded:Connect(sendToLobby)
	Remotes.SetReady.OnServerEvent:Connect(function(player, ready)
		if type(ready) == "boolean" and phase == "Lobby" then
			player:SetAttribute("Ready", ready)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local r = rootOf(player)
		if r then
			ObjectiveService.dropFuse(player, r.Position - Vector3.new(0, 2.7, 0))
		end
		participants[player] = nil
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
			runResults()
		end
	end)
end

return RoundService
