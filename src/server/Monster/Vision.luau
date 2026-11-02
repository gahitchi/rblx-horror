--!strict
-- What the Engineer sees. He's a man, not a blind thing: his hearing is what makes him deadly,
-- but he sees too, and light decides how far.
--   * In the dark he barely sees: only a few studs.
--   * In a lit area (near a lamp that's on) he sees much farther.
--   * A player with their flashlight on is visible farthest of all, and a beam shone across him
--     gets noticed even from outside his view.
-- He has a view cone and needs a clear line of sight. Players hiding in a wardrobe or locker are
-- never seen. Seeing isn't instant: he has to watch someone for a moment (less when they're close)
-- before he's sure, and while he's making up his mind he stops and stares (MonsterService).

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapContract = require(script.Parent.Parent.MapContract)

local S = Config.MONSTER.SIGHT

export type Sighting = {
	player: Player,
	position: Vector3, -- where he saw them
	distance: number,
	sure: boolean, -- watched long enough to be certain
}

type LampLight = { light: Light, at: BasePart }

local Vision = {}

local lampLights: { LampLight } = {}
local watched: { [Player]: number } = {} -- seconds of looking at each player, recently
local coneCos = math.cos(math.rad(S.CONE_DEGREES / 2))
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

function Vision.setLamps(lamps: { MapContract.Lamp })
	lampLights = {}
	for _, lamp in lamps do
		for _, light in lamp.lights do
			local holder = light.Parent
			if holder and holder:IsA("BasePart") then
				table.insert(lampLights, { light = light, at = holder })
			end
		end
	end
end

function Vision.reset()
	watched = {}
end

-- Whether a position is inside the pool of a lamp that's on right now.
local function lit(position: Vector3): boolean
	for _, entry in lampLights do
		local light = entry.light
		-- A dim equipment indicator can be visibly glowing while giving
		-- almost no usable illumination. Only actual work lighting grants
		-- the longer lit-range detection distance.
		if light.Enabled and light.Brightness >= S.LIT_MIN_BRIGHTNESS and entry.at.Parent then
			local anyLight: any = light
			local range: number = anyLight.Range
			if (entry.at.Position - position).Magnitude <= range * S.LIT_REACH then
				return true
			end
		end
	end
	return false
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

-- Looks around once. `eye` and `look` are his eye position and facing; `ignore` is his own body.
-- Returns the sighting he's most sure of, or nil when he sees nobody.
function Vision.scan(
	dt: number,
	eye: Vector3,
	look: Vector3,
	ignore: { Instance },
	players: { Player },
	isTarget: (Player) -> boolean,
	rangeScale: number
): Sighting?
	local best: Sighting? = nil
	local bestProgress = -1
	local seenNow: { [Player]: boolean } = {}
	local flatLook = flat(look)
	flatLook = if flatLook.Magnitude > 0.01 then flatLook.Unit else Vector3.new(0, 0, -1)

	for _, player in players do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if
			not character
			or not root
			or not root:IsA("BasePart")
			or not isTarget(player)
			or player:GetAttribute("Hiding") == true
		then
			continue
		end
		local head = root.Position + Vector3.new(0, 1.5, 0)
		local offset = head - eye
		local distance = offset.Magnitude
		if distance < 0.5 then
			continue
		end
		local torch = character:GetAttribute("FlashlightOn") == true
		local range = (
			if torch then S.TORCH_RANGE elseif lit(head) then S.LIT_RANGE else S.DARK_RANGE
		) * rangeScale
		local toward = flat(offset)
		local inCone = toward.Magnitude < 0.01 or toward.Unit:Dot(flatLook) >= coneCos
		-- A beam shone across him: he notices it wherever he's facing.
		local beam = false
		if torch and distance <= S.BEAM_RANGE * rangeScale then
			local theirLook = flat(root.CFrame.LookVector)
			local back = flat(-offset)
			beam = theirLook.Magnitude > 0.01
				and back.Magnitude > 0.01
				and theirLook.Unit:Dot(back.Unit) >= S.BEAM_DOT
		end
		if not ((inCone and distance <= range) or beam) then
			continue
		end
		local exclude = table.clone(ignore)
		for _, other in players do
			if other.Character then
				table.insert(exclude, other.Character)
			end
		end
		params.FilterDescendantsInstances = exclude
		if Workspace:Raycast(eye, offset, params) ~= nil then
			continue -- a wall, a shelf, a closed door in the way
		end
		seenNow[player] = true
		local looked = (watched[player] or 0) + dt
		watched[player] = looked
		local reach = math.max(range, S.DARK_RANGE)
		local need = S.NOTICE_MIN
			+ (S.NOTICE_MAX - S.NOTICE_MIN) * math.clamp(distance / reach, 0, 1)
		local progress = looked / need
		if progress > bestProgress then
			bestProgress = progress
			best = { player = player, position = head, distance = distance, sure = looked >= need }
		end
	end

	-- Out of sight, the impression fades (twice as fast as it builds).
	for player, looked: number in watched do
		if not seenNow[player] then
			local left = looked - dt * 2
			if left > 0 then
				watched[player] = left
			else
				watched[player] = nil
			end
		end
	end
	return best
end

return Vision
