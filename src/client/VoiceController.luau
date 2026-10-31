--!strict
-- Optional: if this player has voice chat, measure how loud they talk and report it to the server,
-- which turns it into noise the monster can hear. Uses the Audio API (UseAudioApi is enabled in the
-- project file). Players without voice simply never send anything; the game works the same.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

-- Microphone RMS for normal speech sits around 0.05 to 0.2; this maps a shout to about 1.
-- Tune it in a real voice test.
local GAIN = 4

local VoiceController = {}

local level = 0 -- the last measured level, 0 to 1, for the HUD
local available = false

function VoiceController.getLevel(): number
	return level
end

function VoiceController.isAvailable(): boolean
	return available
end

function VoiceController.start()
	-- Roblox creates the AudioDeviceInput under the player only when they have voice enabled.
	local input = player:WaitForChild("AudioDeviceInput", 30)
	if not input or not input:IsA("AudioDeviceInput") then
		return
	end

	local analyzer = Instance.new("AudioAnalyzer")
	analyzer.Name = "DeadAirVoiceAnalyzer"
	analyzer.Parent = input
	local wire = Instance.new("Wire")
	wire.SourceInstance = input
	wire.TargetInstance = analyzer
	wire.Parent = analyzer
	available = true

	while true do
		task.wait(Config.VOICE_SEND_INTERVAL)
		local character = player.Character
		if input.Muted or not character or character:GetAttribute("InRound") ~= true then
			level = 0
		else
			level = math.clamp(analyzer.RmsLevel * GAIN, 0, 1)
			if level >= Config.VOICE_THRESHOLD then
				Remotes.VoiceLevel:FireServer(level)
			end
		end
	end
end

return VoiceController
