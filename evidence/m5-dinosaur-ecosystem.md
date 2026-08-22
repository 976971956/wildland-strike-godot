# M5 dinosaur ecosystem evidence

Date: 2026-08-22

## Four archetypes

| Species | Behavior | Spawn state | Combat role |
|---|---|---|---|
| Compy | Flanker | Neutral/active | Fast, fragile close-pressure creature |
| Raptor | Pouncer | Neutral/active | Retreat-and-pounce skirmisher |
| Ankylosaur | Pressure | Sleeping | Slow armored tail-club bruiser |
| Triceratops | Charger | Sleeping | Heavy telegraphed lane charger |

All four use the neutral-creature combat team, cannot be grabbed, ignore neutral allies, and may acquire nearer human enemies through the same target-hysteresis pipeline used by Stage 1's original raptor.

## Ecology states

- Sleeping is an explicit runtime state and visual pose. The AI entry point hard-stops movement until a live player or opposing-faction enemy crosses the resource-owned wake radius.
- Damage wakes a sleeping dinosaur immediately.
- A resource-owned health ratio changes a surviving dinosaur to the explicit enraged state.
- Enrage applies independent speed and attack-damage multipliers, clears behavior cooldown, emits a dedicated event/SFX, adds a visible red state cue, and works against players or human enemies.
- Wake emits its own event/SFX and sleeping creatures display an animated sleep cue.
- Same-faction target selection and hitbox ownership prevent dinosaur-versus-dinosaur damage while human-versus-dinosaur combat remains bidirectional.

## Art pipeline

Compy, ankylosaur, and triceratops each own an original 2560×320 RGBA eight-state strip. `tools/split_dinosaur_atlas.gd` deterministically keys the archived generated source, discovers the eight largest connected actors per row, orders them by x position, scales with nearest-neighbor interpolation, and centers every pose in an isolated transparent 320×320 cell. Prompt, hashes, source limitations, and clean-room scope are recorded in `ASSET_PROVENANCE.md`.

## Automated acceptance

- Four unique valid IDs, textures, neutral factions, and behavior families.
- Two authored sleeping archetypes and two active neutral archetypes.
- Exact 2560×320 dimensions and alpha retained for every species strip.
- Distant sleep, proximity wake by an opposing enemy, player wake, neutral target acquisition, health-threshold enrage, speed multiplier, cross-faction damage multiplier, and same-faction avoidance verified deterministically.
- Regression: 37 suites, 2034 assertions, 0 failures.

## Packaging and presentation

- Exported Web fixture: 119.9872 average FPS over 300 frames, 0 frames above 20 ms, and 0 frames above 33 ms.
- Web release export completed successfully with the archived opaque source atlas excluded from the runtime package.
- iOS project export completed successfully; the unsigned generic-device Xcode build produced a verified Mach-O arm64 executable.
- All four species were visually inspected together at 1,280×720, including sleeping and enraged cues.
- The archived three-row source is excluded from runtime export; only normalized sheets ship.

The third M5 checklist item is complete. The remaining M5 task is the standard/elite enemy roster and reusable encounter recipes.
