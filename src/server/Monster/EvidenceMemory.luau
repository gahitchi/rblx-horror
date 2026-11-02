--!strict
-- What the blind Engineer can reasonably infer from sounds it ACTUALLY heard.
-- Neither target RootParts nor the director's player-position hints enter here.
-- Repeated stationary decoys become less interesting; genuine moving footsteps
-- leave a short, imperfect track. All memory is cleared between rounds.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Perception = require(script.Parent.Perception)

local M = Config.MONSTER
local C = M.COGNITION

type Track = {
	position: Vector3,
	time: number,
	velocity: Vector3,
	clarity: number,
}
export type Memory = {
	observe: (stimulus: Perception.Stimulus, now: number) -> (),
	attend: (stimulus: Perception.Stimulus, now: number, busy: boolean) -> boolean,
	predicted: (player: Player, now: number) -> Vector3?,
	confidentNear: (point: Vector3, now: number) -> boolean,
	sortSearch: (center: Vector3, points: { Vector3 }, now: number) -> { Vector3 },
	visited: (point: Vector3, now: number) -> (),
	interest: () -> number,
	reset: () -> (),
}

local EvidenceMemory = {}

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function cellKey(point: Vector3): string
	local scale = C.SEARCH_CELL
	return string.format("%d:%d:%d",
		math.floor(point.X / scale), math.floor(point.Y / scale), math.floor(point.Z / scale))
end

function EvidenceMemory.new(): Memory
	local tracks: { [Player]: Track } = {}
	local visited: { [string]: number } = {}
	local attentionScore = 0
	local attentionUntil = 0
	local staticKind = ""
	local staticAt: Vector3? = nil
	local staticTime = -math.huge
	local staticRepeats = 0
	local anonymousBreath: { position: Vector3, time: number, clarity: number }? = nil
	local lastScore = 0

	local brain = {} :: Memory

	function brain.reset()
		table.clear(tracks)
		table.clear(visited)
		attentionScore, attentionUntil = 0, 0
		staticKind, staticAt, staticTime, staticRepeats = "", nil, -math.huge, 0
		anonymousBreath = nil
		lastScore = 0
	end

	function brain.observe(stimulus: Perception.Stimulus, now: number)
		local player = stimulus.source
		if player then
			local old = tracks[player]
			local velocity = Vector3.zero
			if old and now > old.time + 0.18 and now - old.time <= C.TRACK_SECONDS
				and stimulus.clarity >= C.TRACK_CLARITY and old.clarity >= C.TRACK_CLARITY then
				local measured = flat(stimulus.estimate - old.position) / (now - old.time)
				if measured.Magnitude > Config.SPRINT_SPEED then
					measured = measured.Unit * Config.SPRINT_SPEED
				end
				-- Smooth the imperfect sound bearings; don't assume a sharp turn.
				velocity = old.velocity:Lerp(measured, 0.4)
			end
			tracks[player] = {
				position = stimulus.estimate,
				time = now,
				velocity = velocity,
				clarity = stimulus.clarity,
			}
			staticRepeats = 0
		elseif stimulus.kind == "breath" or stimulus.kind == "gasp" then
			-- HideService emits these anonymously to protect player identity.
			-- Hearing breath still provides a rough bearing toward a locker,
			-- never the occupant or a perfect coordinate.
			anonymousBreath = {
				position = stimulus.estimate,
				time = now,
				clarity = stimulus.clarity,
			}
			staticRepeats = 0
		elseif not stimulus.loud then
			if staticAt and staticKind == stimulus.kind
				and now - staticTime < C.STATIC_WINDOW
				and flat(staticAt - stimulus.estimate).Magnitude <= C.STATIC_RADIUS then
				staticRepeats += 1
			else
				staticRepeats = 1
			end
			staticAt = stimulus.estimate
			staticKind = stimulus.kind
			staticTime = now
		end
	end

	function brain.attend(stimulus: Perception.Stimulus, now: number, busy: boolean): boolean
		-- Big objective sounds always interrupt. In a frenzy they still do.
		if stimulus.loud then
			attentionScore = 100
			attentionUntil = now + C.ATTENTION_SECONDS
			lastScore = 100
			return true
		end
		local score = 12 + stimulus.clarity * 48
			+ (if stimulus.source then 24 else 0)
			+ math.max(0, 14 - stimulus.distance / 4)
		-- Repeated sounds from one unmoving, anonymous spot can be a lure.
		-- The first clue still earns investigation; this is never applied
		-- to a player's real footstep / voice track.
		if not stimulus.source and staticRepeats >= C.STATIC_REPEATS then
			score *= C.STATIC_DISCOUNT
		end
		lastScore = score
		if busy and now < attentionUntil and score < attentionScore * C.SWITCH_RATIO then
			return false
		end
		attentionScore = score
		attentionUntil = now + C.ATTENTION_SECONDS
		return true
	end

	function brain.predicted(player: Player, now: number): Vector3?
		local track = tracks[player]
		if not track or now - track.time > C.TRACK_SECONDS then
			return nil
		end
		local horizon = math.clamp(now - track.time, 0, C.PREDICTION_SECONDS)
		return track.position + track.velocity * horizon
	end

	function brain.confidentNear(point: Vector3, now: number): boolean
		for player, track in tracks do
			if player.Parent ~= nil and now - track.time <= C.HIDE_EVIDENCE_SECONDS
				and track.clarity >= C.HIDE_EVIDENCE_CLARITY
				and flat(track.position - point).Magnitude <= C.HIDE_EVIDENCE_RADIUS then
				return true
			end
		end
		if anonymousBreath and now - anonymousBreath.time <= C.HIDE_EVIDENCE_SECONDS
			and anonymousBreath.clarity >= C.HIDE_EVIDENCE_CLARITY
			and flat(anonymousBreath.position - point).Magnitude <= C.HIDE_EVIDENCE_RADIUS then
			return true
		end
		return false
	end

	function brain.sortSearch(center: Vector3, candidates: { Vector3 }, now: number): { Vector3 }
		-- Prefer near, unvisited patrol points and likely directions of travel
		-- inferred from successive audible fixes. Never inspect player roots.
		local direction = Vector3.zero
		local freshest = -math.huge
		for player, track in tracks do
			if player.Parent ~= nil and now - track.time < C.TRACK_SECONDS
				and flat(track.position - center).Magnitude < M.SEARCH_RADIUS * 2
				and track.velocity.Magnitude > 3 and track.time > freshest then
				freshest = track.time
				direction = track.velocity.Unit
			end
		end
		local result = table.clone(candidates)
		local function cost(p: Vector3): number
			local relative = flat(p - center)
			local c = relative.Magnitude
			local last = visited[cellKey(p)]
			if last and now - last < C.SEARCH_REVISIT_SECONDS then
				c += C.SEARCH_REVISIT_PENALTY
			end
			if direction.Magnitude > 0 and relative.Magnitude > 0.5 then
				c -= relative.Unit:Dot(direction) * C.SEARCH_DIRECTION_BONUS
			end
			return c
		end
		table.sort(result, function(a, b)
			return cost(a) < cost(b)
		end)
		return result
	end

	function brain.visited(point: Vector3, now: number)
		visited[cellKey(point)] = now
		-- Bounded over the entire round: avoid unbounded accumulation.
		local count = 0
		for key, time in visited do
			if now - time > C.SEARCH_REVISIT_SECONDS then
				visited[key] = nil
			else
				count += 1
			end
		end
		if count > C.MAX_VISITED then
			table.clear(visited)
		end
	end

	function brain.interest(): number
		return lastScore
	end

	return brain
end

return EvidenceMemory
