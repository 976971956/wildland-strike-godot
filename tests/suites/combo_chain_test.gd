extends RefCounted

const ComboDefinitionScript = preload("res://core/combat/combo_definition.gd")
const COMBO = preload("res://data/fighters/ranger_combo.tres")


func run(test) -> void:
	test.check(COMBO != null and COMBO.is_valid_definition(), "Ranger combo definition failed validation")
	test.check(COMBO.fighter_id == &"ranger" and COMBO.attacks.size() == 4, "Ranger combo roster drifted")
	test.check(COMBO.finisher_from_step == 3 and COMBO.finisher_step == 4, "finisher chain position drifted")
	test.check(
		COMBO.finisher_input_open_remaining == 0.20
		and COMBO.finisher_input_close_remaining == 0.04,
		"finisher input window drifted"
	)
	test.check(COMBO.is_finisher_input_open(3, 0.20), "finisher open boundary was rejected")
	test.check(COMBO.is_finisher_input_open(3, 0.04), "finisher close boundary was rejected")
	test.check(not COMBO.is_finisher_input_open(3, 0.201), "finisher accepted input before its window")
	test.check(not COMBO.is_finisher_input_open(3, 0.039), "finisher accepted input after its window")
	test.check(not COMBO.is_finisher_input_open(2, 0.10), "non-bridge attack opened the finisher window")
	test.check(COMBO.attack_for_step(0) == null and COMBO.attack_for_step(5) == null, "combo accepted an invalid step")

	var invalid_combo = ComboDefinitionScript.new()
	test.check(not invalid_combo.is_valid_definition(), "empty combo definition should be invalid")
	invalid_combo.fighter_id = &"broken"
	invalid_combo.attacks = COMBO.attacks.duplicate()
	invalid_combo.finisher_from_step = 3
	invalid_combo.finisher_step = 3
	test.check(not invalid_combo.is_valid_definition(), "non-sequential finisher definition should be invalid")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.set_physics_process(false)
	game.player.position = Vector2(500.0, 540.0)
	await test.wait_physics_frames(2)
	var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	test.check(enemies.size() >= 2, "combo-chain fixture failed to spawn targets")
	if enemies.size() < 2:
		await test.dispose(game)
		return
	for index in range(enemies.size()):
		enemies[index].set_physics_process(false)
		enemies[index].position = Vector2(1100.0 + index * 120.0, 620.0)

	game.player._reset_combo()
	game.player.attack_timer = 0.0
	game.player._start_attack()
	test.check(game.player.combo_step == 1 and game.player.current_attack.attack_id == &"player_combo_1", "chain did not start at combo one")
	game.player.attack_timer = 0.10
	game.player._start_attack()
	test.check(game.player.combo_step == 2 and game.player.current_attack.attack_id == &"player_combo_2", "chain did not advance to combo two")
	game.player.attack_timer = 0.10
	game.player._start_attack()
	test.check(game.player.combo_step == 3 and game.player.current_attack.attack_id == &"player_combo_3", "chain did not advance to combo three")
	test.check(not game.player.current_attack.launch, "combo three was not retained as a bridge hit")

	game.player.attack_timer = 0.21
	game.player.attack_buffer = 0.0
	game.player._handle_attack_intent()
	test.check(not game.player.finisher_armed and game.player.attack_buffer == 0.0, "early finisher input was buffered")
	game.player.attack_timer = 0.15
	game.player._handle_attack_intent()
	test.check(game.player.finisher_armed, "valid finisher input did not arm combo four")
	test.check(game.player.attack_buffer == COMBO.input_buffer_duration, "finisher buffer duration drifted")
	game.player.attack_timer = 0.10
	game.player._start_attack()
	test.check(game.player.combo_step == 4 and game.player.current_attack.attack_id == &"player_combo_4", "armed chain did not select combo four")
	test.check(game.player.current_attack.combo_window == 0.0 and game.player.current_attack.launch, "combo four did not close the chain with launch")
	test.check(game.player._visual_frame() == Vector2i(3, 1), "combo-four visual frame drifted")

	var target = enemies[0]
	target.position = game.player.position + Vector2(60.0, 0.0)
	target.invulnerable = 0.0
	target.hurt_timer = 0.0
	var target_health: int = target.health
	game.player.attack_timer = game.player.current_attack.hit_trigger_remaining - 0.01
	game.player._check_attack_hit()
	test.check(target.health == target_health - 22, "combo-four damage drifted")
	test.check(target.knockdown_state, "combo four did not knock its target down")
	test.check(target.velocity == Vector2(520.0, -55.0), "combo-four knockback drifted")
	test.check(target.invulnerable > 0.0, "combo-four target did not enter hit invulnerability")

	var weapon_target = enemies[1]
	weapon_target.position = game.player.position + Vector2(90.0, 0.0)
	weapon_target.invulnerable = 0.0
	weapon_target.hurt_timer = 0.0
	var weapon_target_health: int = weapon_target.health
	game.player._reset_combo()
	game.player.combo_step = 3
	game.player.combo_window = 0.3
	game.player.finisher_armed = true
	game.player.attack_timer = 0.0
	game.player.weapon_hits = 1
	game.player._start_attack()
	test.check(game.player.attack_hitbox.center_offset == Vector2(44.0, 0.0), "weapon finisher reach center drifted")
	test.check(game.player.attack_hitbox.half_extents == Vector2(38.0, 28.0), "weapon finisher reach size drifted")
	game.player.attack_timer = game.player.current_attack.hit_trigger_remaining - 0.01
	game.player._check_attack_hit()
	test.check(weapon_target.health == weapon_target_health - 29, "weapon finisher damage drifted")
	test.check(game.player.weapon_hits == 0, "weapon finisher did not consume a weapon hit")
	test.check(target.health == target_health - 22, "invulnerable nearer target intercepted the next finisher")

	game.player.combo_step = 3
	game.player.combo_window = 0.25
	game.player.finisher_armed = true
	game.player.attack_buffer = 0.2
	game.player.attack_timer = 0.0
	game.player._handle_attack_intent()
	test.check(game.player.combo_step == 1 and game.player.current_attack.attack_id == &"player_combo_1", "missed finisher window did not restart the chain")

	game.player.combo_step = 3
	game.player.combo_window = 0.25
	game.player.finisher_armed = true
	game.player.attack_buffer = 0.2
	game.player.invulnerable = 0.0
	game.player.take_hit(1, Vector2.ZERO)
	test.check(game.player.combo_step == 0 and not game.player.finisher_armed and game.player.attack_buffer == 0.0, "taking damage retained combo state")
	game.player.hurt_timer = 0.0
	game.player.combo_step = 3
	game.player.combo_window = 0.25
	game.player.finisher_armed = true
	game.player.attack_buffer = 0.2
	game.player.special_timer = 0.0
	game.player._start_special()
	test.check(game.player.combo_step == 0 and not game.player.finisher_armed and game.player.attack_buffer == 0.0, "special attack retained combo state")
	await test.dispose(game)
