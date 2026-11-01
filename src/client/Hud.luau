--!strict
-- The on-screen information: round status, objectives, noise meter, stamina, messages.
-- Kept sparse on purpose; the dark should do most of the work.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local EchoController = require(script.Parent.EchoController)
local MovementController = require(script.Parent.MovementController)
local SpectateController = require(script.Parent.SpectateController)
local VoiceController = require(script.Parent.VoiceController)

local player = Players.LocalPlayer

local FONT = Enum.Font.RobotoMono
local TEXT = Color3.fromRGB(225, 220, 210)
local DIM = Color3.fromRGB(130, 125, 118)
local RADIO = Color3.fromRGB(235, 190, 110)
local BROADCAST = Color3.fromRGB(170, 160, 200)
local WHISPER = Color3.fromRGB(160, 200, 230)
local DANGER = Color3.fromRGB(230, 70, 60)
local NOISE_FULL = 60 -- a noise this loud fills the meter
local TOAST_SECONDS = 4.5

local Hud = {}

local function label(parent: Instance, size: UDim2, position: UDim2, textSize: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = position
	l.Font = FONT
	l.TextSize = textSize
	l.TextColor3 = TEXT
	l.TextStrokeTransparency = 0.6
	l.Text = ""
	l.Parent = parent
	return l
end

local function bar(parent: Instance, position: UDim2, caption: string): (Frame, Frame)
	local back = Instance.new("Frame")
	back.AnchorPoint = Vector2.new(0.5, 0)
	back.Position = position
	back.Size = UDim2.fromOffset(220, 6)
	back.BackgroundColor3 = Color3.fromRGB(30, 28, 26)
	back.BackgroundTransparency = 0.3
	back.BorderSizePixel = 0
	back.Parent = parent
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = TEXT
	fill.BorderSizePixel = 0
	fill.Parent = back
	local cap = label(back, UDim2.fromOffset(80, 14), UDim2.new(0, -86, 0, -4), 12)
	cap.TextXAlignment = Enum.TextXAlignment.Right
	cap.TextColor3 = DIM
	cap.Text = caption
	return back, fill
end

-- A red mark where an echo saw the monster, for a few seconds.
local function showPing(position: Vector3)
	local anchor = Instance.new("Part")
	anchor.Name = "EchoPing"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = position + Vector3.new(0, 4, 0)
	anchor.Parent = workspace
	local board = Instance.new("BillboardGui")
	board.Size = UDim2.fromOffset(60, 60)
	board.AlwaysOnTop = true
	board.Parent = anchor
	local mark = Instance.new("TextLabel")
	mark.Size = UDim2.fromScale(1, 1)
	mark.BackgroundTransparency = 1
	mark.Text = "!"
	mark.TextScaled = true
	mark.Font = Enum.Font.GothamBlack
	mark.TextColor3 = DANGER
	mark.TextStrokeTransparency = 0.3
	mark.Parent = board
	task.delay(Config.ECHO.PING_SECONDS, function()
		anchor:Destroy()
	end)
end

function Hud.start()
	local state = ReplicatedStorage:WaitForChild("RoundState")

	local gui = Instance.new("ScreenGui")
	gui.Name = "DeadAirHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Top centre: phase and clock.
	local status = label(gui, UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 44), 18)

	-- Top left: objectives.
	local objectives = label(gui, UDim2.fromOffset(340, 120), UDim2.fromOffset(20, 44), 15)
	objectives.TextXAlignment = Enum.TextXAlignment.Left
	objectives.TextYAlignment = Enum.TextYAlignment.Top
	objectives.RichText = true

	-- Centre: a small dot to aim prompts, and a big message line.
	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(3, 3)
	dot.BackgroundColor3 = TEXT
	dot.BackgroundTransparency = 0.4
	dot.BorderSizePixel = 0
	dot.Parent = gui
	local centre = label(gui, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0.5, 40), 22)

	-- Bottom centre: noise and stamina.
	local _, noiseFill = bar(gui, UDim2.new(0.5, 0, 1, -50), "NOISE")
	local staminaBack, staminaFill = bar(gui, UDim2.new(0.5, 0, 1, -34), "BREATH")

	-- Bottom left: controls.
	local help = label(gui, UDim2.fromOffset(520, 18), UDim2.new(0, 20, 1, -32), 13)
	help.TextXAlignment = Enum.TextXAlignment.Left
	help.TextColor3 = DIM
	local keys = { "Shift run", "C crouch", "F light", "E interact", "G drop", "T throw" }
	if Config.FEATURES.WALKIE then
		table.insert(keys, "V talk")
		table.insert(keys, "1-4 callouts")
		table.insert(keys, "N radio off")
	end
	if Config.FEATURES.TAPE then
		table.insert(keys, "R tape")
	end
	help.Size = UDim2.fromOffset(760, 18)
	help.Text = table.concat(keys, " · ")

	-- Bottom left, above the controls: the items' state.
	local items = label(gui, UDim2.fromOffset(900, 18), UDim2.new(0, 20, 1, -54), 14)
	items.TextXAlignment = Enum.TextXAlignment.Left
	items.RichText = true

	-- Right: messages, newest at the bottom.
	local toasts = Instance.new("Frame")
	toasts.BackgroundTransparency = 1
	toasts.AnchorPoint = Vector2.new(1, 1)
	toasts.Position = UDim2.new(1, -20, 1, -80)
	toasts.Size = UDim2.fromOffset(420, 300)
	toasts.Parent = gui
	local list = Instance.new("UIListLayout")
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 4)
	list.Parent = toasts
	local toastCount = 0

	local function showToast(message: string, color: Color3?, seconds: number?)
		toastCount += 1
		local toast = label(toasts, UDim2.new(1, 0, 0, 20), UDim2.new(), 15)
		toast.TextXAlignment = Enum.TextXAlignment.Right
		toast.TextWrapped = true
		toast.AutomaticSize = Enum.AutomaticSize.Y
		toast.LayoutOrder = toastCount
		toast.Text = message
		toast.TextColor3 = color or TEXT
		task.delay(seconds or TOAST_SECONDS, function()
			local fade = TweenService:Create(
				toast,
				TweenInfo.new(1),
				{ TextTransparency = 1, TextStrokeTransparency = 1 }
			)
			fade:Play()
			fade.Completed:Wait()
			toast:Destroy()
		end)
	end
	Remotes.Notify.OnClientEvent:Connect(function(message: string)
		showToast(message)
	end)
	Remotes.Radio.OnClientEvent:Connect(function(sender: string, room: string, text: string)
		if sender == "1987 broadcast" then
			showToast(text, BROADCAST, TOAST_SECONDS + 3)
		elseif room == "" then
			showToast(string.format("[%s] %s", sender, text), RADIO, TOAST_SECONDS + 4)
		else
			showToast(
				string.format("[radio] %s, %s: %s", sender, room, text),
				RADIO,
				TOAST_SECONDS + 2
			)
		end
	end)
	Remotes.Whisper.OnClientEvent:Connect(function(from: string, text: string)
		showToast(string.format("%s, faintly: %s", from, text), WHISPER, TOAST_SECONDS)
	end)
	Remotes.Ping.OnClientEvent:Connect(function(position: Vector3, from: string)
		showPing(position)
		showToast(from .. " marked where it is.", WHISPER, TOAST_SECONDS)
	end)

	-- Echo panel: whisper lines and the mark button, while you're an echo.
	local echoPanel = Instance.new("Frame")
	echoPanel.AnchorPoint = Vector2.new(0.5, 1)
	echoPanel.Position = UDim2.new(0.5, 0, 1, -70)
	echoPanel.Size = UDim2.fromOffset(600, 44)
	echoPanel.BackgroundTransparency = 1
	echoPanel.Visible = false
	echoPanel.Parent = gui
	local echoLayout = Instance.new("UIListLayout")
	echoLayout.FillDirection = Enum.FillDirection.Horizontal
	echoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	echoLayout.Padding = UDim.new(0, 6)
	echoLayout.Parent = echoPanel
	local function echoButton(text: string, onClick: () -> ()): TextButton
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(112, 36)
		b.BackgroundColor3 = Color3.fromRGB(30, 40, 48)
		b.BackgroundTransparency = 0.2
		b.BorderSizePixel = 0
		b.Font = FONT
		b.TextSize = 13
		b.TextColor3 = WHISPER
		b.Text = text
		b.Parent = echoPanel
		b.Activated:Connect(onClick)
		return b
	end
	local pingButton = echoButton("Mark it (P)", EchoController.ping)
	pingButton.TextColor3 = DANGER
	for i, line in Config.ECHO.WHISPERS do
		echoButton(string.format("%d: %s", i + 4, line), function()
			EchoController.whisper(i)
		end)
	end

	local noise = 0
	Remotes.NoiseFeedback.OnClientEvent:Connect(function(radius: number)
		noise = math.max(noise, math.clamp(radius / NOISE_FULL, 0, 1))
	end)

	RunService.RenderStepped:Connect(function(dt: number)
		local phase = state:GetAttribute("Phase")
		local character = player.Character
		local inRound = character ~= nil and character:GetAttribute("InRound") == true

		-- Status line and centre message.
		centre.Text = ""
		centre.TextColor3 = TEXT
		local isEcho = EchoController.isActive()
		if phase == "Playing" then
			status.Text = string.format("%d alive", state:GetAttribute("Alive") or 0)
			status.TextColor3 = TEXT
			local ends = state:GetAttribute("LastCallEnds")
			if state:GetAttribute("LastCall") and type(ends) == "number" then
				local left = math.max(0, math.ceil(ends - workspace:GetServerTimeNow()))
				status.Text = string.format("THE LOCKS RE-ENGAGE IN %d", left)
				status.TextColor3 = DANGER
			end
			if player:GetAttribute("Hiding") then
				local left: number = player:GetAttribute("BreathLeft") or 1
				if player:GetAttribute("BreathDanger") then
					centre.Text = string.format(
						"It's close. Hold your breath (Space)   %s",
						string.rep("|", math.ceil(left * 10))
					)
					centre.TextColor3 = DANGER
				else
					centre.Text = "Hiding   ·   E to step out"
					centre.TextColor3 = DIM
				end
			elseif isEcho then
				centre.Text = "You're an echo. Float anywhere and help the living."
				centre.TextColor3 = WHISPER
			elseif not inRound then
				local watching = SpectateController.getTarget()
				centre.Text = if watching
					then string.format("Watching %s   ·   Q / E to switch", watching.DisplayName)
					else "You're out. The next round starts soon."
			end
		elseif phase == "Results" then
			status.Text = "ROUND OVER"
			status.TextColor3 = TEXT
		else
			status.TextColor3 = TEXT
			local countdown = state:GetAttribute("Countdown") or -1
			status.Text = if countdown >= 0
				then string.format("DEAD AIR   ·   next round in %d", countdown)
				else "DEAD AIR   ·   waiting for players"
		end
		echoPanel.Visible = isEcho

		-- Objectives come from the chapter (RoundState.ObjectiveText), while playing.
		if phase == "Playing" and (inRound or isEcho) then
			local text: string = state:GetAttribute("ObjectiveText") or ""
			local dub: number = state:GetAttribute("DubProgress") or 0
			if dub > 0 and dub < 1 then
				text ..= string.format("\nLast session: %d%%", math.floor(dub * 100))
			end
			objectives.Text = text
		else
			objectives.Text = ""
		end

		-- Noise: what the server heard from you, plus your voice, decaying back to silence.
		noise = math.max(noise, VoiceController.getLevel()) - dt * 0.8
		noise = math.max(noise, 0)
		noiseFill.Size = UDim2.fromScale(noise, 1)
		noiseFill.BackgroundColor3 = if noise > 0.6
			then Color3.fromRGB(220, 70, 60)
			elseif noise > 0.3 then Color3.fromRGB(225, 170, 70)
			else TEXT

		-- Items
		if phase == "Playing" and inRound then
			local parts: { string } = {}
			if Config.FEATURES.WALKIE then
				local walkie = if player:GetAttribute("WalkieTalking")
					then string.format('<font color="#%s">TALKING</font>', RADIO:ToHex())
					elseif player:GetAttribute("WalkieOn") then "on"
					else "off"
				local incoming: { string } = {}
				if player:GetAttribute("WalkieOn") then
					for _, other in Players:GetPlayers() do
						if other ~= player and other:GetAttribute("WalkieTalking") then
							table.insert(incoming, other.DisplayName)
						end
					end
				end
				if #incoming > 0 then
					walkie ..= string.format(
						'  <font color="#%s">%s on the radio</font>',
						RADIO:ToHex(),
						table.concat(incoming, ", ")
					)
				end
				table.insert(parts, "Walkie: " .. walkie)
			end
			if Config.FEATURES.TAPE then
				local tapeState = player:GetAttribute("TapeState")
				local tapeText = if tapeState == "recording"
					then string.format('<font color="#%s">RECORDING</font>', RADIO:ToHex())
					elseif tapeState == "ready" then "recorded (R to set down)"
					elseif tapeState == "placed" then "set down"
					else "blank (R to record)"
				table.insert(parts, "Tape: " .. tapeText)
			end
			local holding = player:GetAttribute("HoldingName")
			if type(holding) == "string" and holding ~= "" then
				table.insert(parts, "Holding: " .. holding)
			end
			if player:GetAttribute("HasCassette") then
				table.insert(
					parts,
					string.format('<font color="#%s">CASSETTE</font>', RADIO:ToHex())
				)
			end
			local tapes = player:GetAttribute("TapesCarried") or 0
			if tapes > 0 then
				table.insert(
					parts,
					string.format("%d old tape%s", tapes, if tapes == 1 then "" else "s")
				)
			end
			items.Text = table.concat(parts, "     ")
		else
			items.Text = ""
		end

		local stamina = MovementController.getStamina()
		staminaFill.Size = UDim2.fromScale(stamina, 1)
		staminaBack.Visible = stamina < 0.999
	end)
end

return Hud
