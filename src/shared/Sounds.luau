--!strict
-- Sound ids in one place. These are placeholders built into Roblox; replace them with proper
-- sounds from the Creator Store (Toolbox -> Audio) and every use updates at once.

local Sounds = {}

Sounds.DOOR = "rbxasset://sounds/switch.wav"
Sounds.LOCK_SLAM = "rbxasset://sounds/action_jump_land.mp3" -- needs heavy magnetic locks slamming
Sounds.FOGHORN = "rbxasset://sounds/electronicpingshort.wav" -- played very slow; needs a real foghorn
Sounds.REEL_TRACK = "rbxasset://sounds/electronicpingshort.wav" -- a reel's track; needs the eerie recording
Sounds.RECORDING = "rbxasset://sounds/electronicpingshort.wav" -- the complete sound; needs the real thing
Sounds.TAPE_THREAD = "rbxasset://sounds/switch.wav" -- tape seating on a guide
Sounds.TAPE_SLIP = "rbxasset://sounds/action_jump_land.mp3" -- tape clattering off
Sounds.SAFE_CLICK = "rbxasset://sounds/switch.wav"
Sounds.CLUTTER = "rbxasset://sounds/action_jump_land.mp3" -- an instrument being moved; needs a cymbal or amp scrape
Sounds.BUZZ = "rbxasset://sounds/electronicpingshort.wav" -- played low; needs a mains hum
Sounds.SHUTTER = "rbxasset://sounds/action_jump_land.mp3" -- needs a metal shutter crashing down
Sounds.THUMP = "rbxasset://sounds/action_jump_land.mp3" -- something behind the barricaded door
Sounds.HUM = "rbxasset://sounds/uuhhh.mp3" -- an entranced body humming; needs a hummed melody
Sounds.WHISPER = "rbxasset://sounds/uuhhh.mp3" -- played fast and quiet; needs a breathy whisper
Sounds.STINGER = "rbxasset://sounds/electronicpingshort.wav" -- escaping; needs a music sting
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
	elseif kind == "reel" then
		return Sounds.REEL_TRACK, 0.7
	elseif kind == "recording" then
		return Sounds.RECORDING, 0.5
	elseif kind == "clutter" then
		return Sounds.CLUTTER, 1
	elseif kind == "buzz" then
		return Sounds.BUZZ, 0.3
	elseif kind == "hum" then
		return Sounds.HUM, 0.6
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
