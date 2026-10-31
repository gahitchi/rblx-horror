--!strict
-- All RemoteEvents in one place. The server creates them; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()

local folder: Instance
if IS_SERVER then
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		folder = existing
	else
		local created = Instance.new("Folder")
		created.Name = "Remotes"
		created.Parent = ReplicatedStorage
		folder = created
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

local function event(name: string): RemoteEvent
	if IS_SERVER then
		local existing = folder:FindFirstChild(name)
		if existing and existing:IsA("RemoteEvent") then
			return existing
		end
		local created = Instance.new("RemoteEvent")
		created.Name = name
		created.Parent = folder
		return created
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

return table.freeze({
	ToggleFlashlight = event("ToggleFlashlight"), -- client -> server: ()
	VoiceLevel = event("VoiceLevel"), -- client -> server: (level: number, 0 to 1)
	NoiseFeedback = event("NoiseFeedback"), -- server -> client: (radius: number) for the noise meter
	Notify = event("Notify"), -- server -> client: (message: string)
	WalkieTalk = event("WalkieTalk"), -- client -> server: (talking: boolean)
	WalkiePower = event("WalkiePower"), -- client -> server: () toggles the walkie on or off
	WalkieCallout = event("WalkieCallout"), -- client -> server: (index: number) into Config.WALKIE.CALLOUTS
	Radio = event("Radio"), -- server -> client: (sender: string, room: string, text: string)
	TapeAction = event("TapeAction"), -- client -> server: () record, or set down a recorded tape
	SetReady = event("SetReady"), -- client -> server: (ready: boolean) in the lobby
	Results = event("Results"), -- server -> client: ({ ResultRow }) at the end of a round
	SendFeedback = event("SendFeedback"), -- client -> server: ({ rating, tags, text })
	FeedbackReceived = event("FeedbackReceived"), -- server -> client: (ok: boolean, message: string)
})
