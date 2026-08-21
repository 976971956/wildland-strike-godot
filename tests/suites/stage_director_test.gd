extends RefCounted

const StageDefinitionScript = preload("res://core/stages/stage_definition.gd")
const EncounterDefinitionScript = preload("res://core/stages/encounter_definition.gd")
const STAGE_1 = preload("res://data/stages/stage_1/stage_1.tres")


func run(test) -> void:
	test.check(STAGE_1 != null and STAGE_1.is_valid_stage(), "Stage 1 definition is invalid")
	test.check(STAGE_1.stage_id == &"stage_1" and STAGE_1.stage_number == 1, "Stage 1 identity drifted")
	test.check(STAGE_1.display_name == "THE RUINED DISTRICT", "Stage 1 display name drifted")
	test.check(STAGE_1.time_limit_seconds == 240.0, "Stage 1 time limit drifted")
	test.check(STAGE_1.scenes.size() == 3, "Stage 1 should contain three scene segments")
	var expected_scene_ids := [&"ruined_avenue", &"flooded_courtyard", &"processing_plant"]
	var expected_environment_ids := [&"overgrown_city_sunset", &"flooded_industrial_yard", &"red_alert_plant"]
	var previous_scene_end := 0.0
	for index in range(STAGE_1.scenes.size()):
		var scene: Resource = STAGE_1.scenes[index]
		test.check(scene.is_valid_scene(), "%s scene definition is invalid" % scene.scene_id)
		test.check(scene.scene_id == expected_scene_ids[index], "scene order or identity drifted")
		test.check(scene.environment_id == expected_environment_ids[index], "scene environment identity drifted")
		test.check(scene.start_x == previous_scene_end, "scene segments are not contiguous")
		previous_scene_end = scene.end_x
	test.check(previous_scene_end == 4200.0, "scene segments do not cover the full stage")
	var encounters: Array[Resource] = STAGE_1.all_encounters()
	test.check(encounters.size() == 4, "Stage 1 encounter count drifted")
	var encounter_ids := {}
	var total_spawns := 0
	var previous_trigger := -1.0
	for encounter in encounters:
		test.check(encounter.is_valid_encounter(), "%s encounter is invalid" % encounter.encounter_id)
		test.check(not encounter_ids.has(encounter.encounter_id), "%s encounter id is duplicated" % encounter.encounter_id)
		test.check(encounter.trigger_x > previous_trigger, "%s trigger is out of order" % encounter.encounter_id)
		encounter_ids[encounter.encounter_id] = true
		previous_trigger = encounter.trigger_x
		total_spawns += encounter.total_spawn_count()
	test.check(total_spawns == 14, "Stage 1 migrated spawn count drifted")
	test.check(encounters[1].waves.size() == 2, "courtyard encounter lost its reinforcement wave")
	test.check(encounters[1].waves[1].reinforcement_delay == 0.45, "reinforcement delay drifted")
	test.check(encounters[2].waves[0].spawns.size() == 4, "four-enemy benchmark encounter drifted")
	test.check(not StageDefinitionScript.new().is_valid_stage(), "empty stage definition should be invalid")
	test.check(not EncounterDefinitionScript.new().is_valid_encounter(), "empty encounter definition should be invalid")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	test.check(game.encounter_director.get_encounter_count() == 4, "game did not configure the Stage 1 director")
	test.check(not game.wave_active and game.stage_index == 0, "director should start idle at encounter zero")
	test.check(game.stage_limit == encounters[0].arena_right, "director did not establish the first arena bound")
	var started_ids: Array[StringName] = []
	var cleared_ids: Array[StringName] = []
	game.encounter_director.encounter_started.connect(
		func(encounter: Resource, _index: int) -> void: started_ids.append(encounter.encounter_id)
	)
	game.encounter_director.encounter_cleared.connect(
		func(encounter: Resource, _index: int) -> void: cleared_ids.append(encounter.encounter_id)
	)
	game._start_game()
	game.encounter_director.force_start_encounter(1)
	test.check(game.wave_active and game.stage_index == 1, "forced courtyard encounter did not start")
	test.check(game.remaining_enemies == 2 and game.encounter_director.current_wave_index == 0, "courtyard opening group is incorrect")
	test.check(game.stage_limit == encounters[1].arena_right, "courtyard lock bound is incorrect")
	test.check(started_ids == [&"courtyard_reinforcement"], "encounter-start signal payload is incorrect")
	game.encounter_director.force_start_encounter(3)
	test.check(game.stage_index == 1 and game.remaining_enemies == 2, "force-start replaced an active encounter")

	_defeat_all_enemies(test)
	await test.wait_physics_frames(50)
	test.check(game.wave_active and game.remaining_enemies == 0, "director cleared encounter before reinforcement")
	test.check(game.encounter_director.reinforcement_timer > 0.0, "director did not arm reinforcement delay")
	game.encounter_director.tick(1.0, game.player.position.x)
	test.check(game.remaining_enemies == 2 and game.encounter_director.current_wave_index == 1, "reinforcement group did not spawn")
	test.check(test.tree.get_nodes_in_group("enemies").size() == 2, "reinforcement entity count is incorrect")

	_defeat_all_enemies(test)
	await test.wait_physics_frames(50)
	test.check(not game.wave_active and game.stage_index == 2, "reinforcement encounter did not complete")
	test.check(game.stage_limit == encounters[1].unlock_right, "director did not release the courtyard bound")
	test.check(cleared_ids == [&"courtyard_reinforcement"], "encounter-clear signal payload is incorrect")

	game.encounter_director.force_start_encounter(3)
	test.check(game.remaining_enemies == 3, "final encounter spawn count is incorrect")
	_defeat_all_enemies(test)
	await test.wait_physics_frames(52)
	test.check(game.encounter_director.completed, "director did not emit stage completion")
	test.check(game.state == "victory", "stage completion did not enter victory state")
	test.check(game.stage_limit == STAGE_1.end_x(), "final encounter did not unlock the stage endpoint")

	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	test.check(not game_source.contains("var waves := ["), "game still owns a hard-coded wave table")
	test.check(game_source.contains("EncounterDirectorScript"), "game is not routed through EncounterDirector")
	await test.dispose(game)


func _defeat_all_enemies(_test) -> void:
	for enemy in _test.tree.get_nodes_in_group("enemies"):
		enemy.take_hit(9999, Vector2(300.0, 0.0), true)
