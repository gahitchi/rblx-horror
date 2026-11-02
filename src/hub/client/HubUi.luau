--!strict
-- The hub's lobby browser: your lobby (with Start for the host), the lobbies you can see (this
-- server's, and friends' in other hub servers), and a panel to create one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Chapters = require(Shared:WaitForChild("Chapters"))
local StoryTapes = require(Shared:WaitForChild("StoryTapes"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local FONT = Enum.Font.RobotoMono
local TEXT = Color3.fromRGB(225, 220, 210)
local DIM = Color3.fromRGB(130, 125, 118)
local PANEL = Color3.fromRGB(18, 17, 16)
local BUTTON = Color3.fromRGB(45, 42, 40)
local ACCENT = Color3.fromRGB(232, 162, 74)

local HubUi = {}

local function rounded(instance: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function label(
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
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = content
	l.Parent = parent
	return l
end

local function button(parent: Instance, content: string, size: UDim2, position: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = BUTTON
	b.BorderSizePixel = 0
	b.Font = FONT
	b.TextSize = 14
	b.TextColor3 = TEXT
	b.Text = content
	b.Parent = parent
	rounded(b, 4)
	return b
end

function HubUi.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "HubUi"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromOffset(440, 470)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.BackgroundColor3 = PANEL
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	rounded(panel, 6)

	-- The handler's tape deck, in his van: every story tape this player has recovered.
	local deck = Instance.new("Frame")
	deck.Size = UDim2.fromOffset(460, 470)
	deck.Position = UDim2.fromScale(0.5, 0.5)
	deck.AnchorPoint = Vector2.new(0.5, 0.5)
	deck.BackgroundColor3 = PANEL
	deck.BackgroundTransparency = 0.1
	deck.BorderSizePixel = 0
	deck.Visible = false
	deck.Parent = gui
	rounded(deck, 6)
	local deckTitle =
		label(deck, "THE VAN: TAPE DECK", UDim2.new(1, -120, 0, 30), UDim2.fromOffset(16, 10), 18)
	deckTitle.TextColor3 = ACCENT
	local deckClose = button(deck, "Close", UDim2.fromOffset(90, 28), UDim2.new(1, -106, 0, 10))
	local tapeList = Instance.new("ScrollingFrame")
	tapeList.Size = UDim2.new(1, -32, 0, 130)
	tapeList.Position = UDim2.fromOffset(16, 48)
	tapeList.BackgroundTransparency = 1
	tapeList.BorderSizePixel = 0
	tapeList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tapeList.CanvasSize = UDim2.new()
	tapeList.ScrollBarThickness = 6
	tapeList.Parent = deck
	local tapeListLayout = Instance.new("UIListLayout")
	tapeListLayout.Padding = UDim.new(0, 4)
	tapeListLayout.Parent = tapeList
	local tapeText = Instance.new("ScrollingFrame")
	tapeText.Size = UDim2.new(1, -32, 1, -200)
	tapeText.Position = UDim2.fromOffset(16, 188)
	tapeText.BackgroundTransparency = 1
	tapeText.BorderSizePixel = 0
	tapeText.AutomaticCanvasSize = Enum.AutomaticSize.Y
	tapeText.CanvasSize = UDim2.new()
	tapeText.ScrollBarThickness = 6
	tapeText.Parent = deck
	local tapeBody = label(tapeText, "", UDim2.new(1, -12, 0, 0), UDim2.new(), 13)
	tapeBody.AutomaticSize = Enum.AutomaticSize.Y
	tapeBody.TextWrapped = true
	tapeBody.TextYAlignment = Enum.TextYAlignment.Top

	local function refreshDeck()
		for _, child in tapeList:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local tapes = StoryTapes.recovered(
			Chapters.clearedBy(player),
			Chapters.parse(player:GetAttribute("TapesDelivered"))
		)
		if #tapes == 0 then
			tapeBody.Text =
				"No tapes yet. Clear a chapter (carry the cassette out) or push old tapes through the studio's mail slot."
			return
		end
		tapeBody.Text = "Pick a tape."
		for _, tape in tapes do
			local entry = button(tapeList, tape.title, UDim2.new(1, -10, 0, 28), UDim2.new())
			entry.TextXAlignment = Enum.TextXAlignment.Left
			entry.TextSize = 13
			entry.Activated:Connect(function()
				tapeBody.Text = tape.title .. "\n\n" .. tape.body
			end)
		end
	end
	deckClose.Activated:Connect(function()
		deck.Visible = false
	end)

	-- The other two diegetic screens: equipment at the van's crate and town
	-- progress through the lookout. Their backing data already belongs to
	-- LobbyService / Progress_v1; no extra remotes or currency systems.
	local kitPanel = Instance.new("Frame")
	kitPanel.Name = "EquipmentPanel"
	kitPanel.Size = UDim2.fromOffset(440, 390)
	kitPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	kitPanel.Position = UDim2.fromScale(0.5, 0.5)
	kitPanel.BackgroundColor3 = PANEL
	kitPanel.BackgroundTransparency = 0.08
	kitPanel.BorderSizePixel = 0
	kitPanel.Visible = false
	kitPanel.Parent = gui
	rounded(kitPanel, 6)
	local kitClose = button(kitPanel, "Close", UDim2.fromOffset(88, 28), UDim2.new(1, -104, 0, 12))
	label(kitPanel, "THE HANDLER / CREW KIT", UDim2.fromOffset(300, 28),
		UDim2.fromOffset(18, 12), 18).TextColor3 = ACCENT
	local kitStatus = label(kitPanel, "", UDim2.fromOffset(408, 44), UDim2.fromOffset(18, 48), 13)
	kitStatus.TextWrapped = true
	local skinList = Instance.new("ScrollingFrame")
	skinList.Position = UDim2.fromOffset(16, 103)
	skinList.Size = UDim2.fromOffset(408, 265)
	skinList.BackgroundTransparency = 1
	skinList.ScrollBarThickness = 4
	skinList.BorderSizePixel = 0
	skinList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	skinList.CanvasSize = UDim2.new()
	skinList.Parent = kitPanel
	local kitLayout = Instance.new("UIListLayout")
	kitLayout.Padding = UDim.new(0, 5)
	kitLayout.Parent = skinList
	local function refreshKit()
		local level = player:GetAttribute("Level")
		local lv = if type(level) == "number" then level else 1
		local current = player:GetAttribute("FlashlightSkin")
		kitStatus.Text = "LEVEL " .. tostring(lv)
			.. "  ·  Flashlight colour only. All styles are earned for free."
		for _, child in skinList:GetChildren() do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for _, id in Config.FLASHLIGHT_SKIN_ORDER do
			local info = Config.FLASHLIGHT_SKINS[id]
			local required = 1
			if id ~= "warm" then
				for _, reward in Config.TRACK do
					if reward.kind == "skin" and reward.id == id then
						required = reward.level
						break
					end
				end
			end
			local unlocked = lv >= required
			local suffix = if not unlocked then "  /  LEVEL " .. tostring(required)
				elseif current == id then "  /  EQUIPPED" else "  /  EQUIP"
			local entry = button(skinList, info.name .. suffix, UDim2.new(1, -8, 0, 34), UDim2.new())
			entry.TextXAlignment = Enum.TextXAlignment.Left
			entry.TextSize = 13
			entry.TextColor3 = if unlocked then TEXT else DIM
			if unlocked then
				entry.Activated:Connect(function()
					Remotes.SetSkin:FireServer(id)
				end)
			end
		end
	end
	kitClose.Activated:Connect(function()
		kitPanel.Visible = false
	end)
	player:GetAttributeChangedSignal("Level"):Connect(refreshKit)
	player:GetAttributeChangedSignal("FlashlightSkin"):Connect(refreshKit)

	local lookoutPanel = Instance.new("Frame")
	lookoutPanel.Name = "TelescopePanel"
	lookoutPanel.Size = UDim2.fromOffset(440, 310)
	lookoutPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	lookoutPanel.Position = UDim2.fromScale(0.5, 0.5)
	lookoutPanel.BackgroundColor3 = PANEL
	lookoutPanel.BackgroundTransparency = 0.08
	lookoutPanel.BorderSizePixel = 0
	lookoutPanel.Visible = false
	lookoutPanel.Parent = gui
	rounded(lookoutPanel, 6)
	label(lookoutPanel, "LOOKOUT / WRENMOUTH", UDim2.fromOffset(310, 30),
		UDim2.fromOffset(18, 12), 18).TextColor3 = ACCENT
	local lookoutClose = button(lookoutPanel, "Close", UDim2.fromOffset(88, 28),
		UDim2.new(1, -104, 0, 12))
	local townText = label(lookoutPanel, "", UDim2.fromOffset(402, 240),
		UDim2.fromOffset(18, 56), 15)
	townText.TextWrapped = true
	townText.TextYAlignment = Enum.TextYAlignment.Top
	local function refreshLookout()
		local cleared = Chapters.clearedBy(player)
		local function yes(id: string): string
			return if table.find(cleared, id) then "a warm window" else "dark"
		end
		townText.Text = "The town lies beneath the fog. The lighthouse never stops.\n\n"
			.. "RECORDING HOUSE   " .. yes("studio1") .. "\n"
			.. "LOWER FLOORS     " .. yes("studio2") .. "\n"
			.. "ENGINEER'S FLAT  " .. yes("studio3") .. "\n"
			.. "RADIO STATION    " .. yes("radio1") .. "\n"
			.. "LISTENING POST   " .. yes("sonar1") .. "\n\n"
			.. "The mast will blink only when the third chapter is cleared."
	end
	player:GetAttributeChangedSignal("ChaptersCleared"):Connect(refreshLookout)
	lookoutClose.Activated:Connect(function()
		lookoutPanel.Visible = false
	end)

	-- On phones fit the panels instead of covering the entire third-person view.
	for _, frame in { panel, deck, kitPanel, lookoutPanel } do
		local fit = Instance.new("UIScale")
		fit.Parent = frame
		local camera = Workspace.CurrentCamera
		local function resize()
			if camera then
				local view = camera.ViewportSize
				fit.Scale = math.min(1, (view.X - 20) / 470, (view.Y - 20) / 490)
			end
		end
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
		end
		resize()
	end

	local function open(which: string)
		panel.Visible = which == "crew"
		deck.Visible = which == "deck"
		kitPanel.Visible = which == "kit"
		lookoutPanel.Visible = which == "lookout"
		if deck.Visible then
			refreshDeck()
		elseif kitPanel.Visible then
			refreshKit()
		elseif lookoutPanel.Visible then
			refreshLookout()
		end
	end
	local crewButton = button(gui, "CREWS  [B]", UDim2.fromOffset(150, 38),
		UDim2.new(1, -164, 0, 12))
	crewButton.BackgroundColor3 = Color3.fromRGB(65, 55, 42)
	crewButton.Activated:Connect(function()
		open(if panel.Visible then "" else "crew")
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.B then
			open(if panel.Visible then "" else "crew")
		end
	end)

	-- Prompt instances are client-local so browsing and viewing progress never
	-- requires a new server RemoteEvent, and Studio's fallback hub still works.
	task.spawn(function()
		local hub = Workspace:WaitForChild("Hub", 20)
		if not hub then
			return
		end
		local markers = hub:FindFirstChild("Markers")
		if not markers then
			return
		end
		for _, action in {
			{ key = "CrewBoard", verb = "View crews", panel = "crew" },
			{ key = "VanDoors", verb = "Play recovered tapes", panel = "deck" },
			{ key = "KitCrate", verb = "Choose equipment", panel = "kit" },
			{ key = "Telescope", verb = "Look over Wrenmouth", panel = "lookout" },
		} do
			local marker = markers:FindFirstChild(action.key)
			if marker and marker:IsA("BasePart") then
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = action.verb
				prompt.ObjectText = action.key
				prompt.MaxActivationDistance = 10
				prompt.RequiresLineOfSight = false
				prompt.HoldDuration = 0.25
				prompt.Parent = marker
				prompt.Triggered:Connect(function()
					open(action.panel)
				end)
			end
		end
	end)

	local title = label(
		panel,
		string.upper(Config.GAME_NAME),
		UDim2.new(1, -20, 0, 30),
		UDim2.fromOffset(16, 10),
		20
	)
	title.TextColor3 = ACCENT
	label(
		panel,
		"Make a crew, join one, or quick join. Friends' crews in other servers show too.",
		UDim2.new(1, -32, 0, 30),
		UDim2.fromOffset(16, 40),
		12
	).TextColor3 =
		DIM

	-- Create (the chapter cycles through the ones you've unlocked: the story is played in order)
	local chapterIndex = 1
	local size = Config.LOBBY.MAX_PLAYERS
	local friendsOnly = false
	local mapButton = button(panel, "", UDim2.fromOffset(200, 30), UDim2.fromOffset(16, 78))
	local function unlocked(): { Chapters.Entry }
		return Chapters.unlockedList(Chapters.clearedBy(player))
	end
	local sizeButton = button(panel, "", UDim2.fromOffset(90, 30), UDim2.fromOffset(222, 78))
	local privacyButton = button(panel, "", UDim2.fromOffset(110, 30), UDim2.fromOffset(318, 78))
	local create =
		button(panel, "Create crew", UDim2.fromOffset(200, 32), UDim2.fromOffset(16, 114))
	create.BackgroundColor3 = Color3.fromRGB(80, 40, 34)
	local quick = button(panel, "Quick join", UDim2.fromOffset(200, 32), UDim2.fromOffset(228, 114))
	quick.BackgroundColor3 = Color3.fromRGB(40, 60, 46)
	quick.Activated:Connect(function()
		Remotes.QuickJoin:FireServer()
	end)
	local deckButton =
		button(panel, "Tape deck", UDim2.fromOffset(110, 26), UDim2.new(1, -126, 0, 12))
	deckButton.TextSize = 13
	deckButton.Activated:Connect(function()
		open(if deck.Visible then "" else "deck")
	end)
	local function refreshCreate()
		local list = unlocked()
		if chapterIndex > #list then
			chapterIndex = #list
		end
		local entry = list[math.max(chapterIndex, 1)]
		mapButton.Text = if entry then "Chapter " .. Chapters.name(entry.id) else "Chapter: ..."
		sizeButton.Text = string.format("%d players", size)
		privacyButton.Text = if friendsOnly then "Friends only" else "Public"
	end
	refreshCreate()
	mapButton.Activated:Connect(function()
		chapterIndex = chapterIndex % math.max(#unlocked(), 1) + 1
		refreshCreate()
	end)
	player:GetAttributeChangedSignal("ChaptersCleared"):Connect(function()
		-- Start on the next unplayed chapter.
		local list = unlocked()
		local nextId = Chapters.nextFor(Chapters.clearedBy(player))
		for index, entry in list do
			if entry.id == nextId then
				chapterIndex = index
			end
		end
		refreshCreate()
	end)
	sizeButton.Activated:Connect(function()
		size = size % Config.LOBBY.MAX_PLAYERS + 1
		refreshCreate()
	end)
	privacyButton.Activated:Connect(function()
		friendsOnly = not friendsOnly
		refreshCreate()
	end)
	create.Activated:Connect(function()
		local entry = unlocked()[math.max(chapterIndex, 1)]
		Remotes.CreateLobby:FireServer({
			chapter = if entry then entry.id else nil,
			max = size,
			friendsOnly = friendsOnly,
		})
	end)

	-- Your lobby
	local mineBox = Instance.new("Frame")
	mineBox.Size = UDim2.fromOffset(412, 44)
	mineBox.Position = UDim2.fromOffset(16, 156)
	mineBox.BackgroundColor3 = Color3.fromRGB(40, 30, 28)
	mineBox.BorderSizePixel = 0
	mineBox.Parent = panel
	rounded(mineBox, 4)
	local mineText = label(mineBox, "", UDim2.fromOffset(230, 44), UDim2.fromOffset(10, 0), 13)
	local startButton = button(mineBox, "Start", UDim2.fromOffset(70, 30), UDim2.fromOffset(250, 7))
	startButton.BackgroundColor3 = Color3.fromRGB(50, 90, 60)
	local leaveButton = button(mineBox, "Leave", UDim2.fromOffset(74, 30), UDim2.fromOffset(328, 7))
	startButton.Activated:Connect(function()
		Remotes.StartLobby:FireServer()
	end)
	leaveButton.Activated:Connect(function()
		Remotes.LeaveLobby:FireServer()
	end)

	-- The list
	label(panel, "Lobbies", UDim2.fromOffset(200, 20), UDim2.fromOffset(16, 208), 14).TextColor3 =
		DIM
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromOffset(412, 230)
	scroll.Position = UDim2.fromOffset(16, 230)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = scroll

	-- Toasts from the server (errors, "you're the host now"...)
	local toast = label(gui, "", UDim2.fromOffset(600, 24), UDim2.new(0.5, -300, 0, 20), 15)
	toast.TextXAlignment = Enum.TextXAlignment.Center
	local toastId = 0
	Remotes.Notify.OnClientEvent:Connect(function(message: string)
		toastId += 1
		local id = toastId
		toast.Text = message
		task.delay(4, function()
			if toastId == id then
				toast.Text = ""
			end
		end)
	end)

	Remotes.LobbyList.OnClientEvent:Connect(function(list: { any }, mine: string?)
		for _, child in scroll:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		mineBox.Visible = mine ~= nil
		for _, entry in list do
			if type(entry) ~= "table" then
				continue
			end
			if entry.mine then
				mineText.Text = string.format(
					"Your crew: %s  %d/%d",
					tostring(entry.chapter),
					entry.count,
					entry.max
				)
				startButton.Visible = entry.isHost == true
				continue
			end
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 40)
			row.BackgroundColor3 = Color3.fromRGB(32, 30, 29)
			row.BorderSizePixel = 0
			row.Parent = scroll
			rounded(row, 4)
			local where = if entry.here then "" else "  (friend, other server)"
			local lock = if entry.friendsOnly then "  · friends" else ""
			local info = label(
				row,
				string.format(
					"%s's crew%s\n%s  %d/%d%s",
					tostring(entry.host),
					where,
					tostring(entry.chapter),
					entry.count,
					entry.max,
					lock
				),
				UDim2.fromOffset(300, 40),
				UDim2.fromOffset(10, 0),
				12
			)
			info.TextWrapped = true
			local joinButton =
				button(row, "Join", UDim2.fromOffset(80, 28), UDim2.fromOffset(316, 6))
			if entry.locked then
				-- Strict lobbies: the chapter before it has to be cleared first.
				joinButton.Text = "Locked"
				joinButton.TextColor3 = DIM
				joinButton.AutoButtonColor = false
			end
			joinButton.Activated:Connect(function()
				Remotes.JoinLobby:FireServer(entry.id)
			end)
		end
	end)
end

return HubUi
