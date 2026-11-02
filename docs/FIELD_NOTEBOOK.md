# Dead Air — field notebook (first-play clarity pass)

**Source:** `src/client/NotebookUi.luau`, started from
`src/client/Main.client.luau`. This is a **match-place** UI only.
It does not modify the hub, the studio map, the monster, prompts,
round scoring or any existing puzzle interaction.

## Design goal

The studio's story is in real documents and radio calls, not in
automatic map markers. However, players originally had to remember a
log's numbers, the patch-bay assignments and the memorial date even
after closing the paper. Meanwhile, useful handler dialogue and
broadcast lines disappeared from screen quickly.

The notebook gives players a way to check **only information they
already discovered**, including when sound is muted. It helps teams
without turning the horror experience into a GPS quest list.

## Layout — small-screen first

```text
                    ┌─────────────────────────────┐
                    │ NOTES [J]                   │
                    └─────────────────────────────┘

          ┌──────────────────────────────────────┐
          │ FIELD NOTEBOOK                  Close │
          │                                      │
          │ CURRENT TASK                         │
          │ Read the diary at reception.         │
          │                                      │
          │ [FOUND PAPERS]      [RADIO LOG]       │
          │ ──────────────────────────────────── │
          │ SESSION LOG, 2 NOVEMBER 1987         │
          │ ...contents already read...          │
          │                                      │
          │ BOOKING DIARY, 1987                  │
          │ ...contents already read...          │
          │                                      │
          │  (scroll for earlier entries)        │
          │                                      │
          │ Only clues you've encountered...     │
          └──────────────────────────────────────┘
```

The mobile panel scales **by available screen space** rather than
shrinking all text with a UIScale. Maximum size is 560 x 600 pixels.
It uses legible monospaced type and paper/amber on charcoal, consistent
with the existing Chapter UI. Controls: **J** on keyboard, a small
**NOTES [J]** touch button at the top right, and **Close**.

## Rules and constraints

1. **Found papers** contains documents delivered via the existing
   server-to-client `Remotes.Document`: booking diary, session log,
   card index and memorial programme. Documents only enter the list
   after this particular player opens them in-game.
2. **Radio log** contains text already sent via `Remotes.Radio`, such
   as handler instructions and the 1987 broadcast. It is not a
   transcription of machine noises, footfalls, voice chat or teammates.
3. The current objective is taken from the authoritative
   `RoundState.ObjectiveText`, not inferred by a local hint system.
4. At most **8** discovered papers and the latest **16** received
   radio messages are retained. The client keeps them **in memory
   only** for the current round. No DataStore, RemoteEvent or
   networking changes were introduced.
5. The notebook resets when the next round enters the Playing phase,
   ensuring a previous round's random reel identifiers, safe code
   and patch assignments cannot be consulted.
6. The notebook automatically closes before a document/puzzle opens.
   It does not open while a chapter puzzle is on screen. It is hidden
   outside active play; it cannot reveal documents to spectators
   or players who haven't interacted with them.
7. The underlying `ChapterUi` retains control over the actual
   read, rethread, safe, patch and fader puzzles. The server still
   verifies every action.

## User journey

- Enter the recording house and find the **booking diary**. Its
  original reading panel opens. After putting the paper down, press J
  and the discovered page is retained.
- Read the **session log** in Control A. Its randomly generated reel
  catalogue numbers and patch information are now in Found Papers.
- Follow **handler radio**. If a hint was missed, open Radio Log and
  reread the written call. A broadcast fragment becomes a saved
  textual fragment, but cannot be generated on demand.
- Travel to another room without returning to the original desk just
  to recheck a number. The Engineer still hunts normally; the
  notebook does not pause the round.
- A subsequent round starts with an empty notebook.

## First playtest checklist

- Solo and 2-player: each player sees **only** their own discoveries.
- First-person keyboard J can open/close the notebook; Close releases
  mouse lock and restores it on close. Mobile button remains tappable.
- Open a diary, close it, walk away and find the page in the notebook.
- Open no log in a fresh round and verify its contents are **not**
  already available.
- Receive radio instructions and verify they appear in Radio Log;
  check that later entries evict the oldest after 16.
- Start a new round. Verify both lists reset and no old safe code,
  reel number or patch map remains.
- Open a puzzle while reading the notebook: the puzzle must take
  priority. Check no conflicting modal input on a phone.
- Observe readability on small screens (320–390 px wide) and check
  that the objective title, tabs, long log lines and scroll work.

**Validation:** source-level review only. Roblox Studio rendering,
modal mouse capture, mobile touch targets and physical gameplay are
still untested.
