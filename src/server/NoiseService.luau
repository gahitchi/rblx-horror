--!strict
-- The heart of the game: every noise is an event with a position and a loudness (how far it carries
-- in open air). Listeners (the monster) ask whether they can hear it from where they are: walls
-- weaken it, and a sealed soundproof booth contains it completely.
-- Also turns movement and voice into noise, and tells each player how loud they are.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

export type Noise = {
	position: Vector3,
	loudness: number,
	kind: string,
	source: Player?,
	time: number,
	zone: string?, -- set when the noise is sealed inside a soundproof booth
	replay: boolean?, -- played back by a tape recorder (never recorded again)
}

type ZoneInfo = { name: string, min: Vector3, max: Vector3, door: BasePart }

local listeners: { (Noise) -> () } = {}
local zones: { ZoneInfo } = {}
local lastVoiceTime: { [Player]: number } = {}
local extraIgnore: { Instance } = {}
local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude

local NoiseService = {}

local function zoneAt(position: Vector3): ZoneInfo?
	for _, zone in zones do
		local lo, hi = zone.min, zone.max
		if
			position.X > lo.X
			and position.X < hi.X
			and position.Y > lo.Y
			and position.Y < hi.Y
			and position.Z > lo.Z
			and position.Z < hi.Z
		then
			return zone
		end
	end
	return nil
end

function NoiseService.setZones(list: { ZoneInfo })
	zones = list
end

-- Extra things that never block sound (the monster). Player characters are always ignored.
function NoiseService.setIgnoreList(list: { Instance })
	extraIgnore = list
end

local function refreshIgnore()
	local list = table.clone(extraIgnore)
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	wallParams.FilterDescendantsInstances = list
end

function NoiseService.onNoise(callback: (Noise) -> ())
	table.insert(listeners, callback)
end

function NoiseService.emit(
	position: Vector3,
	loudness: number,
	kind: string,
	source: Player?,
	replay: boolean?
)
	if loudness <= 0 then
		return
	end
	local zone = zoneAt(position)
	local sealed = zone and zone.door:GetAttribute("Open") ~= true
	local noise: Noise = {
		position = position,
		loudness = loudness,
		kind = kind,
		source = source,
		time = os.clock(),
		zone = if sealed and zone then zone.name else nil,
		replay = replay,
	}
	if source then
		Remotes.NoiseFeedback:FireClient(source, loudness)
	end
	for _, callback in listeners do
		task.spawn(callback, noise)
	end
end

-- How far a noise effectively reaches a listener at `listenerPosition`: 0 if it can't be heard.
function NoiseService.effectiveLoudness(noise: Noise, listenerPosition: Vector3): number
	if noise.zone then
		local listenerZone = zoneAt(listenerPosition)
		if not listenerZone or listenerZone.name ~= noise.zone then
			return 0 -- sealed in a booth
		end
	end

	-- Count distinct opaque sound occluders, not repeated faces of the same
	-- wall. A fixed "step 1.2 studs" can land inside a thick/diagonal wall,
	-- making the same occluder count multiple times at grazing angles.
	refreshIgnore()
	local ignore = table.clone(wallParams.FilterDescendantsInstances)
	local loudness = noise.loudness
	local origin = listenerPosition
	local target = noise.position
	for _ = 1, Config.MAX_WALL_HITS do
		local direction = target - origin
		if direction.Magnitude < 0.05 then
			break
		end
		wallParams.FilterDescendantsInstances = ignore
		local hit = workspace:Raycast(origin, direction, wallParams)
		if not hit then
			break
		end
		loudness *= Config.WALL_DAMPING
		-- This instance is already counted. Ignore its entire volume on the
		-- next cast, so a second independent wall still attenuates the sound.
		table.insert(ignore,hit.Instance)
		origin = hit.Position + direction.Unit * 0.05
	end
	return loudness
end

function NoiseService.canHear(noise: Noise, listenerPosition: Vector3): boolean
	local distance = (noise.position - listenerPosition).Magnitude
	if distance > noise.loudness then
		return false -- too far even in open air: skip the raycasts
	end
	return distance <= NoiseService.effectiveLoudness(noise, listenerPosition)
end

-- Movement noise, judged on the server from how fast each character actually moves, so it can't be faked.
local function sampleMovement()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if
			root
			and root:IsA("BasePart")
			and humanoid
			and humanoid.Health > 0
			and character:GetAttribute("InRound")
		then
			local velocity = root.AssemblyLinearVelocity
			local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			local loudness = 0
			if speed > Config.WALK_SPEED + 3 then
				loudness = Config.NOISE.SPRINT
			elseif speed > Config.CROUCH_SPEED + 1 then
				loudness = Config.NOISE.WALK
			end
			if loudness > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
				NoiseService.emit(root.Position, loudness, "footsteps", player)
			end
		end
	end
end

local function watchLanding(character: Model, player: Player)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed and character:GetAttribute("InRound") then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") then
				NoiseService.emit(root.Position, Config.NOISE.LAND, "landing", player)
			end
		end
	end)
end

local function onVoiceLevel(player: Player, level: unknown)
	if typeof(level) ~= "number" or level ~= level then
		return
	end
	local now = os.clock()
	if now - (lastVoiceTime[player] or 0) < Config.VOICE_SEND_INTERVAL * 0.8 then
		return
	end
	lastVoiceTime[player] = now
	local clamped = math.clamp(level, 0, 1)
	if clamped < Config.VOICE_THRESHOLD then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") and character and character:GetAttribute("InRound") then
		NoiseService.emit(root.Position, clamped * Config.NOISE.VOICE_MAX, "voice", player)
	end
end

function NoiseService.init()
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed >= Config.FOOTSTEP_INTERVAL then
			elapsed = 0
			sampleMovement()
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			watchLanding(character, player)
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastVoiceTime[player] = nil
	end)
	Remotes.VoiceLevel.OnServerEvent:Connect(onVoiceLevel)
end

return NoiseService
