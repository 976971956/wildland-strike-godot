extends RefCounted

const FighterIntentScript = preload("res://core/input/fighter_intent.gd")


func run(test) -> void:
	var game: Node = await test.instantiate_main()
	if game == null:
		return
	var second: Node = game.join_local_player(0, 1)
	test.check(second != null, "co-op revive fixture could not join player two")
	game._start_game()
	game.set_process(false)
	game.player.set_physics_process(false)
	second.set_physics_process(false)
	game.player.position = Vector2(500.0, 550.0)
	second.position = Vector2(570.0, 550.0)

	second.invulnerable = 0.0
	second.take_hit(second.max_health, Vector2.ZERO)
	test.check(second.is_defeated and game.downed_time_remaining.has(1), "defeated teammate did not enter the revive window")
	test.check(is_equal_approx(float(game.downed_time_remaining[1]), game.TEAMMATE_REVIVE_WINDOW), "teammate revive window duration drifted")
	test.check(game.local_player_registry.slot_at(1).remaining_lives == 2, "entering the revive window consumed a continue immediately")
	test.check(game.hud.local_player_states[1].down and float(game.hud.local_player_states[1].down_time) > 0.0, "HUD did not expose teammate down state and countdown")

	game.player.position = Vector2(350.0, 550.0)
	test.check(not game.try_revive_teammate(game.player), "revive succeeded outside the interaction radius")
	game.player.position = Vector2(500.0, 550.0)
	var rescue_intent = FighterIntentScript.new(Vector2.ZERO, false, true, false)
	game.player._apply_intent(rescue_intent)
	var expected_revive_health := roundi(second.max_health * game.TEAMMATE_REVIVE_HEALTH_RATIO)
	test.check(not second.is_defeated and second.health == expected_revive_health, "nearby attack input did not revive teammate at 35% health")
	test.check(not game.downed_time_remaining.has(1) and not game.continue_respawn_time.has(1), "successful revive left stale down/continue state")
	test.check(game.local_player_registry.slot_at(1).remaining_lives == 2, "successful teammate revive consumed a continue")
	test.check(second.invulnerable > 2.0 and second.is_physics_processing(), "revived teammate did not receive safe control recovery")
	test.check(game.sfx_event_history.has(&"revive"), "teammate revive feedback cue did not fire")

	second.set_physics_process(false)
	second.invulnerable = 0.0
	second.take_hit(second.max_health, Vector2.ZERO)
	game._tick_downed_players(game.TEAMMATE_REVIVE_WINDOW)
	test.check(game.local_player_registry.slot_at(1).remaining_lives == 1, "expired revive window did not consume player two's own continue")
	test.check(game.continue_respawn_time.has(1) and second.is_defeated, "expired teammate did not enter the continue countdown")
	test.check(is_equal_approx(float(game.continue_respawn_time[1]), game.CONTINUE_RESPAWN_DELAY), "continue countdown duration drifted")
	test.check(game._confirm_continue_for_slot(1), "player two could not accept the continue offer")
	test.check(not second.is_defeated and second.health == second.max_health, "player two continue did not restore full health")
	test.check(not game.continue_respawn_time.has(1), "completed continue retained stale respawn state")
	test.check(game.local_player_registry.slot_at(0).remaining_lives == 2 and game.lives == 2, "player two death consumed player one's lives")

	second.set_physics_process(false)
	second.invulnerable = 0.0
	game.local_player_registry.slot_at(1).remaining_lives = 0
	second.take_hit(second.max_health, Vector2.ZERO)
	game._tick_downed_players(game.TEAMMATE_REVIVE_WINDOW)
	test.check(game.local_player_registry.slot_at(1).remaining_lives == -1 and not game.continue_respawn_time.has(1), "exhausted secondary player received an extra continue")
	test.check(game.state == "playing" and is_equal_approx(float(game.hud.local_player_states[1].down_time), -2.0), "one eliminated teammate incorrectly ended a surviving player's run")

	game.player.invulnerable = 0.0
	game.player.take_hit(game.player.max_health, Vector2.ZERO)
	game._tick_downed_players(0.01)
	test.check(game.lives == 1 and game.continue_respawn_time.has(0), "all-down fallback did not schedule player one's available continue")
	test.check(game.state == "playing", "team game-over triggered while a continue was pending")
	game._confirm_continue_for_slot(0)
	test.check(not game.player.is_defeated and game.get_active_players() == [game.player], "pending continue did not recover the last available teammate")

	game.player.set_physics_process(false)
	game.player.invulnerable = 0.0
	game.local_player_registry.slot_at(0).remaining_lives = 0
	game.lives = 0
	game.player.take_hit(game.player.max_health, Vector2.ZERO)
	game._tick_downed_players(0.01)
	test.check(game.lives == -1 and game.state == "gameover", "team game-over did not wait for every player's continues to be exhausted")
	test.check(game.hud.mode == "gameover", "team game-over did not reach the HUD")
	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(probe_source.contains("coop_revive_preview=1"), "reproducible co-op revive Web preview is missing")
	await test.dispose(game)
