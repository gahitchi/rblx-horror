--!strict
-- Hub lobbies (crews). Players create a crew (chapter, size, friends only or not), others join, and
-- the host starts it: everyone in it is teleported together to a fresh reserved match server for
-- that chapter. Lobbies are strict: everyone must have the chapter unlocked (the story is played in
-- order). Quick join puts you in a crew on your next unplayed chapter, or makes one.
--
-- Who sees what:
--   * lobbies in this hub server: everyone, except friends-only ones (only the host's friends);
--   * lobbies in other hub servers: only those whose host is your friend. They're shared between
--     hub servers through a MemoryStore map; joining one first moves you to that hub server.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Chapters = require(Shared:WaitForChild("Chapters"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local L = Config.LOBBY

type Lobby = {
	id: string,
	host: Player,
	map: string,
	chapter: string,
	max: number,
	friendsOnly: boolean,
	members: { Player },
	starting: boolean,
}

-- What a hub publishes for other hubs (and what the remote part of the list is built from).
type Published = {
	id: string,
	hostId: number,
	hostName: string,
	map: string,
	chapter: string,
	max: number,
	count: number,
	friendsOnly: boolean,
	jobId: string,
}

local LobbyService = {}

-- The hub scene may lift the barrier before a published teleport starts.
local onDeparture: (() -> ())? = nil

function LobbyService.onDeparture(callback: () -> ())
	onDeparture = callback
end

local lobbies: { [string]: Lobby } = {}
local lobbyOf: { [Player]: Lobby } = {}
local friends: { [Player]: { [number]: boolean } } = {}
local remote: { Published } = {} -- other hubs' lobbies, refreshed periodically
local shared: MemoryStoreSortedMap? = nil

local function notify(player: Player, message: string)
	Remotes.Notify:FireClient(player, message)
end

local function mapName(id: string): string
	for _, map in Config.MAPS do
		if map.id == id then
			return map.name
		end
	end
	return id
end

local function validMap(id: unknown): string
	for _, map in Config.MAPS do
		if map.id == id then
			return map.id
		end
	end
	return Config.MAPS[1].id
end

-- The chapters a player has cleared live in the match place's progress save; read them here.
local progressStore: DataStore? = nil

local function loadProgress(player: Player)
	local store = progressStore
	if not store then
		player:SetAttribute("ChaptersCleared", "")
		player:SetAttribute("TapesDelivered", "")
		player:SetAttribute("Level", 1)
		player:SetAttribute("FlashlightSkin", "warm")
		player:SetAttribute("ProgressSaved", false)
		return
	end
	local ok, result = pcall(function()
		return store:GetAsync("player_" .. player.UserId)
	end)
	local function ids(value: any): { string }
		local list: { string } = {}
		if type(value) == "table" then
			for _, id in value do
				if type(id) == "string" then
					table.insert(list, id)
				end
			end
		end
		return list
	end
	local saved: any = if ok and type(result) == "table" then result else {}
	if player.Parent == Players then
		player:SetAttribute("ChaptersCleared", table.concat(ids(saved.chapters), ","))
		-- Optional tapes delivered (the van's tape deck plays them back).
		player:SetAttribute("TapesDelivered", table.concat(ids(saved.tapes), ","))
		-- Expose only the public loadout fields, not a separate hub progression save.
		local xp = math.max(0, tonumber(saved.xp) or 0)
		local level, need, total = 1, 100, 0
		while xp >= total + need do
			total += need
			need += 100
			level += 1
		end
		player:SetAttribute("Level", level)
		local skin = saved.skin
		player:SetAttribute("FlashlightSkin", if type(skin) == "string"
			and Config.FLASHLIGHT_SKINS[skin] then skin else "warm")
		player:SetAttribute("ProgressSaved", ok)
	end
end

local function canPlay(player: Player, chapterId: string): boolean
	return Chapters.unlocked(Chapters.clearedBy(player), chapterId)
end

local function isFriend(viewer: Player, userId: number): boolean
	local set = friends[viewer]
	return set ~= nil and set[userId] == true
end

local function loadFriends(player: Player)
	local set: { [number]: boolean } = {}
	pcall(function()
		local pages = Players:GetFriendsAsync(player.UserId)
		for _ = 1, 4 do -- up to about 200 friends
			for _, friend in pages:GetCurrentPage() do
				set[friend.Id] = true
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
	end)
	friends[player] = set
end

local function removeShared(id: string)
	if shared then
		task.spawn(function()
			pcall(function()
				(shared :: MemoryStoreSortedMap):RemoveAsync(id)
			end)
		end)
	end
end

local function leave(player: Player)
	local lobby = lobbyOf[player]
	if not lobby then
		return
	end
	lobbyOf[player] = nil
	local index = table.find(lobby.members, player)
	if index then
		table.remove(lobby.members, index)
	end
	if #lobby.members == 0 then
		lobbies[lobby.id] = nil
		removeShared(lobby.id)
	elseif lobby.host == player then
		lobby.host = lobby.members[1] -- the next member hosts
		notify(lobby.host, "You're the host of this lobby now.")
	end
end

local function join(player: Player, lobby: Lobby): boolean
	if lobby.starting or #lobby.members >= lobby.max then
		notify(player, "That lobby is full or already starting.")
		return false
	end
	if lobby.friendsOnly and lobby.host ~= player and not isFriend(player, lobby.host.UserId) then
		notify(player, "That lobby is for the host's friends.")
		return false
	end
	-- Strict: the story is played in order.
	if not canPlay(player, lobby.chapter) then
		notify(
			player,
			"You haven't unlocked "
				.. Chapters.name(lobby.chapter)
				.. " yet. Clear the chapter before it first."
		)
		return false
	end
	leave(player)
	table.insert(lobby.members, player)
	lobbyOf[player] = lobby
	return true
end

local function onCreate(player: Player, settings: unknown)
	local raw: { [any]: any } = if type(settings) == "table" then settings :: any else {}
	local max = math.clamp(math.floor(tonumber(raw.max) or L.MAX_PLAYERS), 1, L.MAX_PLAYERS)
	-- The chapter: the one asked for if this player has unlocked it, otherwise their next one.
	local entry = Chapters.find(raw.chapter)
	local chapterId = if entry and canPlay(player, entry.id)
		then entry.id
		else Chapters.nextFor(Chapters.clearedBy(player))
	local chapter = Chapters.find(chapterId)
	leave(player)
	local lobby: Lobby = {
		id = string.sub(HttpService:GenerateGUID(false), 1, 8),
		host = player,
		map = validMap(if chapter then chapter.map else raw.map),
		chapter = chapterId,
		max = max,
		friendsOnly = raw.friendsOnly == true,
		members = {},
		starting = false,
	}
	lobbies[lobby.id] = lobby
	join(player, lobby)
end

local function onJoin(player: Player, id: unknown)
	if type(id) ~= "string" then
		return
	end
	local lobby = lobbies[id]
	if lobby then
		join(player, lobby)
		return
	end
	-- A friend's lobby in another hub server: go there first, then join on arrival.
	for _, entry in remote do
		if entry.id == id and isFriend(player, entry.hostId) then
			if RunService:IsStudio() then
				notify(player, "Joining another hub server only works in the published game.")
				return
			end
			local options = Instance.new("TeleportOptions")
			options.ServerInstanceId = entry.jobId
			options:SetTeleportData({ joinLobby = id })
			local ok = pcall(function()
				TeleportService:TeleportAsync(game.PlaceId, { player }, options)
			end)
			if not ok then
				notify(player, "Couldn't reach your friend's hub server. Try again.")
			end
			return
		end
	end
	notify(player, "That lobby doesn't exist any more.")
end

-- Quick join: a public crew here on this player's next unplayed chapter, or a new one.
local function onQuickJoin(player: Player)
	local wanted = Chapters.nextFor(Chapters.clearedBy(player))
	for _, lobby in lobbies do
		if
			lobby.chapter == wanted
			and not lobby.friendsOnly
			and not lobby.starting
			and #lobby.members < lobby.max
			and lobbyOf[player] ~= lobby
		then
			if join(player, lobby) then
				notify(player, "Joined " .. lobby.host.DisplayName .. "'s crew.")
				return
			end
		end
	end
	onCreate(player, { chapter = wanted, max = L.MAX_PLAYERS, friendsOnly = false })
	notify(player, "No crew was waiting, so you made one. Others can join it.")
end

local function onStart(player: Player)
	local lobby = lobbyOf[player]
	if not lobby or lobby.host ~= player or lobby.starting then
		return
	end
	if Config.PLACES.MATCH == 0 or RunService:IsStudio() then
		notify(
			player,
			"Starting a match needs the published game with Config.PLACES set (see docs/HUB.md)."
		)
		return
	end
	lobby.starting = true
	removeShared(lobby.id)
	local members = table.clone(lobby.members)
	for _, member in members do
		notify(member, "Starting " .. Chapters.name(lobby.chapter) .. "...")
	end
	if onDeparture then
		local ok, message = pcall(onDeparture)
		if not ok then
			warn("[Hub gate] departure effect failed: " .. tostring(message))
		end
	end
	-- Let the barrier rise before teleporting. The hub scene is never a
	-- prerequisite for a match; an absent gate cannot stop valid crews.
	task.wait(1.25)
	local options = Instance.new("TeleportOptions")
	options.ShouldReserveServer = true
	options:SetTeleportData({ map = lobby.map, chapter = lobby.chapter, fromHub = true })
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(Config.PLACES.MATCH, members, options)
	end)
	if not ok then
		lobby.starting = false
		for _, member in members do
			notify(member, "The teleport failed. Try starting again.")
		end
		warn("[Lobby] teleport failed: " .. tostring(err))
	end
end

-- What one player sees: this server's visible lobbies, plus friends' lobbies elsewhere.
local function listFor(viewer: Player): { any }
	local list = {}
	for _, lobby in lobbies do
		local visible = not lobby.friendsOnly
			or lobby.host == viewer
			or isFriend(viewer, lobby.host.UserId)
		if visible and not lobby.starting then
			table.insert(list, {
				id = lobby.id,
				host = lobby.host.DisplayName,
				map = mapName(lobby.map),
				chapter = Chapters.name(lobby.chapter),
				locked = not canPlay(viewer, lobby.chapter),
				count = #lobby.members,
				max = lobby.max,
				friendsOnly = lobby.friendsOnly,
				here = true,
				mine = lobbyOf[viewer] == lobby,
				isHost = lobby.host == viewer,
			})
		end
	end
	for _, entry in remote do
		if
			entry.jobId ~= game.JobId
			and isFriend(viewer, entry.hostId)
			and not lobbies[entry.id]
		then
			table.insert(list, {
				id = entry.id,
				host = entry.hostName,
				map = mapName(entry.map),
				chapter = Chapters.name(entry.chapter),
				locked = not canPlay(viewer, entry.chapter),
				count = entry.count,
				max = entry.max,
				friendsOnly = entry.friendsOnly,
				here = false,
				mine = false,
				isHost = false,
			})
		end
	end
	return list
end

local function publishLoop()
	while true do
		task.wait(L.PUBLISH_INTERVAL)
		local map = shared
		if map then
			for id, lobby in lobbies do
				if not lobby.starting then
					local entry: Published = {
						id = id,
						hostId = lobby.host.UserId,
						hostName = lobby.host.DisplayName,
						map = lobby.map,
						chapter = lobby.chapter,
						max = lobby.max,
						count = #lobby.members,
						friendsOnly = lobby.friendsOnly,
						jobId = game.JobId,
					}
					pcall(function()
						map:SetAsync(id, entry, L.EXPIRY)
					end)
				end
			end
			local ok, items = pcall(function()
				return map:GetRangeAsync(Enum.SortDirection.Ascending, 200)
			end)
			if ok and type(items) == "table" then
				local fresh: { Published } = {}
				for _, item in items do
					if type(item.value) == "table" then
						table.insert(fresh, item.value)
					end
				end
				remote = fresh
			end
		end
	end
end

function LobbyService.init()
	local ok, result = pcall(function()
		return MemoryStoreService:GetSortedMap("HubLobbies_v1")
	end)
	if ok then
		shared = result
	end

	Remotes.CreateLobby.OnServerEvent:Connect(onCreate)
	Remotes.JoinLobby.OnServerEvent:Connect(onJoin)
	Remotes.LeaveLobby.OnServerEvent:Connect(leave)
	Remotes.StartLobby.OnServerEvent:Connect(onStart)
	Remotes.QuickJoin.OnServerEvent:Connect(onQuickJoin)
	local storeOk, storeResult = pcall(function()
		return DataStoreService:GetDataStore("Progress_v1")
	end)
	if storeOk then
		progressStore = storeResult
	end

	local function onPlayer(player: Player)
		task.spawn(loadProgress, player)
		loadFriends(player)
		-- Arrived from another hub server to join a friend's lobby?
		local joinData = player:GetJoinData()
		local data: any = joinData and joinData.TeleportData
		local wanted = if type(data) == "table" then data.joinLobby else nil
		if type(wanted) == "string" then
			local lobby = lobbies[wanted]
			if lobby then
				join(player, lobby)
			else
				notify(player, "That lobby already started or closed.")
			end
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayer, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		leave(player)
		friends[player] = nil
	end)
	TeleportService.TeleportInitFailed:Connect(function(player)
		local lobby = lobbyOf[player]
		if lobby then
			lobby.starting = false
		end
		notify(player, "The teleport failed. Try again.")
	end)

	task.spawn(publishLoop)
	task.spawn(function()
		while true do
			for _, player in Players:GetPlayers() do
				local mine = lobbyOf[player]
				Remotes.LobbyList:FireClient(player, listFor(player), if mine then mine.id else nil)
			end
			task.wait(L.LIST_INTERVAL)
		end
	end)
end

return LobbyService
