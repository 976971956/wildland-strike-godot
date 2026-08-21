---
name: wildland-strike-arcade
description: Develop, review, test, package, or publish the Wildland Strike Godot project according to its arcade-parity roadmap. Use for every gameplay, content, art, audio, mobile, Web, iOS, QA, or release task in this repository; do not use for unrelated Godot projects.
---

# Wildland Strike Arcade

Build the public, clean-room arcade tribute defined in [`PROJECT_PLAN.md`](../../../PROJECT_PLAN.md). Match the systems, pacing, content scale, and responsiveness of a complete 1990s dinosaur beat-'em-up while keeping names, story, art, music, dialogue, and branding original.

## Before changing the project

1. Read the current status, next-task queue, dependencies, and acceptance criteria in [`PROJECT_PLAN.md`](../../../PROJECT_PLAN.md).
2. Read [`references/execution-workflow.md`](references/execution-workflow.md).
3. Inspect the relevant implementation and tests. Do not trust a stale status checkbox over the code.
4. Select the highest-priority unblocked task unless the user names a different in-scope task.

## Project invariants

- Preserve a 60 FPS, 2.5D lane-based beat-'em-up with deterministic hit timing.
- Prefer data-driven fighters, enemies, weapons, encounters, and stages over additional type branches in monolithic scripts.
- Keep combat readable: explicit state transitions, hitboxes/hurtboxes, frame data, hit stop, knockback, invulnerability, attack priority, and debug visualization.
- Public assets must be original or properly licensed. Never add ROM-extracted sprites, original soundtrack rips, dialogue, logos, character names, or Cadillac branding.
- Treat desktop/Web gamepads as the 1–3 player reference experience. Preserve a complete single-player touch layout on mobile.
- A milestone is not complete because it has placeholder art, one generic behavior reused under several labels, or an unverified build.
- Preserve unrelated user changes and do not rewrite working systems without a milestone reason.

## Completion contract

For every implementation task:

1. Satisfy its acceptance criteria and add or update regression coverage.
2. Run the proportional checks from the workflow reference.
3. Update `PROJECT_PLAN.md` status, evidence, and next task in the same commit.
4. Rebuild `docs/` when behavior visible in the Web version changes.
5. Commit and push the completed task to `origin/main`, then verify GitHub Pages when `docs/` changed.
6. Report the commit, tests, builds, deployment status, and any remaining limitation honestly.

Resolve ordinary implementation problems independently. Ask the user only when progress requires a product decision that changes the final-version contract, private credentials or device interaction, destructive action, licensed third-party material, or another external choice that cannot be inferred safely.
