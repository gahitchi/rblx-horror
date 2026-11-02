# Chapter 1 — opening ten minutes: quiet dread

Source: `src/server/Chapters/StudioTension.luau` added on `chatgpt/studio-v2`.
This is a restrained **sound staging** pass, not an encounter overhaul.
Everything remains compatible with the chapter 1 objective order and original
monster AI. The recordings are still placeholder Roblox sound IDs.

## Intended player experience

The recording house must feel inhabited by memory without feeling like an
arcade of jumpscares. A crew should understand the ordinary business (the
reception, session log, archive, booths) before the night becomes impossible.
The opening asks players to listen, not watch a forced cutscene.

| Earliest elapsed | Existing or new | Beat | What the player understands |
| --- | --- | --- | --- |
| 0:00 | Existing | Quarantine lock slams and distant foghorn | Entry is deliberate; outside is unreachable |
| 0:03 / 0:09 | Existing | Handler identifies the diary | The room is a real business, with a clear first objective |
| 0:15 | Existing | The Engineer appears; its director grants initial grace | Something is already inside, but immediate chase isn't forced |
| 0:25 | New, when in Reception | A dry old door/latch tick | Even the lobby doesn't feel fully empty |
| 0:45 | New, when in Control A | A muted tape transport click from Mastering | The analogue equipment has an unsettling presence |
| 1:15 | New, when in Tape Archive | A soft slipping-tape sound in the adjoining room | Sound crosses boundaries; the shelves are a search, not a safe zone |
| 1:50 | New, when in Sound Lock | A small radio crackle through the viewing area | The studio's communications are unreliable |
| 2:35 | New, when in Live Hall | A faint hum from the isolated vocal booth | The room has a musical memory, not a monster jumpscare |
| 3:10 | New, when in Service Hall | Low electrical buzz | The naval alterations feel separate from the warm recording wing |
| ~1–2 min and later | Existing | Infrequent 1987 broadcast fragments | The past sometimes interrupts the handler's radio |
| Every ~45–95 s | Existing | Thumps behind the barricaded flat | The later chapter is present without becoming playable |
| First reel or 9:00 fallback | Existing | First shock: studio lighting wakes | The stakes escalate because of progress or a long stall |

The new beats are **earliest opportunities**, not mandatory timestamps.
A player who never visits a location simply misses its cue. Each new sound
only plays the first time its room is visited after the threshold. At most
four new cues can occur per round, separated by at least 45 seconds.
The sequence ends when the first shock fires, Last Call starts, the round
ends, or ten minutes pass. It cannot emit player noise or reposition the
Engineer; the existing footsteps, mimicry, radio and shocks are unchanged.

## What we deliberately did not add

- No scripted jumpscares, sanity meter, artificial AI awareness, forced
  chase, sudden permanent power loss or impossible objectives
- No new Room/Objective/Marker requirements or MapContract revisions
- No expensive area triggers or extra generated geometry
- No assumption that actual audio is finalized; `Sounds.luau` IDs remain
  placeholders requiring licensed sounds and in-Studio audition

## Offline review and next playtest

Source-level checks are enough to review **wiring and intended timing** but
cannot confirm acoustic audibility or AI behaviors in Roblox.

In the first Studio run on the 0.7.6 branch build:

1. Start in Reception and confirm the lock slam/handler audio plays and the
   Engineer can still arrive through its existing logic.
2. Stay in Reception for ~30 sec and check a *single* quiet cue. Enter
   Control A after ~45 sec for the muted tape transport.
3. Search the archive and listen near the Sound Lock and Live Hall. There
   must be no repeat spam, visible model motion or added prompt.
4. Load a reel early. Once the first shock fires, remaining ambient cues
   should cease and the studio lighting should wake normally.
5. Trigger a round restart or finish and confirm sounds from the
   previous round do not continue scheduling.
6. Play on speakers/headphones at mobile volume; reject cues that
   sound artificial or obscure teammate callouts.

If the placeholders sound poor, swap their corresponding values in
`src/shared/Sounds.luau` with licensed, Roblox-accessible audio instead of
adding more loud events.
