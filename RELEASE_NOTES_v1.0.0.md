# Wildland Strike v1.0.0

Release candidate date: 2026-08-22

Wildland Strike is a clean-room, original-IP Godot arcade brawler with a complete eight-stage campaign, four heroes, 1–3 player local co-op, mobile touch play, Web delivery, and iOS device export.

## Campaign and combat

- Eight stages, 24 authored scenes, 38 ordered encounters, eight multi-phase boss battles, a campaign route, ending, credits, and final report.
- Four distinct heroes with individual health, damage, movement, aerial, grapple, and item-efficiency profiles.
- Run/double-tap movement, four-hit chains, aerial and dive attacks, command move, defensive special, grabs, directional throws, weapons, props, team revive, and linked team attack.
- Human standard/elite roles, neutral dinosaur ecology, twelve weapon behaviors, a three-player vehicle set piece, and five families of data-driven stage hazards.

## Consumer build

- Title, attract/instructions, character select, campaign map, pause/options, continue countdown, local top-ten scores, victory, ending, and credits.
- Versioned local profile with v0/v1/v2 migration, corruption fallback, last-known-good backup, configurable audio/feedback/UI/touch/language/subtitles, and keyboard rebinding.
- English and Simplified Chinese interface/subtitles, OFL-licensed Noto Sans SC, original synthesized music/SFX/efforts, and accessibility cues independent of color.
- Desktop/Web keyboard and gamepad support; 1–3 player local co-op with controller disconnect/reconnect restoration.
- Mobile landscape safe-area controls, adjustable classic/compact/left-handed layouts, haptics, focus-loss pause, and suspend/resume safety.

## Release qualification

- 53 deterministic suites and 3,719 assertions pass, including the final content/provenance/license audit.
- All 24 stage/player-count difficulty cells, all 14 unique hero rosters, all campaign waves, and every final boss gate are covered.
- Maximum-load Chromium fixture: three players, Stage 8 final boss, twelve additional enemies, hazards, 300 sampled frames, 8.050 ms average, zero frames above 20/33 ms, and no browser warnings/errors.
- Web export, iOS project export, and unsigned Xcode generic-device arm64 build pass.

Final tag publication requires the clean-checkout gate, exact GitHub Pages deployment verification, and the signed physical-iPhone attempt documented in the release evidence.
