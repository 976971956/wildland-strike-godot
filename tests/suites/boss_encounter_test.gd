extends RefCounted

const BossPhaseDataScript = preload("res://core/combat/boss_phase_data.gd")
const StreetEnemyScript = preload("res://scripts/enemy.gd")
const BOSS = preload("res://data/enemies/boss.tres")
const SLAM = preload("res://data/attacks/enemy_boss_slam.tres")
const OVERDRIVE = preload("res://data/attacks/enemy_boss_overdrive.tres")


func run(test) -> void:
	test.check(BOSS.boss_phases.size() == 2, "Stage 1 boss does not have exactly two phases")
	var command_phase: Resource = BOSS.boss_phases[0]
	var overdrive_phase: Resource = BOSS.boss_phases[1]
	test.check(command_phase.is_valid_phase() and overdrive_phase.is_valid_phase(), "boss phase data failed validation")
	test.check(command_phase.phase_id == &"command" and command_phase.health_threshold_ratio == 1.0, "command phase identity drifted")
	test.check(overdrive_phase.phase_id == &"overdrive" and overdrive_phase.health_threshold_ratio == 0.5, "overdrive threshold drifted")
	test.check(command_phase.special_kind == BossPhaseDataScript.SpecialKind.GROUND_SLAM, "phase one lost ground slam")
	test.check(overdrive_phase.special_kind == BossPhaseDataScript.SpecialKind.RUSH, "phase two lost rush behavior")
	test.check(command_phase.special_attack == SLAM and overdrive_phase.attack == OVERDRIVE, "boss attacks are not phase-driven")
	test.check(SLAM.damage == 22 and SLAM.circle_radius == 96.0 and SLAM.launch, "ground slam tuning drifted")
	test.check(OVERDRIVE.damage == 24 and OVERDRIVE.duration == 0.42 and OVERDRIVE.launch, "overdrive attack tuning drifted")
	test.check(overdrive_phase.speed_scale > command_phase.speed_scale, "overdrive phase did not increase boss speed")
	test.check(overdrive_phase.reinforcement_enemy_id == &"hunter" and overdrive_phase.reinforcement_count == 2, "phase reinforcements drifted")
	test.check(not BossPhaseDataScript.new().is_valid_phase(), "empty boss phase should be invalid")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.encounter_director.force_start_encounter(3)
	test.check(game.remaining_enemies == 3, "boss encounter opening count drifted")
	var boss: Node = null
	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if enemy.definition.is_boss:
			boss = enemy
	test.check(boss != null, "boss encounter did not spawn its boss")
	if boss == null:
		await test.dispose(game)
		return
	test.check(boss.boss_phase_index == 0 and boss.current_boss_phase == command_phase, "boss did not initialize command phase")
	test.check(boss.current_attack == command_phase.attack and boss.speed == BOSS.speed, "command phase tuning was not applied")
	test.check(game.boss_phase_history == [&"command"], "boss spawn phase was not observed")
	test.check(game.hud.boss_health == BOSS.max_health and game.hud.boss_max == BOSS.max_health, "boss HUD did not initialize before first hit")
	test.check(game.hud.boss_name == "WARDEN ROURKE" and game.hud.boss_phase == 1, "boss HUD identity drifted")
	test.check(game.hud.dialogue_line == command_phase.dialogue_line and game.hud.dialogue_time > 0.0, "boss entrance dialogue did not display")

	game.player.set_physics_process(false)
	game.player.position = boss.position - Vector2(200.0, 0.0)
	boss.behavior_cooldown_timer = 0.0
	boss._think(1.0 / 60.0)
	test.check(boss.behavior_phase == StreetEnemyScript.BehaviorPhase.TELEGRAPH, "command phase did not telegraph ground slam")
	test.check(boss.last_behavior_event == &"boss_special_telegraph", "boss special telegraph event was not observable")
	boss._think(command_phase.telegraph_duration + 0.01)
	test.check(boss.current_attack == SLAM and boss.attack_timer == SLAM.duration, "ground slam attack did not start from phase data")
	test.check(boss.behavior_phase == StreetEnemyScript.BehaviorPhase.RECOVER, "ground slam did not enter recovery")
	test.check(boss.behavior_event_history.has(&"boss_slam"), "ground slam event was not observable")
	game.player.position = boss.position - Vector2(60.0, 0.0)
	game.player.invulnerable = 0.0
	var player_health_before: int = game.player.health
	boss.attack_timer = SLAM.hit_trigger_remaining - 0.01
	boss._check_attack()
	test.check(game.player.health == player_health_before - SLAM.damage, "ground slam did not damage player")

	boss.invulnerable = 0.0
	boss.take_hit(9999, Vector2(300.0, -60.0), true)
	test.check(not boss.is_defeated and boss.health == 130, "lethal phase-one hit skipped overdrive gate")
	test.check(boss.boss_phase_index == 1 and boss.current_boss_phase == overdrive_phase, "boss did not transition to overdrive")
	test.check(boss.current_attack == OVERDRIVE and is_equal_approx(boss.speed, BOSS.speed * overdrive_phase.speed_scale), "overdrive tuning was not applied")
	test.check(boss.boss_transition_timer == 1.0 and boss.invulnerable == 1.0, "phase transition did not grant a readable safe window")
	test.check(game.boss_phase_history == [&"command", &"overdrive"], "boss phase history drifted")
	test.check(game.hud.boss_phase == 2 and game.hud.dialogue_line == overdrive_phase.dialogue_line, "phase-two dialogue/HUD did not update")
	test.check(game.remaining_enemies == 5, "dynamic reinforcements were not registered with encounter director")
	var hunters: Array[Node] = []
	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if enemy.definition.enemy_id == &"hunter":
			hunters.append(enemy)
	test.check(hunters.size() == 2, "overdrive phase did not spawn two hunters")

	boss.boss_transition_timer = 0.0
	boss.invulnerable = 0.0
	boss.attack_timer = 0.0
	boss._cancel_behavior()
	game.player.position = boss.position - Vector2(300.0, 0.0)
	game.player.invulnerable = 0.0
	boss._think(1.0 / 60.0)
	test.check(boss.behavior_phase == StreetEnemyScript.BehaviorPhase.TELEGRAPH, "overdrive did not telegraph rush")
	boss._think(overdrive_phase.telegraph_duration + 0.01)
	test.check(boss.behavior_phase == StreetEnemyScript.BehaviorPhase.BURST, "overdrive telegraph did not become rush")
	test.check(boss.last_behavior_event == &"boss_rush", "boss rush event was not observable")
	test.check(is_equal_approx(boss.velocity.length(), boss.speed * overdrive_phase.burst_speed_scale), "boss rush ignored phase speed")
	game.player.position = boss.position - Vector2(55.0, 0.0)
	boss._think(0.01)
	test.check(boss.attack_timer == OVERDRIVE.duration and boss.behavior_phase == StreetEnemyScript.BehaviorPhase.RECOVER, "boss rush did not resolve into overdrive attack/recovery")
	player_health_before = game.player.health
	boss.attack_timer = OVERDRIVE.hit_trigger_remaining - 0.01
	boss._check_attack()
	test.check(game.player.health == player_health_before - OVERDRIVE.damage, "overdrive rush attack damage drifted")

	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(true)
		enemy.invulnerable = 0.0
		enemy.take_hit(9999, Vector2(300.0, 0.0), true)
	await test.wait_physics_frames(55)
	test.check(game.encounter_director.completed and game.state == "victory", "boss and reinforcements did not complete Stage 1")
	await test.dispose(game)
