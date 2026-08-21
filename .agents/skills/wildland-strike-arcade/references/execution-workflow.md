# Execution workflow

Use this workflow for any task that mutates Wildland Strike.

## 1. Select and bound the task

- Read `PROJECT_PLAN.md` from the repository root.
- Prefer the first unblocked item in **Next task queue**.
- A task should deliver one testable behavior or one coherent content slice. Split work that crosses milestone boundaries without a shared acceptance test.
- Confirm prerequisites in code. If the roadmap is stale, correct it before building on the wrong assumption.

## 2. Establish evidence

- Reproduce bugs before fixing them when practical.
- For combat work, identify the exact fighter states, frame windows, hitbox/hurtbox interactions, and expected outcome.
- For content work, identify the stage/encounter data and completion transition.
- For visual work, inspect the rendered game at gameplay scale; source images alone are insufficient.

## 3. Implement at the right layer

- Put reusable combat behavior in fighter/combat components, not stage scripts.
- Put tunable values in typed resources or data definitions, not scattered conditionals.
- Put stage-specific sequencing in encounter/stage data, not player or enemy controllers.
- Keep input intent separate from fighter simulation so AI, touch, keyboard, and multiple players share the same action API.
- Add debug visualization for new hitboxes, navigation bounds, spawn triggers, or camera constraints.

## 4. Validate proportionally

Minimum for any code change:

```sh
godot --headless --path . --script res://tests/smoke_test.gd
```

Also require:

- A focused regression test for a fixed bug or new deterministic rule.
- A real rendered play check for animation, camera, UI, touch, or stage-layout changes.
- A Web export to `docs/index.html` for player-visible behavior.
- An Xcode generic-device build for iOS-affecting changes; install and launch when the paired iPhone is available.
- `git diff --check` and a clean status after commit.

Do not weaken tests merely to accept a regression. If a flaky timing test is found, make the simulation or test deterministic.

## 5. Update project state

In `PROJECT_PLAN.md`:

- Move the task to completed only after its acceptance criteria pass.
- Record concise evidence: test name, build target, or observable behavior.
- Update the **Current status** percentages only when a milestone changes materially.
- Put the next highest-priority unblocked task at the top of **Next task queue**.
- Record architectural or scope decisions in **Decision log** when they affect later tasks.

## 6. Publish the completed task

The user has explicitly requested GitHub submission after every completed mutation.

1. Commit source, tests, roadmap update, and generated Web output together.
2. Use a concise imperative commit message naming the delivered behavior.
3. Push to `origin/main`.
4. If `docs/` changed, confirm the GitHub Pages build references the new commit and reports `built`.
5. Never commit signing secrets, provisioning profiles, tokens, DerivedData, or generated iOS frameworks.

If publishing is blocked, preserve the verified local commit and report the exact blocker. Do not claim the task is fully delivered until the required push succeeds.
