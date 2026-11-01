# Q02 Engineer — documented CC0 realistic human source

Derivative asset: `EngineerBody.glb`, `EngineerSkinned.glb`.
Derivative authoring code: `tools/quality_engineer_real.py` (Dead Air).
This source is independently sourced for **Dead Air**; it is NOT lifted from
TTK Testing, Roblox, a commercial character pack, or other copyrighted game.

## Original source

- Source title: **Daniel — 3D Person, Standing, Casual**
- Publisher: Innerscene 3D Parts Library; adapted from MakeHuman public-domain assets
- Official URL: https://www.innerscene.com/tools/library/3d-parts/daniel-3d-person-standing-casual-f788af5a
- Original download: https://www.innerscene.com/api/library/daniel-3d-person-standing-casual-f788af5a/download
- File: `daniel-man.glb`
- File SHA-256: `3e68ffc55382bd01e8a3ae52c3f22cdbd24d68e3e72ce6a21a5233903992d230`
- Source license: **CC0 / Public Domain**, as explicitly represented
  by the public source page when acquired on November 1, 2026.
- Source asset: original anatomy, short hair, eyes, jacket, patterned
  shirt, jeans and shoes, UV maps and photographic diffuse/normal textures.
- The copyright mark on the original photographic cloth atlas remains
  source provenance; it does not indicate an endorsement of this derivative.

## Dead Air changes

The character is scaled to `~6.6` studs and centered relative to the
existing `HumanoidRootPart` art offset, with local forward facing `-Z`.
Source geometry is selected and remeshed only where covered by workwear,
using material-safe UV decimation on the hands. Anatomically modeled face,
hair and garment panels retain original source topology. Cloth color
is darkened and blue jeans + striped shirt desaturated while keeping original
weave and wear detail. Original Blackline-specific modeled analog headphones,
cable and small belt recorder are added with image-mapped identification
plate decals. All extra geometry is original, non-graphic and unlit.

The builder exports **both** a visible rigid character and a weighted
15-joint GLB source without replacing the server monster's authoritative
hitbox/navigation/AI. Import as visual-only model.

## Production checks and limitations

- This license/provenance is documented for auditing; users distributing
  material must recheck upstream license representations if facts change.
- Source download in GitHub Actions is verified against the fixed SHA-256;
  it cannot silently change to an unrelated third-party character.
- The original unmodified 27 MB source is **not** part of the game asset pack.
  The derived, CC0-based textured model is published as a production artifact.
- Body model is medium/high-detail and may exceed mobile GPU / drawcall limits.
  Studio render, deformation, frame-time and multiplayer behavior must be
  measured before game approval.
- The character still needs human animator review; this is an anatomically
  accurate **art asset candidate**, not a finished photo-scanned AAA character
  or proof of parity with the referenced Roblox game.
