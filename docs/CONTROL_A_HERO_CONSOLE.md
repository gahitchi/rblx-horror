# Control Room A — DA-16 hero mixing console

**Branch:** `chatgpt/integrated-v1`  
**Build:** `0.8.7-control-a-console`  
**Status:** native Roblox source asset authored and wired into the chapter. Offline geometry previews produced; NOT yet tested or photographed in Roblox Studio.

## What was built

A purpose-designed late-1980s 16-channel analog recording desk with:
- Sixteen individually inset channel strips, each with three rotary controls
  and index notches, record-arm/status button, slot and individually positioned
  physical fader handle, and labelled number
- Eight warm-face VU meters in a unified wooden meter bridge, each with a
  glass lens, separate needle and front trim; an analogue manufacturer plate
- Dual master faders, pan controls and a dedicated master/bus indicator bank
- Inclined dark metal chassis, restrained hardwood cheeks and hand rest,
  metal trim, front knee panel and paper reading shelf
- A separate place for the session log, in front of the controls, with the
  same authoritative `SessionLog` prompt as before
- Indicator color/material synchronized with the chapter's
  `dead` / `woken` / `red` lighting states and blackouts

The desk remains intentionally noncolliding and non-queryable visual geometry.
The original `Map.Objectives.MixingDesk` remains the invisible solid
interaction volume and authoritative source for Chapter 1's puzzle. It has not
been deleted or replaced by a duplicate model. The session-log document is the
same objective moved slightly forward to its new reading shelf.

## Source integration

- `src/server/Maps/StudioHeroConsole.luau`: all console geometry and print labels
- `src/server/Maps/StudioProductionDetail.luau`: one call to build the
  hero asset in `Props.ProductionDressing.ControlA`
- `src/server/Maps/StudioGroundFloor.luau`: preserves old game desk, removes
  duplicate crude faders and repositions the real session log
- `src/server/LightingService.luau`: power-state connection for the
  channel and bus indicators; no extra dynamic lighting sources
- `tools/integration/check_integration.py`: protects asset-to-objective
  integration and details, plus previous lighting contracts

The main drum room, archive, hub, Engineer and 23-room geometry are unchanged.

## Offline visual previews

The three separately provided PNGs were rendered from the authored part
geometry in an independent offline projection renderer. They are
**representations of the source geometry**, not:
- actual Roblox screenshots or playtest evidence
- photographs of a real recording studio
- a promise of path tracing, native PBR shading or final textures

The preview uses simplified local shading and color approximations. Roblox
material response, exact text visibility, playability and the elaborate
lighting setup must be evaluated inside Roblox Studio.

## Acceptance criteria for a true gold-standard asset

1. **Player eye level:** in first-person near the chair, controls should
   be readable from believable working distance; the desk should not
   look like one scaled-up block.
2. **Prompt clearance:** SessionLog can be read from the shelf; MixingDesk
   still opens its original puzzle. No visual component blocks a raycast,
   hiding interaction or AI path.
3. **Material polish:** hardwood, brushed painted metal, meter lenses and
   cream fader handles look credible in the studio's Realistic renderer.
   Tiny components must remain readable, not appear as pixel noise.
4. **Lighting states:** channel lights are off before the first shock,
   awake during normal work and respond to blackout/emergency. No added
   shadow-casting practicals were introduced by the console.
5. **Performance:** the many small parts and SurfaceGuis must be profiled
   on lower-end mobile. If the desk causes excess draw calls, consolidate
   repeated labels and channel plates into fewer MeshParts or atlases while
   keeping existing collision and the source design.
6. **AAA upgrade path:** replace boxy wood-frame corners with properly
   chamfered meshes, authored material textures, normal maps and correct
   screw/knob geometry after the first Studio screenshot review.

**Important:** this is a quality intermediate asset for a Roblox build,
not a completed AAA-ready mesh. Real Studio screenshots must drive final
refinement; don't label offline source previews as proof of in-engine quality.
