--!strict
-- The Engineer: map 1's monster. Blind; it only knows where you are from what it hears.
-- States: Dormant (not arrived yet) -> Wander -> Investigate a noise -> Search the area,
-- or Chase a player it keeps hearing close by. It catches anyone it reaches.

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local DoorService = require(script.Parent.DoorService)
local NoiseService = require(script.Parent.NoiseService)

type State = "Dormant" | "Wander" | "Investigate" | "Search" | "Chase"
type LungePhase = "None" | "Windup" | "Lunge"

local M = Config.MONSTER
local TICK = 0.1

local MonsterService = {}

local model: Model? = nil
local humanoid: Humanoid? = nil
local root: BasePart? = nil
local state: State = "Dormant"
local wanderNodes: { Vector3 } = {}
local isTarget: (Player) -> boolean = function()
	return false
end
local onCatch: (Player) -> () = function() end

local goal: Vector3? = nil
local waypoints: { PathWaypoint } = {}
local waypointIndex = 1
local lastPathTime = 0
local lastGoalForPath: Vector3? = nil

local chaseTarget: Player? = nil
local lastHeardTime = 0
local lastHeardPosition: Vector3? = nil
local chaseStartTime = 0
local lungePhase: LungePhase = "None"
local lungePhaseEnd = 0
local lungeReadyAt = 0
local glows: { PointLight } = {}
local searchUntil = 0
local nextSearchPoint = 0
local stuckCheckTime = 0
local stuckCheckPosition = Vector3.zero
local loopId = 0
local rng = Random.new()

local path = PathfindingService:CreatePath({
	AgentRadius = 2.2,
	AgentHeight = 8.5,
	AgentCanJump = false,
	WaypointSpacing = 4,
})

local function log(...)
	if Config.DEBUG then
		print("[Engineer]", ...)
	end
end

local function setState(newState: State)
	if state ~= newState then
		state = newState
		if model then
			model:SetAttribute("State", newState)
		end
		log("->", newState)
	end
end

local function weld(part: BasePart, to: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = to
	w.Part1 = part
	w.Parent = part
end

-- A tall, gaunt figure with studio headphones grown into its skull. Placeholder shapes for now.
local function buildModel(position: Vector3): (Model, Humanoid, BasePart)
	local m = Instance.new("Model")
	m.Name = "Monster"
	glows = {}
	m:SetAttribute("MonsterName", "The Engineer")

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.CFrame = CFrame.new(position)
	hrp.Parent = m
	m.PrimaryPart = hrp

	local skin = Color3.fromRGB(32, 30, 30)
	local function limb(
		name: string,
		size: Vector3,
		offset: Vector3,
		color: Color3?,
		material: Enum.Material?
	): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = hrp.CFrame * CFrame.new(offset)
		p.Color = color or skin
		p.Material = material or Enum.Material.SmoothPlastic
		p.CanCollide = false
		p.Massless = true
		p.Parent = m
		weld(p, hrp)
		return p
	end

	limb("Torso", Vector3.new(2.2, 3.6, 1.1), Vector3.new(0, 1, 0))
	local head = limb("Head", Vector3.new(1.4, 1.6, 1.4), Vector3.new(0, 3.6, 0))
	limb("LeftLeg", Vector3.new(0.7, 4, 0.7), Vector3.new(-0.6, -2, 0))
	limb("RightLeg", Vector3.new(0.7, 4, 0.7), Vector3.new(0.6, -2, 0))
	limb("LeftArm", Vector3.new(0.5, 4.8, 0.5), Vector3.new(-1.45, 0.4, 0))
	limb("RightArm", Vector3.new(0.5, 4.8, 0.5), Vector3.new(1.45, 0.4, 0))
	limb(
		"HeadphoneBand",
		Vector3.new(1.9, 0.3, 0.4),
		Vector3.new(0, 4.55, 0),
		Color3.fromRGB(20, 20, 20),
		Enum.Material.Metal
	)
	for _, side in { -1, 1 } do
		local cup = limb(
			"Earcup",
			Vector3.new(0.5, 1, 1),
			Vector3.new(side * 0.95, 3.6, 0),
			Color3.fromRGB(18, 18, 18),
			Enum.Material.Metal
		)
		-- A faint red glow from the earcups: just enough to glimpse it in the dark.
		local glow = Instance.new("PointLight")
		glow.Color = Color3.fromRGB(255, 40, 30)
		glow.Brightness = 0.8
		glow.Range = 7
		glow.Parent = cup
		table.insert(glows, glow)
	end
	head:SetAttribute("Blind", true)

	local h = Instance.new("Humanoid")
	h.RigType = Enum.HumanoidRigType.R15
	h.HipHeight = 3
	h.WalkSpeed = M.WANDER_SPEED
	h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	h.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	h:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	h:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	h.Parent = m

	m.Parent = Workspace
	hrp:SetNetworkOwner(nil) -- the server moves it, not a nearby player's client
	return m, h, hrp
end

local function computePath(target: Vector3)
	local r = root
	if not r then
		return
	end
	lastPathTime = os.clock()
	lastGoalForPath = target
	local ok = pcall(function()
		path:ComputeAsync(r.Position, target)
	end)
	if ok and path.Status == Enum.PathStatus.Success then
		waypoints = path:GetWaypoints()
		waypointIndex = math.min(2, #waypoints)
	else
		waypoints = {}
		waypointIndex = 1
	end
end

local function pickWanderGoal(): Vector3
	return wanderNodes[rng:NextInteger(1, #wanderNodes)]
end

local function startSearch(around: Vector3)
	setState("Search")
	searchUntil = os.clock() + M.SEARCH_TIME
	nextSearchPoint = 0
	goal = around
end

local function hasLineOfSight(from: Vector3, to: Vector3, ignore: { Instance }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	return Workspace:Raycast(from, to - from, params) == nil
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	return nil
end

local function onNoise(noise: NoiseService.Noise)
	local r = root
	if state == "Dormant" or not r then
		return
	end
	if not NoiseService.canHear(noise, r.Position) then
		return
	end

	local source = noise.source
	local distance = (noise.position - r.Position).Magnitude
	if source and isTarget(source) and distance <= M.CHASE_LOCK_DISTANCE then
		if chaseTarget ~= source then
			log("chasing", source.Name, "heard", noise.kind)
		end
		if state ~= "Chase" then
			chaseStartTime = os.clock()
		end
		chaseTarget = source
		lastHeardTime = os.clock()
		lastHeardPosition = noise.position
		setState("Chase")
	elseif state ~= "Chase" then
		goal = noise.position
		setState("Investigate")
	elseif source == chaseTarget then
		lastHeardTime = os.clock()
		lastHeardPosition = noise.position
	end
end

-- Starts at walking pace and builds up the longer the chase goes on.
local function chaseSpeed(now: number): number
	local t = math.clamp((now - chaseStartTime) / M.CHASE_RAMP_SECONDS, 0, 1)
	return M.CHASE_SPEED + (M.CHASE_MAX_SPEED - M.CHASE_SPEED) * t
end

local function decideGoal(now: number): (Vector3?, number)
	local r = root :: BasePart
	if state == "Chase" then
		local target = chaseTarget
		if not target or not isTarget(target) or now - lastHeardTime > M.CHASE_MEMORY then
			chaseTarget = nil
			startSearch(lastHeardPosition or r.Position)
			return goal, M.INVESTIGATE_SPEED
		end
		-- Right after hearing them it knows roughly where they are; then only where they last were.
		local targetRoot = rootOf(target)
		if targetRoot and now - lastHeardTime < 1 then
			return targetRoot.Position, chaseSpeed(now)
		end
		return lastHeardPosition, chaseSpeed(now)
	elseif state == "Investigate" then
		if goal and (goal - r.Position).Magnitude < 5 then
			startSearch(goal)
		end
		return goal, M.INVESTIGATE_SPEED
	elseif state == "Search" then
		if now > searchUntil then
			setState("Wander")
			goal = pickWanderGoal()
			return goal, M.WANDER_SPEED
		end
		if now > nextSearchPoint then
			nextSearchPoint = now + 3
			local offset = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
				* M.SEARCH_RADIUS
			goal = (lastHeardPosition or r.Position) + offset
		end
		return goal, M.WANDER_SPEED
	else -- Wander
		if not goal or (goal - r.Position).Magnitude < 6 then
			goal = pickWanderGoal()
		end
		return goal, M.WANDER_SPEED
	end
end

local function setLungeVisual(on: boolean)
	if model then
		model:SetAttribute("Lunging", on)
	end
	for _, glow in glows do
		glow.Brightness = if on then 5 else 0.8
		glow.Range = if on then 16 else 7
	end
end

local function endLunge(now: number)
	if lungePhase ~= "None" then
		lungePhase = "None"
		lungeReadyAt = now + M.LUNGE_COOLDOWN
		setLungeVisual(false)
	end
end

-- Up close in a chase it lunges: a short warning (shriek, glow), then a burst of speed straight at
-- the player. Returns true while the burst is moving it, so normal pathing stands aside.
local function updateLunge(now: number, h: Humanoid, r: BasePart): boolean
	local target = chaseTarget
	local targetRoot = if target then rootOf(target) else nil
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
		h.WalkSpeed = M.LUNGE_SPEED
		h:MoveTo(targetRoot.Position)
		return true
	end

	if state ~= "Chase" or now < lungeReadyAt or not targetRoot or not target then
		return false
	end
	local offset = targetRoot.Position - r.Position
	local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
	if flat > M.LUNGE_RANGE or math.abs(offset.Y) > 6 then
		return false
	end
	-- It needs a clear run at them: no lunging through walls.
	local ignore: { Instance } = { model :: Model }
	if target.Character then
		table.insert(ignore, target.Character)
	end
	if not hasLineOfSight(r.Position, targetRoot.Position, ignore) then
		return false
	end
	log("lunging at", target.Name)
	lungePhase = "Windup"
	lungePhaseEnd = now + M.LUNGE_WINDUP
	setLungeVisual(true)
	Sounds.playAt(Sounds.LUNGE, r.Position, 1, 120)
	return false
end

local function tryCatch()
	local r = root
	local m = model
	if not r or not m then
		return
	end
	for _, player in Players:GetPlayers() do
		if isTarget(player) then
			local targetRoot = rootOf(player)
			if targetRoot then
				local offset = targetRoot.Position - r.Position
				local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
				if flat <= M.CATCH_DISTANCE and math.abs(offset.Y) < 6 then
					local ignore: { Instance } = { m }
					if player.Character then
						table.insert(ignore, player.Character)
					end
					if hasLineOfSight(r.Position, targetRoot.Position, ignore) then
						log("caught", player.Name)
						Sounds.playAt(Sounds.CATCH, targetRoot.Position, 1)
						onCatch(player)
						endLunge(os.clock())
						if chaseTarget == player then
							chaseTarget = nil
							startSearch(r.Position)
						end
					end
				end
			end
		end
	end
end

local function step(now: number)
	local h = humanoid
	local r = root
	if not h or not r or state == "Dormant" then
		return
	end

	local target, speed = decideGoal(now)
	h.WalkSpeed = speed
	if not target then
		return
	end
	local lunging = updateLunge(now, h, r)

	-- Re-plan when the goal moved, on a timer while chasing, or when the path ran out.
	local goalMoved = not lastGoalForPath or (target - (lastGoalForPath :: Vector3)).Magnitude > 4
	local repathDue = state == "Chase" and now - lastPathTime > M.REPATH_INTERVAL
	if not lunging and (goalMoved or repathDue or waypointIndex > #waypoints) then
		computePath(target)
	end

	if lunging then
		-- updateLunge is steering.
	elseif #waypoints > 0 and waypointIndex <= #waypoints then
		local waypoint = waypoints[waypointIndex].Position
		h:MoveTo(waypoint)
		local flat = Vector3.new(waypoint.X - r.Position.X, 0, waypoint.Z - r.Position.Z).Magnitude
		if flat < 3 then
			waypointIndex += 1
		end
	else
		h:MoveTo(target) -- no path: head straight for it
	end

	local door = DoorService.closedDoorNear(r.Position, M.DOOR_OPEN_DISTANCE)
	if door then
		DoorService.monsterOpen(door)
	end

	-- If it hasn't moved in a while, it's stuck: re-plan towards somewhere else.
	if now - stuckCheckTime > 3 then
		if (r.Position - stuckCheckPosition).Magnitude < 1.5 and state ~= "Chase" then
			goal = pickWanderGoal()
			lastGoalForPath = nil
		end
		stuckCheckTime = now
		stuckCheckPosition = r.Position
	end

	tryCatch()
end

function MonsterService.init(
	nodes: { Vector3 },
	targetCheck: (Player) -> boolean,
	catchCallback: (Player) -> ()
)
	wanderNodes = nodes
	isTarget = targetCheck
	onCatch = catchCallback
	NoiseService.onNoise(onNoise)
end

-- Removes the monster (between rounds).
function MonsterService.despawn()
	loopId += 1
	if model then
		model:Destroy()
	end
	model, humanoid, root = nil, nil, nil
	state = "Dormant"
	chaseTarget = nil
	goal = nil
	waypoints = {}
	lungePhase = "None"
	lungeReadyAt = 0
	glows = {}
	NoiseService.setIgnoreList({})
end

-- Brings the monster in at `position` and starts its brain.
function MonsterService.spawn(position: Vector3)
	MonsterService.despawn()
	local m, h, r = buildModel(position)
	model, humanoid, root = m, h, r
	NoiseService.setIgnoreList({ m })
	setState("Wander")
	goal = pickWanderGoal()
	stuckCheckTime = os.clock()
	stuckCheckPosition = r.Position

	loopId += 1
	local myLoop = loopId
	task.spawn(function()
		while loopId == myLoop do
			step(os.clock())
			task.wait(TICK)
		end
	end)
	log("arrived")
end

function MonsterService.getModel(): Model?
	return model
end

-- Keeps the monster's physics owned by the server even if it touches players.
RunService.Heartbeat:Connect(function()
	if root and root.Parent and root:GetNetworkOwner() ~= nil then
		root:SetNetworkOwner(nil)
	end
end)

return MonsterService
