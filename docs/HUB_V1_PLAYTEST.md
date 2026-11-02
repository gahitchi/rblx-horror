# Hub v1 — Wrenmouth Coast Checkpoint

This build creates **Workspace.Hub** on the hub place from
`src/hub/server/HubBuilder.luau`. It uses the real hub runtime already in
`src/hub/server/LobbyService.luau`, not the match place's
`Workspace.Map` contract.

**Source branch:** `chatgpt/hub-v1` (based on the 2 Nov 2026 `main`
commit). **Version:** `0.7.1-hub-v1`.

## Story and art

2026, at the edge of Wrenmouth. The studio is not the lobby: the players
arrive on a windswept coast road, where the handler's cream-and-rust camper
van is the only stable warm place. A navy gate seals the descent into
Wrenmouth. The town and lighthouse remain visible through the fog.

The visual palette and level concept follow `docs/MAP_BRIEF_HUB.md`.
No monster, no jumpscares, no scoreboards suspended in the sky, and no
large realistic mesh requirements. The hub should be legible in third
person on a mobile screen.

## Schematic / travel flow

```text
                                     NORTH — CLIFF / SEA
  NORTHWEST LOOKOUT   • bench + telescope             distant lighthouse
         ↘                            navy fence                 far coast
  SPAWN  →  HANDLER'S VAN  →  CREW BOARD / HUT     ║  gate ║   WRENMOUTH
          kit crate   warm lamp             ║     ║      ║   skyline
    WEST    gravel lay-by                  ║     ║      ║   (unwalkable)
  ───────────────── COAST ROAD ─────────────╫─────╬──────╫────────────────
                         moorland          ║ gate ║ town ║
                               SOUTH — low stone / fog boundary
```

The playable footprint is approximately 175 by 130 studs (excluding
non-playable distant silhouettes). The physical fence/gate prevents
ordinary visitors from entering the town. An invisible far-side
boundary prevents falling into the non-playable skyline during the
short departure animation.

## Content built

- Gravel lay-by, coastal asphalt with worn lines, stone/bracken patches,
  sea below the cliff, safety railing and soft world boundaries
- Accessible-looking invented cream-and-rust handler van with an open
  rear, electronics, workshop bench, reel deck, fold-out table, windows,
  tyres and steady tungsten light
- Checkpoint hut with a dark window; physical crew noticeboard
- Crew kit trunk with headset/flashlight silhouettes
- Navy quarantine fence, stencilled warnings and striped lifting barrier
- Cliff lookout, bench and brass telescope
- Distant, non-playable studio, cannery, river quay, navy listening
  station, radio hill/mast, houses and white/red-band lighthouse
- Extremely faint pale Choir streaks above Wrenmouth; no red warning
  lights in the playable hub
- Warm windows on cleared town locations and a mast beacon after
  chapter three, displayed **locally per player**

The scenery is entirely native Roblox geometry, with no external mesh
or Store models required. The fan of repeating details is intentionally
small so the initial hub loads on phones.

## Exact scene contract

```text
Workspace.Hub                       Model
├─ HubSpawn                          invisible BasePart, facing van / fence
├─ Markers                           Folder
│  ├─ VanDoors                        invisible Part: tape-deck interaction
│  ├─ CrewBoard                       invisible Part: existing crew browser
│  ├─ KitCrate                         invisible Part: flashlight cosmetics
│  ├─ Telescope                       invisible Part: lookout progress screen
│  ├─ GatePath                        invisible Part: departure road area
│  └─ Foghorn                         invisible Part at distant lighthouse
├─ Gate                              Model
│  ├─ Hinge                           Part, rotation origin
│  ├─ BarrierArm                      animated part
│  ├─ BarrierStripe                   repeated animated parts
│  └─ GateBlocker                     invisible collision barrier
├─ TownLights                        Folder
│  ├─ studio1, studio2, studio3       chapter windows with PointLights
│  ├─ radio1, sonar1                 future landmark windows
│  └─ RadioMast                       chapter-three red aviation light
├─ HandlersVan / CheckpointHut
├─ EquipmentCrate / Lookout
├─ Landscape / NavyFence
└─ DistantWrenmouth
```

A correctly named hand-built `Workspace.Hub` can still override the
generated scene. If no suitable Hub exists, the default is now
`HubBuilder.build()`, with a small platform fallback if the generator
throws.

## Existing hub gameplay wiring

**Crew board:** local ProximityPrompt opens the existing public/friends
lobby browser. It also remains accessible through the small
**CREWS [B]** screen button / keyboard B, including if the generated
map is temporarily unavailable.

**Van:** local ProximityPrompt opens recovered evidence and optional
tapes. Those texts come from the existing `StoryTapes` list and the
shared `Progress_v1` save.

**Kit crate:** local ProximityPrompt opens the earned flashlight-colour
picker. The hub reads level and equipped look from the same
`Progress_v1` DataStore and validates unlocks server-side before
`UpdateAsync` persists the chosen `skin`. Nothing here grants
survival or money. In Studio with API access disabled, saving can fail
and the UI explains that.

**Lookout:** local progress display and client-only light toggles
reflect this player's chapter clears. Later chapter IDs are placeholders
in the view; they do not silently unlock new game chapters.

**Departure:** when a published lobby host chooses Start, the navy
gate rises for roughly one second before the existing reserved-server
teleport. The gate resets. The authoritative lobby permissions,
chapter unlocks and teleport destination remain unchanged.
As before, Studio Play cannot test a cross-place teleport.

## Installation

1. Create/choose the **hub place** within the same Roblox experience
   and set it as the start place, as described in `docs/HUB.md`.
2. Open that place, switch to `chatgpt/hub-v1`, run
   `rojo serve hub.project.json`, connect Rojo from Studio and
   publish the hub place. Do not run the match `default.project.json`
   there. The `src/shared` folder is included in both places.
3. Set both nonzero IDs in `Config.PLACES.HUB` and
   `Config.PLACES.MATCH` when you know the published place IDs.
   Those IDs are intentionally **not invented** in source control.
4. Enable Studio Access to API Services only when appropriate for
   progress tests; shared data should be tested using a safe test
   account or test environment.
5. The detailed studio remains on a *separate* source branch,
   `chatgpt/studio-v2`. Merging or deploying both requires combining
   their separate changes and resolving `Config.VERSION`, not
   replacing one branch with the other.

## First Roblox Studio smoke test

- **Scene:** verify `Hub.Scene == "Wrenmouth Coast Checkpoint"`,
  `HubSpawn`, all six Markers, gate parts and TownLights; ensure no
  fallback platform has loaded. The client should be third person.
- **Walk:** spawn facing the van and town, reach the lookout, all
  four prompts and the checkpoint, and confirm the cliff, south
  moorland and far gate prevent falling out of bounds.
- **Lobby UI:** CREWS [B] and CrewBoard both open the same lobby;
  create, join, leave and Quick Join still work.
- **Kit:** cosmetics are level-locked and equipped from the free track;
  they persist after leaving and returning when saves are available.
- **Van:** recovered story tapes appear when cleared and disappear
  from the deck if not yet obtained.
- **View:** cleared studio windows glow only for this player; untouched
  chapters remain dark, while the lighthouse keeps sweeping.
- **Published servers:** check that an eligible lobby host opens the
  gate, then the group teleports to the match place. No published
  teleport can be validated in Studio Play.
- **Performance:** check UI scaling on a phone, cliff view performance,
  no van camera clipping, gate animation, shadow budget and asset count.

**Validation scope:** code-reviewed and committed, not actually run
in Roblox Studio. The hub's parts, UI interactions, DataStore writes,
teleports and camera behavior all require in-engine verification.
