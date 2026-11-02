# Chapter 1 — the 1987 evidence trail

**Build:** 0.8.3-evidence-pass  
**Branch:** `chatgpt/integrated-v1`  
**Status:** integrated source; waiting for Roblox Studio / mobile visual testing

## Design principle

A puzzle should look like an ordinary task in an operating recording studio
before its sinister purpose becomes clear. Written clues are physically located
near the relevant equipment. The narrative is learned by reading, not by
unavoidable exposition or loading screens.

We keep a quiet first act: a real family business, a specific final recording,
and increasingly unusual instructions from the Engineer. The navy's quarantine
must feel like a response to the broadcast rather than the studio's original
purpose.

## Discoverable route

| Stage | What the crew sees | What the crew learns | What changes |
| --- | --- | --- | --- |
| Reception | Booking diary dated 1987 | R.'s last session was in Control A on 2 November; late-night radio delivery was arranged for the following day | Objective now points to the session log |
| Control A | Handwritten session log | Three unique catalogue numbers, the seven-step tape path and the per-round routing for tracks A/B/C | Objective expands to repairing the machine and finding reels |
| Transport | Optional service card pinned on Control A's north wall | Replacement belt and pinch roller are in the staff break room | Optional confirmation, not a prerequisite |
| Archive | Drawer W card index and optional filing slip | Physical reel numbers correspond to index numbers; the active master is on one particular shelf | Unique Reel A becomes distinguishable |
| Live room | Optional borrowing slip attached to road case | Reel B was lent for the last session, and equipment has been stacked on top | Clutter must be moved, causing noise |
| Break room | Original memorial programme | E. died at sea on 3 November 1979; a note from R. establishes the six-digit day-month-year safe convention | The safe combination is deducible without guessing |
| Control B | R.'s desk safe | The memorial date opens it; Reel C is inside | Wrong guesses still make noise / temporarily jam the dial |
| Control A | Optional patch-bay notice | A/B/C must be routed from the session log, rather than guessed | The patch puzzle becomes relevant after shock two |
| Public wing | Optional 1987 navy intake order | The radio broadcast preceded the sealing of the upper residence, basement and service lift | Builds history; no new required objective |
| Finale | Mixing desk, evidence cassette, front door | These recordings were deliberately separated; dubbing them is dangerous | Existing Last Call escape remains unchanged |

The notebook captures all core papers plus up to five optional records.
**Only discovered pages** are stored, and they reset on a new round. No
undiscovered safe code, shelf location or randomly assigned patch routing
is displayed by the notebook or these supplementary props.

## World objects added

Five paper props are generated in `Workspace.Map.Props.RecordedEvidence`:
`MachineServiceCard`, `ArchiveFilingSlip`, `LiveCaseTag`,
`RoutingNotice`, `QuarantineIntake`. They are wall- or case-mounted,
noncolliding parts using ordinary Roblox materials. They have unique names.
The chapter installs temporary `Read` prompts only when the objects exist.
Older / manually built maps still work without them.

The authoritative text is in `Studio1Text.EVIDENCE`. Each read uses
`Kit.document` and the normal `Remotes.Document` event, so it appears in
the existing Chapter UI and becomes available in the field notebook.

The two other main story dates remain constant:

- **3 November 1979:** E. is lost at sea.
- **2 November 1987:** last studio session.
- **3 November 1987:** late-night radio broadcast and subsequent navy closure.

The safe still uses `031179` (DDMMYY). The three reel numbers and the
patch inputs still randomize every round.

## Integrity improvements

- The archive index and the **physical decoy reels** now use the **same**
  unique catalogue numbers and shelf labels. Extra catalog entries use
  existing numbered shelves, not nonexistent shelf numbers.
- Picking up A, B or C when the character is already carrying a hand
  item no longer consumes the original reel or awards extra XP. The road
  case and safe only mark themselves cleared after successful acquisition.
- Threading guides visually reset after an incorrect click; players can
  clearly restart the sequence.
- On-screen objectives are staged by discovery: diary, then session log,
  then transport/reels. Exploration itself is not gated.
- The notebook can retain twelve documents, sufficient for the four
  core texts and five optional sheets.

## Review / mobile playtest priorities

1. Verify the player can walk to all five new notes and see distinct
   `Read` prompts. Ensure the card by the road case does not obscure
   the `Open` prompt.
2. Read the booking diary first and verify the objective switches to
   Control A; read the log and verify equipment/reels appear next.
3. On multiple rounds, compare all archive decoy reel numbers against
   their index cards. No letter-A catalog number should be duplicated.
4. Hold spare parts while attempting all three reel pickups. The
   active reel should remain in place, safe/case should not be consumed,
   and finding XP should only be awarded once.
5. Read the programme, enter the six-digit memorial date, then confirm
   no brute-force guess is required.
6. Wrong threading sequence must reset all highlighted guide buttons,
   while the server's existing noise effect still applies.
7. Reopen all core and optional records in the notebook; restart and
   ensure the previous round's reel/patch identifiers are gone.
8. Confirm the three acoustic shocks, the Engineer, and Last Call still
   behave as before. Judge readability and prompt overlap in Studio.

**Offline validation limitations:** Luau runtime, actual camera placement,
pathfinding, prompt distances, collision and mobile layout were not tested.
