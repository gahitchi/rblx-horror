--!strict
-- Five optional, readable studio papers. Small, noncolliding parts and no
-- chapter targets; the chapter script installs round-owned ProximityPrompts
-- only when these named objects exist in the generated studio.
local Kit = require(script.Parent.StudioDecorKit)
local C = Kit.palette

local Evidence = {}

type Placement = {
	id: string,
	caption: string,
	at: Vector3,
	size: Vector3,
	face: Enum.NormalId,
}

-- Positioned on actual 0.8 chapter-one walls and the live-room road-case face.
-- All references are within room bounds and away from the mandatory doorways.
local PAPERS: { Placement } = {
	{
		id = "MachineServiceCard", caption = "SERVICE / TRANSPORT / 02 NOV",
		at = Vector3.new(-65, 5.7, -106.42),
		size = Vector3.new(3.5, 2.6, 0.09),
		face = Enum.NormalId.Back,
	},
	{
		id = "ArchiveFilingSlip", caption = "DRAWER W / FILING RULES",
		at = Vector3.new(-83.5, 5.7, -116),
		size = Vector3.new(0.09, 3.2, 3.6),
		face = Enum.NormalId.Right,
	},
	{
		id = "LiveCaseTag", caption = "LOAN / LIVE ROOM / NOV 2",
		at = Vector3.new(19, 2.45, -78.91),
		size = Vector3.new(3.4, 1.4, 0.09),
		face = Enum.NormalId.Back,
	},
	{
		id = "RoutingNotice", caption = "CONTROL A / PATCH ROUTING",
		at = Vector3.new(-34.46, 5.8, -96),
		size = Vector3.new(0.09, 3.0, 4.2),
		face = Enum.NormalId.Left,
	},
	{
		id = "QuarantineIntake", caption = "NAVY / ORDER 27 / 1987",
		at = Vector3.new(25, 5.8, 23.53),
		size = Vector3.new(4.6, 3.0, 0.09),
		face = Enum.NormalId.Front,
	},
}

function Evidence.apply(map: Model)
	local props = map:FindFirstChild("Props")
	if not props then
		return
	end
	local folder = Kit.group(props, "RecordedEvidence")
	for _, entry in PAPERS do
		-- Visual type and unique name are shared with Studio1Text.EVIDENCE.
		-- No prompts are parented during map generation; Kit owns their lifetime.
		local sheet = Kit.sign(folder, entry.caption, CFrame.new(entry.at),
			entry.size, entry.face, C.dark, C.paper)
		sheet.Name = entry.id
		sheet.CastShadow = false
		sheet.CanCollide = false
		sheet.CanQuery = false
		sheet.CanTouch = false
	end
end

return Evidence
