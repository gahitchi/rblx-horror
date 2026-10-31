--!strict
-- After a round: "Play again?" and, for those who stay, the vote on the next map.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local FONT = Enum.Font.RobotoMono
local TEXT = Color3.fromRGB(225, 220, 210)
local DIM = Color3.fromRGB(130, 125, 118)
local BUTTON = Color3.fromRGB(45, 42, 40)
local CHOSEN = Color3.fromRGB(90, 60, 40)

local ReplayUi = {}

local function make(className: string, parent: Instance, props: { [string]: any }): any
	local instance = Instance.new(className)
	for key, value in props do
		(instance :: any)[key] = value
	end
	instance.Parent = parent
	return instance
end

local function button(parent: Instance, content: string, size: UDim2, position: UDim2): TextButton
	local b = make("TextButton", parent, {
		Size = size,
		Position = position,
		BackgroundColor3 = BUTTON,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 15,
		TextColor3 = TEXT,
		Text = content,
	})
	make("UICorner", b, { CornerRadius = UDim.new(0, 4) })
	return b
end

function ReplayUi.start()
	if not Config.FEATURES.REPLAY then
		return
	end
	local state = ReplicatedStorage:WaitForChild("RoundState")
	local gui = make("ScreenGui", player:WaitForChild("PlayerGui"), {
		Name = "DeadAirReplay",
		ResetOnSpawn = false,
		DisplayOrder = 8,
	})
	local panel = make("Frame", gui, {
		Size = UDim2.fromOffset(420, 120 + #Config.MAPS * 40),
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(18, 17, 16),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Visible = false,
	})
	make("UICorner", panel, { CornerRadius = UDim.new(0, 6) })
	local title = make("TextLabel", panel, {
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.fromOffset(0, 8),
		BackgroundTransparency = 1,
		Font = FONT,
		TextSize = 18,
		TextColor3 = TEXT,
		Text = "Play again?",
	})
	local yes = button(panel, "Yes", UDim2.fromOffset(180, 36), UDim2.fromOffset(20, 46))
	local no =
		button(panel, "No, back to the hub", UDim2.fromOffset(180, 36), UDim2.fromOffset(220, 46))
	yes.Modal = true -- a free mouse while the question is up

	local choice: boolean? = nil
	local myVote: string? = nil
	local mapButtons: { [string]: TextButton } = {}
	for i, map in Config.MAPS do
		local b =
			button(panel, "", UDim2.fromOffset(380, 32), UDim2.fromOffset(20, 92 + (i - 1) * 40))
		b.Visible = false
		b.Activated:Connect(function()
			myVote = map.id
			Remotes.MapVote:FireServer(map.id)
		end)
		mapButtons[map.id] = b
	end
	yes.Activated:Connect(function()
		choice = true
		Remotes.ReplayChoice:FireServer(true)
	end)
	no.Activated:Connect(function()
		choice = false
		Remotes.ReplayChoice:FireServer(false)
	end)

	local wasVoting = false
	RunService.RenderStepped:Connect(function()
		local voting = state:GetAttribute("Voting") == true
		if voting and not wasVoting then
			choice, myVote = nil, nil
		end
		wasVoting = voting
		panel.Visible = voting
		if not voting then
			return
		end
		local left = math.max(0, (state:GetAttribute("VoteEnds") or 0) - os.time())
		yes.BackgroundColor3 = if choice == true then CHOSEN else BUTTON
		no.BackgroundColor3 = if choice == false then CHOSEN else BUTTON
		if choice == false then
			title.Text = string.format("Heading back to the hub...  (%d)", left)
		elseif choice == true then
			title.Text = string.format("Vote for the next map  (%d)", left)
		else
			title.Text = string.format("Play again?  (%d)", left)
		end
		for _, map in Config.MAPS do
			local b = mapButtons[map.id]
			b.Visible = choice == true
			b.Text = string.format(
				"%s  ·  %s   [%d]",
				map.name,
				map.monster,
				state:GetAttribute("Votes_" .. map.id) or 0
			)
			b.BackgroundColor3 = if myVote == map.id then CHOSEN else BUTTON
			b.TextColor3 = if myVote == nil or myVote == map.id then TEXT else DIM
		end
	end)
end

return ReplayUi
