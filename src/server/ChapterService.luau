--!strict
-- Runs the chapter being played: each round resets the toolkit (Chapters/Kit) and starts the
-- chapter's module, which sets up its objectives, shocks and story. The round loop tells it when
-- players are caught, leave or escape.
--
-- Adding a chapter: write Chapters/<Name>.luau with `id`, `requires` (the objective parts it
-- needs from the map) and `start()`, list it in CHAPTERS below and in Config.CHAPTERS.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Kit = require(script.Parent.Chapters.Kit)
local MapContract = require(script.Parent.MapContract)
local Studio1 = require(script.Parent.Chapters.Studio1)

type Chapter = {
	id: string,
	requires: { string },
	start: () -> (),
	onCleared: (() -> ())?,
}

local CHAPTERS: { [string]: Chapter } = {
	studio1 = Studio1 :: Chapter,
}

local ChapterService = {}

local current: Chapter = Studio1 :: Chapter

-- The chapter to play: `wanted` if it exists and belongs to `mapId`, otherwise that map's first.
function ChapterService.pick(mapId: string, wanted: unknown): string
	local first: string? = nil
	for _, entry in Config.CHAPTERS do
		if entry.map == mapId then
			first = first or entry.id
			if entry.id == wanted and CHAPTERS[entry.id] then
				return entry.id
			end
		end
	end
	return first or Config.CHAPTERS[1].id
end

-- The objective parts a chapter needs that `layout` doesn't have (empty when the map is ready).
function ChapterService.missing(layout: MapContract.Layout, chapterId: string): { string }
	local chapter = CHAPTERS[chapterId]
	local list: { string } = {}
	if chapter then
		for _, name in chapter.requires do
			if not layout.objectives[name] then
				table.insert(list, name)
			end
		end
	end
	return list
end

function ChapterService.init(layout: MapContract.Layout, chapterId: string, hooks: Kit.Hooks)
	current = CHAPTERS[chapterId] or Studio1 :: Chapter
	Kit.init(layout, hooks)
end

function ChapterService.chapterId(): string
	return current.id
end

function ChapterService.startRound()
	Kit.reset()
	current.start()
end

-- Returns true when this escape carried the cassette out (the chapter is cleared).
function ChapterService.onEscape(player: Player): boolean
	local carriedOut = Kit.onEscape(player)
	if carriedOut and current.onCleared then
		current.onCleared()
	end
	return carriedOut
end

function ChapterService.onLost(player: Player, position: Vector3)
	Kit.onLost(player, position)
end

function ChapterService.cleared(): boolean
	return Kit.cleared()
end

return ChapterService
