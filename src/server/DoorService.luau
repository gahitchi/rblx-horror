--!strict
-- Doors swing open and closed around a hinge. Players use a prompt; the monster opens doors it
-- walks into, loudly. Booth doors decide whether a soundproof booth is sealed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local NoiseService = require(script.Parent.NoiseService)

type DoorState = {
	part: BasePart,
	closed: CFrame,
	opened: CFrame,
	busy: boolean,
	prompt: ProximityPrompt?,
}

local SWING_TIME = 0.35

local doors: { [BasePart]: DoorState } = {}

local DoorService = {}

local function swing(state: DoorState, open: boolean)
	state.busy = true
	state.part:SetAttribute("Open", open)
	state.part.CanCollide = not open
	state.part.CanQuery = not open -- an open door no longer muffles sound
	local tween = TweenService:Create(
		state.part,
		TweenInfo.new(SWING_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = if open then state.opened else state.closed }
	)
	tween.Completed:Once(function()
		state.busy = false
	end)
	tween:Play()
	if state.prompt then
		state.prompt.ActionText = if open then "Close" else "Open"
	end
end

-- Toggles a door. `loudness` is how far the sound carries; the source player is credited for the noise.
-- `kind` is "door" for players and "monster" for the monster, which never reacts to its own noise.
local function toggle(state: DoorState, loudness: number, source: Player?, kind: string)
	if state.busy then
		return
	end
	swing(state, not (state.part:GetAttribute("Open") == true))
	Sounds.playAt(Sounds.DOOR, state.part.Position, 0.7)
	NoiseService.emit(state.part.Position, loudness, kind, source)
end

function DoorService.register(part: BasePart, withPrompt: boolean)
	local width = part.Size.X
	local closed = part.CFrame
	-- Hinge on the door's left edge; open by rotating 90 degrees around it.
	local hinge = closed * CFrame.new(-width / 2, 0, 0)
	local opened = hinge * CFrame.Angles(0, math.rad(90), 0) * (hinge:Inverse() * closed)

	local state: DoorState =
		{ part = part, closed = closed, opened = opened, busy = false, prompt = nil }
	doors[part] = state

	if withPrompt then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = if part:GetAttribute("Kind") == "booth"
			then "Soundproof booth"
			else "Door"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.RequiresLineOfSight = false
		prompt.Parent = part
		prompt.Triggered:Connect(function(player)
			toggle(state, Config.NOISE.DOOR, player, "door")
		end)
		state.prompt = prompt
	end
end

-- True for a closed door the monster may push open (any registered door except the exit).
function DoorService.isClosedInnerDoor(part: BasePart): boolean
	return doors[part] ~= nil
		and part:GetAttribute("Kind") ~= "front"
		and part:GetAttribute("Open") ~= true
end

function DoorService.isOpen(part: BasePart): boolean
	return part:GetAttribute("Open") == true
end

-- Called by the monster when it reaches a closed door.
function DoorService.monsterOpen(part: BasePart)
	local state = doors[part]
	if state and not DoorService.isOpen(part) then
		toggle(state, Config.NOISE.DOOR_SLAM, nil, "monster")
	end
end

-- Opens or closes a door from game logic (the front doors), without a player.
function DoorService.set(part: BasePart, open: boolean)
	local state = doors[part]
	if state and DoorService.isOpen(part) ~= open then
		swing(state, open)
	end
end

-- Closes every door instantly: used when a new round starts.
function DoorService.resetAll()
	for part, state in doors do
		part:SetAttribute("Open", false)
		part.CanCollide = true
		part.CanQuery = true
		part.CFrame = state.closed
		state.busy = false
		if state.prompt then
			state.prompt.ActionText = "Open"
		end
	end
end

-- The closest closed door within `distance` of a position, if any.
function DoorService.closedDoorNear(position: Vector3, distance: number): BasePart?
	local best: BasePart? = nil
	local bestDistance = distance
	for part in doors do
		if not DoorService.isOpen(part) and part:GetAttribute("Kind") ~= "front" then
			local d = (part.Position - position).Magnitude
			if d < bestDistance then
				best = part
				bestDistance = d
			end
		end
	end
	return best
end

return DoorService
