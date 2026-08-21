extends SceneTree

const TestContext = preload("res://tests/test_context.gd")
const SUITES := [
	{"name": "baseline_flow", "path": "res://tests/suites/baseline_flow_test.gd"},
	{"name": "combat_rules", "path": "res://tests/suites/combat_rules_test.gd"},
	{"name": "fighter_state_machine", "path": "res://tests/suites/fighter_state_machine_test.gd"},
	{"name": "hitbox_hurtbox", "path": "res://tests/suites/hitbox_hurtbox_test.gd"},
	{"name": "attack_frame_data", "path": "res://tests/suites/attack_frame_data_test.gd"},
	{"name": "input_intent", "path": "res://tests/suites/input_intent_test.gd"},
	{"name": "enemy_definition", "path": "res://tests/suites/enemy_definition_test.gd"},
	{"name": "enemy_behavior", "path": "res://tests/suites/enemy_behavior_test.gd"},
	{"name": "combat_regression", "path": "res://tests/suites/combat_regression_test.gd"},
	{"name": "run_controller", "path": "res://tests/suites/run_controller_test.gd"},
	{"name": "combo_chain", "path": "res://tests/suites/combo_chain_test.gd"},
	{"name": "aerial_combat", "path": "res://tests/suites/aerial_combat_test.gd"},
	{"name": "command_move", "path": "res://tests/suites/command_move_test.gd"},
	{"name": "grapple_system", "path": "res://tests/suites/grapple_system_test.gd"},
	{"name": "combat_resolution", "path": "res://tests/suites/combat_resolution_test.gd"},
	{"name": "impact_feedback", "path": "res://tests/suites/impact_feedback_test.gd"},
	{"name": "performance_probe", "path": "res://tests/suites/performance_probe_test.gd"},
	{"name": "stage_director", "path": "res://tests/suites/stage_director_test.gd"},
	{"name": "stage_environment", "path": "res://tests/suites/stage_environment_test.gd"},
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	seed(0x57494C44)
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	var requested := _requested_suites()
	var total_assertions := 0
	var total_failures := 0
	var executed := 0

	for definition: Dictionary in SUITES:
		var suite_name: String = definition["name"]
		if not requested.is_empty() and not requested.has(suite_name):
			continue
		var suite_script: Script = load(definition["path"])
		if suite_script == null or not suite_script.can_instantiate():
			push_error("TEST RUNNER: failed to load suite %s" % suite_name)
			total_failures += 1
			continue
		var context := TestContext.new(self, suite_name)
		var suite: RefCounted = suite_script.new()
		print("TEST SUITE START: %s" % suite_name)
		await suite.run(context)
		executed += 1
		total_assertions += context.assertions
		total_failures += context.failures
		print("TEST SUITE %s: %d assertions, %d failures" % [
			suite_name.to_upper(), context.assertions, context.failures
		])

	if executed == 0:
		push_error("TEST RUNNER: no suites matched %s" % [requested])
		quit(2)
		return
	if total_failures > 0:
		push_error("TEST RUN FAILED: %d assertions, %d failures" % [total_assertions, total_failures])
		quit(1)
		return
	print("TEST RUN PASSED: %d suites, %d assertions" % [executed, total_assertions])
	quit(0)


func _requested_suites() -> PackedStringArray:
	var requested := PackedStringArray()
	var args := OS.get_cmdline_user_args()
	var read_next := false
	for arg in args:
		if read_next:
			requested.append(arg)
			read_next = false
		elif arg == "--suite":
			read_next = true
		elif arg.begins_with("--suite="):
			requested.append(arg.trim_prefix("--suite="))
	return requested
