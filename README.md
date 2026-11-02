# Dead Air (working title)

A co-op horror escape for Roblox. One to four players are trapped in a dark place with a monster that
hunts using hearing and sight: footsteps, doors, objectives, lighting and, when available, player voices.
Every objective is loud. Getting out means making noise; staying alive means keeping quiet.

Map 1 is an abandoned recording studio, hunted by **the Engineer**. Its soundproof booths are the
one place you can talk freely, as long as the door is shut and it didn't see you go in.

Proprietary, all rights reserved (see `LICENSE`).

## Status: integrated 0.9.2 — convincing assets, duplicated props removed (awaiting playtest)

**Use branch `chatgpt/integrated-v1`.** It includes both the playable-code Wrenmouth
cliff-top hub and the detailed 23-room recording house in **two distinct Roblox places**.
See [the complete integration guide](docs/INTEGRATED_BUILD.md) for setup, checks, required
published place IDs and what is still untested. This branch leaves `main`,
`chatgpt/studio-v2` and `chatgpt/hub-v1` intact.

The original Chapter 1 game systems remain authoritative, with full story
objectives, horror pacing and Last Call; the 1987 studio is built procedurally
when no hand-made map is supplied. Placeholder audio and Roblox Studio
playtesting are still outstanding. The design is in `docs/DIRECTION.md`.

**0.8.2 field notebook:** During a match, press **J** or use **NOTES [J]** to
review documents you have read and radio subtitles you have received this
round. The notes contain no hidden solutions and reset on the next round.
Design and later mobile checks: [docs/FIELD_NOTEBOOK.md](docs/FIELD_NOTEBOOK.md).

**0.8.3 evidence pass:** Chapter 1 now includes optional readable service, archive,
road-case, routing and navy records. The archive card index matches physical
reel labels, full-hand pickups preserve reels, and objectives are introduced
in a more natural sequence. See [docs/STUDIO_CH1_EVIDENCE.md](docs/STUDIO_CH1_EVIDENCE.md).

**0.8.4 Engineer AI:** The Engineer now makes decisions from imperfect
sound memory, resists repetitive distractions, infers likely search
directions and commits to non-homing lunges. Research references and
later fairness tests: [docs/ENGINEER_AI_V2.md](docs/ENGINEER_AI_V2.md).

**0.8.5 Engineer scripting pass:** articulated listening/search/pursuit poses,
studio-equipment inspections, fair closed-locker detection, bounded
pathfinding and per-round cleanup. The AI is behavior-complete **in source**;
it still needs engine and multiplayer validation before release.
See [the Engineer's complete behavior and acceptance plan](docs/ENGINEER_AI_SCRIPTED.md).

**0.8.6 lighting milestone:** The studio now uses Roblox's Realistic renderer
configuration and a 40-fixture, room-specific lighting system with simulated
indirect light bounce, two broad SurfaceLights, three total planned dynamic
shadow sources, and distinct exploration/shock states. This is **not true
path tracing**; lighting is untested in Studio. Read the complete
[studio lighting bible](docs/STUDIO_LIGHTING_BIBLE.md) before refining assets.

**0.8.7 Control A hero console:** A real, authored 16-channel analog DA-16
mixing desk replaces the duplicate blocky decorative faders. The original
MixingDesk puzzle remains authoritative; the session log now rests on a
readable shelf. Its status LEDs follow the chapter's lighting. Source-derived
offline previews are *not* Roblox screenshots. See
[docs/CONTROL_A_HERO_CONSOLE.md](docs/CONTROL_A_HERO_CONSOLE.md).

**Actual imported-asset option:** A new, real PBR-textured DA-16 glTF mesh
has been generated as a downloadable asset package. It contains 66 actual
mesh elements, independent faders and dials, a detailed meter bridge, and
original wood/metal textures. After the user imports the GLB into
`ServerStorage.WrenmouthDA16`, the studio map clones and positions
this imported mesh *instead* of the old Parts-built fallback. The previous
gameplay objectives and lighting controls remain authoritative. The binary
is distributed separately from GitHub; it is **not installed in Studio yet**.
See [mesh import instructions](docs/IMPORTABLE_DA16_MESH.md).

**0.8.8 playtest-driven lighting:** The studio now starts with partial working
power and a coherent, ceiling-mounted navigation circuit rather than an
almost unlit map. Main lighting brightens on shock one; emergency wayfinding
remains during the blackout. Fallback greybox lighting is also readable.
See [docs/STUDIO_LIGHTING_READABILITY.md](docs/STUDIO_LIGHTING_READABILITY.md).
Asset work is paused until lighting is reviewed in Roblox Studio.

**0.8.9 playtest-driven hiding:** Replace the generated studio's seven boxy
lockers/wardrobes with six meaningful under-desk hiding positions, including
reception, break room and archive worktables. The Engineer now catches a
player after a confirmed cover inspection and may intentionally inspect a
recently witnessed entry. E / touch Step out remains available. See
[docs/UNDER_DESK_HIDING.md](docs/UNDER_DESK_HIDING.md).

**0.9.0 physical asset pass:** Reusable collidable studio furniture, grounded
monitor speakers, three detailed machine-room equipment racks and two
server-owned, non-anchored wheeled flight cases with genuine hinge axles and
physics. The story RoadCase remains fixed and interactive. See
[docs/PHYSICAL_ASSET_FOUNDATION.md](docs/PHYSICAL_ASSET_FOUNDATION.md).
The assets are not final AAA meshes and need real Studio/collision testing.

**0.9.1 purposeful interiors:** Four grounded open archive cabinets replace featureless blocks. All 48 tape cases sit on twelve load-bearing decks. Reception and break-room contents now sit on real worktops; the vinyl display and cleaning shelves have physical supports; and stage instruments have actual mounts and stands. Reusable tables also have more coherent joinery. See [docs/GROUNDED_INTERIORS.md](docs/GROUNDED_INTERIORS.md).

**0.9.2 full asset pass:** Reusable benches, cabinets and corrected open-leg desks first; then room-specific editing/mastering consoles, patchbay sockets and actual cables, safe and card index mechanisms, supported vocal and live instruments, bathroom fixtures and grounded loading gear. Removed duplicate base-map fixtures and floating placeholder overlays. **No AAA geometry requirement:** assets should look plausible and have meaningful collision, not more parts for their own sake. See [docs/CONVINCING_ASSET_PASS.md](docs/CONVINCING_ASSET_PASS.md). Not yet verified in Studio. This is a placement repair, not a claim of final custom-mesh quality.
More playtest details: [studio](docs/STUDIO_V2_PLAYTEST.md) and
[hub](docs/HUB_V1_PLAYTEST.md).

What a round looks like (about 20 to 25 minutes):
1. The front doors' quarantine locks slam behind the crew. The handler talks on the walkies.
2. The booking diary points to control room A; the session log there names three reels.
3. Fix the tape machine: spare parts from the break room, then rethread it by hand.
4. Find the reels: the archive (card index, then the right shelf), the live room (a road case under
   instruments), control room B (a safe; the date is on the memorial programme). Each reel plays out
   loud when it's loaded.
5. Two shocks: the building wakes at the first reel; blackout, fog and red lights at the second.
6. Patch the desk at the patch bay, then hold the desk while the recording dubs onto the cassette,
   riding the faders.
7. Last Call: 45 seconds to get out the front doors with the cassette, the long way round.
8. Caught players become echoes: their body stays, humming; they float, mark the monster and whisper.
   A teammate can put their headset back on.

## Controls

| Key | Action |
| --- | --- |
| WASD | Walk (makes some noise) |
| Shift | Run (fast, loud, tiring; shorter and slower while carrying something heavy) |
| C or Ctrl | Crouch (slow, silent) |
| F | Flashlight (a quiet click) |
| E (hold) | Interact: read, take, use, get under a desk |
| G | Put down what you're holding |
| T | Throw what you're holding (bottles, cans, pipes) |
| Space | While hiding with the monster close: hold your breath |
| V (hold) | Talk on the walkie: teammates' walkies crackle (and carry your voice) |
| 1 to 4 | Walkie callouts: "It's here!", "Need help!", "Found a reel.", "Going quiet." |
| N | Walkie on or off |
| R | Tape recorder: record nearby noise, then set it down as a decoy |
| As an echo | Move as usual (forward follows your look); P marks the monster; 5 to 8 whisper |
| G (lobby) | Ready up |

## Setup

Tools are pinned in `rokit.toml` (Rojo, StyLua, Selene).

```sh
git clone https://github.com/gahitchi/rblx-horror.git
cd rblx-horror
git switch chatgpt/integrated-v1
rokit install
# For the MATCH place:
rojo serve default.project.json
# For the HUB place instead, stop that server and run:
# rojo serve hub.project.json
```

In Roblox Studio: open a new Baseplate, click **Connect** in the Rojo plugin, then **Play**. The
map is built by the server when the game starts, so the edit view stays empty; that's expected.
The server removes the template's baseplate and spawn when it runs.

Tips for testing:
- Set Studio's max frame rate to 60 to keep the laptop cool.
- `Config.DEBUG` (in `src/shared/Config.luau`) shortens the lobby countdown and prints the
  monster's decisions to the Output.
- `Config.DEBUG_AI` shows a label over the monster (state, awareness, director mode, path status)
  and yellow dots along its current path.
- To test with several players, use Test > Clients and Servers.

### Voice

Voice is optional; the game works the same without it. To test it in a published place, turn on
voice chat for the experience (Game Settings > Communication) and use an account that has voice.
`UseAudioApi` is already enabled in the project file. Voice doesn't work in solo Studio play.

## Places

Two places in one Roblox experience: the **hub/start place** (`hub.project.json`,
`src/hub/`) and the **reserved match place** (`default.project.json`,
`src/server/` and `src/client/`). Each project uses the same `src/shared/`.

**Before published teleports work:** set the actual nonzero
`Config.PLACES.HUB` and `Config.PLACES.MATCH` IDs. Until then, crew Start
is intentionally blocked rather than sending players somewhere they cannot
return from. Exact steps: [docs/INTEGRATED_BUILD.md](docs/INTEGRATED_BUILD.md).

## Maps

A map is a `Workspace.Map` laid out as [docs/MAP_CONTRACT.md](docs/MAP_CONTRACT.md) describes. Without
one, this integration branch builds the detailed `StudioGroundFloor` studio.
An old greybox remains only as the last-resort fallback if a map contract fails.

## Layout

```
src/shared   Config (all tuning numbers), Remotes, Sounds
src/server   MapContract, MapBuilder, DoorService, NoiseService, MonsterService (+ Monster/),
             ObjectiveService, RoundService, RoundState, PlayerService, Items/, ItemArt, Main
src/client   Movement, Flashlight, Voice, Items, Spectate, Hud, DangerEffect, Main
```

## Checks before pushing

```sh
python3 tools/integration/check_integration.py
stylua --check src
rojo build default.project.json -o match.rbxl
rojo build hub.project.json -o hub.rbxl
```

Also run Luau-LSP analysis against each Rojo project's own sourcemap;
only a Roblox Studio/published-server test can verify actual multiplayer teleports.
