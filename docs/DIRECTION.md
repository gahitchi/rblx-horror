# Direction: stylized look, adrenaline finish

Set by Gabriel on 1 November 2026. This page overrides older notes where they disagree.

## Why

- The games at the top of Roblox right now are stylized, not realistic, and the horror hits there
  (Dandy's World, 99 Nights in the Forest, Violence District) scare through atmosphere, sound and
  tension rather than detail.
- Roblox's discovery ranks games on playtime, return days, co-play and a low first-play bounce rate.
  Visual fidelity isn't one of the signals.
- Players are blocky avatars, and most play on phones.
- So Dead Air aims to be an **emotional game, not an AAA one**. The feeling we're building for:
  **every round ends in an adrenaline rush.**

## Art direction

- **Stylized and readable.** A room or a monster should read at phone size in a dark corridor.
  Shape first, then lighting, then texture.
- **Mood comes from light, fog, darkness and sound**, not from material detail.
- **The Engineer is one strong silhouette**: tall, thin, blind, studio headphones grown into its
  skull, earcups that flare red. Scary because of how it moves and sounds, not because of anatomy.
- **Budget:** one asset should take about an afternoon. Roblox materials plus a few custom textures.
  Keep part and triangle counts low so mobile holds its frame rate.
- **Out of scope for now:** realism benchmarks, anatomical base meshes, per-bone fit checks,
  physically based texture pipelines and per-asset quality gates. These are parked, not deleted:
  the work stays on its branch in case Deep Down (Godot, realistic) can use it later.
- **Validation:** keep `rojo build`, `luau-lsp analyze` and checks that catch real bugs
  (map contract, 6-stud doorways). A new validator needs a bug it would have caught.

## From `chatgpt/studio-art-pass` to `main`

ChatGPT built a lot in two days. These parts fit the new direction and should come over, restyled
where needed:

- the Blackline layout: 19 connected spaces with varied room heights and a bigger live hall;
- story props and environmental clues;
- the sound catalog;
- the map kit pieces, once they follow `docs/MAP_CONTRACT.md`.

Bring them over in small, playtestable steps, each one tested by Gabriel before the next.

## The finish: "Last Call" (proposal)

Before this, the climax was a door that opens: the tape played for 20 seconds, the doors unlocked, you walked
out and got sent to the lobby. The last minute should instead be the most intense of the round.

1. **The full recording is the trigger.** Once the last reel is in, the recording plays through the
   whole building and the Engineer comes straight for control room A at full speed. Someone has to
   hold the mixing desk until it finishes and dubs onto the team's evidence cassette.
2. **Frenzy.** When the doors unlock, the Engineer hears everything everywhere and keeps its top
   hunt speed. The director's back-off rules switch off. It stays just slower than a sprint, so
   the run is a chase you can win, not a death sentence.
3. **The doors close again.** A visible countdown (about 45 seconds) starts at the unlock. Anyone
   still inside when it hits zero is trapped and caught.
4. **The way out changes.** A shutter drops on the short route, so the team runs through the live
   room, where everything is easy to knock over.
5. **The cassette and the rescues.** The evidence cassette has to leave the building or the chapter
   isn't cleared; a caught carrier drops it for someone else to grab. A teammate's entranced body can
   be revived on the way out too (put their headset back on), tying the run into the revive system.
6. **The escape moment.** Burst through the doors, they slam behind you, the Engineer hits the
   glass, a music stinger. Escaped players stay outside for a few seconds watching through the
   glass and can shout (the monster can't hear outside) before results.
7. **Results that replay the rush.** Near-miss stats: how close the Engineer got ("2 studs behind
   you"), seconds left on the doors, who rescued whom.

Tuning goal: calm early, rising mid-round, peak in the last 60 to 90 seconds. Playtests decide the
numbers; they live in `Config` like everything else.

The full round, the chapters and the story are in the design doc (see `CLAUDE.md`). Generators and
fuse boxes are out: too close to Dead by Daylight.
