# M4 local-cooperation acceptance

Date: 2026-08-22

This gate verifies the complete Stage 1 loop with every unique local roster required by M4. The deterministic matrix contains fourteen runs:

- Solo: Ranger, Mara, Kestrel, Atlas.
- Two players: Ranger+Mara, Ranger+Kestrel, Ranger+Atlas, Mara+Kestrel, Mara+Atlas, Kestrel+Atlas.
- Three players: Ranger+Mara+Kestrel, Ranger+Mara+Atlas, Ranger+Kestrel+Atlas, Mara+Kestrel+Atlas.

Every run must retain the assigned heroes and player count, start and clear all four encounters, pass both boss phases and dynamic reinforcements, reach victory at 7,500 combat score, and complete settlement at 16,900 final score.

The same suite exercises the mobile single-player path through real touch-control routing: title start, direct hero selection/confirmation, eight-way joystick intent, attack, jump, special, release handling, and focus-loss cleanup. Web visual/performance and iOS arm64 build evidence are recorded in `PROJECT_PLAN.md` when the gate closes.

## Result

- Matrix: 14/14 Stage 1 rosters passed.
- Regression: 34 suites, 1740 assertions, 0 failures.
- Mobile Web fixture: 120.0032 average FPS over 300 frames; 0 frames above 20 ms; 0 frames above 33 ms; 0 browser warnings/errors.
- Packaging: Web release export and GitHub Pages deployment passed; unsigned generic-device iOS build produced a Mach-O arm64 executable.

M4 exit gate: **passed**.
