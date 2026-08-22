# M5 twelve-weapon sandbox evidence

Date: 2026-08-22

## Catalog

| Family | Weapons | Distinct systemic behavior |
|---|---|---|
| Melee | Machete, Steel Pipe, Field Whip, Shock Baton | baseline durability, forced heavy launch, scaled reach, stun plus chained target |
| Firearms | Pistol, Shotgun, Rifle, Burst SMG | direct round, five-lane spread, three-target penetration, three rounds per ammo unit |
| Explosives | Grenade, Molotov, Rocket, Proximity Mine | timed blast, lingering fire ticks, contact detonation, stationary arm/trigger cycle |

Every resource owns a unique weapon and behavior ID, capacity, damage or melee bonus, impact profile, mixed use cue, display color, and explicit pickup/drop mapping. Runtime consumption is exactly once per use and honors each hero's item-efficiency capacity modifier.

## Automated acceptance

- Typed resources: 12/12 valid; no duplicate weapon or behavior IDs; four resources per family.
- Drops: 12 explicit pickup IDs resolve to 12 unique resources.
- Melee: real hitbox reach scaling, resource-owned bonus damage, forced launch, durability, chain damage, and stun verified.
- Firearms: five shotgun depth velocities, three-round SMG use, and three unique rifle penetrations verified.
- Explosives: rocket contact, mine arm delay/stationarity/proximity trigger, and Molotov immediate plus later fire damage verified.
- Friendly-fire boundary: an armed mine ignores a nearby teammate, triggers on the opposing actor, and leaves the teammate unharmed.
- Regression: 35 suites, 1867 assertions, 0 failures.

## Packaging and presentation

- Exported Web fixture: 119.9984 average FPS over 300 frames, 0 frames above 20 ms, 0 frames above 33 ms, and no browser warnings/errors.
- All twelve labeled pickup silhouettes were visually inspected without stage-object overlap.
- Web release export passed.
- iOS project export and unsigned generic-device Mach-O arm64 build passed.

The first M5 checklist item is complete. Stage-authored distribution beyond the original three generic family drops continues in the props/items batch.
