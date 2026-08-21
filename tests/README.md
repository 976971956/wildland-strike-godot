# Automated tests

Run the complete deterministic suite from the repository root:

```sh
godot --headless --log-file /tmp/wildland-tests.log --path . --script res://tests/test_runner.gd
```

Run one focused suite by name:

```sh
godot --headless --log-file /tmp/wildland-combat-tests.log --path . --script res://tests/test_runner.gd -- --suite=combat_rules
```

`res://tests/smoke_test.gd` remains a compatibility entry point and runs the same complete suite.

## Adding a suite

1. Add a `RefCounted` script under `tests/suites/` with an asynchronous `run(test)` method.
2. Register its stable name and resource path in `SUITES` inside `test_runner.gd`.
3. Use `test.check(...)` for assertions and `test.wait_physics_frames(...)` for deterministic timing.
4. Instantiate and dispose the main scene through the shared test context so suites cannot leak actors, groups, or `Engine.time_scale` into the next suite.

Avoid wall-clock timers, uncontrolled input, and assertions that depend on a rendered frame rate. The runner fixes the random seed, physics rate, and time scale before executing suites.
