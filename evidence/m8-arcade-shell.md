# M8 arcade shell and persistence evidence

Date: 2026-08-22

## Consumer arcade flow

- Title idle transitions into an attract/instructions screen without starting or mutating a campaign.
- The title, high-score table, character selection, campaign map, gameplay, pause/options, continue, ending, credits, and final report now have explicit state-owned presentation instead of leaking gameplay actors or HUD beneath menu screens.
- Escape/P or an active player's gamepad Start pauses live gameplay. The root UI remains responsive while actors and world simulation stop, and every exit path clears tree pause/time scale.
- A defeated solo player now receives a visible nine-second continue countdown. Start or Attack confirms; timeout declines; no automatic life is spent before confirmation.
- Final and game-over scores enter the local top ten at most once and report the achieved rank.

## Versioned profile

- `ArcadeProfile` owns `user://wildland_strike_profile.cfg` with schema version 1 and deterministic defaults.
- Persisted settings cover music/effects volume, screen shake, hit flash, haptics, touch scale, UI scale, and language.
- Values are clamped and normalized on load. Version-zero percentage/accessibility/mobile keys migrate to the version-one schema.
- High scores are normalized, sorted by descending score with stable metadata, and capped at ten entries.
- Headless test runs use an in-memory profile and do not alter the player's real local file.

## Automated verification

- Focused arcade-shell/persistence suite: 34 assertions, 0 failures.
- Updated co-op revive/continue suite: 28 assertions, 0 failures.
- Final project gate: 47 suites, 2854 assertions, 0 failures.
- Coverage includes profile defaults, clamping, round-trip persistence, legacy migration, top-ten ordering, attract/high-score/options flow, real tree pause, confirm/timeout continue paths, and score-recording idempotence.

## Web visual/performance acceptance

- Attract fixture: `?arcade_shell_preview=1`; 120.551321376428 average FPS, 8.29522222 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Pause/options fixture: `?arcade_shell_preview=3`; 120.025605462499 average FPS, 8.33155555 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Continue fixture: `?arcade_shell_preview=4`; 120.040013337779 average FPS, 8.33055555 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- High-score fixture passed 1280×720 visual review; accepted fixtures contained no browser warnings or errors.
- QA rejected the first title capture because live HUD/actors remained visible beneath the title and rejected an ambiguous compact effects label. State-owned visibility and the explicit `EFFECTS VOLUME` copy passed the corrected export.

## Packaging

- Web release export passed; `build/web/index.pck` is 66,498,120 bytes with SHA-256 `35af7449522d3a008fecbea820995eded517bfc76db258620e901983968a2ac1`.
- iOS project export passed; exported PCK is 66,498,168 bytes.
- Unsigned generic-device Xcode Debug build passed; executable verified as `Mach-O 64-bit executable arm64`.
- Signed install remains dependent on renewing the invalid development provisioning profile and having the paired phone available.
