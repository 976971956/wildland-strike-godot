# M8 mobile and accessibility evidence

Date: 2026-08-22

## Mobile controls and lifecycle safety

- Virtual joystick, Attack, Jump, Special, and Pause centers derive from the platform safe rectangle rather than hard-coded screen edges.
- Touch size is persisted and clamped from 0.75× to 1.35×; maximum-size hit targets remain inside a representative 70/28/70/38 px landscape safe area without action overlap.
- Classic, compact, and fully mirrored left-handed layouts remap joystick-side capture and every action center through the same persisted setting.
- Title score/options targets, character cards, campaign deployment, gameplay actions, pause/options rows, resume, and continue confirmation all have touch paths.
- Focus loss releases every held virtual action and opens a paused options screen. Returning to the app never resumes combat without player confirmation.
- Touch dialogue uses a narrower raised panel and deterministic two-line word wrapping to remain clear of the joystick and action cluster.

## Accessibility and rebinding

- Profile schema version 2 persists eight physical-key bindings: four movement directions, Attack, Jump, Special, and Pause.
- Rebinding replaces only keyboard events, preserves gamepad events, swaps a conflicting binding instead of silently duplicating it, saves immediately, and restores the original project InputMap when a test/game tree exits.
- Music/effects, touch size, UI text size, shake, hit flash, haptics, and high-contrast cues are independently selectable in the pause/options screen.
- Critical HUD, objective, dialogue, options, and control-remap text responds to the persisted UI scale.
- Timed industrial, disaster, jungle, vault, and laboratory hazards add a pulsing outlined warning triangle, exclamation mark, and boundary strokes. The cue is shape/pattern based and does not depend on color recognition.

## Automated verification

- Focused mobile/accessibility suite: 21 assertions, 0 failures.
- Related mobile roster, profile/remap, HUD/audio, and performance suites pass.
- Final project gate: 48 suites, 2883 assertions, 0 failures.
- Coverage includes safe-area placement, maximum-scale non-overlap, touch pause/resume, settings touch adjustment, UI-scale propagation, high-contrast toggling, focus-loss pause, profile binding round trip, remap application, and legacy migration.

## Web visual/performance acceptance

- Mobile safe-area fixture: `?mobile_accessibility_preview=1`; 120.006400341351 average FPS, 8.33288888888889 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Control-remap fixture: `?arcade_shell_preview=5`; 119.873733001239 average FPS, 8.34211111111111 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Both accepted Chrome fixtures contained no browser warnings or errors.
- QA rejected the first mobile capture because Pause covered the objective and a long touch subtitle clipped behind action buttons. The accepted layout moves Pause below the objective, wraps touch dialogue to two lines inside a control-safe panel, centers the fighter outside action controls, and visibly demonstrates the non-color warning marker.

## Packaging

- Web release export passed; `build/web/index.pck` is 66,511,288 bytes with SHA-256 `9a55d0b1168602bbdd121b293de204c463faa76ca3b5c43c21440cce877a43f5`.
- iOS project export passed; exported PCK is 66,511,336 bytes.
- Unsigned generic-device Xcode Debug build passed; executable verified as `Mach-O 64-bit executable arm64`.
- Signed install remains dependent on renewing the invalid development provisioning profile and having the paired phone available.
