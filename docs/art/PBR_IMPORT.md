# Studio import: high-fidelity mesh and PBR deployment

**Status:** The game-side mesh swap is implemented. Twenty-five original GLB files
(nine core, four optional Blackline props, four optional characters, two optional hero machines) have been exported successfully. They are *not* live in Roblox until imported and approved
under the experience's creator account. Rojo and server Scripts cannot directly
assign `MeshPart.MeshId` at runtime. <https://create.roblox.com/docs/reference/engine/classes/MeshPart>

## Step 1 — Get the source asset pack

Open [successful GitHub Source Asset Export](https://github.com/gahitchi/rblx-horror/actions/runs/41261640055)
and download `dead-air-import-ready-mesh-pbr-pack`. The ZIP contains:

- `roblox-glb/`: twenty-five GLB models (nine core, four optional Blackline props, four optional characters, two optional hero machines), ready for Studio's 3D Importer;
- `materials/`: 16 PNG PBR maps (four materials × color, normal, roughness, metalness);
- `meshes/`: the original five OBJ and MTL source models for further hand editing.

If the Actions archive has expired, run locally:

```bash
python -m pip install pillow numpy trimesh
python tools/generate_pbr.py --size 1024 --out build/materials
python tools/build_glb_assets.py --out build/roblox-glb
```

## Step 2 — Import the nine GLBs into the MATCH place

In Roblox Studio's 3D Importer, import these files. Keep the names below **exactly**,
and check each GLB contains one or more MeshParts. Keep their origin at the intended
object pivot before import (ground at y=0 for static props, local head origin for
EngineerHeadset). Use the importer to review scale and material orientation.

| Studio prefab name | GLB filename | Where the runtime uses it |
| --- | --- | --- |
| `MixingConsole` | `MixingConsole.glb` | Studio and radio control rooms |
| `BroadcastMicrophone` | `BroadcastMicrophone.glb` | Studio and broadcast microphones |
| `FoundryBell` | `FoundryBell.glb` | Foundry visual landmarks |
| `CassetteRecorder` | `CassetteRecorder.glb` | Objective tape deck and movable decoy |
| `EngineerHeadset` | `EngineerHeadset.glb` | Welded to the Engineer's original root |
| `WalkieTalkie` | `WalkieTalkie.glb` | Welded to the walkie gameplay root |
| `AnalogRack` | `AnalogRack.glb` | Studio/broadcast equipment racks |
| `NearfieldMonitor` | `NearfieldMonitor.glb` | Control room monitor speakers |
| `TapeReel` | `TapeReel.glb` | Tape archive prop details |

Select all nine correctly named imports in Explorer. Open Studio's **Command Bar**
and run the contents of `tools/studio/InstallImportedModels.luau`. The command
checks each asset contains a MeshPart and creates `ServerStorage.ArtLibrary`
without overwriting existing approved imports. The runtime's
`src/server/PrefabLibrary.luau` then automatically uses them. Missing assets
fall back to procedural visuals; gameplay collision and prompts remain unchanged.

**Save the Studio place after importing.** For reproducible Rojo builds, export
the approved `ServerStorage.ArtLibrary` as a binary/model package under a
new `assets/roblox/` path and explicitly link it in the Rojo project. Until that
export step is done, cloning only GitHub source will use procedural fallbacks.

## Step 3 — Import PBR image maps

Upload the 16 source PNG files into your Roblox experience's Asset Manager.
Open `tools/studio/InstallMaterialVariants.luau`, replace each placeholder
numeric `0` with the **real uploaded image asset ID** for that image, then run
the script in Studio's Command Bar. It installs six approved MaterialVariants
and never invents asset IDs or silently overwrites non-variant objects.

The runtime `Maps/PBRMaterials.luau` automatically assigns imported variants
to generated parts when their exact names and BaseMaterial match. Objects
without imported textures keep their native look.

## Step 4 — Verify the actual in-game upgrade

At high graphics quality, enter each map and inspect control desks, acoustic
surfaces, machinery, door hardware and the Engineer silhouette. Check the
Output lines `[Dead Air] Importable visuals: 9 approved prefabs ready` and
`[Dead Air] PBR: assigned ... parts from ... approved MaterialVariants`.
Make sure the Model pivots and scale are correct, and that imported surfaces
do not look unnaturally reflective or metallic.

The GLBs are **author-made procedural starter meshes**, not scanned photogrammetry
or finished cinematic character assets. Their material and silhouette quality
will need additional Blender artist work to meet a truly high-end realism target.

--- 

## Background reference

**This procedure is required for the final-quality materials to appear in the game.** The GitHub source pack is not an automatically published Roblox asset pack. All image and mesh asset IDs must come from the user's own Studio import and permissions.

## Source files

[Original asset export](https://github.com/gahitchi/rblx-horror/actions/runs/41250991694) contains five OBJ assets and 16 original procedural PBR maps. The texture generator can be rerun from a checkout:

```bash
python -m pip install pillow numpy
python tools/generate_pbr.py --size 1024 --out assets/generated-textures
```

The map visuals are currently native Parts, so apply PBR through **MaterialVariants** first; the imported OBJ meshes are separate hero assets.

## Material Manager setup

Use Roblox Studio's Material Manager / MaterialService to create the following six variants. Each variant must have its **BaseMaterial** set exactly as listed. Assign the matching generated image IDs to ColorMap, NormalMap, RoughnessMap and MetalnessMap.

| Variant name (exact) | BaseMaterial | Generated texture prefix |
| --- | --- | --- |
| `DA_Plaster_Concrete` | Concrete | `old_plaster_` |
| `DA_Acoustic_Fabric` | Fabric | `acoustic_weave_` |
| `DA_Oak_Wood` | Wood | `aged_oak_` |
| `DA_Oak_WoodPlanks` | WoodPlanks | `aged_oak_` |
| `DA_Oxidized_Metal` | Metal | `oxidized_steel_` |
| `DA_Oxidized_DiamondPlate` | DiamondPlate | `oxidized_steel_` |

The name and `BaseMaterial` must both match. `src/server/Maps/PBRMaterials.luau` automatically assigns only validated imported MaterialVariants to generated parts of the corresponding material, and falls back to the native material when a variant is absent. It does not insert arbitrary fake IDs or mutate texture maps at runtime.

**Normal-map format:** OpenGL tangent space, green channel oriented upward. Roblox accepts texture assets imported through Studio, not raw PNG paths inside the Git repository.

## Mesh import

From `assets/meshes/`, import the five OBJ sources into Blender with `dead-air-materials.mtl`. The files are original procedural starting models with UV coordinates and material grouping; they're not final optimized photogrammetric meshes. Check scale, face winding, smoothing and tangent basis. Add improved texture maps and proper LODs, then export glTF/FBX and use Roblox Studio's 3D Importer.

| Import target | Original model file | Existing gameplay connection |
| --- | --- | --- |
| Studio consoles | `console-master.obj` | Visual-only geometry replacing console blocks |
| Broadcast microphones | `broadcast-microphone.obj` | Noncollision visual asset |
| Foundry bell | `foundry-bell.obj` | Noncollision visual landmark |
| Tape recorder | `cassette-recorder.obj` | Keep anchored `ItemArt.makeTapeRecorder()` root and its prompt |
| Engineer headset | `engineer-headset.obj` | Keep original invisible HRP (2×2×1), Humanoid, two returned earcup lights |

Do not attach unsupported `rbxassetid://` values. Verify the mesh imports under your experience's creator ownership before referencing it in the game. A MeshPart's `SurfaceAppearance` uses the uploaded PBR maps after import.

## Acceptance

1. Start the match in Studio, choose studio, radio and foundry. Look for the Output log line `[Dead Air] PBR: assigned ... parts`. Zero means no matching variants have been installed; the game is still using native fallback materials.
2. Verify old plaster isn't unnaturally metallic, oak grain has believable scale, acoustic panels are matte and utility steel has localized metal response.
3. For glazing, approach each control-room or industrial window and check visible through-glass sightlines, collision and sound dampening; ensure no window overlaps a door.
4. Verify handles/panels remain on doors during opening and closing; isolation-booth doors still seal sound.
5. Compare power-off and power-on screenshots; controlled key lights, generator status, monster outline and exit marker must remain readable.
6. Use Roblox MicroProfiler and frame-time captures on high/medium graphics quality (not just Studio Edit). If the part count is too large, replace modular decoration with batched mesh kits and use actual performance measurements.
7. Only then consider the PBR/mesh integration qualified. **Do not label the present procedural models fully photorealistic before these checks.**

Current renderer capability reference: [Roblox PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance), [MaterialVariant](https://create.roblox.com/docs/reference/engine/classes/MaterialVariant), [Realistic lighting](https://create.roblox.com/docs/environment/lighting).

## Optional Blackline second-wave art (November 1)

A fresh Source Asset Export also contains `ReceptionTerminal.glb`,
`TapeArchiveCart.glb`, `ServiceIntercom.glb` and `StudioWallClock.glb`.
They are **optional**, and their scene placement code has procedural fallbacks.
The original nine installed models remain untouched. When ready in Studio,
import these four GLBs only, select the imported models and rerun the updated
`tools/studio/InstallImportedModels.luau` Command Bar installer (or place them
directly in `ServerStorage.ArtLibrary` with the exact model names).
A newly exported asset pack does not automatically upload any GLB to Roblox.

The current import-ready pack is downloadable from
[Source Asset Export run 41261640055](https://github.com/gahitchi/rblx-horror/actions/runs/41261640055)
until its artifact expires (December 1, 2026).

## Optional Engineer and player meshes (third wave, November 1)

The updated export also contains:

- `EngineerBody.glb` — an original, gaunt Engineer body prototype with
  cloth, tissue, hardware, cabling and embedded **base color, normal, packed
  metallic/roughness** texture images;
- `FieldOperatorVest.glb` — a muted technical vest for R15 player characters;
- `FieldOperatorMask.glb` — a lightweight protective respirator;
- `FieldOperatorPack.glb` — a rear technician equipment pack.

**Install:** Download the successful
[17-model Source Asset Export](https://github.com/gahitchi/rblx-horror/actions/runs/41263248769)
under Artifacts. Import **only the four additional GLBs** through Studio's 3D
Importer. Select their root Models or MeshParts and run the current
`tools/studio/InstallImportedModels.luau` installer (or place them manually,
with the exact names, in `ServerStorage.ArtLibrary`). Save the place.

No prior assets need to be reimported. If any of the four are absent, the
game uses its previous gameplay-safe models and Roblox avatars.

**Important:** the character exporter currently produces *rigid, cosmetic
models*. The imported EngineerBody is welded to the server-owned gameplay
root; it does not yet have a skinned animated skeleton. The field-operator
pieces attach to ordinary R15 `UpperTorso`/`Head` without replacing the
existing animated body. This preserves controls and gameplay but is **not
a completed TTK-class character-animation pipeline**. It needs Studio fit
and clipping review and a professional skinned-R15/Engineer rig pass.

## Two additional image-mapped environment hero meshes

`BlacklineTransferDeck.glb` and `BlacklinePatchMatrix.glb` supplement the
character pack. They have original modeled analog components and embedded
base-color, normal and metallic/roughness images. Import them only if you want
to replace their procedural fallback pieces in the MasteringVault and PatchBay.
Use the same selected-model installer, with exact asset names.
They do **not** change the live fuse interaction, door or enemy navigation code.

## Articulated Engineer — six-part body import (November 1)

A newer [25-GLB asset pack](https://github.com/gahitchi/rblx-horror/actions/runs/41297996570) contains six additional textured rigid segments: `EngineerRigTorso`, `EngineerRigHead`, `EngineerRigArmLeft`, `EngineerRigArmRight`, `EngineerRigLegLeft`, `EngineerRigLegRight`. Import all six into Studio's ArtLibrary using the updated importer; older meshes remain valid. Once all six are present, an articulated Motor6D character replaces the rigid Engineer visual automatically; if one is missing, the old figure remains. Keep the source-space pivot of each imported GLB: arms pivot at shoulders and legs at hips, not at the bounding-box center.

[Full installation and F5 acceptance protocol](https://github.com/gahitchi/rblx-horror/blob/chatgpt/studio-art-pass/docs/art/ENGINEER_ARTICULATION_AND_BLACKLINE_HERO.md). These are articulated cosmetic hard-surface segments, **not** smooth skin-weighted character anatomy.
