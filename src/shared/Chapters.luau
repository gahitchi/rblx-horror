--!strict
-- The story's chapters in order (Config.CHAPTERS) and who may play which. The story is played in
-- order: a chapter is unlocked when the one before it has been cleared, and lobbies are strict
-- (everyone in a lobby must have its chapter unlocked). A player's cleared chapters travel as the
-- "ChaptersCleared" attribute: chapter ids separated by commas.

local Config = require(script.Parent.Config)

local Chapters = {}

export type Entry = { id: string, map: string, number: number, name: string }

function Chapters.list(): { Entry }
	return Config.CHAPTERS :: any
end

function Chapters.find(id: unknown): Entry?
	for _, entry in Config.CHAPTERS do
		if entry.id == id then
			return entry :: any
		end
	end
	return nil
end

function Chapters.name(id: unknown): string
	local entry = Chapters.find(id)
	return if entry then string.format("%d. %s", entry.number, entry.name) else tostring(id)
end

-- The cleared chapters from the attribute text.
function Chapters.parse(text: unknown): { string }
	local list: { string } = {}
	if type(text) == "string" then
		for id in string.gmatch(text, "[^,]+") do
			table.insert(list, id)
		end
	end
	return list
end

function Chapters.clearedBy(player: Player): { string }
	return Chapters.parse(player:GetAttribute("ChaptersCleared"))
end

-- Whether `id` is unlocked given the chapters already cleared.
function Chapters.unlocked(cleared: { string }, id: string): boolean
	for index, entry in Config.CHAPTERS do
		if entry.id == id then
			if index == 1 then
				return true
			end
			return table.find(cleared, Config.CHAPTERS[index - 1].id) ~= nil
		end
	end
	return false
end

-- The first chapter not yet cleared (or the last one, when everything is cleared).
function Chapters.nextFor(cleared: { string }): string
	for _, entry in Config.CHAPTERS do
		if not table.find(cleared, entry.id) then
			return entry.id
		end
	end
	return Config.CHAPTERS[#Config.CHAPTERS].id
end

-- Every unlocked chapter, in story order.
function Chapters.unlockedList(cleared: { string }): { Entry }
	local list: { Entry } = {}
	for _, entry in Config.CHAPTERS do
		if Chapters.unlocked(cleared, entry.id) then
			table.insert(list, entry :: any)
		end
	end
	return list
end

return Chapters
