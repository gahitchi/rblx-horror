--!strict
-- Studio-specific search affordances: the former engineer naturally checks
-- equipment associated with the sound, but ONLY where an audible clue brought
-- him. This never asks where a player is, or reads hidden occupants.
local Workspace = game:GetService("Workspace")
local MapContract = require(script.Parent.Parent.MapContract)

local Environment = {}

local BY_SOUND: { [string]: { string } } = {
	reel = { "TapeMachine", "CardIndex" },
	slip = { "TapeMachine" },
	recording = { "TapeMachine", "MixingDesk" },
	buzz = { "PatchBay", "MixingDesk" },
	spike = { "MixingDesk" },
	clutter = { "RoadCase" },
	safe = { "Safe" },
	door = { "CardIndex" },
}

-- Returns an existing authored walkable patrol point, not the position
-- inside a solid console. No new pathfinding or scripts are started.
function Environment.select(
	areas: { MapContract.Area },
	center: Vector3,
	kind: string
): (Vector3?, string?)
	local names = BY_SOUND[kind]
	if not names then
		return nil, nil
	end
	local map = Workspace:FindFirstChild("Map")
	local objectives = map and map:FindFirstChild("Objectives")
	if not objectives then
		return nil, nil
	end
	local nearest: BasePart? = nil
	local best = 16
	for _, name in names do
		local part = objectives:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			local distance = (part.Position - center).Magnitude
			if distance < best and math.abs(part.Position.Y - center.Y) < 9 then
				nearest = part
				best = distance
			end
		end
	end
	if not nearest then
		return nil, nil
	end

	local closest: Vector3? = nil
	local bestWalk = 9
	for _, area in areas do
		for _, point in area.points do
			local d = (point - nearest.Position).Magnitude
			if d < bestWalk and (point - center).Magnitude < 24 then
				closest = point
				bestWalk = d
			end
		end
	end
	return closest, nearest.Name
end

return Environment
