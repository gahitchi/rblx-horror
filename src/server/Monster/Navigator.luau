--!strict
-- Moves a humanoid around the map the way a careful NPC should: it never walks blindly at a goal.
--
--   * Paths are computed in the background, so the brain never stalls; the old path keeps being
--     followed until the new one is ready.
--   * If the exact goal can't be reached (inside a prop, off the navmesh) it tries spots around it.
--   * Path smoothing: it skips ahead to the farthest waypoint it can walk to in a straight, clear
--     line, so it cuts corners like a person instead of zig-zagging between waypoints.
--   * Direct steering: when the goal itself is in clear reach on the same floor (a chase in an open
--     room), it heads straight for it without pathfinding.
--   * Doors: a closed door across its way gets pushed open.
--   * Stuck recovery: re-plan, then back off and re-plan, then give up and report "Failed" so the
--     brain picks something else to do.

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

export type Status = "Idle" | "Moving" | "Arrived" | "Failed"

export type Navigator = {
	-- Head for `destination`. `allowDirect` lets it steer straight there when the way is clear.
	moveTo: (destination: Vector3, allowDirect: boolean?) -> (),
	stop: () -> (),
	update: (now: number) -> (),
	status: () -> Status,
	waypoints: () -> { Vector3 },
	destroy: () -> (),
}

local AGENT = {
	AgentRadius = 1.5,
	AgentHeight = 8.5,
	AgentCanJump = false,
	AgentCanClimb = false,
	WaypointSpacing = 4,
}
local ARRIVE_DISTANCE = 2.2 -- flat distance at which a waypoint counts as reached
local LOOKAHEAD = 4 -- how many waypoints ahead it tries to skip to
local CLEARANCE = 1.3 -- radius of the body sweep used for straight-line checks
local STEP_HEIGHT = 1.6 -- a waypoint this much above or below the feet is "another level"
local REPLAN_SHIFT = 3 -- re-plan when the goal moves this far
local REPLAN_INTERVAL = 0.35 -- but not more often than this
local STUCK_INTERVAL = 1
local STUCK_PROGRESS = 1 -- studs it must cover per interval while moving
local DOOR_REACH = 5
local FALLBACK_RADII = { 4, 8 }

local Navigator = {}

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function flatDistance(a: Vector3, b: Vector3): number
	return (flat(a) - flat(b)).Magnitude
end

function Navigator.new(
	humanoid: Humanoid,
	root: BasePart,
	ignore: { Instance },
	isClosedDoor: (BasePart) -> boolean,
	openDoor: (BasePart) -> ()
): Navigator
	local status: Status = "Idle"
	local destination: Vector3? = nil
	local plannedFor: Vector3? = nil -- the destination the current or pending plan is for
	local allowDirect = false
	local direct = false
	local points: { Vector3 } = {}
	local index = 1
	local currentPath: Path? = nil
	local blockedConnection: RBXScriptConnection? = nil
	local computeId = 0
	local lastComputeTime = -math.huge
	local progressTime = 0
	local progressPosition = root.Position
	local stuckCount = 0
	local backoffUntil = 0
	local destroyed = false

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	local function refreshIgnore()
		local list = table.clone(ignore)
		for _, player in Players:GetPlayers() do
			if player.Character then
				table.insert(list, player.Character)
			end
		end
		params.FilterDescendantsInstances = list
	end

	local function feetY(): number
		return root.Position.Y - humanoid.HipHeight - root.Size.Y / 2
	end

	-- The floor height under a point, if there's floor within reach below it.
	local function groundY(point: Vector3): number?
		local hit = Workspace:Raycast(point + Vector3.new(0, 1, 0), Vector3.new(0, -10, 0), params)
		return if hit then hit.Position.Y else nil
	end

	-- Can it walk from where it stands to `point` in a straight line, on the same floor, without
	-- hitting anything (closed doors included)?
	local function clearWalk(point: Vector3): boolean
		local feet = feetY()
		local ground = groundY(point)
		if not ground or math.abs(ground - feet) > STEP_HEIGHT then
			return false
		end
		local height = feet + CLEARANCE + 0.9 -- sweep above ankle-high clutter, below the head
		local from = Vector3.new(root.Position.X, height, root.Position.Z)
		local to = Vector3.new(point.X, height, point.Z)
		local offset = to - from
		if offset.Magnitude < 0.1 then
			return true
		end
		return Workspace:Spherecast(from, CLEARANCE, offset, params) == nil
	end

	local function clearPath()
		if blockedConnection then
			blockedConnection:Disconnect()
			blockedConnection = nil
		end
		if currentPath then
			currentPath:Destroy()
			currentPath = nil
		end
		points = {}
		index = 1
	end

	local function tryCompute(from: Vector3, to: Vector3): (Path?, { PathWaypoint }?)
		local path = PathfindingService:CreatePath(AGENT)
		local ok = pcall(function()
			path:ComputeAsync(from, to)
		end)
		if ok and path.Status == Enum.PathStatus.Success then
			local waypoints = path:GetWaypoints()
			if #waypoints > 0 then
				return path, waypoints
			end
		end
		path:Destroy()
		return nil, nil
	end

	local requestPath: (Vector3) -> ()

	local function adopt(path: Path, waypoints: { PathWaypoint })
		clearPath()
		currentPath = path
		for _, waypoint in waypoints do
			table.insert(points, waypoint.Position)
		end
		index = math.min(2, #points) -- the first waypoint is where it stands
		status = "Moving"
		progressTime = os.clock()
		progressPosition = root.Position
		-- Something moved into the way after planning: plan again.
		blockedConnection = path.Blocked:Connect(function(blockedIndex: number)
			if blockedIndex >= index and destination then
				requestPath(destination)
			end
		end)
	end

	requestPath = function(target: Vector3)
		computeId += 1
		local myId = computeId
		lastComputeTime = os.clock()
		plannedFor = target
		task.spawn(function()
			local from = root.Position
			local path, waypoints = tryCompute(from, target)
			-- The exact spot may be unreachable (inside a prop, a wall, mid-air): try around it.
			if not path then
				for _, radius in FALLBACK_RADII do
					for i = 0, 7 do
						if myId ~= computeId or destroyed then
							return
						end
						local angle = i * math.pi / 4
						local candidate = target
							+ Vector3.new(math.cos(angle), 0, math.sin(angle)) * radius
						path, waypoints = tryCompute(from, candidate)
						if path then
							break
						end
					end
					if path then
						break
					end
				end
			end
			if myId ~= computeId or destroyed then
				if path then
					path:Destroy()
				end
				return
			end
			if path and waypoints then
				adopt(path, waypoints)
			else
				clearPath()
				status = "Failed"
			end
		end)
	end

	local function openDoorsAhead(target: Vector3)
		local offset = flat(target - root.Position)
		if offset.Magnitude < 0.1 then
			return
		end
		local reach = math.min(offset.Magnitude + 1, DOOR_REACH)
		local hit = Workspace:Raycast(root.Position, offset.Unit * reach, params)
		if hit and hit.Instance:IsA("BasePart") and isClosedDoor(hit.Instance) then
			openDoor(hit.Instance)
		end
	end

	local function checkStuck(now: number)
		if now - progressTime < STUCK_INTERVAL then
			return
		end
		local moved = flatDistance(root.Position, progressPosition)
		progressTime = now
		progressPosition = root.Position
		if moved >= STUCK_PROGRESS then
			stuckCount = 0
			return
		end
		stuckCount += 1
		if stuckCount == 1 then
			direct = false
			plannedFor = nil -- re-plan on the next update
		elseif stuckCount == 2 then
			-- Step back from whatever it's pressed against, then re-plan.
			humanoid:MoveTo(root.Position - root.CFrame.LookVector * 4)
			backoffUntil = now + 0.7
			direct = false
			plannedFor = nil
		else
			stuckCount = 0
			clearPath()
			direct = false
			status = "Failed"
		end
	end

	local nav = {} :: Navigator

	function nav.moveTo(target: Vector3, allowStraight: boolean?)
		if destination and (destination - target).Magnitude < 0.5 and status ~= "Idle" then
			allowDirect = allowStraight == true
			return
		end
		destination = target
		allowDirect = allowStraight == true
		if status == "Idle" or status == "Arrived" or status == "Failed" then
			status = "Moving"
			plannedFor = nil -- always a fresh plan after stopping, arriving or failing
			progressTime = os.clock()
			progressPosition = root.Position
			stuckCount = 0
		end
	end

	function nav.stop()
		destination = nil
		plannedFor = nil
		direct = false
		computeId += 1
		clearPath()
		status = "Idle"
		humanoid:MoveTo(root.Position)
	end

	function nav.update(now: number)
		local goal = destination
		if not goal or status == "Idle" or status == "Arrived" or status == "Failed" then
			return
		end
		if now < backoffUntil then
			return
		end
		refreshIgnore()

		-- Straight for it when it's close, on the same floor and nothing is in the way.
		if allowDirect and clearWalk(goal) then
			direct = true
			humanoid:MoveTo(goal)
			openDoorsAhead(goal)
			if flatDistance(root.Position, goal) < ARRIVE_DISTANCE then
				status = "Arrived"
				return
			end
			checkStuck(now)
			return
		elseif direct then
			direct = false
			plannedFor = nil -- the straight line closed up: plan a path
		end

		-- (Re-)plan when there's no plan for this goal yet.
		local planned = plannedFor
		if
			(planned == nil or (planned - goal).Magnitude > REPLAN_SHIFT)
			and now - lastComputeTime >= REPLAN_INTERVAL
		then
			requestPath(goal)
		end
		if index > #points then
			if #points > 0 then
				status = "Arrived"
			end
			return -- still computing the first plan
		end

		-- Skip ahead to the farthest waypoint it can walk to directly.
		for ahead = math.min(index + LOOKAHEAD, #points), index + 1, -1 do
			if clearWalk(points[ahead]) then
				index = ahead
				break
			end
		end
		local target = points[index]
		if
			flatDistance(root.Position, target) < ARRIVE_DISTANCE
			and math.abs(target.Y - feetY()) < 3
		then
			index += 1
			if index > #points then
				status = "Arrived"
				return
			end
			target = points[index]
		end
		humanoid:MoveTo(target)
		openDoorsAhead(target)
		checkStuck(now)
	end

	function nav.status(): Status
		return status
	end

	function nav.waypoints(): { Vector3 }
		return points
	end

	function nav.destroy()
		destroyed = true
		computeId += 1
		clearPath()
	end

	return nav
end

return Navigator
