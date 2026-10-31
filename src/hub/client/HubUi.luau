--!strict
-- The hub's lobby browser: your lobby (with Start for the host), the lobbies you can see (this
-- server's, and friends' in other hub servers), and a panel to create one.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local FONT = Enum.Font.RobotoMono
local TEXT = Color3.fromRGB(225, 220, 210)
local DIM = Color3.fromRGB(130, 125, 118)
local PANEL = Color3.fromRGB(18, 17, 16)
local BUTTON = Color3.fromRGB(45, 42, 40)
local ACCENT = Color3.fromRGB(200, 70, 55)

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
	panel.Position = UDim2.new(1, -460, 0.5, 0)
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.BackgroundColor3 = PANEL
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Parent = gui
	rounded(panel, 6)

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
		"Make a lobby, or join one. Friends' lobbies in other servers show too.",
		UDim2.new(1, -32, 0, 30),
		UDim2.fromOffset(16, 40),
		12
	).TextColor3 =
		DIM

	-- Create
	local mapIndex = 1
	local size = Config.LOBBY.MAX_PLAYERS
	local friendsOnly = false
	local mapButton = button(panel, "", UDim2.fromOffset(200, 30), UDim2.fromOffset(16, 78))
	local sizeButton = button(panel, "", UDim2.fromOffset(90, 30), UDim2.fromOffset(222, 78))
	local privacyButton = button(panel, "", UDim2.fromOffset(110, 30), UDim2.fromOffset(318, 78))
	local create =
		button(panel, "Create lobby", UDim2.fromOffset(412, 32), UDim2.fromOffset(16, 114))
	create.BackgroundColor3 = Color3.fromRGB(80, 40, 34)
	local function refreshCreate()
		mapButton.Text = "Map: " .. Config.MAPS[mapIndex].name
		sizeButton.Text = string.format("%d players", size)
		privacyButton.Text = if friendsOnly then "Friends only" else "Public"
	end
	refreshCreate()
	mapButton.Activated:Connect(function()
		mapIndex = mapIndex % #Config.MAPS + 1
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
		Remotes.CreateLobby:FireServer({
			map = Config.MAPS[mapIndex].id,
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
					"Your lobby: %s  %d/%d",
					tostring(entry.map),
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
					"%s's lobby%s\n%s  %d/%d%s",
					tostring(entry.host),
					where,
					tostring(entry.map),
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
			joinButton.Activated:Connect(function()
				Remotes.JoinLobby:FireServer(entry.id)
			end)
		end
	end)
end

return HubUi
