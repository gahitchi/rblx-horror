# Dead Air — physical desk-cover hiding prototype

**Build:** `0.8.9-desk-cover`  
**Branch:** `chatgpt/integrated-v1`  
**Status:** source integrated; Roblox Studio validation required.

## Reason for redesign

In the first actual playtest, the Engineer could look for a player who hid
in a locker but did not reliably catch them. The search handler was
**releasing discovered players and starting a second chase**, allowing an
escape even after the successful hiding-spot inspection. The generated
map also had seven large, scattered rectangular wardrobes and lockers
that felt more like generic horror props than a believable working studio.

The goal is closer to *R.E.P.O.*: crouching behind / under ordinary furniture
is natural to the environment. It must be risky, not a special invulnerability
box. The 1987 studio has service desks, a staff table and a receptionist's
counter where someone could plausibly duck out of sight.

### The six actual hiding surfaces

| Room | Real cover | Why it belongs |
| --- | --- | --- |
| Reception | Reception counter | Booking-diary working desk, with an open knee space |
| Break room | Staff table | Ordinary seating table, memorial programme still on top |
| Tape archive | Sorting worktable | Used to examine cards/reels; shelves remain accessible |
| Control B | Editing desk | Existing editor's tabletop, now with opaque rear modesty panel |
| Live room | Music/score worktable | At the quiet outer edge of tracking activity |
| Service passage | Technician's maintenance desk | Near machine room, clear of the instrument load-in path |

Generated `Workspace.Map.HidingSpots` now contains **six invisible,
noncolliding `Kind = "underdesk"` markers**. Every new tabletop and
back panel is a real opaque, collidable/raycastable part (unlike old
decorative phantoms). The front is open rather than covered by a locker
door. The original 23 rooms, 30 connections, diary, programme, reels,
safe, chapter triggers and console puzzle remain unchanged.

### How it plays

1. Approach a real worktable and hold **E** on **Get under / Desk**.
2. The server moves and anchors the player in the table bay, sets a
   temporary seated/crouched humanoid pose, marks `Hiding` and offers
   breath control. The existing touch **Step out** button also works.
3. Open-front desks muffle movement **less** than lockers
   (`Config.HIDE.DESK_MUFFLE = 0.72` vs the old `0.35`).
4. Hold **Space** to limit breathing near the Engineer. Running out
   of breath still produces a gasp the Engineer may investigate.
5. Press **E / Step out** to leave toward the open desk front.
6. The Engineer can choose to inspect a table from credible nearby
   sounds; if he has **confirmed seeing someone at that desk** within
   roughly 2.5 seconds of entry and about 9 studs of their last
   seen position, he deliberately approaches that desk's entrance.
7. Only an actual inspection can reveal the occupant.
   **If he reaches and inspects an occupied desk, the catch is immediate.**
   He no longer releases the player and restarts a separate chase.

Existing hand-authored maps with `locker` / `wardrobe` spots still
work under the old contract. The new furniture system is introduced
to the generated 1987 map first; it doesn't break older map imports.

### Fairness requirements

- No tracking every hidden player's actual location.
- No choosing a desk based on whether the player is inside.
- A recently confirmed line-of-sight observation is a legitimate
  reason to check where the person just ducked.
- If the Engineer didn't see or hear a player enter, he can miss them.
- Other non-occupied desk checks remain possible: no perfect AI knowledge.
- Hiding is **not immunity from a completed search**.
- Cover has physical geometry that must block sight and movement
  appropriately; it is not a ghost rectangle.
- A player may still attempt to leave before the Engineer checks;
  outside the desk their normal vision/footstep rules apply.

### Quality limits

The current system is a **scripted enter-under-desk interaction**, not
yet a freeform REPO-style crouch/crawl physics system. The seated/crouched
avatar pose is a first implementation and must be checked on the real
Roblox R15/R6 avatar, especially camera height, limbs intersecting
the tabletop and the exit teleport. Geometry remains native Parts with
some square corners; meshes/material variants and dimensional polish
can follow the same isolated, room-by-room art process as the mixing
console once gameplay and lighting are stable.

### Test immediately in Studio

Update the **Match** Rojo session from the branch, reconnect/sync, then
press Play on a fresh Baseplate. The startup should identify
`0.8.9-desk-cover`.

1. **Reception desk:** hold E to Get under. Check camera height, avatar
   posture, front opening, diary position and Step out E/touch.
2. **Control B:** inspect editing tabletop and rear panel. Check that
   the Engineer's line of sight is blocked by the panel, not by an
   invisible game flag alone.
3. **Quiet hide:** enter unseen, no recent noise. The Engineer must not
   magically know the occupied desk.
4. **Witnessed hide:** let him see you, then get under a nearby desk.
   His Output should show `watched ... get under cover; checking ...`.
   If he walks to its entrance and completes the inspection, Output
   should show `caught ... under cover` and the normal caught/echo flow.
5. **Breath test:** hide with the Engineer nearby, hold Space, then
   release and wait. Gasp or breathing should attract a plausible search.
6. **Escape timing:** step out before he arrives. You should be able
   to escape, but ordinary vision and pursuit must apply immediately.
7. **Scene coherence:** verify no office table blocks a doorway or
   Last Call path; inspect the old locker locations and confirm the
   giant rectangular lockers are gone.
8. **Multiplayer:** enter a table while occupied; the second player
   should be refused. Exit, re-enter, die, restart the round and confirm
   prompt reuse and absence of stale occupant memory.

The developer-only `tools/studio/DeskCoverSelfTest.server.luau`
checks the generated model's markers, prompts and opaque table panels
when run from Studio's **Server Command Bar** during a private test.
`tools/integration/check_integration.py` checks the source-side
contracts. Neither proves real pathfinding or final avatar animation.

## Log notes from the first Studio playtest

- `[Dead Air] server running, v0.8.8-readable-lighting` confirms
  the prior lighting build was actually launched.
- Engineer Roam → Listen → Hunt → lost/search → lunge → catch traces
  confirm those major state transitions ran, **not** that every search
  or hiding case was correct.
- `DataStore unavailable; progress lasts this session only` is a
  normal local Studio limitation without enabled API access.
- `rbxassetid://203785492 failed ... Asset type does not match requested
  type` is a separate asset-type warning; not evidence of a hiding
  script failure. Its precise source has not been identified yet.
