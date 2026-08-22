# Wildland Strike 1.0 — final-version plan

Last updated: 2026-08-22

Plan version: 1.0

Current release state: playable prototype

Public delivery: Godot source, GitHub Pages Web build, signed iOS development build

## Product contract

Wildland Strike 1.0 will be a complete, original-IP, clean-room reimplementation of the systems and content scale expected from a classic dinosaur arcade beat-'em-up. It will reproduce the genre-defining combat grammar, eight-stage campaign structure, four distinct heroes, three-player cooperation, neutral dinosaur behavior, broad weapon sandbox, vehicle set piece, boss variety, arcade flow, and responsive audiovisual feedback without distributing protected names, artwork, music, dialogue, logos, or ROM-derived data.

The final public game must feel mechanically complete rather than merely resemble the reference in screenshots.

### Target platforms

- Desktop and Web: keyboard plus gamepad, 1–3 local players.
- iOS/mobile Web: complete single-player touch controls, safe-area support, haptics, landscape layout.
- Rendering: 60 FPS; crisp low-resolution pixel-art presentation with nearest-neighbor scaling and stable frame pacing.

## Final-version acceptance criteria

### Campaign and stages

- Eight stages with distinct visual themes, encounter data, hazards, transitions, music, and a unique end boss.
- Multiple scenes per stage where appropriate; no repeated-background strip presented as separate levels.
- One vehicle-focused highway stage with acceleration, lane steering, collisions, hazards, and a vehicle boss encounter.
- At least one elevator/arena sequence, environmental hazard sequence, dinosaur ecology encounter, and multi-phase laboratory finale.
- Stage title/map flow, boss dialogue presentation, completion bonuses, ending, credits, continue flow, and local high-score table.

### Playable heroes

- Four original heroes covering balanced, technical/item, speed/aerial, and power/grapple roles.
- Each hero has distinct movement values, range, damage, throws, dash attack, offensive command move, defensive special, and animation set.
- Character-select screen communicates the four roles without hiding important tradeoffs.
- Up to three simultaneous local players on desktop/Web, with join/leave, per-player HUD, spawn safety, difficulty scaling, and team attack.

### Combat grammar

- Eight-direction walk and double-tap run; running can turn through adjacent directions without an unnecessary stop.
- Four-hit ground combo with intentional input windows and character-specific finisher.
- Running attack, jump attack, apex/dive attack, and offensive command move.
- Invulnerable defensive special triggered by attack+jump, consuming health only when it connects.
- Contact grab, up to three grab strikes, forward/back throws, combo-to-throw, throw collisions, knockdown, wake-up, stun, counter-hit, and invulnerability rules.
- Explicit hitboxes and hurtboxes with frame data, priority, multi-hit rules, hit stop, camera shake, recoil, launch, wall bounds, and debug rendering.
- Input buffering that remains responsive on touch, keyboard, and gamepad without automating combos.

### Enemies, dinosaurs, and bosses

- At least five standard human archetypes: basic brawler, small explosive user, knife specialist, charging heavy, and ranged hunter.
- At least four elite/sub-boss archetypes with genuinely different movement and attacks.
- At least four dinosaur archetypes including neutral/sleeping states; dinosaurs can become enraged and attack players or human enemies.
- Eight stage bosses with unique silhouettes, AI state machines, attacks, arena interactions, and balance profiles.
- Multi-phase behavior for major transformation/parasite/final bosses; palette swaps alone do not count as new bosses.
- Encounter director supports entrances, reinforcements, simultaneous limits, anti-stalling, lane selection, and multiplayer scaling.

### Weapons, pickups, and environments

- Melee, throwable, explosive, semi-automatic, spread-shot, rapid-fire, heavy firearm, ammunition, and empty-weapon behavior.
- At least twelve mechanically distinct weapons; different names or sprites on identical logic do not count.
- Weapon pickup, drop-on-hit, durability/ammo, reload pickup, empty throw/swing, charge where appropriate, and multiplayer ownership rules.
- Breakable barrels/crates/doors, rolling hazards, hidden drops, carry/throw interactions, and contextual stage objects.
- Several healing tiers and score-item tiers with readable silhouettes and documented values.

### Presentation and technical quality

- Cohesive original pixel art with transparent sprites, consistent palette/lighting, no baked sprite backgrounds or scaling halos.
- Complete animation coverage for idle, walk, run, attacks, jumps, grabs, throws, weapons, hurt, knockdown, get-up, special, victory, and defeat states.
- Original stage music, boss music, UI cues, weapon sounds, hit layers, footsteps, creature sounds, and concise original voice efforts.
- Stable save/settings data for controls, audio, language, accessibility, high scores, and unlock-neutral settings.
- Automated smoke coverage for all stages plus focused deterministic combat tests; Web and iOS exports must build without project errors.
- Sustained 60 FPS on the paired iPhone 14 Pro and a mainstream desktop browser during the heaviest supported encounter.

## Current baseline audit

| Area | Current state | Final target | Baseline estimate |
|---|---|---|---:|
| Core loop | One 4,200 px strip, four locked waves, victory/game-over | Eight complete multi-scene stages | 20% |
| Combat | Three-hit combo, jump hit, simplified grab/throw, health special | Full combat grammar above | 30% |
| Heroes | One generic hero | Four differentiated heroes | 10% |
| Enemies | Three human stat types plus one raptor | 5+ standard, 4+ elite, 4+ dinosaur archetypes | 15% |
| Bosses | One enlarged melee enemy | Eight unique bosses, several multi-phase | 3% |
| Weapons/items | One temporary blade buff and one food | 12+ weapon behaviors, ammo, breakables, item tiers | 5% |
| Vehicle | None | Complete highway vehicle stage | 0% |
| Multiplayer | None | 1–3 local players and team attack | 0% |
| Presentation | One repeated background, limited sprite sheets, synthesized tones | Eight visual themes, full animation/audio/UI flow | 10% |
| Platforms | Web and iOS pipelines, touch controls | Polished builds and performance gates | 70% |

Weighted overall baseline: approximately **20% complete / 80% remaining**.

## Architecture destination

Before scaling content, migrate the prototype toward these boundaries:

- `core/combat/`: combat clock, frame data, hitbox/hurtbox, damage result, hit stop, knockdown and status rules.
- `actors/fighters/`: shared fighter state machine plus player/AI input adapters.
- `data/`: typed resources for heroes, enemies, attacks, weapons, items, encounters, stages, and difficulty.
- `stages/`: stage controller, encounter director, camera bounds, transitions, hazards, and stage-specific set pieces.
- `presentation/`: HUD, character select, continue, dialogue, high scores, options, audio routing, and accessibility.
- `tests/`: deterministic combat tests, encounter tests, stage smoke tests, export checks.

Do not perform a disruptive all-at-once rewrite. Introduce these boundaries while delivering the milestones below, keeping the game runnable after every commit.

## Milestones

### M0 — Governance and reproducible baseline

Status: **complete**

- [x] Web build and GitHub Pages are public.
- [x] iOS export preset, signing build, and paired-device installation path exist.
- [x] Basic headless smoke test exists.
- [x] Project-specific Skill and final-version plan exist.
- [x] Add a deterministic test runner that can execute multiple focused test scenes/scripts.
- [x] Capture baseline Web/iOS performance and known defects.

Evidence (2026-08-22): the project Skill passes `quick_validate.py`; Godot 4.7.1 runs three deterministic suites with 30/30 assertions passing. The Web four-enemy baseline averages 124.70 FPS with no frames over 20 ms in a 300-frame sample. The iOS arm64 generic-device build passes without signing; current provisioning and device availability remain documented release blockers. See [`evidence/baseline/README.md`](evidence/baseline/README.md).

Exit gate: roadmap, workflow, automated baseline, and task tracking are reproducible by a fresh agent checkout.

### M1 — Combat and data foundation

Status: **complete**

- [x] M1-01: Introduce a fighter state enum/state machine without changing current behavior.
- [x] M1-02: Add reusable hitbox/hurtbox components and debug visualization.
- [x] M1-03: Move attacks into typed frame-data resources.
- [x] M1-04: Separate player input intent from fighter simulation.
- [x] M1-05: Replace enemy type branches with typed enemy definitions.
- [x] M1-06: Add deterministic combat regression tests for hit, stun, invulnerability, knockback, and defeat.

Evidence (2026-08-22): player and enemy controllers share explicit fighter states, reusable hitbox/hurtbox components, and ten typed attack resources. Player simulation consumes clamped fighter-intent snapshots and no longer reads the Input singleton; keyboard, gamepad, touch-action injection, test doubles, and future AI share the same boundary. Grunt, brute, raptor, and boss rules live in typed enemy definitions; `enemy.gd` has no enemy-type behavior branches. A dedicated combat outcome suite locks hit, hurt, stun, invulnerability, recoil, knockdown, grab/release, defeat, score, revive, and one-hit resolution. Nine deterministic suites pass 232/232 assertions; the M1 Web release export and unsigned iOS arm64 generic-device build pass.

Exit gate: one hero and current enemies run entirely through reusable combat/data layers, with no regression in Web or iOS builds.

### M2 — Reference-quality combat vertical slice

Status: **complete**

- [x] M2-01: Eight-direction double-tap run and turning behavior.
- [x] M2-02: Four-hit combo and character-specific finisher windows.
- [x] M2-03: Running, jump, and apex/dive attacks with counter-hit rules.
- [x] M2-04: Offensive command move and attack+jump defensive special.
- [x] M2-05: Full grab strikes, directional throws, combo throws, knockdown, and wake-up.
- [x] M2-06: Attack priority, multi-hit, wall/throw collision, and anti-infinite rules.
- [x] M2-07: Tune hit stop, recoil, SFX layers, camera response, and haptics using frame-data tests.

Exit gate: a graybox arena supports the complete combat grammar against three behaviorally distinct enemies at stable 60 FPS.

Evidence (2026-08-22): a reusable run controller quantizes all eight directions, recognizes same-direction double taps within 0.28 seconds, permits adjacent-direction steering, cancels on release/attack/hurt, and drops to walk speed on hard reverse while updating facing. Player RUN state and 1.65× movement are explicit. Ranger now uses a typed four-hit chain: combo three is a non-launch bridge, while a deliberate input during its 0.20–0.04 second remaining-time window buffers the heavy launching finisher; early and missed inputs do not automate the chain. The finisher has distinct frame data, weapon geometry, damage, knockback, and animation selection. Target acquisition also skips enemies still in hit invulnerability so they cannot intercept a valid follow-up. Running, rising-jump, apex, and descending-dive attacks each have independent typed timing, motion, reach, damage, launch, and counter-hit values; dive velocity is data-driven. Counter hits are restricted to unresolved attack startup, work in both directions, add attack-specific damage/knockback/stun, and interrupt the countered startup. A facing-relative down→forward+attack recognizer now drives Ranger's typed offensive command move. The invulnerable defensive special prioritizes an attack+jump chord (with a mobile A+B shortcut), suppresses accidental jump/attack leakage, and charges its health cost exactly once only after at least one valid target takes damage. Contact combo-one hits can now enter a two-second grab hold. Neutral attack delivers up to three typed grab strikes and then a combo throw; facing-relative forward/back inputs select distinct directional throws without flipping the holder. Throws interrupt enemy offense, launch into knockdown, and transition through an explicit invulnerable get-up window before neutral recovery. Hold timeout, player hurt, defensive special, and revive release the target safely. Every attack now carries a typed priority tier: higher tiers suppress lower unresolved attacks, equal tiers trade, and winning priority interrupts without incorrectly granting a counter bonus outside startup. Ranger's command move is a configured two-pulse attack whose first hit holds the target and whose final hit launches. Thrown enemies deal configured collision damage to walls or one nearby enemy. Six chained hits force a hard knockdown that rejects further hits until get-up completes, then resets cleanly. Light, medium, heavy, throw, special, and clash impacts now use reusable typed profiles for hit stop, attacker recoil, two-layer SFX, camera duration/strength, and haptic duration/intensity; headless tests observe the same resolved values without mutating global time scale. Every attack must reference a valid profile. Grunts now continuously close from offset flank lanes, brutes use a long readable charge telegraph followed by a straight burst and recovery, and raptors alternate diagonal retreats with shorter, faster depth-tracking pounces. These behaviors are parameterized by typed enemy definitions, expose deterministic phase events, cancel safely on combat interruption, and display distinct telegraph cues. Seventeen deterministic suites pass 585/585 assertions. The exported four-enemy Web benchmark averages 123.11 FPS over 300 frames with zero frames above 20 ms; its console is error-free. Web export, iOS project export, and an unsigned generic-device arm64 Xcode build all pass.

### M3 — Polished Stage 1 vertical slice

Status: **complete**

- [x] Data-driven stage/scene and encounter director.
- [x] Three distinct scenes with transitions, lock zones, breakables, drops, hazards, and stage timer.
- [x] Basic brawler, charging heavy, ranged hunter, and neutral raptor behaviors.
- [x] Three weapon families: melee, throwable explosive, and firearm with ammo.
- [x] One unique two-phase boss with dialogue and reinforcement logic.
- [x] Final-quality original background, sprites, animation, music, SFX, HUD, and stage-clear flow.

Exit gate: Stage 1 alone is release-quality and demonstrates the final art, combat, content, test, and performance standards.

Evidence (2026-08-22): Stage 1 content now loads through typed stage, scene, encounter, wave, enemy-spawn, and environment-object resources instead of a hard-coded `game.gd` wave table. The independent encounter director owns trigger progression, scene-entry transitions, arena bounds, sequential reinforcement delays, live-enemy accounting, clear signals, final stage completion, and benchmark force-starts while the game remains responsible for entities, rewards, HUD, scoring, and the stage clock. The original four encounters and fourteen enemies migrated without score or baseline-flow drift; the courtyard demonstrates a tested two-group reinforcement sequence. Ruined Avenue, Flooded Courtyard, and Processing Plant now form contiguous data-driven segments with independent 1672×941 original backgrounds, clean gameplay lanes, scene-entry cards, and environment identities; scene definitions own their texture references and validation rejects missing art. Three breakable crates accept the player's ordinary attack hitboxes, award configured score, and produce deterministic food/weapon drops. A bounded rolling drum damages and knocks down either faction with contact cooldown. A visible 240-second timer enters a tested timeout state. The roster now includes a data-driven ranged hunter that maintains a configurable firing band, visibly aims, fires the shared pistol projectile, retreats when crowded, and observes recovery/cooldown windows. Enemy faction data makes the raptor a neutral creature: nearby human enemies and raptors select each other with target hysteresis and a bounded acquisition radius, damage each other through the normal priority/hit pipeline, ignore allies, and fall back to the player when appropriate. Machete, grenade, and pistol resources provide distinct melee durability, delayed area launch, and direct-fire ammunition behavior; each family has deterministic Stage 1 placement, synthesized SFX, impact profiles, held visuals, projectiles, and a live weapon/ammo HUD. Warden Rourke replaces the placeholder boss with typed phase data: phase one uses a telegraphed ground slam, while the 50% health gate prevents lethal phase skipping, grants a one-second transition window, then shifts speed, tint, attack timing, and behavior into a rushing overdrive. Entrance and phase-change dialogue, a named phase health bar, synthesized cues, and two dynamically registered hunter reinforcements keep the director's live-enemy accounting and stage-victory gate correct. A deterministic 16-bit procedural score now supplies distinct 126 BPM stage, 148 BPM looping boss, and 132 BPM non-looping victory cues; the game switches cues at the title, stage-start, boss, timeout, game-over, and victory boundaries without duplicate restarts. Victory advances through clear, bonus-tally, and complete phases, awards time, remaining-life, and fixed clear bonuses exactly once, plays tally feedback, and withholds restart until the final score is presented. Ranger now uses a transparent original 6×4 sheet with distinct breathing, four-frame locomotion, combo, rush, special, air, grab, hurt, defeated, weapon, and two-stage victory poses. A separate 20 Hz ambience layer adds scene-specific fire/smoke, rain/ripples, and steam/alert motion without redrawing the large background textures. Grunt/hunter, brute, raptor, and boss now use clean-room eight-state single-row sheets with deterministic idle, locomotion, attack, hurt, and defeat selection; the large archetypes were isolated into independent atlases and every pose was normalized into a true 320×320 cell to eliminate neighboring-limb bleed. A no-damage Web roster fixture keeps the intended human-versus-neutral-creature targeting rules from contaminating visual QA. The final audio pass centralizes more than two dozen deterministic SFX profiles, gives every attack and weapon family an event, protects high-priority impacts with an eight-voice pool, and ducks the music under heavy hits, boss cues, and settlement feedback. The HUD now exposes area, hostile count, arena-lock/route state, urgent timer and low-health warnings, plus a mobile-safe dialogue layout that avoids the virtual controls. Stable formation slots, proportional depth correction, soft separation, and a 56 px visible-overlap floor close the attached-enemy movement defect. The deterministic end-to-end fixture completes all four encounters, three scenes, both boss phases, dynamic reinforcements, rewards, and settlement in sequence at 7500 combat/16900 final score. Twenty-seven deterministic suites pass 1110/1110 assertions. The final four-enemy Web benchmark averages 120.01 FPS over 300 frames and the five-archetype visual roster averages 119.96 FPS, both with zero frames above 20 ms or 33 ms. Web formation acceptance passes at a 56.84 px minimum center distance. All three scenes, both boss phases, dialogue/reinforcement composition, settlement phases, Ranger alpha edges, enemy state sheets, motion layers, final HUD variants, and Web end-to-end acceptance were verified in the exported build. Web export, iOS project export, and unsigned generic-device arm64 Xcode build pass. Detailed exit evidence is archived in `evidence/m3-stage1-acceptance.md`.

### M4 — Four heroes and local cooperation

Status: **in progress**

- [x] Character-select and four complete typed hero definitions.
- [x] Complete original animation sets for all four heroes.
- [x] Balanced, technical/item, speed/aerial, and power/grapple differentiation.
- [x] 1–3 player local join/leave, per-device input routing, spawn safety, and shared-camera framing.
- [x] Per-player hero selection, ready-state gating, and compact local co-op HUD.
- [ ] Collision ownership, player-count scaling, revive/continue, and team attack.
- [ ] Mobile retains a complete, tuned single-player control path.

Exit gate: all four heroes finish Stage 1 solo, and every 2–3 player combination can complete it locally.

Evidence (2026-08-22, first batch): four validated `HeroDefinition` resources now establish Ranger, Mara, Kestrel, and Atlas as distinct balanced, item/technical, speed/aerial, and power/grapple roles. Their health, walk/run speed, damage, healing efficiency, weapon capacity, aerial control, and grapple scaling are applied by the shared player runtime while Ranger's established baseline remains unchanged. Title start now enters a four-card character-select flow with wraparound keyboard/controller navigation, direct touch-card selection, confirmation, dynamic identity/health HUD binding, and a query-gated exported-Web preview. The clean 1,280×720 selection screen was verified without stale HUD bleed or browser console errors and averaged 120.00 FPS across 300 sampled frames with no frame above 20 ms. Twenty-eight deterministic suites pass 1156/1156 assertions covering roster uniqueness, role tradeoffs, selection/wrap/confirm flow, data application, damage/grapple scaling, touch routing, and Web fixture availability. Web export, iOS project export, and an unsigned generic-device arm64 Xcode build pass. At that checkpoint the non-Ranger heroes temporarily shared Ranger's combat sheet; the following animation batch replaces that temporary state.

Evidence (2026-08-22, animation batch): Mara, Kestrel, and Atlas now each own an original 1,536×1,024 RGBA 6×4 action sheet with the same 24-state production contract as Ranger: idle, four-frame movement, full grounded chain, rush, defensive special, air/dive, grab, hurt/knockdown, defeat/get-up, melee/firearm, and two victory poses. Their technician, aerial-scout, and heavyweight silhouettes, palettes, equipment, motion arcs, and proportions remain consistent across every frame while differing visibly from Ranger and each other. Typed hero resources own their texture/grid metadata; selection cards and the shared player renderer now consume the selected sheet directly with nearest-neighbor sampling. A reproducible exported-Web action-grid fixture exposed atlas-sampling lines and generated neighboring-pose fragments that ordinary alpha tests missed. The retained normalization tool thresholds weak alpha, removes small connected artifacts, and preserves only independent effects within an eight-pixel expansion of the actual main-character silhouette; repeated browser review confirmed all 72 new cells are cleanly isolated without cropped limbs or cross-cell debris. The final character-select screen displays the four real idle sprites. Twenty-nine deterministic suites pass 1380/1380 assertions, including dimensions, alpha, per-cell opaque silhouettes, transparent gutters, runtime texture routing, and fixture availability. Exported animation and selection previews both average about 120 FPS across 300 frames with no frame above 20 ms and no browser console errors. Web export, iOS project export, and an unsigned generic-device arm64 Xcode build pass. Full prompts, hashes, and clean-room provenance are recorded in `ASSET_PROVENANCE.md`.

Evidence (2026-08-22, local-player architecture batch): a deterministic three-slot registry now owns stable player/device/hero assignments for keyboard plus two gamepads, rejects duplicate devices and a fourth player, reuses vacated slots, and disconnects secondary players when their controller leaves. Each fighter receives a device-scoped intent source: desktop keyboard sampling is physically isolated from gamepad actions, controller axes/D-pad/buttons are sampled by device with non-repeating edges, and the virtual-action path remains available for the mobile single-player controls. Runtime Start joins and Back leaves secondary controllers; the primary keyboard slot remains stable. Spawn candidates enforce a 70-pixel safety radius, active-player APIs preserve the legacy `player` alias, the encounter director follows the lead fighter, and a bounded shared camera widens to 0.72× when the team spreads. Enemies, hostile projectiles, pickups, and rolling hazards now resolve against all active local players rather than player one only. A query-gated exported-Web fixture displays three distinct heroes together; it was visually inspected with clean browser logs and averaged 120.01 FPS across 300 frames with no frame above 20 ms. Thirty deterministic suites pass 1417/1417 assertions covering registry limits/reuse, input isolation and mobile routing, runtime join/leave, distinct heroes/devices, safe spawn, shared camera, lead progression, nearest-player enemy targeting, and non-primary pickup collection. Web export, iOS project export, and an unsigned generic-device arm64 Xcode build pass.

Evidence (2026-08-22, co-op selection/HUD batch): every joined slot now owns an independent hero cursor and ready flag. Keyboard, D-pad, analog stick, A/Start confirmation, and Back cancellation are routed to the correct slot; changing a hero invalidates only that player's ready state, and Stage 1 cannot start until every joined player confirms. The selection cards display color-coded P1–P3 `READY`/`SELECTING` badges, while gameplay switches to three non-overlapping compact health/life/weapon panels without covering the timer or stage objective. Legacy single-player APIs and the mobile selection path remain intact. Reproducible exported-Web fixtures verify both the selection and gameplay layouts; browser inspection found zero warnings/errors, and the three-player selection fixture averaged 119.58 FPS across 300 frames with no frame above 20 ms. Thirty deterministic suites pass 1430/1430 assertions. Web export, iOS project export, and an unsigned generic-device arm64 Xcode build pass; the executable is Mach-O arm64.

### M5 — Weapon sandbox and dinosaur ecology

Status: **not started**

- [ ] At least twelve distinct weapon behaviors plus ammo/durability/drop rules.
- [ ] Breakables, carry/throw props, rolling hazards, food tiers, and score tiers.
- [ ] Four dinosaur archetypes with neutral, sleeping, enraged, and cross-faction targeting states.
- [ ] Full enemy standard/elite roster and reusable encounter recipes.

Exit gate: weapons and dinosaurs create systemic interactions rather than scripted visual cameos.

### M6 — Stages 2–4 and vehicle set piece

Status: **not started**

- [ ] Flooded wilderness stage and boss.
- [ ] Highway vehicle stage with complete driving and vehicle-boss mechanics.
- [ ] Garage/industrial multi-scene stage and boss.
- [ ] Stage map flow, persistent score/lives, completion bonuses, and difficulty progression.

Exit gate: first half of the campaign is content-complete and playable by all supported player counts.

### M7 — Stages 5–8 and finale

Status: **not started**

- [ ] Burning settlement stage and transformation boss.
- [ ] Jungle/mine stage with large-creature hazard and multi-phase boss.
- [ ] Underground vault/elevator stage with paired boss encounter.
- [ ] Laboratory finale with elite gauntlet, multi-phase final boss, ending, and credits.

Exit gate: the complete eight-stage campaign can be finished from a fresh start without debug intervention.

### M8 — Arcade shell, mobile polish, and accessibility

Status: **not started**

- [ ] Attract/title flow, character select polish, continue countdown, local high scores, options, pause, and save settings.
- [ ] Original full soundtrack, audio mixing, voice efforts, subtitles, and language-ready UI.
- [ ] Touch remapping/sizing, safe areas, haptics controls, pause/resume safety, and mobile performance tuning.
- [ ] Rebindable controls, screen shake/hit-flash controls, readable UI scale, and color-independent telegraphs.

Exit gate: desktop, Web, and iOS behave like complete consumer builds rather than development demos.

### M9 — Balance, QA, and 1.0 release

Status: **not started**

- [ ] Full solo and 2–3 player balance passes with documented difficulty curves.
- [ ] All-stage automated smoke suite and focused combat/encounter regression suite.
- [ ] Browser/device compatibility, reconnect, suspend/resume, save migration, and performance tests.
- [ ] Asset provenance audit, license audit, release notes, clean checkout build, Pages deployment, and signed iOS run.
- [ ] No critical/high defects; accepted medium defects documented with owner and target.

Exit gate: tag `v1.0.0`, publish the verified Web build, and archive reproducible build evidence.

## Next task queue

Tasks are ordered. Take the first unblocked item unless the user explicitly prioritizes another milestone-compatible task.

1. **M4 — Co-op combat loop:** add explicit collision ownership and player-count scaling, then implement revive/continue and team attack before closing the M4 exit gate.

## Definition of done for every task

- Acceptance criteria are implemented without unrelated scope expansion.
- A regression test or reproducible verification covers the behavior.
- Existing required tests pass.
- Player-visible Web changes are exported into `docs/` and GitHub Pages builds successfully.
- iOS-impacting changes compile; install/launch is verified when the paired phone is available.
- `PROJECT_PLAN.md` status/evidence/next task is updated in the same commit.
- No secrets, profiles, DerivedData, build frameworks, or unlicensed reference assets enter Git.
- The change is committed and pushed to `origin/main`; the final report includes commit and verification evidence.

## Decision log

- **2026-08-22 — Public clean-room scope:** pursue mechanical and content-scale parity with original IP, art, music, dialogue, branding, and stage names. This preserves the goal of a complete arcade experience while keeping the public repository distributable.
- **2026-08-22 — Vertical-slice strategy:** finish reusable combat architecture and one release-quality stage before producing the remaining seven stages.
- **2026-08-22 — Platform hierarchy:** desktop/Web 1–3 player local co-op is the multiplayer reference; mobile guarantees polished single-player rather than forcing an unusable three-player touch layout.
- **2026-08-22 — Continuous delivery:** every completed mutation is tested, documented, committed, pushed to `main`, and redeployed when Web-visible.
- **2026-08-22 — Reproducible Web performance probe:** a query-gated four-enemy scenario prints one local console summary after fixed warm-up/sample counts, giving future milestones a comparable render baseline without changing ordinary gameplay.

## Known baseline limitations

- The current 1,280×720 assets use a high-resolution pseudo-pixel style rather than a controlled low-resolution pixel pipeline.
- Ranger has 24 state/weapon frames; every Stage 1 enemy archetype has eight state-driven frames, while full multi-frame attack chains, extra locomotion in-betweens, and authored directional variants remain campaign-polish work.
- The enemy roster still lacks explosive specialists, knife specialists, elites, additional dinosaur archetypes, and the remaining seven unique campaign boss state machines.
- Stage 1 is the completed release-quality reference slice for later campaign production; subsequent milestones must preserve its combat, presentation, Web performance, and acceptance standards while expanding heroes, systems, and stages.
- Character selection, typed role tuning, and complete original 24-state sheets exist for all four heroes. Their timing contract remains shared until later role-balance passes. Three-slot local device routing, runtime join/leave, safe spawning, active-player targeting, shared-camera framing, independent selection/ready states, and compact player HUDs exist; explicit co-op collision ownership/scaling, teammate revive/continue, and team attack remain the next M4 batch. Vehicle, continue countdown, and high-score persistence do not exist yet; the procedural Stage 1 score and three-family weapon set are foundations for the final soundtrack and weapon sandbox rather than complete campaign coverage.
- The current development provisioning profile is invalid; a fresh signed iOS install requires renewed signing access and an available paired device.
