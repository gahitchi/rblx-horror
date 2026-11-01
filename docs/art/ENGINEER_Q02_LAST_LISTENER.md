# Engineer Q02 — REJECTED source prototype / realistic character rebuild brief

**User review (2026-11-01): REJECTED.** The generated Engineer preview
looked blocky and cartoonish. It did **not** reproduce the professional
visual fidelity of TTK Testing and must not be described as Q01-standard,
realistic, finished or artist-approved.

The procedural `quality_engineer.py` experiment and its imported/weighted
GLBs are **not to be installed** as the official Engineer. The branch has
restored the prior working prototype character exporter, existing 15-joint
weighted skeleton and original client motion so gameplay does not inherit
the rejected experiment. Old character visuals are **temporary functional
placeholders only**. Previous rejected export ZIPs should not be used.

## Final character direction: The Last Listener

A believable former Blackline mastering technician who is unsettling because
his intense listening, ritualized movements and reaction to interruption feel
wrong. **80% ordinary adult human / 20% eerie.** No exaggerated proportions,
monster claws, giant eyes, zombie damage, teeth displays, speaker-head, alien
skin or hovering sci-fi equipment.

- Normal adult male proportions, lean but not emaciated. Body silhouette
  should be human at 25 studs and *credible* at 3 studs.
- Convincing face first: accurately formed eyelids, nose, brow, cheeks,
  mouth, ear anatomy, textured short hair and subtly tired skin; slight
  expression asymmetry but **not** hollow toy-eye sockets.
- Authentic studio wardrobe: weathered charcoal technician jacket with
  constructed collar, layered shirt, naturally falling fabric sleeves,
  trousers, leather work shoes, small keys, tape-splicing tool and ID badge.
- Signature old professional monitoring headphones: molded earcups,
  wear on cushions, metal headband, intact wearable fit and a small wired
  boom microphone. Slight asymmetry and worn materials—not flesh fusion.
- One plausibly mounted, hand-sized belt recorder/VU unit. Restrained,
  tactile knobs and stamped plate. Never a neon HUD or combat armor.
- Controlled movement language: headphone adjustment, listening pause,
  imperfect but human walk, sudden attentive head turn, purposeful pursuit.
  No contortion, gore, injuries or threatening torture scenes.

## The required production method (Q02 authoring gate)

**Stop generating a character from Python ellipsoids, cylinders, lofts and
fabric-colored primitives.** Another exported GLB is not an improvement by
itself. This requires manually controlled, anatomically accurate modeling,
not a procedural geometry density increase.

1. **Reference and proportions:** orthographic front/side/back human
   references and measured real audio-technician gear. Fit the existing
   gameplay root without changing AI/collision/earlight semantics.
   Aim for source y=-4.0 feet to y=+2.5 head, about 6.5 studs
   of human-sized visible art after import; validate real Studio avatar
   comparisons before settling on a scale. Keep root/pivot orientation.
2. **High-quality anatomical base:** sculpt in Blender, Maya or a similarly
   capable DCC, based on a properly licensed original/usable human base mesh.
   Model skull, ears, asymmetrical expression and eyelid structure with
   enough density for a convincing close-up. Build proper cloth panels
   with thickness, folds and seams. **No box substitute.**
3. **Retopology:** smooth bend loops at shoulders, elbows, hips, neck and
   knees. Hero head/face should have adequate edge flow, not radial
   sphere topology. Distribute topology for first-person silhouette
   and animation rather than maximizing overall triangle count.
4. **Texture authoring:** distinct skin, hair, fabric, worn plastic/leather
   and painted/brushed metal materials. Create authored UV maps and bake
   normal/ambient detail from high to low poly; deliver Roblox-compatible
   1024px-or-lower per-material color, OpenGL tangent normal, roughness
   and metalness textures. Variation must correspond to material physics,
   not white noise over every surface.
5. **Rig + animation:** preserve the existing Monster root
   (2×2×1, HipHeight 3), service AI/nav/audio, two existing earcup warning
   lights and non-colliding imported art. Weight tested head, shoulders,
   waist and wrists; repair the skeleton **only** as needed to work with the
   approved topology, with source inverse binds and named Bones validated.
6. **Acceptance images:** actual DCC rendered **source model** front,
   profile, rear, face close-up and material close-up. Compare quality against
   TTK's character/hands, not merely against our rejected placeholders.
   Only after the owner accepts this geometry should the rigged GLB be
   installed in Roblox Studio and checked at 3/12/25 studs, multiple lights,
   walking, listening, chasing, doors and real FPS.

**Acceptance condition:** if the face still reads as a Roblox toy or the
sleeves/legs read as tubes or stacked cones, the character is **not accepted**
regardless of triangle count, PBR map count, successful CI or animation.

## What we can and cannot assert today

- Q01 console visual direction **was accepted** by owner.
- Engineer theme, wardrobe and behavior **were accepted** in principle.
- Q02 procedural human model **was rejected** for visual quality.
- This repository can audit GLB geometry, texture presence, bone weights
  and runtime isolation. None of those prove visual realism.
- We have not produced or imported an artist-quality human sculpt. This is
  a real production dependency; Blender/DCC authoring cannot be replaced
  by marketing a procedural prototype as TTK-level art.

Non-graphic unease and tension remain the desired creative approach, but
actual content maturity is determined from the finished entire experience
at publishing time.
