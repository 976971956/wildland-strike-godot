extends RefCounted

const LIGHT = preload("res://data/impacts/light.tres")
const MEDIUM = preload("res://data/impacts/medium.tres")
const HEAVY = preload("res://data/impacts/heavy.tres")
const THROW = preload("res://data/impacts/throw.tres")
const SPECIAL = preload("res://data/impacts/special.tres")
const CLASH = preload("res://data/impacts/clash.tres")


func run(test) -> void:
	var profile_ids := {}
	for profile in [LIGHT, MEDIUM, HEAVY, THROW, SPECIAL, CLASH]:
		test.check(profile != null and profile.is_valid_profile(), "impact profile failed validation")
		test.check(not profile_ids.has(profile.profile_id), "impact profile id is duplicated")
		profile_ids[profile.profile_id] = true
	test.check(LIGHT.hit_stop_duration == 0.034 and LIGHT.attacker_recoil_speed == 42.0, "light impact timing drifted")
	test.check(HEAVY.camera_shake_strength == 12.5 and HEAVY.layer_sfx == &"impact_crack", "heavy impact response drifted")
	test.check(THROW.haptic_duration_ms == 56 and THROW.haptic_strength == 0.95, "throw haptic response drifted")
	test.check(SPECIAL.hit_stop_duration == 0.105 and SPECIAL.layer_sfx == &"special_burst", "special impact response drifted")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game.sfx_event_history.clear()
	game.shake_time = 0.0
	game.shake_strength = 0.0
	game.last_hit_stop_duration = 0.0
	game.hit_confirm(Vector2(320.0, 240.0), 1, 1, true, LIGHT)
	test.check(game.last_impact_profile_id == &"light", "light profile was not selected")
	test.check(game.shake_time == 0.052 and game.shake_strength == 4.2, "light camera response ignored profile data")
	test.check(game.last_hit_stop_duration == 0.034, "light hit stop ignored profile data")
	test.check(game.last_haptic_duration_ms == 16 and game.last_haptic_strength == 0.32, "light haptic response ignored profile data")
	test.check(game.sfx_event_history == [&"hit", &"impact_snap"], "light impact did not layer its configured SFX")
	test.check(Engine.time_scale == 1.0, "headless hit stop changed global time scale")

	game.sfx_event_history.clear()
	game.shake_time = 0.0
	game.shake_strength = 0.0
	game.hit_confirm(Vector2(320.0, 240.0), 3, -1, true, HEAVY)
	test.check(game.last_impact_profile_id == &"heavy", "heavy profile was not selected")
	test.check(game.shake_time == 0.145 and game.shake_strength == 12.5, "heavy camera response ignored profile data")
	test.check(game.last_hit_stop_duration == 0.082, "heavy hit stop ignored profile data")
	test.check(game.sfx_event_history == [&"heavy", &"impact_crack"], "heavy impact did not layer its configured SFX")

	game.sfx_event_history.clear()
	game.last_hit_stop_duration = 0.0
	game.hit_confirm(Vector2(320.0, 240.0), 1, 1, false, CLASH)
	test.check(game.last_impact_profile_id == &"clash" and game.last_hit_stop_duration == 0.0, "non-freezing clash applied hit stop")
	test.check(game.sfx_event_history == [&"impact_clash"], "clash SFX drifted")

	game._start_game()
	game.player.set_physics_process(false)
	game.player.position = Vector2(500.0, 540.0)
	await test.wait_physics_frames(2)
	var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.set_physics_process(false)
		enemy.position = Vector2(1300.0, 650.0)
	test.check(not enemies.is_empty(), "impact gameplay fixture failed to spawn")
	if not enemies.is_empty():
		var target = enemies[0]
		target.position = Vector2(569.0, 540.0)
		target.attack_timer = 0.0
		target.attack_hit_done = true
		target.attack_hitbox.deactivate()
		target.invulnerable = 0.0
		game.player.facing = 1
		game.player.attack_timer = 0.0
		game.player.combo_window = 0.0
		game.player._start_attack()
		game.player.attack_timer = game.player.current_attack.hit_trigger_remaining - 0.01
		game.sfx_event_history.clear()
		game.player._check_attack_hit()
		test.check(game.last_impact_profile_id == &"light", "combo hit did not forward its impact profile")
		test.check(game.player.attack_lunge == -42.0, "combo hit did not apply configured attacker recoil")
		test.check(game.sfx_event_history == [&"hit", &"impact_snap"], "combo hit did not play layered impact SFX")

	game.player._apply_attacker_recoil(THROW)
	test.check(game.player.attack_lunge == -82.0, "throw recoil profile was not applied")
	await test.dispose(game)
