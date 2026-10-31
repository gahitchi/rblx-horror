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
Sounds.FLASHLIGHT = "rbxasset://sounds/switch.wav"

-- Plays a one-shot sound at a position in the world, heard by everyone nearby.
function Sounds.playAt(soundId: string, position: Vector3, volume: number?, maxDistance: number?)
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
