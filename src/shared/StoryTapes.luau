--!strict
-- Every story tape, so both places can use them: the match place spawns the optional ones, and the
-- hub's tape deck (in the handler's van) plays back the ones a player has recovered.
--
--   * evidence: the cassette a chapter is cleared with, and what the handler makes of it. It's what
--     sends the crew back in for the next chapter (the story's unlocks come from the tapes).
--   * optional: townspeople's tapes found in a chapter and pushed through the mail slot.
--
-- Bodies describe what's on the tape. Names are placeholders: the engineer signs "R.", his wife "E.".

export type Tape = {
	id: string,
	chapter: string,
	kind: string, -- "evidence" or "optional"
	title: string,
	body: string,
}

local StoryTapes = {}

StoryTapes.LIST = table.freeze({
	table.freeze({
		id = "studio1_evidence",
		chapter = "studio1",
		kind = "evidence",
		title = "The last session (the cassette)",
		body = [[(Played through the filter rack in the van: the complete sound is never heard unfiltered.)

Tape hiss, then a low tone that rises and falls like slow breathing. Under it, very faint, a woman hums the alto line of a carol. It doesn't sound recorded. It sounds close.

At the end, the engineer's voice, tired: "Navy wants the clean copy downstairs by Friday. They think it's a submarine. It isn't."

THE HANDLER: Navy. Dad told us the men in the basement that autumn were fixing the damp. There's a stairwell down in that building with the navy's seal on it... I'm bringing bolt cutters.]],
	}),
	table.freeze({
		id = "studio1_choir",
		chapter = "studio1",
		kind = "optional",
		title = "Choir rehearsal, December 1978",
		body = [[A church choir warming up, someone laughing at a wrong note. Under everyone, a woman hums the alto line, warm and a little flat. The engineer, close to the microphone: "Again from the top, love. That was lovely."]],
	}),
	table.freeze({
		id = "studio1_shanty",
		chapter = "studio1",
		kind = "optional",
		title = "Harbour Lads session, October 1987",
		body = [[Fishermen singing a work song, stamping in time. Between takes one of them says: "Your lad was down the cannery till four again. Tell him to get some sleep." The engineer doesn't answer. Under the hiss there is a low tone that isn't in the room.]],
	}),
	table.freeze({
		id = "studio1_jingle",
		chapter = "studio1",
		kind = "optional",
		title = "Wrenmouth Late Night, jingle take 3",
		body = [[A young woman's voice over a cheap synthesizer: "Wrenmouth Late Night. Keeping you company till the fog lifts." Then, off-mic: "Dad, was that all right? ...Dad?"]],
	}),
})

function StoryTapes.find(id: string): Tape?
	for _, tape in StoryTapes.LIST do
		if tape.id == id then
			return tape :: any
		end
	end
	return nil
end

-- A chapter's optional tapes.
function StoryTapes.optional(chapter: string): { Tape }
	local list: { Tape } = {}
	for _, tape in StoryTapes.LIST do
		if tape.chapter == chapter and tape.kind == "optional" then
			table.insert(list, tape :: any)
		end
	end
	return list
end

-- The tapes a player can play back: the evidence of every chapter they've cleared, and the
-- optional tapes they've delivered, in story order.
function StoryTapes.recovered(cleared: { string }, delivered: { string }): { Tape }
	local list: { Tape } = {}
	for _, tape in StoryTapes.LIST do
		local have = if tape.kind == "evidence"
			then table.find(cleared, tape.chapter) ~= nil
			else table.find(delivered, tape.id) ~= nil
		if have then
			table.insert(list, tape :: any)
		end
	end
	return list
end

return StoryTapes
