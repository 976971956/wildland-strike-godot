# M6 flooded-wilderness stage evidence

Date: 2026-08-22

## Campaign slice

- Stage 2 (`THE FLOODED WILDERNESS`) is a validated 4,200 px route with a 270-second limit.
- Three contiguous scenes—Cypress Floodplain, Drowned Research Camp, and Ancient Spillway—each own an original 1672×941 background, environment identity, transition copy, ambience theme, encounter data, and stage objects.
- Four ordered encounters author fourteen initial/reinforcement spawns across the complete standard/elite roster and all four neutral dinosaur species.
- Completing Stage 1 can advance in place to Stage 2 while preserving score, lives, selected heroes, and 1–3 player roster state; the encounter director, world art, timer, objects, camera bounds, HUD, and music are reconfigured.

## Systemic hazard

- `WATER_CURRENT` is a typed `EnvironmentObjectData` kind rather than a stage-ID branch.
- Every scene owns one current with independent direction, width, push speed, damage, and cooldown.
- Currents push and periodically damage both player and enemy factions, producing ecological and positioning interactions through ordinary fighter hit rules.
- Stage 1 rolling-hazard regression was caught during the first full run, repaired at the original function boundary, and reverified by the unchanged `stage_environment` suite.

## Mirewarden Sable

- Original 2560×320 RGBA eight-state atlas with transparent 320×320 cells; idle, movement, strike, telegraph, tidal smash, rush, hurt, and defeat poses remain isolated.
- Floodgate phase launches a traveling, one-hit-per-player tidal-wave volume after a visible telegraph.
- Harpoon Rush phase changes speed/special behavior at 62% health and registers one raptor reinforcement with the director.
- Deluge phase changes speed/cooldown at 28% health, restores tidal pressure, and registers two Compy reinforcements.
- Phase gates block lethal skipping; dialogue, HUD phase identity, tint, attacks, timings, reinforcement IDs/counts, and recovery are typed resource data.

## Automated verification

- Focused Stage 2 suite: 59 assertions, 0 failures, including a retained three-player transition/run fixture.
- Focused Stage 1 environment + Stage 2 regression: 111 assertions, 0 failures.
- Final full project gate: 39 suites, 2329 assertions, 0 failures.
- The deterministic Stage 2 suite validates art dimensions, scene continuity, encounter order/count, hazards, campaign persistence, all three boss phases, dynamic enemy accounting, tidal-wave creation, and stage completion.

## Web visual/performance acceptance

- Environment fixture: `?stage2_preview=1`; 120.0400 average FPS, 8.3306 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Boss fixture: `?stage2_preview=2`; the first composition was rejected because the boss entered cropped and too dark. The authored spawn offset and phase tints were corrected, then the accepted fixture averaged 120.00 FPS, 8.3333 ms, with zero frames above 20 ms or 33 ms over 300 frames.
- Cypress combat lane, monsoon overlay, current telegraph, Spillway arena, boss silhouette, HUD identity, and telegraph were inspected in the exported 1280×720 build.

## Packaging

- Generated source atlases are archived for provenance but excluded from Web and iOS runtime exports.
- Web release export passed and the final output was copied to `docs/`.
- iOS project export passed.
- Unsigned generic-device Xcode Debug build passed; executable verified as `Mach-O 64-bit executable arm64`.
- Signed install remains dependent on renewing the invalid development provisioning profile and having the paired phone available.
