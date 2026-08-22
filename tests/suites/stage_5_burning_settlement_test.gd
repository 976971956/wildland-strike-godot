extends RefCounted

const BossPhaseDataScript = preload("res://core/combat/boss_phase_data.gd")
const DisasterHazardDataScript = preload("res://core/stages/disaster_hazard_data.gd")
const EnvironmentObjectDataScript = preload("res://core/stages/environment_object_data.gd")
const STAGE_5 = preload("res://data/stages/stage_5/stage_5.tres")
const CINDER_MATRIARCH = preload("res://data/enemies/cinder_matriarch.tres")


func run(test) -> void:
	test.check(STAGE_5 != null and STAGE_5.is_valid_stage(), "Stage 5 burning settlement definition is invalid")
	test.check(STAGE_5.stage_id == &"stage_5" and STAGE_5.stage_number == 5, "Stage 5 identity drifted")
	test.check(STAGE_5.display_name == "THE BURNING SETTLEMENT" and STAGE_5.time_limit_seconds == 285.0, "Stage 5 presentation/timer drifted")
	test.check(STAGE_5.enemy_health_scale == 1.34 and STAGE_5.enemy_damage_scale == 1.17 and STAGE_5.clear_bonus == 12000, "Stage 5 campaign profile drifted")
	test.check(STAGE_5.scenes.size() == 3 and STAGE_5.end_x() == 4200.0, "Stage 5 should be three contiguous 4,200px scenes")
	var expected_scene_ids := [&"ember_refuge", &"burning_market", &"ashen_cistern"]
	var expected_themes := [12, 13, 14]
	var previous_end := 0.0
	var hazard_kind_counts := {0: 0, 1: 0, 2: 0}
	for index in range(STAGE_5.scenes.size()):
		var scene: Resource = STAGE_5.scenes[index]
		test.check(scene.is_valid_scene(), "%s scene is invalid" % scene.scene_id)
		test.check(scene.scene_id == expected_scene_ids[index] and scene.visual_theme == expected_themes[index], "Stage 5 scene order/theme drifted")
		test.check(scene.start_x == previous_end, "Stage 5 scene continuity failed")
		test.check(scene.background_texture.get_width() == 1672 and scene.background_texture.get_height() == 941, "Stage 5 background dimensions drifted")
		previous_end = scene.end_x
		for object_definition in scene.environment_objects:
			test.check(object_definition.kind == EnvironmentObjectDataScript.ObjectKind.DISASTER_HAZARD and object_definition.is_valid_object(), "%s disaster hazard is invalid" % object_definition.object_id)
			hazard_kind_counts[object_definition.hazard_kind] += 1
	test.check(hazard_kind_counts == {0: 2, 1: 1, 2: 2}, "Stage 5 fire/smoke/cistern hazard distribution drifted")

	var encounters: Array[Resource] = STAGE_5.all_encounters()
	test.check(encounters.size() == 5, "Stage 5 encounter count drifted")
	test.check(encounters.map(func(encounter: Resource): return encounter.encounter_id) == [&"refuge_evacuation", &"market_smoke_lock", &"market_fireline", &"cistern_approach", &"cinder_matriarch_showdown"], "Stage 5 encounter order drifted")
	var total_spawns := 0
	for encounter in encounters:
		test.check(encounter.is_valid_encounter(), "%s encounter is invalid" % encounter.encounter_id)
		total_spawns += encounter.total_spawn_count()
	test.check(total_spawns == 15, "Stage 5 authored population drifted")

	test.check(CINDER_MATRIARCH.is_valid_definition() and CINDER_MATRIARCH.boss_phases.size() == 3, "Cinder Matriarch definition is invalid")
	test.check(CINDER_MATRIARCH.sprite_sheet.get_width() == 2560 and CINDER_MATRIARCH.sprite_sheet.get_height() == 640, "Cinder Matriarch atlas contract drifted")
	test.check(CINDER_MATRIARCH.sprite_columns == 8 and CINDER_MATRIARCH.sprite_rows == 2, "Cinder Matriarch atlas grid drifted")
	var marshal: Resource = CINDER_MATRIARCH.boss_phases[0]
	var ashbeast: Resource = CINDER_MATRIARCH.boss_phases[1]
	var rupture: Resource = CINDER_MATRIARCH.boss_phases[2]
	test.check(marshal.special_kind == BossPhaseDataScript.SpecialKind.EMBER_SURGE and marshal.sprite_row_override == 0, "Veyra human phase lost ember surge/form row")
	test.check(ashbeast.special_kind == BossPhaseDataScript.SpecialKind.RUSH and ashbeast.sprite_row_override == 1, "Veyra transformation phase lost rush/form row")
	test.check(rupture.special_kind == BossPhaseDataScript.SpecialKind.CISTERN_BURST and rupture.sprite_row_override == 1, "Veyra rupture phase lost cistern burst/form row")
	test.check(marshal.health_threshold_ratio > ashbeast.health_threshold_ratio and ashbeast.health_threshold_ratio > rupture.health_threshold_ratio, "Veyra phase thresholds are not descending")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	for _stage in range(4):
		game._advance_campaign_stage()
		await test.tree.process_frame
	test.check(game.campaign_stage_index == 4 and game.active_stage_definition == STAGE_5, "campaign did not advance to Stage 5")
	test.check(game.encounter_director.encounters.size() == 5 and test.tree.get_nodes_in_group("disaster_hazards").size() == 5, "Stage 5 runtime did not instantiate encounters/hazards")

	var fire: Node = null
	var smoke: Node = null
	var jet: Node = null
	for hazard in test.tree.get_nodes_in_group("disaster_hazards"):
		hazard.set_physics_process(false)
		match hazard.definition.hazard_kind:
			DisasterHazardDataScript.HazardKind.FIRE_PATCH:
				if fire == null: fire = hazard
			DisasterHazardDataScript.HazardKind.SMOKE_CLOUD:
				smoke = hazard
			DisasterHazardDataScript.HazardKind.CISTERN_JET:
				if jet == null: jet = hazard
	test.check(fire != null and smoke != null and jet != null, "Stage 5 did not create all disaster hazard kinds")
	game.player.invulnerable = 0.0
	game.player.position = fire.position
	var health_before_fire: int = game.player.health
	fire.disaster_cycle_time = fire.definition.cycle_duration - fire.definition.active_duration + 0.01
	fire._tick_disaster_hazard(0.01)
	test.check(fire.disaster_damage_active and game.player.health == health_before_fire - fire.definition.contact_damage, "active fire patch did not damage the player")
	game.player.invulnerable = 0.0
	game.player.position = smoke.position
	game.player.velocity = Vector2(200.0, 0.0)
	smoke.disaster_cycle_time = smoke.definition.cycle_duration - smoke.definition.active_duration + 0.01
	smoke._tick_disaster_hazard(0.01)
	test.check(game.player.velocity.x < 200.0, "smoke cloud did not slow movement")
	game.player.invulnerable = 0.0
	game.player.position = jet.position
	var x_before_jet: float = game.player.position.x
	jet.disaster_cycle_time = jet.definition.cycle_duration - jet.definition.active_duration + 0.01
	jet._tick_disaster_hazard(0.1)
	test.check(game.player.position.x != x_before_jet, "cistern jet did not push the player")

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
		if enemy.definition.enemy_id == &"cinder_matriarch": boss = enemy
	test.check(boss != null and boss.boss_phase_index == 0 and boss._visual_sprite_row() == 0, "Veyra did not spawn in human marshal form")
	if boss == null:
		await test.dispose(game)
		return
	boss._execute_boss_special()
	test.check(boss.behavior_event_history.has(&"boss_ember_surge") and test.tree.get_nodes_in_group("furnace_waves").size() == 2, "Veyra human form did not emit ember surge")
	boss.invulnerable = 0.0
	boss.take_hit(9999, Vector2(280.0, -30.0), true)
	test.check(boss.boss_phase_index == 1 and boss._visual_sprite_row() == 1, "Veyra did not transform to ashbeast atlas row")
	test.check(game.remaining_enemies == 3 and game.boss_phase_history == [&"fire_marshal", &"ashbeast"], "Veyra ashbeast transition/reinforcements drifted")
	boss.boss_transition_timer = 0.0
	boss.behavior_direction = Vector2.LEFT
	boss._execute_boss_special()
	test.check(boss.behavior_phase == boss.BehaviorPhase.BURST and boss.behavior_event_history.has(&"boss_rush"), "Veyra ashbeast form did not enter rush behavior")
	boss.invulnerable = 0.0
	boss._cancel_behavior()
	boss.take_hit(9999, Vector2(280.0, -30.0), true)
	test.check(boss.boss_phase_index == 2 and boss._visual_sprite_row() == 1, "Veyra did not reach cistern rupture form")
	boss.boss_transition_timer = 0.0
	boss._execute_boss_special()
	test.check(boss.behavior_event_history.has(&"boss_cistern_burst") and test.tree.get_nodes_in_group("tidal_waves").size() == 2, "Veyra rupture form did not emit opposing cistern waves")
	test.check(game.boss_phase_history == [&"fire_marshal", &"ashbeast", &"cistern_rupture"], "Veyra full transformation history drifted")
	await test.dispose(game)
