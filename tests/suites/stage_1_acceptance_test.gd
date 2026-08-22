extends RefCounted

const STAGE_1 = preload("res://data/stages/stage_1/stage_1.tres")
const ENEMY_RESOURCES := {
	&"grunt": preload("res://data/enemies/grunt.tres"),
	&"brute": preload("res://data/enemies/brute.tres"),
	&"hunter": preload("res://data/enemies/hunter.tres"),
	&"raptor": preload("res://data/enemies/raptor.tres"),
	&"boss": preload("res://data/enemies/boss.tres"),
}
const FULL_COMBO_DAMAGE := 12 + 14 + 16 + 22


func run(test) -> void:
	var encounters: Array[Resource] = STAGE_1.all_encounters()
	var health_budgets: Array[int] = []
	var opening_counts: Array[int] = []
	var authored_spawn_count := 0
	for encounter in encounters:
		var encounter_health := 0
		var encounter_count := 0
		for wave in encounter.waves:
			for spawn in wave.spawns:
				var enemy_definition: Resource = ENEMY_RESOURCES.get(spawn.enemy_id)
				test.check(enemy_definition != null, "%s uses an unknown enemy" % encounter.encounter_id)
				if enemy_definition == null:
					continue
				encounter_health += enemy_definition.max_health
				encounter_count += 1
				authored_spawn_count += 1
		health_budgets.append(encounter_health)
		opening_counts.append(encounter.waves[0].spawns.size())

	var boss_phase: Resource = ENEMY_RESOURCES[&"boss"].boss_phases[1]
	var reinforcement_health: int = ENEMY_RESOURCES[boss_phase.reinforcement_enemy_id].max_health * boss_phase.reinforcement_count
	health_budgets[-1] += reinforcement_health
	test.check(authored_spawn_count == 14, "Stage 1 authored enemy count drifted")
	test.check(authored_spawn_count + boss_phase.reinforcement_count == 16, "Stage 1 runtime enemy count drifted")
	test.check(health_budgets == [142, 212, 240, 444], "Stage 1 health curve is no longer steadily escalating")
	test.check(opening_counts.max() <= 4, "a Stage 1 opening exceeds the four-enemy render budget")
	test.check(opening_counts[-1] + boss_phase.reinforcement_count <= 5, "boss phase exceeds the five-enemy peak budget")
	var estimated_combo_seconds := 0.0
	for encounter in encounters:
		for wave in encounter.waves:
			for spawn in wave.spawns:
				estimated_combo_seconds += ceilf(float(ENEMY_RESOURCES[spawn.enemy_id].max_health) / FULL_COMBO_DAMAGE) * 1.32
	estimated_combo_seconds += boss_phase.reinforcement_count * 1.32
	var traversal_seconds := STAGE_1.end_x() / 255.0
	test.check(estimated_combo_seconds + traversal_seconds < STAGE_1.time_limit_seconds * 0.4, "Stage 1 timer no longer leaves a practical combat margin")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.set_process(false)
	game.player.invulnerable = 999.0
	game.player.set_physics_process(false)
	var started_ids: Array[StringName] = []
	var cleared_ids: Array[StringName] = []
	var entered_scene_ids: Array[StringName] = []
	game.encounter_director.encounter_started.connect(
		func(encounter: Resource, _index: int) -> void: started_ids.append(encounter.encounter_id)
	)
	game.encounter_director.encounter_cleared.connect(
		func(encounter: Resource, _index: int) -> void: cleared_ids.append(encounter.encounter_id)
	)
	game.encounter_director.scene_entered.connect(
		func(scene: Resource, _index: int) -> void: entered_scene_ids.append(scene.scene_id)
	)

	for encounter_index in range(encounters.size()):
		var encounter: Resource = encounters[encounter_index]
		game.player.position.x = encounter.trigger_x
		game.encounter_director.tick(1.0 / 60.0, game.player.position.x)
		test.check(game.wave_active and game.stage_index == encounter_index, "%s did not start in sequential play" % encounter.encounter_id)
		test.check(game.stage_limit == encounter.arena_right, "%s did not lock its combat arena" % encounter.encounter_id)
		test.check(game.hud.arena_locked, "%s did not expose its lock state to the HUD" % encounter.encounter_id)

		for wave_index in range(encounter.waves.size()):
			if wave_index > 0:
				game.encounter_director.tick(1.0, game.player.position.x)
				test.check(game.encounter_director.current_wave_index == wave_index, "%s reinforcement wave did not arrive" % encounter.encounter_id)
			await _defeat_current_group(test, game)

		if encounter_index == encounters.size() - 1:
			# The first boss hit advances the phase and creates two hunters; the
			# second group pass defeats the phase-two boss and those reinforcements.
			await _defeat_current_group(test, game)
		test.check(not game.wave_active, "%s did not clear after every registered enemy was defeated" % encounter.encounter_id)
		test.check(game.stage_limit == encounter.unlock_right, "%s did not release the route" % encounter.encounter_id)
		test.check(not game.hud.arena_locked, "%s left the HUD in a locked state" % encounter.encounter_id)

	game.encounter_director.tick(1.0 / 60.0, STAGE_1.end_x())
	test.check(game.encounter_director.completed, "the sequential Stage 1 run never emitted completion")
	test.check(game.state == "victory" and game.hud.mode == "victory", "the sequential Stage 1 run did not enter victory")
	test.check(started_ids == [&"ruins_intro", &"courtyard_reinforcement", &"factory_pressure", &"plant_boss"], "encounter start order drifted")
	test.check(cleared_ids == started_ids, "encounter clear order differs from start order")
	test.check(entered_scene_ids == [&"ruined_avenue", &"flooded_courtyard", &"processing_plant"], "not every Stage 1 scene was entered in order")
	test.check(game.score == 7500, "sequential combat score drifted before bonuses")
	test.check(test.tree.get_nodes_in_group("pickups").size() == 3, "encounter rewards did not survive the full run")
	test.check(game.boss_phase_history == [&"command", &"overdrive"], "full run skipped a boss phase")
	test.check(game.music_director.cue_history == [1, 2, 3], "full run music did not transition stage→boss→victory")

	game._tick_victory(1.6)
	game._tick_victory(2.4)
	test.check(game.victory_phase == &"complete", "full run settlement did not become restart-ready")
	test.check(game.score == 16900 and game.hud.victory_final_score == 16900, "full run settlement total drifted")
	test.check(game.victory_bonus_applied, "full run settlement did not apply bonuses")
	await test.dispose(game)


func _defeat_current_group(test, game: Node) -> void:
	var targets: Array[Node] = []
	for enemy in test.tree.get_nodes_in_group("enemies"):
		if not enemy.is_defeated:
			targets.append(enemy)
	for enemy in targets:
		enemy.set_physics_process(true)
		enemy.invulnerable = 0.0
		enemy.take_hit(9999, Vector2(300.0, -45.0), true)
	await test.wait_physics_frames(52)
