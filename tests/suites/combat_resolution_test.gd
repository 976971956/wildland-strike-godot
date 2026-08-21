extends RefCounted

const AttackPriorityRulesScript = preload("res://core/combat/attack_priority_rules.gd")
const FighterStateMachineScript = preload("res://actors/fighters/fighter_state_machine.gd")
const COMBO_ONE = preload("res://data/attacks/player_combo_1.tres")
const RUN_ATTACK = preload("res://data/attacks/player_run.tres")
const COMMAND_ATTACK = preload("res://data/attacks/player_command.tres")


func run(test) -> void:
	test.check(COMBO_ONE.priority == 1 and RUN_ATTACK.priority == 3 and COMMAND_ATTACK.priority == 4, "player priority tiers drifted")
	test.check(COMMAND_ATTACK.max_hits == 2 and COMMAND_ATTACK.damage * COMMAND_ATTACK.max_hits == 24, "command multi-hit total drifted")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.set_physics_process(false)
	game.player.position = Vector2(500.0, 540.0)
	await test.wait_physics_frames(2)
	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.position = Vector2(1350.0, 650.0)

	var priority_target = _spawn_enemy(game, "grunt", Vector2(569.0, 540.0))
	priority_target.health = 200
	priority_target.attack_timer = priority_target.current_attack.duration
	priority_target.attack_hit_done = false
	priority_target.attack_hitbox.configure_circle(priority_target.current_attack.circle_radius, -1)
	game.player.facing = 1
	game.player.combo_window = 0.0
	game.player.attack_timer = 0.0
	game.player._start_attack()
	game.player.attack_timer = COMBO_ONE.hit_trigger_remaining - 0.01
	var priority_health: int = priority_target.health
	game.player._check_attack_hit()
	test.check(priority_target.health == priority_health, "low-priority combo damaged a higher-priority startup")
	test.check(game.player.attack_timer == 0.0 and game.player.fighter_state == FighterStateMachineScript.State.STUN, "losing priority did not recoil player")
	test.check(priority_target.attack_timer == priority_target.current_attack.duration, "winning defender attack was interrupted")

	game.player.hurt_timer = 0.0
	game.player.current_attack = RUN_ATTACK
	game.player.attack_hit_done = false
	game.player.attack_timer = RUN_ATTACK.hit_trigger_remaining - 0.01
	game.player.next_hit_remaining = RUN_ATTACK.hit_trigger_remaining
	game.player.attack_hits_resolved = 0
	game.player._configure_attack_hitbox()
	priority_target.invulnerable = 0.0
	priority_target.hurt_timer = 0.0
	priority_target.attack_timer = priority_target.current_attack.duration
	priority_target.attack_hit_done = false
	priority_target.attack_hitbox.configure_circle(priority_target.current_attack.circle_radius, -1)
	priority_health = priority_target.health
	game.player._check_attack_hit()
	test.check(priority_target.health == priority_health - 23, "higher-priority run attack lost its counter-hit bonus")
	test.check(priority_target.last_hit_was_counter and priority_target.attack_timer == 0.0, "priority win did not interrupt defender startup")
	priority_target.position = Vector2(1250.0, 650.0)

	var trade_target = _spawn_enemy(game, "brute", Vector2(580.0, 540.0))
	trade_target.health = 200
	trade_target.attack_timer = trade_target.current_attack.duration
	trade_target.attack_hit_done = false
	trade_target.attack_hitbox.configure_circle(trade_target.current_attack.circle_radius, -1)
	game.player.current_attack = RUN_ATTACK
	game.player.attack_hit_done = false
	game.player.attack_hits_resolved = 0
	game.player.next_hit_remaining = RUN_ATTACK.hit_trigger_remaining
	game.player.attack_timer = RUN_ATTACK.hit_trigger_remaining - 0.01
	game.player._configure_attack_hitbox()
	game.player._check_attack_hit()
	test.check(trade_target.health == 183 and not trade_target.last_hit_was_counter, "equal-priority trade received counter damage")
	test.check(trade_target.attack_timer == trade_target.current_attack.duration, "equal-priority trade interrupted defender")
	trade_target.position = Vector2(1250.0, 650.0)

	var losing_attacker = _spawn_enemy(game, "grunt", Vector2(555.0, 540.0))
	losing_attacker.facing = -1
	losing_attacker.attack_timer = losing_attacker.current_attack.hit_trigger_remaining - 0.01
	losing_attacker.attack_hit_done = false
	losing_attacker.attack_hitbox.configure_circle(losing_attacker.current_attack.circle_radius, -1)
	game.player.current_attack = RUN_ATTACK
	game.player.attack_timer = RUN_ATTACK.duration
	game.player.attack_hit_done = false
	game.player._configure_attack_hitbox()
	game.player.invulnerable = 0.0
	var player_health: int = game.player.health
	losing_attacker._check_attack()
	test.check(game.player.health == player_health, "lower-priority enemy attack damaged player startup")
	test.check(losing_attacker.attack_timer == 0.0 and losing_attacker.fighter_state == FighterStateMachineScript.State.STUN, "losing enemy priority did not recoil")
	losing_attacker.position = Vector2(1250.0, 650.0)

	var multi_target = _spawn_enemy(game, "brute", Vector2(580.0, 540.0))
	multi_target.health = 200
	game.player.attack_timer = 0.0
	game.player.hurt_timer = 0.0
	game.player._start_command_attack()
	game.player.attack_timer = COMMAND_ATTACK.hit_trigger_remaining - 0.01
	game.player._check_attack_hit()
	test.check(multi_target.health == 188 and game.player.attack_hits_resolved == 1, "command first pulse drifted")
	test.check(not game.player.attack_hit_done and game.player.attack_hitbox.active, "command first pulse closed the attack")
	test.check(not multi_target.knockdown_state and multi_target.velocity == Vector2(196.0, -24.5), "command first pulse launched target out of follow-up range")
	multi_target.invulnerable = 0.0
	game.player.attack_timer = game.player.next_hit_remaining - 0.01
	game.player._check_attack_hit()
	test.check(multi_target.health == 176 and game.player.attack_hits_resolved == 2, "command second pulse drifted")
	test.check(game.player.attack_hit_done and not game.player.attack_hitbox.active, "command multi-hit did not close after configured count")
	test.check(multi_target.knockdown_state and multi_target.velocity == Vector2(560.0, -70.0), "command final pulse did not launch")
	game.player._check_attack_hit()
	test.check(multi_target.health == 176, "completed multi-hit dealt an extra pulse")
	multi_target.position = Vector2(1250.0, 650.0)

	var chain_target = _spawn_enemy(game, "brute", Vector2(700.0, 540.0))
	chain_target.health = 300
	for hit_index in range(6):
		chain_target.invulnerable = 0.0
		chain_target.take_hit(5, Vector2(90.0, 0.0), false)
		test.check(chain_target.chain_hit_count == hit_index + 1, "chain counter drifted at hit %d" % (hit_index + 1))
	test.check(chain_target.hard_knockdown_lockout and chain_target.knockdown_state, "chain cap did not force hard knockdown")
	test.check(chain_target.velocity.y == -45.0, "anti-infinite knockdown lost minimum launch")
	chain_target.invulnerable = 0.0
	var locked_health: int = chain_target.health
	chain_target.take_hit(99, Vector2.ZERO, false)
	test.check(chain_target.health == locked_health, "hard knockdown accepted an infinite follow-up")
	game.player.is_defeated = true
	chain_target._physics_process(0.47)
	test.check(chain_target.hard_knockdown_lockout and chain_target.fighter_state == FighterStateMachineScript.State.GET_UP, "anti-infinite lockout ended before get-up")
	chain_target._physics_process(0.39)
	test.check(not chain_target.hard_knockdown_lockout and chain_target.chain_hit_count == 0, "get-up did not reset anti-infinite state")
	chain_target.invulnerable = 0.0
	chain_target.take_hit(5, Vector2.ZERO, false)
	test.check(chain_target.health == locked_health - 5 and chain_target.chain_hit_count == 1, "post-get-up target did not accept a fresh chain")
	chain_target.position = Vector2(1250.0, 650.0)

	game.player.position = Vector2(900.0, 540.0)
	var wall_target = _spawn_enemy(game, "brute", Vector2(65.0, 540.0))
	wall_target.health = 200
	wall_target.grabbed_by(game.player)
	wall_target.thrown(22, Vector2(-560.0, -80.0), 8)
	wall_target._physics_process(0.03)
	test.check(wall_target.health == 170, "wall impact did not add configured collision damage")
	test.check(wall_target.wall_collision_done and not wall_target.throw_collision_active, "wall collision did not resolve exactly once")
	test.check(wall_target.position.x == 60.0 and wall_target.velocity.x > 0.0, "wall impact did not clamp and rebound")

	var thrown_target = _spawn_enemy(game, "brute", Vector2(500.0, 540.0))
	var collision_target = _spawn_enemy(game, "brute", Vector2(530.0, 540.0))
	thrown_target.health = 200
	collision_target.health = 200
	thrown_target.grabbed_by(game.player)
	thrown_target.thrown(22, Vector2(560.0, -80.0), 10)
	test.check(thrown_target != collision_target and thrown_target.throw_collision_active, "throw collision fixture did not arm")
	test.check(thrown_target.knockdown_state and thrown_target.position.distance_to(collision_target.position) < 48.0, "throw collision fixture geometry drifted")
	thrown_target._resolve_throw_collisions()
	test.check(collision_target.health == 190 and collision_target.knockdown_state, "thrown enemy did not damage and launch collision target")
	test.check(not thrown_target.throw_collision_active and thrown_target.throw_collision_targets.has(collision_target.get_instance_id()), "throw collision was not consumed")

	collision_target.attack_timer = collision_target.current_attack.duration
	collision_target.attack_hit_done = false
	test.check(
		AttackPriorityRulesScript.resolve(COMBO_ONE, collision_target) == AttackPriorityRulesScript.Outcome.LOSE,
		"priority resolver result drifted"
	)
	await test.dispose(game)


func _spawn_enemy(game: Node, type: String, position: Vector2) -> Node:
	game.spawn_enemy(position, type)
	var enemy: Node = game.get_tree().get_nodes_in_group("enemies")[-1]
	enemy.set_physics_process(false)
	return enemy
