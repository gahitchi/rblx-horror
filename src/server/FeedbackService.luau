--!strict
-- Optional feedback from players: a 1-5 rating, some quick tags, and an optional short comment.
-- Comments go through Roblox's text filter before they're stored. Everything is saved in the
-- "Feedback_v1" DataStore (see docs/FEEDBACK.md for reading it), ratings are also sent to the
-- Creator Dashboard as a custom analytics event, and in Studio each entry is printed to the Output.

local AnalyticsService = game:GetService("AnalyticsService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

-- The tags a player can tick. The client shows the same list.
local TAGS: { [string]: boolean } = {
	["Too hard"] = true,
	["Too easy"] = true,
	["Too dark"] = true,
	["Confusing"] = true,
	["Found a bug"] = true,
	["Monster got stuck"] = true,
	["Scary in a good way"] = true,
	["Want more maps"] = true,
}
local MAX_TEXT = 300
local COOLDOWN = 120 -- seconds between submissions from one player

local FeedbackService = {}

local store: DataStore? = nil
local lastSent: { [Player]: number } = {}

local function filtered(player: Player, text: string): string?
	local ok, result = pcall(function()
		local filter = TextService:FilterStringAsync(text, player.UserId)
		return filter:GetNonChatStringForBroadcastAsync()
	end)
	return if ok and type(result) == "string" then result else nil
end

local function reply(player: Player, ok: boolean, message: string)
	Remotes.FeedbackReceived:FireClient(player, ok, message)
end

local function onFeedback(player: Player, payload: unknown)
	if not Config.FEATURES.FEEDBACK or type(payload) ~= "table" then
		return
	end
	local now = os.clock()
	if now - (lastSent[player] or -math.huge) < COOLDOWN then
		reply(
			player,
			false,
			"Thanks, we already got your feedback. Try again in a couple of minutes."
		)
		return
	end

	local raw = payload :: { [any]: any }
	local rating = tonumber(raw.rating)
	if not rating or rating ~= math.floor(rating) or rating < 1 or rating > 5 then
		reply(player, false, "Pick a rating from 1 to 5 first.")
		return
	end
	local tags: { string } = {}
	if type(raw.tags) == "table" then
		for _, tag in raw.tags do
			if type(tag) == "string" and TAGS[tag] and not table.find(tags, tag) then
				table.insert(tags, tag)
			end
		end
	end
	local text = ""
	if type(raw.text) == "string" and #raw.text > 0 then
		local trimmed = string.sub(raw.text, 1, MAX_TEXT)
		text = filtered(player, trimmed) or "" -- if the filter can't run, the comment is dropped
	end
	lastSent[player] = now

	local entry = {
		time = os.time(),
		userId = player.UserId,
		version = Config.VERSION,
		level = player:GetAttribute("Level"),
		rating = rating,
		tags = tags,
		text = text,
	}
	if RunService:IsStudio() then
		print("[Feedback] " .. HttpService:JSONEncode(entry))
	end
	pcall(function()
		AnalyticsService:LogCustomEvent(player, "FeedbackRating", rating)
	end)
	task.spawn(function()
		if store then
			local key = string.format("%d_%d", os.time(), player.UserId)
			pcall(function()
				(store :: DataStore):SetAsync(key, entry)
			end)
		end
	end)
	reply(player, true, "Thank you! Your feedback was sent.")
end

function FeedbackService.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("Feedback_v1")
	end)
	if ok then
		store = result
	end
	Remotes.SendFeedback.OnServerEvent:Connect(onFeedback)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastSent[player] = nil
	end)
end

return FeedbackService
