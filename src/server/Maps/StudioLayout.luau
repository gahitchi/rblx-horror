--!strict
-- Chapter 1: a reworked, stylized Blackline footprint. Coordinates are in studs.
-- Nineteen connected areas, with a two-route return to reception and a taller live hall.
-- Unlike the archived art-pass layout, this contains no generators or fuse objectives.

export type Room = {
	name: string, role: string,
	x1: number, x2: number, z1: number, z2: number, height: number,
}
export type Link = { string }
local StudioLayout = {}

function StudioLayout.make(): ({ Room }, { Link })
	local rooms: { Room } = {
		{ name = "IsolationWest", role = "booth", x1 = -116, x2 = -72, z1 = -192, z2 = -160, height = 14 },
		{ name = "MasteringSuite", role = "control", x1 = -72, x2 = -24, z1 = -192, z2 = -160, height = 14 },
		{ name = "TapeArchive", role = "archive", x1 = -24, x2 = 30, z1 = -192, z2 = -160, height = 15 },
		{ name = "IsolationEast", role = "booth", x1 = 30, x2 = 84, z1 = -192, z2 = -160, height = 14 },
		{ name = "IsolationDrums", role = "booth", x1 = -116, x2 = -72, z1 = -160, z2 = -128, height = 15 },
		{ name = "ViewingGallery", role = "corridor", x1 = -72, x2 = 30, z1 = -160, z2 = -128, height = 18 },
		{ name = "ServiceGallery", role = "corridor", x1 = 30, x2 = 84, z1 = -160, z2 = -128, height = 16 },
		{ name = "ControlA", role = "control", x1 = -116, x2 = -72, z1 = -128, z2 = -94, height = 16 },
		{ name = "LiveHall", role = "live", x1 = -72, x2 = 30, z1 = -128, z2 = -60, height = 24 },
		{ name = "LiveAnnex", role = "live", x1 = 30, x2 = 84, z1 = -128, z2 = -94, height = 19 },
		{ name = "ControlB", role = "control", x1 = -116, x2 = -72, z1 = -94, z2 = -60, height = 16 },
		{ name = "MachineRoom", role = "service", x1 = 30, x2 = 84, z1 = -94, z2 = -60, height = 16 },
		{ name = "StaffPassage", role = "corridor", x1 = -116, x2 = -72, z1 = -60, z2 = -30, height = 15 },
		{ name = "StaffGallery", role = "corridor", x1 = -72, x2 = 30, z1 = -60, z2 = -30, height = 18 },
		{ name = "Maintenance", role = "service", x1 = 30, x2 = 84, z1 = -60, z2 = -30, height = 16 },
		{ name = "BreakRoom", role = "break", x1 = -116, x2 = -72, z1 = -30, z2 = 0, height = 15 },
		{ name = "Reception", role = "reception", x1 = -72, x2 = 30, z1 = -30, z2 = 0, height = 20 },
		{ name = "Stairwell", role = "stair", x1 = 30, x2 = 84, z1 = -30, z2 = 0, height = 21 },
		{ name = "LoadingBay", role = "service", x1 = 30, x2 = 84, z1 = 0, z2 = 34, height = 16 },
	}
	-- Every link is an actual opening in the shared wall, never a teleport.
	-- open = wide un-doored opening; booth = acoustic door; short = Last Call shutter.
	local links: { Link } = {
		{ "IsolationWest", "MasteringSuite", "booth" },
		{ "MasteringSuite", "TapeArchive", "normal" },
		{ "TapeArchive", "IsolationEast", "booth" },
		{ "MasteringSuite", "ViewingGallery", "normal" },
		{ "TapeArchive", "ViewingGallery", "normal" },
		{ "IsolationDrums", "ViewingGallery", "booth" },
		{ "ViewingGallery", "ServiceGallery", "normal" },
		{ "ViewingGallery", "LiveHall", "open" },
		{ "ServiceGallery", "LiveAnnex", "normal" },
		{ "ControlA", "LiveHall", "normal" },
		{ "ControlB", "LiveHall", "normal" },
		{ "LiveHall", "LiveAnnex", "open" },
		{ "LiveHall", "MachineRoom", "normal" },
		{ "ControlA", "ControlB", "normal" },
		{ "LiveAnnex", "MachineRoom", "normal" },
		{ "ControlB", "StaffPassage", "short" },
		{ "LiveHall", "StaffGallery", "open" },
		{ "MachineRoom", "Maintenance", "normal" },
		{ "StaffPassage", "StaffGallery", "normal" },
		{ "StaffGallery", "Maintenance", "normal" },
		{ "StaffPassage", "BreakRoom", "normal" },
		{ "StaffGallery", "Reception", "open" },
		{ "Maintenance", "Stairwell", "normal" },
		{ "Reception", "Stairwell", "normal" },
		{ "BreakRoom", "Reception", "normal" },
		{ "Stairwell", "LoadingBay", "normal" },
	}
	return rooms, links
end

return StudioLayout
