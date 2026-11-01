# Dead Air — sound direction and Creator Store search guide

Map/visual team handoff. **This is a casting sheet, not an asset manifest.** No Roblox asset IDs have been selected or uploaded. Test licensing, playback permissions, trim, loudness and loops in Studio before setting `src/shared/Sounds.luau` entries.

## Acoustic identity

The recording studio must sound *believable* when quiet. Use decaying mechanical reverberation in corridors, suppressed fabric thuds in isolation booths, a humming electrical basement, narrowband transistor coloration on portable devices, and recognisable analogue tape transport sounds. Keep the Engineer's cues distinct from ordinary player footsteps and the alarm. Most scares should be created by proximity and contrast, not maximum-volume jumps.

## Existing entries in `src/shared/Sounds.luau`

| Entry | Desired sound / usage | Roblox Creator Store > Audio search terms | Playback notes |
| --- | --- | --- | --- |
| `DOOR` | Heavy insulated wood/steel studio door: latch click, short low hinge groan, rubber seal compressing, no cartoon creak | `soundproof studio door close`, `heavy door latch`, `metal hinge close` | One short spatial event; audible from nearby rooms |
| `FUSE` | Ceramic/cartridge fuse seating in spring clips: little metallic snap followed by soft panel resonance | `electrical fuse insert`, `switch metal click`, `circuit breaker click` | Short one-shot; avoid loud sparks or zaps |
| `GENERATOR_PULL` | Abrasive rope starter yank, crank rotation, dry engine cough; each pull should sound like an attempt | `generator pull start`, `lawn engine pull cord`, `diesel engine failed start` | Characterful loud one-shot; three pulls can vary pitch |
| `GENERATOR_HUM` | Aged stationary diesel/electric machine settling into a low, rhythmic industrial drone | `industrial generator loop`, `diesel generator running`, `electric generator rumble` | Ideally seamless loop; current system only uses noise events, so implement persistent sound with Claude |
| `ALARM` | Degraded, overdriven emergency tone through old PA speakers, with clipping and faint crackle | `old evacuation alarm`, `industrial siren distant`, `vintage PA alarm` | Prefer a short loop and spatial distribution; avoid modern clean phone alarms |
| `CATCH` | Hard cut into a close fabric/metal impact, low breath or distorted feedback; avoid silly character death samples | `horror impact metal`, `fabric body thump`, `low distorted feedback hit` | Brief, non-gory, does not mask gameplay communication |
| `LUNGE` | Short distorted headset squeal escalating into a rushing metallic cable snap | `feedback shriek horror`, `microphone feedback burst`, `metal whip whoosh` | Distinct warning with ~0.45 s windup; should precede rather than follow hit |
| `FLASHLIGHT` | Tiny worn mechanical toggle, dull double click, very little high-frequency harshness | `flashlight switch click`, `mechanical toggle small`, `old torch click` | Quiet one-shot near the player |
| `MONSTER_STEP` | Slow heavy uneven boots plus loose headset/cable rattle; recognizable through thin walls | `heavy boots concrete slow`, `industrial work boots footsteps`, `metal scrape step` | Layer light drag/rattle over distinct steps; no music |
| `ALERT` | Engineer locks onto a sound: throatless headset squeal, magnetic tape braking, angry electrical groan | `radio feedback scream`, `tape brake squeal`, `electronic horror alert` | Different from lunge: longer and lower, obvious change in AI intention |

| `FOOTSTEP` | Human step recorded onto tape or reproduced by mimicry; lighter than Engineer boots | `carpet walking steps`, `shoe on concrete`, `shoe wood floor` | Replay/mimic cue; later add surface-specific variants |
| `LANDING` | Weighty shoe landing and fabric rustle | `human landing thud`, `boot land concrete`, `soft landing` | Short distinct transient |
| `VOICE_GARBLE` | Muffled, unintelligible analog-recorded speech and pitch wobble | `garbled old radio speech`, `cassette voice fragment` | Slowed for playback; avoid copyrighted speech |
| `WALKIE_CRACKLE` | Narrowband radio hiss, clipped bursts and squelch | `walkie squelch analog`, `two way radio static burst` | Plays at receiving walkies; some calls at half speed |
| `WALKIE_CLICK` | Dry thumb push-to-talk spring click | `walkie PTT click`, `two way radio button` | Repeated at call start/end; keep quiet |
| `TAPE_CLUNK` | Plastic transport key and metal portable deck placed on floor | `cassette transport button`, `tape recorder set down` | Short one-shot; separate from fuse snap |

## Additional anticipated cues — verify their exact names after Claude's milestone lands

Claude's v0.3.0 additions are listed above. The following are further ideas, not additional existing constants. Coordinate new identifiers with Claude.

| Planned effect | Desired sound | Search terms | Implementation coordination |
| --- | --- | --- | --- |
| Walkie crackle / connection | Fuzzy analog UHF squelch with a clipped transmission onset and falloff | `radio walkie static burst`, `two way radio squelch`, `short radio crackle` | 0.1–0.5 s dry sound; avoid drowning speech |
| Walkie push-to-talk | Two subtly different contact clicks for press/release | `radio ptt click`, `walkie button click` | Keep quieter than crackle |
| Walkie weak-signal noise | Thin gated hiss with sporadic interference, not a constant loud wash | `weak signal radio static`, `VHF noise loop` | Looped only when the feature explicitly enables it |
| Tape recorder button / motor | Physical mechanical transport click then low capstan whirr and soft reel flutter | `cassette recorder play click`, `tape transport motor`, `cassette deck running loop` | Mechanical motor loop separate from recorded audio |
| Tape playback decoy | Narrow, fluttering sound of a *recorded* player voice and nearby foley; light tape hiss | `cassette tape hiss`, `recording playback vintage`, `tape wow flutter` | Recorded signal should be clearly identifiable as playback to attentive players |
| Tape stop / eject | Brief head disengagement and a spring-loaded key clack | `cassette deck stop`, `tape player eject click` | 0.2–0.8 s |
| Engineer sound mimic | Badly reconstructed speech/footsteps through broken analog processing: uneven pitch, dropouts, flutter | `ghost radio voice`, `tape distorted voice`, `glitch voice loop` | Keep some tell; mimic should be uncanny but not unfairly indistinguishable |
| Distant room ambience | Subdued HVAC, transformer hum, pipe ping, tiny loose metal resonances | `abandoned building roomtone`, `old air conditioner hum`, `industrial pipe settling` | Room-specific low-volume loop; avoid constant blanket audio |
| Floor-dependent footsteps | Carpet makes soft scuffs; archive concrete gives boots and rack vibration; wood gives short planks | `footstep carpet walking`, `footstep wooden floor`, `footstep concrete boot` | Coordinate movement audio with server-side NoiseService: cosmetic sound does not change detection |

## Candidate selection checklist

1. Confirm an audio asset can legally and technically be used in the experience; Roblox Creator Store publication does not automatically grant unrestricted rights outside Roblox.
2. Audition without headphones and with headphones; especially control piercing highs and distorted peaks.
3. Compare each candidate against voice chat, navigation and the Engineer's warning cues at realistic game volume.
4. Ensure a persistent source actually loops cleanly (the current `Sounds.playAt()` helper creates a disposable one-shot).
5. Choose variants for important repetitions where possible, while keeping the monster's threat cue recognizable.
6. For spatial audio, use rolloff distances consistent with the scene; `NoiseService` hearing is gameplay logic and is not automatically the same as the audible sound's distance.
7. Test the complete alarm/tape phase with multiple players to avoid a wall of overlapping sirens and radio signals.

**Owner split:** Gabriel selects and uploads audio in Roblox Studio; Claude wires the selected IDs and timing into gameplay; ChatGPT owns the audible art direction and environment/room ambience planning.
