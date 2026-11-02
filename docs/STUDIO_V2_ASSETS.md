# Studio v2 — convincing assets, not a realism benchmark

**Target:** intentionally stylized 1987 recording house with convincing silhouettes,
proportions, period equipment, acoustic finishes and well-chosen highlights.
An object should look credible from first-person gameplay distance (roughly
4–12 studs), including on a phone. It does not need photogrammetry, TTK-level
materials, high-resolution PBR or elaborate simulation.

## Production priority

1. **Hero equipment:** analog mixing desk, multitrack reel machine, microphones,
   drum kit, studio monitors. Replace the visible blocky shells with a few
   well-chosen, modest-poly models. Keep the existing invisible gameplay objective
   and all pickup/puzzle logic.
2. **Architecture and circulation:** baseboards, acoustic-panel silhouettes,
   studio glazing, believable doors, signage. The current geometry already
   establishes these; fix visible clipping before adding more.
3. **Functional support:** reception seating, recording archives, bathrooms,
   janitor closet, staff kitchen, road cases, equipment racks. Keep consistent
   palette and a handful of reused design families.
4. **Atmosphere:** warm lamp pools, fogged corners, tape hiss and machinery
   sounds. Keep lights controlled by the existing dead/woken/red system.

An asset is accepted when its shape reads at phone size, its style suits 1987,
it has clean external surfaces, its proportions are plausible next to the
character, it can be safely made static, and its approximate mesh count is
reasonable for a mobile horror game. Do not maximize triangle count for its
own sake.

## Free Creator Store — candidates to *inspect*, not approved imports

The catalog changes. These are actual catalog pages, but nothing listed below
has been downloaded, visually approved in Studio, or integrated. Some other
search results contained scripts or copyright-sensitive characters.

| Candidate | Why inspect | Caution | Link |
| --- | --- | --- | --- |
| Record Player V.1 by @marcus6895 | Period turntable and small prop; Store reports ~650 triangles and no script count | Appearance and permitted use need in-Studio review | https://create.roblox.com/store/asset/113420804/Record-Player-V1 |
| Microphone by @DoubleA7 | Simple reference at ~24 triangles | Might be too crude to use as final mic | https://create.roblox.com/store/asset/54333218 |
| Cavern Drum Kit by @ForeverSkriptz | ~14k triangles, 10 MeshParts; may give drums a better outline | Store reports 2 scripts; stage geometry only and inspect materials | https://create.roblox.com/store/asset/121516237146825/Cavern-Drum-Kit-Music-Piano-Band-Instrument |
| Piano by @Theraredude1234 | ~2.2k triangles, could fit a side room if geometry is good | Store reports 1 script; not automatically approved | https://create.roblox.com/store/asset/11294758178/Piano |

Reject examples: modern interfaces that break the 1987 setting, branded
fandom/character rip-offs, scripts that remain with a model, and massive
poly-count furniture sets with many textures. In particular, the 100k+
triangle Monkees drum-kit model is not a reasonable first mobile choice.

Recommended live Store searches in Studio's **Toolbox > Creator Store > Models**:
`reel to reel recorder`, `analog audio mixer`, `vintage microphone`,
`studio drum kit`, `1980s tape deck`, `acoustic studio speaker`,
`vintage vinyl record player`, `vintage studio rack`.

## How to stage an approved model

**There is no third-party model installed automatically by the GitHub branch.**
The running game never downloads Store assets.

1. Run Roblox Studio in **Edit** mode and open the match place on
   `chatgpt/studio-v2` with Rojo synced.
2. In Toolbox's Creator Store, insert one candidate asset as a **Model**.
   Examine it in the Explorer and properties, creator listing, visuals,
   mesh count, scripts, physics and hidden descendants. Use only assets
   that are available to your experience and whose use is permitted.
3. Select the model. Open `tools/studio/StageApprovedStudioAsset.luau`,
   set its `SLOT`, and paste/run the code in Studio's **Command Bar**.
   It copies a static geometry-only version into
   `ServerStorage/StudioApprovedAssets/<SLOT>`, removing all Scripts,
   ModuleScripts, LocalScripts, prompts, remotes and sounds.
4. Remove the **original imported Store model** from Workspace and check
   the staged copy's `Part` / `MeshPart` count and visual fidelity.
5. Press Play: `StudioStoreAssets.luau` clones, scales, positions and
   sanitizes the approved model; relevant primitive dressing is hidden.
   `Objectives/MixingDesk` and `Objectives/TapeMachine` remain functioning
   invisible proxies, so puzzles still use existing code.
6. Test every affected prompt, the Engineer's path, acoustic occlusion,
   camera angles and performance. If bad, delete the matching staged model
   from `ServerStorage` and the native geometry immediately returns.

**Supported staging slots:** `AnalogConsole`, `ReelToReel`, `DrumKit`,
`VintageMicrophone`, `ElectricKeyboard`, `Guitar`,
`VintageRecordPlayer`, `AnalogRack`. Drum and microphone slots
are reused at several authored placements.

### Source-control and security

- Only the Luau modules and staging tool are committed to GitHub.
  Models placed manually in `ServerStorage` are stored in your **place
  file**, not in this Rojo code branch. Back up the place and its
  approved asset inventory or use your existing managed asset workflow.
- Never trust scripts that ship with free models. Roblox explicitly
  warns about third-party asset backdoors. Our Command Bar workflow
  strips scripts *before* placing copies in `ServerStorage`; the
  runtime loader sanitizes again. This is an additional safeguard, not
  a substitute for manual inspection.
- The current asset pipeline does not change `docs/MAP_CONTRACT.md`
  or `src/server/MapContract.luau`, and it doesn't alter monster/round code.
- Public third-party models should be inserted and reviewed in Studio.
  `AssetService:LoadAssetAsync` has permission/settings requirements;
  the game intentionally does **not** call it on live servers.

**Roblox official references:**
- https://create.roblox.com/docs/production/creator-store
- https://create.roblox.com/docs/scripting/security/third-party-vulnerabilities
- https://create.roblox.com/docs/reference/engine/classes/AssetService
