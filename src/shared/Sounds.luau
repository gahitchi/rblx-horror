--!strict
-- Sound ids in one place. These are placeholders built into Roblox; replace them with proper
-- sounds from the Creator Store (Toolbox -> Audio) and every use updates at once.

local Sounds = {}

Sounds.DOOR = "rbxasset://sounds/switch.wav"
Sounds.FUSE = "rbxasset://sounds/switch.wav"
Sounds.GENERATOR_PULL = "rbxasset://sounds/action_jump_land.mp3"
Sounds.GENERATOR_HUM = "" -- needs a looping engine sound
Sounds.ALARM = "rbxasset://sounds/electronicpingshort.wav" -- needs a proper siren
Sounds.CATCH = "rbxasset://sounds/uuhhh.mp3"
Sounds.LUNGE = "rbxasset://sounds/swordlunge.wav" -- needs a proper shriek
Sounds.FLASHLIGHT = "rbxasset://sounds/switch.wav"
Sounds.MONSTER_STEP = "rbxasset://sounds/action_footsteps_plastic.mp3" -- played slow and low; needs heavy steps
Sounds.ALERT = "rbxasset://sounds/swordlunge.wav" -- the Engineer locking on; needs a proper cry
Sounds.FOOTSTEP = "rbxasset://sounds/action_footsteps_plastic.mp3" -- a person's step (tape, mimicry)
Sounds.LANDING = "rbxasset://sounds/action_jump_land.mp3"
Sounds.VOICE_GARBLE = "rbxasset://sounds/uuhhh.mp3" -- a voice played back; needs muffled speech
Sounds.WALKIE_CRACKLE = "rbxasset://sounds/electronicpingshort.wav" -- needs radio static
Sounds.WALKIE_CLICK = "rbxasset://sounds/switch.wav" -- needs a push-to-talk click
Sounds.TAPE_CLUNK = "rbxasset://sounds/switch.wav" -- needs a tape button / setting it down

-- The sound that stands for a kind of noise when it's played back (tape recorder, mimicry), and the
-- playback speed to use. Empty when there's nothing sensible to play.
function Sounds.forKind(kind: string): (string, number)
	if kind == "footsteps" then
		return Sounds.FOOTSTEP, 1
	elseif kind == "landing" then
		return Sounds.LANDING, 1
	elseif kind == "door" then
		return Sounds.DOOR, 1
	elseif kind == "voice" then
		return Sounds.VOICE_GARBLE, 0.75
	elseif kind == "walkie" then
		return Sounds.WALKIE_CRACKLE, 0.5
	elseif kind == "flashlight" then
		return Sounds.FLASHLIGHT, 1
	elseif kind == "generator" then
		return Sounds.GENERATOR_PULL, 1
	elseif kind == "fuse" then
		return Sounds.FUSE, 1
	elseif kind == "alarm" then
		return Sounds.ALARM, 1
	end
	return "", 1
end

-- Plays a one-shot sound at a position in the world, heard by everyone nearby.
function Sounds.playAt(
	soundId: string,
	position: Vector3,
	volume: number?,
	maxDistance: number?,
	playbackSpeed: number?
)
	if soundId == "" then
		return
	end
	local holder = Instance.new("Part")
	holder.Name = "SoundAt"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.Position = position

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.8
	sound.RollOffMaxDistance = maxDistance or 120
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.Parent = holder
	holder.Parent = workspace

	sound:Play()
	sound.Ended:Once(function()
		holder:Destroy()
	end)
	task.delay(10, function()
		if holder.Parent then
			holder:Destroy()
		end
	end)
end

return Sounds
