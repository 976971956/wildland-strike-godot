# M6 highway-vehicle stage evidence

Date: 2026-08-22

## Campaign slice

- Stage 3 (`HIGHWAY OF TEETH`) is a validated 4,200 px vehicle route with a 255-second limit.
- Red Mesa Highway, Convoy Checkpoint, and Tempest Overpass are contiguous 1,400 px scenes with independent original 1672×941 backgrounds, transition copy, environment identity, ambience, encounters, and road objects.
- Five ordered encounters author seventeen initial/reinforcement spawns across standard, elite, and neutral dinosaur roles.
- Completing Stage 2 advances in place to Stage 3 while preserving score, lives, selected heroes, and all 1–3 local-player slots.

## Vehicle system

- `VehicleStageData` owns the sequence bounds, three ordered lane positions, minimum/maximum speed, acceleration, braking, passive drag, steering speed, hull health, collision damage, ram damage/cooldown, mounted weapon, and mounted-fire cooldown.
- The shared `HighwayVehicle` samples the primary player's horizontal/depth movement for speed and lane control while every active local player retains independent attack edges and cooldowns for the mounted piercing rifle.
- Mounted players follow the vehicle as the encounter/camera lead, stop running incompatible on-foot physics, hide the standing full-body sprite, and restore normal presentation/control when the sequence ends.
- Six `ROAD_HAZARD` resources cover barricades, gates, and oil traps. Vehicle contact damages hull, reduces speed, creates heavy impact feedback, destroys or displaces the road object, and awards authored score.
- Vehicle overlap uses the normal enemy damage pipeline for a 48-damage forced-launch ram. Hull depletion resets the shared hull only after a breakdown stun and applies an authored collision hit to each active rider.

## Iron Vulture

- Original 2560×320 RGBA eight-state armored-truck atlas with isolated 320×320 cells and a resource-owned `VEHICLE` visual kind.
- Pursuit phase uses a visible road-aligned ram telegraph and burst state.
- Minefield begins at 64% health, deploys a delayed armed road mine that damages the vehicle hull, and registers one elite bombardier reinforcement.
- Redline begins at 30% health, increases speed and ram frequency, and registers one elite enforcer reinforcement.
- Phase gates, dialogue, HUD identity, damage, timing, reinforcement accounting, tint, recovery, and completion all remain data-driven.

## Automated verification

- Focused Stage 3 suite: 71 assertions, 0 failures.
- Targeted resource-driven enemy/roster/Stage 3 regression after the telegraph pass: 272 assertions, 0 failures.
- Final project gate: 40 suites, 2413 assertions, 0 failures.
- Coverage includes route validity, art dimensions, scene continuity, encounter/spawn order, six hazards, campaign persistence, three-player mounting, acceleration, braking contract, lane selection, independent mounted fire, hull collision, ram scoring, three boss phases, mine arming/contact, dynamic director accounting, and stage completion.

## Web visual/performance acceptance

- Canyon fixture: `?stage3_preview=1`; 119.5997 average FPS, 8.3612 ms average, zero frames above 20 ms or 33 ms over 300 frames, with no browser warnings/errors.
- Boss fixture: `?stage3_preview=2`; 120.0016 average FPS, 8.3332 ms average, zero frames above 20 ms or 33 ms over 300 frames, with no browser warnings/errors.
- The first exported canyon fixture was rejected because its procedural player car was visually toy-like and the standing Ranger sprite intersected the roof. The accepted build uses an original four-state 1440×240 Desert Interceptor sheet and hides incompatible standing sprites while mounted.
- The first boss telegraph used an oversized circular arena cue. It was replaced with readable road-aligned ram chevrons before final acceptance.

## Packaging

- Generated source atlases are archived for provenance but excluded from Web and iOS runtime exports.
- Web release export passed and is copied to `docs/` for GitHub Pages.
- iOS project export passed.
- Unsigned generic-device Xcode Debug build passed; executable verified as `Mach-O 64-bit executable arm64`.
- Signed install remains dependent on renewing the invalid development provisioning profile and having the paired phone available.
