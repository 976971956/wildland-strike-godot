extends RefCounted

const CommandMoveControllerScript = preload("res://actors/fighters/command_move_controller.gd")
const FighterIntentScript = preload("res://core/input/fighter_intent.gd")
const COMMAND_ATTACK = preload("res://data/attacks/player_command.tres")
const SPECIAL_ATTACK = preload("res://data/attacks/player_special.tres")


func run(test) -> void:
	test.check(COMMAND_ATTACK.is_valid_frame_data(), "command attack failed frame-data validation")
	test.check(COMMAND_ATTACK.attack_id == &"player_command_attack" and COMMAND_ATTACK.launch, "command attack identity or launch drifted")
	test.check(SPECIAL_ATTACK.self_damage == 7 and SPECIAL_ATTACK.invulnerable_duration == 0.7, "defensive-special cost or invulnerability drifted")

	var controller = CommandMoveControllerScript.new()
	controller.update(Vector2.DOWN, 1)
	test.check(controller.phase == 1 and not controller.is_ready(), "down input did not start command sequence")
	controller.update(Vector2.ZERO, 1)
	controller.update(Vector2.RIGHT, 1)
	test.check(controller.is_ready(), "forward input did not complete right-facing command")
	test.check(controller.consume_attack(), "ready command was not consumed")
	test.check(not controller.consume_attack(), "command sequence was consumed twice")

	controller.update(Vector2.DOWN, -1)
	controller.update(Vector2.ZERO, -1)
	controller.update(Vector2.LEFT, -1)
	test.check(controller.is_ready(), "left-facing command did not mirror its forward input")
	controller.tick(controller.INPUT_WINDOW + 0.01)
	test.check(not controller.is_ready() and controller.phase == 0, "expired command sequence remained ready")

	controller.update(Vector2.DOWN, 1)
	controller.update(Vector2.ZERO, 1)
	controller.update(Vector2.LEFT, 1)
	test.check(not controller.is_ready() and controller.phase == 0, "backward input completed a forward command")
	test.check(
		CommandMoveControllerScript.classify(Vector2(0.0, 0.2), 1) == CommandMoveControllerScript.InputKind.NEUTRAL,
		"command deadzone accepted weak input"
	)
	test.check(
		CommandMoveControllerScript.classify(Vector2(0.45, 0.8), 1) == CommandMoveControllerScript.InputKind.DOWN,
		"down-forward input lost its down phase"
	)

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.set_physics_process(false)
	game.player.position = Vector2(500.0, 540.0)
	await test.wait_physics_frames(2)
	var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	test.check(enemies.size() >= 3, "command-move fixture failed to spawn targets")
	if enemies.size() < 3:
		await test.dispose(game)
		return
	for index in range(enemies.size()):
		enemies[index].set_physics_process(false)
		enemies[index].position = Vector2(1200.0 + index * 120.0, 620.0)

	game.player.combo_step = 3
	game.player.combo_window = 0.3
	game.player.finisher_armed = true
	game.player._apply_intent(FighterIntentScript.new(Vector2.DOWN))
	game.player._apply_intent(FighterIntentScript.new(Vector2.ZERO))
	game.player._apply_intent(FighterIntentScript.new(Vector2.RIGHT, false, true))
	test.check(game.player.current_attack == COMMAND_ATTACK, "quarter-circle input did not select command attack")
	test.check(game.player.combo_step == 0 and game.player.combo_window == 0.0, "command attack retained ground combo state")
	test.check(game.player.attack_lunge == 320.0, "command-attack lunge drifted")
	test.check(game.player._visual_frame() == Vector2i(4, 1), "command-attack visual frame drifted")

	var command_target = enemies[0]
	command_target.position = game.player.position + Vector2(80.0, 0.0)
	command_target.invulnerable = 0.0
	command_target.hurt_timer = 0.0
	var command_target_health: int = command_target.health
	game.player.attack_timer = COMMAND_ATTACK.hit_trigger_remaining - 0.01
	game.player._check_attack_hit()
	test.check(command_target.health == command_target_health - 12, "command-attack first-hit damage drifted")
	test.check(game.player.attack_hits_resolved == 1 and not game.player.attack_hit_done, "command attack did not retain its second hit")
	command_target.invulnerable = 0.0
	game.player.attack_timer = game.player.next_hit_remaining - 0.01
	game.player._check_attack_hit()
	test.check(command_target.health == command_target_health - 24, "command-attack total damage drifted")
	test.check(game.player.attack_hits_resolved == 2 and game.player.attack_hit_done, "command attack did not finish after two hits")
	test.check(command_target.knockdown_state and command_target.velocity == Vector2(560.0, -70.0), "command attack did not launch with configured force")

	for enemy in enemies:
		enemy.position = Vector2(1200.0, 620.0)
	game.player.attack_timer = 0.0
	game.player.special_timer = 0.0
	game.player.invulnerable = 0.0
	var miss_health: int = game.player.health
	game.player._apply_intent(FighterIntentScript.new(Vector2.ZERO, true, true))
	test.check(game.player.current_attack == SPECIAL_ATTACK and game.player.special_timer == SPECIAL_ATTACK.duration, "attack+jump chord did not select defensive special")
	test.check(game.player.z_height == 0.0 and game.player.z_velocity == 0.0, "defensive chord also started a jump")
	test.check(not game.player.special_connected and game.player.health == miss_health, "missed defensive special consumed health")
	test.check(game.player.invulnerable == SPECIAL_ATTACK.invulnerable_duration, "defensive special lost invulnerability")

	var first_target = enemies[1]
	var second_target = enemies[2]
	first_target.position = game.player.position + Vector2(80.0, 0.0)
	second_target.position = game.player.position + Vector2(-80.0, 0.0)
	for target in [first_target, second_target]:
		target.health = target.max_health
		target.invulnerable = 0.0
		target.hurt_timer = 0.0
	var first_health: int = first_target.health
	var second_health: int = second_target.health
	game.player.attack_timer = 0.0
	game.player.special_timer = 0.0
	game.player.invulnerable = 0.0
	var connect_health: int = game.player.health
	game.player._apply_intent(FighterIntentScript.new(Vector2.ZERO, true, true))
	test.check(game.player.special_connected, "connected defensive special was marked as a miss")
	test.check(first_target.health == first_health - 18 and second_target.health == second_health - 18, "defensive special did not hit every valid nearby target")
	test.check(game.player.health == connect_health - SPECIAL_ATTACK.self_damage, "multi-target defensive special did not charge exactly one health cost")

	for target in [first_target, second_target]:
		target.invulnerable = 1.0
	game.player.attack_timer = 0.0
	game.player.special_timer = 0.0
	game.player.invulnerable = 0.0
	var invulnerable_miss_health: int = game.player.health
	game.player._apply_intent(FighterIntentScript.new(Vector2.ZERO, false, false, true))
	test.check(not game.player.special_connected and game.player.health == invulnerable_miss_health, "invulnerable targets caused a defensive-special health cost")

	game.player.attack_timer = 0.0
	game.player.special_timer = 0.0
	game.player.invulnerable = 0.0
	game.player.health = SPECIAL_ATTACK.self_damage
	game.player.current_attack = COMMAND_ATTACK
	game.player.z_height = 0.0
	game.player.z_velocity = 0.0
	game.player._apply_intent(FighterIntentScript.new(Vector2.ZERO, true, true))
	test.check(game.player.special_timer == 0.0 and game.player.current_attack == COMMAND_ATTACK, "insufficient-health chord started defensive special")
	test.check(game.player.z_height == 0.0, "rejected defensive chord leaked into jump")

	var touch_source := FileAccess.get_file_as_string("res://scripts/touch_controls.gd")
	test.check(touch_source.contains("A+B"), "touch special shortcut does not communicate the defensive chord")
	await test.dispose(game)
