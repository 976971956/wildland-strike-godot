extends RefCounted

const EnvironmentObjectDataScript = preload("res://core/stages/environment_object_data.gd")
const STAGE_1 = preload("res://data/stages/stage_1/stage_1.tres")


func run(test) -> void:
	var all_objects: Array[Resource] = []
	var background_paths := {}
	for scene in STAGE_1.scenes:
		all_objects.append_array(scene.environment_objects)
		test.check(scene.background_texture != null, "%s has no scene-specific background" % scene.scene_id)
		if scene.background_texture != null:
			background_paths[scene.background_texture.resource_path] = true
	test.check(background_paths.size() == 3, "Stage 1 scenes do not use three independent background assets")
	test.check(all_objects.size() == 7, "Stage 1 environment object count drifted")
	var object_ids := {}
	var breakable_count := 0
	var hazard_count := 0
	var carryable_count := 0
	for object_definition in all_objects:
		test.check(object_definition.is_valid_object(), "%s environment object is invalid" % object_definition.object_id)
		test.check(not object_ids.has(object_definition.object_id), "%s environment object id is duplicated" % object_definition.object_id)
		object_ids[object_definition.object_id] = true
		match object_definition.kind:
			EnvironmentObjectDataScript.ObjectKind.BREAKABLE:
				breakable_count += 1
				test.check(not object_definition.drop_id.is_empty(), "%s breakable has no deterministic drop" % object_definition.object_id)
			EnvironmentObjectDataScript.ObjectKind.ROLLING_HAZARD:
				hazard_count += 1
				test.check(object_definition.move_max_x > object_definition.move_min_x, "rolling hazard travel bounds are invalid")
			EnvironmentObjectDataScript.ObjectKind.CARRYABLE:
				carryable_count += 1
				test.check(object_definition.throw_damage > 0 and object_definition.throw_speed > 0.0, "%s carryable throw data is invalid" % object_definition.object_id)
	test.check(breakable_count == 3 and hazard_count == 1 and carryable_count == 3, "Stage 1 breakable/hazard/carryable mix drifted")
	test.check(not EnvironmentObjectDataScript.new().is_valid_object(), "empty environment object should be invalid")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	test.check(test.tree.get_nodes_in_group("breakables").size() == 6, "game did not instantiate all breakables and carryable props")
	test.check(test.tree.get_nodes_in_group("carryables").size() == 3, "game did not instantiate all carryable props")
	test.check(test.tree.get_nodes_in_group("stage_hazards").size() == 1, "game did not instantiate the rolling hazard")
	test.check(game.stage_time_remaining == 240.0, "stage timer did not initialize from StageDefinition")
	test.check(game.hud.stage_time_remaining == 240.0, "HUD timer did not initialize")

	var entered_ids: Array[StringName] = []
	game.encounter_director.scene_entered.connect(
		func(scene: Resource, _index: int) -> void: entered_ids.append(scene.scene_id)
	)
	game.encounter_director._update_scene(260.0)
	game.encounter_director._update_scene(1200.0)
	game.encounter_director._update_scene(2800.0)
	test.check(
		entered_ids == [&"ruined_avenue", &"flooded_courtyard", &"processing_plant"],
		"scene transition signals are missing or out of order"
	)
	test.check(game.encounter_director.current_scene_index == 2, "director did not retain current scene index")

	game._start_game()
	var crate: Node = test.tree.get_nodes_in_group("breakables")[0]
	crate.set_physics_process(false)
	var crate_health_before: int = crate.health
	game.player.position = crate.position - Vector2(50.0, 0.0)
	game.player.facing = 1
	game.player.attack_timer = 0.0
	game.player._start_attack()
	game.player.attack_timer = game.player.current_attack.hit_trigger_remaining - 0.001
	game.player._check_attack_hit()
	test.check(crate.health < crate_health_before, "player attack did not damage the breakable")
	test.check(game.last_impact_profile_id == game.player.current_attack.impact_profile.profile_id, "breakable hit lost attack impact feedback")
	var score_before_break: int = game.score
	while is_instance_valid(crate) and not crate.is_defeated:
		crate.take_stage_hit(999, 1)
	await test.tree.process_frame
	test.check(game.score > score_before_break, "destroying a breakable did not award configured score")
	test.check(test.tree.get_nodes_in_group("pickups").size() == 1, "breakable did not create its deterministic drop")
	test.check(test.tree.get_nodes_in_group("breakables").size() == 5, "destroyed breakable remained registered")

	var hazard: Node = test.tree.get_nodes_in_group("stage_hazards")[0]
	hazard.set_physics_process(false)
	game.player.invulnerable = 0.0
	game.player.position = hazard.position
	var player_health_before: int = game.player.health
	hazard.contact_cooldown = 0.0
	hazard._resolve_hazard_contact()
	test.check(game.player.health == player_health_before - hazard.definition.contact_damage, "rolling hazard did not damage player")
	test.check(hazard.contact_cooldown > 0.0, "rolling hazard did not arm contact cooldown")

	game.player.position = Vector2(200.0, 500.0)
	game.spawn_enemy(hazard.position, "grunt")
	var enemy: Node = test.tree.get_nodes_in_group("enemies")[-1]
	enemy.set_physics_process(false)
	var enemy_health_before: int = enemy.health
	hazard.contact_cooldown = 0.0
	hazard._resolve_hazard_contact()
	test.check(enemy.health == enemy_health_before - hazard.definition.contact_damage, "rolling hazard did not damage enemy")
	test.check(enemy.knockdown_state, "rolling hazard did not knock enemy down")
	hazard.position.x = hazard.definition.move_max_x - 1.0
	hazard.direction = 1
	hazard._physics_process(0.1)
	test.check(hazard.position.x == hazard.definition.move_max_x and hazard.direction == -1, "rolling hazard did not bounce at travel bound")

	game.stage_time_remaining = 0.01
	game._process(0.02)
	test.check(game.stage_timed_out and game.state == "gameover", "stage timer did not enter timeout game-over state")
	test.check(game.hud.mode == "gameover", "stage timeout did not update HUD mode")
	test.check(not game.player.is_physics_processing(), "stage timeout did not stop player simulation")

	var player_source := FileAccess.get_file_as_string("res://scripts/player.gd")
	test.check(player_source.contains("get_nodes_in_group(\"breakables\")"), "player targeting is not wired to breakables")
	var world_source := FileAccess.get_file_as_string("res://scripts/world_art.gd")
	test.check(world_source.contains("scene.background_texture"), "world art does not render scene-specific background data")
	await test.dispose(game)
