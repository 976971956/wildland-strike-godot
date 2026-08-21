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

Status: **in progress**

- [x] M1-01: Introduce a fighter state enum/state machine without changing current behavior.
- [x] M1-02: Add reusable hitbox/hurtbox components and debug visualization.
- [x] M1-03: Move attacks into typed frame-data resources.
- [x] M1-04: Separate player input intent from fighter simulation.
- [x] M1-05: Replace enemy type branches with typed enemy definitions.
- [ ] M1-06: Add deterministic combat regression tests for hit, stun, invulnerability, knockback, and defeat.

Evidence (2026-08-22): player and enemy controllers share explicit fighter states, reusable hitbox/hurtbox components, and ten typed attack resources. Player simulation consumes clamped fighter-intent snapshots and no longer reads the Input singleton; keyboard, gamepad, touch-action injection, test doubles, and future AI share the same boundary. Grunt, brute, raptor, and boss health, movement, attack, grab, score, boss, and sprite-layout rules now live in typed enemy definitions; `enemy.gd` has no enemy-type behavior branches. Eight deterministic suites pass 190/190 assertions; Web release export and unsigned iOS arm64 generic-device build pass.

Exit gate: one hero and current enemies run entirely through reusable combat/data layers, with no regression in Web or iOS builds.

### M2 — Reference-quality combat vertical slice

Status: **not started**

- [ ] M2-01: Eight-direction double-tap run and turning behavior.
- [ ] M2-02: Four-hit combo and character-specific finisher windows.
- [ ] M2-03: Running, jump, and apex/dive attacks with counter-hit rules.
- [ ] M2-04: Offensive command move and attack+jump defensive special.
- [ ] M2-05: Full grab strikes, directional throws, combo throws, knockdown, and wake-up.
- [ ] M2-06: Attack priority, multi-hit, wall/throw collision, and anti-infinite rules.
- [ ] M2-07: Tune hit stop, recoil, SFX layers, camera response, and haptics using frame-data tests.

Exit gate: a graybox arena supports the complete combat grammar against three behaviorally distinct enemies at stable 60 FPS.

### M3 — Polished Stage 1 vertical slice

Status: **not started**

- [ ] Data-driven stage/scene and encounter director.
- [ ] Three distinct scenes with transitions, lock zones, breakables, drops, hazards, and stage timer.
- [ ] Basic brawler, charging heavy, ranged hunter, and neutral raptor behaviors.
- [ ] Three weapon families: melee/throwable, explosive, and firearm with ammo.
- [ ] One unique two-phase boss with dialogue and reinforcement logic.
- [ ] Final-quality original background, sprites, animation, music, SFX, HUD, and stage-clear flow.

Exit gate: Stage 1 alone is release-quality and demonstrates the final art, combat, content, test, and performance standards.

### M4 — Four heroes and local cooperation

Status: **not started**

- [ ] Character-select and four complete hero definitions/animation sets.
- [ ] Balanced, technical/item, speed/aerial, and power/grapple differentiation.
- [ ] 1–3 player local join/leave, spawn, camera, HUD, collisions, scaling, revive/continue, and team attack.
- [ ] Mobile retains a complete, tuned single-player control path.

Exit gate: all four heroes finish Stage 1 solo, and every 2–3 player combination can complete it locally.

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

1. **M1-06 — Combat regression:** lock hit, stun, invulnerability, knockback, and defeat outcomes with deterministic tests.
2. **M2-01 — Eight-direction run:** add double-tap run and turning behavior after the combat/data foundation closes.
3. **M2-02 — Four-hit combo:** expand the current three-hit chain with character-specific finisher windows.

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
- Player and enemies switch between very few frames; many combat states share art.
- Melee hit detection is distance-based and enemy AI mostly shares one chase/attack loop.
- Four enemies converging on one player can still overlap visibly even though their collision bodies no longer move as a rigid clump.
- The stage is one background repeated four times, not a true multi-scene campaign.
- No music, character selection, multiplayer, firearm/ammo system, breakables, stage timer, vehicle, continue countdown, or high-score persistence exists yet.
- The current development provisioning profile is invalid; a fresh signed iOS install requires renewed signing access and an available paired device.
