extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error("SMOKE TEST: " + message)

func _run() -> void:
	var scene: PackedScene = load("res://main.tscn")
	check(scene != null, "main scene failed to load")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.state == "title", "expected title state")
	game._start_game()
	await process_frame
	check(game.state == "playing", "game did not enter playing state")
	check(game.player != null and game.player.health == 120, "player initialization failed")
	game.player.position.x = 500.0
	await process_frame
	check(game.wave_active and game.remaining_enemies == 3, "first wave did not spawn")
	# Let actors run briefly so visual smoke captures contain live combat poses.
	await create_timer(0.5).timeout
	for enemy in get_nodes_in_group("enemies"):
		enemy.take_hit(999, Vector2(300,0), true)
	await create_timer(0.9).timeout
	check(game.stage_index == 1, "wave clear progression failed (stage=%d, remaining=%d)" % [game.stage_index, game.remaining_enemies])
	check(game.score == 1150, "score did not update for two raiders and one raptor")
	game.player.heal(10)
	game.player.give_weapon()
	check(game.player.weapon_hits == 12, "weapon pickup failed")
	if failed:
		game.queue_free()
		await process_frame
		quit(1)
	else:
		print("SMOKE TEST PASSED: title, player, combat wave, score, rewards")
		game.queue_free()
		await process_frame
		quit(0)
