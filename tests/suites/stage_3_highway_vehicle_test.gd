extends RefCounted

const BossPhaseDataScript = preload("res://core/combat/boss_phase_data.gd")
const EnvironmentObjectDataScript = preload("res://core/stages/environment_object_data.gd")
const StreetEnemyScript = preload("res://scripts/enemy.gd")
const STAGE_3 = preload("res://data/stages/stage_3/stage_3.tres")
const IRON_VULTURE = preload("res://data/enemies/iron_vulture.tres")


func run(test) -> void:
	test.check(STAGE_3 != null and STAGE_3.is_valid_stage(), "Stage 3 highway definition is invalid")
	test.check(STAGE_3.stage_id == &"stage_3" and STAGE_3.stage_number == 3, "Stage 3 identity drifted")
	test.check(STAGE_3.display_name == "HIGHWAY OF TEETH" and STAGE_3.time_limit_seconds == 255.0, "Stage 3 presentation/timer drifted")
	test.check(STAGE_3.scenes.size() == 3 and STAGE_3.end_x() == 4200.0, "Stage 3 should be three contiguous 4,200px scenes")
	test.check(STAGE_3.is_vehicle_stage(), "Stage 3 lost its vehicle sequence")
	var vehicle_data: Resource = STAGE_3.vehicle_sequence
	test.check(vehicle_data.is_valid_vehicle_stage(), "highway vehicle resource is invalid")
	test.check(vehicle_data.lane_positions == PackedFloat32Array([490.0, 560.0, 630.0]), "highway lane contract drifted")
	test.check(vehicle_data.maximum_speed > vehicle_data.minimum_speed and vehicle_data.ram_damage > vehicle_data.collision_damage, "driving/combat tuning is not ordered")
	test.check(vehicle_data.mounted_weapon.weapon_id == &"rifle", "mounted weapon is not the authored piercing rifle")
	var interceptor_sheet: Texture2D = load("res://assets/sprites/desert_interceptor_sheet.png")
	test.check(interceptor_sheet != null and interceptor_sheet.get_width() == 1440 and interceptor_sheet.get_height() == 240, "player interceptor runtime atlas contract drifted")

	var expected_scene_ids := [&"canyon_run", &"raider_checkpoint", &"storm_overpass"]
	var expected_themes := [6, 7, 8]
	var previous_end := 0.0
	var road_hazards := 0
	for index in range(STAGE_3.scenes.size()):
		var scene: Resource = STAGE_3.scenes[index]
		test.check(scene.is_valid_scene(), "%s scene is invalid" % scene.scene_id)
		test.check(scene.scene_id == expected_scene_ids[index] and scene.visual_theme == expected_themes[index], "Stage 3 scene order/theme drifted")
		test.check(scene.start_x == previous_end, "Stage 3 scene continuity failed")
		test.check(scene.background_texture.get_width() == 1672 and scene.background_texture.get_height() == 941, "Stage 3 background dimensions drifted")
		previous_end = scene.end_x
		for object_definition in scene.environment_objects:
			test.check(object_definition.is_valid_object(), "%s road object is invalid" % object_definition.object_id)
			if object_definition.kind == EnvironmentObjectDataScript.ObjectKind.ROAD_HAZARD:
				road_hazards += 1
	test.check(road_hazards == 6, "Stage 3 should author two road hazards per scene")

	var encounters: Array[Resource] = STAGE_3.all_encounters()
	test.check(encounters.size() == 5, "Stage 3 encounter count drifted")
	test.check(encounters.map(func(encounter: Resource): return encounter.encounter_id) == [&"canyon_intercept", &"checkpoint_breach", &"convoy_counterattack", &"storm_pursuit", &"iron_vulture_showdown"], "Stage 3 encounter order drifted")
	var total_spawns := 0
	for encounter in encounters:
		test.check(encounter.is_valid_encounter(), "%s encounter is invalid" % encounter.encounter_id)
		total_spawns += encounter.total_spawn_count()
	test.check(total_spawns == 17, "Stage 3 authored population drifted")

	test.check(IRON_VULTURE.is_valid_definition() and IRON_VULTURE.boss_phases.size() == 3, "Iron Vulture definition is invalid")
	test.check(IRON_VULTURE.sprite_sheet.get_width() == 2560 and IRON_VULTURE.sprite_sheet.get_height() == 320, "Iron Vulture runtime atlas contract drifted")
	var pursuit: Resource = IRON_VULTURE.boss_phases[0]
	var minefield: Resource = IRON_VULTURE.boss_phases[1]
	var redline: Resource = IRON_VULTURE.boss_phases[2]
	test.check(pursuit.special_kind == BossPhaseDataScript.SpecialKind.ROAD_RAM, "Iron Vulture opening lost road ram")
	test.check(minefield.special_kind == BossPhaseDataScript.SpecialKind.MINE_DROP, "Iron Vulture middle phase lost mine drop")
	test.check(redline.special_kind == BossPhaseDataScript.SpecialKind.ROAD_RAM, "Iron Vulture final phase lost redline ram")
	test.check(pursuit.health_threshold_ratio > minefield.health_threshold_ratio and minefield.health_threshold_ratio > redline.health_threshold_ratio, "Iron Vulture phase thresholds are not descending")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	var second_player: Node = game.join_local_player(0, 1)
	var third_player: Node = game.join_local_player(1, 2)
	game.score = 6789
	game.lives = 1
	game._advance_campaign_stage()
	await test.tree.process_frame
	game._advance_campaign_stage()
	await test.tree.process_frame
	test.check(game.campaign_stage_index == 2 and game.active_stage_definition == STAGE_3, "campaign did not advance to Stage 3")
	test.check(game.score == 6789 and game.lives == 1, "Stage 3 transition did not preserve score/lives")
	test.check(second_player != null and third_player != null and game.get_local_players().size() == 3, "Stage 3 lost the three-player roster")
	test.check(is_instance_valid(game.highway_vehicle), "Stage 3 did not instantiate the shared highway vehicle")
	if not is_instance_valid(game.highway_vehicle):
		await test.dispose(game)
		return
	var vehicle: Node = game.highway_vehicle
	vehicle.set_physics_process(false)
	test.check(not game.player.is_physics_processing() and not second_player.is_physics_processing() and not third_player.is_physics_processing(), "mounted players should not run the on-foot controller")
	test.check(not game.player.visible and not second_player.visible and not third_player.visible, "standing fighter sprites should be hidden while mounted")
	test.check(game.lead_player_x() == vehicle.position.x, "encounter director does not follow vehicle progress")
	var speed_before: float = vehicle.speed
	vehicle.apply_drive_input(Vector2.RIGHT, 0.5)
	test.check(vehicle.speed > speed_before and vehicle.event_history.has(&"accelerating"), "vehicle acceleration is not observable")
	var original_lane: int = vehicle.lane_index
	vehicle.apply_drive_input(Vector2.DOWN, 0.1)
	test.check(vehicle.lane_index == original_lane + 1 and vehicle.target_lane_y == 630.0, "vehicle lane steering did not select the lower lane")
	test.check(vehicle.request_mounted_attack(0), "primary mounted attack was rejected")
	test.check(vehicle.request_mounted_attack(1), "co-op mounted attack was rejected")
	test.check(vehicle.shot_count == 2 and test.tree.get_nodes_in_group("weapon_projectiles").size() >= 2, "mounted attacks did not create independent projectiles")

	var road_hazard: Node = null
	for stage_object in test.tree.get_nodes_in_group("road_hazards"):
		road_hazard = stage_object
		break
	test.check(road_hazard != null, "Stage 3 transition did not instantiate road hazards")
	if road_hazard != null:
		var hull_before: int = vehicle.hull_health
		var score_before: int = game.score
		vehicle.position = road_hazard.position
		vehicle.hazard_cooldown = 0.0
		vehicle._resolve_contacts()
		test.check(vehicle.hull_health == hull_before - road_hazard.definition.contact_damage, "road collision did not damage vehicle hull")
		test.check(vehicle.hazard_hit_count == 1 and vehicle.event_history.has(&"hazard_collision"), "road collision was not recorded")
		await test.tree.process_frame
		test.check(game.score > score_before, "rammed road hazard did not award score")

	for existing_enemy in test.tree.get_nodes_in_group("enemies"):
		existing_enemy.queue_free()
	await test.tree.process_frame
	game.encounter_director.active = false
	game.encounter_director.remaining_enemies = 0
	game.encounter_director.current_encounter_index = 4
	game.encounter_director.completed = false
	vehicle.position = Vector2(3600.0, 560.0)
	vehicle._mount_players()
	game.encounter_director.force_start_encounter(4)
	var boss: Node = null
	var spawned_enemy_ids := PackedStringArray()
	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		spawned_enemy_ids.append(String(enemy.definition.enemy_id))
		if enemy.definition.enemy_id == &"iron_vulture":
			boss = enemy
	test.check(boss != null and boss.boss_phase_index == 0, "Iron Vulture did not spawn in pursuit phase (spawned=%s active=%s index=%d)" % [spawned_enemy_ids, game.encounter_director.active, game.encounter_director.current_encounter_index])
	if boss == null:
		await test.dispose(game)
		return
	boss.behavior_direction = Vector2.LEFT
	boss._execute_boss_special()
	test.check(boss.behavior_phase == StreetEnemyScript.BehaviorPhase.BURST and boss.behavior_event_history.has(&"boss_road_ram"), "Iron Vulture pursuit ram did not enter burst state")

	boss.invulnerable = 0.0
	boss.take_hit(9999, Vector2(300.0, -40.0), true)
	test.check(boss.boss_phase_index == 1 and boss.health == ceili(boss.max_health * minefield.health_threshold_ratio), "Iron Vulture skipped minefield gate")
	test.check(game.remaining_enemies == 2, "minefield reinforcement was not registered")
	boss.boss_transition_timer = 0.0
	boss._execute_boss_special()
	test.check(boss.behavior_event_history.has(&"boss_mine_drop") and test.tree.get_nodes_in_group("road_mines").size() == 1, "Iron Vulture mine phase did not deploy a mine")
	var mine: Node = test.tree.get_nodes_in_group("road_mines")[0]
	mine.set_physics_process(false)
	vehicle.hazard_cooldown = 0.0
	vehicle.position = mine.position
	var mine_hull_before: int = vehicle.hull_health
	mine.arm_timer = 0.0
	mine._physics_process(0.01)
	test.check(vehicle.hull_health == mine_hull_before - mine.damage, "armed road mine did not damage vehicle hull")

	boss.invulnerable = 0.0
	boss.boss_transition_timer = 0.0
	boss.take_hit(9999, Vector2(300.0, -40.0), true)
	test.check(boss.boss_phase_index == 2 and boss.health == ceili(boss.max_health * redline.health_threshold_ratio), "Iron Vulture skipped redline gate")
	test.check(game.boss_phase_history == [&"pursuit", &"minefield", &"redline"], "Iron Vulture phase history drifted")
	test.check(game.remaining_enemies == 3, "redline reinforcement was not registered")

	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(true)
		enemy.invulnerable = 0.0
		enemy.boss_transition_timer = 0.0
		enemy.take_hit(9999, Vector2(300.0, 0.0), true)
	await test.wait_physics_frames(58)
	test.check(game.encounter_director.completed and game.state == "victory", "Stage 3 vehicle boss encounter did not complete")
	await test.dispose(game)
