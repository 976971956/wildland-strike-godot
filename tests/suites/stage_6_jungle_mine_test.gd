extends RefCounted

const BossPhaseDataScript = preload("res://core/combat/boss_phase_data.gd")
const EnvironmentObjectDataScript = preload("res://core/stages/environment_object_data.gd")
const JungleHazardDataScript = preload("res://core/stages/jungle_hazard_data.gd")
const STAGE_6 = preload("res://data/stages/stage_6/stage_6.tres")
const TITAN_WARDEN = preload("res://data/enemies/titan_warden.tres")


func run(test) -> void:
	test.check(STAGE_6 != null and STAGE_6.is_valid_stage(), "Stage 6 jungle mine definition is invalid")
	test.check(STAGE_6.stage_id == &"stage_6" and STAGE_6.stage_number == 6, "Stage 6 identity drifted")
	test.check(STAGE_6.display_name == "THE TITAN QUARRY" and STAGE_6.time_limit_seconds == 300.0, "Stage 6 presentation/timer drifted")
	test.check(STAGE_6.enemy_health_scale == 1.43 and STAGE_6.enemy_damage_scale == 1.21 and STAGE_6.clear_bonus == 14000, "Stage 6 campaign profile drifted")
	test.check(STAGE_6.scenes.size() == 3 and STAGE_6.end_x() == 4200.0, "Stage 6 should be three contiguous 4,200px scenes")
	var expected_scene_ids := [&"jungle_research_trail", &"jungle_mine_entrance", &"titan_shaft"]
	var expected_themes := [15, 16, 17]
	var previous_end := 0.0
	var hazard_kind_counts := {0: 0, 1: 0, 2: 0}
	for index in range(STAGE_6.scenes.size()):
		var scene: Resource = STAGE_6.scenes[index]
		test.check(scene.is_valid_scene(), "%s scene is invalid" % scene.scene_id)
		test.check(scene.scene_id == expected_scene_ids[index] and scene.visual_theme == expected_themes[index], "Stage 6 scene order/theme drifted")
		test.check(scene.start_x == previous_end, "Stage 6 scene continuity failed")
		test.check(scene.background_texture.get_width() == 1672 and scene.background_texture.get_height() == 941, "Stage 6 background dimensions drifted")
		previous_end = scene.end_x
		for object_definition in scene.environment_objects:
			test.check(object_definition.kind == EnvironmentObjectDataScript.ObjectKind.JUNGLE_HAZARD and object_definition.is_valid_object(), "%s jungle hazard is invalid" % object_definition.object_id)
			hazard_kind_counts[object_definition.hazard_kind] += 1
	test.check(hazard_kind_counts == {0: 3, 1: 1, 2: 2}, "Stage 6 spore/cart/titan hazard distribution drifted")

	var encounters: Array[Resource] = STAGE_6.all_encounters()
	test.check(encounters.size() == 5, "Stage 6 encounter count drifted")
	test.check(encounters.map(func(encounter: Resource): return encounter.encounter_id) == [&"trail_survey", &"mine_mouth_lock", &"cart_run", &"shaft_breach", &"titan_warden_showdown"], "Stage 6 encounter order drifted")
	var total_spawns := 0
	for encounter in encounters:
		test.check(encounter.is_valid_encounter(), "%s encounter is invalid" % encounter.encounter_id)
		total_spawns += encounter.total_spawn_count()
	test.check(total_spawns == 17, "Stage 6 authored population drifted")

	test.check(TITAN_WARDEN.is_valid_definition() and TITAN_WARDEN.boss_phases.size() == 3, "Titan Warden definition is invalid")
	test.check(TITAN_WARDEN.sprite_sheet.get_width() == 2560 and TITAN_WARDEN.sprite_sheet.get_height() == 320, "Titan Warden atlas contract drifted")
	test.check(TITAN_WARDEN.sprite_columns == 8 and TITAN_WARDEN.sprite_rows == 1, "Titan Warden atlas grid drifted")
	var survey: Resource = TITAN_WARDEN.boss_phases[0]
	var protocol: Resource = TITAN_WARDEN.boss_phases[1]
	var deep_core: Resource = TITAN_WARDEN.boss_phases[2]
	test.check(survey.special_kind == BossPhaseDataScript.SpecialKind.SEISMIC_FRACTURE, "Korva survey phase lost seismic fracture")
	test.check(protocol.special_kind == BossPhaseDataScript.SpecialKind.TITAN_CALL and protocol.reinforcement_enemy_id == &"triceratops", "Korva titan protocol lost its mega-fauna call")
	test.check(deep_core.special_kind == BossPhaseDataScript.SpecialKind.RUSH and deep_core.burst_speed_scale > 2.0, "Korva deep-core phase lost drill charge")
	test.check(survey.health_threshold_ratio > protocol.health_threshold_ratio and protocol.health_threshold_ratio > deep_core.health_threshold_ratio, "Korva phase thresholds are not descending")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	for _stage in range(5):
		game._advance_campaign_stage()
		await test.tree.process_frame
	test.check(game.campaign_stage_index == 5 and game.active_stage_definition == STAGE_6, "campaign did not advance to Stage 6")
	test.check(game.encounter_director.encounters.size() == 5 and test.tree.get_nodes_in_group("jungle_hazards").size() == 6, "Stage 6 runtime did not instantiate encounters/hazards")

	var spores: Node = null
	var cart: Node = null
	var stomp: Node = null
	for hazard in test.tree.get_nodes_in_group("jungle_hazards"):
		hazard.set_physics_process(false)
		match hazard.definition.hazard_kind:
			JungleHazardDataScript.HazardKind.SPORE_BLOOM:
				if spores == null: spores = hazard
			JungleHazardDataScript.HazardKind.MINE_CART:
				cart = hazard
			JungleHazardDataScript.HazardKind.TITAN_STOMP:
				if stomp == null: stomp = hazard
	test.check(spores != null and cart != null and stomp != null, "Stage 6 did not create all jungle hazard kinds")
	game.player.invulnerable = 0.0
	game.player.position = spores.position
	game.player.velocity = Vector2(200.0, 0.0)
	spores.jungle_cycle_time = spores.definition.cycle_duration - spores.definition.active_duration + 0.01
	spores._tick_jungle_hazard(0.01)
	test.check(game.player.velocity.x < 200.0, "spore bloom did not slow movement")
	game.player.invulnerable = 0.0
	game.player.position = cart.position
	var cart_x_before: float = cart.position.x
	var cart_health_before: int = game.player.health
	cart.jungle_cycle_time = cart.definition.cycle_duration - cart.definition.active_duration + 0.01
	cart._tick_jungle_hazard(0.08)
	test.check(cart.position.x != cart_x_before and game.player.health == cart_health_before - cart.definition.contact_damage, "active mine cart did not move and damage")
	game.player.invulnerable = 0.0
	game.player.position = stomp.position
	var stomp_health_before: int = game.player.health
	stomp.jungle_cycle_time = stomp.definition.cycle_duration - stomp.definition.active_duration + 0.01
	stomp._tick_jungle_hazard(0.01)
	test.check(stomp.jungle_damage_active and game.player.health == stomp_health_before - stomp.definition.contact_damage, "titan stomp did not damage the player")

	for existing_enemy in test.tree.get_nodes_in_group("enemies"):
		existing_enemy.queue_free()
	await test.tree.process_frame
	game.encounter_director.active = false
	game.encounter_director.remaining_enemies = 0
	game.encounter_director.current_encounter_index = 4
	game.encounter_director.completed = false
	game.encounter_director.force_start_encounter(4)
	var boss: Node = null
	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if enemy.definition.enemy_id == &"titan_warden": boss = enemy
	test.check(boss != null and boss.boss_phase_index == 0, "Titan Warden did not spawn in seismic survey phase")
	if boss == null:
		await test.dispose(game)
		return
	boss._execute_boss_special()
	test.check(boss.behavior_event_history.has(&"boss_seismic_fracture") and test.tree.get_nodes_in_group("seismic_fractures").size() == 3, "Korva survey phase did not emit three sequential fractures")
	boss.invulnerable = 0.0
	boss.take_hit(9999, Vector2(280.0, -30.0), true)
	test.check(boss.boss_phase_index == 1 and game.remaining_enemies == 2, "Korva titan protocol/reinforcement drifted")
	boss.boss_transition_timer = 0.0
	boss._execute_boss_special()
	test.check(boss.behavior_event_history.has(&"boss_titan_call") and test.tree.get_nodes_in_group("seismic_fractures").size() == 9, "Korva titan call did not fracture both sides of the arena")
	boss.invulnerable = 0.0
	boss.take_hit(9999, Vector2(280.0, -30.0), true)
	test.check(boss.boss_phase_index == 2 and game.boss_phase_history == [&"seismic_survey", &"titan_protocol", &"deep_core"], "Korva full phase history drifted")
	boss.boss_transition_timer = 0.0
	boss.behavior_direction = Vector2.LEFT
	boss._execute_boss_special()
	test.check(boss.behavior_phase == boss.BehaviorPhase.BURST and boss.behavior_event_history.has(&"boss_rush"), "Korva deep-core phase did not enter drill charge")
	await test.dispose(game)
