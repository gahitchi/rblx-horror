--!strict
-- The pacing layer above the monster's senses, in the spirit of Alien: Isolation's director. The
-- monster never gets told where a player is; the director only decides where it goes when it has
-- nothing better to do, so tension rises and falls instead of being constant:
--   Grace: just after it arrives it keeps to the far side of the building.
--   Normal: it roams; if it hasn't been near anyone for a long while, it drifts toward the rooms
--     where the players are (a room, never a person).
--   Retreat: after it has spent too long near the players, or caught someone, it goes backstage for
--     a while, reacting only to unmistakable noises.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local MapContract = require(script.Parent.Parent.MapContract)

local M = Config.MONSTER

export type Mode = "Grace" | "Normal" | "Retreat"

local Director = {}

local mode: Mode = "Grace"
local modeUntil = 0
local menace = 0 -- 0 to 1: how long it has been close to the players lately
local lastContact = 0
local hintScale = 1 -- soft pressure shrinks how long it waits before drifting toward the players
local rng = Random.new()

function Director.setHintScale(scale: number)
	hintScale = math.clamp(scale, 0.1, 1)
end

function Director.reset(now: number)
	mode = "Grace"
	modeUntil = now + M.GRACE_TIME
	menace = 0
	lastContact = now
end

function Director.mode(): Mode
	return mode
end

function Director.menace(): number
	return menace
end

function Director.update(
	dt: number,
	now: number,
	monster: Vector3,
	hunting: boolean,
	players: { Vector3 }
)
	local nearest = math.huge
	for _, position in players do
		nearest = math.min(nearest, (position - monster).Magnitude)
	end
	if nearest < M.NEAR_DISTANCE then
		lastContact = now
		menace = math.min(1, menace + dt / M.MENACE_SECONDS * (if hunting then 1.6 else 1))
	else
		menace = math.max(0, menace - dt / M.MENACE_COOL_SECONDS)
	end
	if mode ~= "Normal" and now >= modeUntil then
		mode = "Normal"
	end
end

-- Too much time near the players: time to back off (the brain decides when it's free to).
function Director.wantsRetreat(): boolean
	return mode == "Normal" and menace >= 1
end

function Director.startRetreat(now: number)
	mode = "Retreat"
	modeUntil = now + M.RETREAT_TIME
	menace = 0.3
end

local function nearestDistance(point: Vector3, players: { Vector3 }): number
	local nearest = math.huge
	for _, position in players do
		nearest = math.min(nearest, (position - point).Magnitude)
	end
	return nearest
end

-- Where to roam next.
function Director.pickArea(
	areas: { MapContract.Area },
	now: number,
	monster: Vector3,
	players: { Vector3 },
	current: MapContract.Area?
): MapContract.Area
	local candidates: { MapContract.Area } = {}
	for _, area in areas do
		if area ~= current and #area.points > 0 then
			table.insert(candidates, area)
		end
	end
	if #candidates == 0 then
		return areas[1]
	end

	if (mode == "Grace" or mode == "Retreat") and #players > 0 then
		-- The rooms farthest from everyone, with a little variety.
		table.sort(candidates, function(a, b)
			return nearestDistance(a.center, players) > nearestDistance(b.center, players)
		end)
		return candidates[rng:NextInteger(1, math.min(3, #candidates))]
	end

	if now - lastContact > M.HINT_AFTER * hintScale and #players > 0 then
		-- Drift toward one player's part of the building: one of the two rooms closest to them.
		local focus = players[rng:NextInteger(1, #players)]
		table.sort(candidates, function(a, b)
			return (a.center - focus).Magnitude < (b.center - focus).Magnitude
		end)
		return candidates[rng:NextInteger(1, math.min(2, #candidates))]
	end

	-- A normal patrol: prefer rooms a plausible walk away, not across the whole map every time.
	local weights: { number } = {}
	local total = 0
	for i, area in candidates do
		local d = (area.center - monster).Magnitude
		local w = if d < 25 then 0.6 elseif d < 80 then 1.5 else 0.8
		weights[i] = w
		total += w
	end
	local roll = rng:NextNumber() * total
	for i, area in candidates do
		roll -= weights[i]
		if roll <= 0 then
			return area
		end
	end
	return candidates[#candidates]
end

return Director
