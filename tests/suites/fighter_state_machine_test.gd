extends RefCounted

const FighterStateMachineScript = preload("res://actors/fighters/fighter_state_machine.gd")


func run(test) -> void:
	var machine = FighterStateMachineScript.new()
	test.check(machine.current_state == FighterStateMachineScript.State.IDLE, "state machine should start idle")
	machine.tick(0.25)
	test.check(is_equal_approx(machine.elapsed, 0.25), "state elapsed time did not advance")
	test.check(machine.transition(FighterStateMachineScript.State.ATTACK), "idle-to-attack transition failed")
	test.check(machine.previous_state == FighterStateMachineScript.State.IDLE, "previous state was not retained")
	test.check(machine.revision == 1 and machine.elapsed == 0.0, "transition revision or elapsed reset is incorrect")
	machine.transition(FighterStateMachineScript.State.DEFEATED)
	test.check(not machine.transition(FighterStateMachineScript.State.IDLE), "defeated state should reject ordinary transitions")
	test.check(machine.force_transition(FighterStateMachineScript.State.IDLE), "forced revive transition failed")
	test.check(FighterStateMachineScript.state_name(machine.current_state) == "IDLE", "state name lookup failed")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	test.check(game.player.fighter_state == FighterStateMachineScript.State.IDLE, "player did not initialize idle")
	game._start_game()
	game.player._start_attack()
	test.check(game.player.fighter_state == FighterStateMachineScript.State.ATTACK, "player attack state was not explicit")
	game.player.take_hit(8, Vector2.ZERO)
	test.check(game.player.fighter_state == FighterStateMachineScript.State.HURT, "player hurt state was not explicit")
	game.player.hurt_timer = 0.0
	game.player.invulnerable = 0.0
	game.player._start_special()
	test.check(game.player.fighter_state == FighterStateMachineScript.State.SPECIAL, "player special state was not explicit")
	game.player.special_timer = 0.0
	game.player.attack_timer = 0.0
	game.player.z_height = 20.0
	game.player._sync_fighter_state()
	test.check(game.player.fighter_state == FighterStateMachineScript.State.AIRBORNE, "player airborne state was not explicit")
	game.player.z_height = 0.0

	game.player.position.x = 500.0
	await test.wait_physics_frames(2)
	var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	test.check(not enemies.is_empty(), "enemy state fixture failed to spawn")
	if not enemies.is_empty():
		var enemy = enemies[0]
		enemy.set_physics_process(false)
		enemy.take_hit(5, Vector2.ZERO, false)
		test.check(enemy.fighter_state == FighterStateMachineScript.State.HURT, "enemy hurt state was not explicit")
		enemy.grabbed_by(game.player)
		test.check(enemy.fighter_state == FighterStateMachineScript.State.GRABBED, "enemy grabbed state was not explicit")
		game.player.grabbed_enemy = enemy
		game.player._sync_fighter_state()
		test.check(game.player.fighter_state == FighterStateMachineScript.State.GRAB_HOLD, "player grab-hold state was not explicit")
		game.player.grabbed_enemy = null
		enemy.release_grab()
		test.check(enemy.fighter_state == FighterStateMachineScript.State.STUN, "enemy release stun state was not explicit")
		enemy.invulnerable = 0.0
		enemy.take_hit(5, Vector2.ZERO, true)
		test.check(enemy.fighter_state == FighterStateMachineScript.State.KNOCKDOWN, "enemy knockdown state was not explicit")
	await test.dispose(game)
