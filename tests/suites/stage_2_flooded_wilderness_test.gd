extends RefCounted

const BossPhaseDataScript = preload("res://core/combat/boss_phase_data.gd")
const EnvironmentObjectDataScript = preload("res://core/stages/environment_object_data.gd")
const StreetEnemyScript = preload("res://scripts/enemy.gd")
const STAGE_2 = preload("res://data/stages/stage_2/stage_2.tres")
const MIREWARDEN = preload("res://data/enemies/mirewarden.tres")


func run(test) -> void:
	test.check(STAGE_2 != null and STAGE_2.is_valid_stage(), "Stage 2 flooded-wilderness definition is invalid")
	test.check(STAGE_2.stage_id == &"stage_2" and STAGE_2.stage_number == 2, "Stage 2 identity drifted")
	test.check(STAGE_2.display_name == "THE FLOODED WILDERNESS" and STAGE_2.time_limit_seconds == 270.0, "Stage 2 presentation/timer drifted")
	test.check(STAGE_2.scenes.size() == 3 and STAGE_2.end_x() == 4200.0, "Stage 2 should be three contiguous 4,200px scenes")
	var expected_scene_ids := [&"cypress_approach", &"research_camp", &"ancient_spillway"]
	var expected_themes := [3, 4, 5]
	var previous_end := 0.0
	var water_currents := 0
	for index in range(STAGE_2.scenes.size()):
		var scene: Resource = STAGE_2.scenes[index]
		test.check(scene.is_valid_scene(), "%s scene is invalid" % scene.scene_id)
		test.check(scene.scene_id == expected_scene_ids[index] and scene.visual_theme == expected_themes[index], "Stage 2 scene order/theme drifted")
		test.check(scene.start_x == previous_end and scene.background_texture != null, "Stage 2 scene continuity/art contract failed")
		test.check(scene.background_texture.get_width() == 1672 and scene.background_texture.get_height() == 941, "Stage 2 background dimensions drifted")
		previous_end = scene.end_x
		for object_definition in scene.environment_objects:
			if object_definition.kind == EnvironmentObjectDataScript.ObjectKind.WATER_CURRENT:
				water_currents += 1
			test.check(object_definition.is_valid_object(), "%s environment object is invalid" % object_definition.object_id)
	test.check(water_currents == 3, "each flooded-wilderness scene should own one systemic water current")

	var encounters: Array[Resource] = STAGE_2.all_encounters()
	test.check(encounters.size() == 4, "Stage 2 encounter count drifted")
	test.check(encounters.map(func(encounter: Resource): return encounter.encounter_id) == [&"cypress_ambush", &"camp_siege", &"spillway_predators", &"mirewarden_showdown"], "Stage 2 encounter order drifted")
	var total_initial_spawns := 0
	for encounter in encounters:
		test.check(encounter.is_valid_encounter(), "%s encounter is invalid" % encounter.encounter_id)
		total_initial_spawns += encounter.total_spawn_count()
	test.check(total_initial_spawns == 14, "Stage 2 authored opening/reinforcement population drifted")

	test.check(MIREWARDEN.is_valid_definition() and MIREWARDEN.boss_phases.size() == 3, "Mirewarden boss definition is invalid")
	test.check(MIREWARDEN.sprite_sheet.get_width() == 2560 and MIREWARDEN.sprite_sheet.get_height() == 320, "Mirewarden runtime atlas contract drifted")
	var floodgate: Resource = MIREWARDEN.boss_phases[0]
	var harpoon: Resource = MIREWARDEN.boss_phases[1]
	var deluge: Resource = MIREWARDEN.boss_phases[2]
	test.check(floodgate.phase_id == &"floodgate" and floodgate.special_kind == BossPhaseDataScript.SpecialKind.TIDAL_WAVE, "Mirewarden opening phase lost tidal wave")
	test.check(harpoon.phase_id == &"harpoon_rush" and harpoon.special_kind == BossPhaseDataScript.SpecialKind.RUSH, "Mirewarden middle phase lost harpoon rush")
	test.check(deluge.phase_id == &"deluge" and deluge.special_kind == BossPhaseDataScript.SpecialKind.TIDAL_WAVE, "Mirewarden final phase lost deluge")
	test.check(floodgate.health_threshold_ratio > harpoon.health_threshold_ratio and harpoon.health_threshold_ratio > deluge.health_threshold_ratio, "Mirewarden phase thresholds are not descending")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	var second_player: Node = game.join_local_player(0, 1)
	var third_player: Node = game.join_local_player(1, 2)
	test.check(second_player != null and third_player != null, "three-player campaign fixture could not join both gamepads")
	game.score = 4321
	game.lives = 1
	game._advance_campaign_stage()
	await test.tree.process_frame
	test.check(game.campaign_stage_index == 1 and game.active_stage_definition == STAGE_2, "campaign did not advance from Stage 1 to Stage 2")
	test.check(game.score == 4321 and game.lives == 1, "campaign transition did not preserve score/lives")
	test.check(game.get_local_players().size() == 3 and game.get_active_players().size() == 3, "Stage 2 transition did not preserve the full three-player roster")
	test.check(second_player.hero_id == &"mara" and third_player.hero_id == &"kestrel", "Stage 2 transition changed joined-player hero assignments")
	test.check(game.state == "playing" and game.stage_time_remaining <= 270.0 and game.stage_time_remaining > 269.0, "Stage 2 transition did not enter timed play (state=%s timer=%.3f)" % [game.state, game.stage_time_remaining])
	test.check(game.encounter_director.stage_definition == STAGE_2 and game.encounter_director.get_encounter_count() == 4, "Stage 2 director was not reconfigured")
	test.check(game.world_art.scenes == STAGE_2.scenes, "Stage 2 world art was not reconfigured")

	var current_hazard: Node = null
	for stage_object in test.tree.get_nodes_in_group("stage_objects"):
		if stage_object.definition.kind == EnvironmentObjectDataScript.ObjectKind.WATER_CURRENT:
			current_hazard = stage_object
			break
	test.check(current_hazard != null, "Stage 2 transition did not instantiate water hazards")
	if current_hazard != null:
		current_hazard.set_physics_process(false)
		game.player.set_physics_process(false)
		game.player.position = current_hazard.position
		game.player.invulnerable = 0.0
		var health_before: int = game.player.health
		var x_before: float = game.player.position.x
		current_hazard._physics_process(0.5)
		test.check(game.player.position.x < x_before, "cypress current did not push an overlapping player left")
		test.check(game.player.health == health_before - current_hazard.definition.contact_damage, "water current contact damage drifted")

	game.player.position = Vector2(3600.0, 560.0)
	game.player.set_physics_process(false)
	game.encounter_director.force_start_encounter(3)
	test.check(game.remaining_enemies == 1 and game.encounter_director.is_active_encounter(&"mirewarden_showdown"), "Mirewarden encounter did not start")
	var boss: Node = null
	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if enemy.definition.enemy_id == &"mirewarden":
			boss = enemy
	test.check(boss != null and boss.boss_phase_index == 0, "Mirewarden did not spawn in floodgate phase")
	if boss == null:
		await test.dispose(game)
		return
	game.player.position = boss.position - Vector2(300.0, 0.0)
	boss.behavior_cooldown_timer = 0.0
	boss._think(1.0 / 60.0)
	test.check(boss.behavior_phase == StreetEnemyScript.BehaviorPhase.TELEGRAPH, "Mirewarden tidal wave did not telegraph")
	boss._think(floodgate.telegraph_duration + 0.01)
	test.check(boss.behavior_event_history.has(&"boss_tidal_wave"), "Mirewarden tidal wave event was not observable")
	test.check(test.tree.get_nodes_in_group("stage_effects").size() == 1, "Mirewarden tidal wave did not create its traveling hazard")

	boss.invulnerable = 0.0
	boss.take_hit(9999, Vector2(300.0, -40.0), true)
	test.check(boss.boss_phase_index == 1 and boss.health == ceili(boss.max_health * harpoon.health_threshold_ratio), "Mirewarden skipped the harpoon phase gate")
	test.check(game.remaining_enemies == 2, "harpoon phase raptor was not registered")
	boss.invulnerable = 0.0
	boss.boss_transition_timer = 0.0
	boss.take_hit(9999, Vector2(300.0, -40.0), true)
	test.check(boss.boss_phase_index == 2 and boss.health == ceili(boss.max_health * deluge.health_threshold_ratio), "Mirewarden skipped the deluge phase gate")
	test.check(game.remaining_enemies == 4, "deluge compy reinforcements were not registered")
	test.check(game.boss_phase_history == [&"floodgate", &"harpoon_rush", &"deluge"], "Mirewarden phase history drifted")

	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(true)
		enemy.invulnerable = 0.0
		enemy.boss_transition_timer = 0.0
		enemy.take_hit(9999, Vector2(300.0, 0.0), true)
	await test.wait_physics_frames(58)
	test.check(game.encounter_director.completed and game.state == "victory", "Stage 2 boss and reinforcements did not complete the stage")
	await test.dispose(game)
