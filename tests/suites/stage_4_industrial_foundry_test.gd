extends RefCounted

const BossPhaseDataScript = preload("res://core/combat/boss_phase_data.gd")
const EnvironmentObjectDataScript = preload("res://core/stages/environment_object_data.gd")
const IndustrialHazardDataScript = preload("res://core/stages/industrial_hazard_data.gd")
const STAGE_4 = preload("res://data/stages/stage_4/stage_4.tres")
const FORGE_REGENT = preload("res://data/enemies/forge_regent.tres")


func run(test) -> void:
	test.check(STAGE_4 != null and STAGE_4.is_valid_stage(), "Stage 4 industrial definition is invalid")
	test.check(STAGE_4.stage_id == &"stage_4" and STAGE_4.stage_number == 4, "Stage 4 identity drifted")
	test.check(STAGE_4.display_name == "THE IRON FOUNDRY" and STAGE_4.time_limit_seconds == 270.0, "Stage 4 presentation/timer drifted")
	test.check(STAGE_4.scenes.size() == 3 and STAGE_4.end_x() == 4200.0, "Stage 4 should be three contiguous 4,200px scenes")
	test.check(not STAGE_4.is_vehicle_stage(), "Stage 4 should restore on-foot combat")
	var expected_scene_ids := [&"motor_pool_breach", &"assembly_floor", &"crucible_lift"]
	var expected_themes := [9, 10, 11]
	var previous_end := 0.0
	var hazard_kind_counts := {0: 0, 1: 0, 2: 0}
	for index in range(STAGE_4.scenes.size()):
		var scene: Resource = STAGE_4.scenes[index]
		test.check(scene.is_valid_scene(), "%s scene is invalid" % scene.scene_id)
		test.check(scene.scene_id == expected_scene_ids[index] and scene.visual_theme == expected_themes[index], "Stage 4 scene order/theme drifted")
		test.check(scene.start_x == previous_end, "Stage 4 scene continuity failed")
		test.check(scene.background_texture.get_width() == 1672 and scene.background_texture.get_height() == 941, "Stage 4 background dimensions drifted")
		previous_end = scene.end_x
		for object_definition in scene.environment_objects:
			test.check(object_definition.is_valid_object(), "%s industrial object is invalid" % object_definition.object_id)
			if object_definition.kind == EnvironmentObjectDataScript.ObjectKind.INDUSTRIAL_HAZARD:
				hazard_kind_counts[object_definition.hazard_kind] += 1
	test.check(hazard_kind_counts == {0: 1, 1: 2, 2: 2}, "Stage 4 industrial hazard distribution drifted")

	var encounters: Array[Resource] = STAGE_4.all_encounters()
	test.check(encounters.size() == 5, "Stage 4 encounter count drifted")
	test.check(encounters.map(func(encounter: Resource): return encounter.encounter_id) == [&"motor_pool_breach", &"assembly_line_lock", &"press_gauntlet", &"crucible_ascent", &"forge_regent_showdown"], "Stage 4 encounter order drifted")
	var total_spawns := 0
	for encounter in encounters:
		test.check(encounter.is_valid_encounter(), "%s encounter is invalid" % encounter.encounter_id)
		total_spawns += encounter.total_spawn_count()
	test.check(total_spawns == 17, "Stage 4 authored population drifted")

	test.check(FORGE_REGENT.is_valid_definition() and FORGE_REGENT.boss_phases.size() == 3, "Forge Regent definition is invalid")
	test.check(FORGE_REGENT.sprite_sheet.get_width() == 2560 and FORGE_REGENT.sprite_sheet.get_height() == 320, "Forge Regent runtime atlas contract drifted")
	var smelter: Resource = FORGE_REGENT.boss_phases[0]
	var polarity: Resource = FORGE_REGENT.boss_phases[1]
	var overdrive: Resource = FORGE_REGENT.boss_phases[2]
	test.check(smelter.special_kind == BossPhaseDataScript.SpecialKind.FURNACE_BLAST, "Forge Regent opening lost furnace blast")
	test.check(polarity.special_kind == BossPhaseDataScript.SpecialKind.MAGNET_PULL, "Forge Regent middle phase lost magnetic pull")
	test.check(overdrive.special_kind == BossPhaseDataScript.SpecialKind.FURNACE_BLAST, "Forge Regent final phase lost overdrive blast")
	test.check(smelter.health_threshold_ratio > polarity.health_threshold_ratio and polarity.health_threshold_ratio > overdrive.health_threshold_ratio, "Forge Regent phase thresholds are not descending")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	var second_player: Node = game.join_local_player(0, 1)
	var third_player: Node = game.join_local_player(1, 2)
	game.score = 8420
	game.lives = 1
	for _stage in range(3):
		game._advance_campaign_stage()
		await test.tree.process_frame
	test.check(game.campaign_stage_index == 3 and game.active_stage_definition == STAGE_4, "campaign did not advance to Stage 4")
	test.check(game.score == 8420 and game.lives == 1, "Stage 4 transition did not preserve score/lives")
	test.check(second_player != null and third_player != null and game.get_local_players().size() == 3, "Stage 4 lost the three-player roster")
	test.check(not is_instance_valid(game.highway_vehicle), "Stage 4 did not release the highway vehicle")
	test.check(game.player.visible and second_player.visible and third_player.visible, "Stage 4 did not restore on-foot fighter sprites")

	var conveyor: Node = null
	var press: Node = null
	for hazard in test.tree.get_nodes_in_group("industrial_hazards"):
		hazard.set_physics_process(false)
		if hazard.definition.hazard_kind == IndustrialHazardDataScript.HazardKind.CONVEYOR:
			conveyor = hazard
		elif hazard.definition.hazard_kind == IndustrialHazardDataScript.HazardKind.PISTON_PRESS and press == null:
			press = hazard
	test.check(conveyor != null and press != null, "Stage 4 did not instantiate conveyor and press hazards")
	if conveyor != null:
		game.player.position = conveyor.position
		var x_before: float = game.player.position.x
		conveyor._tick_industrial_hazard(0.25)
		test.check(game.player.position.x < x_before, "assembly conveyor did not push the player in its authored direction")
	if press != null:
		game.player.position = press.position
		game.player.invulnerable = 0.0
		var health_before: int = game.player.health
		press.industrial_cycle_time = press.definition.cycle_duration - press.definition.active_duration + 0.01
		press._tick_industrial_hazard(0.01)
		test.check(press.industrial_damage_active and game.player.health == health_before - press.definition.contact_damage, "active piston press did not damage the player")

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
		if enemy.definition.enemy_id == &"forge_regent":
			boss = enemy
	test.check(boss != null and boss.boss_phase_index == 0, "Forge Regent did not spawn in smelter phase")
	if boss == null:
		await test.dispose(game)
		return
	boss._execute_boss_special()
	test.check(boss.behavior_event_history.has(&"boss_furnace_blast") and test.tree.get_nodes_in_group("furnace_waves").size() == 2, "Forge Regent smelter phase did not emit two furnace waves")

	boss.invulnerable = 0.0
	boss.take_hit(9999, Vector2(280.0, -30.0), true)
	test.check(boss.boss_phase_index == 1 and boss.health == ceili(boss.max_health * polarity.health_threshold_ratio), "Forge Regent skipped polarity gate")
	test.check(game.remaining_enemies == 3, "polarity reinforcements were not registered")
	boss.boss_transition_timer = 0.0
	game.player.position = boss.position + Vector2(-260.0, 0.0)
	game.player.invulnerable = 0.0
	var pull_health_before: int = game.player.health
	boss._execute_boss_special()
	test.check(game.player.health < pull_health_before and game.player.velocity.x > 0.0, "magnetic pull did not drag the player toward Volkr")
	test.check(boss.behavior_event_history.has(&"boss_magnet_pull") and boss.boss_special_pose_column == 4, "magnetic pull event/pose was not observable")

	boss.invulnerable = 0.0
	boss.boss_transition_timer = 0.0
	boss.take_hit(9999, Vector2(280.0, -30.0), true)
	test.check(boss.boss_phase_index == 2 and boss.health == ceili(boss.max_health * overdrive.health_threshold_ratio), "Forge Regent skipped overdrive gate")
	test.check(game.boss_phase_history == [&"smelter", &"polarity", &"overdrive"], "Forge Regent phase history drifted")
	test.check(game.remaining_enemies == 4, "overdrive reinforcement was not registered")

	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(true)
		enemy.invulnerable = 0.0
		enemy.boss_transition_timer = 0.0
		enemy.take_hit(9999, Vector2(300.0, 0.0), true)
	await test.wait_physics_frames(58)
	test.check(game.encounter_director.completed and game.state == "victory", "Stage 4 industrial boss encounter did not complete")
	await test.dispose(game)
