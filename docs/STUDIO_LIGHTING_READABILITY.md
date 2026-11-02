# Dead Air — lighting readability revision (Studio Playtest Feedback)

**Build:** `0.8.8-readable-lighting`  
**Branch:** `chatgpt/integrated-v1`  
**Priority:** Readable 1987 studio lighting **before** further asset work

## What changed and why

The initial renderer tried too hard to make Chapter 1 scary by disabling
nearly every practical before the first shock, using crushed-black ambient
lighting and obscuring the room layout with pressure fog. A playtest confirmed
the result was dark and chaotic rather than atmospheric.

This revision changes the lighting hierarchy without changing the layout,
puzzles, the Engineer's behavior or authored props.

### Lighting hierarchy

**1. Route / navigation layer — reliable**

Fifteen new ceiling-mounted maintenance fluorescents sit on the principal
navigation spine and key work-room thresholds. They are one circuit, not
random decoration. Every one has a **visible physical housing** fitted to
the room's actual ceiling and uses a downward SurfaceLight, without costly
dynamic shadows.

Coverage anchors: reception north and public counter, west/east entry hall,
staff passage, break room, sound lock, viewing gallery, inner hall, service
hall, Control A center, archive aisle, Control B, live hall and service pass.

**2. Working equipment layer — focused**

Existing Control A mixing desk, tape machine and patch board lights are
**already working at reduced power** when players arrive. They become
stronger on the first shock. The same pattern applies to important
reception and archive clues. Work lights create islands of purpose, not an
evenly lit room.

**3. Background / indirect layer — subtle**

Existing low-energy bounce proxies, threshold spill and practical
ceiling lights now provide enough shape to distinguish walls and equipment
without flattening materials. Acoustic shadows remain, especially around
the Engineeer's approach routes and shelving.

### Three story states

| State | What happens | Readability |
| --- | --- | --- |
| `dead` (partial power) | Some old circuits are active: route, ceiling, task and small guide fixtures glow; the full studio hasn't woken | Players can read corridors, room transitions and essential equipment; flashlight remains useful |
| `woken` (first shock) | Full working circuits brighten, warm desk light and studio areas feel alive; fault lights stay restrained | The visual emphasis shifts from basic navigation to machinery |
| `red` (second shock) | Emergency red becomes visible; task and route lights dim without going dark; cold service lighting stays recognizable | The facility looks unstable but doesn't become a monochrome red fog |
| Brief blackout | Working circuits fail for the original blackout duration; route, EXIT/emergency and tiny guide lights stay on battery | A tense interruption, not an unplayable black screen |

The `LightingService` keeps all light state on the server. LEDs on the
hero mixing console still follow the chapter state.

### Global look (initial source values; Studio calibration required)

- `LightingStyle = Realistic` and `PrioritizeLightingQuality = true`
  remain authored in `default.project.json`.
- `Lighting.Brightness = 1.20` rather than `0.28`.
- Environment diffuse / specular both `0.25`, up from `0.12` /
  `0.15`. No baked/path-traced GI is claimed.
- Ambient is now a dark neutral charcoal rather than near-black
  RGB (9,13,18). Exposure is slightly positive.
- Color correction contrast reduced (0.055 on early/woken, 0.09 emergency)
  to preserve shadow detail. Bloom remains restrained.
- Calm pressure fog distance increased **160 → 210** studs; maximum
  pressure fog **70 → 110**. Shock fog **35 → 75** and fades in
  **16** seconds rather than 25.

### Performance and AI fairness

- Previous 40 authored lights remain, including eight low-energy bounce
  proxies and two broad SurfaceLights.
- New total: **55 added fixtures**, of which **15 are route lights**.
  The original 23 room ceiling lights and existing studio accents are
  not removed, so these are not the entire scene light count.
- New route lights cast **zero dynamic shadows**. The additional
  authored shadow budget remains one new Control A key and two
  original landmarks.
- All route lights mount at `room.height - 0.36` and have no collision,
  physics or raycast obstruction. No fake geometric cover is added.
- Because the Engineer can now **see**, illuminated route pools are also
  legitimate, predictable areas where he may spot players. Dark corners,
  walls and real physical cover continue to offer concealment. The
  sight system itself is not made omniscient.
- A sound puzzle or chase never modifies the room geometry or moveable
  props to force lighting onto players.

## Acceptance tests when Studio is available

Play the generated studio, not the greybox fallback, in first person.

1. **First 60 seconds:** Reception and the walk toward Control A must
   reveal doorway positions and floor boundaries. Player must not need
   the flashlight just to know which direction a corridor leads.
2. **Control A:** The mixing desk, session log and tape-machine
   silhouettes should remain readable at partial power. Full power
   should add warmth and dimensionality rather than a blinding wash.
3. **Long corridor:** Follow the entry → staff → sound lock →
   viewing gallery transition. Every corridor should have a recurring
   visual rhythm: softly lit floor, visible doorway, and darker walls.
4. **Shock sequence:** First shock brightens work areas; second shock
   changes the atmosphere but retains navigation lighting. During the
   outage, route/EXIT markers must survive.
5. **Engineer visibility:** In a lit doorway the Engineer should have
   sight only with a clear cone/line-of-sight and a notice delay. When
   the player steps behind real cover, the sight lock must decay.
6. **Mobile graphics:** Check low graphics settings with the flashlight
   off and confirm readable floor/wall silhouettes; profile 1–4 players.
7. **No floating fixtures:** New route fittings are fitted to ceilings.
   Existing authored detail lighting must be visually evaluated and
   refined if its housings float in open space.
8. **Studio self-test:** Run the developer-only
   `tools/studio/StudioLightingSelfTest.server.luau` in a private
   Match playtest. It validates states, early route illumination and
   blackout restoration. It is not automatically executed.

**Status:** all fixture coordinates, source wiring and state contracts
can be checked without Studio, but Roblox lighting quality cannot be
certified until screenshots and performance measurements from a real game.

The next content milestone should be a single-room screenshot comparison,
not more randomly placed meshes. Do **not** resume broad asset dressing
until the first navigation and Control A lighting gate is accepted.
