--!strict
-- The chapter's screens: documents to read (the booking diary, the session log, the card index)
-- and the hands-on puzzles (rethreading the tape machine, the safe, the patch bay, riding the
-- faders). The server opens and closes puzzles and checks every answer; this only draws them and
-- sends what the player did. Everything works with mouse, touch and gamepad (it's all buttons).

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local FONT = Enum.Font.RobotoMono
local TEXT = Color3.fromRGB(225, 220, 210)
local DIM = Color3.fromRGB(130, 125, 118)
local PANEL = Color3.fromRGB(22, 20, 19)
local BUTTON = Color3.fromRGB(48, 44, 41)
local GOOD = Color3.fromRGB(120, 200, 140)
local BAD = Color3.fromRGB(220, 80, 70)
local AMBER = Color3.fromRGB(235, 190, 110)
local DOCUMENT_WALK_AWAY = 10 -- studs: walk this far and the paper is put down

local ChapterUi = {}

local gui: ScreenGui
local panel: Frame
local title: TextLabel
local body: Frame
local closeButton: TextButton
local openKind = "" -- "", "document" or a puzzle kind
local documentFrom: Vector3? = nil
local faderPush = 0
local lastFaderSent = 0
local faderSentValue = 0

local function make(className: string, props: { [string]: any }, parent: Instance?): any
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local function textLabel(
	parent: Instance,
	text: string,
	size: UDim2,
	position: UDim2,
	textSize: number
): TextLabel
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Size = size,
		Position = position,
		Font = FONT,
		TextSize = textSize,
		TextColor3 = TEXT,
		Text = text,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	}, parent)
end

local function button(parent: Instance, text: string, size: UDim2, position: UDim2): TextButton
	local b: TextButton = make("TextButton", {
		Size = size,
		Position = position,
		BackgroundColor3 = BUTTON,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 15,
		TextColor3 = TEXT,
		Text = text,
		AutoButtonColor = true,
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
	return b
end

local function rootPosition(): Vector3?
	local character = player.Character
	local r = character and character:FindFirstChild("HumanoidRootPart")
	return if r and r:IsA("BasePart") then r.Position else nil
end

local function clearBody()
	for _, child in body:GetChildren() do
		child:Destroy()
	end
end

local function close()
	openKind = ""
	documentFrom = nil
	panel.Visible = false
	closeButton.Modal = false
	faderPush = 0
	ContextActionService:UnbindAction("DeadAirFaderUp")
	ContextActionService:UnbindAction("DeadAirFaderDown")
	clearBody()
end

local function open(kind: string, heading: string)
	clearBody()
	openKind = kind
	title.Text = heading
	panel.Visible = true
	closeButton.Modal = true -- frees the mouse in first person while the panel is up
end

-- ===== Documents =====

local function showDocument(heading: string, text: string)
	open("document", heading)
	documentFrom = rootPosition()
	local scroll = make("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
	}, body)
	local label = textLabel(scroll, text, UDim2.new(1, -12, 0, 0), UDim2.new(), 15)
	label.AutomaticSize = Enum.AutomaticSize.Y
end

-- ===== Rethreading the tape machine =====

local function showRethread(data: any)
	local order: { string } = if type(data) == "table" and type(data.parts) == "table"
		then data.parts
		else {}
	open("rethread", "Rethread the tape path")
	local hint = textLabel(
		body,
		"Route the tape around the guides in order, from the supply reel to the take-up reel. A wrong guide and it slips off (that makes noise).",
		UDim2.new(1, 0, 0, 40),
		UDim2.new(),
		13
	)
	hint.TextColor3 = DIM
	local progress = textLabel(body, "", UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 44), 14)
	progress.TextColor3 = AMBER
	local chosen: { string } = {}
	local guideButtons: { TextButton } = {}

	local function refresh()
		progress.Text = if #chosen == 0
			then "Guides: 0/" .. tostring(#order) .. "  /  Start at the supply reel"
			else "Guides: "
				.. tostring(#chosen)
				.. "/"
				.. tostring(#order)
				.. "  /  "
				.. table.concat(chosen, " > ")
	end
	refresh()

	-- The guides, scattered in a shuffled grid each time.
	local names = table.clone(order)
	local rng = Random.new()
	for i = #names, 2, -1 do
		local j = rng:NextInteger(1, i)
		names[i], names[j] = names[j], names[i]
	end
	for index, name in names do
		local col = (index - 1) % 3
		local row = (index - 1) // 3
		local b = button(
			body,
			name,
			UDim2.fromOffset(150, 40),
			UDim2.fromOffset(
				col * 160 + rng:NextInteger(0, 10),
				90 + row * 52 + rng:NextInteger(0, 6)
			)
		)
		table.insert(guideButtons, b)
		b.Activated:Connect(function()
			if openKind ~= "rethread" or table.find(chosen, name) then
				return
			end
			table.insert(chosen, name)
			if order[#chosen] ~= name then
				-- Slipped off: the server hears about it (noise), and you start again.
				Remotes.PuzzleAnswer:FireServer("rethread", chosen)
				chosen = {}
				for _, guide in guideButtons do
					guide.BackgroundColor3 = BUTTON
				end
				progress.Text = "Wrong guide. The tape slipped off. Restart at the supply reel."
				progress.TextColor3 = BAD
				task.delay(1.2, function()
					if openKind == "rethread" then
						progress.TextColor3 = AMBER
						refresh()
					end
				end)
				return
			end
			b.BackgroundColor3 = Color3.fromRGB(60, 80, 62)
			refresh()
			if #chosen == #order then
				Remotes.PuzzleAnswer:FireServer("rethread", chosen)
			end
		end)
	end
end

-- ===== The safe =====

local function showSafe(data: any)
	local digits = if type(data) == "table" and type(data.digits) == "number"
		then data.digits
		else 6
	open("safe", "Desk safe")
	local display = textLabel(body, "", UDim2.new(1, 0, 0, 40), UDim2.new(), 28)
	display.TextXAlignment = Enum.TextXAlignment.Center
	display.TextColor3 = AMBER
	local entered = ""
	local function refresh()
		display.Text = entered .. string.rep("_", digits - #entered)
	end
	refresh()
	local keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "Clear", "0", "Open" }
	for index, key in keys do
		local col = (index - 1) % 3
		local row = (index - 1) // 3
		local b = button(
			body,
			key,
			UDim2.fromOffset(100, 44),
			UDim2.fromOffset(80 + col * 110, 56 + row * 52)
		)
		b.Activated:Connect(function()
			if openKind ~= "safe" then
				return
			end
			if key == "Clear" then
				entered = ""
			elseif key == "Open" then
				if #entered == digits then
					Remotes.PuzzleAnswer:FireServer("safe", entered)
					entered = ""
				end
			elseif #entered < digits then
				entered ..= key
			end
			refresh()
		end)
	end
	local hint = textLabel(
		body,
		"Six digits. People pick dates that matter to them.",
		UDim2.new(1, 0, 0, 20),
		UDim2.fromOffset(0, 270),
		13
	)
	hint.TextColor3 = DIM
end

-- ===== The patch bay =====

local function showPatchBay(data: any)
	local tracks: { string } = if type(data) == "table" and type(data.tracks) == "table"
		then data.tracks
		else {}
	local inputCount = if type(data) == "table" and type(data.inputs) == "number"
		then data.inputs
		else 8
	open("patchbay", "Patch bay")
	local hint = textLabel(
		body,
		"Pick a track, then the desk input it goes to. The engineer's log has the patch. A wrong patch buzzes through the speakers.",
		UDim2.new(1, 0, 0, 40),
		UDim2.new(),
		13
	)
	hint.TextColor3 = DIM
	local patch: { [string]: number } = {}
	local selected: string? = nil
	local trackButtons: { [string]: TextButton } = {}

	local function refresh()
		for letter, b in trackButtons do
			local input = patch[letter]
			b.Text =
				string.format("TRACK %s  >  %s", letter, if input then "INPUT " .. input else "...")
			b.BackgroundColor3 = if selected == letter then Color3.fromRGB(90, 76, 48) else BUTTON
		end
	end

	for i, letter in tracks do
		local b =
			button(body, "", UDim2.fromOffset(220, 40), UDim2.fromOffset(0, 50 + (i - 1) * 50))
		trackButtons[letter] = b
		b.Activated:Connect(function()
			selected = letter
			refresh()
		end)
	end
	for input = 1, inputCount do
		local col = (input - 1) % 2
		local row = (input - 1) // 2
		local b = button(
			body,
			"INPUT " .. input,
			UDim2.fromOffset(110, 36),
			UDim2.fromOffset(250 + col * 120, 50 + row * 44)
		)
		b.Activated:Connect(function()
			local letter = selected
			if not letter then
				return
			end
			-- One cable per input: unplug whatever was there.
			for other, value in patch do
				if value == input then
					patch[other] = nil
				end
			end
			patch[letter] = input
			selected = nil
			refresh()
		end)
	end
	local test =
		button(body, "Throw the switch", UDim2.fromOffset(220, 40), UDim2.fromOffset(0, 210))
	test.TextColor3 = AMBER
	test.Activated:Connect(function()
		if openKind == "patchbay" then
			Remotes.PuzzleAnswer:FireServer("patchbay", patch)
		end
	end)
	refresh()
end

-- ===== Riding the faders =====

local function onFaderKey(name: string, state: Enum.UserInputState): Enum.ContextActionResult
	local direction = if name == "DeadAirFaderUp" then 1 else -1
	if state == Enum.UserInputState.Begin then
		faderPush = direction
	elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
		if faderPush == direction then
			faderPush = 0
		end
	end
	return Enum.ContextActionResult.Sink
end

local function showFaders(data: any)
	local band = if type(data) == "table" and type(data.band) == "number" then data.band else 0.18
	open("faders", "The last session")
	local hint = textLabel(
		body,
		"Keep the level inside the band (W / S, or hold the arrows). If it drifts out, the sound spikes and it will hear. Don't walk away from the desk.",
		UDim2.new(1, 0, 0, 56),
		UDim2.new(),
		13
	)
	hint.TextColor3 = DIM
	local meter: Frame = make("Frame", {
		Size = UDim2.fromOffset(60, 220),
		Position = UDim2.fromOffset(40, 64),
		BackgroundColor3 = Color3.fromRGB(14, 13, 12),
		BorderSizePixel = 0,
	}, body)
	make("Frame", {
		Size = UDim2.new(1, 0, band * 2, 0),
		Position = UDim2.new(0, 0, 0.5 - band, 0),
		BackgroundColor3 = Color3.fromRGB(40, 70, 46),
		BorderSizePixel = 0,
	}, meter)
	local needle: Frame = make("Frame", {
		Size = UDim2.new(1, 10, 0, 4),
		Position = UDim2.new(0, -5, 0.5, -2),
		BackgroundColor3 = AMBER,
		BorderSizePixel = 0,
	}, meter)
	local status = textLabel(body, "", UDim2.fromOffset(300, 60), UDim2.fromOffset(130, 70), 16)
	local up = button(body, "▲", UDim2.fromOffset(80, 60), UDim2.fromOffset(130, 150))
	local down = button(body, "▼", UDim2.fromOffset(80, 60), UDim2.fromOffset(130, 220))
	local arrows: { { button: TextButton, direction: number } } =
		{ { button = up, direction = 1 }, { button = down, direction = -1 } }
	for _, arrow in arrows do
		local b, direction = arrow.button, arrow.direction
		b.MouseButton1Down:Connect(function()
			faderPush = direction
		end)
		b.MouseButton1Up:Connect(function()
			if faderPush == direction then
				faderPush = 0
			end
		end)
		b.MouseLeave:Connect(function()
			if faderPush == direction then
				faderPush = 0
			end
		end)
	end
	ContextActionService:BindAction(
		"DeadAirFaderUp",
		onFaderKey,
		false,
		Enum.KeyCode.W,
		Enum.KeyCode.Up,
		Enum.KeyCode.DPadUp
	)
	ContextActionService:BindAction(
		"DeadAirFaderDown",
		onFaderKey,
		false,
		Enum.KeyCode.S,
		Enum.KeyCode.Down,
		Enum.KeyCode.DPadDown
	)

	local state = ReplicatedStorage:WaitForChild("RoundState")
	task.spawn(function()
		while openKind == "faders" do
			local level = player:GetAttribute("DubLevel")
			local value: number = if type(level) == "number" then level else 0.5
			needle.Position = UDim2.new(0, -5, 1 - value, -2)
			local inBand = math.abs(value - 0.5) <= band
			needle.BackgroundColor3 = if inBand then GOOD else BAD
			local progress: number = state:GetAttribute("DubProgress") or 0
			status.Text = string.format(
				"Dubbing onto the cassette: %d%%\n%s",
				math.floor(progress * 100),
				if inBand then "Steady." else "TOO HOT. Bring it back!"
			)
			status.TextColor3 = if inBand then TEXT else BAD
			task.wait(0.05)
		end
	end)
end

-- ===== Wiring =====

local function onPuzzle(kind: string, data: any)
	if kind == "" then
		if openKind ~= "document" then
			close()
		end
		return
	end
	if kind == "rethread" then
		showRethread(data)
	elseif kind == "safe" then
		showSafe(data)
	elseif kind == "patchbay" then
		showPatchBay(data)
	elseif kind == "faders" then
		showFaders(data)
	end
end

function ChapterUi.isOpen(): boolean
	return openKind ~= ""
end

function ChapterUi.start()
	gui = make("ScreenGui", {
		Name = "DeadAirChapter",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 5,
	}, player:WaitForChild("PlayerGui"))
	panel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(540, 400),
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Visible = false,
	}, gui)
	make("UICorner", { CornerRadius = UDim.new(0, 6) }, panel)
	make("UISizeConstraint", { MaxSize = Vector2.new(540, 400) }, panel)
	title = textLabel(panel, "", UDim2.new(1, -120, 0, 28), UDim2.fromOffset(16, 12), 18)
	title.TextColor3 = AMBER
	closeButton = button(panel, "Close", UDim2.fromOffset(90, 30), UDim2.new(1, -106, 0, 10))
	closeButton.Activated:Connect(close)
	body = make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -32, 1, -64),
		Position = UDim2.fromOffset(16, 50),
	}, panel)

	Remotes.Document.OnClientEvent:Connect(showDocument)
	Remotes.Puzzle.OnClientEvent:Connect(onPuzzle)

	RunService.Heartbeat:Connect(function()
		-- Put the paper down when walking off, or when the character changes.
		if openKind == "document" then
			local here = rootPosition()
			if
				not here or (documentFrom and (here - documentFrom).Magnitude > DOCUMENT_WALK_AWAY)
			then
				close()
			end
		end
		-- The fader push, sent when it changes and now and then while held.
		local now = os.clock()
		if openKind == "faders" then
			if faderPush ~= faderSentValue or (faderPush ~= 0 and now - lastFaderSent > 0.25) then
				faderSentValue = faderPush
				lastFaderSent = now
				Remotes.Fader:FireServer(faderPush)
			end
		elseif faderSentValue ~= 0 then
			faderSentValue = 0
			Remotes.Fader:FireServer(0)
		end
	end)
end

return ChapterUi
