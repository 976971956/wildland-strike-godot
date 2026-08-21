extends RefCounted


func run(test) -> void:
	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.position.x = 500.0
	await test.wait_physics_frames(2)

	var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	test.check(enemies.size() == 3, "combat fixture failed to spawn three enemies")
	if enemies.size() < 3:
		await test.dispose(game)
		return

	var first_enemy = enemies[0]
	var second_enemy = enemies[1]
	first_enemy.position = Vector2(720.0, 540.0)
	second_enemy.position = Vector2(722.0, 540.0)
	var crowded_distance: float = first_enemy.position.distance_to(second_enemy.position)
	await test.wait_physics_frames(18)
	test.check(
		first_enemy.position.distance_to(second_enemy.position) > crowded_distance + 5.0,
		"nearby enemies failed to separate"
	)

	first_enemy.set_physics_process(false)
	var enemy_start_health: int = first_enemy.health
	first_enemy.take_hit(10, Vector2.ZERO, false)
	test.check(first_enemy.health == enemy_start_health - 10, "enemy damage was not applied")
	first_enemy.take_hit(10, Vector2.ZERO, false)
	test.check(first_enemy.health == enemy_start_health - 10, "enemy invulnerability did not reject a repeated hit")

	var player_start_health: int = game.player.health
	game.player.take_hit(8, Vector2.ZERO)
	test.check(game.player.health == player_start_health - 8, "player damage was not applied")
	game.player.take_hit(8, Vector2.ZERO)
	test.check(game.player.health == player_start_health - 8, "player invulnerability did not reject a repeated hit")
	await test.wait_physics_frames(40)
	game.player.take_hit(8, Vector2.ZERO)
	test.check(game.player.health == player_start_health - 16, "player did not become vulnerable after 0.65 seconds")

	var score_before_defeat: int = game.score
	second_enemy.take_hit(999, Vector2.ZERO, true)
	test.check(second_enemy.is_defeated, "lethal damage did not defeat enemy")
	test.check(game.score == score_before_defeat + 650, "raptor defeat score is incorrect")
	await test.dispose(game)
