extends RefCounted

const CounterHitRulesScript = preload("res://core/combat/counter_hit_rules.gd")
const RUN_ATTACK = preload("res://data/attacks/player_run.tres")
const JUMP_ATTACK = preload("res://data/attacks/player_air.tres")
const APEX_ATTACK = preload("res://data/attacks/player_apex.tres")
const DIVE_ATTACK = preload("res://data/attacks/player_dive.tres")
const COMBO_ONE = preload("res://data/attacks/player_combo_1.tres")


func run(test) -> void:
	for attack in [RUN_ATTACK, JUMP_ATTACK, APEX_ATTACK, DIVE_ATTACK]:
		test.check(attack != null and attack.is_valid_frame_data(), "%s failed frame-data validation" % attack.attack_id)
	test.check(RUN_ATTACK.counter_hit_launch and not RUN_ATTACK.launch, "run attack lost counter-only launch")
	test.check(JUMP_ATTACK.counter_hit_launch and not JUMP_ATTACK.launch, "jump attack lost counter-only launch")
	test.check(APEX_ATTACK.launch and DIVE_ATTACK.launch, "apex or dive attack lost guaranteed launch")
	test.check(DIVE_ATTACK.vertical_velocity_override == -620.0, "dive-attack vertical override drifted")
	test.check(CounterHitRulesScript.damage_for(RUN_ATTACK, false) == 17, "normal run-attack damage rule drifted")
	test.check(CounterHitRulesScript.damage_for(RUN_ATTACK, true) == 23, "counter run-attack damage rule drifted")
	test.check(
		CounterHitRulesScript.knockback_for(RUN_ATTACK, -1, true) == Vector2(-487.5, -37.5),
		"counter run-attack knockback rule drifted"
	)

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.set_physics_process(false)
	game.player.position = Vector2(500.0, 540.0)
	await test.wait_physics_frames(2)
	var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	test.check(enemies.size() >= 3, "aerial-combat fixture failed to spawn targets")
	if enemies.size() < 3:
		await test.dispose(game)
		return
	for index in range(enemies.size()):
		enemies[index].set_physics_process(false)
		enemies[index].position = Vector2(1200.0 + index * 120.0, 620.0)

	_start_player_run(game.player)
	game.player._start_attack()
	test.check(game.player.current_attack == RUN_ATTACK, "running player did not select run attack")
	test.check(not game.player.is_running and game.player.combo_step == 0, "run attack did not cancel run and ground combo")
	test.check(game.player.attack_lunge == 420.0, "run-attack lunge drifted")
	test.check(game.player._visual_frame() == Vector2i(4, 1), "run-attack visual frame drifted")

	game.player.attack_timer = 0.0
	game.player.z_height = 50.0
	game.player.z_velocity = 250.0
	game.player._start_attack()
	test.check(game.player.current_attack == JUMP_ATTACK, "rising jump did not select jump attack")
	test.check(game.player._visual_frame() == Vector2i(1, 2), "jump-attack visual frame drifted")

	game.player.attack_timer = 0.0
	game.player.z_height = 80.0
	game.player.z_velocity = 40.0
	game.player._start_attack()
	test.check(game.player.current_attack == APEX_ATTACK, "jump apex did not select apex attack")
	test.check(game.player._visual_frame() == Vector2i(3, 2), "apex-attack visual frame drifted")

	game.player.attack_timer = 0.0
	game.player.z_height = 60.0
	game.player.z_velocity = -200.0
	game.player._start_attack()
	test.check(game.player.current_attack == DIVE_ATTACK, "descending jump did not select dive attack")
	test.check(game.player.z_velocity == -620.0, "dive attack did not force its descent velocity")
	test.check(game.player._visual_frame() == Vector2i(4, 2), "dive-attack visual frame drifted")

	var idle_target = enemies[0]
	idle_target.position = game.player.position + Vector2(80.0, 0.0)
	idle_target.invulnerable = 0.0
	idle_target.hurt_timer = 0.0
	idle_target.attack_timer = 0.0
	var idle_health: int = idle_target.health
	game.player.z_height = 0.0
	game.player.z_velocity = 0.0
	game.player.attack_timer = 0.0
	game.player.facing = 1
	_start_player_run(game.player)
	game.player._start_attack()
	game.player.attack_timer = RUN_ATTACK.hit_trigger_remaining - 0.01
	game.player._check_attack_hit()
	test.check(idle_target.health == idle_health - RUN_ATTACK.damage, "normal run attack received counter damage")
	test.check(not idle_target.last_hit_was_counter and not idle_target.knockdown_state, "idle target was marked or launched as a counter")
	test.check(idle_target.velocity == RUN_ATTACK.knockback, "normal run-attack knockback drifted")

	var counter_target = enemies[1]
	counter_target.position = game.player.position + Vector2(80.0, 0.0)
	counter_target.invulnerable = 0.0
	counter_target.hurt_timer = 0.0
	counter_target.attack_timer = counter_target.current_attack.duration
	counter_target.attack_hit_done = false
	counter_target.attack_hitbox.configure_circle(counter_target.current_attack.circle_radius, -1)
	var counter_health: int = counter_target.health
	game.player.attack_timer = 0.0
	_start_player_run(game.player)
	game.player._start_attack()
	test.check(CounterHitRulesScript.is_counterable(counter_target), "enemy startup was not counterable")
	game.player.attack_timer = RUN_ATTACK.hit_trigger_remaining - 0.01
	game.player._check_attack_hit()
	test.check(counter_target.health == counter_health - 23, "run counter-hit damage drifted")
	test.check(counter_target.last_hit_was_counter and counter_target.knockdown_state, "run counter did not mark and launch target")
	test.check(counter_target.velocity == Vector2(487.5, -37.5), "run counter-hit knockback drifted")
	test.check(is_equal_approx(counter_target.hurt_timer, 0.58) and is_equal_approx(counter_target.stun_timer, 0.58), "run counter-hit stun drifted")
	test.check(counter_target.attack_timer == 0.0 and counter_target.attack_hit_done, "counter hit did not interrupt enemy startup")
	test.check(not counter_target.attack_hitbox.active, "countered enemy retained an active hitbox")

	counter_target.hurt_timer = 0.0
	counter_target.attack_timer = counter_target.current_attack.hit_trigger_remaining
	counter_target.attack_hit_done = false
	test.check(not CounterHitRulesScript.is_counterable(counter_target), "active-frame boundary was incorrectly counterable")
	counter_target.attack_timer = counter_target.current_attack.duration
	counter_target.attack_hit_done = true
	test.check(not CounterHitRulesScript.is_counterable(counter_target), "resolved attack was incorrectly counterable")

	var attacker = enemies[2]
	attacker.position = game.player.position + Vector2(55.0, 0.0)
	attacker.facing = -1
	attacker.attack_timer = attacker.current_attack.hit_trigger_remaining - 0.01
	attacker.attack_hit_done = false
	attacker.attack_hitbox.configure_circle(attacker.current_attack.circle_radius, attacker.facing)
	game.player.invulnerable = 0.0
	game.player.hurt_timer = 0.0
	game.player.attack_timer = COMBO_ONE.duration
	game.player.current_attack = COMBO_ONE
	game.player.attack_hit_done = false
	game.player._configure_attack_hitbox()
	var player_health: int = game.player.health
	attacker._check_attack()
	test.check(game.player.health == player_health - attacker.current_attack.damage - attacker.current_attack.counter_hit_damage_bonus, "enemy counter-hit damage drifted")
	test.check(game.player.last_hit_was_counter, "player was not marked as counter-hit")
	test.check(game.player.attack_timer == 0.0 and not game.player.attack_hitbox.active, "enemy counter did not interrupt player startup")
	test.check(game.player.hurt_timer == 0.42 + attacker.current_attack.counter_hit_stun_bonus, "player counter-hit stun drifted")
	await test.dispose(game)
func _start_player_run(player: Node) -> void:
	player.run_controller.cancel()
	player.run_controller.update(Vector2.RIGHT)
	player.run_controller.update(Vector2.ZERO)
	player.run_controller.tick(0.1)
	player.run_controller.update(Vector2.RIGHT)
