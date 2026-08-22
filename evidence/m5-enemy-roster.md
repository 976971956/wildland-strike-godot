# M5 standard/elite enemy roster evidence

Date: 2026-08-22

## Authored roster

- Standard: grunt (flanker), brute (charger), hunter (direct ranged), knife raider (duelist), demolitionist (delayed explosive ranged), and shield guard (pressure/control).
- Elite: enforcer (armored charge), blade (fast duelist), bombardier (accelerated explosive control), and bulwark (armored shield pressure).
- Hunter and all seven new roles use unique original 2560×320 RGBA eight-state strips. The archived 8×8 source, final hashes, prompt, rejected-source limitations, and deterministic isolation process are recorded in `ASSET_PROVENANCE.md`.

## System acceptance

- Rank, outgoing power, stun-duration resistance, and consumable knockdown armor are typed `EnemyDefinition` fields; runtime behavior contains no enemy-ID conditionals.
- Knife specialists visibly feint, lunge, disengage diagonally when cornered, recover, and observe cooldown data.
- Demolition specialists reuse the delayed grenade projectile, combat ownership, co-op scaling, cross-faction damage, and explosion feedback pipeline.
- Shield specialists block only an incoming front-facing vector, reduce damage, suppress launch, spend guard capacity, expose a guard meter, enter an audible break, and restore on an authored timer. Rear attacks bypass the guard.
- Elite attack and projectile damage apply their archetype power against players and opposing human/neutral factions without mutating the existing co-op snapshot contract.
- Four encounter recipes—street patrol, demolition crossfire, elite assault, and ecology collision—validate unique pools and formations, expand deterministically by seed, cap difficulty growth, and return ordinary `EnemySpawnData` consumed by `EncounterWaveData.resolved_spawns()` and the existing director.

## Automated verification

- Targeted roster/definition/animation suites: 328 assertions, 0 failures before the fixture-layout pass; the final roster suite contains 150 assertions.
- Full project gate: 38 suites, 2260 assertions, 0 failures.
- Web fixture query: `?enemy_roster_preview=2`.

## Web visual/performance acceptance

- First browser composition was rejected because a center banner obscured the upper row.
- Accepted layout shows all ten humans unobstructed in two rows with readable labels, weapons, shield bars, and elite gold cues.
- 300-frame sample: 119.9968 average FPS, 8.3336 ms average, 0 frames above 20 ms, 0 frames above 33 ms.
- Browser console: engine/build/performance logs only; zero warnings or errors.

## Packaging

- The opaque 8×8 source atlas is excluded from both runtime export presets; only normalized transparent strips ship.
- Web release export passed.
- iOS project export and unsigned generic-device Mach-O arm64 build passed.
