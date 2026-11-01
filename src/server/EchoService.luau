--!strict
-- Echoes. When the monster catches someone it rips their filter headset off: they hear the sound
-- unfiltered and the Choir takes their voice (the story's fourth rule). Their body stays where it
-- fell, entranced and humming (a quiet noise the monster can hear). The player becomes an echo:
--   * floats anywhere in the building (the camera is theirs; this only tracks where it is)
--   * senses the monster through walls, and can ping it for the living (with a cooldown)
--   * whispers short lines to living players nearby; the monster sometimes catches a whisper, and
--     whispers fade if used too often, so they can't be used to get teammates killed
-- A teammate brings them back by putting the headset back on (ReviveService).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local MapContract = require(script.Parent.MapContract)
local MonsterService = require(script.Parent.MonsterService)
local NoiseService = require(script.Parent.NoiseService)
local ProgressService = require(script.Parent.ProgressService)
local RoundState = require(script.Parent.RoundState)

local E = Config.ECHO

local EchoService = {}

local isTarget: (Player) -> boolean = function()
	return false
end
local boundsMin = Vector3.zero
local boundsMax = Vector3.zero
local positions: { [Player]: Vector3 } = {}
local lastMove: { [Player]: number } = {}
local lastPing: { [Player]: number } = {}
local whisperTimes: { [Player]: { number } } = {}
local rng = Random.new()

local function rootOf(character: Model?): BasePart?
	local r = character and character:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	return nil
end

function EchoService.isEcho(player: Player): boolean
	return player:GetAttribute("Echo") == true and RoundState.get("Phase") == "Playing"
end

-- Turns a caught player's character into an entranced body and the player into an echo.
function EchoService.entrance(player: Player)
	local character = player.Character
	local r = rootOf(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not r or not humanoid then
		player:SetAttribute("Echo", true)
		return
	end
	character:SetAttribute("InRound", false)
	character:SetAttribute("Entranced", true)
	character:SetAttribute("FlashlightOn", false)
	humanoid.WalkSpeed = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false
	-- Slumped where it fell, swaying a little as it hums.
	r.Anchored = true
	r.CFrame = r.CFrame * CFrame.new(0, -1.2, 0) * CFrame.Angles(math.rad(-18), 0, 0)
	positions[player] = r.Position + Vector3.new(0, 2.5, 0)
	player:SetAttribute("Echo", true)
end

local function onMove(player: Player, position: unknown)
	if not EchoService.isEcho(player) or typeof(position) ~= "Vector3" then
		return
	end
	local now = os.clock()
	if now - (lastMove[player] or 0) < E.SEND_INTERVAL * 0.6 then
		return
	end
	lastMove[player] = now
	positions[player] = position:Max(boundsMin):Min(boundsMax)
end

local function onPing(player: Player)
	if not EchoService.isEcho(player) then
		return
	end
	local now = os.clock()
	if now - (lastPing[player] or -math.huge) < E.PING_COOLDOWN then
		return
	end
	local monster = MonsterService.position()
	if not monster then
		Remotes.Notify:FireClient(player, "It isn't in the building yet.")
		return
	end
	lastPing[player] = now
	player:SetAttribute("PingReadyAt", workspace:GetServerTimeNow() + E.PING_COOLDOWN)
	for _, other in Players:GetPlayers() do
		if isTarget(other) or EchoService.isEcho(other) then
			Remotes.Ping:FireClient(other, monster, player.DisplayName)
		end
	end
	ProgressService.award(player, "Marked the monster", Config.REWARDS.PING)
end

local function onWhisper(player: Player, index: unknown)
	if not EchoService.isEcho(player) or type(index) ~= "number" then
		return
	end
	local line = E.WHISPERS[index]
	local from = positions[player]
	if not line or not from then
		return
	end
	local now = os.clock()
	local times: { number } = whisperTimes[player] or {}
	if #times > 0 and now - times[#times] < E.WHISPER_COOLDOWN then
		return
	end
	-- Too many whispers in a short time and the voice fades out for a while.
	local recent: { number } = {}
	for _, t in times do
		if now - t < E.WHISPER_WINDOW then
			table.insert(recent, t)
		end
	end
	if #recent >= E.WHISPER_MAX then
		Remotes.Notify:FireClient(player, "Your voice is too faint. Wait a little.")
		whisperTimes[player] = recent
		return
	end
	table.insert(recent, now)
	whisperTimes[player] = recent
	local heardBy = 0
	for _, other in Players:GetPlayers() do
		local r = rootOf(other.Character)
		if isTarget(other) and r and (r.Position - from).Magnitude <= E.WHISPER_RANGE then
			Remotes.Whisper:FireClient(other, player.DisplayName, line)
			heardBy += 1
		end
	end
	Remotes.Whisper:FireClient(player, player.DisplayName, line)
	if heardBy > 0 then
		Sounds.playAt(Sounds.WHISPER, from, 0.35, E.WHISPER_RANGE, 1.6)
	end
	if rng:NextNumber() < E.WHISPER_HEARD_CHANCE then
		NoiseService.emit(from, Config.NOISE.WHISPER, "whisper", nil)
	end
end

-- Entranced bodies hum the sound: a quiet, regular noise near where each one fell.
local function humLoop()
	while true do
		task.wait(E.HUM_INTERVAL)
		if RoundState.get("Phase") ~= "Playing" then
			continue
		end
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character and character:GetAttribute("Entranced") == true then
				local r = rootOf(character)
				if r then
					local at = r.Position + Vector3.new(rng:NextNumber(-0.3, 0.3), 0, 0)
					Sounds.playAt(Sounds.HUM, at, 0.45, 40, rng:NextNumber(0.55, 0.65))
					NoiseService.emit(at, Config.NOISE.HUM, "hum", nil)
				end
			end
		end
	end
end

function EchoService.reset()
	positions = {}
	lastPing = {}
	whisperTimes = {}
	for _, player in Players:GetPlayers() do
		player:SetAttribute("Echo", false)
		player:SetAttribute("PingReadyAt", nil)
	end
end

function EchoService.init(layout: MapContract.Layout, targetCheck: (Player) -> boolean)
	isTarget = targetCheck
	boundsMin = layout.boundsMin
	boundsMax = layout.boundsMax
	RoundState.set("BoundsMin", boundsMin)
	RoundState.set("BoundsMax", boundsMax)
	Remotes.EchoMove.OnServerEvent:Connect(onMove)
	Remotes.EchoPing.OnServerEvent:Connect(onPing)
	Remotes.EchoWhisper.OnServerEvent:Connect(onWhisper)
	Players.PlayerRemoving:Connect(function(player)
		positions[player] = nil
		lastMove[player] = nil
		lastPing[player] = nil
		whisperTimes[player] = nil
	end)
	task.spawn(humLoop)
end

return EchoService
