--!strict
-- Chapter 1's words: the handler's radio lines, the 1987 broadcast bleeding through the walkies,
-- the documents players read, and the optional tapes. Kept apart from the logic so they're easy to
-- rewrite. Names are placeholders: the engineer signs "R.", his wife is "E.".
--
-- Story facts these follow (design doc, "Story" and "The rules of the sound"):
--   * E. drowned on 3 November 1979. The broadcast went out on the anniversary, 3 November 1987.
--   * The last session was the night before, 2 November, in control room A.
--   * He split the cleaned sound across three reels so no single reel carried it whole.

local Text = {}

Text.RADIO = table.freeze({
	arrival = "Locks slammed? That's the building waking up. Your headsets are tuned, so keep them on.",
	arrival2 = "Dad kept a booking diary on the front desk. Start there.",
	logRead = "That log's in his hand. The card index in the archive will tell you where each reel lives.",
	machineBroken = "His tape path's gone. There were always spare parts in the break room cupboard.",
	machineFixed = "Good. Now the reels. Load them one at a time, and be ready: they play out loud.",
	shock1 = "Every lamp in there just came on. Nothing's had power in that building for thirty-nine years.",
	shock1Stalled = "The lamps are coming on by themselves. It's getting closer out there. You need to move.",
	shock2 = "I lost you for a second. The whole building screamed. If the desk's dead, patch it by hand. His notes say how.",
	patched = "That's signal. When all three reels are in, hold the desk. It plays through every speaker, and it will hear.",
	dubStart = "Ride the faders. Keep it steady. Whatever happens, don't let go.",
	lastCall = "The locks are open. Run. Bring me that tape.",
	cleared = "You got it out. Thirty-nine years. Thank you.",
})

Text.BROADCAST = table.freeze({
	"...three minutes to midnight here on Wrenmouth Late Night...",
	"...tonight's for Mum. Dad made something for all of us...",
	"...if you're still awake out there, turn it up...",
	"...listen. Can you hear her?...",
	"...keeping you company till the fog lifts...",
})

Text.DIARY_TITLE = "Booking diary, 1987"
Text.DIARY = [[12 Oct  St Brannoc's choir. Christmas rehearsal tapes.

20 Oct  Harbour Lads. Work songs, two days.

26 Oct to 1 Nov  PRIVATE. Do not book.
(written over twice in heavy pen)

2 Nov  LAST SESSION. Control room A. Log stays on the desk.

3 Nov  Late Night, 11:30 pm. Cassette to the radio station.
(a small heart drawn next to it)]]

Text.LOG_TITLE = "Session log, 2 November 1987"

-- `numbers` are the three reels' catalogue numbers; `inputs` the desk inputs for tracks A, B and C.
function Text.log(numbers: { string }, inputs: { number }): string
	return string.format(
		[[Cleaned at last. Split across three reels so no single tape carries it whole.
NEVER PLAY THEM TOGETHER. (underlined three times)

Reel A   %s
Reel B   %s
Reel C   %s

Mixdown patch:  TRACK A > INPUT %d    TRACK B > INPUT %d    TRACK C > INPUT %d

Threading, as always: supply reel, tension arm, erase head, record head, play head,
capstan, take-up reel.

She's under it. Humming the alto line, like at Christmas. I'm not imagining it.
- R.]],
		numbers[1],
		numbers[2],
		numbers[3],
		inputs[1],
		inputs[2],
		inputs[3]
	)
end

Text.PROGRAMME_TITLE = "Order of service"
Text.PROGRAMME = [[St Brannoc's Church, Wrenmouth

A service of remembrance for E.
Lost at sea, 3 November 1979

Hymn: Eternal Father, Strong to Save
Reading: the harbour master
Music: St Brannoc's choir

"She sang with us every Christmas. The alto line will never be the same."]]

Text.CARD_TITLE = "Card index, drawer W"

-- Other recordings in the same drawer, for the decoy cards.
Text.DECOY_TITLES = table.freeze({
	"St Brannoc's choir, carols 1983",
	"Harbour Lads, demos",
	"Lifeboat appeal, radio advert",
	"Wedding: Pryce and Hollis",
	"Brass band, Whitsun 1985",
	"Late Night station idents",
	"Organ recital, St Brannoc's",
	"Primary school nativity 1986",
	"Council fog signal test",
	"Ferry announcements",
	"Folk night at the Anchor",
	"Gull recordings, west cliffs",
	"Choir, Easter 1981",
	"Cannery safety talk",
})

-- The three reels' cards.
function Text.cardArchive(number: string, shelf: string): string
	return string.format("%s   Session, 2 Nov 1987, reel A   >  SHELF %s", number, shelf)
end
function Text.cardRoadCase(number: string): string
	return string.format(
		"%s   Session, 2 Nov 1987, reel B   >  ON LOAN: live room, in the road case",
		number
	)
end
function Text.cardSafe(number: string): string
	return string.format(
		"%s   Session, 2 Nov 1987, reel C   >  WITHDRAWN. Kept by R. (desk safe, control B)",
		number
	)
end

-- The order the tape runs through the machine (also in the session log).
Text.THREAD_ORDER = table.freeze({
	"Supply reel",
	"Tension arm",
	"Erase head",
	"Record head",
	"Play head",
	"Capstan",
	"Take-up reel",
})

-- The optional tapes live in src/shared/StoryTapes.luau (the hub's tape deck plays them too).

return Text
