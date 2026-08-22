# M6 first-half campaign-flow evidence

Date: 2026-08-22

## Route and presentation

- Confirming the complete 1–3 player roster enters a four-node campaign map before Stage 1 instead of immediately dropping into combat.
- The map shows authored operation positions, connected cleared route, current objective, route subtitle, threat multiplier, clear award, cumulative score, and remaining continues.
- Every non-final settlement returns to the map with the next operation selected; desktop/gamepad start, attack confirm, and mobile whole-screen tap use the same deployment path.
- Stage-clear presentation now uses the active resource's stage number, title, and clear message instead of hard-coded Stage 1 copy.
- Stage 4 leads to a first-front report with one 20,000-point completion award, remaining continues, final score, and return-to-title action.

## Difficulty and settlement data

- `StageDefinition` owns route subtitle, clear message, map position, enemy health/damage scales, clear bonus, time bonus per remaining second, and life bonus per remaining continue.
- Stage 1: health 1.00×, damage 1.00×, clear 5,000.
- Stage 2: health 1.08×, damage 1.04×, clear 6,500.
- Stage 3: health 1.16×, damage 1.08×, clear 8,000.
- Stage 4: health 1.25×, damage 1.12×, clear 10,000.
- Stage multipliers compose with the existing 1–3 player spawn-time scaling and remain snapshotted on each enemy, so joining/leaving cannot rewrite an active wave.
- Score, primary and per-player continues, hero assignments, and joined local slots remain intact through all four transitions.

## Shared-resource defect found and fixed

- Full-order automation revealed that `EncounterDirector.scenes` aliased `StageDefinition.scenes`; its next `configure()` call cleared the previous cached stage resource.
- Encounter director, world art, and stage ambience now consume duplicate arrays while the authored stage resources remain immutable.
- The campaign acceptance suite completes all four settlements and then verifies every cached stage still contains three valid scenes, permanently locking the regression.

## Automated verification

- Focused route, hero-select, local-player, and M4 regressions: 374 assertions, 0 failures before the alias audit.
- Real stage-order reproduction after the alias fix: 7 suites, 409 assertions, 0 failures.
- Final project gate: 42 suites, 2539 assertions, 0 failures.
- The deterministic route run starts at 1,000 points, settles 100 remaining seconds and two continues at every stage, reaches 42,500 after the four stage awards, then reaches exactly 62,500 after the one-time first-front bonus. A repeated completion call cannot add it again.

## Web visual/performance acceptance

- Route fixture: `?campaign_flow_preview=1`; 119.9968 average FPS, 8.3336 ms average, zero frames above 20 ms or 33 ms over 300 frames, with no browser warnings/errors.
- Completion fixture: `?campaign_flow_preview=2`; 120.00 average FPS, 8.3333 ms average, zero frames above 20 ms or 33 ms over 300 frames, with no browser warnings/errors.
- Both 1280×720 fixtures were inspected for node/route readability, status contrast, long-stage-title fit, bottom action fit, score/continue clarity, and overlay occlusion; no corrective visual pass was required.

## Packaging

- Web release export passed; `build/web/index.pck` SHA-256 is `22fa8071d938b8a85e5b77d7c15f1d13b1dd6a2207ab9b4b40c00bdc892460b3`.
- iOS project-only export passed.
- Unsigned generic-device Xcode Debug build passed; executable verified as `Mach-O 64-bit executable arm64`.
- Signed install remains dependent on renewing the invalid development provisioning profile and having the paired phone available.
