# Dead Air — Coherent Asset Pass (0.9.2)

**Branch:** `chatgpt/integrated-v1`  
**Status:** source implementation complete; **in-engine visual, collision, pathfinding and device-performance acceptance pending**.

## Art direction

This pass aims for **convincing, lived-in 1987 recording-studio assets within Roblox**, not an AAA polygon count. A believable object should be recognizable at first glance, be physically supported, use plausible proportions, and exist because someone who works in the building needed it.

Objects are divided into installed furniture (anchored with accurate structural colliders), moving equipment (genuine Roblox rigid-body physics in the loading bay), and light decorative details (no physical collision). More clutter is not a sign of more realism.

## Pass 1 — Reusable asset families

| Asset type | Rework | Collision / rationale |
| --- | --- | --- |
| Worktables | Lowered minimum depth to permit the actual isolation-booth guitar-case shelf; preserved real legs/rails and top | Fixed top + leg contacts, no invisible solid middle |
| Hiding desks / counters | Replaced two full-depth side panels that looked like box walls with four corner legs, side aprons and a shallow stationery drawer | Accessible central hiding space; solid rear screen still blocks vision |
| Gallery benches | Four handmade bench assemblies with distinct seat boards, actual legs and under-seat rails | Seats and leg colliders; no solid cubic volume |
| Storage cabinets | Reusable floor-to-top case, internal shelves, dual doors, label/handle details | Installed collidable furniture rather than loose filing blocks |
| Objective cabinet facades | Detailed two-door Spares surface; four actual card-index drawer faces and pulls | Original chapter objective geometry and prompts stay authoritative; no duplicate solid body |
| Studio equipment | Reuse established detailed rack, chairs/sofas and worktable helpers instead of making new featureless cubes | Collision remains coherent and performance bounded |

## Pass 2 — Purpose-built rooms

**Control Room A**
- Retained the DA-16 hero mixing desk and source-aware three-state lighting.
- Removed overlapping legacy reel-guide cylinders. The real tape-machine objective now has two reels, hub centers, a control face and structural rail.
- Replaced three free-floating, disconnected patch cords with a complete face fitted to the actual PatchBay, 32 jacks and three cords spanning physical connectors.
- Removed the duplicate hard-coded patch-bay visuals from production dressing.

**Control Room B**
- The edit counter still has open solid legs and a rear screen for hiding.
- Editor's deck and reel tops have aligned support heights.
- Converted three upright PaperFiling placeholders into a mounted staff archive cabinet with two doors.
- The original Safe remains the puzzle target; new hinges, dial, lever and trim mount to its real face.

**Mastering suite**
- Replaced the old opaque box-bottom console with a true open-legged mastering table, inclined compact control surface, aligned faders and a physically supported meter cabinet.

**Archive**
- Preserved previous repair: four three-tier grounded cabinets, twelve shelf decks, 48 cassette cases and reachable ReelSpot chapter prompts.
- Card-index objective now reads as a functional four-drawer reference cabinet rather than a teal box.

**Reception and break room**
- Previous desk accessory and memorial object placement repairs remain.
- Reception desk now has usable knee clearance, visible legs and a small working drawer.
- The refrigerator is a collision-solid appliance with fitted door, handle, freezer seam and toe grille.
- Built four purpose-made waiting benches in the viewing-gallery route, replacing big slab blocks.

**Live room / isolation booths**
- Replaced the floating guitar case with a low, grounded closed case.
- Added two feet to each of the two solid gobos; these remain valid opaque visual cover.
- The vocal-booth music stand has a leg/foot and paper lip; pop filter has a support arm.
- The isolation-booth shelf is now valid for the reusable table dimensions and carries a recognizable case.
- The drum stands, guitar stand and keyboard supports from 0.9.1 remain.

**Service / machine / janitor / loading**
- Removed old rack-face overlays: one machine-room outboard cabinet now owns each set of controls.
- Removed duplicate toilet/sink parts from the original base map; each washroom now gets only its dedicated ceramic fixtures with real collisions.
- Added taps and drains to pedestal sinks, moved the Staff WC mirror to a real wall; toilet seats are low-profile, not rotated upright.
- Replaced box-shaped bucket with a round one and handle; the mop closet retains its supported shelves.
- Grounded three loading equipment crates on the floor instead of a diagonally rising unsupported row, and kept two genuinely physics-based rolling cases.
- Grounded the shut roller door and added wall brackets to the fire-hose fitting.

## Why not every asset moves

A fixed cabinet, toilet, counter, built-in shelf or rack **should stay fixed**, with correctly sized collision. The rolling loading-bay flight cases use Roblox unanchored assemblies, four HingeConstraints each, realistic wheel friction and server-controlled ownership. A cup, hinge, cassette label or fader need not run its own physics simulation to feel real.

## What was deliberately removed

Repeated empty-space ornaments or duplicate geometry: base-map toilet/sink blocks, JanitorShelf/MopBucket, base-map pole microphones and stray reels, machine-room extra rack faces/meters, free-floating PatchCable parts, orphan SafeDial, PaperFiling slabs and rectangular gallery benches.

No Chapter 1 objective, room, doorway, Engineer AI behavior, lighting fixture, hiding marker or route graph is removed.

## Tests and approval gate

The static `tools/integration/check_integration.py` now checks reusable construction methods, supporting details, room-specific integration, removal of conflicting placeholder names and build version. The new developer-only `tools/studio/AssetPassSelfTest.server.luau` checks prop counts, fixtures, old duplicate names and preserved objective objects. The existing `WorldPlacementSelfTest.server.luau`, `PhysicalAssetsSelfTest.server.luau` and `DeskCoverSelfTest.server.luau` remain useful.

**Playtest checklist:**
1. Press Play from the Match Rojo project and confirm `0.9.2-convincing-assets`.
2. Enter Reception, Control A, Control B, the Mastering Suite, viewing gallery, Tape Archive, service rooms and loading bay. Inspect from first-person eye level.
3. Test actual desk hiding/Step out and the Engineer's visual occlusion: no extra prop should block a prompt or trap the character.
4. Walk into large benches, cabinets, monitor stands and bathroom fixtures. Check contact geometry and no hidden invisible boxes.
5. Confirm CardIndex, Safe, PatchBay and Spares retain their original prompts and chapter state.
6. Inspect console/tape path, music stands, guitar case, drawers, all shelf objects and door clearance for floating or intersecting details.
7. Push both wheeled flight cases; profile mobile/desktop FPS before increasing dynamic-body count.
8. Run the Studio-only regression scripts using the **Server Command Bar** in a private test. If one fails, send its exact error to correct that fixture.

**Important limitation:** this is a wide source pass, **not evidence of complete finished realism**. It is intentionally made of simple, purpose-built Roblox geometry; a small number of custom curves/bevels/material variants can still be added once actual Studio screenshots reveal the remaining weak assets.
