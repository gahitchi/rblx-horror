--!strict
-- After each round in a match server: "Play again?" Those who say no (or don't answer) go back to
-- the hub; those who say yes vote on the next map. The same map keeps going in this server; a
-- different map sends the group to a fresh match server on it. In Studio, or before the places are
-- set up (Config.PLACES), nobody is teleported: everyone just stays for the next round.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local RoundState = require(script.Parent.RoundState)

local ReplayService = {}

local currentMap = Config.MAPS[1].id
local currentChapter = "" -- the chapter being played; a replay keeps it
local voting = false
local choices: { [Player]: boolean } = {}
local votes: { [Player]: string } = {}

local function canTeleport(): boolean
	-- A round trip is only valid when the two published places are configured
	-- and distinct. Match the lobby's preflight rather than sending players
	-- back to the same place when the IDs were copied incorrectly.
	return not RunService:IsStudio()
		and Config.PLACES.HUB ~= 0
		and Config.PLACES.MATCH ~= 0
		and Config.PLACES.HUB ~= Config.PLACES.MATCH
end

local function notify(player: Player, message: string)
	Remotes.Notify:FireClient(player, message)
end

local function publishCounts()
	for _, map in Config.MAPS do
		local count = 0
		for _, id in votes do
			if id == map.id then
				count += 1
			end
		end
		RoundState.set("Votes_" .. map.id, count)
	end
end

local function teleport(
	placeId: number,
	group: { Player },
	data: { [string]: any },
	reserve: boolean
)
	if #group == 0 then
		return
	end
	local options = Instance.new("TeleportOptions")
	options.ShouldReserveServer = reserve
	options:SetTeleportData(data)
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(placeId, group, options)
	end)
	if not ok then
		warn("[Replay] teleport failed: " .. tostring(err))
		for _, player in group do
			notify(player, "The teleport failed; you're staying here for now.")
		end
	end
end

-- Runs the question and the vote with `players`, then moves people where they chose.
function ReplayService.run(players: { Player })
	if not Config.FEATURES.REPLAY or #players == 0 then
		return
	end
	choices, votes = {}, {}
	publishCounts()
	voting = true
	RoundState.set("VoteEnds", os.time() + Config.REPLAY.VOTE_TIME)
	RoundState.set("Voting", true)

	local deadline = os.clock() + Config.REPLAY.VOTE_TIME
	while os.clock() < deadline do
		local undecided = 0
		for _, player in players do
			if player.Parent == Players then
				local choice = choices[player]
				if choice == nil or (choice and not votes[player]) then
					undecided += 1
				end
			end
		end
		if undecided == 0 then
			break
		end
		task.wait(0.5)
	end
	voting = false
	RoundState.set("Voting", false)

	local leaving: { Player } = {}
	local staying: { Player } = {}
	for _, player in players do
		if player.Parent == Players then
			table.insert(if choices[player] == true then staying else leaving, player)
		end
	end

	-- The most voted map among those staying; ties keep the current one.
	local tally: { [string]: number } = {}
	for player, id in votes do
		if choices[player] == true then
			tally[id] = (tally[id] or 0) + 1
		end
	end
	local winner, best = currentMap, tally[currentMap] or 0
	for id, count in tally do
		if count > best then
			winner, best = id, count
		end
	end

	if not canTeleport() then
		for _, player in leaving do
			notify(player, "Back to the hub only works in the published game; staying here.")
		end
		return
	end
	teleport(Config.PLACES.HUB, leaving, { fromMatch = true }, false)
	if winner ~= currentMap then
		teleport(
			Config.PLACES.MATCH,
			staying,
			{ map = winner, chapter = currentChapter, fromMatch = true },
			true
		)
	end
end

function ReplayService.init(mapId: string, chapterId: string)
	currentMap = mapId
	currentChapter = chapterId
	Remotes.ReplayChoice.OnServerEvent:Connect(function(player, again)
		if voting and type(again) == "boolean" then
			choices[player] = again
			if not again then
				votes[player] = nil
				publishCounts()
			end
		end
	end)
	Remotes.MapVote.OnServerEvent:Connect(function(player, id)
		if not voting or choices[player] ~= true or type(id) ~= "string" then
			return
		end
		for _, map in Config.MAPS do
			if map.id == id then
				votes[player] = id
				publishCounts()
				return
			end
		end
	end)
end

return ReplayService
