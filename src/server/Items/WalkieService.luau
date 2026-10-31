--!strict
-- Walkie-talkies. Every player in a round carries one on their belt.
--
--   * Hold V to talk: with voice chat, your voice comes out of every teammate's walkie, through a
--     radio filter, wherever they are. With or without voice, every other walkie that's switched on
--     crackles at its owner while you hold the button, and the monster can hear that crackle.
--   * 1 to 4 send quick callouts (for everyone, voice or not): a short line plus the room you're in,
--     shown to teammates with their walkie on, and a crackle burst at each of them.
--   * N switches your walkie off: you hear nothing, but nothing crackles on you either.
--
-- Talking is a team decision with a cost: the person you call may be hiding right next to it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local ItemArt = require(script.Parent.Parent.ItemArt)
local MapContract = require(script.Parent.Parent.MapContract)
local NoiseService = require(script.Parent.Parent.NoiseService)
local RoundService = require(script.Parent.Parent.RoundService)

local W = Config.WALKIE

type Talk = {
	id: number,
	wires: { Wire },
}

local WalkieService = {}

local areas: { MapContract.Area } = {}
local talks: { [Player]: Talk } = {}
local lastCallout: { [Player]: number } = {}
local talkId = 0

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	return nil
end

local function isOn(player: Player): boolean
	return player:GetAttribute("WalkieOn") == true and RoundService.isTarget(player)
end

-- The other players whose walkies would pick up a transmission from `sender`.
local function receivers(sender: Player): { Player }
	local list: { Player } = {}
	for _, player in Players:GetPlayers() do
		if player ~= sender and isOn(player) then
			table.insert(list, player)
		end
	end
	return list
end

-- A crackle out of someone's walkie: a sound for the people nearby, a noise for the monster.
local function crackleAt(player: Player, volume: number)
	local root = rootOf(player)
	if root then
		Sounds.playAt(Sounds.WALKIE_CRACKLE, root.Position, volume, 45, 0.5)
		NoiseService.emit(root.Position, Config.NOISE.WALKIE_CRACKLE, "walkie", player)
	end
end

local function click(player: Player)
	local root = rootOf(player)
	if root then
		Sounds.playAt(Sounds.WALKIE_CLICK, root.Position, 0.4, 25, 1.3)
		NoiseService.emit(root.Position, Config.NOISE.WALKIE_CLICK, "walkie", player)
	end
end

-- The radio effect for one player's voice, kept under their Player so every client gets it:
-- microphone -> band-pass filter (tinny) -> distortion (crunchy). Nil without voice chat.
local function radioChain(player: Player): Instance?
	local existing = player:FindFirstChild("WalkieRadioOut")
	if existing then
		return existing
	end
	local input = player:FindFirstChildOfClass("AudioDeviceInput")
	if not input then
		return nil
	end
	local filter = Instance.new("AudioFilter")
	filter.Name = "WalkieRadioFilter"
	filter.FilterType = Enum.AudioFilterType.Bandpass
	filter.Frequency = 1800
	filter.Q = 1.2
	filter.Parent = player
	local distortion = Instance.new("AudioDistortion")
	distortion.Name = "WalkieRadioOut"
	distortion.Level = 0.35
	distortion.Parent = player
	local a = Instance.new("Wire")
	a.SourceInstance = input
	a.TargetInstance = filter
	a.Parent = filter
	local b = Instance.new("Wire")
	b.SourceInstance = filter
	b.TargetInstance = distortion
	b.Parent = distortion
	return distortion
end

local function speakerOf(player: Player): AudioEmitter?
	local character = player.Character
	local speaker = character and character:FindFirstChild("WalkieSpeaker", true)
	if speaker and speaker:IsA("AudioEmitter") then
		return speaker
	end
	return nil
end

local function stopTalking(player: Player)
	local talk = talks[player]
	if not talk then
		return
	end
	talks[player] = nil
	for _, wire in talk.wires do
		wire:Destroy()
	end
	player:SetAttribute("WalkieTalking", false)
	click(player)
end

local function startTalking(player: Player)
	if talks[player] or not isOn(player) then
		return
	end
	talkId += 1
	local talk: Talk = { id = talkId, wires = {} }
	talks[player] = talk
	player:SetAttribute("WalkieTalking", true)
	click(player)

	-- Voice: route the radio-filtered microphone into every receiving walkie's speaker.
	local chain = radioChain(player)
	if chain then
		for _, receiver in receivers(player) do
			local speaker = speakerOf(receiver)
			if speaker then
				local wire = Instance.new("Wire")
				wire.SourceInstance = chain
				wire.TargetInstance = speaker
				wire.Parent = speaker
				table.insert(talk.wires, wire)
			end
		end
	end

	-- Crackle at every receiver while the button is held (and stop by itself if it's held forever).
	task.spawn(function()
		local started = os.clock()
		while talks[player] == talk do
			if os.clock() - started > W.MAX_TALK_SECONDS or not isOn(player) then
				stopTalking(player)
				break
			end
			for _, receiver in receivers(player) do
				crackleAt(receiver, 0.3)
			end
			task.wait(W.CRACKLE_INTERVAL)
		end
	end)
end

local function onTalk(player: Player, talking: unknown)
	if not Config.FEATURES.WALKIE or type(talking) ~= "boolean" then
		return
	end
	if talking then
		startTalking(player)
	else
		stopTalking(player)
	end
end

local function onPower(player: Player)
	if not Config.FEATURES.WALKIE or not RoundService.isTarget(player) then
		return
	end
	local on = player:GetAttribute("WalkieOn") ~= true
	if not on then
		stopTalking(player)
	end
	player:SetAttribute("WalkieOn", on)
	click(player)
end

local function onCallout(player: Player, index: unknown)
	if not Config.FEATURES.WALKIE or type(index) ~= "number" or not isOn(player) then
		return
	end
	local text = W.CALLOUTS[math.floor(index)]
	if not text then
		return
	end
	local now = os.clock()
	if now - (lastCallout[player] or 0) < W.CALLOUT_COOLDOWN then
		return
	end
	lastCallout[player] = now
	local root = rootOf(player)
	if not root then
		return
	end
	local room = MapContract.placeName(areas, root.Position)
	click(player)
	Remotes.Radio:FireClient(player, "You", room, text)
	for _, receiver in receivers(player) do
		Remotes.Radio:FireClient(receiver, player.DisplayName, room, text)
		crackleAt(receiver, 0.5)
	end
end

-- Clips a walkie to a character's belt, with the speaker teammates' voices come out of.
local function equip(character: Model)
	local hip = character:WaitForChild("LowerTorso", 5) or character:FindFirstChild("Torso")
	if not hip or not hip:IsA("BasePart") then
		return
	end
	local walkie = ItemArt.makeWalkie()
	walkie.CFrame = hip.CFrame * CFrame.new(-1.05, 0.1, 0)
	walkie.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hip
	weld.Part1 = walkie
	weld.Parent = walkie
	local speaker = Instance.new("AudioEmitter")
	speaker.Name = "WalkieSpeaker"
	speaker.Parent = walkie
end

function WalkieService.init(mapAreas: { MapContract.Area })
	areas = mapAreas
	Remotes.WalkieTalk.OnServerEvent:Connect(onTalk)
	Remotes.WalkiePower.OnServerEvent:Connect(onPower)
	Remotes.WalkieCallout.OnServerEvent:Connect(onCallout)

	RoundService.onSpawn(function(player, character, inRound)
		stopTalking(player)
		player:SetAttribute("WalkieOn", inRound and Config.FEATURES.WALKIE)
		player:SetAttribute("WalkieTalking", false)
		if inRound and Config.FEATURES.WALKIE then
			equip(character)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		stopTalking(player)
		lastCallout[player] = nil
	end)
end

return WalkieService
