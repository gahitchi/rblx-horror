# Dead Air — Physical Asset Foundation

**Build:** `0.9.0-physical-assets`  
**Branch:** `chatgpt/integrated-v1`  
**Status:** scripted, committed, source-audited; **not yet engine playtested**.

## Why this pass exists

Playtesting showed that the recording studio felt full of floating or scattered
rectangular blocks with inconsistent collisions. Increasing prop quantity
would make it worse. This milestone replaces the *shared furniture
construction system* and two visible fake loading-bay props with objects
designed around real contact, plausible supports and grounded purpose.

This is **not an AAA-final mesh pass**. It is a functioning, extensible
physical foundation in the actual game. Mesh bevels, texture maps and
art-direction polish remain necessary.

## Two clear asset categories

### Fixed studio furniture

Real installed fixtures **should not** slide around when players bump them.
They are anchored on purpose, but have true physical collisions and
raycast occlusion on the structure players actually touch:

- Tables: real individual solid tops and cylindrical legs; open knee
  spaces, edge trim and an apron, rather than a filled cuboid.
- Studio chairs: actual padded seat and back with collision, metal swivel
  post and four supported feet. Decorative seams, caster details and
  trim do not add expensive collision surfaces.
- Waiting-room sofas: solid seats, wood frame, arms and back,
  individual cushions and fabric piping; not a single flat cuboid.
- Rack cabinets: full collidable rack chassis with mounted metal rails,
  per-unit controls, ventilation, indicators and screws.
- Control-room monitors: real-collision speaker cabinets and grounded
  monitor stand bases; nonessential cone/screw detail stays lightweight.
- Machine room: replaces three old unadorned rectangular MachineRack
  props with rack models from the same new library.

The old `StudioDecorKit.table/chair/sofa/rack` API still works. This
change upgrades their output **across all rooms** that use those helpers,
without altering authored placements or moving gameplay objectives.

### Real dynamic equipment

The loading bay now has **two real 4-wheel flight cases** rather than
an immovable block and a box stacked on a fake trolley.

Each case has:
- One full-size **collidable, unanchored main body** with deliberate
  density, friction, elasticity and a stable collision hull.
- Four independently simulated, **collidable cylindrical wheels**.
- Four `HingeConstraint` axles with correctly aligned attachments.
- Reinforced metal edge extrusions, corner pieces, side handles,
  a stamped label and readable stage-equipment proportions.
- Rigid welded visual detailing (massless, noncolliding) that follows
  the moving body as the player pushes it.
- Explicit **server network ownership** to avoid client-owned
  exploitably teleported props. The engine naturally handles gravity,
  contact, pushing and wheel motion. There is no custom position
  animation or client-side fake physics.

Only **two** dynamic cases are spawned, inside the loading area.
Dynamic cases can move unpredictably and should be profiled before more
are introduced. Unlike the fixed assets, they can topple or be shoved.

The chapter-critical `Objectives.RoadCase` remains anchored and
interactive, with extra hardware and the original objective position.
Its part still handles all reel searches and prompts. The hero mixing
console's original collider, desk puzzle, story documents, closets/desk
hiding and the Engineer's AI are not changed in this milestone.

## Why not every prop simulates physics

For a 1–4 player Roblox horror level, physics for every chair, paper,
pencil, cup and rack would increase replication cost, create path
obstruction and produce random-looking scatter. Heavy furniture has
credible static collision; deliberately movable equipment uses dynamic
rigid bodies. Tiny trim does not need a separate collision hull.

This approach uses the Roblox physics engine rather than simulating
it in Luau. It follows Roblox's assembly, weld, constraints and
network-ownership guidance:

- https://create.roblox.com/docs/physics/assemblies
- https://create.roblox.com/docs/physics
- https://create.roblox.com/docs/physics/network-ownership

## Files

- `src/server/Maps/StudioFurnitureAsset.luau` — collision-aware
  furniture library
- `src/server/Maps/StudioDecorKit.luau` — backwards-compatible
  table/chair/sofa/rack wrappers
- `src/server/Maps/StudioPhysicalAssets.luau` — physics case
  assemblies and fixed road-case detail
- `src/server/Maps/StudioGroundFloor.luau` — two target upgrades
  and three detailed machine racks
- `src/server/Maps/StudioServiceDetail.luau` — replacement of fake
  trolley/stacked case with the second moving case
- `src/server/Maps/StudioProductionDetail.luau` — true monitor
  collision and grounded stands
- `tools/studio/PhysicalAssetsSelfTest.server.luau` — physical
  assembly tests in Studio Server Command Bar
- `tools/integration/check_integration.py` — source contract checks

## Studio acceptance criteria

On a fresh Match Baseplate with the updated Rojo session:

1. Confirm Output says `v0.9.0-physical-assets`, not the older 0.8.9.
2. In Control A, collide with the chair, speaker cabinets, tabletop
   and the mixing console. You should not pass straight through
   them or encounter a giant invisible collision box.
3. In reception, sit near the sofa and coffee table, attempt to walk
   through the sofa frame, and check cushions aren't inexplicably
   suspended or overlapping nearby objects.
4. In the machine room, inspect the three rack assemblies, ensure
   mounted controls face the accessible side, and make sure the
   Engineer does not stand atop the rack or walk through it.
5. In the loading bay, push both flight cases. Check wheel rotation,
   gravity, body collision and whether the cases can topple or
   obstruct the hall. Ensure no parts are welded to the level.
6. In the live room, use the reel road case as before. It must
   keep its original story prompt and NOT drift away.
7. Return to under-desk hiding; the furniture upgrade must not
   break "Get under", breathing, E/Step out or catch inspections.
8. Run `tools/studio/PhysicalAssetsSelfTest.server.luau` from
   Studio's **Server** Command Bar during a private Play session.
   It asserts the two cases have real, unanchored physics bodies,
   collidable wheels, four hinge axles and server ownership.

**Do not mark this visual quality as final until we have actual Studio
screenshots and a brief 1–4 player physics/performance test.**
If FPS or navigation deteriorates, preserve correct collision for
touchable surfaces and trim decorative faces before adding more parts.

## Next art milestones

1. Realize a small selection of benchmark equipment with authored
   curved meshes, weighted normals, UVs, trim sheets and real PBR
   material maps rather than extending hundreds of native Parts.
2. Replace old box-only **Spares cabinet, PatchBay and TapeMachine**
   visuals while keeping their existing gameplay colliders and prompts.
3. Replace scattered minor props with purposeful room-specific clusters.
4. Assess the Engineer's navigation against the new furniture and
   tune collision hulls, without relocating chapter clues.

The guiding rule is **quality per object, with physical plausibility**
rather than filling empty square footage with placeholder boxes.
