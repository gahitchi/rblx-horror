--!strict
-- The shared state of the current round, as attributes on ReplicatedStorage.RoundState so every
-- client's HUD can read it. Only the server writes it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("RoundState")
if not folder then
	local created = Instance.new("Folder")
	created.Name = "RoundState"
	created.Parent = ReplicatedStorage
	folder = created
end

local RoundState = {}

RoundState.folder = folder :: Folder

function RoundState.set(name: string, value: any)
	RoundState.folder:SetAttribute(name, value)
end

function RoundState.get(name: string): any
	return RoundState.folder:GetAttribute(name)
end

return RoundState
