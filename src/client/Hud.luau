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

local MovementController = require(script.Parent.MovementController)
local SpectateController = require(script.Parent.SpectateController)
local VoiceController = require(script.Parent.VoiceController)

local player = Players.LocalPlayer

local FONT = Enum.Font.RobotoMono
local TEXT = Color3.fromRGB(225, 220, 210)
local DIM = Color3.fromRGB(130, 125, 118)
local DONE = Color3.fromRGB(120, 200, 140)
local RADIO = Color3.fromRGB(235, 190, 110)
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

local function formatTime(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
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
	local keys = { "Shift run", "C crouch", "F light", "E interact" }
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
	local items = label(gui, UDim2.fromOffset(620, 18), UDim2.new(0, 20, 1, -54), 14)
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
		showToast(string.format("[radio] %s, %s: %s", sender, room, text), RADIO, TOAST_SECONDS + 2)
	end)

	local noise = 0
	Remotes.NoiseFeedback.OnClientEvent:Connect(function(radius: number)
		noise = math.max(noise, math.clamp(radius / NOISE_FULL, 0, 1))
	end)

	local function progressText(n: number?, goal: number): string
		local value = n or 0
		if value >= goal then
			return string.format('<font color="#%s">done</font>', DONE:ToHex())
		end
		return string.format("%d/%d", value, goal)
	end

	RunService.RenderStepped:Connect(function(dt: number)
		local phase = state:GetAttribute("Phase")
		local character = player.Character
		local inRound = character ~= nil and character:GetAttribute("InRound") == true

		-- Status line and centre message.
		centre.Text = ""
		if phase == "Playing" then
			status.Text = string.format(
				"%s   ·   %d alive",
				formatTime(state:GetAttribute("TimeLeft") or 0),
				state:GetAttribute("Alive") or 0
			)
			if not inRound then
				local watching = SpectateController.getTarget()
				centre.Text = if watching
					then string.format("Watching %s   ·   Q / E to switch", watching.DisplayName)
					else "You're out. The next round starts soon."
			end
		elseif phase == "Results" then
			status.Text = "ROUND OVER"
		else
			local countdown = state:GetAttribute("Countdown") or -1
			status.Text = if countdown >= 0
				then string.format("DEAD AIR   ·   next round in %d", countdown)
				else "DEAD AIR   ·   waiting for players"
		end

		-- Objectives, only while playing.
		if phase == "Playing" and inRound then
			local lines = {
				"<b>GET OUT OF THE STUDIO</b>",
				"Generator (basement)   "
					.. progressText(state:GetAttribute("GeneratorPulls"), Config.GENERATOR_PULLS),
				"Fuses to the fuse box  "
					.. progressText(state:GetAttribute("FusesPlaced"), Config.FUSES_NEEDED),
			}
			local progress: number = state:GetAttribute("TapeProgress") or 0
			if state:GetAttribute("DoorsOpen") then
				table.insert(lines, "Emergency tape         " .. progressText(1, 1))
				table.insert(
					lines,
					string.format('<font color="#%s">FRONT DOORS OPEN. RUN.</font>', DONE:ToHex())
				)
			elseif progress > 0 then
				table.insert(
					lines,
					string.format("Emergency tape         %d%%", math.floor(progress * 100))
				)
			else
				table.insert(lines, "Emergency tape (control A)")
			end
			if player:GetAttribute("CarryingFuse") then
				table.insert(
					lines,
					string.format('<font color="#%s">Carrying a fuse</font>', DIM:ToHex())
				)
			end
			objectives.Text = table.concat(lines, "\n")
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
