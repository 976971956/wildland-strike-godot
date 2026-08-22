extends RefCounted

const BossPhaseDataScript = preload("res://core/combat/boss_phase_data.gd")
const EnvironmentObjectDataScript = preload("res://core/stages/environment_object_data.gd")
const LabHazardDataScript = preload("res://core/stages/lab_hazard_data.gd")
const STAGE_8 = preload("res://data/stages/stage_8/stage_8.tres")
const CALDER = preload("res://data/enemies/architect_calder.tres")


func run(test) -> void:
	test.check(STAGE_8 != null and STAGE_8.is_valid_stage(), "Stage 8 Genesis Protocol definition is invalid")
	test.check(STAGE_8.stage_id == &"stage_8" and STAGE_8.stage_number == 8, "Stage 8 identity drifted")
	test.check(STAGE_8.display_name == "THE GENESIS PROTOCOL" and STAGE_8.time_limit_seconds == 330.0, "Stage 8 presentation/timer drifted")
	test.check(STAGE_8.enemy_health_scale == 1.62 and STAGE_8.enemy_damage_scale == 1.3 and STAGE_8.clear_bonus == 20000, "Stage 8 campaign profile drifted")
	test.check(STAGE_8.scenes.size() == 3 and STAGE_8.end_x() == 4200.0, "Stage 8 should be three contiguous 4,200px scenes")
	var expected_scene_ids := [&"gene_forge_causeway", &"specimen_gallery", &"genesis_core"]
	var expected_themes := [21, 22, 23]
	var previous_end := 0.0
	var hazard_kind_counts := {0: 0, 1: 0, 2: 0}
	for index in range(STAGE_8.scenes.size()):
		var scene: Resource = STAGE_8.scenes[index]
		test.check(scene.is_valid_scene(), "%s scene is invalid" % scene.scene_id)
		test.check(scene.scene_id == expected_scene_ids[index] and scene.visual_theme == expected_themes[index], "Stage 8 scene order/theme drifted")
		test.check(scene.start_x == previous_end, "Stage 8 scene continuity failed")
		test.check(scene.background_texture.get_width() == 1672 and scene.background_texture.get_height() == 941, "Stage 8 background dimensions drifted")
		previous_end = scene.end_x
		for object_definition in scene.environment_objects:
			test.check(object_definition.kind == EnvironmentObjectDataScript.ObjectKind.LAB_HAZARD and object_definition.is_valid_object(), "%s lab hazard is invalid" % object_definition.object_id)
			hazard_kind_counts[object_definition.hazard_kind] += 1
	test.check(hazard_kind_counts == {0: 2, 1: 2, 2: 2}, "Stage 8 arc/mutagen/core hazard distribution drifted")

	var encounters: Array[Resource] = STAGE_8.all_encounters()
	test.check(encounters.size() == 5, "Stage 8 encounter count drifted")
	test.check(encounters.map(func(encounter: Resource): return encounter.encounter_id) == [&"quarantine_breach", &"elite_gauntlet", &"specimen_containment", &"genesis_threshold", &"architect_calder_showdown"], "Stage 8 encounter order drifted")
	var total_spawns := 0
	for encounter in encounters:
		test.check(encounter.is_valid_encounter(), "%s encounter is invalid" % encounter.encounter_id)
		total_spawns += encounter.total_spawn_count()
	test.check(total_spawns == 19, "Stage 8 authored population drifted")
	test.check(encounters[1].waves[0].spawns.map(func(spawn: Resource): return spawn.enemy_id) == [&"elite_enforcer", &"elite_blade", &"elite_bombardier", &"elite_bulwark"], "Stage 8 elite gauntlet lost a protocol")

	test.check(CALDER.is_valid_definition() and CALDER.boss_phases.size() == 3, "Architect Calder final boss definition is invalid")
	test.check(CALDER.sprite_sheet.get_width() == 2560 and CALDER.sprite_sheet.get_height() == 960, "Architect Calder atlas contract drifted")
	test.check(CALDER.sprite_columns == 8 and CALDER.sprite_rows == 3, "Architect Calder atlas grid drifted")
	var architect: Resource = CALDER.boss_phases[0]
	var apex: Resource = CALDER.boss_phases[1]
	var core: Resource = CALDER.boss_phases[2]
	test.check(architect.health_threshold_ratio > apex.health_threshold_ratio and apex.health_threshold_ratio > core.health_threshold_ratio, "Calder phase thresholds are not descending")
	test.check(architect.special_kind == BossPhaseDataScript.SpecialKind.GENESIS_BARRAGE, "Calder human form lost Genesis barrage")
	test.check(apex.special_kind == BossPhaseDataScript.SpecialKind.RUSH and apex.burst_speed_scale > 2.0, "Calder Apex Mantle lost its rush")
	test.check(core.special_kind == BossPhaseDataScript.SpecialKind.CORE_COLLAPSE, "Calder exposed core lost collapse attack")
	test.check([architect.sprite_row_override, apex.sprite_row_override, core.sprite_row_override] == [0, 1, 2], "Calder form rows drifted")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	for _stage in range(7):
		game._advance_campaign_stage()
		await test.tree.process_frame
	test.check(game.campaign_stage_index == 7 and game.active_stage_definition == STAGE_8, "campaign did not advance to Stage 8")
	test.check(game.encounter_director.encounters.size() == 5 and test.tree.get_nodes_in_group("lab_hazards").size() == 6, "Stage 8 runtime did not instantiate encounters/hazards")

	var arc: Node = null
	var mutagen: Node = null
	var surge: Node = null
	for hazard in test.tree.get_nodes_in_group("lab_hazards"):
		hazard.set_physics_process(false)
		match hazard.definition.hazard_kind:
			LabHazardDataScript.HazardKind.ARC_FIELD:
				if arc == null: arc = hazard
			LabHazardDataScript.HazardKind.MUTAGEN_POOL:
				if mutagen == null: mutagen = hazard
			LabHazardDataScript.HazardKind.CORE_SURGE:
				if surge == null: surge = hazard
	test.check(arc != null and mutagen != null and surge != null, "Stage 8 did not create all laboratory hazard kinds")
	game.player.invulnerable = 0.0
	game.player.position = arc.position
	var arc_health_before: int = game.player.health
	arc.lab_cycle_time = arc.definition.cycle_duration - arc.definition.active_duration + 0.01
	arc._tick_lab_hazard(0.01)
	test.check(game.player.health == arc_health_before - arc.definition.contact_damage, "containment arc did not damage the player")
	game.player.invulnerable = 0.0
	game.player.position = mutagen.position
	game.player.velocity = Vector2(200.0, 0.0)
	mutagen.lab_cycle_time = mutagen.definition.cycle_duration - mutagen.definition.active_duration + 0.01
	mutagen._tick_lab_hazard(0.01)
	test.check(game.player.velocity.x < 200.0, "mutagen pool did not slow movement")
	game.player.invulnerable = 0.0
	game.player.position = surge.position
	var surge_x_before: float = game.player.position.x
	surge.lab_cycle_time = surge.definition.cycle_duration - surge.definition.active_duration + 0.01
	surge._tick_lab_hazard(0.08)
	test.check(game.player.position.x != surge_x_before, "core surge did not displace the player")

	for existing_enemy in test.tree.get_nodes_in_group("enemies"):
		existing_enemy.queue_free()
	await test.tree.process_frame
	game.encounter_director.active = false
	game.encounter_director.remaining_enemies = 0
	game.encounter_director.current_encounter_index = 4
	game.encounter_director.completed = false
	game.encounter_director.force_start_encounter(4)
	var calder: Node = null
	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if enemy.definition.enemy_id == &"architect_calder": calder = enemy
	test.check(calder != null, "Architect Calder did not spawn in the final arena")
	if calder == null:
		await test.dispose(game)
		return
	test.check(game.hud.boss_name == "ARCHITECT SERA CALDER" and game.hud.boss_max == calder.max_health, "final boss HUD identity drifted")
	calder._execute_boss_special()
	test.check(calder.behavior_event_history.has(&"boss_genesis_barrage") and test.tree.get_nodes_in_group("vault_energy_lanes").size() == 4, "Calder Genesis barrage did not emit four alternating lanes")
	calder.invulnerable = 0.0
	calder.take_hit(9999, Vector2(280.0, -30.0), true)
	calder.boss_transition_timer = 0.0
	calder.behavior_direction = Vector2.LEFT
	calder._execute_boss_special()
	test.check(calder.boss_phase_index == 1 and calder.behavior_event_history.has(&"boss_rush"), "Calder Apex Mantle did not enter rush")
	calder.invulnerable = 0.0
	calder.take_hit(9999, Vector2(280.0, -30.0), true)
	calder.boss_transition_timer = 0.0
	calder._execute_boss_special()
	test.check(calder.boss_phase_index == 2 and calder.behavior_event_history.has(&"boss_core_collapse") and test.tree.get_nodes_in_group("genesis_collapse_zones").size() >= 2, "Calder Genesis Core did not create collapse zones")
	test.check(game.boss_phase_history.has(&"architect") and game.boss_phase_history.has(&"apex_mantle") and game.boss_phase_history.has(&"genesis_core"), "final boss phase history drifted")
	await test.dispose(game)
