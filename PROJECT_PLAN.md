# Wildland Strike 1.0 — final-version plan

Last updated: 2026-08-22

Plan version: 1.0

Current release state: v1.0.0 released; post-release maintenance active

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

Status: **complete**

- [x] Character-select and four complete typed hero definitions.
- [x] Complete original animation sets for all four heroes.
- [x] Balanced, technical/item, speed/aerial, and power/grapple differentiation.
- [x] 1–3 player local join/leave, per-device input routing, spawn safety, and shared-camera framing.
- [x] Per-player hero selection, ready-state gating, and compact local co-op HUD.
- [x] Explicit combat ownership/faction filtering and player-count enemy scaling.
- [x] Teammate revive window, per-player continues, safe respawn, and all-team game-over gating.
- [x] Team attack.
- [x] Mobile retains a complete, tuned single-player control path.

Exit gate: all four heroes finish Stage 1 solo, and every 2–3 player combination can complete it locally.

Evidence (2026-08-22, first batch): four validated `HeroDefinition` resources now establish Ranger, Mara, Kestrel, and Atlas as distinct balanced, item/technical, speed/aerial, and power/grapple roles. Their health, walk/run speed, damage, healing efficiency, weapon capacity, aerial control, and grapple scaling are applied by the shared player runtime while Ranger's established baseline remains unchanged. Title start now enters a four-card character-select flow with wraparound keyboard/controller navigation, direct touch-card selection, confirmation, dynamic identity/health HUD binding, and a query-gated exported-Web preview. The clean 1,280×720 selection screen was verified without stale HUD bleed or browser console errors and averaged 120.00 FPS across 300 sampled frames with no frame above 20 ms. Twenty-eight deterministic suites pass 1156/1156 assertions covering roster uniqueness, role tradeoffs, selection/wrap/confirm flow, data application, damage/grapple scaling, touch routing, and Web fixture availability. Web export, iOS project export, and an unsigned generic-device arm64 Xcode build pass. At that checkpoint the non-Ranger heroes temporarily shared Ranger's combat sheet; the following animation batch replaces that temporary state.

Evidence (2026-08-22, animation batch): Mara, Kestrel, and Atlas now each own an original 1,536×1,024 RGBA 6×4 action sheet with the same 24-state production contract as Ranger: idle, four-frame movement, full grounded chain, rush, defensive special, air/dive, grab, hurt/knockdown, defeat/get-up, melee/firearm, and two victory poses. Their technician, aerial-scout, and heavyweight silhouettes, palettes, equipment, motion arcs, and proportions remain consistent across every frame while differing visibly from Ranger and each other. Typed hero resources own their texture/grid metadata; selection cards and the shared player renderer now consume the selected sheet directly with nearest-neighbor sampling. A reproducible exported-Web action-grid fixture exposed atlas-sampling lines and generated neighboring-pose fragments that ordinary alpha tests missed. The retained normalization tool thresholds weak alpha, removes small connected artifacts, and preserves only independent effects within an eight-pixel expansion of the actual main-character silhouette; repeated browser review confirmed all 72 new cells are cleanly isolated without cropped limbs or cross-cell debris. The final character-select screen displays the four real idle sprites. Twenty-nine deterministic suites pass 1380/1380 assertions, including dimensions, alpha, per-cell opaque silhouettes, transparent gutters, runtime texture routing, and fixture availability. Exported animation and selection previews both average about 120 FPS across 300 frames with no frame above 20 ms and no browser console errors. Web export, iOS project export, and an unsigned generic-device arm64 Xcode build pass. Full prompts, hashes, and clean-room provenance are recorded in `ASSET_PROVENANCE.md`.

Evidence (2026-08-22, local-player architecture batch): a deterministic three-slot registry now owns stable player/device/hero assignments for keyboard plus two gamepads, rejects duplicate devices and a fourth player, reuses vacated slots, and disconnects secondary players when their controller leaves. Each fighter receives a device-scoped intent source: desktop keyboard sampling is physically isolated from gamepad actions, controller axes/D-pad/buttons are sampled by device with non-repeating edges, and the virtual-action path remains available for the mobile single-player controls. Runtime Start joins and Back leaves secondary controllers; the primary keyboard slot remains stable. Spawn candidates enforce a 70-pixel safety radius, active-player APIs preserve the legacy `player` alias, the encounter director follows the lead fighter, and a bounded shared camera widens to 0.72× when the team spreads. Enemies, hostile projectiles, pickups, and rolling hazards now resolve against all active local players rather than player one only. A query-gated exported-Web fixture displays three distinct heroes together; it was visually inspected with clean browser logs and averaged 120.01 FPS across 300 frames with no frame above 20 ms. Thirty deterministic suites pass 1417/1417 assertions covering registry limits/reuse, input isolation and mobile routing, runtime join/leave, distinct heroes/devices, safe spawn, shared camera, lead progression, nearest-player enemy targeting, and non-primary pickup collection. Web export, iOS project export, and an unsigned generic-device arm64 Xcode build pass.

Evidence (2026-08-22, co-op selection/HUD batch): every joined slot now owns an independent hero cursor and ready flag. Keyboard, D-pad, analog stick, A/Start confirmation, and Back cancellation are routed to the correct slot; changing a hero invalidates only that player's ready state, and Stage 1 cannot start until every joined player confirms. The selection cards display color-coded P1–P3 `READY`/`SELECTING` badges, while gameplay switches to three non-overlapping compact health/life/weapon panels without covering the timer or stage objective. Legacy single-player APIs and the mobile selection path remain intact. Reproducible exported-Web fixtures verify both the selection and gameplay layouts; browser inspection found zero warnings/errors, and the three-player selection fixture averaged 119.58 FPS across 300 frames with no frame above 20 ms. Thirty deterministic suites pass 1430/1430 assertions. Web export, iOS project export, and an unsigned generic-device arm64 Xcode build pass; the executable is Mach-O arm64.

Evidence (2026-08-22, co-op ownership/scaling batch): players, human enemies, neutral creatures, hitboxes, hurtboxes, and weapon projectiles now carry explicit combat-team and source-owner identities. Same-team hitboxes and projectiles reject damage at the shared combat boundary, each local player retains a unique stable owner ID, and human-versus-neutral-creature ecology remains valid. Enemy health/damage tuning is 1.0×/1.0× for solo, 1.4×/1.08× for two players, and 1.7×/1.16× for three players. Each enemy snapshots the joined-player scaling when it spawns, and enemy projectiles inherit that snapshot, so mid-wave joins/leaves never rewrite an existing combatant's health or damage budget. Thirty-one deterministic suites pass 1459/1459 assertions, including real scaled enemy-to-player damage, friendly-fire rejection, cross-faction eligibility, stable mid-wave snapshots, and projectile ownership. The exported three-player Web fixture retested at 120.01 FPS across 300 frames with no frame above 20 ms and zero browser warnings/errors. Web export, iOS project export, and unsigned arm64 Xcode build pass.

Evidence (2026-08-22, revive/continue batch): a defeated co-op fighter now enters an eight-second down window without immediately spending a life. Any active teammate can move within 96 pixels and press attack to revive them at 35% health with temporary invulnerability; the rescue input is consumed instead of leaking into an attack. Expiry consumes only that slot's continue, then respawns it after 1.1 seconds at a safe candidate near the surviving team. Simultaneous knockdowns preserve a pending continue instead of deadlocking, eliminated teammates no longer end the run while another player survives, and game over occurs only after every player is down with no rescue window or continue remaining. Solo retains the original three-attempt timing. Compact HUD panels expose `DOWN` countdowns and `OUT` state, with banners and a dedicated revive cue. A reproducible Web fixture visually verifies the fallen pose, timer, and interaction prompt; it averaged 120.01 FPS across 300 frames with no frame above 20 ms and zero browser warnings/errors. Thirty-two deterministic suites pass 1485/1485 assertions. Web export, iOS project export, and unsigned arm64 Xcode build pass.

Evidence (2026-08-22, team-attack batch): any two active nearby teammates can press special within a 0.24-second link window and a 190-pixel radius to trigger one typed radial team attack. Its damage uses the participants' average hero damage scale, hits each eligible hostile at most once, grants both participants the configured invulnerability, and charges the configured health cost exactly once per participant only after a valid target is damaged. Friendly fire remains impossible. Unmatched and out-of-range requests fall back to each fighter's ordinary special instead of swallowing input, while hurt, down, leave, and timeout paths clear stale requests safely. Distinct linked rings, launch/impact behavior, synthesized audio, and a team banner make the result readable. Thirty-three deterministic suites pass 1515/1515 assertions. The exported Web fixture was visually inspected at 120.04 FPS over 300 frames with no frame above 20 ms and zero browser warnings/errors. Web export, iOS project export, and the unsigned Mach-O arm64 Xcode build pass.

Exit evidence (2026-08-22): the deterministic M4 matrix completes Stage 1 with all four solo heroes, all six unique two-player hero pairs, and all four unique three-player hero trios. Every one of the fourteen runs retains its selected roster and player count, clears all four encounters, passes both boss phases and dynamic reinforcements, reaches victory at 7,500 combat score, and completes settlement at 16,900 final score. The same gate routes real touch events through title start, direct hero selection/confirmation, eight-way movement, attack, jump, special, release, and focus-loss cleanup. Thirty-four suites pass 1740/1740 assertions. The exported mobile HUD/dialogue/control layout was visually accepted with zero browser warnings/errors and averaged 120.00 FPS over 300 frames with no frame above 20 ms or 33 ms. M4 Web export, Pages deployment, and unsigned iOS arm64 build pass. Detailed matrix evidence is archived in `evidence/m4-coop-acceptance.md`.

### M5 — Weapon sandbox and dinosaur ecology

Status: **complete**

- [x] At least twelve distinct weapon behaviors plus ammo/durability/drop rules.
- [x] Breakables, carry/throw props, rolling hazards, food tiers, and score tiers.
- [x] Four dinosaur archetypes with neutral, sleeping, enraged, and cross-faction targeting states.
- [x] Full enemy standard/elite roster and reusable encounter recipes.

Exit gate: weapons and dinosaurs create systemic interactions rather than scripted visual cameos.

Evidence (2026-08-22, weapon-sandbox batch): a typed catalog now owns twelve unique weapon resources and explicit pickup/drop IDs, split evenly across melee, firearms, and explosives. Machete is the durable baseline; steel pipe trades durability for heavy forced launch; field whip scales the real hitbox for reach; shock baton adds stun and one-target chaining. Pistol remains the direct sidearm; shotgun fans five projectiles across depth lanes; burst SMG emits three rounds per ammo unit; rifle penetrates three unique actors or breakables. Grenade retains its timed blast; Molotov creates a later ticking fire field; rocket detonates on contact; proximity mine remains stationary, arms after a delay, and scans an opposing-faction trigger radius. Ammo/durability is capacity- and hero-efficiency-driven, decrements once per use, and safely preserves the final-use resource through hit resolution. Projectiles, explosions, lingering fields, and mines all reuse explicit combat ownership so co-op friendly fire remains impossible while human-versus-neutral ecology stays valid. Each behavior has a distinct held/drop silhouette and mixed use cue. Thirty-five suites pass 1867/1867 assertions. The exported twelve-item Web fixture was visually accepted at 120.00 FPS over 300 frames with no frame above 20 ms or 33 ms and zero browser warnings/errors. Web export, iOS project export, and unsigned Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m5-weapon-sandbox.md`.

Evidence (2026-08-22, prop/item batch): Stage 1 now authors a tire, fuel canister, and industrial scrap bundle as independent carryable resources alongside its three breakable crates and bounded rolling drum. A nearby neutral attack lifts a prop out of the targetable world, keeps it visually attached above its carrier, and the next attack throws it along the gameplay floor plane. Each prop owns damage, travel speed/lifetime, break-on-contact behavior, durability, score, color, and a typed drop; thrown hits launch enemies and damage other breakables while explicit co-op ownership keeps teammates safe. Hurt, special, linked attack, revive, and player departure all drop a held object safely. A typed pickup catalog replaces the generic food path with four rising healing/score tiers and adds four pure-score treasure tiers; healing retains per-hero item efficiency and the health cap. Thirty-six suites pass 1946/1946 assertions. The exported Web fixture was visually accepted at 119.99 FPS over 300 frames with no frame above 20 ms or 33 ms. Web export, iOS project export, and unsigned Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m5-prop-item-system.md`.

Evidence (2026-08-22, dinosaur-ecosystem batch): Compy, raptor, ankylosaur, and triceratops now form four typed neutral-creature archetypes with flanker, pouncer, pressure, and charger behavior families. Every creature participates in the existing faction-safe target pipeline, prefers a nearer human enemy over the player, and never targets another neutral dinosaur. Ankylosaur and triceratops can begin asleep: their AI remains motionless until a player or human enemy enters a resource-owned wake radius, while taking damage also wakes them. A resource-owned health threshold promotes any dinosaur into an explicit enraged state with observable audio/visual feedback and independent speed/damage multipliers that apply against players and enemy factions. The three new species use original 2560×320 transparent eight-state strips; a retained deterministic connected-component tool reconstructs those runtime sheets from the archived clean-room source without cross-cell bleed. Thirty-seven suites pass 2034/2034 assertions. The exported four-species Web fixture was visually accepted at 119.99 FPS over 300 frames with no frame above 20 ms or 33 ms. Web release export, iOS project export, and the unsigned Mach-O arm64 Xcode build pass. Detailed evidence is archived in `evidence/m5-dinosaur-ecosystem.md`.

Exit evidence (2026-08-22, standard/elite roster batch): the human catalog now contains six standard roles—grunt, brute, hunter, knife raider, demolitionist, and shield guard—and four explicit elites: enforcer, blade, bombardier, and bulwark. Knife units use a data-driven feint/lunge/diagonal-disengage behavior; demolition units throw the shared delayed explosive through the faction-safe projectile pipeline; shield units reduce only frontal damage, absorb launch, break under an authored damage budget, and recover on a resource-owned timer. Every elite has an independent behavior family plus outgoing power, reduced stun duration, consumable knockdown armor, gold rank cues, and a unique original eight-state sheet. Four validated encounter recipes deterministically expand standard/elite pools, formation offsets, seeds, and difficulty tiers into ordinary wave spawns consumed by the encounter director. Thirty-eight suites pass 2260/2260 assertions. The unobstructed ten-character exported-Web fixture was visually accepted at 119.997 FPS over 300 frames with zero frames above 20 ms or 33 ms and no browser warnings/errors. Detailed evidence is archived in `evidence/m5-enemy-roster.md`.

### M6 — Stages 2–4 and vehicle set piece

Status: **complete**

- [x] Flooded wilderness stage and boss.
- [x] Highway vehicle stage with complete driving and vehicle-boss mechanics.
- [x] Garage/industrial multi-scene stage and boss.
- [x] Stage map flow, persistent score/lives, completion bonuses, and difficulty progression.

Evidence (2026-08-22, flooded-wilderness batch): Stage 2 is a complete 4,200 px data-driven route through Cypress Floodplain, Drowned Research Camp, and Ancient Spillway, each with independent original 1672×941 scene art and monsoon/mist/lighting ambience. Four ordered encounters combine the complete M5 human roster with neutral Compy, raptor, ankylosaur, and triceratops ecology across fourteen authored initial/reinforcement spawns. Three typed water-current hazards push and periodically damage either faction, allowing the environment to change real combat outcomes. Mirewarden Sable is an original 330-health three-phase boss with an isolated 2560×320 eight-state atlas: Floodgate launches a traveling tidal-wave hit volume, Harpoon Rush switches to a burst state and adds a raptor, and Deluge accelerates tidal pressure while adding two Compys; all phase gates, dialogue, HUD identity, dynamic director accounting, recovery, and completion behavior are resource-driven. The campaign now transitions from Stage 1 to Stage 2 in place while preserving score, lives, selected heroes, and all three local-player slots, reconfiguring the director, art, hazards, timer, and camera bounds. Thirty-nine deterministic suites pass 2329/2329 assertions. Exported environment and boss fixtures average 120.04 and 120.00 FPS over 300 frames with zero frames above 20 ms or 33 ms. Web release export, iOS project export, and unsigned generic-device Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m6-flooded-wilderness.md`.

Evidence (2026-08-22, highway-vehicle batch): Stage 3 is a complete 4,200 px route through Red Mesa Highway, Convoy Checkpoint, and Tempest Overpass, with five ordered encounters, seventeen authored spawns, six destructible road hazards, three scene-specific ambience themes, and independent original 1672×941 backgrounds. A typed `VehicleStageData` resource owns minimum/maximum speed, acceleration, braking, passive drag, three ordered lanes, steering rate, hull health, collision and ram damage/cooldowns, mounted weapon, and per-player firing cooldown. The shared runtime mounts all active local players, suppresses incompatible on-foot physics/standing sprites, drives director/camera progression, supports independent P1–P3 mounted fire, applies hull breakdown consequences, and restores players safely when leaving the sequence. Iron Vulture is an original 390-health armored-truck boss with an isolated 2560×320 eight-state atlas: Pursuit uses a telegraphed lane ram, Minefield deploys armed road mines and an elite bombardier, and Redline accelerates repeated rams with an elite enforcer. The first exported visual was rejected because the procedural player car looked toy-like and exposed a standing fighter through its roof; it was replaced by an original four-state 1440×240 Desert Interceptor atlas and the oversized circular boss cue was replaced with road-aligned chevrons. Forty suites pass 2413/2413 assertions. Accepted exported-Web fixtures average 119.60 FPS for the canyon route and 120.00 FPS for the boss over 300 frames, with zero frames above 20 ms or 33 ms and zero browser warnings/errors. Web release export, iOS project export, and unsigned generic-device Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m6-highway-vehicle.md`.

Evidence (2026-08-22, industrial-foundry batch): Stage 4 is a complete 4,200 px route through Armored Motor Pool, Armored Assembly Line, and Crucible Lift, with five ordered encounters, seventeen authored spawns, a carryable engine block, breakable supply crate, continuous conveyor, two independently offset piston presses, two independently offset furnace vents, three industrial ambience themes, and independent original 1672×941 backgrounds. `IndustrialHazardData` owns hazard kind, bounds, timing, warning/active windows, phase offset, damage, knockback, push speed, and color cues; the shared runtime applies them faction-neutrally without enemy stacking or scene-specific ID branches. Forge Regent Volkr is an original 430-health exosuit boss with an isolated 2560×320 eight-state atlas: Smelter sends two opposing furnace waves, Polarity magnetically pulls and damages players while adding shield guards, and Overdrive accelerates furnace pressure with an elite bulwark. Two exported visual passes were rejected and corrected: abstract floating press outlines gained connected steel shafts, filled housings, bolts, grates, and floor warning stripes; the oversized inherited boss circle became readable cable/coil and floor-flame cues. Forty-one suites pass 2485/2485 assertions. Accepted environment and boss fixtures sustain approximately 120 FPS over 300 frames with zero frames above 20 ms or 33 ms and zero browser warnings/errors. Web release export, iOS project export, and unsigned generic-device Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m6-industrial-foundry.md`.

Exit evidence (2026-08-22, first-half campaign batch): character confirmation now opens a four-node campaign route before deployment, and every completed stage returns through the route instead of jumping directly into the next scene. Each typed stage definition owns map position, route subtitle, clear copy, enemy health/damage multipliers, time/life conversion, and clear bonus. Threat rises monotonically from 1.00×/1.00× in Stage 1 to 1.25×/1.12× in Stage 4, while clear awards rise from 5,000 to 10,000; score, primary and per-player continues, heroes, and joined slots remain intact. Stage victory copy is no longer hard-coded to Stage 1, and the fourth clear awards one 20,000-point first-front bonus before a final report. Full-order testing exposed a shared-array alias in `EncounterDirector`: reconfiguration cleared previously completed cached StageDefinition scene arrays. Director, world-art, and ambience consumers now duplicate those arrays and a permanent regression proves all four resources remain valid after the route. Forty-two suites pass 2539/2539 assertions. Accepted route and report Web fixtures average 119.9968 and 120.00 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings/errors. Web release export, iOS project export, and unsigned generic-device Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m6-first-half-campaign.md`.

Exit gate: first half of the campaign is content-complete and playable by all supported player counts.

### M7 — Stages 5–8 and finale

Status: **complete**

- [x] Burning settlement stage and transformation boss.
- [x] Jungle/mine stage with large-creature hazard and multi-phase boss.
- [x] Underground vault/elevator stage with paired boss encounter.
- [x] Laboratory finale with elite gauntlet, multi-phase final boss, ending, and credits.

Evidence (2026-08-22, burning-settlement batch): Stage 5 adds a complete 4,200 px route through Ember Refuge, Burning Market, and Ashen Cistern, with five ordered encounters, fifteen authored spawns, independent original 1672×941 backgrounds, three firestorm ambience themes, and a fifth campaign-map node. A new typed `DisasterHazardData` system provides two cyclic fire patches, a damaging movement-slowing smoke cloud, and two directional cistern jets with explicit warning/active windows and independent phase offsets. Cinder Matriarch Veyra uses an original 2560×640 two-form atlas: her human fire-marshal phase launches opposing ember waves, the 58% gate switches to a genuinely different ash-beast row and rush behavior with two reinforcements, and the 24% rupture phase launches opposing water-pressure waves with a final reinforcement. Phase-owned sprite-row overrides, validation, animation columns, dialogue, telegraphs, and director accounting are data-driven. Exported QA rejected and corrected a scene-boundary framing issue, reinforcement occlusion, and an inherited oversized boss circle before acceptance. Forty-three deterministic suites pass 2606/2606 assertions. Accepted environment and boss Web fixtures average 120.00 and 120.08 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings/errors. Web release export, iOS project export, and unsigned generic-device Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m7-burning-settlement.md`.

Evidence (2026-08-22, jungle-mine batch): Stage 6 adds a complete 4,200 px route through Jungle Research Trail, Jungle Mine Entrance, and Titan Shaft, with five ordered encounters, seventeen authored spawns, three original 1672×941 backgrounds, three rain/mine/cavern ambience themes, and a sixth campaign-map node. A typed `JungleHazardData` system provides three movement-slowing damaging spore blooms, one cyclic traveling ore cart with a generated transparent runtime sprite, and two giant-creature stomp zones with readable footprint warnings. Titan Warden Korva uses an original isolated 2560×320 eight-state atlas and three resource-owned phases: Seismic Survey sends three sequential floor fractures; Titan Protocol fractures both sides and summons a triceratops; Deep Core converts to a high-speed drill charge with an elite reinforcement. Hazard timing, faction-safe damage, movement, phase thresholds, specials, dialogue, reinforcements, director accounting, and campaign transition are data-driven. Exported QA rejected two procedural mine-cart presentations and accepted the generated pixel-art cart after deterministic alpha cleanup; environment and phase-two boss fixtures average 120.00 and 120.006 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings/errors. Forty-four deterministic suites pass 2672/2672 assertions. Web release export, iOS project export, and unsigned generic-device Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m7-jungle-mine.md`.

Evidence (2026-08-22, underground-vault batch): Stage 7 adds a complete 4,200 px descent through Vault Elevator Descent, Cryogenic Vault Hall, and Twin Core Vault, with five ordered encounters, eighteen authored spawns, three independent original 1672×941 backgrounds, three elevator/cryo/core ambience themes, and a seventh campaign-map node. Typed `VaultHazardData` drives two moving-deck shifts, two security lasers, and two cryogenic vents with independent warning, active, movement, and phase-offset data. Vault Sentinels Orin and Nyx are a simultaneous paired boss encounter using an original isolated 2560×640 sixteen-state atlas, two individual health pools aggregated into one HUD ledger, and synchronized faction-safe barrier/crossfire attacks without duplicate completion. Visual QA rejected component bleed, a clipped Nyx composition, and hazard occlusion before accepting the deterministic atlas and corrected arena. Forty-five deterministic suites pass 2744/2744 assertions. Accepted environment and paired-boss Web fixtures average 120.1547 and 120.0881 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings/errors. Web release export, iOS project export, and unsigned generic-device Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m7-underground-vault.md`.

Evidence (2026-08-22, Genesis Protocol batch): Stage 8 completes the 4,200 px campaign through Gene-Forge Causeway, Specimen Gallery, and Genesis Core, with five ordered encounters, nineteen authored spawns, three independent original 1672×941 backgrounds, three quarantine/gallery/reactor ambience themes, and the eighth campaign-map node. Typed `LabHazardData` drives two arc fields, two mutagen pools, and two core surges with independent warning, active, offset, damage, knockback, and movement data. Architect Sera Calder uses an original isolated 2560×960 three-form atlas: Director form controls jade/magenta Genesis barrages, Apex Mantle changes silhouette and attack grammar for a four-arm rush phase, and Genesis Core creates faction-safe collapse zones with targeted warning/impact/linger timing. The final settlement applies one campaign bonus before an authored ending, credits, and eight-stage report. Forty-six deterministic suites pass 2817/2817 assertions. Accepted environment and final-boss Web fixtures both average 119.9968 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings/errors; ending and credits fixtures also pass visual review. Web release export, iOS project export, and unsigned generic-device Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m7-genesis-protocol.md`.

Exit gate: the complete eight-stage campaign can be finished from a fresh start without debug intervention.

### M8 — Arcade shell, mobile polish, and accessibility

Status: **complete**

- [x] Attract/title flow, character select polish, continue countdown, local high scores, options, pause, and save settings.
- [x] Original full soundtrack, audio mixing, voice efforts, subtitles, and language-ready UI.
- [x] Touch remapping/sizing, safe areas, haptics controls, pause/resume safety, and mobile performance tuning.
- [x] Rebindable controls, screen shake/hit-flash controls, readable UI scale, and color-independent telegraphs.

Evidence (2026-08-22, arcade-shell/persistence batch): the consumer flow now includes an idle attract/instructions screen, clean title and character-select transitions, a local top-ten table, a gameplay-safe pause/options screen, and a nine-second player-confirmable continue countdown instead of automatic resurrection. A versioned `ConfigFile` profile persists clamped audio, feedback, haptics, touch/UI scale, language, and ordered high-score data, migrates legacy version-zero keys, and records each final score at most once. Keyboard Escape/P and active-slot gamepad Start pause safely; music and effects volumes, shake, hit flash, and haptics apply immediately. Forty-seven deterministic suites pass 2854/2854 assertions. Accepted attract, pause/options, continue, and high-score Web fixtures render without browser warnings/errors; the performance fixtures average 120.55, 120.03, and 120.04 FPS with zero frames above 20 ms or 33 ms. Web release export passes. Detailed evidence is archived in `evidence/m8-arcade-shell.md`.

Evidence (2026-08-22, mobile/accessibility batch): touch controls now resolve against the device safe area, scale from 0.75× to 1.35× without overlapping action hit targets, offer classic/compact/left-handed remapped layouts, expose a dedicated pause button, support touch-driven settings, and automatically pause on focus loss without auto-resuming. Touch dialogue wraps inside a control-safe panel. The version-two profile adds persistent eight-action keyboard bindings; rebinding swaps conflicts and applies through `InputMap` while preserving gamepad input. UI text scale, shake, hit flash, haptics, and always-on-by-default high-contrast hazard markers are independently configurable. Forty-eight deterministic suites pass 2883/2883 assertions. Accepted mobile safe-area and control-remap Web fixtures average 120.01 and 119.87 FPS over 300 frames, with zero frames above 20 ms or 33 ms and no browser warnings/errors. Detailed evidence is archived in `evidence/m8-mobile-accessibility.md`.

Exit evidence (2026-08-22, audio/localization batch): a deterministic music director now supplies title, eight distinct stage arrangements, eight distinct boss arrangements, victory, ending, and credits cues with same-cue variant switching and mix ducking. Three original synthesized effort families layer hero, boss, and creature vocal force into specials, phase changes, and dinosaur state transitions. Profile schema version three persists subtitle and English/Chinese choices; every one of the campaign's 24 boss-phase lines has a Simplified Chinese subtitle, the consumer shell localizes its primary settings/high-score/continue/remap flow, and subtitles can be disabled independently. Web QA initially rejected the build because browser fallback fonts rendered Chinese as boxes; the accepted build bundles OFL-licensed Noto Sans SC and verifies both Chinese and Latin glyphs. Forty-nine deterministic suites pass 3065/3065 assertions. Accepted Chinese options and boss-subtitle fixtures have no browser warnings/errors; the subtitle fixture averages 120.02 FPS over 300 frames with zero frames above 20 ms or 33 ms. Web release export, iOS project export, and unsigned generic-device Mach-O arm64 build pass. Detailed evidence is archived in `evidence/m8-audio-localization.md`.

Post-release evidence (2026-08-22, complete Simplified Chinese batch): the existing language option now localizes the complete player-facing campaign rather than only the shell and boss subtitles. Runtime rendering covers HUD objectives, combat banners, co-op join/down/revive/continue notices, all eight stage routes, 24 scenes, 38 encounter cards, character roles, boss speakers, weapons, pickups, vehicle name, victory/report flow, ending, credits, and mobile pickup labels; switching language applies immediately without duplicating gameplay resources. Chinese touch subtitles wrap by character when no word spaces are present. A catalog traversal regression rejects any untranslated authored stage, encounter, hero, item, weapon, vehicle, or boss-speaker string. The focused localization suite passes 382/382 assertions and the full release matrix passes 53 suites/3,929 assertions. Accepted Chinese options and in-game subtitle Web fixtures render with zero browser warnings/errors. Web export, iOS project export, signed arm64 device build, and installation on the paired iPhone 14 Pro pass.

Exit gate: desktop, Web, and iOS behave like complete consumer builds rather than development demos.

### M9 — Balance, QA, and 1.0 release

Status: **complete**

- [x] Full solo and 2–3 player balance passes with documented difficulty curves.
- [x] All-stage automated smoke suite and focused combat/encounter regression suite.
- [x] Browser/device compatibility, reconnect, suspend/resume, save migration, and performance tests.
- [x] Asset provenance audit, license audit, release notes, clean checkout build, Pages deployment, and signed iOS run.
- [x] No critical/high defects; accepted medium defects documented with owner and target.

Evidence (2026-08-22, release balance/smoke batch): the release gate now evaluates all 24 stage/player-count difficulty cells, all four solo hero profiles, and all fourteen unique solo/duo/trio hero rosters. Enemy health rises with each extra player while per-player encounter health falls; co-op damage pressure is capped at 1.16× over the same stage, solo hero TTK remains within 0.75–1.18× of Ranger, and co-op roster TTK remains inside the documented 0.52–0.82× teamwork band. A second release suite traverses all 24 scenes, 38 encounters, every wave, at least 120 resolved spawns, at least 20 referenced enemy roles, every final boss gate, and representative runtime instantiation/health scaling for all 8 stages at 1–3 players. The two new suites pass 487/487 assertions. Detailed curves and coverage are archived in `evidence/m9-balance-stage-smoke.md`.

Evidence (2026-08-22, compatibility/lifecycle batch): controller disconnect/reconnect now restores the reserved slot, hero, health, position, continues, and safety invulnerability; application suspend persists the profile and enters the normal pause-confirmation flow. Profile release tests cover v1, v2, current/future schemas, defaults for new localization fields, last-known-good backup recovery, and clean fallback from an unrecoverable primary file. Automated platform checks hold Web to the compatibility renderer without thread/isolation requirements and iOS to arm64/iOS 15+. A real Chromium maximum-load fixture renders three players, the Stage 8 final boss, twelve additional enemies, and active stage hazards at 8.050 ms average with zero sampled frames above 20/33 ms and no browser warnings/errors. Full regression passes 52 suites and 3,586 assertions; Web and unsigned iOS packages plus Xcode arm64 build pass. Detailed evidence is archived in `evidence/m9-compatibility-lifecycle-performance.md`.

Evidence (2026-08-22, provenance/license audit): all tracked PNGs are named in the generation/provenance log; nineteen archived generation, edit, and superseded prototype canvases are excluded from both Web and iOS. The project now has explicit MIT/CC BY 4.0 grants, the complete Noto Sans SC OFL, Godot runtime redistribution notice, v1.0.0 notes, and a zero-critical/high/medium defect ledger. Automated audit rejects unrecorded PNGs, missing dual-export exclusions, protected franchise runtime tokens, ROM/archive formats, external audio, and missing third-party notices. The audit suite passes 133 deterministic assertions and full regression passes 53 suites/3,719 assertions. Removing three superseded prototype canvases from runtime reduces the Web PCK from 79,814,916 to 76,160,164 bytes; the maximum-load browser fixture remains error-free at 8.050 ms average with zero frames over 20/33 ms. Detailed evidence is archived in `evidence/m9-release-audit.md`.

Exit evidence (2026-08-22, release-candidate gate): remote commit `2f47eaa` was checked out into a new detached worktree with no inherited `.godot` or build cache. `tools/verify_release.sh` completed import, all 53 suites/3,719 assertions, Web export, iOS project export, and unsigned Xcode arm64 build. The refreshed Xcode account supplied the matching `BYSMY792J7` development profile for `com.jianghu.wildlandstrike`; a signed arm64 build succeeded, installed on the paired iPhone 14 Pro, launched, and remained visible in the device process list. GitHub Pages deployed the exact source commit successfully. Final tagged-commit reproduction and published-package checks are recorded in `evidence/m9-release-audit.md` and the annotated `v1.0.0` release.

Exit gate: tag `v1.0.0`, publish the verified Web build, and archive reproducible build evidence.

## Next task queue

Tasks are ordered. Take the first unblocked item unless the user explicitly prioritizes another milestone-compatible task.

1. **Post-release maintenance:** accept only reproduced defects, add a failing regression first, and preserve the M0–M9 release gates.
2. **Optional distribution:** prepare store-facing metadata and App Store/TestFlight signing only when explicitly requested; this is outside the v1.0.0 development-device gate.

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
- The reusable human/dinosaur roster is complete through M5; all eight stages now have unique boss encounters and original compositions, including the three-form final boss.
- Stages 1–8, ending, credits, and final report are completed campaign content; subsequent milestones must preserve their combat, presentation, Web performance, and acceptance standards while completing the consumer arcade shell.
- Character selection, typed role tuning, complete original 24-state sheets, three-slot local device routing, independent ready states, safe spawning, shared-camera framing, faction-safe combat, stage-and-player-count spawn scaling, teammate rescue, per-player continues, linked team attacks, eight-node campaign mapping, score/life settlement, and the complete fourteen-run M4 acceptance matrix exist for all four heroes. Their timing contract remains shared until the M9 balance pass. Version-three local settings/high scores, legacy migration, keyboard rebinding, UI scaling, classic/compact/left-handed mobile layouts, complete Simplified Chinese campaign/UI coverage, and all 24 Chinese boss subtitles are complete. The twelve-behavior weapon catalog, Stage 1 carryable/breakable/hazard and typed pickup distribution, Stage 2 systemic currents, Stage 5 fire/smoke/water-pressure hazards, Stage 6 spore/cart/stomp hazards, Stage 7 deck/laser/cryo hazards, Stage 8 arc/mutagen/core hazards, four-species ecology, six standard enemies, four elites, and reusable encounter recipes are complete.
- The v1.0.0 candidate passes unsigned generic-device and signed physical-device arm64 builds; installation, launch, and live process presence were verified on the paired iPhone 14 Pro.
