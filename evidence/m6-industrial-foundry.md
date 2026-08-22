# M6 industrial-foundry stage evidence

Date: 2026-08-22

## Campaign slice

- Stage 4 (`FOUNDRY OF IRON`) is a validated 4,200 px industrial route with a 270-second limit.
- Armored Motor Pool, Armored Assembly Line, and Crucible Lift are contiguous 1,400 px scenes with independent original 1672×941 backgrounds, transition copy, ambience, encounters, and machinery identity.
- Five ordered encounters author seventeen initial/reinforcement spawns across standard and elite human roles.
- Completing Stage 3 advances in place to Stage 4 while preserving score, lives, selected heroes, and all 1–3 local-player slots.
- The route adds one breakable supply crate and one carryable/throwable engine block using the shared prop and pickup systems.

## Industrial hazard system

- `IndustrialHazardData` validates conveyor, piston-press, and furnace-vent kinds through resource-owned bounds, cycle duration, warning duration, active duration, phase offset, damage, knockback, push speed, and presentation colors.
- A continuous conveyor pushes players and active actors across the floor plane without changing their faction or target ownership.
- Two piston presses and two furnace vents use independent offsets, visible warning states, active states, and per-target contact cooldowns.
- Active hazards damage players, human enemies, and neutral actors through explicit faction-neutral environment ownership; player co-op safety rules remain intact everywhere else.
- Final visuals use filled steel housings, overhead-connected press shafts, bolts, hazard stripes, dark floor grates, and warning bands instead of abstract floating outlines.

## Forge Regent Volkr

- Original 2560×320 RGBA eight-state exosuit atlas with isolated 320×320 cells and resource-owned `EXOSUIT` visual kind.
- Smelter phase launches two opposing, faction-safe traveling furnace waves.
- Polarity begins at 62% health, applies a telegraphed magnetic pull and damage toward the boss, and registers two shield-guard reinforcements.
- Overdrive begins at 28% health, accelerates furnace pressure, and registers one elite-bulwark reinforcement.
- Phase gates, dialogue, HUD identity, damage, timing, reinforcement accounting, tint, recovery, and completion remain data-driven.
- The first inherited oversized circular special cue was rejected and replaced with readable floor-flame, magnetic cable, and coil cues.

## Automated verification

- Focused Stage 4 suite: 59 assertions, 0 failures.
- Final project gate: 41 suites, 2485 assertions, 0 failures.
- Coverage includes route validity, scene continuity, art dimensions, encounter/spawn order, campaign transition, prop/drop IDs, three hazard kinds, independent cycle offsets, warning/active contact, Forge Regent definition, three boss phases, magnetic pull, dual furnace waves, dynamic reinforcement accounting, and completion.

## Web visual/performance acceptance

- Industrial fixture: `?stage4_preview=1`; 120.0032 average FPS, 8.3331 ms average, zero frames above 20 ms or 33 ms over 300 frames, with no browser warnings/errors.
- Boss fixture: `?stage4_preview=2`; 119.9636 average FPS, 8.3359 ms average, zero frames above 20 ms or 33 ms over 300 frames, with no browser warnings/errors.
- The first machinery fixture was rejected because press heads resembled floating UI outlines; connected steel shafts, filled housings, bolts, grates, and warning-floor stripes replaced it before final acceptance.
- The first boss fixture was rejected because an inherited giant circular telegraph obscured the industrial arena; floor-aligned heat and magnetic cues replaced it before final acceptance.

## Packaging

- Generated boss source is archived for provenance but excluded from Web and iOS runtime exports.
- Web release export passed; `build/web/index.pck` SHA-256 is `82fbdc0b615367efe1f7a81ed9387e57d8808155d1c87c2da32649886292cd95`.
- iOS project-only export passed.
- Unsigned generic-device Xcode Debug build passed; executable verified as `Mach-O 64-bit executable arm64`.
- Signed install remains dependent on renewing the invalid development provisioning profile and having the paired phone available.
