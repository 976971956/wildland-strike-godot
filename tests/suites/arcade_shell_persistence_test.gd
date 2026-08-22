extends RefCounted

const ArcadeProfileScript = preload("res://core/persistence/arcade_profile.gd")


func run(test) -> void:
	var profile_path := "/tmp/wildland_arcade_profile_test.cfg"
	if FileAccess.file_exists(profile_path):
		DirAccess.remove_absolute(profile_path)
	var profile = ArcadeProfileScript.new(profile_path)
	test.check(profile.load_profile() == OK, "fresh arcade profile did not load defaults")
	test.check(profile.loaded_version == profile.CURRENT_VERSION, "fresh profile version drifted")
	test.check(is_equal_approx(float(profile.settings.music_volume), 0.8) and is_equal_approx(float(profile.settings.sfx_volume), 0.9), "default audio settings drifted")
	test.check(profile.settings.screen_shake and profile.settings.hit_flash and profile.settings.haptics, "default accessibility feedback settings drifted")
	test.check(int(profile.bindings.attack) == KEY_J and int(profile.bindings.pause) == KEY_P, "default rebindable controls drifted")
	test.check(profile.high_scores.is_empty() and profile.top_score() == 0, "fresh profile created phantom high scores")

	profile.set_setting("music_volume", 2.0)
	profile.set_setting("sfx_volume", -1.0)
	profile.set_setting("language", "unsupported")
	profile.set_binding("attack", KEY_F)
	test.check(is_equal_approx(float(profile.settings.music_volume), 1.0) and is_zero_approx(float(profile.settings.sfx_volume)), "profile did not clamp audio settings")
	test.check(profile.settings.language == "en" and not profile.set_setting("unknown", true), "profile did not normalize language/unknown keys")
	for index in range(12):
		profile.record_score(1000 + index * 250, (index % 8) + 1, (index % 3) + 1, "operative_%d" % index)
	test.check(profile.high_scores.size() == 10, "local high-score table did not trim to ten entries")
	test.check(profile.top_score() == 3750 and int(profile.high_scores[9].score) == 1500, "local high scores are not sorted descending")
	test.check(String(profile.high_scores[0].name).length() <= 12, "high-score operative name was not bounded")
	test.check(profile.save_profile() == OK and FileAccess.file_exists(profile_path), "versioned arcade profile did not save")

	var reloaded = ArcadeProfileScript.new(profile_path)
	test.check(reloaded.load_profile() == OK and reloaded.loaded_version == reloaded.CURRENT_VERSION, "saved profile did not reload at the current version")
	test.check(reloaded.high_scores == profile.high_scores and reloaded.settings == profile.settings and int(reloaded.bindings.attack) == KEY_F, "profile round-trip changed settings, scores, or bindings")

	var legacy := ConfigFile.new()
	legacy.set_value("audio", "music_percent", 55.0)
	legacy.set_value("audio", "sfx_percent", 65.0)
	legacy.set_value("accessibility", "shake", false)
	legacy.set_value("accessibility", "flash", false)
	legacy.set_value("mobile", "haptics", false)
	legacy.set_value("scores", "entries", [{"name": "OLD", "score": 777, "stage": 3, "players": 2}])
	legacy.save(profile_path)
	var migrated = ArcadeProfileScript.new(profile_path)
	test.check(migrated.load_profile() == OK and migrated.loaded_version == migrated.CURRENT_VERSION, "legacy profile migration failed")
	test.check(is_equal_approx(float(migrated.settings.music_volume), 0.55) and is_equal_approx(float(migrated.settings.sfx_volume), 0.65), "legacy audio percentages did not migrate")
	test.check(not migrated.settings.screen_shake and not migrated.settings.hit_flash and not migrated.settings.haptics, "legacy feedback settings did not migrate")
	test.check(migrated.high_scores.size() == 1 and int(migrated.high_scores[0].score) == 777, "legacy score entry did not migrate")
	DirAccess.remove_absolute(profile_path)

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	test.check(game.state == "title" and game.hud.profile_high_scores.is_empty(), "arcade shell did not initialize at the title with its profile")
	game._process(game.ATTRACT_DELAY)
	test.check(game.state == "attract" and game.hud.mode == "attract", "idle title did not enter attract mode")
	game._return_to_title()
	game._open_high_scores()
	test.check(game.state == "high_scores" and game.hud.mode == "high_scores", "high-score screen did not open")
	game._return_to_title()

	game._open_options("title")
	test.check(game.state == "options" and game.hud.mode == "options" and not test.tree.paused, "title options did not open safely")
	var initial_music := float(game.settings.music_volume)
	game.options_selected_index = 0
	game._adjust_option(-1)
	test.check(float(game.settings.music_volume) < initial_music and is_equal_approx(game.music_director.master_volume_ratio, float(game.settings.music_volume)), "music option did not apply to the director")
	game.options_selected_index = 5
	game._adjust_option(1)
	test.check(not game.settings.screen_shake and game.hit_flash_enabled(), "screen-shake option did not toggle independently")
	game.options_selected_index = 9
	game._adjust_option(1)
	test.check(game.state == "controls" and game.hud.mode == "controls", "options did not open the control-remapping screen")
	game.control_selected_index = 4
	game._begin_control_rebind()
	test.check(game.pending_rebind_action == "attack" and game._commit_control_rebind(KEY_F), "attack binding did not enter and commit capture")
	var rebound_attack := InputMap.action_get_events("attack").filter(func(event): return event is InputEventKey)
	test.check(rebound_attack.size() == 1 and int(rebound_attack[0].physical_keycode) == KEY_F, "committed attack binding did not reach InputMap")
	game._return_to_options()
	game._close_options()
	test.check(game.state == "title" and not test.tree.paused, "closing title options did not return safely")

	game._start_game()
	game._open_options("playing")
	test.check(game.state == "options" and test.tree.paused and game.hud.option_return_to_game, "gameplay pause/options did not pause the scene tree")
	game._close_options()
	test.check(game.state == "playing" and not test.tree.paused and game.player.is_physics_processing(), "closing gameplay options did not resume simulation")

	game.set_process(false)
	game.player.set_physics_process(false)
	game.player.is_defeated = true
	game.local_player_registry.slot_at(0).remaining_lives = 1
	game.lives = 1
	game._consume_player_continue(game.player)
	test.check(game.continue_respawn_time.has(0) and is_equal_approx(float(game.continue_respawn_time[0]), game.CONTINUE_RESPAWN_DELAY), "continue offer did not start its arcade countdown")
	test.check(game.hud.continue_offer_times.has(0), "continue countdown was not exposed to the HUD")
	game._tick_downed_players(game.CONTINUE_RESPAWN_DELAY)
	test.check(game.state == "gameover" and game.lives == -1 and not game.continue_respawn_time.has(0), "expired continue offer did not end the exhausted run")
	test.check(game.arcade_profile.high_scores.size() == 0, "zero-score game over polluted the local high-score table")

	game.score = 12345
	game.final_score_recorded = false
	game._record_final_score()
	game._record_final_score()
	test.check(game.arcade_profile.high_scores.size() == 1 and game.final_score_rank == 0, "final score was not recorded exactly once")
	test.check(game.hud.final_score_rank == 0 and game.arcade_profile.top_score() == 12345, "final score rank did not reach the HUD/profile")
	await test.dispose(game)
