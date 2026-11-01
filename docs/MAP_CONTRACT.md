# Map contract

Contract v2 (1 November 2026): chapters choose the objectives they need; the generator, fuse box,
fuse spots, emergency tape deck and power lights are gone (see `docs/BUILD_PLAN.md`).

How a map must be laid out so the game's scripts can use it: the monster, the noise system, the
objectives and the rounds all read the map from this structure and nothing else. Follow it and a new
map works with no script changes.

The greybox in `src/server/MapBuilder.luau` is built exactly this way, so it's a working example of
every rule below. When the game starts it looks for `Workspace.Map`. If there is one it's used;
if not, the greybox is built instead. Any problem with the map is printed in Studio's Output window
as a line starting with `[Map]`.

## Structure (contract v2, chapter 1)

```
Workspace
└─ Map                      Model or Folder (exactly this name)
   ├─ Markers               Folder
   │  ├─ PlayerSpawn        Part: where players start, facing the part's front
   │  ├─ MonsterSpawn       Part: where the monster appears
   │  ├─ Speaker            Part, at least 1: where the building's speakers are
   │  ├─ ReelSpot           Part, 3 or more: archive shelf places a reel can sit (attribute Shelf = "4")
   │  ├─ OptionalTapeSpot   Part, 3 or more: where optional story tapes can appear
   │  └─ Throwable          Part, any number: a bottle, can or pipe lies here (attribute Item, optional)
   ├─ Areas                 Folder: one Folder per room, named after the room
   │  └─ <Room>             Folder
   │     ├─ Bounds          Part: a box covering the room, floor to ceiling
   │     └─ Spot            Part, 1 or more: places the monster walks to and stands
   ├─ Doors                 Folder: every door
   │  └─ <any name>         Part (the door leaf), attribute Kind (see Doors below)
   ├─ Booths                Folder (optional): soundproof rooms
   │  └─ <any name>         Part: a box covering the booth, attribute Door = name of its door
   ├─ HidingSpots           Folder (optional): wardrobes and lockers
   │  └─ <any name>         Part: the wardrobe itself, its front (-Z) face is the door; attribute Kind = "wardrobe" | "locker"
   ├─ Shutters              Folder (optional): navy quarantine shutters
   │  └─ <any name>         Part, built CLOSED (blocking the way); attributes Route, StartsOpen
   ├─ Lamps                 Folder (optional, old name PowerLights also works)
   │  └─ <any name>         Part with Light objects inside (PointLight, SpotLight, SurfaceLight)
   ├─ Objectives            Folder: the parts the chapter uses, by name (list below)
   └─ everything else       walls, floors, props, decoration: any folders, any names
```

Names of folders and of the special parts must match exactly (they're case-sensitive). Everything
else in the map can be organised however you like.

### Objectives for chapter 1 (The Last Session)

Each one is the actual prop (or an invisible part placed on it); its prompt appears there. Players
must be able to stand within 8 studs of each. The chapter refuses a map missing any of them and the
greybox is used instead (the Output says which are missing).

| Name | What it is |
| --- | --- |
| `BookingDiary` | The studio's booking diary, on the reception desk |
| `SessionLog` | The engineer's session log, in control room A |
| `TapeMachine` | The big multitrack tape machine (control room A): rethreaded, then reels load here |
| `Spares` | The maintenance cupboard with spare parts (break room) |
| `CardIndex` | The archive's card index cabinet |
| `RoadCase` | A road case in the live room; three instruments get piled on its top by script |
| `Safe` | The engineer's desk safe (control room B) |
| `MemorialProgramme` | The order of service from the wife's memorial (break room) |
| `PatchBay` | The patch bay next to the mixing desk |
| `MixingDesk` | The mixing desk (control room A): the last session is held here |
| `MailSlot` | The mail slot in the front doors, reachable from inside |
| `ExitZone` | A box just outside the front doors: touching it during Last Call is an escape |

## The pieces

**Markers, Bounds, Spots, Booth boxes and the ExitZone** are for scripts only. The game makes them
invisible and non-solid when it starts, so they can be visible while you build.

- **PlayerSpawn, MonsterSpawn, Spot:** place them roughly above the floor (between the floor and
  about 4 studs above it). The game finds the floor underneath and sets the right height. The floor
  under them has to be part of the Map.
- **PlayerSpawn** faces the way its front face points: point it into the building.
- **MonsterSpawn** should be far from PlayerSpawn. The monster appears there 15 seconds into the round.
- **Speaker:** put one at each place the building's speakers would be (ceilings, walls). Reel
  tracks, the full recording and the second shock's replayed sounds come from these.
- **ReelSpot:** a reel appears with its centre exactly at the marker (on a shelf). One holds the
  real reel A each round, the others hold ordinary reels. Give each an attribute **Shelf** with the
  label on that shelf (the card index points to it), and put a matching sign on the shelf.
- **OptionalTapeSpot:** spread them around; each round picks three.
- **Throwable:** optional attribute **Item** = `bottle`, `can` or `pipe` (random otherwise).

**Areas** are how the monster understands the building: it patrols from room to room, and searches
the spots near where it heard something.

- Make one Area per room or corridor.
- **Bounds** must cover the whole room and stay level with the world axes (not rotated).
- Give each room 1 to 9 **Spots**, spread around the room, at least 2.5 studs from walls and furniture.
  Big rooms need more; a small booth needs one.
- At least 2 Areas need Spots. Every place a player can hide should be near a Spot, or the monster
  will never look there.
- Rooms the chapter keeps shut (the basement and the flat in chapter 1) get **no Area**, or the
  monster will try to walk there.

**Doors**

- Each door is **one Part**, the door leaf. Its size must be width (X) × height (Y) × thickness (Z),
  with the hinge on its left edge (the -X side). It swings 90 degrees when opened.
- The leaf must be **Anchored**. Handles, panels and other decoration can be added as separate parts
  that are **not anchored**, have **CanCollide off**, and are joined to the leaf with a
  **WeldConstraint**; they then swing with it.
- Set the attribute **Kind**:
  - `normal`: an ordinary door;
  - `booth`: a soundproof booth's door;
  - `front`: the exit, locked until Last Call. There must be exactly one;
  - `sealed`: shut in plain sight for this chapter (the basement stairwell, chained behind the
    navy's quarantine seal). Never opens; it's a wall to the monster;
  - `barricaded`: also never opens, and something thumps behind it now and then (the door to the
    engineer's flat, barricaded from inside).
- The game adds the prompt, the swing and the pathfinding settings itself.

**Booths** (soundproof rooms): while a booth's door is shut, nothing said or done inside reaches the
monster, wherever it is. Make a box Part covering the inside of the booth, level with the world axes,
and give it the attribute **Door** with the exact name of its door in `Doors` (a `booth` door).

**Hiding spots**: the part is the wardrobe or locker itself, anchored and solid. Its front face
(-Z, the direction its LookVector points) is the door: point it into the room and leave about 3
studs clear in front of it. A hidden player stands at its centre, so make it at least 3 × 7 × 2.5.
The monster opens hiding spots near where it searches, so keep each one near an Area `Spot`.

**Shutters**: build each shutter where it stands when **closed**. The script lifts it by its own
height to open it, so leave that much room above it (inside the ceiling is fine). Attributes:
**Route** (a name; chapter 1 drops the one with `Route = "short"` during Last Call, so put it on the
short way from control room A to reception and make sure a longer way exists) and **StartsOpen**
(true by default).

**Lamps**: each child is a lamp Part with lights inside. The scripts switch them between three
states: **dead** (off; the lamp keeps its own look), **woken** (dim, warm and flickering, after the
first shock) and **red** (emergency red, after the second shock).

## Rules the scripts depend on

The monster is about 8.5 studs tall and needs room to move:

- **Doorways at least 6 studs wide and 9 tall. Corridors at least 6 wide. Ceilings at least 10.**
  Narrower and the monster can't plan a path through, so it can't reach the rooms beyond.
- **Stairs:** use a smooth ramp for collision, no steeper than 40 degrees. Put the visible steps on
  top with **CanCollide off**. Real steps confuse pathfinding.
- **Small clutter** (cables, papers, bottles, small boxes): **CanCollide off**, so neither players nor
  the monster snag on it.
- **Don't add jumps or gaps** the route depends on. The monster can't jump or climb.

Sound is blocked by anything with **CanQuery on**: each wall between a noise and the monster halves
how far the noise carries.

- Walls, floors, ceilings and closed doors: **CanQuery on** (the default).
- Things that shouldn't muffle sound (railings, foliage, light fixtures, open grilles, glass you
  want to hear through): **CanQuery off**.

Also:

- **No SpawnLocation** anywhere: the game removes them and spawns players itself.
- **Lighting** is darkened by the scripts at start (pitch black, short black fog). If the map
  brings its own lighting setup, set the attribute **OwnsLighting = true** on `Map` and the scripts
  won't touch Lighting. Note that `default.project.json` also sets some Lighting properties
  (Technology Future, Brightness, Ambient and others), and Rojo re-applies them on every sync: to
  change those, change them in that file.
- **Don't name anything else** `Map`, `Lobby` or `Monster` directly in Workspace. The lobby is built
  by the scripts, high above the map at y = 400, so keep the map well below that.
- Players are standard Roblox characters (about 5 studs tall, walking at 11 studs a second).

## Getting the map into the game

Work on your own branch (for example `chatgpt/studio-art-pass`) and bring in `main` regularly
(`git merge main` or `git rebase main`), so script changes and map changes don't drift apart.

The map has to end up as `Workspace.Map`. With several maps, store each one in the match place as
`ServerStorage.Maps.<map id>` (ids in `Config.MAPS`): the server copies the chosen one into
`Workspace.Map` when a match starts. For a single map in Studio, `Workspace.Map` directly also works.
Either way, the map gets there by:

1. **A model file in the repo** (recommended): save the map from Studio as a model file
   (right-click `Map` > Save to File > `.rbxmx`) at `assets/maps/Map.rbxmx`, and add it to
   `default.project.json` under the DataModel:
   ```json
   "Workspace": {
     "Map": { "$path": "assets/maps/Map.rbxmx" }
   }
   ```
   Rojo then puts it in Workspace like the scripts. Prefer `.rbxmx` (text) over `.rbxm` (binary) so
   changes show up in git.
2. **Built by code:** a ModuleScript that creates the `Map` model following this contract (the way
   `MapBuilder.luau` does for the greybox), called from `Main.server.luau` before the map is read.

This contract is shared ground, not a fence. If the map needs something it doesn't allow (glass
that lets sound through, a ladder, a different kind of door), change it: update this file and
`src/server/MapContract.luau` together, or ask and we'll work it out. Anyone can touch any file;
when you change something the other is in the middle of, say so in the commit message so it can be
checked together.

## Checking a map

1. Play in Studio and read the Output window. Every `[Map]` line is a problem. An `ERROR` means the
   map wasn't usable and the greybox was loaded instead; a `warning` means something is missing or
   risky but the round still runs.
2. Set `DEBUG_AI = true` in `src/shared/Config.luau`. A label over the monster shows what it's doing,
   and yellow dots show the path it's following. Watch it walk the whole building: any room it never
   reaches, or a spot where it stands still with "nav Failed", points to a doorway or corridor that's
   too narrow, a missing Spot, or something solid in the way.
3. Walk every route yourself as a player, crouching and sprinting, and make sure nothing snags.
