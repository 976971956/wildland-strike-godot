extends RefCounted


func run(test) -> void:
	var game: Node = await test.instantiate_main()
	if game == null:
		return

	test.check(game.state == "title", "expected title state")
	game._start_game()
	await test.tree.process_frame
	test.check(game.state == "playing", "game did not enter playing state")
	test.check(game.player != null and game.player.health == 120, "player initialization failed")

	game.player.position.x = 500.0
	await test.wait_physics_frames(2)
	test.check(game.wave_active and game.remaining_enemies == 3, "first wave did not spawn")
	test.check(
		game.player.collision_layer == 1 and game.player.collision_mask == 2,
		"player collision layers are incorrect"
	)
	var spawned_enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	test.check(spawned_enemies.size() == 3, "expected three spawned enemies")
	if not spawned_enemies.is_empty():
		var first_enemy = spawned_enemies[0]
		test.check(
			first_enemy.collision_layer == 2 and first_enemy.collision_mask == 1,
			"enemy collision layers are incorrect"
		)

	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.take_hit(999, Vector2(300.0, 0.0), true)
	await test.wait_physics_frames(50)
	test.check(
		game.stage_index == 1,
		"wave clear progression failed (stage=%d, remaining=%d)" % [game.stage_index, game.remaining_enemies]
	)
	test.check(game.score == 1150, "score did not update for two raiders and one raptor")

	game.player.heal(10)
	game.player.give_weapon()
	test.check(game.player.weapon_hits == 12, "weapon pickup failed")
	await test.dispose(game)
