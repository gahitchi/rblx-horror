--!strict
-- The screens outside the action: level and coins, the ready button (G), the end-of-round results,
-- and the optional feedback menu. While any of it is on screen the mouse is free to click it.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local FONT = Enum.Font.RobotoMono
local TEXT = Color3.fromRGB(225, 220, 210)
local DIM = Color3.fromRGB(130, 125, 118)
local PANEL = Color3.fromRGB(18, 17, 16)
local ACCENT = Color3.fromRGB(200, 70, 55)
local GOOD = Color3.fromRGB(120, 200, 140)

-- Must match the server's list in FeedbackService.
local TAGS = {
	"Too hard",
	"Too easy",
	"Too dark",
	"Confusing",
	"Found a bug",
	"Monster got stuck",
	"Scary in a good way",
	"Want more maps",
}
local OUTCOME_TEXT = { escaped = "escaped", caught = "caught", alive = "still inside" }

local LobbyUi = {}

local function frame(parent: Instance, size: UDim2, position: UDim2, anchor: Vector2?): Frame
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = position
	f.AnchorPoint = anchor or Vector2.zero
	f.BackgroundColor3 = PANEL
	f.BackgroundTransparency = 0.15
	f.BorderSizePixel = 0
	f.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = f
	return f
end

local function text(
	parent: Instance,
	content: string,
	size: UDim2,
	position: UDim2,
	textSize: number
): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = position
	l.Font = FONT
	l.TextSize = textSize
	l.TextColor3 = TEXT
	l.TextWrapped = true
	l.Text = content
	l.Parent = parent
	return l
end

local function button(parent: Instance, content: string, size: UDim2, position: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = Color3.fromRGB(45, 42, 40)
	b.BorderSizePixel = 0
	b.Font = FONT
	b.TextSize = 15
	b.TextColor3 = TEXT
	b.Text = content
	b.AutoButtonColor = true
	b.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = b
	return b
end

function LobbyUi.start()
	local state = ReplicatedStorage:WaitForChild("RoundState")

	local gui = Instance.new("ScreenGui")
	gui.Name = "DeadAirLobby"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Top right: level and coins.
	local progress = text(gui, "", UDim2.fromOffset(320, 20), UDim2.new(1, -340, 0, 12), 15)
	progress.TextXAlignment = Enum.TextXAlignment.Right

	-- Bottom centre in the lobby: ready and feedback.
	local bar =
		frame(gui, UDim2.fromOffset(420, 52), UDim2.new(0.5, 0, 1, -110), Vector2.new(0.5, 0))
	local readyButton = button(bar, "", UDim2.fromOffset(190, 36), UDim2.fromOffset(8, 8))
	local feedbackButton =
		button(bar, "Feedback", UDim2.fromOffset(110, 36), UDim2.fromOffset(204, 8))
	local readyCount = text(bar, "", UDim2.fromOffset(90, 36), UDim2.fromOffset(322, 8), 13)
	readyCount.TextColor3 = DIM
	feedbackButton.Visible = Config.FEATURES.FEEDBACK

	local function toggleReady()
		Remotes.SetReady:FireServer(player:GetAttribute("Ready") ~= true)
	end
	readyButton.Activated:Connect(toggleReady)

	-- Results, centre screen at the end of a round.
	local results =
		frame(gui, UDim2.fromOffset(460, 300), UDim2.fromScale(0.5, 0.42), Vector2.new(0.5, 0.5))
	results.Visible = false
	local resultsTitle =
		text(results, "ROUND OVER", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 8), 20)
	resultsTitle.TextColor3 = ACCENT
	local resultsBody = text(results, "", UDim2.new(1, -32, 1, -56), UDim2.fromOffset(16, 46), 15)
	resultsBody.TextXAlignment = Enum.TextXAlignment.Left
	resultsBody.TextYAlignment = Enum.TextYAlignment.Top
	resultsBody.RichText = true
	local resultsShown = 0

	Remotes.Results.OnClientEvent:Connect(function(rows: { any })
		local lines: { string } = {}
		local mine: { string } = {}
		for _, row in rows do
			if type(row) == "table" then
				local outcome = OUTCOME_TEXT[row.outcome] or tostring(row.outcome)
				local color = if row.outcome == "escaped" then GOOD else ACCENT
				table.insert(
					lines,
					string.format(
						'%s  <font color="#%s">%s</font>   +%d XP  +%d coins',
						tostring(row.name),
						color:ToHex(),
						outcome,
						tonumber(row.xp) or 0,
						tonumber(row.coins) or 0
					)
				)
				if row.name == player.DisplayName and type(row.lines) == "table" then
					for _, line in row.lines do
						table.insert(mine, "  " .. tostring(line))
					end
				end
			end
		end
		if #mine > 0 then
			table.insert(lines, "")
			table.insert(
				lines,
				string.format('<font color="#%s">What you earned:</font>', DIM:ToHex())
			)
			for _, line in mine do
				table.insert(lines, line)
			end
		end
		resultsBody.Text = table.concat(lines, "\n")
		results.Visible = true
		resultsShown = os.clock()
	end)

	-- The feedback menu.
	local menu =
		frame(gui, UDim2.fromOffset(500, 400), UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
	menu.Visible = false
	menu.ZIndex = 10
	text(menu, "How's Dead Air so far?", UDim2.new(1, 0, 0, 30), UDim2.fromOffset(0, 10), 18)
	text(
		menu,
		"Optional. Ratings and comments help us fix and improve the game.",
		UDim2.new(1, -40, 0, 34),
		UDim2.fromOffset(20, 38),
		13
	).TextColor3 =
		DIM

	local rating = 0
	local ratingButtons: { TextButton } = {}
	for i = 1, 5 do
		local b = button(
			menu,
			tostring(i),
			UDim2.fromOffset(52, 36),
			UDim2.fromOffset(105 + (i - 1) * 60, 78)
		)
		b.Activated:Connect(function()
			rating = i
			for j, other in ratingButtons do
				other.BackgroundColor3 = if j <= rating then ACCENT else Color3.fromRGB(45, 42, 40)
			end
		end)
		ratingButtons[i] = b
	end

	local chosen: { [string]: boolean } = {}
	for i, tag in TAGS do
		local column = (i - 1) % 2
		local row = (i - 1) // 2
		local b = button(
			menu,
			tag,
			UDim2.fromOffset(225, 28),
			UDim2.fromOffset(20 + column * 235, 126 + row * 34)
		)
		b.TextSize = 13
		b.Activated:Connect(function()
			chosen[tag] = not chosen[tag]
			b.BackgroundColor3 = if chosen[tag]
				then Color3.fromRGB(90, 60, 40)
				else Color3.fromRGB(45, 42, 40)
		end)
	end

	local box = Instance.new("TextBox")
	box.Size = UDim2.fromOffset(460, 64)
	box.Position = UDim2.fromOffset(20, 266)
	box.BackgroundColor3 = Color3.fromRGB(30, 28, 27)
	box.BorderSizePixel = 0
	box.Font = FONT
	box.TextSize = 14
	box.TextColor3 = TEXT
	box.PlaceholderText = "Anything else? (optional)"
	box.PlaceholderColor3 = DIM
	box.Text = ""
	box.TextWrapped = true
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.ClearTextOnFocus = false
	box.Parent = menu
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if #box.Text > 300 then
			box.Text = string.sub(box.Text, 1, 300)
		end
	end)

	local status = text(menu, "", UDim2.fromOffset(300, 30), UDim2.fromOffset(20, 350), 13)
	status.TextXAlignment = Enum.TextXAlignment.Left
	local send = button(menu, "Send", UDim2.fromOffset(70, 32), UDim2.fromOffset(330, 348))
	local close = button(menu, "Close", UDim2.fromOffset(70, 32), UDim2.fromOffset(410, 348))
	close.Modal = true -- frees the mouse while the menu is open, even in first person

	feedbackButton.Activated:Connect(function()
		menu.Visible = true
		status.Text = ""
	end)
	close.Activated:Connect(function()
		menu.Visible = false
	end)
	send.Activated:Connect(function()
		if rating == 0 then
			status.Text = "Pick a rating from 1 to 5."
			return
		end
		local tags: { string } = {}
		for _, tag in TAGS do
			if chosen[tag] then
				table.insert(tags, tag)
			end
		end
		status.Text = "Sending..."
		Remotes.SendFeedback:FireServer({ rating = rating, tags = tags, text = box.Text })
	end)
	Remotes.FeedbackReceived.OnClientEvent:Connect(function(ok: boolean, message: string)
		status.Text = message
		status.TextColor3 = if ok then GOOD else TEXT
		if ok then
			box.Text = ""
			task.delay(1.5, function()
				menu.Visible = false
			end)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or input.KeyCode ~= Enum.KeyCode.G then
			return
		end
		if state:GetAttribute("Phase") == "Lobby" then
			toggleReady()
		end
	end)

	-- Coming back after being caught (shown while you're an echo, once per round).
	local revive =
		frame(gui, UDim2.fromOffset(440, 96), UDim2.new(0.5, 0, 1, -230), Vector2.new(0.5, 0))
	revive.Visible = false
	local reviveTitle = text(revive, "", UDim2.new(1, -20, 0, 26), UDim2.fromOffset(10, 6), 14)
	local byLevel =
		button(revive, "Lose a level (B)", UDim2.fromOffset(160, 40), UDim2.fromOffset(10, 44))
	local byToken = button(revive, "", UDim2.fromOffset(120, 40), UDim2.fromOffset(176, 44))
	local byRobux = button(revive, "Robux", UDim2.fromOffset(124, 40), UDim2.fromOffset(306, 44))
	byRobux.TextColor3 = DIM
	byLevel.Activated:Connect(function()
		Remotes.Revive:FireServer("level")
	end)
	byToken.Activated:Connect(function()
		Remotes.Revive:FireServer("token")
	end)
	byRobux.Activated:Connect(function()
		if Config.REVIVE.PRODUCT_ID ~= 0 then
			MarketplaceService:PromptProductPurchase(player, Config.REVIVE.PRODUCT_ID)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if
			not processed
			and input.KeyCode == Enum.KeyCode.B
			and player:GetAttribute("CanRevive")
		then
			Remotes.Revive:FireServer("level")
		end
	end)

	-- Flashlight look, chosen in the lobby from those unlocked on the reward track.
	local skinButton = button(gui, "", UDim2.fromOffset(240, 30), UDim2.new(1, -260, 0, 62))
	skinButton.TextSize = 13
	local nextReward = text(gui, "", UDim2.fromOffset(320, 18), UDim2.new(1, -340, 0, 36), 13)
	nextReward.TextXAlignment = Enum.TextXAlignment.Right
	nextReward.TextColor3 = DIM
	local function unlockedSkins(): { string }
		local peak = player:GetAttribute("Level") or 1
		local list: { string } = {}
		for _, id in Config.FLASHLIGHT_SKIN_ORDER do
			local open = id == "warm"
			for _, reward in Config.TRACK do
				if reward.kind == "skin" and reward.id == id and peak >= reward.level then
					open = true
				end
			end
			if open then
				table.insert(list, id)
			end
		end
		return list
	end
	skinButton.Activated:Connect(function()
		local list = unlockedSkins()
		local index = table.find(list, player:GetAttribute("FlashlightSkin") or "warm") or 1
		Remotes.SetSkin:FireServer(list[index % #list + 1])
	end)

	RunService.RenderStepped:Connect(function()
		local phase = state:GetAttribute("Phase")
		local character = player.Character
		local inRound = character ~= nil and character:GetAttribute("InRound") == true
		local outside = not inRound

		-- Level and coins, outside the action only.
		local level = player:GetAttribute("Level")
		progress.Visible = outside and level ~= nil
		if level then
			progress.Text = string.format(
				"Level %d   ·   %d coins%s",
				level,
				player:GetAttribute("Coins") or 0,
				if player:GetAttribute("ProgressSaved") == false then "   (not saved)" else ""
			)
		end

		-- Reward track: what's next, and the flashlight look.
		local peak = player:GetAttribute("Level") or 1
		local upcoming = nil
		for _, reward in Config.TRACK do
			if reward.level > peak and (not upcoming or reward.level < upcoming.level) then
				upcoming = reward
			end
		end
		nextReward.Visible = outside and level ~= nil
		nextReward.Text = if upcoming
			then string.format("Next reward at level %d: %s", upcoming.level, upcoming.name)
			else "Reward track complete"
		local skin = Config.FLASHLIGHT_SKINS[player:GetAttribute("FlashlightSkin") or "warm"]
		skinButton.Visible = phase == "Lobby" and outside and level ~= nil
		skinButton.Text = string.format("Flashlight: %s  >", if skin then skin.name else "Warm")
		skinButton.Modal = skinButton.Visible

		-- Revive, while you're an echo.
		local canRevive = player:GetAttribute("CanRevive") == true
		local waiting = player:GetAttribute("RevivePending") == true
		revive.Visible = canRevive
		reviveTitle.Text = if waiting
			then "Waiting for a teammate to put your headset back on..."
			else "Ask your team to bring you back? (once per round)"
		byLevel.Visible = not waiting
		byRobux.Visible = not waiting and Config.REVIVE.PRODUCT_ID ~= 0
		if canRevive and not waiting then
			local tokens = player:GetAttribute("ReviveTokens") or 0
			byLevel.AutoButtonColor = (level or 1) >= 2
			byLevel.TextColor3 = if (level or 1) >= 2 then TEXT else DIM
			byToken.Visible = tokens > 0
			byToken.Text = string.format("Use bought (%d)", tokens)
			byLevel.Modal = true
		else
			byToken.Visible = false
			byLevel.Modal = false
		end

		-- The lobby bar.
		local inLobby = phase == "Lobby" and outside
		bar.Visible = inLobby or (phase == "Results" and Config.FEATURES.FEEDBACK)
		readyButton.Visible = inLobby
		readyCount.Visible = inLobby
		readyButton.Modal = bar.Visible -- a free mouse to click with
		feedbackButton.Modal = bar.Visible and not inLobby
		if inLobby then
			local ready = player:GetAttribute("Ready") == true
			readyButton.Text = if ready then "Ready ✓ (G)" else "Ready up (G)"
			readyButton.BackgroundColor3 = if ready
				then Color3.fromRGB(50, 90, 60)
				else Color3.fromRGB(45, 42, 40)
			readyCount.Text = string.format(
				"%d/%d ready",
				state:GetAttribute("Ready") or 0,
				#Players:GetPlayers()
			)
		end

		if
			results.Visible
			and (phase ~= "Results" or os.clock() - resultsShown > Config.RESULTS_TIME)
		then
			results.Visible = false
		end
		if inRound and menu.Visible then
			menu.Visible = false -- a round started: back to the game
		end
	end)
end

return LobbyUi
