--!strict
-- Wardrobes and lockers. Step in and your noise is muffled (Config.HIDE.MUFFLE). The monster is
-- blind, so a hiding spot works by sound alone: with it close, your breathing grows loud. Hold
-- your breath (Space) for a few seconds; run out and you gasp. Breathing draws it over to listen,
-- and when it searches nearby it opens hiding spots it walks past. Open one with you inside and
-- it has you.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local MapContract = require(script.Parent.MapContract)
local MonsterService = require(script.Parent.MonsterService)
local NoiseService = require(script.Parent.NoiseService)
local RoundState = require(script.Parent.RoundState)

local HIDE = Config.HIDE

type Breath = { holding: boolean, left: number, nextBreath: number }

local HideService = {}

local isTarget: (Player) -> boolean = function()
	return false
end
local hiddenIn: { [Player]: BasePart } = {}
local occupant: { [BasePart]: Player } = {}
local breath: { [Player]: Breath } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	if r and r:IsA("BasePart") then
		return r
	end
	return nil
end

local function setAttributes(player: Player, hiding: boolean)
	player:SetAttribute("Hiding", hiding)
	player:SetAttribute("BreathDanger", false)
	player:SetAttribute("BreathLeft", 1)
	local character = player.Character
	if character then
		character:SetAttribute("Hiding", hiding)
	end
end

function HideService.isHiding(player: Player): boolean
	local spot: BasePart? = hiddenIn[player]
	return spot ~= nil
end

-- Steps a player out of their hiding spot, in front of its door.
function HideService.leave(player: Player)
	local spot = hiddenIn[player]
	if not spot then
		return
	end
	hiddenIn[player] = nil
	occupant[spot] = nil
	breath[player] = nil
	setAttributes(player, false)
	local r = rootOf(player)
	if r and r.Parent then
		local floorY = spot.Position.Y - spot.Size.Y / 2
		local front = spot.CFrame * CFrame.new(0, 0, -(spot.Size.Z / 2 + 2))
		r.CFrame = CFrame.lookAt(
			Vector3.new(front.X, floorY + 3, front.Z),
			Vector3.new(front.X, floorY + 3, front.Z) + spot.CFrame.LookVector
		)
		r.Anchored = false
	end
end

local function hide(player: Player, spot: BasePart)
	local r = rootOf(player)
	if not r then
		return
	end
	hiddenIn[player] = spot
	occupant[spot] = player
	breath[player] = { holding = false, left = HIDE.HOLD_SECONDS, nextBreath = 0 }
	setAttributes(player, true)
	r.Anchored = true
	local floorY = spot.Position.Y - spot.Size.Y / 2
	r.CFrame = CFrame.lookAt(
		Vector3.new(spot.Position.X, floorY + 3, spot.Position.Z),
		Vector3.new(spot.Position.X, floorY + 3, spot.Position.Z) + spot.CFrame.LookVector
	)
	Sounds.playAt(Sounds.DOOR, spot.Position, 0.4, 40, 1.3)
end

-- The monster opens a hiding spot. Returns whoever was inside (now pulled out), if anyone.
function HideService.check(spot: BasePart): Player?
	local found = occupant[spot]
	Sounds.playAt(Sounds.DOOR, spot.Position, 0.9, 80, 0.8)
	if found and isTarget(found) then
		HideService.leave(found)
		return found
	end
	return nil
end

-- How much of a player's noise gets out (muffled while hiding).
function HideService.muffle(player: Player): number
	return if hiddenIn[player] then HIDE.MUFFLE else 1
end

local function onHoldBreath(player: Player, holding: unknown)
	local b = breath[player]
	if b and type(holding) == "boolean" then
		b.holding = holding and b.left > 0
	end
end

local function update(dt: number)
	local monster = MonsterService.position()
	local now = os.clock()
	for player, spot in hiddenIn do
		local b = breath[player]
		if player.Parent ~= Players or not isTarget(player) or not b then
			HideService.leave(player)
			continue
		end
		local close = monster ~= nil and (monster - spot.Position).Magnitude <= HIDE.BREATH_RANGE
		player:SetAttribute("BreathDanger", close)
		if b.holding then
			b.left -= dt
			if b.left <= 0 then
				-- Out of breath: a gasp it can't miss.
				b.left = 0
				b.holding = false
				Sounds.playAt(Sounds.VOICE_GARBLE, spot.Position, 0.8, 60, 1.2)
				NoiseService.emit(spot.Position, Config.NOISE.GASP, "gasp", nil)
			end
		else
			b.left =
				math.min(HIDE.HOLD_SECONDS, b.left + dt * HIDE.HOLD_SECONDS / HIDE.RECOVER_SECONDS)
			if close and now >= b.nextBreath then
				b.nextBreath = now + HIDE.BREATH_INTERVAL
				NoiseService.emit(spot.Position, Config.NOISE.BREATH, "breath", nil)
			end
		end
		player:SetAttribute("BreathLeft", b.left / HIDE.HOLD_SECONDS)
	end
end

function HideService.reset()
	for player in hiddenIn do
		HideService.leave(player)
	end
	hiddenIn = {}
	occupant = {}
	breath = {}
end

function HideService.init(layout: MapContract.Layout, targetCheck: (Player) -> boolean)
	isTarget = targetCheck
	for _, spot in layout.hidingSpots do
		local kind = spot:GetAttribute("Kind")
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Hide"
		prompt.ObjectText = if kind == "locker" then "Locker" else "Wardrobe"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 6
		prompt.RequiresLineOfSight = false
		prompt.Parent = spot
		prompt.Triggered:Connect(function(player)
			if hiddenIn[player] == spot then
				HideService.leave(player)
			elseif not isTarget(player) or hiddenIn[player] then
				return
			elseif occupant[spot] then
				Remotes.Notify:FireClient(player, "Someone's already in there.")
			else
				hide(player, spot)
			end
		end)
	end
	NoiseService.setMuffle(HideService.muffle)
	MonsterService.setHidingSpots(layout.hidingSpots, HideService.check)
	Remotes.HoldBreath.OnServerEvent:Connect(onHoldBreath)
	Players.PlayerRemoving:Connect(function(player)
		local spot = hiddenIn[player]
		if spot then
			occupant[spot] = nil
		end
		hiddenIn[player] = nil
		breath[player] = nil
	end)
	local last = os.clock()
	task.spawn(function()
		while true do
			task.wait(0.2)
			local now = os.clock()
			if RoundState.get("Phase") == "Playing" then
				update(now - last)
			end
			last = now
		end
	end)
end

return HideService
