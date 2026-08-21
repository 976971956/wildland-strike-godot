extends RefCounted

const FighterIntentScript = preload("res://core/input/fighter_intent.gd")
const ActionInputSourceScript = preload("res://core/input/action_input_source.gd")

class StubIntentSource:
	extends RefCounted
	var next_intent

	func sample_intent():
		return next_intent


func run(test) -> void:
	var clamped_intent = FighterIntentScript.new(Vector2(4.0, 3.0), true, true, true)
	test.check(clamped_intent.move.is_equal_approx(Vector2(0.8, 0.6)), "fighter intent did not clamp movement")
	test.check(clamped_intent.has_action(), "fighter intent lost action edges")
	var neutral_intent = FighterIntentScript.new()
	test.check(neutral_intent.move == Vector2.ZERO and not neutral_intent.has_action(), "neutral fighter intent is not neutral")

	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	test.check(not player_source.contains("Input."), "player simulation still accesses the Input singleton")

	for action in ["move_left", "move_right", "move_up", "move_down", "attack", "jump", "special"]:
		test.check(InputMap.has_action(action), "%s is missing from the shared action map" % action)
	var attack_events := InputMap.action_get_events("attack")
	var has_keyboard_attack := false
	var has_gamepad_attack := false
	for event in attack_events:
		has_keyboard_attack = has_keyboard_attack or event is InputEventKey
		has_gamepad_attack = has_gamepad_attack or event is InputEventJoypadButton
	test.check(has_keyboard_attack, "attack intent has no keyboard mapping")
	test.check(has_gamepad_attack, "attack intent has no gamepad mapping")

	var action_source = ActionInputSourceScript.new()
	test.tree.root.add_child(action_source)
	Input.action_press("move_right", 0.75)
	Input.action_press("attack")
	var action_intent = action_source.sample_intent()
	test.check(action_intent.move.x > 0.5 and action_intent.move.x < 1.0, "action input source lost analog movement strength")
	test.check(action_intent.attack_pressed, "action input source lost attack edge")
	Input.action_release("move_right")
	Input.action_release("attack")
	await test.dispose(action_source)

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.set_physics_process(false)
	var stub := StubIntentSource.new()
	game.player.set_intent_source(stub)
	stub.next_intent = FighterIntentScript.new(Vector2(-1.0, 0.0))
	game.player._apply_intent(stub.sample_intent())
	test.check(game.player.velocity == Vector2(-game.player.SPEED, 0.0), "player did not consume injected movement intent")
	test.check(game.player.facing == -1, "injected movement intent did not turn the player")

	stub.next_intent = FighterIntentScript.new(Vector2.ZERO, true)
	game.player._apply_intent(stub.sample_intent())
	test.check(game.player.z_height == 2.0 and game.player.z_velocity == 510.0, "player did not consume injected jump intent")
	game.player.z_height = 0.0
	game.player.z_velocity = 0.0
	game.player.attack_timer = 0.0
	stub.next_intent = FighterIntentScript.new(Vector2.ZERO, false, true)
	game.player._apply_intent(stub.sample_intent())
	test.check(game.player.current_attack.attack_id == &"player_combo_1", "player did not consume injected attack intent")

	game.player.attack_timer = 0.2
	stub.next_intent = FighterIntentScript.new(Vector2.ZERO, false, true)
	game.player._apply_intent(stub.sample_intent())
	test.check(game.player.attack_buffer == 0.24, "injected attack intent did not enter the attack buffer")

	game.player.attack_timer = 0.0
	game.player.attack_buffer = 0.0
	game.player.special_timer = 0.0
	var health_before_special: int = game.player.health
	stub.next_intent = FighterIntentScript.new(Vector2.ZERO, false, false, true)
	game.player._apply_intent(stub.sample_intent())
	test.check(game.player.current_attack.attack_id == &"player_special", "player did not consume injected special intent")
	test.check(game.player.health < health_before_special, "injected special intent did not apply its health cost")
	await test.dispose(game)
