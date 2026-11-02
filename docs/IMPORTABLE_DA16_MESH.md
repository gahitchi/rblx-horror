# Importable high-detail Wrenmouth DA-16 mesh

**Status:** Actual textured glTF 2.0 asset produced and opened in an offline 3D renderer. **Not yet imported or tested in Roblox Studio.** The binary GLB and original texture/source files are delivered as the current conversation attachment; GitHub text APIs do not store the binary asset automatically.

## Art asset

- File: `Wrenmouth_DA16_Studio_Import.glb` (about 7.8 MB)
- 66 named mesh primitives, 47,440 triangles in total
- Largest submesh 14,784 triangles; each is below Roblox's 20,000-triangle asset limit
- 16 uniquely numbered input strips, 48 actual rotary controls
- 16 independent channel-fader mesh parts and two master-fader mesh parts
- 8 individual original printed analog VU dials and separately modeled needles
- 22 individual channel-arm and bus indicator mesh parts
- Original PBR albedo, tangent-space normal, and packed metallic/roughness maps for hardwood and metal; separate print atlases for controls, meter faces and paper session log
- Chamfered furniture and hardware geometry, without stock asset dependencies

## Exact import setup

1. Download the actual `Wrenmouth_DA16_Studio_Import.glb` from the supplied asset package.
2. In Roblox Studio use **File → Import**, choosing the glTF/GLB file, and let Studio import all components.
3. Check front/back orientation: the VU bridge is behind the sloped controls; the session log shelf faces the operator.
4. Move the top-level imported Model into `ServerStorage` and rename that Model precisely `WrenmouthDA16`. Keep all inner MeshPart names.
5. Run the map. `src/server/Maps/StudioHeroConsole.luau` automatically detects `ServerStorage.WrenmouthDA16`, clones it as `HeroMixConsole`, fixes its scale and aligns its floor-relative bounding box with Control Room A. If the imported model is absent, the prior native-Part desk remains as fallback.
6. Check that the `MixingDesk` prompt still works and that the `SessionLog` prompt remains reachable. These original objectives remain separate, authoritative gameplay objects.
7. Inspect material maps in Studio; GLB embeds them but import processing and asset moderation are controlled by Roblox. If a map is lost, upload a PNG from the asset package and assign it manually via SurfaceAppearance.
8. Test the three power states and blackout: the imported MeshPart lamps are named `ArmButton_XX` / `BusLamp_XX` and the LightingService now uses opacity when powering imported PBR indicator lenses.

## Engineering constraints

- The binary is not in the GitHub branch; the Lua source **supports** it as soon as the model is imported into ServerStorage. GitHub/Rojo source cannot instantiate unpublished, binary .glb geometry on a player's device.
- Import is not silent. Roblox Studio still must upload and moderate the meshes/textures for the place.
- Offline verification checked the exported glTF with a separate parser and rendered it using VTK from the real file. Those pictures are **not** screenshots from Roblox Studio.
- The approximately 47k triangles and 66 MeshParts are appropriate for *a hero prop*, but actual device profiling and possible mesh LOD consolidation are needed before multiplayer/mobile shipping.
- Material aesthetics under the game's `Realistic` renderer are not yet calibrated. The previous AI-generated images remain **concept references only**, not proof of game-asset fidelity.

## Verification

Offline GLB reload: 66 meshes, all materials PBR, 18 independent faders, 22 separate indicators, 8 printed meter faces, bounding box approximately 11.01 × 5.56 × 5.11 studs. No mesh exceeds Roblox's triangle limit.
