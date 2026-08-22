# M8 audio and localization evidence

Date: 2026-08-22

## Original soundtrack and mix

- The runtime has dedicated title, victory, ending, and credits cues plus eight deterministic stage arrangements and eight deterministic boss arrangements.
- Stage/boss variants change tempo, transposition, phrase rotation, pulse duty, bass order, and lead balance while retaining reproducible sample generation and seamless loops.
- A cue can switch arrangements without leaving and re-entering the cue. The history records both cue and stage variant for deterministic inspection.
- Existing priority-aware eight-voice SFX allocation and per-event music ducking remain active. Hero, boss, and creature effort events have independent pitch, envelope, noise, priority, volume, and duck profiles.
- Hero efforts play on defensive specials and team attacks; boss efforts play on entrance and phase transitions; creature efforts layer with wake and enrage events.

## Subtitles and language-ready UI

- Profile schema version 3 persists `language` and `subtitles`; invalid locales fall back to English and subtitles default on.
- The shell localizes title actions, local high scores, options, values/layouts, control remapping, continue, and game-over text through one keyed localization boundary.
- All 24 authored boss-phase dialogue lines across eight stages have Simplified Chinese subtitles. The HUD retains the source line so changing languages retranslates an active caption immediately.
- Disabling subtitles removes captions without changing boss timing, audio, or other accessibility preferences.
- The build includes Noto Sans SC Variable under the SIL Open Font License in `assets/fonts/`, eliminating system-font dependence on Web and iOS.

## Automated verification

- Focused audio/localization suite: 172 assertions, 0 failures.
- Final project gate: 49 suites, 3065 assertions, 0 failures.
- Coverage proves all shell keys exist in English and Chinese, all 24 boss lines are translated, all 16 campaign arrangements are distinct playable loops, shell cues are nonempty, voice events are playable, settings normalize, language changes reach the HUD immediately, subtitles can be suppressed, and the bundled font contains Chinese and Latin glyphs.

## Web visual/performance acceptance

- Chinese options fixture: `?audio_localization_preview=1`; accepted after visual inspection with no browser warnings or errors.
- Chinese boss subtitle fixture: `?audio_localization_preview=2`; 120.020803605958 average FPS, 8.33188888888889 ms average, zero frames above 20 ms or 33 ms over 300 frames, with no browser warnings or errors.
- QA rejected the first Web capture because every Chinese character used the missing-glyph box. The accepted build bundles Noto Sans SC and renders readable Simplified Chinese in both options and touch-safe dialogue.

## Packaging

- Web release export passed; `build/web/index.pck` is 79,811,460 bytes with SHA-256 `509b1b0794136e1e4e922826f30dc58ec3fd76937552de1a1240f3cf72701e55`.
- iOS project export passed; `build/ios/WildlandStrike.pck` is 79,811,508 bytes with SHA-256 `695fdccb46baaee9bd9fae8e58d47772cee86ae3be94f966cec1bdb5c7039534`.
- Unsigned generic-device Xcode Debug build passed with Xcode's iPhoneOS 26.5 SDK; executable verified as `Mach-O 64-bit executable arm64`.
- Signed installation still depends on renewed development provisioning and an available paired phone.
