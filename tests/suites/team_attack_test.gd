extends RefCounted

const TEAM_ATTACK = preload("res://data/attacks/player_team_attack.tres")
const FighterIntentScript = preload("res://core/input/fighter_intent.gd")


func run(test) -> void:
	test.check(TEAM_ATTACK.is_valid_frame_data(), "typed team-attack frame data is invalid")
	test.check(TEAM_ATTACK.attack_id == &"player_team_attack" and TEAM_ATTACK.priority == 4, "team attack identity or priority drifted")
	test.check(TEAM_ATTACK.effect_radius == 190.0 and TEAM_ATTACK.damage == 30 and TEAM_ATTACK.self_damage == 5, "team attack balance values drifted")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	var second: Node = game.join_local_player(0, 1)
	test.check(second != null, "team attack fixture could not join player two")
	game._start_game()
	game.set_process(false)
	game.player.set_physics_process(false)
	second.set_physics_process(false)
	game.player.position = Vector2(500.0, 550.0)
	second.position = Vector2(610.0, 550.0)
	game.spawn_enemy(Vector2(560.0, 550.0), "grunt")
	var linked_target: Node = test.tree.get_nodes_in_group("enemies").back()
	linked_target.set_physics_process(false)
	game.spawn_enemy(Vector2(1050.0, 550.0), "grunt")
	var distant_target: Node = test.tree.get_nodes_in_group("enemies").back()
	distant_target.set_physics_process(false)
	var linked_health_before: int = linked_target.health
	var distant_health_before: int = distant_target.health
	var p1_health_before: int = game.player.health
	var p2_health_before: int = second.health

	var special_intent = FighterIntentScript.new(Vector2.ZERO, false, false, true)
	game.player._apply_intent(special_intent)
	test.check(game.team_attack_requests.has(0), "first special input did not enter the team-link window")
	test.check(game.player.special_timer == 0.0 and game.player.team_attack_charge_timer > 0.0, "first link input fired early or lost its charge cue")
	game._tick_team_attack_requests(0.1)
	second._apply_intent(special_intent)
	var expected_damage := roundi(TEAM_ATTACK.damage * (game.player.damage_scale + second.damage_scale) * 0.5)
	test.check(game.team_attack_count == 1 and game.last_team_attack_participants == [0, 1], "linked specials did not trigger one deterministic team attack")
	test.check(game.last_team_attack_hits == 1, "team attack did not report its in-range target count")
	test.check(linked_target.health == linked_health_before - expected_damage, "team attack did not apply the averaged hero damage scale")
	test.check(distant_target.health == distant_health_before, "team attack damaged a target outside both participants' radius")
	test.check(game.player.health == p1_health_before - TEAM_ATTACK.self_damage and second.health == p2_health_before - TEAM_ATTACK.self_damage, "connected team attack did not charge each participant exactly once")
	test.check(game.player.current_attack == TEAM_ATTACK and second.current_attack == TEAM_ATTACK, "participants did not enter the shared team-attack presentation state")
	test.check(game.player.invulnerable >= TEAM_ATTACK.invulnerable_duration and second.invulnerable >= TEAM_ATTACK.invulnerable_duration, "team attack did not protect both participants")
	test.check(game.team_attack_requests.is_empty(), "completed team attack retained stale link requests")
	test.check(game.sfx_event_history.has(&"team_attack") and game.hud.banner == "TEAM ATTACK!", "team attack presentation feedback did not fire")

	game.player.special_timer = 0.0
	game.player.attack_timer = 0.0
	game.player.invulnerable = 0.0
	second.special_timer = 0.0
	second.attack_timer = 0.0
	second.invulnerable = 0.0
	linked_target.position = Vector2(1200.0, 550.0)
	game.player._request_special()
	test.check(game.team_attack_requests.has(0), "unmatched special did not wait for a teammate")
	game._tick_team_attack_requests(game.TEAM_ATTACK_INPUT_WINDOW)
	test.check(not game.team_attack_requests.has(0) and game.player.current_attack.attack_id == &"player_special", "expired team-link input did not fall back to the normal special")
	test.check(game.team_attack_count == 1, "unmatched fallback incorrectly counted as a team attack")

	game.player.special_timer = 0.0
	game.player.attack_timer = 0.0
	game.player.invulnerable = 0.0
	second.special_timer = 0.0
	second.attack_timer = 0.0
	second.position = Vector2(900.0, 550.0)
	game.player._request_special()
	second._request_special()
	test.check(game.team_attack_requests.size() == 2, "distant teammates incorrectly linked their special inputs")
	game._tick_team_attack_requests(game.TEAM_ATTACK_INPUT_WINDOW)
	test.check(game.player.current_attack.attack_id == &"player_special" and second.current_attack.attack_id == &"player_special", "distant link requests did not independently fall back")
	test.check(game.team_attack_count == 1, "distant teammates incorrectly triggered a team attack")

	game.player.special_timer = 0.0
	game.player.attack_timer = 0.0
	game.player.invulnerable = 0.0
	game.player._request_special()
	test.check(game.team_attack_requests.has(0), "cancel fixture did not create a pending link request")
	game.player.take_hit(1, Vector2.ZERO)
	test.check(not game.team_attack_requests.has(0) and game.player.team_attack_charge_timer == 0.0, "hurt player retained a pending team attack")
	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(probe_source.contains("team_attack_preview=1"), "reproducible team-attack Web preview is missing")
	await test.dispose(game)
