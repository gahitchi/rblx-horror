--!strict
-- Chapter 1 field notebook: a personal, read-only index of discovered papers
-- and text already received over the radio. No new RemoteEvents or puzzle hints.
-- Notebook data is session-local, cleared at the start of each round, and
-- unavailable outside active play. This is not an ambient-sound transcription.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local ChapterUi = require(script.Parent.ChapterUi)

local player = Players.LocalPlayer
local COLOR = {
	paper = Color3.fromRGB(205, 191, 164),
	ink = Color3.fromRGB(226, 216, 198),
	muted = Color3.fromRGB(158, 150, 134),
	amber = Color3.fromRGB(214, 167, 99),
	panel = Color3.fromRGB(27, 27, 26),
	rule = Color3.fromRGB(67, 61, 55),
	tab = Color3.fromRGB(51, 47, 43),
}
local FONT = Enum.Font.RobotoMono
local MAX_RADIO = 16
local MAX_PAPERS = 12

type Paper = { title: string, body: string }
type RadioEntry = { sender: string, body: string }

local NotebookUi = {}

local papers: { Paper } = {}
local radio: { RadioEntry } = {}
local selectedTab = "papers"
local openPanel = false

local function frame(parent: Instance, name: string, size: UDim2,
	position: UDim2, color: Color3): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function text(parent: Instance, value: string, size: UDim2,
	position: UDim2, fontSize: number, color: Color3): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = position
	l.BackgroundTransparency = 1
	l.Text = value
	l.TextWrapped = true
	l.TextColor3 = color
	l.Font = FONT
	l.TextSize = fontSize
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Parent = parent
	return l
end

local function button(parent: Instance, value: string, size: UDim2,
	position: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = COLOR.tab
	b.BorderSizePixel = 0
	b.Font = FONT
	b.TextSize = 14
	b.TextColor3 = COLOR.ink
	b.Text = value
	b.AutoButtonColor = true
	b.Parent = parent
	return b
end

local function isActive(state: Instance): boolean
	local character = player.Character
	return state:GetAttribute("Phase") == "Playing"
		and character ~= nil and character:GetAttribute("InRound") == true
end

function NotebookUi.start()
	local state = ReplicatedStorage:WaitForChild("RoundState")
	local gui = Instance.new("ScreenGui")
	gui.Name = "DeadAirFieldNotebook"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = 3
	gui.Parent = player:WaitForChild("PlayerGui")

	-- A small always-available notebook affordance while exploring.
	local toggle = button(gui, "NOTES [J]", UDim2.fromOffset(122, 34),
		UDim2.new(1, -136, 0, 112))
	toggle.Name = "NotebookToggle"
	toggle.Visible = false
	toggle.BackgroundColor3 = COLOR.panel
	toggle.TextColor3 = COLOR.amber

	local panel = frame(gui, "NotebookPanel", UDim2.new(1, -24, 1, -100),
		UDim2.fromScale(0.5, 0.5), COLOR.panel)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Visible = false
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(560, 600)
	cap.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = COLOR.rule
	stroke.Thickness = 2
	stroke.Parent = panel

	local header = text(panel, "FIELD NOTEBOOK", UDim2.new(1, -124, 0, 32),
		UDim2.fromOffset(16, 12), 18, COLOR.amber)
	header.TextWrapped = false
	local close = button(panel, "Close", UDim2.fromOffset(90, 32),
		UDim2.new(1, -106, 0, 12))

	local mission = text(panel, "", UDim2.new(1, -32, 0, 58),
		UDim2.fromOffset(16, 52), 14, COLOR.paper)
	mission.TextYAlignment = Enum.TextYAlignment.Top

	local papersTab = button(panel, "FOUND PAPERS", UDim2.new(0.5, -20, 0, 35),
		UDim2.fromOffset(16, 122))
	local radioTab = button(panel, "RADIO LOG", UDim2.new(0.5, -20, 0, 35),
		UDim2.new(0.5, 4, 0, 122))
	local list = Instance.new("ScrollingFrame")
	list.Name = "DiscoveredEntries"
	list.Size = UDim2.new(1, -32, 1, -226)
	list.Position = UDim2.fromOffset(16, 169)
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.ScrollBarThickness = 5
	list.ScrollingDirection = Enum.ScrollingDirection.Y
	list.BorderSizePixel = 0
	list.BackgroundTransparency = 1
	list.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 12)
	layout.Parent = list
	local footer = text(panel,
		"Only clues you've encountered this round. No location tracking or puzzle solutions added.",
		UDim2.new(1, -32, 0, 44), UDim2.new(0, 16, 1, -53), 11, COLOR.muted)
	footer.TextYAlignment = Enum.TextYAlignment.Bottom

	local function clearEntries()
		for _, child in list:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
	end

	local function appendEntry(title: string, body: string, order: number)
		local entry = text(list, title .. "\n\n" .. body, UDim2.new(1, -12, 0, 0),
			UDim2.new(), 14, COLOR.ink)
		entry.Name = "Entry"
		entry.TextYAlignment = Enum.TextYAlignment.Top
		entry.AutomaticSize = Enum.AutomaticSize.Y
		entry.LayoutOrder = order
	end

	local function redraw()
		papersTab.BackgroundColor3 = if selectedTab == "papers" then COLOR.rule else COLOR.tab
		radioTab.BackgroundColor3 = if selectedTab == "radio" then COLOR.rule else COLOR.tab
		local objective = state:GetAttribute("ObjectiveText")
		mission.Text = "CURRENT TASK\n" ..
			(if type(objective) == "string" and objective ~= ""
				then objective else "Follow the handler's instructions.")
		clearEntries()
		list.CanvasPosition = Vector2.zero
		if selectedTab == "papers" then
			if #papers == 0 then
				appendEntry("NO PAPERS FOUND",
					"Read the booking diary, session log, card index or memorial programme. Their text will be filed here after you examine them.", 1)
			else
				for index, paper in papers do
					appendEntry(string.upper(paper.title), paper.body, index)
				end
			end
		elseif #radio == 0 then
			appendEntry("NO MESSAGES RECEIVED",
				"Written radio messages appear here after they reach you. Mechanical noises and footsteps are not transcribed.", 1)
		else
			for index, message in radio do
				appendEntry(message.sender, message.body, index)
			end
		end
	end

	local function setOpen(visible: boolean)
		if visible and (not isActive(state) or ChapterUi.isOpen()) then
			return
		end
		openPanel = visible
		panel.Visible = visible
		-- In first person, a Modal close control releases mouse lock while
		-- the notebook is up; keyboard J and touch remain usable.
		close.Modal = visible
		if visible then
			redraw()
		end
	end

	toggle.Activated:Connect(function()
		setOpen(not openPanel)
	end)
	close.Activated:Connect(function()
		setOpen(false)
	end)
	papersTab.Activated:Connect(function()
		selectedTab = "papers"
		redraw()
	end)
	radioTab.Activated:Connect(function()
		selectedTab = "radio"
		redraw()
	end)
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if not processed and input.KeyCode == Enum.KeyCode.J then
			setOpen(not openPanel)
		end
	end)

	-- Record only content the *server already displayed to this player*.
	Remotes.Document.OnClientEvent:Connect(function(title: string, body: string)
		if not isActive(state) or type(title) ~= "string" or type(body) ~= "string" then
			return
		end
		local existing: number? = nil
		for i, paper in papers do
			if paper.title == title then
				existing = i
				break
			end
		end
		if existing then
			papers[existing].body = body
		else
			table.insert(papers, { title = title, body = body })
			if #papers > MAX_PAPERS then
				table.remove(papers, 1)
			end
		end
		setOpen(false) -- the discovered paper's own reading panel takes priority
	end)
	Remotes.Radio.OnClientEvent:Connect(function(sender: string, room: string, body: string)
		if not isActive(state) or type(sender) ~= "string" or type(body) ~= "string" then
			return
		end
		local heading = if sender == "1987 broadcast" then "1987 BROADCAST"
			elseif type(room) == "string" and room ~= "" then sender .. " / " .. room
			else sender
		table.insert(radio, { sender = heading, body = body })
		if #radio > MAX_RADIO then
			table.remove(radio, 1)
		end
	end)
	Remotes.Puzzle.OnClientEvent:Connect(function(kind: string)
		if kind ~= "" then
			setOpen(false)
		end
	end)

	-- On the *next* round, old clues disappear: a fresh set of reel numbers,
	-- safe details and patch inputs must always be discovered through gameplay.
	state:GetAttributeChangedSignal("Phase"):Connect(function()
		if state:GetAttribute("Phase") == "Playing" then
			table.clear(papers)
			table.clear(radio)
			selectedTab = "papers"
		end
		setOpen(false)
	end)
	state:GetAttributeChangedSignal("ObjectiveText"):Connect(function()
		if openPanel then
			redraw()
		end
	end)

	-- Kept at 4 Hz rather than adding work to every rendering frame.
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt: number)
		accumulator += dt
		if accumulator < 0.25 then
			return
		end
		accumulator = 0
		local active = isActive(state)
		toggle.Visible = active and not ChapterUi.isOpen() and not openPanel
		if not active then
			setOpen(false)
		end
	end)
end

return NotebookUi
