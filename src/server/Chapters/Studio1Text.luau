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
Text.DIARY = [[WRENMOUTH RECORDING HOUSE / BOOKINGS
(cover: tea stain, dates filled in by hand)

12 Oct  St Brannoc's choir. Christmas rehearsals.
20 Oct  Harbour Lads. Two days, bring their own amplifier.

26 Oct - 1 Nov  PRIVATE. Do not book.
(the word PRIVATE is written over twice)

2 Nov  LAST SESSION. Control room A.
R. insists the session log stays beside the mixing desk.

3 Nov  Wrenmouth Late Night, 11:30 pm.
Cassette collected by the radio station.
(a small heart is drawn in the margin)]]

Text.LOG_TITLE = "Session log, 2 November 1987"

-- `numbers` are the three reels' catalogue numbers; `inputs` the desk inputs for tracks A, B and C.
function Text.log(numbers: { string }, inputs: { number }): string
	return string.format(
		[[CONTROL ROOM A / 2 NOVEMBER 1987
R.'S PERSONAL SESSION LOG

I have finally cleaned the recording. Three separate reels: no single
one carries the whole thing. Do not make a combined dub without me.

REEL A      %s
REEL B      %s
REEL C      %s

MIXDOWN / AFTER THE MASTER DESK LOSES ITS NORMAL PATCH
Track A -> Input %d
Track B -> Input %d
Track C -> Input %d

TRANSPORT THREADING (SUPPLY TO TAKE-UP)
Supply reel > Tension arm > Erase head > Record head >
Play head > Capstan > Take-up reel.

She is under the choir recording. The same alto line.
I made the edit three times. It does not go away.

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
Text.PROGRAMME = [[ST BRANNOC'S CHURCH, WRENMOUTH
Order of service for E.

LOST AT SEA: 3 NOVEMBER 1979

Hymn: Eternal Father, Strong to Save
Reading: the harbour master
Music: St Brannoc's choir

"She sang the alto line with us every Christmas.
We will keep her place."

On the folded back page, a note from R.:
"Six figures on my desk safe. Day, month, year.
I have never had the heart to change them."]]

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

-- Ordinary archive labels and card entries have to agree exactly.
function Text.cardOrdinary(number: string, title: string, shelf: string): string
	return string.format("%s   %s   >  SHELF %s", number, title, shelf)
end

-- Optional background documents: never an objective and never a random answer.
-- Each is attached to a named, non-colliding physical note in StudioEvidenceDetail.
Text.EVIDENCE = table.freeze({
	table.freeze({
		id = "MachineServiceCard", label = "Service card", title = "Tape transport / service card",
		body = [[WORKSHOP SERVICE CARD / CONTROL A
2 November, afternoon. Transport taken out of service.

Belt perished. Pinch roller removed. Replacement kit left in
the staff break-room cupboard after the lunchtime inspection.

R. refused to have anyone else thread the tape.
He left the full guide sequence in his session log.]],
	}),
	table.freeze({
		id = "ArchiveFilingSlip", label = "Filing instructions", title = "Archive / drawer W filing instructions",
		body = [[RECORDS ROOM / DRAWER W
File by catalogue number, not session title.

The original number stays on each physical reel.
If a reel has been lent to a room, keep its card in this drawer
and write the destination in the margin.

Returned reels belong on their numbered shelves.
The index is the authority; don't trust old pencil stickers.]],
	}),
	table.freeze({
		id = "LiveCaseTag", label = "Borrowing slip", title = "Live room / borrowing slip",
		body = [[EQUIPMENT LOAN / 2 NOVEMBER
R. borrowed one multitrack reel for the live room.

Road case under the instrument stack.
Return to the machine after the session.
The drummer left the case buried under stands and amplifiers.

A pencilled warning:
"Moving that stack is going to wake the whole building."]],
	}),
	table.freeze({
		id = "RoutingNotice", label = "Routing sheet", title = "Control A / patch-bay notice",
		body = [[CONTROL ROOM A / PATCH BAY
The normalled routing carries a session until the desk loses signal.

If the normal path fails: connect A, B and C to the desk inputs
listed in R.'s session log. Keep each track on its own input.

Never patch by guessing. A misrouted line feeds back through
the live-room monitors.]],
	}),
	table.freeze({
		id = "QuarantineIntake", label = "Incident record", title = "Navy / intake record 27",
		body = [[WRENMOUTH / NAVY QUARANTINE ORDER 27
3 November 1987

Recording house secured after the late-night broadcast.
No personnel are to enter the upper residence.
The basement and service lift are to remain sealed.

An unsigned note has been written below the order:
"Equipment still turning. Do not disconnect the speakers."]],
	}),
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
