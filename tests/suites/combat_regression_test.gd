extends RefCounted

const FighterStateMachineScript = preload("res://actors/fighters/fighter_state_machine.gd")


func run(test) -> void:
	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.position = Vector2(500.0, 540.0)
	await test.wait_physics_frames(2)
	var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	test.check(enemies.size() == 3, "combat-regression fixture failed to spawn")
	if enemies.size() < 3:
		await test.dispose(game)
		return
	for index in range(enemies.size()):
		enemies[index].set_physics_process(false)
		enemies[index].position = Vector2(1000.0 + index * 120.0, 620.0)

	var attacker = enemies[0]
	attacker.position = game.player.position + Vector2(64.0, 0.0)
	attacker.facing = -1
	attacker.attack_hit_done = false
	attacker.attack_timer = attacker.current_attack.hit_trigger_remaining - 0.01
	attacker.attack_hitbox.configure_circle(attacker.current_attack.circle_radius, attacker.facing)
	var player_health: int = game.player.health
	attacker._check_attack()
	test.check(game.player.health == player_health - attacker.current_attack.damage, "enemy hit damage drifted")
	test.check(game.player.velocity == Vector2(-240.0, 0.0), "enemy hit knockback drifted")
	test.check(game.player.fighter_state == FighterStateMachineScript.State.HURT, "enemy hit did not enter player hurt state")
	test.check(game.player.hurt_timer == 0.42 and game.player.invulnerable == 0.65, "player hurt or invulnerability timing drifted")
	test.check(attacker.attack_hit_done and not attacker.attack_hitbox.active, "enemy hit did not resolve exactly once")

	game.player.take_hit(99, Vector2.ZERO)
	test.check(game.player.health == player_health - attacker.current_attack.damage, "player invulnerability did not reject repeated hit")
	game.player.attack_timer = 0.0
	game.player.attack_hitbox.deactivate()
	game.player._physics_process(0.66)
	test.check(game.player.invulnerable == 0.0 and game.player.hurt_timer == 0.0, "player timers did not expire deterministically")
	player_health = game.player.health
	game.player.take_hit(7, Vector2(90.0, -10.0))
	test.check(game.player.health == player_health - 7, "player did not accept hit after invulnerability expired")
	test.check(game.player.velocity == Vector2(90.0, -10.0), "player direct knockback drifted")

	var target = enemies[1]
	target.position = game.player.position + Vector2(69.0, 0.0)
	target.attack_timer = 0.0
	target.attack_hit_done = true
	target.attack_hitbox.deactivate()
	var target_health: int = target.health
	game.player.hurt_timer = 0.0
	game.player.invulnerable = 0.0
	game.player.attack_timer = 0.0
	game.player.combo_window = 0.0
	game.player.facing = 1
	game.player._start_attack()
	game.player.attack_timer = game.player.current_attack.hit_trigger_remaining - 0.01
	game.player._check_attack_hit()
	test.check(target.health == target_health - 12, "player combo hit damage drifted")
	test.check(target.fighter_state == FighterStateMachineScript.State.HURT, "player hit did not enter enemy hurt state")
	test.check(target.velocity == Vector2(118.0, -35.0), "enemy recoil vector drifted")
	test.check(target.hurt_timer == 0.25 and target.stun_timer == 0.25, "enemy hit-stun timing drifted")
	test.check(target.invulnerable == 0.08, "enemy invulnerability timing drifted")
	test.check(not target.knockdown_state, "light hit incorrectly caused knockdown")

	target.take_hit(20, Vector2.ZERO, false)
	test.check(target.health == target_health - 12, "enemy invulnerability did not reject repeated hit")
	target._physics_process(0.09)
	test.check(target.invulnerable == 0.0, "enemy invulnerability did not expire deterministically")
	var health_after_light: int = target.health
	target.take_hit(5, Vector2(40.0, 0.0), false)
	test.check(target.health == health_after_light - 5, "enemy did not accept hit after invulnerability expired")

	target.invulnerable = 0.0
	target.take_hit(6, Vector2(430.0, -35.0), true)
	test.check(target.fighter_state == FighterStateMachineScript.State.KNOCKDOWN, "launch hit did not enter knockdown state")
	test.check(target.knockdown_state, "launch hit did not retain knockdown flag")
	test.check(target.hurt_timer == 0.46 and target.stun_timer == 0.46, "knockdown timing drifted")
	test.check(target.flash_timer == 0.13 and target.impact_squash == 0.28, "heavy-hit feedback timing drifted")
	test.check(target.velocity == Vector2(430.0, -35.0), "launch knockback drifted")

	var grab_target = enemies[2]
	if not grab_target.definition.can_be_grabbed:
		game.spawn_enemy(Vector2(1500.0, 540.0), "grunt")
		grab_target = test.tree.get_nodes_in_group("enemies")[-1]
		grab_target.set_physics_process(false)
	grab_target.hurt_timer = 0.0
	grab_target.grabbed_by(game.player)
	test.check(grab_target.grabbed and grab_target.fighter_state == FighterStateMachineScript.State.GRABBED, "grab state drifted")
	test.check(grab_target.stun_timer == 2.0, "grab hold stun timing drifted")
	grab_target.release_grab()
	test.check(not grab_target.grabbed and grab_target.fighter_state == FighterStateMachineScript.State.STUN, "grab release did not enter stun")
	test.check(grab_target.stun_timer == 0.25, "grab release stun timing drifted")

	target.invulnerable = 0.0
	var score_before: int = game.score
	var defeat_score: int = target.definition.defeat_score
	target.take_hit(999, Vector2(300.0, -20.0), true)
	test.check(target.is_defeated and target.health <= 0, "lethal enemy hit did not defeat target")
	test.check(target.fighter_state == FighterStateMachineScript.State.DEFEATED, "enemy defeat state drifted")
	test.check(not target.is_in_group("enemies"), "defeated enemy stayed targetable")
	test.check(game.score == score_before + defeat_score, "enemy defeat score drifted")
	test.check(
		target.death_timer == 0.75 and target.fall_velocity.is_equal_approx(Vector2(216.0, -14.4)),
		"enemy defeat motion drifted"
	)
	test.check(not target.attack_hitbox.active, "defeated enemy retained active hitbox")

	var defeated_signal_count := [0]
	game.player.defeated.connect(func(): defeated_signal_count[0] += 1)
	game.player.invulnerable = 0.0
	game.player.health = 5
	game.player.take_hit(10, Vector2(-120.0, 0.0))
	test.check(game.player.health == 0 and game.player.is_defeated, "lethal player hit did not clamp health and defeat")
	test.check(game.player.fighter_state == FighterStateMachineScript.State.DEFEATED, "player defeat state drifted")
	test.check(defeated_signal_count[0] == 1, "player defeat signal count drifted")
	game.player.take_hit(10, Vector2.ZERO)
	test.check(defeated_signal_count[0] == 1 and game.player.health == 0, "defeated player accepted another hit")
	game.player.revive(Vector2(430.0, 540.0))
	test.check(game.player.health == game.player.MAX_HEALTH and not game.player.is_defeated, "player revive did not restore combat state")
	test.check(game.player.fighter_state == FighterStateMachineScript.State.IDLE, "player revive did not force idle state")
	test.check(game.player.invulnerable == 2.2, "player revive invulnerability drifted")
	await test.dispose(game)
