# PBR and hero-mesh integration — Roblox Studio

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
