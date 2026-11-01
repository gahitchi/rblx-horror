# Dead Air — Q01 production baseline (adopted for the build-out)

**Decision (2026-11-01):** The owner accepts the rebuilt Blackline
`BlacklineHeroConsole` as the **provisional visual direction for game production**.
Use its construction discipline across the game first. An eventual AAA-level
artist polish is a **second pass**, not a prerequisite to completing the world.

**Crucial distinction:** The Q01 console was reviewed as a real source-GLB
preview. It has NOT been qualified in Roblox Studio for lighting, texture
streaming, pivot, gameplay sightlines, mobile performance or first-person
composition. The user's approval of the look is **not** Studio runtime signoff.

## What the baseline actually means

1. **Silhouette and construction:** No unbroken primitive-looking hero
   equipment. Design a believable object with an accurate function; use shaped
   housings, purposeful component breaks, consistent human scale, beveled
   structural edges and visible manufacturing logic.
2. **Authored surface treatment:** Original, deliberately unwrapped images for
   high-salience hero components, with color, normal and metallic/roughness
   response. Not a blanket noisy rust texture, random repeated details,
   black rectangles pretending to be displays or glowing UI replacing controls.
3. **Readability:** Distinct front/back, correct model pivot, service access,
   credible silhouette at 25 studs, readable identity at 12, close detail at 3.
   Hero labels are oriented **toward the actual gameplay approach**.
4. **Performance and fallbacks:** Original imported MeshParts are cosmetic and
   do not replace the map's authoritative collision/nav/audio proxies. Avoid
   accidental duplicates. Existing fallback may remain visibly less detailed,
   but must be recognizably functional; it cannot silently be described as
   Q01-quality or be sold as a completed imported model.
5. **Evidence:** Every promoted asset has its exact GLB source, UV/texture
   inventory, size and triangle audit, 3-view *real-asset* preview, and later
   first-person Roblox Studio screenshots and p50/p95 frame-time measurements.
   **Technical checks never confer visual approval.**

## Two deliberately separate production gates

**Pass A — production baseline (our current goal):** a cohesive, playable
facility with the console's general modeling/material quality standard across
high-value surfaces, credible characters and monsters, a distinctive
environment and a preserved gameplay/navigation contract. Lower-value props
may share approved materials/trim sheets and restrained detail; do not spend
20,720 triangles on every switch or bolt.

**Pass B — late hero polish (after the game is whole):** revise the best assets
with a dedicated artist sculpt / high-poly-to-low-poly normal bake, clean UV
islands, higher-quality cloth and metal responses, custom animation and
material aging, improved scene lighting and optimization based on actual
frames. Pass B never just raises polygon counts.

**Q01 remains the style reference, not a numerical or photographic promise.**
A 20k-triangle static console is not an appropriate universal cap for mobile
props, modular walls or a weighted/animated Engineer.

## Build-out sequence (quality first, gameplay mechanics undecided)

| Sequence | Game-visible result | Production focus |
| --- | --- | --- |
| Q02 | Engineer identity established | Character anatomy and damaged uniform, headset, clean weighted mesh + fallback; preserve AI and two existing ear lights |
| Q03 | One consistent staff silhouette | R15 field-operator mask/vest/pack proportions and fabric/metal reads; preserve avatars and animation |
| Q04 | TapeArchive → MasteringVault → ViewingGallery | Replace conspicuous primitive hardware with authored mesh/UVs; retain authentic glass and all door clearances |
| Q05 | Control A/Control B/LiveHall | Bring remaining console/racks, recording fixtures and surfaces into the same believable design grammar |
| Q06 | Public/staff/engineering wings | Repeat an approved modular wall/trim and equipment grammar, with room-specific identity and no random dressing |
| Q07 | Facility-wide acceptance | One coherent lighting/material grade, navigation/audio regression tests, first-person visual gallery and performance triage |
| Q08 | Content and gameplay choices | Decide core gameplay with player feedback, then author/iterate without making old generator/fuse tasks a visual priority |

**Order can change when an observed quality defect or production blocker
justifies it.** These are *art-production sequences*, not invented gameplay
missions or new systems. No expansion simply to increase the count of assets.

## What is shipped versus still to do

- The original `BlacklineHeroConsole.glb` Q01 source model, UV/PBR texture
  plates, safe `Kit` integration and audit are already present on
  `chatgpt/studio-art-pass`. The Studio importer does **not** automatically
  overwrite an existing `ServerStorage.ArtLibrary.BlacklineHeroConsole`.
- The existing other 28 GLBs are source-valid, **not promoted** to the Q01
  visual baseline by association. The accompanying
  `docs/art/asset_quality_ledger.json` records the actual inventory and
  the planned promotion groups.
- The first production task after this decision is the **Engineer Q02**.
  Its facial anatomy and clothing require artist attention; generic boxes,
  extra unreviewed horns/bolts or random decals do not satisfy the baseline.
- A user-reviewed GLB screenshot is a genuine progress check. It is not
  evidence of a tested Roblox place. Final target remains high-quality
  within Roblox, with TTK/AAA parity **aspirational**, not claimed.

## Asset promotion protocol

For each asset group, do **one** convincing hero at a time: design references
and purpose → authored silhouette/mesh → UV/PBR and labels → real GLB screenshot
→ optimize → import/replace old prefab safely → playtest and screenshot
→ mark accepted. Preserve source and fallback through every step.

The ledger is a **tracking instrument**, not a cosmetic stamp of approval.
Its `studioApproved` fields remain false until real Roblox Studio evidence
exists. The source CI checks its honesty and the exported mesh pack covers the
same set of assets. Do not use CI success as evidence of a completed AAA asset.
