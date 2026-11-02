# Map brief: the hub

For ChatGPT, who leads the map and the graphical side. Written 2 November 2026. Build it **after**
the studio's ground floor (`docs/MAP_BRIEF_STUDIO.md`): the studio is the launch map, and the hub
can stay a plain room until then.

Read `docs/DIRECTION.md` first, then the design doc (link in `CLAUDE.md`): its "Story" and "The hub:
the edge of Wrenmouth" sections are the source for everything below. Gabriel has the Wrenmouth
look-book with drawings of this place (the hub scene and the plan); ask him for screenshots.

## What this place is

The edge of Wrenmouth on the night the crew arrives, in 2026. The coast road runs along a cliff top
and stops at the navy's quarantine fence; beyond it, the road drops into the town, which has been
sealed and dark since 1987. The handler (the engineer's son, the town's only survivor) has parked
his van in a lay-by at the fence. This is where crews gather, listen to what they recovered, and
go in.

It's the only place in the game that's safe, and the only one with steady warm light. It should
feel like the last warm place, looking at something cold: warm light on one side, the fence, the
fog and the dark town on the other.

## Style

The same rules as every zone (`docs/DIRECTION.md` and the look-book):

- **Stylized, not realistic**, readable on a phone. Shape first, then lighting, then texture.
- **Mood from light, fog and sound.** Roblox materials plus a few custom textures.
- **About an afternoon per asset.** Low part and triangle counts.
- **Colour meaning:** warm (sodium amber `#E8A24A`, the van's cream `#CDBB9A` and rust `#8A4A2A`)
  is the people; cold (navy grey `#5B636B`, seal yellow `#D9B33A`) is the navy; night and fog
  (`#0F1A22`, `#1E262B`, `#3D4A55`) is the ground everything sits on. The pale Choir glow
  (`#C9DBE6`) is used only in the sky over the town. No red here: red means danger, and there is
  none in the hub.

## Layout

About 150 by 130 studs, one small place. The hub place uses the default third-person camera
(`hub.project.json`), so build at normal character scale and keep sight lines open.

From west to east (the plan in the look-book):

- **Spawn** at the west end of a gravel lay-by, facing east: the first thing players see is the
  van's warm light, the gate and the town beyond the fence.
- **The lay-by** north of the road: gravel, the van, the kit crate, a streetlamp.
- **The coast road** running east to the fence, worn tarmac with a faded centre line.
- **The quarantine fence** crossing the road and running from the cliff to the moorland: chain-link
  with navy signs ("NAVY · QUARANTINE · NO ENTRY", stencilled, yellow on grey).
- **The gate**: a striped barrier arm across the road, closed.
- **The checkpoint hut** just west of the gate, north side: abandoned, one dark window, its
  noticeboard facing the lay-by.
- **The cliff edge** along the north side, with a low railing. Below it, far down, the sea.
- **The lookout** at the cliff edge, northwest: a bench and a coin-operated telescope pointed at the
  town and the lighthouse.
- **Beyond the fence**: the road dropping toward the town and fading into fog. Players can't cross
  the fence.
- **Bounds**: the cliff railing (north), the fence (east), and low moorland walls lost in fog
  (south and west). Invisible walls behind the fog where needed.

## The places that matter

1. **The van.** The handler's old camper van (an invented design, no real brand): cream with a
   rust stripe, rear doors wide open, warm tungsten light inside spilling onto the gravel. Inside:
   a rack of homemade filter electronics with small green LEDs (he builds the crew's headsets),
   a reel-to-reel tape deck, a town map of Wrenmouth pinned to the wall with string and pins, a
   fold-out table, a camping stool. The handler himself sits inside (a simple seated figure; he
   can come later). Players walk up to the rear doors to use the tape deck and the map.
2. **The crew board.** The checkpoint hut's noticeboard: a corkboard under a little roof, with
   paper sheets pinned to it (crews). The crew panel will open here.
3. **The gate.** When a crew starts, the barrier lifts and the crew walks through into the fog;
   the screen fades and they're teleported. Leave room for a group of four to walk through it side
   by side.
4. **The kit crate.** The handler's equipment trunk beside the van: an open wooden or metal case
   with headsets, flashlights, walkies and folded jackets. Cosmetics are chosen here.
5. **The lookout.** The telescope's view takes in the whole town. Buildings the player has cleared
   show a warm light in a window; the radio station's mast on the hill blinks red once chapter 3
   is cleared. This is the hub's way of showing progress, so the town must be visible from here.

## The view: the town, the sky and the sea

The view is the hub's main feature. It doesn't need to be walkable, just read well from the
lay-by and the lookout:

- **The town** beyond the fence, down the slope: dark rooftops in fog, a few chimneys. Low detail,
  silhouettes. The studio, the radio station on its hill (with its mast), the cannery by the river
  mouth, and the listening station on the headland should each be recognisable by shape from the
  lookout, because they light up as the story progresses (see markers below).
- **The lighthouse** on the headland across the bay: white with two red bands, its lamp lit, a
  slow beam sweeping over the sea.
- **The Choir**: a vast, barely visible pale shape in the fog above the town. Never clear, never
  explained. A large soft glow or a few faint vertical streaks; subtle enough that some players
  only notice it on their third visit.
- **The sea** to the north, far below the cliff, dark blue-black.

## Light

- One sodium streetlamp by the lay-by (amber).
- The van's interior: steady, warm tungsten. The only steady warm light in the game.
- The lighthouse beam sweeping every few seconds.
- Everything else: blue-grey night and fog. The checkpoint hut stays dark.
- Fog thick enough to hide the far ends of the road and the moorland bounds, thin enough to see the
  town from the lookout.

## Sound (for the sound catalog)

Waves below the cliff, wind through the fence, the foghorn every minute or so, the van's tape deck
murmuring. No music in the background; the sound of the place does the work.

## Markers the scripts will read

The rough hub (later, by Claude) will hook the places above up to the lobby, tape deck and
cosmetics screens. Build the hub as a Model named `Hub` in Workspace, with these names, so it works
without script changes. Markers are for scripts only and can be invisible.

```
Workspace
└─ Hub                     Model (exactly this name)
   ├─ HubSpawn             Part: where players appear (already used by the scripts today)
   ├─ Markers              Folder
   │  ├─ VanDoors          Part: where players stand to use the tape deck and the town map
   │  ├─ CrewBoard         Part: the noticeboard face (the crew panel opens here)
   │  ├─ KitCrate          Part: the crate (cosmetics open here)
   │  ├─ Telescope         Part: the telescope; its front face (-Z) points at the town
   │  ├─ GatePath          Part: a box covering the way through the gate (crews walk into it)
   │  └─ Foghorn           Part: where the foghorn sounds from (out by the lighthouse)
   ├─ Gate                 Model: the barrier arm, with a hinge part named "Hinge"
   ├─ Handler              Model (optional): the seated handler in the van
   ├─ TownLights           Folder: one Part per building, named after its chapter id
   │  ├─ studio1           Part with a light inside: a window in the studio
   │  ├─ studio2           (each part is off until that chapter is cleared)
   │  ├─ studio3
   │  └─ RadioMast         Part with a red light: the mast's aviation lamp
   └─ everything else      any folders, any names
```

Chapter ids follow `Config.CHAPTERS` (`studio1`, `studio2`, `studio3`, later the radio station and
listening station chapters). One window per chapter is plenty; more can be added when new chapters
ship. Put `TownLights` parts where they can be seen from the telescope.

## Not in the hub

No monster, no danger, no red light, no puzzles. Keep it small, so it loads fast on phones and is
the first thing new players see working smoothly.
