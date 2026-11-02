# DEAD AIR — LIGHTING BIBLE / V1

**Branch:** `chatgpt/integrated-v1`  
**Build:** `0.8.6-studio-lighting`  
**Status:** source-complete studio lighting pass; **not** yet measured or seen in Roblox Studio.

## Visual north star

Our reference is the *perceptual* richness of path-traced cinematic imagery:
localized illumination, smooth transitions into darkness, reflective separation,
subtle warm bounce and cool rim light, depth around glass, and a clear difference
between an electrical failure and ordinary ambient darkness.

**Roblox limitation:** the public Roblox experience renderer does not offer
creator-controlled, gameplay-ready real-time hardware path tracing or true
ray-traced global illumination/reflections. We do **not** implement or claim
those effects. Offline CPU/Luau path tracers are unsuitable for the 1–4 player
horror game and mobile devices. All of the "bounces" here are deliberately
positioned, low-energy artistic proxy lights, not traced photons.

Verified engine documentation (as reviewed 2 November 2026):

- https://create.roblox.com/docs/environment/lighting
- https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-indoor-environments
- https://devforum.roblox.com/t/let-there-be-unified-light-unified-lighting-is-fully-live/3401512
- https://devforum.roblox.com/t/luau-ray-tracer-path-tracing-on-roblox-with-user-defined-shaders/1932571

## Renderer setup

Match-place `default.project.json` now authors these global settings:

- `LightingStyle: Realistic` — advanced built-in shadows, shading and
  specular highlights
- `PrioritizeLightingQuality: true` — preserve nearer lighting quality as
  lower graphics settings reduce view distance
- `GlobalShadows: true`

`LightingService` controls only script-accessible environmental variables,
ColorCorrection, Bloom, state changes and lamp intensities. It deliberately
does not rely on changing the deprecated `Technology` property.
The hub place has a separate profile; it is not affected by the studio rig.

**Material caveat:** Realistic lighting enhances Roblox's physically based
materials. Future asset geometry can use MaterialVariants or SurfaceAppearance
roughness/metalness maps to benefit from it. We have not modified meshes,
materials or props in this lighting-only milestone.

## Control Room A — gold standard

Room coordinates: **x -84 to -34, z -107 to -58, height 16 studs**.

Every lamp must have a physical source. The room is not globally washed with
orange or red light. Instead, it has complementary light layers:

| Source | Position x/y/z | Purpose | Role |
| --- | --- | --- | --- |
| Desk writing lamp | -57 / 7.8 / -79 | Legible mixing desk and session log | Warm focused key, casts shadow |
| Softbox return | -62 / 9.4 / -76 | Gentle broad illumination across the operator position | Soft SurfaceLight |
| Tape transport pilot | -73 / 6.8 / -94 | Readable machine, even when room has no power | Very weak residual practical |
| Mixing desk scale light | -55 / 4.7 / -78 | VU/fader region separated from deep shadow | Warm accent |
| Patch-bay inspection | -40 / 8.2 / -96 | Readable cable connections | Tight spot |
| Tracking-glass rim | -36.5 / 10 / -98 | Distinguishes booth window from wall | Neutral/warm threshold |
| Circuit-fault marker | -77 / 11 / -73 | One unstable power circuit | Small red accent |
| Desk-to-wall bounce | -61 / 4.4 / -83 | Gentle local tungsten return | 0.15 brightness, no shadows |
| Desk-to-ceiling bounce | -57 / 11.8 / -79 | Lifts ceiling out of featureless black | 0.10 brightness |
| Tape-metal reflection | -72 / 4 / -89 | Metallic tape transport contour | 0.09 brightness |
| Tracking-glass return | -38 / 7.1 / -97 | Indirect glass-side fill | 0.11 brightness |

The existing *ControlA* ceiling practical and service accent practical also
receive room-specific profiles; they are not removed or duplicated.

The key light hits the working desk; the room recedes into controlled shadow
towards the back. The patch bay reads as distinct equipment. The window must
show *a hint* of the live room, not a uniformly lit view of everything.

**Contrast hierarchy:** session log, tape machine and routing patch first;
doorways and the Engineer silhouette second; background equipment last.
Small fluorescent red LEDs are a sign of electrical malfunction, not a red
wash that destroys material colors.

## Whole-studio palette

| Room family | Dominant practical | Accent | Shadow intention |
| --- | --- | --- | --- |
| Control rooms / mastering | 247/194/133 tungsten | 215/192/156 paper return | Soft shadows around desks |
| Live room / booths | 215/192/156 studio neutral | Dim tracking-window spill | Acoustic panels maintain texture |
| Tape archive | Warm paper/labels | Tape-machine pilot | Deep corners, searchable shelves |
| Reception / break room | Warm old business light | Security/warning lights | Legible diary and front exit |
| Navy service / machine room | 150/188/211 cold metal | Limited red emergency | More severe industrial contrast |
| Passageways | 193/204/200 neutral | Threshold spill | Enough light to understand doorways |

Colors are RGB *intent*, not physically calibrated lux, and must be visually
balanced in Roblox Studio on phone and desktop before we call them final.

## Lighting behavior as a game mechanic

**Dead / early exploration:** ceiling lights and active machines are off.
Only a few very weak guide and emergency pilots remain, allowing familiar
landmarks to exist without giving away the next task. The flashlight is still
important; the game does **not** start fully lit.

**Woken / first shock:** real studio work lights wake:
desk lamps, archive, patch board, live hall and control room equipment.
Tungsten in the music rooms contrasts with cooler navy service spaces.
An individual circuit may flicker. Players can navigate without being
blinded by excessive bloom.

**Red / second shock:** selected emergency and faulty lamps become stronger
and red. Most working lamps become weaker but continue to show material and
shape. The **entire building does not turn monochrome red**.
The original seven-second blackout and temporary fog event still trigger
at the authored moment; no new jumpscares were introduced.

**Dynamic pressure:** existing `LightingService.setPressure()` and
`fogIn()` continue to operate. Their fog behaves independently of lighting
state and should not obscure critical prompts.

**Blackout robustness:** if a state changes during a blackout, its scheduled
restoration still applies the correct latest state. New blackout calls
extend, rather than shorten, the interval. Flicker never permanently
leaves a lamp off when the current state changes.

## Lighting budget and architecture

- **40 new physical fixtures**, all inside named rooms, including
  **11 in Control A**. Eight are simulated indirect bounce proxies.
- Two added `SurfaceLight` fixtures provide broader, softer pools than
  point/spot lights; all are real Roblox lights, **not path tracers**.
- Most new lights have **Range 9–20** studs and brightness below **0.9**.
- **Only one new fixture** (Control A writing lamp) casts a dynamic shadow.
  Existing landmark ceiling fixtures in Live Hall and Reception also cast
  shadows, for a planned total of three authored shadow sources.
- Original 23 room ceilings, two extra live-room fixtures and six
  existing accent lamps are *retained* and reprofiled. This means the
  **full generated studio has about 71 Light objects**.
  That is a **source count, not a device performance certification**.
- No per-frame raycaster, CPU renderer, large particles or real-time
  custom shaders were added. Existing flickers use one bounded loop and
  ColorCorrection/Bloom are controlled through named singleton effects.
- If a handbuilt map does not declare `StudioLightingRig`, the previous
  generic LightingService behavior remains available.

## Physical / source contract

- `src/server/Maps/StudioLightingRig.luau` — light fixtures, warm/cold
  categorization, diffusers and authored bounce proxies; applies **after**
  other studio dressing, but **before** map parenting.
- `src/server/LightingService.luau` — authoritative dead/woken/red
  state, lamp settings, per-lamp blackout/flicker and global grading.
- `default.project.json` — persistent rendering quality settings.
- `tools/integration/check_integration.py` — static validation of 40
  unique fixtures, bounded intensity/range, room coordinates and renderer
  configuration.
- `tools/studio/StudioLightingSelfTest.server.luau` — developer-only
  Roblox Studio **Server Command Bar** state test; never run in a live public
  game and never ship it under ServerScriptService.

The script does not change map objectives, doorways, collision, the monster,
tapes or hub-place lighting.

## Required visual / performance acceptance before assets

After syncing the Match project, run the developer-only
`tools/studio/StudioLightingSelfTest.server.luau` from the Roblox Studio
**server Command Bar** during a private Play test. It deliberately switches
the match through `dead`, `woken`, `red` and a short blackout,
asserts the main practicals behave correctly, and restores the previous
state. Never run this in a public server.

Run both desktop and mobile Roblox Studio sessions:

1. **Start dark:** Verify exact initial visibility and flashlight need
   without pure-black voids or unusable reception diary.
2. **Control A first shock:** Standing at the mixing desk, inspect the
   transition from darkness to warm practicals; console controls must
   be readable. Check the 11 layers do not create unnatural blotches.
3. **Material response:** Wood should look warm, fabric matte, glass
   restrained, metal reflective enough to read. If fake bounce lights
   make a surface look flat or glowing, reduce their local intensity.
4. **Live room through glass:** The tracking window should separate
   spaces with real depth and a gentle rim, not a hard glowing band.
5. **Second shock:** Trigger red state and blackout. After blackout,
   check that console and exit remain distinguishable without a
   uniform saturated red screen.
6. **Mixed state/restart:** Switch states while blacked out, restart a
   round and verify original light materials and the correct current
   state. Watch for permanently disabled fixtures.
7. **Performance:** Profile a desktop-quality mode, a low-end mobile
   graphics setting, and 1–4 players in the live room and Control A.
   If needed, reduce low-value bounce/accent lights first; preserve
   the key/silhouette sources and playability.
8. **Compare references:** Take actual Studio screenshots from
   three camera angles at each lighting state. Tune color, brightness,
   softness, bloom and fog based on *those*, not illustrative renders.

**The lighting look is fully authored in source, but the actual fidelity
cannot be guaranteed before real Studio screenshots and performance
profiling. Only after this pass meets the visual benchmark should we
change furniture or asset meshes.**
