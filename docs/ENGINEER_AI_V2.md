# The Engineer — intelligent stalking AI, first gameplay pass

**Branch:** `chatgpt/integrated-v1`  
**Build:** `0.8.4-engineer-ai`  
**Status:** source integration only. No Roblox Studio/physics/multiplayer playtest.

## What quality means for this enemy

The Engineer is the studio's former recording engineer, not a supernatural
radar. His senses are exceptional, but **limited to sound and contact**.
He should feel deliberate: pauses to listen, forms a hypothesis, follows
a direction, checks a plausible nearby room, occasionally opens a hiding
spot, and leaves when the evidence runs cold. Surprise should come from
his reasoning and spatial presence, not untelegraphed cheating.

Our primary inspirations are *design methods*, not copied code/assets:

1. **Alien: Isolation** — two-layer architecture: a macro director manages
   pressure and a local agent uses senses. We already have
   `Monster/Director.luau` for grace/retreat/indirect room hints and
   `Monster/Perception.luau` for sound perception. The director does not
   feed exact player coordinates into the hunt.
   Research: https://www.gamedeveloper.com/design/the-perfect-organism-the-ai-of-alien-isolation
2. **The Last of Us Part II** — vague knowledge between ignorance and a
   confirmed target. We use imperfect sound estimates, brief track memory
   and movement direction rather than magically tracking the player.
   Research: https://www.gamespot.com/articles/the-last-of-us-2s-enemy-ai-is-getting-a-big-upgrad/1100-6470119/
3. **F.E.A.R.** — planning decisions should select contextual actions
   instead of hardcoded patrol scripts. A small attention utility score
   with hysteresis is inexpensive on Roblox compared with building a
   full generic GOAP solver for one antagonist.
   Research: https://gdcvault.com/play/1013282/Three-States-and-a-Plan
4. **Amnesia: The Bunker** — choices have interacting consequences,
   especially the sound produced by ordinary actions. The existing
   sound occlusion, noisy puzzles, inventory tradeoffs, hiding breath
   and chase all support this design already.
   Research: https://www.superjumpmagazine.com/the-making-of-amnesia-the-bunker/

Our implementation is independent and intentionally smaller than a
commercial AAA AI stack.

## Architecture

```text
    ROUND PROGRESSION / SHOCKS / LAST CALL
                  |
              Director
       (menace, grace, retreat)
                  |
     Room-level patrol influence only
                  |
  NoiseService ---> Perception ---> EvidenceMemory
  (real sound)     (fuzzy bearing)  (track / attention / visited)
                  |                    |
                  +-------+------------+
                          |
                 MonsterService brain
            ROAM / LISTEN / INVESTIGATE
                 SEARCH / HUNT / RETREAT
                          |
                     Navigator
           (doors, grounded pathing, stuck recovery)
                          |
                   Engineer humanoid
```

`Monster/EvidenceMemory.luau` is isolated, cheap and ephemeral:
information enters only through already-audible `Stimulus.estimate`
and never from a player's real `HumanoidRootPart.Position`.
Except for contact/catching and physically verifying lunge range,
`MonsterService` steers using this heard evidence.

## Upgrades added in 0.8.4

### 1. Attention, not constant reflex

When busy with a search or investigation, the Engineer holds his current
interest for about 2.5 seconds unless stronger evidence arrives.
A loud objective is always allowed to interrupt. This is small
utility-style arbitration, **not** a complete GOAP system.

**Player experience:** a series of weak clicks cannot endlessly spin him,
but a sharp crash still gets an immediate response.

### 2. Short acoustic memory and movement inference

Only player-sourced audible events create per-player tracks:
estimated position, clarity, approximate velocity and timestamp.
Successive reliable sound bearings may suggest direction. Tracks expire
after about 4.5 seconds; prediction looks no farther than one second
ahead, is clamped to sprint-scale movement and remains intentionally
imperfect.

**Player experience:** sprinting toward a hallway gives him a rough
direction; stopping, ducking behind a door and staying silent can
defeat that prediction. He does **not** know the player's next room
or exact position after losing contact.

### 3. Search pattern instead of random wandering

Search expands from the most recent evidence, looks at nearby authored
patrol points, then penalizes points recently visited for 48 seconds.
The newest reliable movement direction can bias the next few choices
by a small amount. The search budget and existing navigation remain
bounded: at most the chapter's configured search points, not a
whole-building path search every tick.

**Player experience:** he can check the likely exit from a noisy room,
but he also makes wrong guesses and eventually moves away.

### 4. Plausible locker inspection

Previously the nearest hiding spot could be checked every time a search
began, even without good evidence. Now a nearby recent, confident sound
bearing makes checking a local locker more likely. If none exists, a
small generic chance remains so the studio never feels perfectly safe.

The hiding system already emits muffled breathing and gasping
**anonymously**, so the new memory treats them as approximate human
presence without revealing a player's identity or which locker is
actually occupied. Silence and breath-holding remain valid counters.

### 5. Adaptation to simple sound distractions

Repeated, similar **anonymous** sounds from a stationary location
gradually lose attention. The first couple still work. Close, strong
noise and objective sounds remain effective; genuine player footsteps
and breath are not classified as worn-out machine loops.

**Player experience:** repeatedly throwing an object in one corner is
less effective than changing tactics.

### 6. A more credible pursuit and lunge

A loud, clear sound from a second player can cause the Engineer to
switch target after the original player has gone quiet.
During a chase, navigation follows recent estimated sound bearings,
not an exact constantly read player position. The lunge checks
proximity and line of sight, but **commits to the last heard bearing**
when the windup begins. A player who dodges quietly can make him miss.
His maximum speeds, warning duration and catch range have **not**
been increased.

## Fairness rules

- No direct teleporting, wallhacks, omniscient hiding detection,
  false player voices, forced bad choices or unavoidable catches
- Player velocity used in pursuit is derived from *heard estimates*;
  live positions are consulted only for legitimate touch / catch /
  minimum lunge eligibility
- Sealed booths still muffle noise according to `NoiseService`
- Initial grace, retreats, shock frenzy and Last Call remain
  controlled by the existing director and chapter logic
- Existing doors, pathfinding, object noise and hide-service contracts
  are unchanged
- Memory is reset every spawn/despawn, and visited/search caches have
  hard caps to protect multiplayer servers

## Visual-first test plan (when Studio becomes available)

1. **No free wallhack:** walk through a doorway out of sight, stop, and
   watch the Engineer go to the audible last known place rather than
   follow your exact movement through the wall.
2. **F.E.A.R.-style interruption:** make a quiet click during an
   investigation, then a loud objective noise. The quiet click
   shouldn't always interrupt; the loud one should.
3. **Search memory:** after evading him, watch his search route.
   It should usually cover different plausible points; observe
   repeated visits in debugging.
4. **Hiding:** enter a locker without being heard; he should not
   know which locker contains you. Gasp loudly close by; he may
   search the vicinity and sometimes find you.
5. **Decoys:** two stationary decoys should be meaningful. Repeat
   from the same spot several times and confirm decreasing interest.
   Move the distraction or make a loud crash to renew attention.
6. **Multiplayer:** one player makes enough noise to draw him away
   from another who is silently hiding; switching occurs only
   after sufficiently fresh and clear evidence.
7. **Lunge fairness:** dodge the windup; he must finish toward the
   original sound bearing, not home toward your new position.
8. **Director pacing:** confirm 45-second grace, occasional retreats,
   frenzy during shocks, and no retreat during Last Call. These are
   unchanged and must still work.
9. **Performance:** test on phone / two-player live server with
   Debug AI on, and again disabled. Watch navigation request rate,
   server frame time and stuck-recovery events.

Use `Config.DEBUG_AI = true` only for local testing: the overlay
shows AI state, awareness, focus, director mode/menace and navigator
status. Debug visuals are not gameplay features.

## Still to be validated

The code has **not** run in Roblox Studio, so actual difficulty,
turning, audibility, path clearance, lag and the precise lunge animation
can only be verified in a future playtest. A source audit checks the
contracts but is not a substitute for runtime behavior tests.
