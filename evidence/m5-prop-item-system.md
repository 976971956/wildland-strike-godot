# M5 prop and item system evidence

Date: 2026-08-22

## Authored environment set

| Family | Stage 1 resources | Runtime behavior |
|---|---|---|
| Breakables | Avenue crate, courtyard crate, plant crate | Ordinary hitboxes damage durability, award score, and spawn a typed drop |
| Carryables | Avenue tire, courtyard canister, plant scrap | Pick up, follow the carrier, throw on the gameplay plane, launch on impact, break or land |
| Rolling hazard | Courtyard drum | Bounded movement, turnaround, contact cooldown, and damage to either faction |

Every carryable owns independent durability, throw damage, speed, lifetime, impact policy, score, visual identity, and drop ID. Carry/throw state unregisters the prop from world targeting until it lands. Player hurt, special, linked attack, revive, and departure paths safely release held objects.

## Typed pickup tiers

| Food tier | Healing | Score |
|---|---:|---:|
| Snack | 15 | 150 |
| Ration | 28 | 400 |
| Field Meal | 50 | 750 |
| Feast | full-cap value | 1,500 |

| Treasure tier | Score |
|---|---:|
| Token | 300 |
| Badge | 800 |
| Relic | 2,000 |
| Intel | 5,000 |

Food healing is multiplied by the selected hero's item-efficiency stat and clamped to maximum health. Treasure never alters health. The legacy `food` drop remains a compatibility alias for Ration while all newly authored drops use explicit typed IDs.

## Automated acceptance

- Eight typed item resources validate with unique IDs and strictly rising tier curves.
- All four food tiers verify exact efficiency-scaled, health-capped healing and score.
- All four treasure tiers verify exact score with no healing side effect.
- Attack-near-prop pickup, overhead follow, second-attack throw, enemy damage/launch, teammate safety, prop consumption/score, and typed impact drop are deterministic.
- Stage fixture verifies three breakables, three carryables, and one rolling hazard across all three scenes.
- Regression: 36 suites, 1946 assertions, 0 failures.

## Packaging and presentation

- Exported Web fixture: 119.9936 average FPS over 300 frames, 0 frames above 20 ms, and 0 frames above 33 ms.
- Three distinct prop silhouettes and eight labeled pickup tiers were visually inspected in the mobile-safe 1,280×720 layout.
- Web release export passed and its generated files were copied to `docs/` for GitHub Pages.
- iOS project export passed.
- Unsigned generic-device build passed; executable verified as Mach-O 64-bit arm64.

The second M5 checklist item is complete. The next task is the four-archetype dinosaur ecosystem.
