extends RefCounted

const EnemyScript = preload("res://scripts/enemy.gd")
const STAGES := [
	preload("res://data/stages/stage_1/stage_1.tres"),
	preload("res://data/stages/stage_2/stage_2.tres"),
	preload("res://data/stages/stage_3/stage_3.tres"),
	preload("res://data/stages/stage_4/stage_4.tres"),
	preload("res://data/stages/stage_5/stage_5.tres"),
	preload("res://data/stages/stage_6/stage_6.tres"),
	preload("res://data/stages/stage_7/stage_7.tres"),
	preload("res://data/stages/stage_8/stage_8.tres"),
]


func run(test) -> void:
	var scene_count := 0
	var encounter_count := 0
	var spawn_count := 0
	var referenced_enemy_ids := {}
	for stage_index in range(STAGES.size()):
		var stage: Resource = STAGES[stage_index]
		test.check(stage.is_valid_stage(), "release smoke rejected Stage %d" % (stage_index + 1))
		test.check(stage.scenes.size() == 3, "Stage %d does not expose three authored scenes" % (stage_index + 1))
		var stage_bosses := {}
		for scene: Resource in stage.scenes:
			scene_count += 1
			test.check(scene.is_valid_scene() and scene.background_texture != null, "Stage %d scene %s is not export-ready" % [stage_index + 1, scene.scene_id])
			for encounter: Resource in scene.encounters:
				encounter_count += 1
				test.check(encounter.is_valid_encounter() and encounter.total_spawn_count() > 0, "Stage %d encounter %s is empty or invalid" % [stage_index + 1, encounter.encounter_id])
				for wave: Resource in encounter.waves:
					test.check(wave.is_valid_wave(), "Stage %d wave %s is invalid" % [stage_index + 1, wave.wave_id])
					for spawn: Resource in wave.resolved_spawns():
						spawn_count += 1
						var enemy_id := String(spawn.enemy_id)
						referenced_enemy_ids[enemy_id] = true
						test.check(EnemyScript.ENEMY_DEFINITIONS.has(enemy_id), "Stage %d references unknown enemy %s" % [stage_index + 1, enemy_id])
						if EnemyScript.ENEMY_DEFINITIONS.has(enemy_id) and EnemyScript.ENEMY_DEFINITIONS[enemy_id].is_boss:
							stage_bosses[enemy_id] = true
		test.check(not stage_bosses.is_empty(), "Stage %d has no authored boss in its route" % (stage_index + 1))
		var final_encounter: Resource = stage.all_encounters().back()
		test.check(final_encounter.waves.any(func(wave: Resource): return wave.resolved_spawns().any(func(spawn: Resource): return EnemyScript.ENEMY_DEFINITIONS[String(spawn.enemy_id)].is_boss)), "Stage %d final encounter is not a boss gate" % (stage_index + 1))

	test.check(scene_count == 24 and encounter_count == 38, "release campaign does not contain the expected 24 scenes / 38 encounters")
	test.check(spawn_count >= 120, "release campaign spawn coverage fell below its authored content floor")
	test.check(referenced_enemy_ids.size() >= 20, "release campaign no longer exercises the broad enemy roster")

	for player_count in range(1, 4):
		var game: Node = await test.instantiate_main()
		if game == null:
			return
		while game.coop_player_count() < player_count:
			game.join_local_player(game.coop_player_count() - 1, game.coop_player_count())
		for stage: Resource in STAGES:
			game.active_stage_definition = stage
			game.encounter_director.configure(game, stage)
			var first_spawn: Resource = stage.all_encounters()[0].waves[0].resolved_spawns()[0]
			game.spawn_enemy(Vector2(720.0, 560.0), String(first_spawn.enemy_id))
			var enemy: Node = test.tree.get_nodes_in_group("enemies").back()
			var definition: Resource = EnemyScript.ENEMY_DEFINITIONS[String(first_spawn.enemy_id)]
			test.check(enemy.definition == definition, "Stage %d P%d runtime failed to instantiate %s" % [stage.stage_number, player_count, first_spawn.enemy_id])
			test.check(enemy.max_health == roundi(definition.max_health * stage.enemy_health_scale * game.COOP_ENEMY_HEALTH_SCALES[player_count - 1]), "Stage %d P%d runtime spawn health missed its matrix value" % [stage.stage_number, player_count])
			enemy.queue_free()
			await test.tree.process_frame
		await test.dispose(game)
