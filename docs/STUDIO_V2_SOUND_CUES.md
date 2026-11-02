# Studio v2 — sound cues for the blockout

Adapted from the sound casting sheet on `chatgpt/studio-art-pass`, but aligned with the **current**
chapter-1 systems and `src/shared/Sounds.luau`. This is an audition guide, **not** a set of
licensed/uploaded assets. The code still uses Roblox placeholder sounds. Replace IDs only after
Creator Store licensing and permission checks in Studio. Do not bring over obsolete generator,
fuse, or old alarm cues.

## Acoustic signature

The studio should be human and nearly quiet before the first reel: fabric-soft booths,
warm wooden live room, dry tape transport, distant surf/fog beyond the front lock.
The navy additions sound alien to that warmth: cold magnetic latches, abrupt metal
shutters and clipped quarantine PA. The Engineer should be identifiable at phone-speaker
volume by slow, irregular boot strikes and the headset's slightly unstable feedback.
Use **distance and contrast**, not constant loudness. An acoustic booth should sound
visibly softer than the same corridor.

## Current sound keys / search direction

| Key in Sounds.luau | Casting target | Search terms |
| --- | --- | --- |
| `DOOR` | Studio acoustic door: latch, seal and short hinge | soundproof door latch, heavy wood close |
| `LOCK_SLAM` | Quarantine magnet engaging or releasing | magnetic lock clunk, industrial bolt |
| `SHUTTER` | Heavy, rattling naval gate descending | rolling shutter slam, heavy metal gate |
| `REEL_TRACK` | Characterful distorted choir fragment on a tape reel | reel to reel tape hiss, old singing muffled |
| `RECORDING` | Long multi-speaker uncanny recording, the chapter climax | analogue tape loop, distant processed vocal |
| `TAPE_THREAD` / `TAPE_SLIP` | Pinch roller click / tape sliding off guide | reel machine click, film transport |
| `SAFE_CLICK` | Small, precise worn mechanical tumbler | safe dial tick |
| `CLUTTER` | Cymbal, amplifier case and metal stand falling | metal stand fall, cymbal impact |
| `BUZZ` | Low analogue mixing desk feedback | mixing console hum, electrical buzz |
| `THUMP` | Ambiguous furniture blow behind barricaded flat door | dull wooden impact behind wall |
| `MONSTER_STEP` | Uneven weight, worn sole and headset rattle | heavy boot floor, metal drag |
| `ALERT` / `LUNGE` | Feedback warning / sharp cable snap | radio feedback, metallic whip |
| `FOOTSTEP` / `LANDING` | Human pace, clearly unlike Engineer | rubber sole wood, soft shoe landing |
| `WALKIE_CRACKLE` / `WALKIE_CLICK` | 1980s clipped voice-radio hiss and button | analog radio squelch, old PTT click |
| `VOICE_GARBLE` / `HUM` / `WHISPER` | The town's memory reappearing in fragments | muffled voice loop, breath, low humming |
| `FOGHORN` | Remote harbor signal beyond the quarantine | fishing harbor fog horn distant |
| `STINGER` / `CATCH` | Clear escape punctuation / short non-gory loss | low orchestral sting, fabric impact |

## Playback priorities after the geometry playtest

1. Confirm that opening and shutting one booth door changes audibility as intended.
2. Test the studio's eight-plus speaker positions when reels load, from reception and backstage.
3. Confirm the short-route shutter sounds **before** the chase turns toward the live hall.
4. Replace the currently shared placeholder sound IDs with approved, accessible sounds;
   audition on phone speakers and headphones. Sound balance is a gameplay test, not a
   requirement for more texture or geometry detail.
