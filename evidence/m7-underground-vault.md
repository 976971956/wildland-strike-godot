# M7 underground-vault Stage 7 evidence

Date: 2026-08-22

## Campaign slice

- Stage 7 (`THE SEVENTH LOCK`) is a validated 4,200 px route with a 315-second limit and a seventh campaign-map node.
- Vault Elevator Descent, Cryogenic Vault Hall, and Twin Core Vault are contiguous 1,400 px scenes with independent original 1672×941 backgrounds, transition copy, elevator/cryo/core ambience, encounters, and hazard composition.
- Five ordered encounters author eighteen initial and reinforcement spawns across the human, elite, and dinosaur roster.
- Completing Stage 6 advances in place while preserving score, continues, heroes, and all 1–3 local-player slots.
- Threat rises to 1.52× health / 1.25× damage and the authored clear award rises to 16,000.

## Vault hazard system

- `VaultHazardData` validates moving-deck, security-laser, and cryogenic-vent kinds through bounds, cycle, warning, active, offset, damage, knockback, and movement data.
- Two deck shifts displace fighters on independent offsets while keeping their warning and movement windows explicit.
- Two horizontal security lasers expose posts and lane-aligned warnings before faction-neutral damage becomes active.
- Two cryogenic vents expose floor bubbles/frost cues before their active contact window; arena placement keeps them outside the paired-boss focal area.

## Vault Sentinels Orin and Nyx

- One original 2560×640 RGBA atlas supplies exact 8×2 transparent cells: Orin occupies row 0 and Nyx row 1.
- Orin is a heavy barrier commander whose second phase emits faction-safe barrier pulses and participates in synchronized crossfire.
- Nyx is an agile phase-blade commander whose rush pressure transitions into the same synchronized crossfire protocol.
- Both bosses retain independent health and phase state. A keyed boss ledger aggregates both maximum/current pools into one `VAULT SENTINELS` HUD without double-counting damage or completing the encounter until both are defeated.
- Crossfire and barrier attacks use reusable horizontal energy lanes, explicit warnings, source ownership, and player-only damage resolution.

## Automated verification

- Focused Stage 7 suite: 58 assertions, 0 failures.
- Campaign-flow suite: 80 assertions, 0 failures.
- Final project gate: 45 suites, 2744 assertions, 0 failures.
- Coverage includes route validity, three scene themes, exact background dimensions, six hazard instances/three kinds, encounter and spawn order, Stage 6→7 persistence, hazard timing/movement, exact paired-boss atlas grid, individual health ledgers, synchronized specials, reinforcements, and full phase history.

## Web visual/performance acceptance

- Environment fixture: `?stage7_preview=1`; 120.154671832104 average FPS, 8.32260606060606 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Paired-boss fixture: `?stage7_preview=2`; 120.088064580692 average FPS, 8.32722222222223 ms average, zero frames above 20 ms or 33 ms over 300 frames.
- Browser console contained no warnings or errors.
- QA rejected the first equal-cell atlas because neighboring poses bled into cells. The deterministic builder now keeps only the largest connected figure inside each fixed source cell. QA also rejected a clipped Nyx composition and a cryogenic cue overlapping the duel; corrected spawn and hazard bounds passed the final review.

## Packaging

- The archived paired-boss generation source is excluded from Web and iOS runtime exports; only the deterministic transparent runtime sheet is shipped.
- Web release export passed; `build/web/index.pck` is 60,080,752 bytes with SHA-256 `ad36ed2e55b337cad0070bb130945626cb4f051ce1fd1df2e89e6dec8ca4cfaa`.
- iOS project-only export passed.
- Unsigned generic-device Xcode Debug build passed; executable verified as `Mach-O 64-bit executable arm64`.
- Signed install remains dependent on renewing the invalid development provisioning profile and having the paired phone available.
