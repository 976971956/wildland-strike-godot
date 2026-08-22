extends RefCounted

const BossPhaseDataScript = preload("res://core/combat/boss_phase_data.gd")
const EnvironmentObjectDataScript = preload("res://core/stages/environment_object_data.gd")
const VaultHazardDataScript = preload("res://core/stages/vault_hazard_data.gd")
const STAGE_7 = preload("res://data/stages/stage_7/stage_7.tres")
const ORIN = preload("res://data/enemies/vault_sentinel_orin.tres")
const NYX = preload("res://data/enemies/vault_sentinel_nyx.tres")


func run(test) -> void:
	test.check(STAGE_7 != null and STAGE_7.is_valid_stage(), "Stage 7 underground vault definition is invalid")
	test.check(STAGE_7.stage_id == &"stage_7" and STAGE_7.stage_number == 7, "Stage 7 identity drifted")
	test.check(STAGE_7.display_name == "THE SEVENTH LOCK" and STAGE_7.time_limit_seconds == 315.0, "Stage 7 presentation/timer drifted")
	test.check(STAGE_7.enemy_health_scale == 1.52 and STAGE_7.enemy_damage_scale == 1.25 and STAGE_7.clear_bonus == 16000, "Stage 7 campaign profile drifted")
	test.check(STAGE_7.scenes.size() == 3 and STAGE_7.end_x() == 4200.0, "Stage 7 should be three contiguous 4,200px scenes")
	var expected_scene_ids := [&"vault_elevator_descent", &"cryogenic_vault_hall", &"twin_core_vault"]
	var expected_themes := [18, 19, 20]
	var previous_end := 0.0
	var hazard_kind_counts := {0: 0, 1: 0, 2: 0}
	for index in range(STAGE_7.scenes.size()):
		var scene: Resource = STAGE_7.scenes[index]
		test.check(scene.is_valid_scene(), "%s scene is invalid" % scene.scene_id)
		test.check(scene.scene_id == expected_scene_ids[index] and scene.visual_theme == expected_themes[index], "Stage 7 scene order/theme drifted")
		test.check(scene.start_x == previous_end, "Stage 7 scene continuity failed")
		test.check(scene.background_texture.get_width() == 1672 and scene.background_texture.get_height() == 941, "Stage 7 background dimensions drifted")
		previous_end = scene.end_x
		for object_definition in scene.environment_objects:
			test.check(object_definition.kind == EnvironmentObjectDataScript.ObjectKind.VAULT_HAZARD and object_definition.is_valid_object(), "%s vault hazard is invalid" % object_definition.object_id)
			hazard_kind_counts[object_definition.hazard_kind] += 1
	test.check(hazard_kind_counts == {0: 2, 1: 2, 2: 2}, "Stage 7 deck/laser/cryo hazard distribution drifted")

	var encounters: Array[Resource] = STAGE_7.all_encounters()
	test.check(encounters.size() == 5, "Stage 7 encounter count drifted")
	test.check(encounters.map(func(encounter: Resource): return encounter.encounter_id) == [&"elevator_boarding", &"counterweight_ambush", &"cryo_perimeter", &"seventh_lock", &"vault_sentinels_showdown"], "Stage 7 encounter order drifted")
	var total_spawns := 0
	for encounter in encounters:
		test.check(encounter.is_valid_encounter(), "%s encounter is invalid" % encounter.encounter_id)
		total_spawns += encounter.total_spawn_count()
	test.check(total_spawns == 18, "Stage 7 authored population drifted")

	for boss in [ORIN, NYX]:
		test.check(boss.is_valid_definition() and boss.boss_phases.size() == 2, "%s paired boss definition is invalid" % boss.enemy_id)
		test.check(boss.sprite_sheet.get_width() == 2560 and boss.sprite_sheet.get_height() == 640, "%s atlas contract drifted" % boss.enemy_id)
		test.check(boss.sprite_columns == 8 and boss.sprite_rows == 2, "%s atlas grid drifted" % boss.enemy_id)
	test.check(ORIN.boss_phases[0].special_kind == BossPhaseDataScript.SpecialKind.BARRIER_PULSE, "Orin lost barrier pulse")
	test.check(ORIN.boss_phases[1].special_kind == BossPhaseDataScript.SpecialKind.SYNC_CROSSFIRE, "Orin lost lockstep crossfire")
	test.check(NYX.boss_phases[0].special_kind == BossPhaseDataScript.SpecialKind.RUSH, "Nyx lost phase-blade rush")
	test.check(NYX.boss_phases[1].special_kind == BossPhaseDataScript.SpecialKind.SYNC_CROSSFIRE, "Nyx lost lockstep crossfire")
	test.check(ORIN.boss_phases[0].sprite_row_override == 0 and NYX.boss_phases[0].sprite_row_override == 1, "paired boss atlas rows drifted")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	for _stage in range(6):
		game._advance_campaign_stage()
		await test.tree.process_frame
	test.check(game.campaign_stage_index == 6 and game.active_stage_definition == STAGE_7, "campaign did not advance to Stage 7")
	test.check(game.encounter_director.encounters.size() == 5 and test.tree.get_nodes_in_group("vault_hazards").size() == 6, "Stage 7 runtime did not instantiate encounters/hazards")

	var deck: Node = null
	var laser: Node = null
	var cryo: Node = null
	for hazard in test.tree.get_nodes_in_group("vault_hazards"):
		hazard.set_physics_process(false)
		match hazard.definition.hazard_kind:
			VaultHazardDataScript.HazardKind.DECK_SHIFT:
				if deck == null: deck = hazard
			VaultHazardDataScript.HazardKind.SECURITY_LASER:
				if laser == null: laser = hazard
			VaultHazardDataScript.HazardKind.CRYO_VENT:
				if cryo == null: cryo = hazard
	test.check(deck != null and laser != null and cryo != null, "Stage 7 did not create all vault hazard kinds")
	game.player.invulnerable = 0.0
	game.player.position = deck.position
	var deck_x_before: float = game.player.position.x
	deck.vault_cycle_time = deck.definition.cycle_duration - deck.definition.active_duration + 0.01
	deck._tick_vault_hazard(0.08)
	test.check(game.player.position.x != deck_x_before, "active elevator deck shift did not move the player")
	game.player.invulnerable = 0.0
	game.player.position = laser.position
	var laser_health_before: int = game.player.health
	laser.vault_cycle_time = laser.definition.cycle_duration - laser.definition.active_duration + 0.01
	laser._tick_vault_hazard(0.01)
	test.check(game.player.health == laser_health_before - laser.definition.contact_damage, "security laser did not damage the player")
	game.player.invulnerable = 0.0
	game.player.position = cryo.position
	game.player.velocity = Vector2(200.0, 0.0)
	cryo.vault_cycle_time = cryo.definition.cycle_duration - cryo.definition.active_duration + 0.01
	cryo._tick_vault_hazard(0.01)
	test.check(game.player.velocity.x < 200.0, "cryo vent did not slow movement")

	for existing_enemy in test.tree.get_nodes_in_group("enemies"):
		existing_enemy.queue_free()
	await test.tree.process_frame
	game.encounter_director.active = false
	game.encounter_director.remaining_enemies = 0
	game.encounter_director.current_encounter_index = 4
	game.encounter_director.completed = false
	game.encounter_director.force_start_encounter(4)
	var orin: Node = null
	var nyx: Node = null
	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if enemy.definition.enemy_id == &"vault_sentinel_orin": orin = enemy
		if enemy.definition.enemy_id == &"vault_sentinel_nyx": nyx = enemy
	test.check(orin != null and nyx != null, "paired Vault Sentinels did not spawn together")
	if orin == null or nyx == null:
		await test.dispose(game)
		return
	test.check(game.hud.boss_name == "VAULT SENTINELS" and game.hud.boss_max == orin.max_health + nyx.max_health, "paired boss HUD did not aggregate both health pools")
	orin._execute_boss_special()
	test.check(orin.behavior_event_history.has(&"boss_barrier_pulse") and test.tree.get_nodes_in_group("vault_energy_lanes").size() == 3, "Orin barrier pulse did not emit three lanes")
	nyx.behavior_direction = Vector2.LEFT
	nyx._execute_boss_special()
	test.check(nyx.behavior_phase == nyx.BehaviorPhase.BURST and nyx.behavior_event_history.has(&"boss_rush"), "Nyx opening phase did not enter blade rush")
	orin.invulnerable = 0.0
	orin.take_hit(9999, Vector2(280.0, -30.0), true)
	orin.boss_transition_timer = 0.0
	orin._execute_boss_special()
	test.check(orin.boss_phase_index == 1 and orin.behavior_event_history.has(&"boss_sync_crossfire") and test.tree.get_nodes_in_group("vault_energy_lanes").size() == 7, "Orin lockstep phase did not add four crossfire lanes")
	nyx.invulnerable = 0.0
	nyx.take_hit(9999, Vector2(280.0, -30.0), true)
	nyx.boss_transition_timer = 0.0
	nyx._execute_boss_special()
	test.check(nyx.boss_phase_index == 1 and test.tree.get_nodes_in_group("vault_energy_lanes").size() == 11, "Nyx lockstep phase did not add four crossfire lanes")
	test.check(game.boss_phase_history.has(&"orin_aegis") and game.boss_phase_history.has(&"nyx_phase_blades") and game.boss_phase_history.has(&"orin_lockstep") and game.boss_phase_history.has(&"nyx_lockstep"), "paired boss phase history drifted")
	await test.dispose(game)
