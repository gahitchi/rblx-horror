--!strict
-- The hub is a safe place: one rotating lighthouse and a short gate departure.
-- Nothing here sends gameplay noise, uses the chapter monster, or runs in the match place.
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sounds"))

local HubDynamics = {}
local openAt = 0

function HubDynamics.init(hub: Model)
	local scene = hub:FindFirstChild("DistantWrenmouth")
	local lighthouse = scene and scene:FindFirstChild("SweepingLighthouseBeacon")
	if lighthouse and lighthouse:IsA("BasePart") then
		local source = lighthouse.CFrame
		task.spawn(function()
			local phase = 0
			while lighthouse.Parent and hub.Parent do
				task.wait(0.12)
				phase += 0.12
				lighthouse.CFrame = source * CFrame.Angles(0, phase * 0.24, 0)
			end
		end)
	end
	local marker = hub:FindFirstChild("Foghorn", true)
	if marker and marker:IsA("BasePart") then
		task.spawn(function()
			while hub.Parent do
				task.wait(80)
				if not hub.Parent then
					return
				end
				-- Temporary sound ID until a real harbour foghorn is auditioned.
				Sounds.playAt(Sounds.FOGHORN, marker.Position, 0.24, 250, 0.4)
			end
		end)
	end
end

-- Called only by an authorized lobby host starting a published match.
-- Opens the barrier, leaves a brief visual beat, then lobby code teleports the crew.
function HubDynamics.departure(hub: Model)
	local gate = hub:FindFirstChild("Gate")
	local hinge = gate and gate:FindFirstChild("Hinge")
	local bar = gate and gate:FindFirstChild("BarrierArm")
	local found = gate and gate:FindFirstChild("GateBlocker")
	local blocker: BasePart? = if found and found:IsA("BasePart") then found else nil
	if not gate or not hinge or not bar or not hinge:IsA("BasePart") or not bar:IsA("BasePart") then
		return
	end
	local now = os.clock()
	openAt = now
	local stripes: { BasePart } = {}
	for _, p in gate:GetChildren() do
		if p:IsA("BasePart") and p.Name == "BarrierStripe" then
			table.insert(stripes, p)
		end
	end
	local rot = CFrame.Angles(math.rad(-78), 0, 0)
	local root = hinge.CFrame
	local info = TweenInfo.new(1.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local originals: { [BasePart]: CFrame } = {}
	local pieces: { BasePart } = { bar }
	for _, stripe in stripes do
		table.insert(pieces, stripe)
	end
	for _, part in pieces do
		originals[part] = part.CFrame
		TweenService:Create(part, info, {
			CFrame = root * rot * root:ToObjectSpace(part.CFrame),
		}):Play()
	end
	if blocker and blocker:IsA("BasePart") then
		blocker.CanCollide = false
	end
	task.delay(6.5, function()
		if not gate.Parent or openAt ~= now then
			return
		end
		for part, target in originals do
			if part.Parent then
				TweenService:Create(part, TweenInfo.new(0.9), { CFrame = target }):Play()
			end
		end
		task.delay(1, function()
			if blocker and blocker.Parent and openAt == now then
				blocker.CanCollide = true
			end
		end)
	end)
end

return HubDynamics
