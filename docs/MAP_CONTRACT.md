# Map contract

How a map must be laid out so the game's scripts can use it: the monster, the noise system, the
objectives and the rounds all read the map from this structure and nothing else. Follow it and a new
map works with no script changes.

The production maps in `src/server/Maps/Kit.luau` and `Layouts.luau` implement these rules.
`src/server/MapBuilder.luau` dispatches to one of three new environments (`studio`, `radio`,
`foundry`). At startup, an existing `Workspace.Map` or a matching map in
`ServerStorage.Maps.<id>` is used first; otherwise the corresponding procedural production
map is built. Any problem with the map is printed in Studio's Output window
as a line starting with `[Map]`.

## Structure

```
Workspace
└─ Map                      Model or Folder (exactly this name)
   ├─ Markers               Folder
   │  ├─ PlayerSpawn        Part: where players start, facing the part's front
   │  ├─ MonsterSpawn       Part: where the monster appears
   │  ├─ FuseSpot           Part, at least 3 (more is better): where a fuse can appear
   │  └─ Speaker            Part, at least 1: where the emergency alarm plays from
   ├─ Areas                 Folder: one Folder per room, named after the room
   │  └─ <Room>             Folder
   │     ├─ Bounds          Part: a box covering the room, floor to ceiling
   │     └─ Spot            Part, 1 or more: places the monster walks to and stands
   ├─ Doors                 Folder: every door that opens
   │  └─ <any name>         Part (the door leaf), attribute Kind = "normal" | "booth" | "front"
   ├─ Booths                Folder (optional): soundproof rooms
   │  └─ <any name>         Part: a box covering the booth, attribute Door = name of its door
   ├─ Objectives            Folder
   │  ├─ Generator          Part: players hold E here to pull the starter
   │  ├─ FuseBox            Part: players fit fuses here
   │  ├─ TapeDeck           Part: plays the emergency tape
   │  └─ ExitZone           Part: a box players walk into to escape (just outside the front door)
   ├─ PowerLights           Folder (optional): lamps that come on with the generator
   │  └─ <any name>         Part with Light objects inside (PointLight, SpotLight, SurfaceLight)
   └─ everything else       walls, floors, props, decoration: any folders, any names
```

Names of folders and of the special parts must match exactly (they're case-sensitive). Everything
else in the map can be organised however you like.

## The pieces

**Markers, Bounds, Spots, Booth boxes and the ExitZone** are for scripts only. The game makes them
invisible and non-solid when it starts, so they can be visible while you build.

- **PlayerSpawn, MonsterSpawn, Spot:** place them roughly above the floor (between the floor and
  about 4 studs above it). The game finds the floor underneath and sets the right height. The floor
  under them has to be part of the Map.
- **PlayerSpawn** faces the way its front face points: point it into the building.
- **MonsterSpawn** should be far from PlayerSpawn. The monster appears there 15 seconds into the round.
- **FuseSpot:** the fuse appears with its centre exactly where the marker's centre is (on a desk, a
  shelf, the floor). Spread them across the map. Each round picks 3 at random.
- **Speaker:** put one at each place the building's speakers would be (ceilings, walls). The alarm
  sound and its noise come from these.

**Areas** are how the monster understands the building: it patrols from room to room, and searches
the spots near where it heard something.

- Make one Area per room or corridor.
- **Bounds** must cover the whole room and stay level with the world axes (not rotated).
- Give each room 1 to 9 **Spots**, spread around the room, at least 2.5 studs from walls and furniture.
  Big rooms need more; a small booth needs one.
- At least 2 Areas need Spots. Every place a player can hide should be near a Spot, or the monster
  will never look there.

**Doors**

- Each door is **one Part**, the door leaf. Its size must be width (X) × height (Y) × thickness (Z),
  with the hinge on its left edge (the -X side). It swings 90 degrees when opened.
- The leaf must be **Anchored**. Handles, panels and other decoration can be added as separate parts
  that are **not anchored**, have **CanCollide off**, and are joined to the leaf with a
  **WeldConstraint**; they then swing with it.
- Set the attribute **Kind** to `normal`, `booth` (a soundproof booth's door) or `front` (the exit,
  locked until the emergency tape finishes). There must be exactly one `front` door.
- The game adds the prompt, the swing and the pathfinding settings itself.

**Booths** (soundproof rooms): while a booth's door is shut, nothing said or done inside reaches the
monster, wherever it is. Make a box Part covering the inside of the booth, level with the world axes,
and give it the attribute **Door** with the exact name of its door in `Doors` (a `booth` door).

**Objectives:** Generator, FuseBox and TapeDeck are where the hold-E prompts appear, so make them
the actual machine (or an invisible part placed on it). Players must be able to stand within 8 studs
of each. The ExitZone is a box just outside the front door; touching it after the doors open is an
escape.

**PowerLights:** each child is a lamp Part with lights inside. With the power off the lights are off
and the lamp keeps its own look. When the generator runs the lights switch on and the lamp turns Neon.
Give the lamp a Color3 attribute **OnColor** to choose its lit colour.

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
2. **Built by code:** the current default. `MapBuilder.build(mapId)` dispatches to the three
   configured production layouts built by `Maps/Kit.luau`. The model must implement the same
   contract as a Studio-authored map, and is read by `MapContract` before gameplay starts.

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
