--!strict
-- Bringing a caught teammate back. Once per round per player (rules in RoundService.canRevive).
--
--   1. The caught player, while spectating, puts up the price: a level (back to the start of the
--      previous one, which relocks its rewards), a revive bought earlier, or Robux (a Developer
--      Product priced as a rare exception).
--   2. Their walkie lies where they were caught; teammates get a radio message with the room.
--   3. A living teammate holds E on it for a few seconds while it screeches back to life (loud:
--      the monster hears it), and the caught player comes back on that spot.
--   4. If nobody comes before the round ends, the price is refunded.
-- Robux purchases are stored as revive tokens and saved before being granted, so none is ever lost.

local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local MapContract = require(script.Parent.MapContract)
local NoiseService = require(script.Parent.NoiseService)
local ProgressService = require(script.Parent.ProgressService)
local RoundService = require(script.Parent.RoundService)

type Pending = { method: string, xpBefore: number }

local ReviveService = {}

local areas: { MapContract.Area } = {}
local purchases: DataStore? = nil
local folder: Folder
local markers: { [Player]: BasePart } = {}
local pending: { [Player]: Pending } = {}

local function notify(player: Player, message: string)
	Remotes.Notify:FireClient(player, message)
end

local function clearMarker(player: Player)
	local marker = markers[player]
	if marker then
		marker:Destroy()
		markers[player] = nil
	end
end

-- The caught player's walkie, left on the floor where it happened. Inert until they pay.
local function dropMarker(player: Player, position: Vector3)
	clearMarker(player)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = { folder }
	for _, other in Players:GetPlayers() do
		if other.Character then
			table.insert(exclude, other.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	local floor = Workspace:Raycast(position, Vector3.new(0, -10, 0), params)
	local spot = if floor then floor.Position else position - Vector3.new(0, 3, 0)

	local marker = Instance.new("Part")
	marker.Name = player.Name .. "Walkie"
	marker.Size = Vector3.new(0.6, 0.3, 1)
	marker.CFrame = CFrame.new(spot + Vector3.new(0, 0.15, 0))
	marker.Color = Color3.fromRGB(35, 35, 32)
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker:SetAttribute("Owner", player.UserId)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 70, 50)
	light.Range = 5
	light.Brightness = 0.8
	light.Enabled = false -- lit once a revive is paid for
	light.Parent = marker

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Bring back " .. player.DisplayName
	prompt.ObjectText = "Lost walkie"
	prompt.HoldDuration = Config.REVIVE.HOLD_SECONDS
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = marker

	-- The hold is loud: static every second until it finishes or they let go.
	local holding: { [Player]: boolean } = {}
	prompt.PromptButtonHoldBegan:Connect(function(by)
		holding[by] = true
		task.spawn(function()
			while holding[by] and marker.Parent do
				Sounds.playAt(Sounds.WALKIE_CRACKLE, marker.Position, 0.8, 70, 0.4)
				NoiseService.emit(marker.Position, Config.REVIVE.NOISE, "walkie", by)
				task.wait(1)
			end
		end)
	end)
	prompt.PromptButtonHoldEnded:Connect(function(by)
		holding[by] = nil
	end)
	prompt.Triggered:Connect(function(by)
		holding[by] = nil
		if by == player or not RoundService.isTarget(by) or not pending[player] then
			return
		end
		local at = CFrame.new(marker.Position + Vector3.new(0, 3, 0))
		pending[player] = nil
		clearMarker(player)
		if RoundService.revive(player, at) then
			ProgressService.award(by, "Brought a teammate back", Config.REWARDS.REVIVE)
		end
	end)

	marker.Parent = folder
	markers[player] = marker
end

-- The price is paid: wake the walkie up and tell the team where it is.
local function activate(player: Player, method: string, xpBefore: number)
	local marker = markers[player]
	if not marker then
		return
	end
	pending[player] = { method = method, xpBefore = xpBefore }
	player:SetAttribute("RevivePending", true)
	local light = marker:FindFirstChildOfClass("PointLight")
	if light then
		light.Enabled = true
	end
	local prompt = marker:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = true
	end
	local room = MapContract.placeName(areas, marker.Position)
	for _, other in Players:GetPlayers() do
		if other ~= player and RoundService.isTarget(other) then
			Remotes.Radio:FireClient(
				other,
				player.DisplayName,
				room,
				"Bring me back! My walkie is here."
			)
		end
	end
	notify(player, "Your team has been told where your walkie is. Wait for someone to reach it.")
end

local function canAsk(player: Player): boolean
	local hasMarker = if markers[player] then true else false
	return RoundService.canRevive(player) and hasMarker and not pending[player]
end

local function onAsk(player: Player, method: unknown)
	if not canAsk(player) then
		notify(player, "You can't ask for a revive right now.")
		return
	end
	local xpBefore = ProgressService.xpOf(player)
	if method == "token" then
		if ProgressService.useReviveToken(player) then
			activate(player, "token", xpBefore)
		end
	elseif method == "level" then
		if ProgressService.loseLevel(player) then
			activate(player, "level", xpBefore)
		else
			notify(player, "You need to be at least level 2 to trade a level for a revive.")
		end
	end
end

-- Round over: refund anyone still waiting, clear the walkies.
local function onRoundEnd()
	for player, ask in pending do
		if ask.method == "level" then
			ProgressService.restoreXp(player, ask.xpBefore)
		else
			ProgressService.addReviveToken(player)
		end
		notify(player, "Nobody reached your walkie in time. The revive was refunded.")
	end
	pending = {}
	for player in markers do
		player:SetAttribute("RevivePending", false)
	end
	folder:ClearAllChildren()
	markers = {}
end

local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	if receipt.ProductId ~= Config.REVIVE.PRODUCT_ID or Config.REVIVE.PRODUCT_ID == 0 then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox retries when they're back
	end
	local purchaseKey = tostring(receipt.PurchaseId)

	-- Already granted (Roblox can call this more than once for the same purchase).
	if purchases then
		local ok, done = pcall(function()
			return (purchases :: DataStore):GetAsync(purchaseKey)
		end)
		if not ok then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if done then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	if not ProgressService.addReviveToken(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if not ProgressService.saveNow(player) and not RunService:IsStudio() then
		ProgressService.useReviveToken(player) -- undo: Roblox will retry the purchase later
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if purchases then
		pcall(function()
			(purchases :: DataStore):SetAsync(purchaseKey, true)
		end)
	end

	if canAsk(player) and ProgressService.useReviveToken(player) then
		activate(player, "token", ProgressService.xpOf(player))
	else
		notify(player, "Revive bought. It's saved for the next time you're caught.")
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ReviveService.init(mapAreas: { MapContract.Area })
	areas = mapAreas
	folder = Instance.new("Folder")
	folder.Name = "LostWalkies"
	folder.Parent = Workspace
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("Purchases_v1")
	end)
	if ok then
		purchases = result
	end
	Remotes.Revive.OnServerEvent:Connect(onAsk)
	MarketplaceService.ProcessReceipt = processReceipt
	RoundService.onCaught(dropMarker)
	RoundService.onRoundEnd(onRoundEnd)
	RoundService.onRoundStart(onRoundEnd)
	RoundService.onSpawn(function(player, _, inRound)
		if inRound then
			player:SetAttribute("RevivePending", false)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local ask = pending[player]
		if ask then
			-- Leaving while waiting: refund now, so it's saved with their progress.
			if ask.method == "level" then
				ProgressService.restoreXp(player, ask.xpBefore)
			else
				ProgressService.addReviveToken(player)
			end
			pending[player] = nil
		end
		clearMarker(player)
	end)
end

return ReviveService
