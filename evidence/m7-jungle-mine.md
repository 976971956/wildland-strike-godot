# M7 jungle-mine Stage 6 evidence

Date: 2026-08-22

## Campaign slice

- Stage 6 (`THE TITAN QUARRY`) is a validated 4,200 px route with a 300-second limit and a sixth campaign-map node.
- Jungle Research Trail, Jungle Mine Entrance, and Titan Shaft are contiguous 1,400 px scenes with independent original 1672×941 backgrounds, transition copy, rain/mine/cavern ambience, encounters, and hazard composition.
- Five ordered encounters author seventeen initial/reinforcement spawns across the complete human, elite, and dinosaur roster.
- Completing Stage 5 advances in place while preserving score, continues, heroes, and all 1–3 local-player slots.
- Threat rises to 1.43× health / 1.21× damage and the authored clear award rises to 14,000.

## Jungle hazard system

- `JungleHazardData` validates spore bloom, mine cart, and Titan stomp kinds through bounds, cycle, warning, active, offset, damage, movement, slowdown, and texture data.
- Three spore blooms use independent offsets and slow and damage either faction only during their active windows.
- The generated ore cart travels through the combat lane during its explicit active window and deals faction-neutral contact damage.
- Two giant-creature stomp zones use floor footprints and descending-leg cues before their damaging window, creating systemic pressure without a scripted creature cameo.

## Titan Warden Korva

- Original 2560×320 RGBA atlas with exact 8×1 transparent cells and a distinct armored mining-commander silhouette.
- Seismic Survey emits three sequential forward floor fractures.
- Titan Protocol begins at 60% health, fractures both sides of the arena, and registers a triceratops reinforcement.
- Deep Core begins at 25% health, enters a high-speed full-body drill charge, and registers an elite bulwark.
- Specials use faction-safe floor hit volumes; identity, attacks, timing, tint, dialogue, HUD phase, reinforcements, and completion remain resource-driven.

## Automated verification

- Focused Stage 6 suite: 53 assertions, 0 failures.
- Campaign-flow suite: 70 assertions, 0 failures.
- Final project gate: 44 suites, 2672 assertions, 0 failures.
- Coverage includes route validity, three scene themes, exact background dimensions, six hazard instances/three kinds, encounter and spawn order, Stage 5→6 persistence, spore slowdown, cart travel/contact damage, stomp activation, exact boss atlas grid, three unique specials, sequential/bidirectional fractures, reinforcements, and full phase history.

## Web visual/performance acceptance

- Environment fixture: `?stage6_preview=1`; 120.0 average FPS, 8.333333 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Boss fixture: `?stage6_preview=2`; 120.006400341352 average FPS, 8.332888888889 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Browser console contained no warnings or errors.
- QA rejected two procedural cart presentations. The accepted fixture uses the generated transparent pixel-art cart and keeps rails, foliage, hazard cues, fighters, and the active lane visually separated.

## Packaging

- Generated boss/cart source and isolation-edit images are archived for provenance but excluded from Web and iOS runtime exports.
- Web release export passed; `build/web/index.pck` SHA-256 is `c123fda70f1fc7a339ac85c6601ea60cc7d5900ec161d226adf15d0b00319503`.
- iOS project-only export passed.
- Unsigned generic-device Xcode Debug build passed; executable verified as `Mach-O 64-bit executable arm64`.
- Signed install remains dependent on renewing the invalid development provisioning profile and having the paired phone available.
