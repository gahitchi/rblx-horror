# Dead Air — grounded, purpose-built environment pass

**Version:** `0.9.1-grounded-interiors`  
**Branch:** `chatgpt/integrated-v1`  
**Verification:** source/coordinate checks only; awaiting new Roblox Studio screenshots and movement tests.

## Why this is different

The preceding furniture upgrade made more structural parts collide, but
it did not fix a deeper flaw: visual props were authored using arbitrary
world coordinates, with no relationship to the table, shelf, wall or
instrument that was supposed to support them.

This caused **literal floating decorations**, physically unsupported
instruments, and generic table slabs. The only sustainable process is
to build coherent objects around their intended function and **verify
their geometry against the authored location**.

## Corrected authored objects

| Location | Problem from source | Correction | Physical contract |
| --- | --- | --- | --- |
| Reception counter | Glass overlay sat roughly 0.4 studs above actual wooden worktop; telephone, bell and pen cup followed imaginary higher surface | Replace hovering glass with a writing mat resting on real top; reposition the phone, bell, pencil cup and pens | Mat and contents align with `ReceptionCounterTop`, counter remains solid, diary unchanged |
| Public vinyl display | Three oversized sleeves hovered on an empty wall | Build an anchored wooden display shelf with three wall brackets; seat sleeves at exact deck height | Shelf is collidable and fixed to wall; sleeves are lightweight |
| Reception coffee table | Generic flat slab and inconsistent loose magazine | Joiner-style top, solid cylindrical legs and support aprons; adjust magazine to table surface | Table has real solid tabletop/leg collisions |
| Staff break table | Vase positioned outside its table; tapes and flowers placed at unrelated heights | Place memorial vase and labelled tapes on the same real table, keep programme visible, attach flowers to vase | No decorative arrangement is suspended over empty floor |
| Staff coffee service | Coffee machine partly embedded in and unsupported by counter; mug near outer edge | Raise machine to actual countertop, move mug fully onto the top, keep supplies adjacent | Counter now collides and is physically load-bearing |
| Tape archive | Four featureless 6-stud blocks, 27 floating cassette props at unrelated X/Z coordinates | Four three-tier wall-aligned cabinets with side panels, back panels, floor plinths and **12 solid shelves**; 48 cassette cases all rest on those decks | All cabinet structure anchored, decks collidable; four accessible `ReelSpot` markers preserved |
| Archive notices | Poster inside the room, not on plausible wall | Remove disconnected poster; retain real wall/shelf identification signage | No floor-floating sign |
| Janitor shelving | Three metal shelves with no supporting uprights | Add two floor-to-top steel frame posts and true solid metal decks | All supply bottles remain on decks |
| Recording instruments | Drum shells, rack toms, stage guitar and keyboard not fully supported | Add bass-drum cradle, tom bar, cymbal feet, guitar stand; fit keyboard legs to case underside and mic base to stand | Installed equipment has believable support, primary instrument/case hulls solid |

## Updated table design

`StudioFurnitureAsset.table` is not a single flat cuboid. It now
creates a grounded worktop, wood underlayer, edge-beading,
four cylindrical legs with sockets and floor shoes, underside rails
and cross bracing. The original placement and interaction coordinates
are unchanged, and the knee space remains accessible.

The six gameplay hiding desks remain authored separately in
`StudioGroundFloor.underDesk`. Their front entrance and real
back sight-occlusion panel are preserved. Their joinery was tightened
and repeated toe-kick geometry removed. The naval maintenance desk
uses steel rather than painted wood.

The work still uses native Parts, so this is **not the final custom
mesh/PBR quality bar**. The correct next visual step after support
validation is sculpted/beveled custom meshes and accurate materials,
not another layer of decorative boxes.

## No random placement rule

Every new detail must have:

1. A reason to exist (e.g. a session archivist needs reachable shelves);
2. A specific host object/room (not just arbitrary X/Y/Z);
3. A realistic physical attachment or floor support;
4. Matching collision/line-of-sight behavior where players and the
   Engineer can interact with it;
5. An explicit check if important to a puzzle or traversal.

No gameplay-relevant part is made unanchored merely for realism:
built-in counters, racks and furniture remain static, while the
two prior wheeled loading cases continue to use real physics.

## Testing

Start Match place from branch `chatgpt/integrated-v1`, press Play and
verify startup prints `v0.9.1-grounded-interiors`. Compare photographs
at character eye level rather than relying on offline concept previews.

Run `tools/studio/WorldPlacementSelfTest.server.luau` using the
**Server Command Bar during a private Play session**. It checks:
- grounded collidable furniture across all grouped models,
- four structural archive cabinets and twelve supported shelf decks,
- all 48 cassette cases resting exactly on a shelf,
- receptionist desk mat, phone, bell and cup aligned with counter,
- memorial vase, coffee mug, magazine and vinyl sleeves supported,
- four chapter ReelSpot prompts retained in reachable aisle.

The previous `tools/studio/PhysicalAssetsSelfTest.server.luau`
should also pass, and the Engineer must still traverse rooms with
all under-desk hiding interactions intact.

**Status: not playtested or profiled.** Actual overlap, shadows,
streaming and AI path clearance must be checked in the engine; no
claim that every prop in all 23 rooms has been perfected yet.
