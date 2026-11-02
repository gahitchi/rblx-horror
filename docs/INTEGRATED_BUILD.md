# Dead Air — unified hub + recording-studio development build

**Branch:** `chatgpt/integrated-v1`  
**Shared build version:** `0.8.4-engineer-ai`  
**Status:** Both source branches merged into one code branch. Source-level checks,
not a Roblox Studio or published-server playtest.

## What is integrated

This branch is an actual Git merge of:

- `chatgpt/studio-v2` — 23-room 1987 recording house, furniture,
  objectives, sound-driven Engineer gameplay, source-built decoration and
  opening-ten-minute ambience
- `chatgpt/hub-v1` — 2026 Wrenmouth coast checkpoint, crew browser,
  free cosmetics selector, handler's tape deck, lighthouse, skyline,
  chapter-progress windows and animated departure gate

Both original branches remain intact; the unified branch has both heads
as ancestors. No game is merged into a *single Roblox place*: **the hub and
match are separate places in the same experience**, built using their own
Rojo project configuration from the same branch.

| Roblox place | Rojo project | Server startup | Client |
| --- | --- | --- | --- |
| Hub / start place | `hub.project.json` | `src/hub/server/Main.server.luau` | `src/hub/client/` |
| Match / reserved server | `default.project.json` | `src/server/Main.server.luau` | `src/client/` |

Both use the exact same `src/shared/` directory for Config, Remotes,
Chapters, Sounds and story tapes. The match still uses
`StudioGroundFloor.build()` when no custom Map is stored, and the hub
uses `HubBuilder.build()` when no custom Hub is stored.

## Cross-place flow

1. A player starts in the coast checkpoint. The existing lobby browser
   is opened with **B / CREWS**, or by interacting with the noticeboard.
2. Player creates a crew or Quick Joins; only story chapters unlocked for
   all members are allowed.
3. The **host** starts the crew. The hub checks that **both** published
   place IDs are nonzero and distinct, lifts the navy gate and sends
   the crew via `TeleportService:TeleportAsync` to a **reserved match
   server**, passing `{ map, chapter, fromHub = true }`.
4. The match startup reads the first joiner's teleport data, validates
   the selected map and chapter and constructs the corresponding studio.
   Gameplay, progression, optional tapes and Last Call remain as in
   the existing chapter.
5. The result/replay vote keeps Yes players in the current server
   (or sends them to a new reserved match if a later map is chosen).
   No or no answer sends players to `Config.PLACES.HUB` through
   the existing `ReplayService`.
6. The hub reads the same `Progress_v1` DataStore that the match
   writes. Recovered tapes, unlocked chapters, cosmetics and the
   locally displayed skyline use that data.

The lobby system is still authoritative for unlocks and teleport
permissions. Gate art never determines who may join a match.

## Required manual deployment configuration

**The code cannot invent published Roblox place IDs.** They are still
`0` on this branch. To make teleports work:

1. Publish both places inside **one Roblox experience** and make Hub
   the **start place**.
2. In `src/shared/Config.luau`, set
   `Config.PLACES.HUB` to the real Hub place ID and
   `Config.PLACES.MATCH` to the real Match place ID.
   They must be different, nonzero IDs.
3. Open the Hub place in Roblox Studio. Run
   `rojo serve hub.project.json` from this branch, sync and publish.
4. Open the Match place. Run `rojo serve default.project.json` (or
   `rojo serve`), sync and publish. **Do not** sync the Hub project
   to the Match place or the Match project to the Hub.
5. Use an appropriate test experience/test accounts when testing
   `Progress_v1`. Enable Studio API access only if you intend
   to test DataStore functionality.
6. To test teleport and return, join **the published game**, not
   Roblox Studio's local Play test. Cross-place teleport does not
   work in Studio Play. If the IDs are not set, crew Start gives a
   clear error instead of sending the group one way.

Important: manually imported approved Creator Store visuals, if any,
remain place-file assets under `ServerStorage/StudioApprovedAssets`
in the Match place. They are not added to Git by this merge. The native
code-drawn visual fallbacks always work without them.

## Offline stability pass — 0.8.1

This pass hardens startup and return flow without adding new gameplay
or changing either map's geometry:

- The match server now tries `StudioGroundFloor.build()` inside a protected
  call. If it errors, the server logs the failure and constructs the existing
  greybox instead of aborting initialization. A greybox means **the studio
  needs debugging**, not that the detailed map was validated.
- Match replay navigation now rejects a missing or identical Hub/Match
  place ID, matching the hub's outbound start validation.
- The source preflight checks for both protections to prevent regressions.

**Still unverified:** whether the built studio, hub UI, and teleports
operate correctly under Roblox Studio and in published servers.

## Offline checks — available now

From the repository root:

```shell
python3 tools/integration/check_integration.py
```

This checks both Rojo source mappings, the shared configuration,
hub scene markers and functions, studio chapter objectives, the
23-room/30-link portal graph, after-shutter connectivity, and both
directions of the teleport wiring.

The script **reports missing place IDs as an informative deployment
warning**, not a source-code failure. It cannot execute Luau or
simulate players. When available on your computer, run:

```shell
stylua --check src
rojo build hub.project.json -o /tmp/dead-air-hub.rbxl
rojo build default.project.json -o /tmp/dead-air-match.rbxl
```

Use your usual Luau-LSP setup and Rojo sourcemaps to check both
places separately. Tool versions/installation differ by machine.

## Live test gate — hub and studio, in order

1. **Local hub Studio:** verify `Workspace.Hub` with six markers,
   the warm van, coast, fence and lighthouse; check all four interactions,
   phone UI layout, flashlight loadout and that the hub is truly safe.
2. **Local match Studio:** verify `Workspace.Map`, all 23 studio
   rooms, objectives and proximity prompts, monster navigation, shocks,
   sound ambience, hiding and Last Call. See
   `docs/STUDIO_V2_PLAYTEST.md`.
3. **Published end-to-end:** from start-place hub, create a crew,
   launch, verify expected chapter and reserved server, complete or
   fail a round, choose No in replay, return to the hub and verify
   story tapes / chapter-window progress / cosmetic loadout.
4. **Recovery:** a blocked/failed teleport should leave crew members
   in hub with a notification. The gate should reset if departure
   fails. Verify this on a safe test experience.
5. **Mobile profiling:** frame rate and memory at the cliff overlook
   and in the studio's live room/control console. Optimize expensive
   props before adding new content.

## Unresolved or untested

- **Published Hub/Match place IDs are unset** until supplied by the
  experience owner; no real teleport can succeed until then.
- No direct Roblox engine, Luau syntax checker, Rojo or device
  performance profiler available in this environment. Source checks
  do not establish that the two experiences boot without runtime errors.
- Audio remains mostly placeholder Roblox sounds; any Creator Store
  models must be vetted and imported in Studio.
- Do not merge this to `main` until the two-place Play/teleport
  smoke test succeeds.

**Related documentation:** `docs/ENGINEER_AI_V2.md`,
`docs/STUDIO_CH1_EVIDENCE.md`,
`docs/HUB_V1_PLAYTEST.md`,
`docs/STUDIO_V2_PLAYTEST.md`, `docs/STUDIO_CH1_OPENING.md`,
`docs/STUDIO_V2_ASSETS.md`.
