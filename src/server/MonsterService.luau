--!strict
-- The Engineer: map 1's monster. Blind; it knows where you are only from what it hears, and from
-- touch when you're right next to it.
--
-- Built in layers (see Config.MONSTER for the tuning):
--   Monster/Perception: awareness and fuzzy sound localisation.
--   Monster/Director: pacing (grace period, retreats, drifting toward the players' area).
--   Monster/Navigator: pathing, smoothing, doors, stuck recovery.
--   This file: the brain, a state machine that turns what it perceives into behaviour.
--
-- States:
--   Dormant      not arrived yet
--   Roam         walking room to room, pausing now and then to listen
--   Listen       heard something faint: stops and turns toward it
--   Investigate  heard enough: goes to where it thinks the sound was
--   Search       found nothing there: checks the spots around it, listening at each
--   Hunt         heard a player clearly and close: pursues, speeding up; loses them after a few
--                seconds of silence and searches where they were heading
--   Retreat      backs off to a far part of the building for a while (director)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local DoorService = require(script.Parent.DoorService)
local MapContract = require(script.Parent.MapContract)
local NoiseService = require(script.Parent.NoiseService)
local Director = require(script.Parent.Monster.Director)
local EvidenceMemory = require(script.Parent.Monster.EvidenceMemory)
local EngineerModel = require(script.Parent.Monster.EngineerModel)
local Environment = require(script.Parent.Monster.Environment)
local Mimicry = require(script.Parent.Monster.Mimicry)
local Motion = require(script.Parent.Monster.Motion)
local Navigator = require(script.Parent.Monster.Navigator)
local Perception = require(script.Parent.Monster.Perception)

type State = "Dormant" | "Roam" | "Listen" | "Investigate" | "Search" | "Hunt" | "Retreat"
type LungePhase = "None" | "Windup" | "Lunge"

local M = Config.MONSTER
local C = M.COGNITION
local TICK = 0.1

local MonsterService = {}

-- Set once
local areas: { MapContract.Area } = {}
local isTarget: (Player) -> boolean = function()
	return false
end
local onCatch: (Player) -> () = function() end

-- The body
local model: Model? = nil
local humanoid: Humanoid? = nil
local root: BasePart? = nil
local nav: Navigator.Navigator? = nil
local motion: Motion.Controller? = nil
local glows: { PointLight } = {}
local loopId = 0
local spawnedAt = 0 -- ignore asynchronous sound events from the previous round
local rng = Random.new()
local memory = EvidenceMemory.new() -- sound estimates, never actual unseen positions

-- The brain
local state: State = "Dormant"
local resumeState: State = "Roam" -- where Listen goes back to
local route: { Vector3 } = {} -- spots left to visit (Roam, Search, Retreat)
local currentArea: MapContract.Area? = nil
local pauseUntil = 0
local listenUntil = 0
local listenToward: Vector3? = nil
local investigateTarget: Vector3? = nil
local investigateUrgent = false
local investigateKind = ""
local searchUntil = 0
local searchCenter: Vector3? = nil

-- The hunt
local huntTarget: Player? = nil
local huntStart = 0
local lastHeard = 0
local lastKnown: Vector3? = nil
local heading = Vector3.zero -- the target's estimated velocity, for predicting where it went

local lungePhase: LungePhase = "None"
local lungePhaseEnd = 0
local lungeReadyAt = 0
local lungeDestination: Vector3? = nil -- committed bearing; no mid-air homing

local stepTimer = 0

-- Pacing from the chapter: soft pressure (hearing grows as the round drags on) and frenzy (after
-- the second shock and through Last Call it hears far, never backs off, and hurries to every sound).
local pressureHearing = 1
local frenzyUntil = 0
local frenzyHeld = false
local frenzyHearing = M.FRENZY_HEARING

-- Hiding spots it can open while searching (HideService). `checkSpot` returns whoever was inside.
local hidingSpots: { BasePart } = {}
local checkSpot: (BasePart) -> Player? = function()
	return nil
end
local spotFronts: { [Vector3]: BasePart } = {}
local inspectionPoints: { [Vector3]: string } = {} -- route points that are a hiding spot's door

-- Debug overlay (Config.DEBUG_AI)
local debugLabel: TextLabel? = nil
local debugFolder: Folder? = nil
local debugPath: { Vector3 }? = nil

local function log(...)
	if Config.DEBUG then
		print("[Engineer]", ...)
	end
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	return nil
end

local function targetPositions(): { Vector3 }
	local list: { Vector3 } = {}
	for _, player in Players:GetPlayers() do
		if isTarget(player) then
			local r = rootOf(player)
			if r then
				table.insert(list, r.Position)
			end
		end
	end
	return list
end

local function areaAt(position: Vector3): MapContract.Area?
	return MapContract.areaAt(areas, position)
end

local function hasLineOfSight(from: Vector3, to: Vector3, ignore: { Instance }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	return Workspace:Raycast(from, to - from, params) == nil
end

local function ear(): Vector3
	local r = root :: BasePart
	return r.Position + Vector3.new(0, 3.6, 0)
end

local function frenzied(): boolean
	return frenzyHeld or os.clock() < frenzyUntil
end

-- Its own footsteps mask quiet sounds: it hears best standing still. Pressure and frenzy widen it.
local function hearing(): number
	local r = root
	local base = M.HEARING_WALKING
	if not r then
		base = M.HEARING_STILL
	else
		local speed = flat(r.AssemblyLinearVelocity).Magnitude
		if speed < 1.5 then
			base = M.HEARING_STILL
		elseif state == "Hunt" then
			base = M.HEARING_HUNTING
		elseif speed > M.INVESTIGATE_SPEED + 1 then
			base = M.HEARING_HURRYING
		end
	end
	return base * pressureHearing * (if frenzied() then frenzyHearing else 1)
end

local function setState(newState: State)
	if state == newState then
		return
	end
	if state == "Listen" and humanoid then
		humanoid.AutoRotate = true
	end
	state = newState
	if model then
		model:SetAttribute("State", newState)
		if newState ~= "Search" then
			model:SetAttribute("Inspecting", "")
		end
	end
	log("->", newState, string.format("(awareness %d)", Perception.awareness()))
end

-- ===== Body =====

local function setGlow(brightness: number, range: number)
	for _, glow in glows do
		glow.Brightness = brightness
		glow.Range = range
	end
end

-- Turns the body toward a point (used while listening).
local function face(point: Vector3)
	local r = root
	if not r then
		return
	end
	local look = flat(point - r.Position)
	if look.Magnitude < 0.5 then
		return
	end
	local current = r.CFrame
	local desired = CFrame.lookAt(current.Position, current.Position + look)
	r.CFrame = current:Lerp(desired, 0.3)
end

-- Heavy, slow steps that players can hear coming. They aren't noise events, so it ignores them.
local function updateFootsteps(dt: number)
	local r = root
	if not r then
		return
	end
	local speed = flat(r.AssemblyLinearVelocity).Magnitude
	if speed < 2 then
		stepTimer = 0
		return
	end
	stepTimer += dt
	local interval = math.clamp(6 / speed, 0.28, 0.9)
	if stepTimer >= interval then
		stepTimer = 0
		local feet = r.Position - Vector3.new(0, 3.5, 0)
		local volume = math.clamp(0.35 + speed / 40, 0.35, 0.9)
		Sounds.playAt(Sounds.MONSTER_STEP, feet, volume, 80, 0.55)
	end
end

-- ===== Behaviours =====

local function pickRoute(area: MapContract.Area, count: number): { Vector3 }
	local spots = table.clone(area.points)
	local picked: { Vector3 } = {}
	while #spots > 0 and #picked < count do
		table.insert(picked, table.remove(spots, rng:NextInteger(1, #spots)) :: Vector3)
	end
	return picked
end

local function startRoam()
	route = {}
	spotFronts = {}
	inspectionPoints = {}
	investigateKind = ""
	searchCenter = nil
	pauseUntil = 0
	setState("Roam")
end

local function startRetreat()
	local r = root
	if not r then
		return
	end
	local now = os.clock()
	Director.startRetreat(now)
	huntTarget = nil
	local area = Director.pickArea(areas, now, r.Position, targetPositions(), areaAt(r.Position))
	currentArea = area
	route = pickRoute(area, #area.points)
	pauseUntil = 0
	setState("Retreat")
	log("retreating to", area.name)
end

local function startListen(toward: Vector3, duration: number?)
	if state ~= "Listen" then
		resumeState = if state == "Search" then "Search" else "Roam"
	end
	listenToward = toward
	listenUntil = os.clock() + (duration or M.LISTEN_TIME + rng:NextNumber(-0.4, 0.6))
	if nav then
		nav.stop()
	end
	if humanoid then
		humanoid.AutoRotate = false
	end
	setState("Listen")
end

local function startInvestigate(target: Vector3, urgent: boolean)
	-- A new audible clue can replace the previous goal, but not carry a
	-- previously stale route or pause into a fresh investigation.
	investigateUrgent = urgent or (state == "Investigate" and investigateUrgent)
	investigateTarget = target
	route = {}
	pauseUntil = 0
	setState("Investigate")
end

-- Search the spots around `center`: the nearest patrol spots of its room and the rooms next to it,
-- closest first, listening at each.
local function startSearch(center: Vector3)
	searchCenter = center
	local spots: { Vector3 } = { center }
	local nearby: { Vector3 } = {}
	for _, area in areas do
		for _, point in area.points do
			local d = (point - center).Magnitude
			if d > 4 and d < M.SEARCH_RADIUS and math.abs(point.Y - center.Y) < 8 then
				table.insert(nearby, point)
			end
		end
	end
	local ordered = memory.sortSearch(center, nearby, os.clock())
	for i = 1, math.min(M.SEARCH_POINTS - 1, #ordered) do
		table.insert(spots, ordered[i])
	end
	inspectionPoints = {}
	-- Studio-specific sound interpretation: the former engineer inspects a
	-- nearby machine when an audible transport or console error led him here.
	local inspectPoint, inspectName = Environment.select(areas, center, investigateKind)
	if inspectPoint and inspectName then
		inspectionPoints[inspectPoint] = inspectName
		table.insert(spots, math.min(2, #spots + 1), inspectPoint)
	end
	-- Search hiding spots based on *heard evidence*, not actual occupancy.
	spotFronts = {}
	local hasEvidence = memory.confidentNear(center, os.clock())
	local closestSpot: BasePart? = nil
	local closestDistance = math.huge
	for _, spot in hidingSpots do
		local d = (spot.Position - center).Magnitude
		if d < M.SEARCH_RADIUS and d < closestDistance then
			closestSpot, closestDistance = spot, d
		end
	end
	for _, spot in hidingSpots do
		local d = (spot.Position - center).Magnitude
		local chance = if hasEvidence then Config.HIDE.CHECK_CHANCE else C.GENERIC_HIDE_CHECK
		if
			d < M.SEARCH_RADIUS
			and ((hasEvidence and spot == closestSpot) or rng:NextNumber() < chance)
		then
			local front = spot.CFrame * CFrame.new(0, 0, -(spot.Size.Z / 2 + 2.2))
			local floorY = spot.Position.Y - spot.Size.Y / 2
			local point = Vector3.new(front.X, floorY + 3, front.Z)
			spotFronts[point] = spot
			table.insert(spots, if spot == closestSpot then 2 else #spots + 1, point)
		end
	end
	route = spots
	pauseUntil = 0
	searchUntil = os.clock() + M.SEARCH_TIME
	setState("Search")
end

local function endLunge(now: number)
	if lungePhase ~= "None" then
		lungePhase = "None"
		lungeDestination = nil
		lungeReadyAt = now + M.LUNGE_COOLDOWN
		setGlow(0.8, 7)
		if model then
			model:SetAttribute("Lunging", false)
		end
	end
end

local function startHunt(player: Player, position: Vector3)
	local now = os.clock()
	if state ~= "Hunt" then
		huntStart = now
		heading = Vector3.zero
		local r = root
		if r then
			Sounds.playAt(Sounds.ALERT, r.Position, 1, 150, 0.7)
		end
		log("hunting", player.Name)
	end
	huntTarget = player
	lastHeard = now
	lastKnown = position
	Perception.set(100)
	setState("Hunt")
end

-- A fresh fix on the hunted player: also estimates which way they're moving.
local function updateTrack(position: Vector3, now: number)
	local previous = lastKnown
	local elapsed = now - lastHeard
	if previous and elapsed > 0.05 and elapsed < 2 then
		local velocity = flat(position - previous) / elapsed
		if velocity.Magnitude > 24 then
			velocity = velocity.Unit * 24
		end
		heading = heading:Lerp(velocity, 0.5)
	end
	lastKnown = position
	lastHeard = now
end

local function chaseSpeed(now: number): number
	local t = math.clamp((now - huntStart) / M.CHASE_RAMP_SECONDS, 0, 1)
	return M.CHASE_SPEED + (M.CHASE_MAX_SPEED - M.CHASE_SPEED) * t
end

-- Reacting to a sound it heard.
local function react(stimulus: Perception.Stimulus)
	local now = os.clock()
	local source = stimulus.source
	Mimicry.remember(stimulus.kind, source ~= nil)
	-- Only current targets can leave a track. An anonymous sound might be
	-- equipment or a thrown object; it cannot reveal a hidden player's location.
	if not source or isTarget(source) then
		memory.observe(stimulus, now)
	end

	if state == "Hunt" then
		if source and source == huntTarget then
			updateTrack(stimulus.estimate, now)
		elseif
			source
			and isTarget(source)
			and now - lastHeard > C.SWITCH_HUNT_AFTER
			and stimulus.clarity >= C.SWITCH_HUNT_CLARITY
			and stimulus.distance <= M.CHASE_LOCK_DISTANCE
		then
			-- A nearby new voice can draw it off a quarry that went silent.
			-- Chase the source's sound estimate, not their current RootPart.
			endLunge(now)
			heading = Vector3.zero
			huntStart = now
			startHunt(source, stimulus.estimate)
		end
		return
	end
	if state == "Retreat" and not stimulus.loud and not frenzied() then
		return
	end
	local busy = state == "Investigate" or state == "Search" or state == "Listen"
	if not memory.attend(stimulus, now, busy) and not frenzied() then
		return
	end

	local awareness = Perception.awareness()
	if frenzied() then
		Perception.set(math.max(awareness, M.HURRY_AT))
		awareness = Perception.awareness()
	end
	if
		source
		and isTarget(source)
		and awareness >= M.HUNT_AT
		and stimulus.clarity >= 0.3
		and stimulus.distance <= M.CHASE_LOCK_DISTANCE
	then
		startHunt(source, stimulus.estimate)
	elseif awareness >= M.INVESTIGATE_AT or stimulus.loud then
		local goal = if source and isTarget(source)
			then memory.predicted(source, now) or stimulus.estimate
			else stimulus.estimate
		investigateKind = stimulus.kind
		startInvestigate(goal, stimulus.loud or awareness >= M.HURRY_AT)
	elseif
		awareness >= M.LISTEN_AT and (state == "Roam" or state == "Search" or state == "Listen")
	then
		startListen(stimulus.estimate)
	end
end

local function onNoise(noise: NoiseService.Noise)
	if state == "Dormant" or not root or noise.time < spawnedAt then
		return
	end
	local stimulus = Perception.hear(noise, ear(), hearing())
	if stimulus then
		react(stimulus)
	end
end

-- Touch: anyone close enough to brush against it is found, however quiet.
local function feelAround()
	local r = root
	if not r then
		return
	end
	for _, player in Players:GetPlayers() do
		if isTarget(player) and player:GetAttribute("Hiding") ~= true then
			local targetRoot = rootOf(player)
			if targetRoot then
				local offset = targetRoot.Position - r.Position
				if flat(offset).Magnitude <= M.TOUCH_DISTANCE and math.abs(offset.Y) < 5 then
					if state == "Hunt" and huntTarget == player then
						updateTrack(targetRoot.Position, os.clock())
					else
						log("felt", player.Name)
						startHunt(player, targetRoot.Position)
					end
					return
				end
			end
		end
	end
end

-- Up close in a hunt it lunges: a short warning (cry, glow, vignette), then a burst of speed straight
-- at the player. Returns true while the burst is steering it.
local function updateLunge(now: number, h: Humanoid, r: BasePart): boolean
	local target = huntTarget
	local targetRoot = if target then rootOf(target) else nil
	if target and target:GetAttribute("Hiding") == true then
		endLunge(now)
		return false
	end
	if lungePhase == "Windup" then
		if now >= lungePhaseEnd then
			lungePhase = "Lunge"
			lungePhaseEnd = now + M.LUNGE_TIME
		end
		return false
	elseif lungePhase == "Lunge" then
		if now >= lungePhaseEnd or not targetRoot then
			endLunge(now)
			return false
		end
		-- The navigator stands aside so it doesn't steer the leap back onto its path.
		if nav and nav.status() ~= "Idle" then
			nav.stop()
		end
		h.WalkSpeed = M.LUNGE_SPEED
		-- A missed lunge goes where the Engineer committed, not through walls
		-- toward a player who moved silently during the windup.
		h:MoveTo(lungeDestination or r.Position)
		return true
	end

	if now < lungeReadyAt or not targetRoot or not target or now - lastHeard > 1 then
		return false
	end
	local offset = targetRoot.Position - r.Position
	if flat(offset).Magnitude > M.LUNGE_RANGE or math.abs(offset.Y) > 5 then
		return false
	end
	local heardAt = lastKnown
	-- Blind lunges require recent audio close to the current target position.
	if
		not heardAt
		or flat(targetRoot.Position - heardAt).Magnitude
			> C.LUNGE_EVIDENCE_RADIUS + math.min(now - lastHeard, 1) * Config.SPRINT_SPEED
	then
		return false
	end
	local ignore: { Instance } = { model :: Model }
	if target.Character then
		table.insert(ignore, target.Character)
	end
	if not hasLineOfSight(r.Position, targetRoot.Position, ignore) then
		return false -- no lunging through walls
	end
	log("lunging at", target.Name)
	lungePhase = "Windup"
	-- Once the windup starts it cannot silently correct to a new location.
	lungeDestination = heardAt + heading * 0.2
	lungePhaseEnd = now + M.LUNGE_WINDUP
	setGlow(5, 16)
	if model then
		model:SetAttribute("Lunging", true)
	end
	Sounds.playAt(Sounds.LUNGE, r.Position, 1, 120)
	return false
end

local function tryCatch(now: number)
	local r = root
	local m = model
	if not r or not m then
		return
	end
	for _, player in Players:GetPlayers() do
		if isTarget(player) and player:GetAttribute("Hiding") ~= true then
			local targetRoot = rootOf(player)
			if targetRoot then
				local offset = targetRoot.Position - r.Position
				if flat(offset).Magnitude <= M.CATCH_DISTANCE and math.abs(offset.Y) < 6 then
					local ignore: { Instance } = { m }
					if player.Character then
						table.insert(ignore, player.Character)
					end
					if hasLineOfSight(r.Position, targetRoot.Position, ignore) then
						log("caught", player.Name)
						Sounds.playAt(Sounds.CATCH, targetRoot.Position, 1)
						onCatch(player)
						endLunge(now)
						if frenzied() then
							-- No breathing room in a frenzy: it goes straight back to listening.
							huntTarget = nil
							startSearch(r.Position)
						else
							-- It leaves its catch behind and backs off: the others get room to breathe.
							startRetreat()
						end
						return
					end
				end
			end
		end
	end
end

-- Walks a route of spots, pausing at some of them. Returns true when the route is done.
local function followRoute(
	now: number,
	speed: number,
	pauseChance: number,
	pauseMin: number,
	pauseMax: number
): boolean
	local h = humanoid :: Humanoid
	local n = nav :: Navigator.Navigator
	if now < pauseUntil then
		return false
	end
	local spot = route[1]
	if not spot then
		return true
	end
	h.WalkSpeed = speed
	n.moveTo(spot)
	local status = n.status()
	if status == "Arrived" or status == "Failed" then
		if state == "Search" then
			memory.visited(spot, now)
		end
		table.remove(route, 1)
		local inspection = inspectionPoints[spot]
		inspectionPoints[spot] = nil
		if status == "Arrived" and inspection then
			pauseUntil = now + C.INSPECT_SECONDS
			if model then
				model:SetAttribute("Inspecting", inspection)
			end
			n.stop()
		elseif status == "Arrived" and rng:NextNumber() < pauseChance then
			pauseUntil = now + rng:NextNumber(pauseMin, pauseMax)
			n.stop()
		end
	end
	return #route == 0
end

local function think(now: number)
	local h = humanoid :: Humanoid
	local r = root :: BasePart
	local n = nav :: Navigator.Navigator

	if model and model:GetAttribute("Inspecting") ~= "" and now >= pauseUntil then
		model:SetAttribute("Inspecting", "")
	end
	if state == "Roam" then
		if #route == 0 then
			local area = Director.pickArea(areas, now, r.Position, targetPositions(), currentArea)
			currentArea = area
			route = pickRoute(area, rng:NextInteger(2, 3))
		end
		followRoute(now, M.ROAM_SPEED, 0.45, 1, 3)
		if Director.wantsRetreat() and not frenzied() then
			startRetreat()
		end
	elseif state == "Listen" then
		if listenToward then
			face(listenToward)
		end
		if now >= listenUntil then
			if resumeState == "Search" and #route > 0 then
				setState("Search")
			else
				startRoam()
			end
		end
	elseif state == "Investigate" then
		local target = investigateTarget
		if not target then
			startRoam()
			return
		end
		h.WalkSpeed = if investigateUrgent then M.HURRY_SPEED else M.INVESTIGATE_SPEED
		n.moveTo(target)
		local status = n.status()
		if status == "Arrived" or flat(target - r.Position).Magnitude < 4 then
			startSearch(target)
		elseif status == "Failed" then
			-- An unreachable sound is not evidence of a player behind the wall.
			-- Inspect the *reachable* side instead of searching a distant point.
			startSearch(r.Position)
		end
	elseif state == "Search" then
		-- At a hiding spot's door: it opens it.
		local nextPoint = route[1]
		local spot = if nextPoint then spotFronts[nextPoint] else nil
		if spot and nextPoint and flat(nextPoint - r.Position).Magnitude < 3.2 then
			table.remove(route, 1)
			spotFronts[nextPoint] = nil
			memory.visited(nextPoint, now)
			n.stop()
			local found = checkSpot(spot)
			local foundRoot = if found then rootOf(found) else nil
			if found and foundRoot then
				log("found", found.Name, "hiding")
				startHunt(found, foundRoot.Position)
				return
			end
			pauseUntil = now + 1.2
		end
		local done = followRoute(now, M.SEARCH_SPEED, 0.8, 1.2, 2.4)
		if done or now >= searchUntil then
			if Director.wantsRetreat() and not frenzied() then
				startRetreat()
			else
				startRoam()
			end
		end
	elseif state == "Retreat" then
		local done = followRoute(now, M.RETREAT_SPEED, 0, 0, 0)
		if Director.mode() ~= "Retreat" or frenzied() then
			startRoam()
		elseif done and currentArea then
			-- Still backstage: idle around the far room until the director lets it go.
			route = pickRoute(currentArea, 1)
			pauseUntil = now + rng:NextNumber(2, 4)
		end
	elseif state == "Hunt" then
		local target = huntTarget
		local targetRoot = if target then rootOf(target) else nil
		if not target or not targetRoot or not isTarget(target) then
			endLunge(now)
			huntTarget = nil
			startSearch(lastKnown or r.Position)
			return
		end
		local silence = now - lastHeard
		local known = lastKnown or r.Position -- never acquire hidden coordinates by fallback
		if silence > M.CHASE_MEMORY then
			-- Lost them: search where they were heading, not where they were.
			endLunge(now)
			huntTarget = nil
			log("lost", target.Name, "- searching ahead of them")
			Perception.set(M.HURRY_AT)
			startInvestigate(known + heading * 1.5, true)
			return
		end
		h.WalkSpeed = chaseSpeed(now)
		local lunging = updateLunge(now, h, r)
		if not lunging then
			-- Right after hearing them it knows roughly where they are; after that, it predicts.
			local goal = memory.predicted(target, now) or (known + heading * math.min(silence, 1.5))
			n.moveTo(goal, true)
			if n.status() == "Failed" then
				n.moveTo(known, false)
			end
		end
	end
end

local function updateDebug()
	if not Config.DEBUG_AI then
		return
	end
	local m = model
	local n = nav
	if not m or not n then
		return
	end
	if not debugLabel then
		local head = m:FindFirstChild("Head")
		if head then
			local board = Instance.new("BillboardGui")
			board.Size = UDim2.fromOffset(270, 84)
			board.StudsOffset = Vector3.new(0, 2.5, 0)
			board.AlwaysOnTop = true
			board.Parent = head
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 0.5
			label.BackgroundColor3 = Color3.new(0, 0, 0)
			label.TextColor3 = Color3.new(1, 1, 1)
			label.Font = Enum.Font.RobotoMono
			label.TextSize = 13
			label.Parent = board
			debugLabel = label
		end
	end
	if debugLabel then
		debugLabel.Text = string.format(
			"%s  aware %d  focus %.0f\n%s  inspect %s\ndirector %s  menace %.2f\nnav %s",
			state,
			Perception.awareness(),
			memory.interest(),
			tostring(m:GetAttribute("Intent") or "Still"),
			tostring(m:GetAttribute("Inspecting") or "-"),
			Director.mode(),
			Director.menace(),
			n.status()
		)
	end
	local points = n.waypoints()
	if points ~= debugPath then
		debugPath = points
		if debugFolder then
			debugFolder:Destroy()
		end
		local folder = Instance.new("Folder")
		folder.Name = "MonsterPathDebug"
		for _, point in points do
			local dot = Instance.new("Part")
			dot.Shape = Enum.PartType.Ball
			dot.Size = Vector3.new(0.6, 0.6, 0.6)
			dot.Position = point + Vector3.new(0, 0.3, 0)
			dot.Anchored = true
			dot.CanCollide = false
			dot.CanQuery = false
			dot.CanTouch = false
			dot.Material = Enum.Material.Neon
			dot.Color = Color3.fromRGB(255, 200, 40)
			dot.Parent = folder
		end
		folder.Parent = Workspace
		debugFolder = folder
	end
end

local function step(now: number, dt: number)
	local r = root
	local n = nav
	if state == "Dormant" or not r or not humanoid or not n then
		return
	end
	if state ~= "Hunt" then
		Perception.decay(dt)
	end
	Director.update(dt, now, r.Position, state == "Hunt", targetPositions())
	feelAround()
	if state == "Roam" or state == "Search" then
		-- Now and then: throw a remembered sound nearby, then wait for whoever comes to look.
		local lure = Mimicry.tryPerform(now, r.Position, areas, targetPositions())
		if lure then
			log("mimicking near", MapContract.placeName(areas, lure))
			startListen(lure, Config.MIMIC.AMBUSH_TIME)
		end
	end
	think(now)
	n.update(now)
	local pose = motion
	if pose then
		local focus: Vector3? = nil
		if state == "Listen" then
			focus = listenToward
		elseif state == "Investigate" then
			focus = investigateTarget
		elseif state == "Search" then
			focus = route[1] or searchCenter
		elseif state == "Hunt" then
			focus = lastKnown
		end
		pose.update(state, focus, state == "Search" and now < pauseUntil, now, dt)
	end
	updateFootsteps(dt)
	tryCatch(now)
	updateDebug()
end

-- ===== API =====

function MonsterService.init(
	mapAreas: { MapContract.Area },
	targetCheck: (Player) -> boolean,
	catchCallback: (Player) -> ()
)
	areas = mapAreas
	isTarget = targetCheck
	onCatch = catchCallback
	NoiseService.onNoise(onNoise)
end

-- Removes the monster (between rounds).
function MonsterService.despawn()
	loopId += 1
	if nav then
		nav.destroy()
	end
	if motion then
		motion.destroy()
		motion = nil
	end
	if model then
		model:Destroy()
	end
	if debugFolder then
		debugFolder:Destroy()
	end
	model, humanoid, root, nav = nil, nil, nil, nil
	searchCenter = nil
	spotFronts = {}
	inspectionPoints = {}
	investigateKind = ""
	investigateTarget = nil
	pauseUntil, listenUntil, searchUntil = 0, 0, 0
	heading = Vector3.zero
	lastHeard = 0
	investigateUrgent = false
	debugLabel, debugFolder, debugPath = nil, nil, nil
	state = "Dormant"
	huntTarget = nil
	lastKnown = nil
	route = {}
	currentArea = nil
	lungePhase = "None"
	lungeDestination = nil
	lungeReadyAt = 0
	glows = {}
	frenzyUntil = 0
	frenzyHeld = false
	Perception.reset()
	memory.reset()
	NoiseService.setIgnoreList({})
end

-- Brings the monster in at `position` and starts its brain.
function MonsterService.spawn(position: Vector3)
	MonsterService.despawn()
	local m, h, r, lights = EngineerModel.build(position)
	spawnedAt = os.clock()
	glows = lights
	model, humanoid, root = m, h, r
	nav = Navigator.new(h, r, { m }, DoorService.isClosedInnerDoor, DoorService.monsterOpen)
	motion = Motion.new(m, r)
	NoiseService.setIgnoreList({ m })
	Director.reset(os.clock())
	Perception.reset()
	Mimicry.reset(os.clock())
	currentArea = areaAt(position)
	startRoam()

	loopId += 1
	local myLoop = loopId
	task.spawn(function()
		local last = os.clock()
		while loopId == myLoop do
			local now = os.clock()
			step(now, now - last)
			last = now
			task.wait(TICK)
		end
	end)
	log("arrived")
end

function MonsterService.getModel(): Model?
	return model
end

-- Where the monster is, if it's in the building.
function MonsterService.position(): Vector3?
	local r = root
	return if r and state ~= "Dormant" then r.Position else nil
end

-- The hiding spots it may open while searching, and how to open one.
function MonsterService.setHidingSpots(spots: { BasePart }, check: (BasePart) -> Player?)
	hidingSpots = spots
	checkSpot = check
end

-- Soft pressure from the round, 0 (calm) to 1 (full): it hears farther and comes looking sooner.
function MonsterService.setPressure(pressure: number)
	local p = math.clamp(pressure, 0, 1)
	pressureHearing = 1 + Config.PACING.PRESSURE_HEARING * p
	Director.setHintScale(1 - Config.PACING.PRESSURE_HINT * p)
end

-- A frenzy for `seconds` (a shock).
function MonsterService.frenzyFor(seconds: number, hearingMultiplier: number?)
	frenzyUntil = math.max(frenzyUntil, os.clock() + seconds)
	frenzyHearing = hearingMultiplier or M.FRENZY_HEARING
	if model then
		model:SetAttribute("Frenzy", true)
	end
	task.delay(seconds + 0.1, function()
		if model and not frenzied() then
			model:SetAttribute("Frenzy", false)
		end
	end)
end

-- A frenzy that lasts until released (Last Call).
function MonsterService.holdFrenzy(on: boolean, hearingMultiplier: number?)
	frenzyHeld = on
	if on then
		frenzyHearing = hearingMultiplier or M.FRENZY_HEARING
	end
	if model then
		model:SetAttribute("Frenzy", frenzied())
	end
end

-- Sends it straight to a place (a loud objective it can't miss), unless it's mid-hunt.
function MonsterService.callTo(position: Vector3)
	if state == "Dormant" or not root or state == "Hunt" then
		return
	end
	Perception.set(math.max(Perception.awareness(), M.HURRY_AT))
	investigateKind = "recording"
	startInvestigate(position, true)
end

-- Keeps the monster's physics owned by the server even if it touches players.
RunService.Heartbeat:Connect(function()
	local r = root
	if r and r.Parent and r:GetNetworkOwner() ~= nil then
		r:SetNetworkOwner(nil)
	end
end)

return MonsterService
