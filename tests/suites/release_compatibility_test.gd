extends RefCounted

const ArcadeProfileScript = preload("res://core/persistence/arcade_profile.gd")
const LocalPlayerRegistryScript = preload("res://core/input/local_player_registry.gd")


func run(test) -> void:
	_test_platform_contract(test)
	_test_registry_reconnect_contract(test)
	_test_profile_migrations_and_recovery(test)
	await _test_runtime_disconnect_and_suspend(test)


func _test_platform_contract(test) -> void:
	var project_source := FileAccess.get_file_as_string("res://project.godot")
	var main_scene_source := FileAccess.get_file_as_string("res://main.tscn")
	var export_source := FileAccess.get_file_as_string("res://export_presets.cfg")
	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(project_source.contains('renderer/rendering_method="gl_compatibility"'), "desktop/Web renderer is not the broad-compatibility backend")
	test.check(project_source.contains('renderer/rendering_method.mobile="gl_compatibility"'), "mobile renderer drifted from the compatibility backend")
	test.check(project_source.contains('window/stretch/mode="canvas_items"') and project_source.contains('window/stretch/aspect="expand"'), "responsive viewport/stretch contract is incomplete")
	test.check(project_source.contains('window/handheld/orientation=4'), "mobile orientation must follow the sensor across both landscape directions")
	test.check(project_source.contains('[physics]') and project_source.contains('common/physics_interpolation=true'), "high-refresh mobile rendering must interpolate 60 Hz fighter motion")
	test.check(main_scene_source.contains('process_callback = 0'), "camera must sample interpolated motion on the physics timeline")
	test.check(export_source.contains('variant/thread_support=false'), "Web release unexpectedly requires cross-origin-isolated threads")
	test.check(export_source.contains('html/canvas_resize_policy=2') and export_source.contains('html/focus_canvas_on_start=true'), "Web canvas resize/focus contract drifted")
	test.check(export_source.contains('application/min_ios_version="15.0"') and export_source.contains('architectures/arm64=true'), "iOS 15+/arm64 release floor drifted")
	test.check(export_source.contains('privacy/tracking_enabled=false') and export_source.contains('modules/camera=false'), "iOS privacy-disabled feature contract drifted")
	test.check(probe_source.contains("release_stress_preview=1") and probe_source.contains("release_three_player_stage_8_stress"), "repeatable three-player release stress fixture is missing")


func _test_registry_reconnect_contract(test) -> void:
	var registry = LocalPlayerRegistryScript.new()
	registry.reset_with_keyboard(0)
	var original = registry.join_device_at_slot(9, 2, 3)
	test.check(original != null and original.slot_index == 2 and original.hero_index == 3, "preferred reconnect slot was not claimed")
	test.check(registry.join_device_at_slot(10, 2, 1) == null, "preferred reconnect overwrote an occupied slot")
	registry.leave_device(9)
	var restored = registry.join_device_at_slot(9, 2, 3)
	test.check(restored != null and restored.slot_index == 2, "released controller slot was not restorable")


func _test_profile_migrations_and_recovery(test) -> void:
	var profile_path := "/tmp/wildland_release_profile.cfg"
	_cleanup_profile(profile_path)

	var v1 := ConfigFile.new()
	v1.set_value("profile", "version", 1)
	v1.set_value("settings", "music_volume", 0.42)
	v1.set_value("settings", "screen_shake", false)
	v1.set_value("scores", "entries", [{"name": "V1", "score": 4200, "stage": 4, "players": 1}])
	v1.save(profile_path)
	var migrated_v1 = ArcadeProfileScript.new(profile_path)
	test.check(migrated_v1.load_profile() == OK and migrated_v1.loaded_version == migrated_v1.CURRENT_VERSION, "v1 profile did not migrate")
	test.check(is_equal_approx(float(migrated_v1.settings.music_volume), 0.42) and not migrated_v1.settings.screen_shake, "v1 settings changed during migration")
	test.check(int(migrated_v1.bindings.attack) == KEY_J and migrated_v1.high_scores.size() == 1, "v1 migration did not supply bindings/preserve scores")

	var v2 := ConfigFile.new()
	v2.set_value("profile", "version", 2)
	v2.set_value("settings", "touch_layout", "left_handed")
	v2.set_value("bindings", "attack", KEY_F)
	v2.save(profile_path)
	var migrated_v2 = ArcadeProfileScript.new(profile_path)
	test.check(migrated_v2.load_profile() == OK and migrated_v2.settings.subtitles and migrated_v2.settings.language == "en", "v2 profile did not receive v3 localization defaults")
	test.check(migrated_v2.settings.touch_layout == "left_handed" and int(migrated_v2.bindings.attack) == KEY_F, "v2 profile lost existing settings/bindings")

	var future := ConfigFile.new()
	future.set_value("profile", "version", 99)
	future.set_value("settings", "language", "zh")
	future.set_value("settings", "future_option", "ignored")
	future.set_value("bindings", "jump", KEY_G)
	future.save(profile_path)
	var future_loaded = ArcadeProfileScript.new(profile_path)
	test.check(future_loaded.load_profile() == OK and future_loaded.settings.language == "zh" and int(future_loaded.bindings.jump) == KEY_G, "future profile did not preserve known forward-compatible fields")
	test.check(not future_loaded.settings.has("future_option"), "future unknown setting leaked into the runtime schema")

	var stable = ArcadeProfileScript.new(profile_path)
	stable.load_profile()
	stable.set_setting("music_volume", 0.33)
	stable.record_score(9900, 8, 3, "BACKUP")
	test.check(stable.save_profile() == OK, "stable profile save failed")
	stable.set_setting("music_volume", 0.66)
	test.check(stable.save_profile() == OK and FileAccess.file_exists(profile_path + ".bak"), "profile save did not maintain a last-known-good backup")
	var corrupt := FileAccess.open(profile_path, FileAccess.WRITE)
	corrupt.store_string("not-a-config")
	corrupt.close()
	var recovered = ArcadeProfileScript.new(profile_path)
	test.check(recovered.load_profile() == OK and recovered.recovered_from_backup, "corrupt primary profile did not recover from backup")
	test.check(is_equal_approx(float(recovered.settings.music_volume), 0.33) and recovered.top_score() == 9900, "backup recovery changed settings or scores")

	_cleanup_profile(profile_path)
	var only_corrupt := FileAccess.open(profile_path, FileAccess.WRITE)
	only_corrupt.store_string("not-a-config")
	only_corrupt.close()
	var defaults = ArcadeProfileScript.new(profile_path)
	test.check(defaults.load_profile() == OK and defaults.recovered_from_corruption, "unrecoverable profile did not fall back safely")
	test.check(defaults.settings == defaults.DEFAULT_SETTINGS and defaults.high_scores.is_empty(), "corruption fallback did not retain clean defaults")
	_cleanup_profile(profile_path)


func _test_runtime_disconnect_and_suspend(test) -> void:
	var game: Node = await test.instantiate_main()
	if game == null:
		return
	var second: Node = game.join_local_player(7, 3)
	test.check(second != null and second.local_slot_index == 1, "release reconnect fixture could not join controller")
	game._start_game()
	second.health = 47
	second.position = Vector2(640.0, 590.0)
	game.local_player_registry.slot_at(1).remaining_lives = 1
	game._on_joy_connection_changed(7, false)
	test.check(game.local_player_registry.slot_for_device(7) == null and game.disconnected_player_snapshots.has(7), "controller disconnect did not reserve its player state")
	game._on_joy_connection_changed(7, true)
	var restored: Node = game.player_for_slot(1)
	test.check(restored != null and game.local_player_registry.slot_for_device(7) != null, "controller reconnect did not restore its runtime player")
	test.check(restored.hero_id == &"atlas" and restored.health == 47 and game.local_player_registry.slot_at(1).remaining_lives == 1, "controller reconnect lost hero, health, or continues")
	test.check(restored.position.is_equal_approx(Vector2(640.0, 590.0)) and restored.invulnerable > 0.0, "controller reconnect lost position or safety invulnerability")

	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	test.check(game.suspended_by_os and game.state == "options" and test.tree.paused, "application suspend did not persist and safely pause gameplay")
	game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	test.check(not game.suspended_by_os and game.state == "options" and test.tree.paused, "application resume bypassed the player's pause confirmation")
	game._close_options()
	test.check(game.state == "playing" and not test.tree.paused, "suspended run could not resume through the normal pause flow")
	await test.dispose(game)


func _cleanup_profile(profile_path: String) -> void:
	for path in [profile_path, profile_path + ".bak"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
