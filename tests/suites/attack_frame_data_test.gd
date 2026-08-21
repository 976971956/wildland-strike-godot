extends RefCounted

const AttackFrameDataScript = preload("res://core/combat/attack_frame_data.gd")
const ATTACKS := [
	preload("res://data/attacks/player_combo_1.tres"),
	preload("res://data/attacks/player_combo_2.tres"),
	preload("res://data/attacks/player_combo_3.tres"),
	preload("res://data/attacks/player_combo_4.tres"),
	preload("res://data/attacks/player_air.tres"),
	preload("res://data/attacks/player_run.tres"),
	preload("res://data/attacks/player_apex.tres"),
	preload("res://data/attacks/player_dive.tres"),
	preload("res://data/attacks/player_throw.tres"),
	preload("res://data/attacks/player_special.tres"),
	preload("res://data/attacks/enemy_grunt.tres"),
	preload("res://data/attacks/enemy_brute.tres"),
	preload("res://data/attacks/enemy_raptor.tres"),
	preload("res://data/attacks/enemy_boss.tres"),
]


func run(test) -> void:
	var attack_ids := {}
	for attack in ATTACKS:
		test.check(attack != null, "attack frame-data resource failed to load")
		test.check(attack.is_valid_frame_data(), "%s has invalid frame data" % attack.attack_id)
		test.check(not attack_ids.has(attack.attack_id), "%s is a duplicate attack id" % attack.attack_id)
		attack_ids[attack.attack_id] = true

	var combo_one = ATTACKS[0]
	var combo_three = ATTACKS[2]
	var combo_four = ATTACKS[3]
	var jump_attack = ATTACKS[4]
	var run_attack = ATTACKS[5]
	var apex_attack = ATTACKS[6]
	var dive_attack = ATTACKS[7]
	var throw_attack = ATTACKS[8]
	var special_attack = ATTACKS[9]
	var grunt_attack = ATTACKS[10]
	var boss_attack = ATTACKS[13]
	test.check(combo_one.duration == 0.26 and combo_one.hit_trigger_remaining == 0.18, "combo-one timing drifted")
	test.check(combo_one.damage == 12 and combo_one.knockback == Vector2(118, -35), "combo-one outcome drifted")
	test.check(combo_three.duration == 0.32 and not combo_three.launch, "combo bridge data drifted")
	test.check(combo_four.duration == 0.48 and combo_four.launch, "combo finisher data drifted")
	test.check(jump_attack.box_half_extents == Vector2(31, 28), "jump-attack reach drifted")
	test.check(run_attack.damage == 17 and run_attack.counter_hit_damage_bonus == 6, "run-attack outcome drifted")
	test.check(apex_attack.attack_id == &"player_apex_attack" and apex_attack.launch, "apex-attack data drifted")
	test.check(dive_attack.attack_id == &"player_dive_attack" and dive_attack.knockback == Vector2(500, -65), "dive-attack data drifted")
	test.check(throw_attack.knockback == Vector2(560, -80), "throw force drifted")
	test.check(special_attack.self_damage == 7 and special_attack.effect_radius == 115.0, "special cost or radius drifted")
	test.check(grunt_attack.damage == 8 and grunt_attack.circle_radius == 47.0, "grunt attack data drifted")
	test.check(boss_attack.damage == 18 and boss_attack.duration == 0.52, "boss attack data drifted")
	var weapon_geometry: Array[Vector2] = combo_one.box_geometry(true)
	test.check(weapon_geometry == [Vector2(40, 0), Vector2(34, 28)], "weapon reach data drifted")
	var invalid_attack = AttackFrameDataScript.new()
	test.check(not invalid_attack.is_valid_frame_data(), "empty frame data should be invalid")
	invalid_attack.attack_id = &"invalid_counter"
	invalid_attack.duration = 0.2
	invalid_attack.counter_hit_knockback_scale = 0.5
	test.check(not invalid_attack.is_valid_frame_data(), "invalid counter-hit scale should be rejected")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.position = Vector2(500.0, 540.0)
	await test.wait_physics_frames(2)
	var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	test.check(not enemies.is_empty(), "attack frame-data fixture failed to spawn")
	if not enemies.is_empty():
		for index in range(enemies.size()):
			enemies[index].set_physics_process(false)
			enemies[index].position = Vector2(1000.0 + index * 100.0, 620.0)
		var enemy = enemies[0]
		enemy.position = game.player.position + Vector2(69.0, 0.0)
		var enemy_health: int = enemy.health
		game.player.facing = 1
		game.player.combo_window = 0.0
		game.player._start_attack()
		test.check(game.player.current_attack.attack_id == &"player_combo_1", "player did not select combo-one data")
		test.check(game.player.attack_timer == combo_one.duration, "player did not use resource duration")
		game.player.attack_timer = 0.17
		game.player._check_attack_hit()
		test.check(enemy.health == enemy_health - combo_one.damage, "player did not use resource damage")
		test.check(not game.player.attack_hitbox.active, "resolved resource hitbox stayed active")

		game.player.attack_timer = 0.0
		game.player.combo_window = 0.4
		game.player.z_height = 20.0
		game.player.z_velocity = 250.0
		game.player._start_attack()
		test.check(game.player.current_attack.attack_id == &"player_jump_attack", "player did not select jump-attack data")
		test.check(game.player.combo_window == 0.0, "jump attack retained a ground combo window")
		game.player.z_height = 0.0
		game.player.z_velocity = 0.0

		enemy.invulnerable = 0.0
		enemy.hurt_timer = 0.0
		enemy.position = game.player.position + Vector2(90.0, 0.0)
		enemy_health = enemy.health
		game.player.attack_timer = 0.0
		game.player.combo_window = 0.0
		game.player.weapon_hits = 1
		game.player._start_attack()
		test.check(game.player.attack_hitbox.center_offset == Vector2(40, 0), "weapon hitbox did not use resource geometry")
		game.player.attack_timer = 0.17
		game.player._check_attack_hit()
		test.check(enemy.health == enemy_health - combo_one.damage - combo_one.weapon_bonus_damage, "weapon bonus did not use resource data")
		test.check(game.player.weapon_hits == 0, "weapon hit was not consumed")

		enemy.invulnerable = 0.0
		enemy.hurt_timer = 0.0
		enemy.position = game.player.position + Vector2(100.0, 0.0)
		enemy_health = enemy.health
		var player_health: int = game.player.health
		game.player.attack_timer = 0.0
		game.player.special_timer = 0.0
		game.player._start_special()
		test.check(game.player.current_attack.attack_id == &"player_special", "player did not select special data")
		test.check(game.player.health == player_health - special_attack.self_damage, "special did not use resource self-cost")
		test.check(enemy.health == enemy_health - special_attack.damage, "special did not use resource damage")
	await test.dispose(game)
