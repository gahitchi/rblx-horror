# Dead Air (working title)

A co-op horror escape for Roblox. One to four players are trapped in a dark place with a monster that
hunts by sound: footsteps, doors, objectives and, for players who have voice chat, their actual voices.
Every objective is loud. Getting out means making noise; staying alive means keeping quiet.

Map 1 is an abandoned recording studio, hunted by **the Engineer**. Its soundproof booths are the
one place you can talk freely, as long as the door is shut and it didn't see you go in.

Proprietary, all rights reserved (see `LICENSE`).

## Status: integrated 0.8.0 — hub and studio (not playtested)

**Use branch `chatgpt/integrated-v1`.** It includes both the playable-code Wrenmouth
cliff-top hub and the detailed 23-room recording house in **two distinct Roblox places**.
See [the complete integration guide](docs/INTEGRATED_BUILD.md) for setup, checks, required
published place IDs and what is still untested. This branch leaves `main`,
`chatgpt/studio-v2` and `chatgpt/hub-v1` intact.

The original Chapter 1 game systems remain authoritative, with full story
objectives, horror pacing and Last Call; the 1987 studio is built procedurally
when no hand-made map is supplied. Placeholder audio and Roblox Studio
playtesting are still outstanding. The design is in `docs/DIRECTION.md`.
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
| E (hold) | Interact: read, take, use, hide in a wardrobe or locker |
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
