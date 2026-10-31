--!strict
-- The tape recorder: the team's decoy. Every player in a round carries one.
--
--   R (empty tape): record for a few seconds. Every noise within a few studs of you goes on the tape:
--     your footsteps, a door, your voice, a teammate, even a generator pull.
--   R (recorded tape): set it down in front of you. A few seconds later it plays the recording back
--     from where it sits, with the same timing and loudness, and the monster hears it like the real
--     thing (it can investigate a tape, but it can never lock on to a player through one).
--   E on a recorder you set down: pick it back up. Once it has played, the tape is blank again.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local ItemArt = require(script.Parent.Parent.ItemArt)
local ProgressService = require(script.Parent.Parent.ProgressService)
local NoiseService = require(script.Parent.Parent.NoiseService)
local RoundService = require(script.Parent.Parent.RoundService)

local TAPE = Config.TAPE

type State = "empty" | "recording" | "ready" | "placed"
type Event = { kind: string, loudness: number, t: number }
type Tape = {
	state: State,
	events: { Event },
	recordStart: number,
	part: BasePart?,
	played: boolean,
	session: number, -- bumps whenever the tape is reset, so stale timers do nothing
}

local TapeService = {}

local tapes: { [Player]: Tape } = {}
local folder: Folder

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	return nil
end

local function notify(player: Player, message: string)
	Remotes.Notify:FireClient(player, message)
end

local function setState(player: Player, tape: Tape, state: State)
	tape.state = state
	player:SetAttribute("TapeState", state)
end

local function newTape(previous: Tape?): Tape
	return {
		state = "empty",
		events = {},
		recordStart = 0,
		part = nil,
		played = false,
		session = if previous then previous.session + 1 else 1,
	}
end

-- Noises near a recording player end up on their tape (never a tape's own playback).
local function onNoise(noise: NoiseService.Noise)
	if noise.replay or noise.kind == "monster" then
		return
	end
	for player, tape in tapes do
		if tape.state == "recording" and #tape.events < TAPE.MAX_EVENTS then
			local root = rootOf(player)
			if root and (noise.position - root.Position).Magnitude <= TAPE.RECORD_RADIUS then
				table.insert(tape.events, {
					kind = noise.kind,
					loudness = noise.loudness,
					t = noise.time - tape.recordStart,
				})
			end
		end
	end
end

local function startRecording(player: Player, tape: Tape)
	tape.events = {}
	tape.recordStart = os.clock()
	setState(player, tape, "recording")
	notify(player, "Recording... make the noise you want on the tape.")
	local session = tape.session
	task.delay(TAPE.RECORD_SECONDS, function()
		if tapes[player] ~= tape or tape.session ~= session or tape.state ~= "recording" then
			return
		end
		if #tape.events == 0 then
			setState(player, tape, "empty")
			notify(player, "The tape is blank: it only records noise. Try again (R).")
		else
			setState(player, tape, "ready")
			notify(player, "Recorded. Press R to set it down; it plays a few seconds later.")
		end
	end)
end

local function playBack(player: Player, tape: Tape, part: BasePart)
	ProgressService.award(player, "Decoy played", Config.REWARDS.DECOY)
	local light = part:FindFirstChildOfClass("PointLight")
	if light then
		light.Enabled = true
	end
	local last = 0
	for _, event in tape.events do
		last = math.max(last, event.t)
		task.delay(event.t, function()
			if part.Parent == nil then
				return -- picked up mid-playback
			end
			local soundId, speed = Sounds.forKind(event.kind)
			Sounds.playAt(soundId, part.Position, 0.8, 80, speed)
			NoiseService.emit(part.Position, event.loudness, event.kind, nil, true)
		end)
	end
	task.delay(last + 0.5, function()
		tape.played = true
		if part.Parent and light then
			light.Enabled = false
		end
	end)
end

local function pickUp(player: Player, tape: Tape, part: BasePart)
	if part.Parent == nil or tape.part ~= part then
		return
	end
	part:Destroy()
	tape.part = nil
	Sounds.playAt(Sounds.TAPE_CLUNK, part.Position, 0.4, 25)
	if tape.played then
		tape.events = {}
		tape.played = false
		setState(player, tape, "empty")
	else
		setState(player, tape, "ready")
	end
end

-- Where the recorder goes: on the floor just in front of the player, or at their feet if there's
-- a wall or no floor there.
local function placement(root: BasePart, character: Model): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, folder }
	local look = root.CFrame.LookVector
	local forward = Vector3.new(look.X, 0, look.Z)
	forward = if forward.Magnitude > 0.1 then forward.Unit else Vector3.zero
	local ahead = root.Position + forward * 2.5
	if Workspace:Raycast(root.Position, ahead - root.Position, params) then
		ahead = root.Position
	end
	local floor = Workspace:Raycast(ahead + Vector3.new(0, 1, 0), Vector3.new(0, -8, 0), params)
	return if floor then floor.Position else nil
end

local function setDown(player: Player, tape: Tape)
	local root = rootOf(player)
	local character = player.Character
	if not root or not character then
		return
	end
	local spot = placement(root, character)
	if not spot then
		notify(player, "There's nowhere to set it down here.")
		return
	end
	local part = ItemArt.makeTapeRecorder()
	local yaw = math.atan2(-root.CFrame.LookVector.X, -root.CFrame.LookVector.Z)
	part.CFrame = CFrame.new(spot + Vector3.new(0, part.Size.Y / 2, 0)) * CFrame.Angles(0, yaw, 0)
	part:SetAttribute("Owner", player.UserId)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 60, 40)
	light.Brightness = 0.6
	light.Range = 4
	light.Enabled = false -- on while it plays
	light.Parent = part

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = player.DisplayName .. "'s tape recorder"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(by)
		if by ~= player then
			notify(by, "That's " .. player.DisplayName .. "'s recorder.")
			return
		end
		pickUp(player, tape, part)
	end)

	part.Parent = folder
	tape.part = part
	tape.played = false
	setState(player, tape, "placed")
	Sounds.playAt(Sounds.TAPE_CLUNK, part.Position, 0.5, 30)
	NoiseService.emit(part.Position, Config.NOISE.TAPE_PLACE, "clunk", player)

	local session = tape.session
	task.delay(TAPE.PLAY_DELAY, function()
		if
			tapes[player] == tape
			and tape.session == session
			and tape.part == part
			and part.Parent
		then
			playBack(player, tape, part)
		end
	end)
end

local function onAction(player: Player)
	if not Config.FEATURES.TAPE or not RoundService.isTarget(player) then
		return
	end
	local tape = tapes[player]
	if not tape then
		return
	end
	if tape.state == "empty" then
		startRecording(player, tape)
	elseif tape.state == "ready" then
		setDown(player, tape)
	elseif tape.state == "placed" then
		notify(player, "Your recorder is set down somewhere. Pick it up first (E).")
	end
end

function TapeService.init()
	folder = Instance.new("Folder")
	folder.Name = "TapeRecorders"
	folder.Parent = Workspace

	NoiseService.onNoise(onNoise)
	Remotes.TapeAction.OnServerEvent:Connect(onAction)

	-- A new round: every recorder left lying around goes, every tape is blank again.
	RoundService.onRoundStart(function()
		folder:ClearAllChildren()
		for player, tape in tapes do
			tapes[player] = newTape(tape)
		end
	end)
	RoundService.onSpawn(function(player, _, inRound)
		local previous = tapes[player]
		if inRound and Config.FEATURES.TAPE then
			if not previous or previous.state == "recording" then
				tapes[player] = newTape(previous)
			end
			player:SetAttribute("TapeState", tapes[player].state)
		else
			-- Out of the round: a set-down recorder stays and still plays; anything held is gone.
			if previous and previous.state ~= "placed" then
				tapes[player] = newTape(previous)
			end
			player:SetAttribute("TapeState", nil)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local tape = tapes[player]
		if tape and tape.part then
			tape.part:Destroy()
		end
		tapes[player] = nil
	end)
end

return TapeService
