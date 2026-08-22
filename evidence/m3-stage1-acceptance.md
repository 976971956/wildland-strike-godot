# M3 Stage 1 exit-gate evidence

Date: 2026-08-22

Result: **PASS**

Stage 1 satisfies the M3 vertical-slice exit gate on the current desktop/Web reference environment and the unsigned generic-device iOS arm64 build path. No critical or high-severity Stage 1 defect remains open.

## Automated regression

- Command: `godot --headless --path . --script res://tests/test_runner.gd`
- Result: 27 suites, 1110 assertions, 0 failures.
- The dedicated `stage_1_acceptance` suite completes all four encounters in authored order, enters all three scenes, resolves the reinforcement wave, drives both boss phases and dynamic hunters, verifies three encounter rewards, and reaches restart-ready settlement.
- Expected score contract: 7500 combat score and 16900 final score with the deterministic full-health/time fixture.
- Balance budget: 14 authored spawns, 16 runtime enemies including boss reinforcements, encounter health budgets of 142/212/240/444, and no opening above four enemies or boss peak above five.

## Web acceptance

- `?stage_acceptance=1` passed in the exported Web game with encounters started/cleared in order, boss phases `command` then `overdrive`, zero remaining enemies, final score 16900, and victory phase `complete`.
- `?formation_acceptance=1` passed with four enemies, four unique approach lanes, and a 56.84 px minimum center distance after the convergence fixture. This closes the reported attached-enemy movement defect with stable formation slots, proportional lane correction, soft steering, and a 56 px visible-overlap floor.
- `?baseline_benchmark=1` averaged 120.01 FPS over 300 frames with p95/p99 at 8.33 ms and zero frames above 20 ms or 33 ms.
- Browser logs contained the expected Godot/runtime/acceptance messages and no error-level game failures.
- Desktop and forced-touch HUD fixtures were visually checked; touch dialogue and control zones do not overlap.

## iOS build

- Godot `iOS Device Debug` project export passed.
- Xcode Debug `iphoneos` arm64 build with `CODE_SIGNING_ALLOWED=NO` passed.
- Signed installation remains external-state blocked by the invalid development provisioning profile and unavailable paired phone; it remains tracked as a release/device task rather than an M3 code defect.

## Exit decision

M3 is complete. The next unblocked milestone is M4: four hero definitions, character select, and the reusable 1–3 local-player architecture.
