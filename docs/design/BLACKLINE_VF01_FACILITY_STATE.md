# Blackline VF-01 — one coherent, stateful signal system

**Status (2026-11-01):** implemented in source, automated regression/build checks passing; first-person Roblox Studio acceptance pending.

## Intent: quality over quantity

A convincing facility should communicate function and history without filling
every wall with random futuristic UI or an artificial "the building is alive"
animation. This pass concentrates on **four authored, human-scale pieces**,
not more generic scattered props. Each panel is at an architecturally chosen
location and changes only when existing gameplay events justify it.

- **Reception:** evacuation/egress authority, restrained green release status
  only after the emergency tape completes.
- **Staff Gallery:** electrical and program distribution status across the main
  architectural link between the public and recording wings.
- **Control A:** original channel-08 master-bus terminal, dark until real
  generator power, armed only when all required fuses are installed, and red
  only while the tape actually broadcasts.
- **Live Hall:** studio program-feed state, showing the remote effect of actions
  performed elsewhere in the complex.

Each panel uses a pressed-steel surround, restrained trim, inset glass,
one small status lens, and legible technical typography. The treatment should
feel like original equipment installed during Blackline's later retrofit.
The status lenses emit *no new PointLight/SurfaceLight*; the existing
generator-linked lighting and flashlight establish the scene.

## Authoritative lifecycle

The new `FacilityStateService` **does not own** an independent set of mission
flags, clocks or progression. It takes values directly from
`ObjectiveService` / `RoundState` and projects them onto the existing
objects. It has no server heartbeat loop and invents no monster-attracting
noise. The exact priority is:

| Phase | Actual prerequisite | Control A | Reception |
| --- | --- | --- | --- |
| Dead | generator unpowered | MASTER BUS OFFLINE | LOCKED / EMERGENCY |
| Powered | generator on, insufficient fuses | CHANNEL 08 / NO PATCH | SERVICE POWER |
| Routed | all required fuses fitted | MASTER BUS ARMED | SIGNAL ROUTED |
| Broadcast | emergency tape currently transmitting | CHANNEL 08 / ON AIR | EVACUATION / PENDING |
| Released | tape finished and actual exit release | MASTER TAPE COMPLETE | EGRESS RELEASED |

An engineer can follow this state sequence spatially: physically restore
electrical power in the service wing, install missing distribution fuses,
go to the original control room, start the emergency tape, then return through
the familiar public entrance after the alarm completes.

The previous static `StoryProps` signal legend was also corrected so
it **no longer falsely claims ON AIR** whenever the power supply is restored.

### Runtime ownership and safety

- `src/server/Maps/BlacklineFacilityDevices.luau` builds only these four
  Blackline props inside `Map.FacilitySystems`. Other maps remain unchanged.
- `src/server/FacilityStateService.luau` validates the four devices,
  maintains an idempotent render, and exposes the current
  `Map.FacilityPhase` / per-device phase attributes for review.
- `src/server/ObjectiveService.luau` refreshes the projection at the
  existing generator, fuse, tape-start, tape-end and round-reset boundaries.
- All prop Parts are **CanCollide=false, CanTouch=false, CanQuery=false**,
  have no gameplay interaction prompt, and are excluded from global PBR
  swapping. The monster's root, navigation, sound occlusion and detection are
  untouched.
- Power, fuse collection, existing generator hum, speaker noise, monster AI,
  exit lock, timing and game objectives retain their existing code paths.
- `FacilityStateService` safely does nothing for Radio, Foundry and
  hand-authored maps without the VF-01 device folder.

## Acceptance: when Studio returns

Pull `chatgpt/studio-art-pass` and synchronize Rojo; **no additional GLB
or texture upload is needed for this pass**. Run the Blackline map in Play
with Server Output visible.

1. On a fresh round, check the four panels remain unlit except for their
   legible low-contrast display text. Look for
   `[Dead Air] Blackline facility: Dead`.
2. Start the generator normally. Check `Powered` and confirm the Control A
   panel does **not** falsely display ON AIR.
3. Install all three fuses. Check `Routed` and the actual signal-path change.
4. Trigger the tape. Before it completes, check `Broadcast` and inspect
   that Control A and Live Hall display distinct, plausible warnings.
5. When the exit really unlocks, check `Released` in Reception.
6. Restart the round and verify every panel immediately returns to `Dead`.
7. At each stage, run `tools/studio/InspectVF01Facility.luau` in the
   **server Command Bar**. Save the `[VF01]` lines and any warnings.
8. View at 5, 15 and 30 studs under generator off/on and flashlight off/on.
   Evaluate readability, front-facing orientation, overbright/neon response,
   wall/door overlaps and material coherence. Remove or relocate any panel
   that competes with the recording console or original facility architecture.
9. Measure frame-time and memory with the unchanged map to confirm the
   limited panel design is not a new performance burden.

**Source acceptance:** `tools/validate_facility_vf01.py` is wired into
GitHub Actions and verifies all four stations, all five concrete phases, the
absence of new sound/lighting/physics load and actual objective-event wiring.

**Not yet qualified:** real Studio visual appearance, first-person sightline
clarity, replication of Gui/TextLabel changes and any gameplay navigation
under the new imported asset set.

## Production direction after acceptance

Only if this scene passes first-person review should VF-01 advance to
high-quality physically modeled devices, measured PBR materials, hand-authored
equipment wear and lighting. The immediate priority is **refinement of these
four locations**, not attaching dozens of new panels across 19 rooms or
inventing additional mission currencies.
