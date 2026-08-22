# M7 burning-settlement Stage 5 evidence

Date: 2026-08-22

## Campaign slice

- Stage 5 (`THE BURNING SETTLEMENT`) is a validated 4,200 px route with a 285-second limit and a fifth campaign-map node.
- Ember Refuge, Burning Market, and Ashen Cistern are contiguous 1,400 px scenes with independent original 1672×941 backgrounds, transition copy, firestorm ambience, encounters, and hazard composition.
- Five ordered encounters author fifteen initial/reinforcement spawns across the complete human/elite/dinosaur roster.
- Completing Stage 4 advances in place while preserving score, continues, heroes, and all 1–3 local-player slots.
- Threat rises to 1.34× health / 1.17× damage and the authored clear award rises to 12,000.

## Disaster hazard system

- `DisasterHazardData` validates fire patch, smoke cloud, and cistern jet kinds through cycle, warning, active, offset, damage, movement, direction, and slowdown data.
- Two fire patches use independent cycle offsets and damage either faction only during their explicit active windows.
- The market smoke cloud damages and slows actors while active, leaving cyan evacuation lighting and clear floor edges readable.
- Two opposing cistern jets push and damage actors directionally, creating an arena hazard without changing combat ownership.

## Cinder Matriarch Veyra

- Original 2560×640 RGBA atlas with exact 8×2 transparent cells: human fire marshal on row 0 and a genuinely different obsidian ash-beast on row 1.
- Fire Marshal phase launches two opposing ember waves.
- Ashbeast begins at 58% health, switches the resource-owned sprite row, enters a high-speed rush state, and registers two elite-blade reinforcements.
- Cistern Rupture begins at 24% health, keeps the transformed silhouette, launches opposing water-pressure waves, and registers a demolitionist.
- Phase-owned row overrides are validated against atlas bounds; identity, attacks, timing, tint, dialogue, HUD phase, reinforcements, and completion remain data-driven.

## Automated verification

- Focused Stage 5 suite: 54 assertions, 0 failures.
- Campaign-flow suite: 60 assertions, 0 failures.
- Final project gate: 43 suites, 2606 assertions, 0 failures.
- Coverage includes route validity, three scene themes, background dimensions, five hazard instances/three kinds, encounter and spawn order, Stage 4→5 persistence, fire damage, smoke slowdown, jet push, exact atlas grid, phase row switching, three unique specials, dynamic reinforcement accounting, and phase history.

## Web visual/performance acceptance

- Environment fixture: `?stage5_preview=1`; 120.00 average FPS, 8.3334 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Boss fixture: `?stage5_preview=2`; 120.08 average FPS, 8.3277 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Browser console contained no warnings or errors.
- QA rejected and corrected a scene-boundary strip, phase-reinforcement occlusion, and an inherited oversized circular warning. The accepted boss fixture isolates the transformed silhouette and uses compact floor-aligned rush cues.

## Packaging

- Generated boss source is archived for provenance but excluded from Web and iOS runtime exports.
- Web release export passed; `build/web/index.pck` SHA-256 is `6299b6bf1a422239a282b05aaf43e6e3e7b3c8497d349989e5ea65dd32cf970a`.
- iOS project-only export passed.
- Unsigned generic-device Xcode Debug build passed; executable verified as `Mach-O 64-bit executable arm64`.
- Signed install remains dependent on renewing the invalid development provisioning profile and having the paired phone available.
