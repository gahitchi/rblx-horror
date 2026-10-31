# Dead Air (working title)

A co-op horror escape for Roblox. One to four players are trapped in a dark place with a monster that
hunts by sound: footsteps, doors, objectives and, for players who have voice chat, their actual voices.
Every objective is loud. Getting out means making noise; staying alive means keeping quiet.

Map 1 is an abandoned recording studio, hunted by **the Engineer**. Its soundproof booths are the
one place you can talk freely, as long as the door is shut and it didn't see you go in.

Proprietary, all rights reserved (see `LICENSE`).

## Status: prototype 0.2.0

Greybox studio, the noise system, the Engineer, the full round loop and a basic HUD. Placeholder sounds.

What a round looks like:
1. Wait in the lobby for the countdown.
2. Start the generator in the basement (three pulls, each one loud). The emergency lights come on.
3. Find three fuses around the studio (one at a time) and fit them in the basement fuse box.
4. Play the emergency tape in control room A. Every speaker blasts an alarm for 20 seconds.
5. The front doors unlock. Get out through reception.

Coming next: walkie-talkies, the tape recorder, the Engineer replaying sounds it heard, spectating,
real sounds and models.

## Controls

| Key | Action |
| --- | --- |
| WASD | Walk (makes some noise) |
| Shift | Run (fast, loud, tiring) |
| C or Ctrl | Crouch (slow, silent) |
| F | Flashlight (a quiet click) |
| E (hold) | Interact |

## Setup

Tools are pinned in `rokit.toml` (Rojo, StyLua, Selene).

```sh
git clone https://github.com/gahitchi/rblx-horror.git
cd rblx-horror
rokit install
rojo serve
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

## Layout

```
src/shared   Config (all tuning numbers), Remotes, Sounds
src/server   MapBuilder, DoorService, NoiseService, MonsterService, ObjectiveService,
             RoundService, RoundState, PlayerService, Main
src/client   Movement, Flashlight, Voice, Hud, DangerEffect, Main
```

## Checks before pushing

```sh
stylua src
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --platform=roblox --sourcemap=sourcemap.json src
rojo build -o build.rbxl
```
