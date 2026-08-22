# M9 compatibility, lifecycle, migration, and performance evidence

Date: 2026-08-22

## Runtime resilience

- A disconnected secondary controller releases its live input binding while reserving the original local-player slot.
- Reconnection automatically restores slot index, hero, health, position, remaining continues, HUD state, and a 2.2-second safety-invulnerability window.
- Application suspend saves the profile, releases touch input, and routes active gameplay into the existing pause/options flow.
- Application resume never advances gameplay automatically; the player explicitly resumes through the normal pause action.

## Save compatibility and recovery

- Version 1 settings/scores migrate with default bindings.
- Version 2 settings/bindings migrate with version 3 subtitle and language defaults.
- Current and future-version files load only known schema fields and ignore unknown settings.
- Each subsequent valid save keeps a last-known-good `.bak` profile.
- A damaged primary file recovers from that backup; a damaged file with no valid backup returns clean defaults rather than preventing startup.

## Platform contract

- Godot GL Compatibility renderer on desktop, Web, and mobile.
- Web canvas uses responsive `canvas_items`/`expand`, automatic resize/focus, and no thread/cross-origin-isolation requirement.
- iOS target is arm64, minimum iOS 15.0, tracking disabled, camera module disabled, and privacy declarations present.

## Maximum-load browser fixture

The reproducible `?release_stress_preview=1` fixture renders three local heroes, Architect Sera Calder, twelve additional enemies spanning elite/mutant/dinosaur/standard roles, and Stage 8 hazards with live actor simulation.

- 300 sampled frames.
- 124.218 average reported FPS / 8.050 ms average frame time.
- p50/p95/p99: 8.333 / 8.333 / 8.333 ms.
- Frames over 20 ms: 0.
- Frames over 33 ms: 0.
- Browser warnings/errors: 0.

## Automated and package results

- Focused affected gate: 4 suites, 146 assertions, 0 failures.
- Full project regression: 52 suites, 3,586 assertions, 0 failures.
- Web package: 79,814,916 bytes, SHA-256 `129d649ee24ed05e7dad8d035c26ee7f7bc461b943fd57f29f558e3183e790c8`.
- iOS package: 79,814,964 bytes, SHA-256 `bc7490fbf42995c346d404cd9d21a19ceb0dfa150bd7f44ce5aa3316e1407036`.
- Xcode generic iOS device build: `BUILD SUCCEEDED`; executable is Mach-O 64-bit arm64.

Signed installation remains part of the final release gate because it requires a valid Apple Development identity/profile and the paired physical phone.
