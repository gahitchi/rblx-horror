--!strict
-- Map 1's objectives, in order: start the generator, fit three fuses, play the emergency tape.
-- Every step makes noise on purpose: loud to escape, quiet to survive.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local DoorService = require(script.Parent.DoorService)
local MapBuilder = require(script.Parent.MapBuilder)
local NoiseService = require(script.Parent.NoiseService)
local RoundState = require(script.Parent.RoundState)

local ObjectiveService = {}

local layout: MapBuilder.Layout
local isTarget: (Player) -> boolean
local fuseFolder: Folder
local roundId = 0 -- bumps each reset, so loops from an old round stop
local tapeRunning = false
local rng = Random.new()

local function notify(player: Player, message: string)
	Remotes.Notify:FireClient(player, message)
end

local function notifyAll(message: string)
	Remotes.Notify:FireAllClients(message)
end

local function makePrompt(
	parent: BasePart,
	action: string,
	object: string,
	hold: number
): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = hold
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

local function setPower(on: boolean)
	RoundState.set("PowerOn", on)
	for _, light in layout.powerLights do
		light.Enabled = on
	end
	for _, lamp in layout.powerLamps do
		lamp.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		lamp.Color = if on then Color3.fromRGB(255, 120, 90) else Color3.fromRGB(60, 30, 26)
	end
end

local function spawnFuse(position: Vector3)
	local fuse = Instance.new("Part")
	fuse.Name = "Fuse"
	fuse.Size = Vector3.new(0.6, 0.5, 1.4)
	fuse.Position = position
	fuse.Color = MapBuilder.FUSE_COLOR
	fuse.Material = Enum.Material.Neon
	fuse.Anchored = true
	fuse.CanCollide = false
	fuse.CanQuery = false
	fuse.Parent = fuseFolder

	local glow = Instance.new("PointLight")
	glow.Color = MapBuilder.FUSE_COLOR
	glow.Brightness = 0.6
	glow.Range = 5
	glow.Parent = fuse

	local prompt = makePrompt(fuse, "Pick up", "Fuse", 0)
	prompt.Triggered:Connect(function(player)
		if not isTarget(player) then
			return
		end
		if player:GetAttribute("CarryingFuse") then
			notify(player, "You can only carry one fuse at a time.")
			return
		end
		player:SetAttribute("CarryingFuse", true)
		fuse:Destroy()
		notify(player, "Fuse picked up. Take it to the fuse box in the basement.")
	end)
end

local function startHum(myRound: number)
	task.spawn(function()
		while roundId == myRound and RoundState.get("PowerOn") do
			NoiseService.emit(
				layout.generator.Position,
				Config.NOISE.GENERATOR_HUM,
				"generator",
				nil
			)
			task.wait(Config.GENERATOR_HUM_INTERVAL)
		end
	end)
end

local function onGeneratorPull(player: Player)
	if not isTarget(player) or RoundState.get("PowerOn") then
		return
	end
	local pulls = (RoundState.get("GeneratorPulls") or 0) + 1
	RoundState.set("GeneratorPulls", pulls)
	Sounds.playAt(Sounds.GENERATOR_PULL, layout.generator.Position, 1, 200)
	NoiseService.emit(layout.generator.Position, Config.NOISE.GENERATOR_PULL, "generator", player)
	if pulls >= Config.GENERATOR_PULLS then
		setPower(true)
		startHum(roundId)
		notifyAll("The generator is running. The emergency lights are on.")
	else
		notify(player, string.format("The engine coughs... (%d/%d)", pulls, Config.GENERATOR_PULLS))
	end
end

local function onInsertFuse(player: Player)
	if not isTarget(player) then
		return
	end
	if not player:GetAttribute("CarryingFuse") then
		notify(player, "The fuse box is missing fuses. Find them around the studio.")
		return
	end
	player:SetAttribute("CarryingFuse", false)
	local placed = (RoundState.get("FusesPlaced") or 0) + 1
	RoundState.set("FusesPlaced", placed)
	Sounds.playAt(Sounds.FUSE, layout.fuseBox.Position, 1)
	NoiseService.emit(layout.fuseBox.Position, Config.NOISE.FUSE, "fuse", player)
	if placed >= Config.FUSES_NEEDED then
		notifyAll("All fuses are in. The tape deck in control room A has power.")
	else
		notifyAll(string.format("Fuse fitted (%d/%d).", placed, Config.FUSES_NEEDED))
	end
end

local function onPlayTape(player: Player, prompt: ProximityPrompt)
	if not isTarget(player) or tapeRunning or RoundState.get("DoorsOpen") then
		return
	end
	if not RoundState.get("PowerOn") then
		notify(player, "No power. Start the generator in the basement.")
		return
	end
	if (RoundState.get("FusesPlaced") or 0) < Config.FUSES_NEEDED then
		notify(player, "The deck won't run. The fuse box still needs fuses.")
		return
	end

	tapeRunning = true
	prompt.Enabled = false
	notifyAll("The emergency tape is playing on every speaker. Hold on until the doors unlock!")
	local myRound = roundId
	task.spawn(function()
		local elapsed = 0
		while roundId == myRound and elapsed < Config.TAPE_DURATION do
			for _, speaker in layout.speakers do
				Sounds.playAt(Sounds.ALARM, speaker, 1, 300)
			end
			local speaker = layout.speakers[rng:NextInteger(1, #layout.speakers)]
			NoiseService.emit(speaker, Config.NOISE.ALARM, "alarm", nil)
			task.wait(Config.ALARM_INTERVAL)
			elapsed += Config.ALARM_INTERVAL
			RoundState.set("TapeProgress", math.min(elapsed / Config.TAPE_DURATION, 1))
		end
		if roundId ~= myRound then
			return
		end
		tapeRunning = false
		RoundState.set("DoorsOpen", true)
		DoorService.set(layout.frontDoor, true)
		notifyAll("The front doors are open. RUN!")
	end)
end

-- A player who dies or leaves while carrying a fuse drops it where they were.
function ObjectiveService.dropFuse(player: Player, position: Vector3)
	if player:GetAttribute("CarryingFuse") then
		player:SetAttribute("CarryingFuse", false)
		spawnFuse(position)
	end
end

function ObjectiveService.reset()
	roundId += 1
	tapeRunning = false
	fuseFolder:ClearAllChildren()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("CarryingFuse", false)
	end
	setPower(false)
	RoundState.set("GeneratorPulls", 0)
	RoundState.set("FusesPlaced", 0)
	RoundState.set("TapeProgress", 0)
	RoundState.set("DoorsOpen", false)
	DoorService.set(layout.frontDoor, false)

	local tapePrompt = layout.tapeDeck:FindFirstChildOfClass("ProximityPrompt")
	if tapePrompt then
		tapePrompt.Enabled = true
	end

	-- Three fuses in different random spots each round.
	local spots = table.clone(layout.fuseSpots)
	for _ = 1, Config.FUSES_NEEDED do
		local index = rng:NextInteger(1, #spots)
		spawnFuse(spots[index])
		table.remove(spots, index)
	end
end

function ObjectiveService.init(map: MapBuilder.Layout, targetCheck: (Player) -> boolean)
	layout = map
	isTarget = targetCheck

	fuseFolder = Instance.new("Folder")
	fuseFolder.Name = "Fuses"
	fuseFolder.Parent = Workspace

	makePrompt(layout.generator, "Pull starter", "Generator", 1.2).Triggered:Connect(
		onGeneratorPull
	)
	makePrompt(layout.fuseBox, "Insert fuse", "Fuse box", 0.6).Triggered:Connect(onInsertFuse)
	local tapePrompt = makePrompt(layout.tapeDeck, "Play emergency tape", "Tape deck", 1)
	tapePrompt.Triggered:Connect(function(player)
		onPlayTape(player, tapePrompt)
	end)

	ObjectiveService.reset()
end

return ObjectiveService
