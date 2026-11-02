# Dead Air — Control Room A / live Studio lighting QA pass

**Baseline:** three genuine Roblox Studio screenshots from the first Codex live session, provided in chat on 2 November 2026. The imported DA-16 was reoriented correctly by local Codex changes on `chatgpt/control-a-visual-qa`, which were **not yet committed or pushed** at the time of review.

**Availability:** Live Studio MCP is attached to the user's local Codex CLI on Arch Linux, not directly to the ChatGPT GitHub connector. Do not imply that a GitHub source change was previewed in Studio.

## Measured baseline

From original 985 × 409 RGB screenshots, display-relative Rec.709 luma `0.2126R + 0.7152G + 0.0722B` using byte values / 255, and a threshold below 0.08:

| Image | Fraction below 0.08 | Whole-image median | Description |
|---|---:|---:|---|
| `before-operator.png` | 92.77% | 0.0202 | Console facing away |
| `after-operator.png` | 90.93% | 0.0253 | Console turned toward operator |
| `play-room.png` | 97.37% | 0.0095 | Live match, early electrical state |

These numbers show poor screen visibility, not measured physical lux or objective HDR exposure. Full image includes UI and dark walls; measure **the same desk ROI and the same camera view** in follow-up. Reject comparisons with unmatched state/camera or pre-round HUD.

## Work already saved in GitHub (source-only)

Commit `75201516557f60e4d3878bd4841616505bb62b20`:
`StudioLightingRig.luau` now creates invisible holders for artificial Bounce sources, without their own fake physical hardware or frosting. Visible ceiling/route light fixtures keep real lens geometry.

Commit `25785bf8b1711023f1ec16ec1417a0c9cb69984d`:
`LightingService.luau` fixes the unreachable dead-state Fault-color conditional and suppresses bounce housing appearance/flickering.

Commit `2557509e2dbb280c97e8c239ac0dfb8a4b2e057e`:
Developer-only `StudioLightingSelfTest.server.luau` asserts bounce invisibility and pale pre-shock Fault color.

**Important:** These commits went to `chatgpt/integrated-v1`, not to the user's local uncommitted `chatgpt/control-a-visual-qa` branch. Codex must inspect Git status and reconcile commits without discarding the console orientation correction. Never run `git reset --hard`, `git clean -fd`, or force-push as a shortcut.

## Mandatory live Studio pass (Codex)

1. Confirm `rblx-horror` is an active Studio instance via `list_roblox_studios`; identify local working branch and uncommitted files. Preserve `StudioHeroConsole.luau` orientation fix.
2. Confirm imported `ServerStorage.WrenmouthDA16` has its full 66 MeshParts and the active map `Workspace.Map` shows the imported model, not procedural fallback. Inspect `Map.Lamps`, the 15 route lights, 8 bounce proxies, `DeskWritingLamp`, `ControlASoftboxReturn`, and `MixingDeskScaleLight`.
3. Capture **same fixed player-eye operator camera**, preferably around (-56, 4.9, -72), pointed at the faders and meter bridge. Use actual player camera position if fixed coordinates intersect furniture; preserve the exact CFrame across images. Capture `dead-before.png` and `woken-before.png` in active play, with HUD hidden if possible. Save at `/tmp/dead-air-qa/control-a-lighting/`.
4. Diagnose source-of-darkness rather than guessing. Inspect `LightingService.state()`, actual Light.Enabled, Light.Brightness, Light.Range, Light.Face and Shadows at the active map, ColorCorrection, Bloom, LightingStyle, ShadowSoftness, actual console `SurfaceAppearance`, and any glass/metal occlusion. Determine if a lamp points away, is blocked by the bridge, too far from faders, or material maps are not attached.
5. Refine the **existing physically motivated source lights first**. The console must have a shallow warm task pool on channel strips, coherent meter illumination, and soft dim room separation. The corner of a speaker and tracking window should be visible but not bright; keep one deep-shadow corner. Don't increase global Ambient/Brightness as the first solution. Don't create extra bounce geometry. Avoid excessive bloom and red monochrome.
6. Only after controlled inspection, make the smallest source-level change needed to fix the dominant issue. Keep the current local QA branch, no merges/pushes yet. Avoid editing the DA-16 imported mesh orientation or objective geometry. If source is under Rojo, edit source then sync. If adjustments require a temporary Studio object, also implement them in source for persistence.
7. Repeat `dead-after.png` and `woken-after.png` with the **identical CFrame, camera settings, UI and state**. Also capture the `red` emergency and blackout/restored frames (note exact times); these should retain navigable routes and not bleach out the meter faces.
8. Use source tests, Studio output, a representative 1-player gameplay test including `SessionLog` and `MixingDesk`, plus performance statistics available via MCP. Check touch/collision, light type, visibility, frame rate before/after on the same device. Don't claim mobile performance without a device profile.
9. Stop playtest, restore test state, leave local edits uncommitted, and report screenshot paths, exact source diff, measured before/after **desk ROI** luma, changes in light counts and warnings. Be candid if tool screenshots or benchmarks are unavailable.

## Art and performance acceptance criteria

- DA-16 fader caps, dials, bridge and session log are distinguishable in the *dead* state from the operator viewpoint, even without flashlight or UI exposure trickery.
- Meter faces have some independently readable printed detail. The emergency state should feel threatening rather than uniformly red.
- The room still has meaningful dark recesses and approximately 1987 practical tungsten work lighting.
- No visible floating light housing, no unintended neon metal, no extra collision on import, and no duplicate fake console.
- Studio-imported texture maps remain attached; their colors aren't judged from offline PBR renders.
- No significant frame-time regression; no unbounded light-instance additions.
- Never mix a pre-round screenshot into an active-play state comparison.

## Codex instruction to copy

> Continue Dead Air Control Room A lighting refinement in the already-connected Roblox Studio MCP session on Arch Linux. Read `docs/CONTROL_A_LIVE_LIGHTING_QA.md` from `chatgpt/integrated-v1` as the QA specification (or use the same requirements supplied in the current chat). Protect my uncommitted `chatgpt/control-a-visual-qa` console-orientation fix; don't reset/rebase/push or overwrite it. Inspect real `Workspace.Map.Lamps` and the 66-part imported DA-16, then use an identical operator camera CFrame in active gameplay for matched dead/woken before-and-after screenshots. Diagnose why the existing practical lights leave the console unreadably dark; tune real source files and Rojo sync rather than globally increasing brightness. Run the original interaction and lighting-state tests, record any warnings, obtain screenshots, then stop playtest and report the diff. No commit or push until screenshots are reviewed.
