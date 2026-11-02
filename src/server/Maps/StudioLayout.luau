--!strict
-- Wrenmouth, 1987: a former family recording house with a purposeful tracking wing.
-- Public entry and restrooms are to the south; quiet control/recording rooms north;
-- naval additions and an instrument loading dock occupy the eastern service spine.
-- No generator or fuse gameplay. Every link is a real shared-wall portal.

export type Room = {
	name: string, role: string, x1: number, x2: number,
	z1: number, z2: number, height: number,
}
export type Link = { string }
local StudioLayout = {}

function StudioLayout.make(): ({ Room }, { Link })
	local rooms: { Room } = {
		{ name = "TapeArchive", role = "archive", x1 = -84, x2 = -58, z1 = -134, z2 = -107, height = 15 },
		{ name = "MasteringSuite", role = "control", x1 = -58, x2 = -34, z1 = -134, z2 = -107, height = 14 },
		{ name = "IsolationWest", role = "booth", x1 = -34, x2 = -8, z1 = -134, z2 = -107, height = 14 },
		{ name = "IsolationVocal", role = "booth", x1 = -8, x2 = 18, z1 = -134, z2 = -107, height = 14 },
		{ name = "IsolationDrums", role = "booth", x1 = 18, x2 = 44, z1 = -134, z2 = -107, height = 15 },
		{ name = "MachineRoom", role = "service", x1 = 44, x2 = 80, z1 = -134, z2 = -107, height = 15 },
		{ name = "ControlA", role = "control", x1 = -84, x2 = -34, z1 = -107, z2 = -58, height = 16 },
		{ name = "LiveHall", role = "live", x1 = -34, x2 = 44, z1 = -107, z2 = -58, height = 24 },
		{ name = "ServicePass", role = "corridor", x1 = 44, x2 = 80, z1 = -107, z2 = -58, height = 15 },
		{ name = "LoadingBay", role = "service", x1 = 80, x2 = 110, z1 = -107, z2 = -58, height = 16 },
		{ name = "ControlB", role = "control", x1 = -84, x2 = -34, z1 = -58, z2 = -31, height = 14 },
		{ name = "SoundLock", role = "corridor", x1 = -34, x2 = -10, z1 = -58, z2 = -31, height = 14 },
		{ name = "ViewingGallery", role = "corridor", x1 = -10, x2 = 44, z1 = -58, z2 = -31, height = 16 },
		{ name = "ServiceHall", role = "corridor", x1 = 44, x2 = 58, z1 = -58, z2 = -7, height = 14 },
		{ name = "StaffWC", role = "washroom", x1 = 58, x2 = 80, z1 = -58, z2 = -31, height = 13 },
		{ name = "BreakRoom", role = "break", x1 = -84, x2 = -34, z1 = -31, z2 = -7, height = 15 },
		{ name = "StaffPassage", role = "corridor", x1 = -34, x2 = 8, z1 = -31, z2 = -7, height = 14 },
		{ name = "InnerHall", role = "corridor", x1 = 8, x2 = 44, z1 = -31, z2 = -7, height = 14 },
		{ name = "JanitorCloset", role = "service", x1 = 58, x2 = 80, z1 = -31, z2 = -7, height = 13 },
		{ name = "Reception", role = "reception", x1 = -84, x2 = 8, z1 = -7, z2 = 24, height = 18 },
		{ name = "EntryHall", role = "corridor", x1 = 8, x2 = 62, z1 = -7, z2 = 24, height = 16 },
		{ name = "PublicWC", role = "washroom", x1 = 62, x2 = 80, z1 = -7, z2 = 6, height = 13 },
		{ name = "Stairwell", role = "stair", x1 = 62, x2 = 80, z1 = 6, z2 = 24, height = 19 },
	}
	local links: { Link } = {
		{ "TapeArchive", "ControlA", "normal" },
		{ "MasteringSuite", "ControlA", "normal" },
		{ "TapeArchive", "MasteringSuite", "normal" },
		{ "IsolationWest", "LiveHall", "booth" },
		{ "IsolationVocal", "LiveHall", "booth" },
		{ "IsolationDrums", "LiveHall", "booth" },
		{ "MachineRoom", "ServicePass", "normal" },
		{ "ControlA", "LiveHall", "normal" },
		{ "ControlA", "ControlB", "normal" },
		{ "LiveHall", "SoundLock", "normal" },
		{ "SoundLock", "ViewingGallery", "normal" },
		{ "SoundLock", "StaffPassage", "normal" },
		{ "ViewingGallery", "InnerHall", "normal" },
		{ "LiveHall", "ServicePass", "normal" },
		{ "ServicePass", "LoadingBay", "normal" },
		{ "ServicePass", "ServiceHall", "normal" },
		{ "ServicePass", "StaffWC", "normal" },
		{ "ViewingGallery", "ServiceHall", "normal" },
		{ "ServiceHall", "JanitorCloset", "normal" },
		{ "ServiceHall", "InnerHall", "normal" },
		{ "ControlB", "BreakRoom", "short" },
		{ "BreakRoom", "Reception", "normal" },
		{ "BreakRoom", "StaffPassage", "normal" },
		{ "StaffPassage", "Reception", "normal" },
		{ "StaffPassage", "InnerHall", "normal" },
		{ "InnerHall", "EntryHall", "normal" },
		{ "Reception", "EntryHall", "open" },
		{ "EntryHall", "PublicWC", "normal" },
		{ "EntryHall", "Stairwell", "normal" },
		{ "EntryHall", "ServiceHall", "normal" },
	}
	return rooms, links
end

return StudioLayout
