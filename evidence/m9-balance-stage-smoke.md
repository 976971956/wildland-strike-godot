# M9 release balance and all-stage smoke evidence

Date: 2026-08-22

## Difficulty curve

Each cell is `enemy health / enemy damage` relative to Stage 1 solo. Health scales by 1.00×, 1.40×, and 1.70× for one, two, and three players. Damage scales by 1.00×, 1.08×, and 1.16× so extra players increase threat without multiplying unavoidable burst damage at the same rate as party health/output.

| Stage | Solo | Two players | Three players |
|---:|---:|---:|---:|
| 1 | 1.000 / 1.000 | 1.400 / 1.080 | 1.700 / 1.160 |
| 2 | 1.080 / 1.040 | 1.512 / 1.123 | 1.836 / 1.206 |
| 3 | 1.160 / 1.080 | 1.624 / 1.166 | 1.972 / 1.253 |
| 4 | 1.250 / 1.120 | 1.750 / 1.210 | 2.125 / 1.299 |
| 5 | 1.340 / 1.170 | 1.876 / 1.264 | 2.278 / 1.357 |
| 6 | 1.430 / 1.210 | 2.002 / 1.307 | 2.431 / 1.404 |
| 7 | 1.520 / 1.250 | 2.128 / 1.350 | 2.584 / 1.450 |
| 8 | 1.620 / 1.300 | 2.268 / 1.404 | 2.754 / 1.508 |

The maximum release cell is therefore 2.754× health and 1.508× damage, both enforced by tests. At two and three players total enemy health rises, but health per player falls below solo so joining a player never makes a wave slower under equal participation.

## Hero and roster bands

- Ranger is the 1.00× reference with 120 health.
- Mara's 0.90× damage gives a 1.111× solo TTK and trades 100 health for 1.50× item efficiency.
- Kestrel's 0.85× damage gives a 1.176× solo TTK and trades 90 health for 1.40× aerial control and the fastest movement.
- Atlas's 1.30× damage gives a 0.769× solo TTK and trades speed, item efficiency, and aerial control for 150 health and 1.50× grapple power.
- Every non-reference hero must retain at least one explicit strength and one explicit tradeoff.
- All fourteen unique hero rosters are evaluated. Solo TTK is constrained to 0.75–1.18×; duo/trio combined-output TTK is constrained to 0.52–0.82× so cooperation is materially faster without deleting the encounter health budget.

## All-stage smoke coverage

- Eight valid stage definitions, 24 authored scenes, and 38 ordered encounters.
- Every wave resolves to valid spawn data; the campaign floor is at least 120 spawns and 20 distinct referenced enemy roles.
- Every referenced enemy ID exists in the runtime catalog.
- Every stage has an authored boss, and every final encounter resolves to a boss gate.
- Representative runtime spawning is executed for every stage at one, two, and three local players. Definition selection and exact scaled max health are asserted in all 24 cells.

## Automated result

- `release_balance_matrix`: 156 assertions, 0 failures.
- `release_stage_smoke`: 331 assertions, 0 failures.
- Combined release-batch gate: 487 assertions, 0 failures.
- Full project regression: 51 suites, 3,552 assertions, 0 failures.

## Platform package verification

- Real Chromium Stage 8 final-boss preview: 300 sampled frames, 120.002 average FPS, 8.333 ms average frame time, 0 frames over 20 ms, 0 frames over 33 ms, and no browser warnings or errors.
- Web package: 79,811,460 bytes, SHA-256 `f9b7c76e88de077e72e46d37a898e72bf412f1864d67299bba98561b4f08ac79`.
- iOS package: 79,811,508 bytes, SHA-256 `9d153ad6b4df5e2db3498bbd525392e99ce4012f12647ba08277904e2ed0513c`.
- Xcode device build: `BUILD SUCCEEDED`; resulting executable is Mach-O 64-bit arm64.
