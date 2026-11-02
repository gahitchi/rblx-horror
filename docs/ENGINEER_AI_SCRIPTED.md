# The Engineer — scripted behavior-complete milestone

**Branch:** `chatgpt/integrated-v1`  
**Build:** `0.8.5-engineer-scripted`  
**Scope:** The Engineer's **code behavior and procedural presentation** are implemented.
Roblox Studio performance, movement, multiplayer fairness and character visual quality
are **not yet validated**. No claim of production-grade AAA AI is made.

## What is actually running in source

The Engineer is the only central stalker in the 1987 recording house. He is
blind; he can hear, infer, remember briefly, inspect and touch. He must not
get continuously updated target coordinates from the player or director.

### Behavior contract

| Behavior | Trigger | Action | Why it is fair |
| --- | --- | --- | --- |
| Dormant | Start of chapter | No AI until arrival delay | Opening grace is preserved |
| Patrol | No strong evidence | Move between authored room points; pause | No fixed repeating circular path |
| Listen | Low-confidence sound | Stop, turn head/body toward approximate bearing | Reveals intent before motion |
| Investigate | Credible sound / loud objective | Choose an approximate sound goal; navigate, opening interior doors | Sound attenuation and fuzziness still apply |
| Equipment inspection | Reel, tape slip, recording, safe or console noise near relevant equipment | Approach a reachable patrol waypoint, pause 1.6 sec, examine | Only sound-associated equipment, not omniscient clues |
| Search | Investigation arrives or target lost | Check near points, bias toward last audible movement, avoid revisits | Search ends on budget/timer; can go the wrong way |
| Hide search | Confident sound or breathing near closet | Sometimes open a reachable locker | Cannot know occupant until actually checking |
| Pursuit | Clear nearby player-sourced sound or touch | Accelerate along *heard estimates*, with short prediction | Silent turns and breaking contact still work |
| Target switch | Original chase goes quiet; a second player makes clear nearby noise | Redirect to the new sound, not the new player's live coordinates | Team distractions remain viable |
| Lunge | Close contact opportunity with recent evidence and clear path | Audible/visual windup, then short committed non-homing movement | Can miss if player dodges |
| Catch | Actual physical proximity + clear line of sight | Catches player through existing round system | Hidden-in-locker players excluded from touch/catch |
| Retreat | Director pressure or successful catch, outside frenzy | Backs off to a remote room for a time | Crew gets recovery windows |
| Last Call | Existing chapter script | Holds frenzy and favors loud evidence | No new unavoidable insta-kill mechanics |

### The complete pipeline

```text
Player actions / studio equipment
       |
NoiseService  →  wall attenuation / isolation booths
       |
Perception    →  fuzzy sound bearing + awareness
       |
EvidenceMemory
  ├─ short tracked source bearing + estimated motion
  ├─ attention competition / 2.5-second commitment
  ├─ novelty reduction for repeatedly triggered anonymous decoys
  ├─ anonymous breathing as *possible* presence, not occupant identity
  └─ recent visited point cache + directional search bias
       |
MonsterService goal/state machine
  ├─ director-selected roam / grace / retreat
  ├─ investigate / search / optional equipment inspection
  ├─ evidence-limited hunt / target switch / committed lunge
  └─ existing hide checks and round capture callbacks
       |
Navigator     →  doors, path smoothing, stuck recovery
Motion        →  neck turns, shoulder gestures, gait, searching pose
       |
EngineerModel →  server-owned humanoid / headset attached to moving head
```

### Studio-specific personality

The Engineer isn't a generic creature dropped into any building. He is drawn
to things he would have worked with:

- **Tape or reel noises:** he may inspect the tape transport or archive
- **Audio buzz / patch errors:** he may check the patch bay or mixing desk
- **Stacked equipment clatter:** he may approach the live room's road case
- **Safe clunk:** he may examine the safe area
- **Recording crescendo:** he may check the transport or desk

He approaches a *patrol point near the equipment*, not a point inside
solid geometry. If an authored map has no suitable objective/waypoint,
the extra inspection is safely skipped. These points are considered only
after the sound already brought him into the area. The inspection is
a visible pose/brief pause, not a new pick-up or scripted jump scare.

### Visual communication of intelligence

The native procedural NPC now uses **neck, shoulder and hip motors**
instead of locking all limbs to the root. The earcups and headband
are welded to the head, so they remain attached when he turns.

The `Monster/Motion.luau` module updates restrained motions in:
Patrol, Listening, Approach, Searching, Inspect, Pursuit and Withdraw.
Model attributes `State`, `Intent` and `Inspecting` expose the
current goal for later model/animation replacement. The existing custom
body remains a **placeholder for art quality**; the AI rig is a functional
transition to a detailed authored character, not a finished mesh.

### Performance and robustness bounds

- One brain update every 0.1 sec; no new per-player AI controller
- No learning model, remote inference, network request or external process
- Bounded visited/search memory, and a max of six path fallback computations
  per failed navigation request
- Path.Blocked replans throttled; stale asynchronous sounds ignored
- No new collision parts or invisible player-detection fields
- Visual body motion uses only five native joints
- Delayed mimicked footsteps are canceled on new-round reset
- Hiding players must be discovered via a locker check, not root-to-root
  contact through the closed compartment
- All new tuning remains in `Config.MONSTER.COGNITION`

## Deterministic test harness

The test script in `tools/studio/EngineerAiSelfTest.server.luau`
is deliberately **not inserted into the live game**. When the
Match place is running in Roblox Studio and synced with Rojo, paste
it into the server Command Bar. It checks:

1. New noise is interesting; equal weak evidence cannot constantly
   interrupt a current investigation
2. Repeating anonymous prop noises lose novelty
3. Loud objectives always interrupt
4. Anonymous breath suggests nearby hiding, not arbitrary lockers
5. Breath evidence expires
6. Search points favor unvisited, plausible locations and penalties
   fade over time
7. All transient knowledge is removed on reset

Run `python3 tools/integration/check_integration.py` in a local
checkout for the expanded static contract checks. These cover source
wiring, configuration knobs, hiding protection, bounded navigation,
articulation and preserved two-place integration. Neither test proves
that a Roblox character can physically navigate the layout.

## Required engine playtest — do not skip

- **State demonstration:** Enable `Config.DEBUG_AI` on a private test
  server. Watch state, intent, inspection target, awareness and path
  status while manually emitting sound at different locations.
- **Body assembly:** Confirm the server-owned rig walks without falling
  or getting stuck and that the headset remains attached as its head
  moves. Verify shoulder/hip articulation on both R15 and current
  server defaults.
- **Blindness:** Walk through a doorway and stop. Confirm he searches
  his last heard area rather than tracking the exact hidden position.
- **Lockers:** Hide silently; he must not detect occupants through
  closed walls. Breathe/gasp close by; he may choose to investigate
  and can find someone only after inspecting a compartment.
- **Workstations:** Trigger reel, safe, routing and clutter sounds in
  different rooms. Ensure he chooses plausible reachable approach
  points and doesn't repeatedly inspect the same prop.
- **Multiplayer:** Have one player distract him while another hides.
  Confirm pursuit switching is bounded and doesn't require any team
  member to become an impossible-to-avoid sacrifice.
- **Movement and lunge:** Check distance, acceleration, warning,
  hit registration and that a last-second dodge can succeed.
- **Lifecycle:** Die, restart the chapter, start another round and
  verify memory, poses, delayed mimics and hunt targets reset.
- **Performance:** Server profiling with 1–4 players; inspect path
  computation rates, Motor6D update/replication cost, footsteps and
  stuck recovery in the full furnished studio.

The completion criterion is **believable and fair behavior**, not a
raw pathfinding success rate. Lower or modify these behaviors if the
engine tests expose cheating, excessive search repetition, jitter,
performance spikes or unavoidable captures.

## Source files

- `src/server/MonsterService.luau` — state and action selection
- `src/server/Monster/EvidenceMemory.luau` — short-lived sound belief
- `src/server/Monster/Environment.luau` — sound-specific studio inspections
- `src/server/Monster/Motion.luau` — physical pose intent
- `src/server/Monster/EngineerModel.luau` — articulated root rig
- `src/server/Monster/Navigator.luau` — bounded navigation
- `src/server/Monster/Director.luau` — grace and retreat pacing
- `src/server/Monster/Mimicry.luau` — sound imitation lifecycle
- `src/server/Monster/Perception.luau` — hearing
- `src/server/HideService.luau` — physical locker handling

Related earlier design background: `docs/ENGINEER_AI_V2.md`.
