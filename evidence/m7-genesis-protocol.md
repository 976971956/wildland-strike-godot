# M7 Genesis Protocol Stage 8 evidence

Date: 2026-08-22

## Campaign finale

- Stage 8 (`THE GENESIS PROTOCOL`) is a validated 4,200 px route with a 330-second limit and the eighth campaign-map node.
- Gene-Forge Causeway, Specimen Gallery, and Genesis Core are contiguous 1,400 px scenes with independent original 1672×941 backgrounds, quarantine/gallery/reactor ambience, encounters, and hazards.
- Five ordered encounters author nineteen initial and reinforcement spawns, including a four-elite gauntlet before the final chamber.
- Completing Stage 7 advances in place while preserving score, continues, heroes, and all 1–3 local-player slots.
- Threat rises to 1.62× health / 1.30× damage and the authored clear award rises to 20,000.
- Final settlement applies the campaign-completion bonus exactly once, then opens the authored ending, credits, and final eight-stage report in order.

## Gene-forge hazard system

- `LabHazardData` validates arc-field, mutagen-pool, and core-surge kinds through bounds, cycle, warning, active, offset, damage, knockback, movement, and color data.
- Two arc fields expose emitters and lane-spanning electrical warnings before faction-neutral contact damage becomes active.
- Two mutagen pools expose oval floor boundaries and bubble cues while applying periodic damage and movement pressure to either faction.
- Two core surges use nested jade/magenta rings and directional arrows; arena placement preserves the final-boss silhouette and player escape lanes.

## Architect Sera Calder

- One original 2560×960 RGBA atlas supplies exact 8×3 transparent cells for Director, Apex Mantle, and Genesis Core forms.
- Director form uses the gene lash and alternating jade/magenta Genesis barrage lanes.
- The 62% phase gate changes to the four-arm Apex Mantle row, switches to rush pressure, and adds an elite enforcer.
- The 25% phase gate changes to the hovering Genesis Core row, creates source- and player-targeted collapse zones, and adds two raptors.
- Collapse zones provide separate warning, impact, and linger windows, are faction-safe, and prevent duplicate placement at the same target.
- Phase-owned sprite rows, attacks, dialogue, reinforcements, HUD identity, behavior history, and completion accounting are resource-driven.

## Automated verification

- Focused Stage 8 suite: 55 assertions, 0 failures.
- Campaign-flow suite: 92 assertions, 0 failures.
- Final project gate: 46 suites, 2817 assertions, 0 failures.
- Coverage includes stage validity, three visual themes, exact background dimensions, six hazard instances/three kinds, encounter/spawn order, Stage 7→8 persistence, exact three-form atlas grid, phase thresholds, special attacks, reinforcements, ending/credits/report order, and completion-bonus idempotence.

## Web visual/performance acceptance

- Environment fixture: `?stage8_preview=1`; 119.996800085331 average FPS, 8.33355555555556 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Final-boss fixture: `?stage8_preview=2`; 119.996800085331 average FPS, 8.33355555555556 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Ending fixture: `?ending_preview=1`; accepted at 1280×720 with readable hierarchy and no crop.
- Credits fixture: `?credits_preview=1`; accepted at 1280×720 with readable columns and no crop.
- Browser console contained no warnings or errors in all accepted fixtures.
- QA rejected the first alpha edit because it baked checkerboard pixels, then rejected fixed global row slicing because irregular source spacing clipped and merged poses. The accepted deterministic builder isolates eight connected figures per row, normalizes each inside a 320×320 transparent runtime cell, and preserves complete silhouettes with gutters.

## Packaging

- The two archived boss generation sources are excluded from Web and iOS runtime exports; only the deterministic transparent runtime sheet is shipped.
- Web release export passed; `build/web/index.pck` is 66,485,852 bytes with SHA-256 `fdf8172460f3471d851c41dbde432925f87c197eead20ad295d15c2e77695a38`.
- iOS project-only export passed; exported PCK is 66,485,900 bytes.
- Unsigned generic-device Xcode Debug build passed; executable verified as `Mach-O 64-bit executable arm64`.
- Signed install remains dependent on renewing the invalid development provisioning profile and having the paired phone available.
