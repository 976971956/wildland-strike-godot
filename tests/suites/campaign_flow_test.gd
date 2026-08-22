extends RefCounted

const STAGES := [
	preload("res://data/stages/stage_1/stage_1.tres"),
	preload("res://data/stages/stage_2/stage_2.tres"),
	preload("res://data/stages/stage_3/stage_3.tres"),
	preload("res://data/stages/stage_4/stage_4.tres"),
	preload("res://data/stages/stage_5/stage_5.tres"),
	preload("res://data/stages/stage_6/stage_6.tres"),
]


func run(test) -> void:
	test.check(STAGES.size() == 6, "M7 campaign route must expose the first six stages")
	var expected_health := [1.0, 1.08, 1.16, 1.25, 1.34, 1.43]
	var expected_damage := [1.0, 1.04, 1.08, 1.12, 1.17, 1.21]
	var expected_clear := [5000, 6500, 8000, 10000, 12000, 14000]
	for index in range(STAGES.size()):
		var stage: Resource = STAGES[index]
		test.check(stage.is_valid_stage(), "Stage %d route profile is invalid" % (index + 1))
		test.check(stage.stage_number == index + 1 and stage.map_position != Vector2.ZERO, "Stage %d route identity/position drifted" % (index + 1))
		test.check(is_equal_approx(stage.enemy_health_scale, expected_health[index]) and is_equal_approx(stage.enemy_damage_scale, expected_damage[index]), "Stage %d difficulty progression drifted" % (index + 1))
		test.check(stage.clear_bonus == expected_clear[index], "Stage %d clear bonus drifted" % (index + 1))
		if index > 0:
			test.check(stage.enemy_health_scale > STAGES[index - 1].enemy_health_scale and stage.enemy_damage_scale > STAGES[index - 1].enemy_damage_scale, "Stage %d does not increase campaign threat" % (index + 1))

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._open_character_select()
	game.confirm_hero_selection()
	test.check(game.state == "campaign_map" and game.hud.mode == "campaign_map", "character select did not enter the first route map")
	test.check(game.hud.campaign_stage_nodes.size() == 6 and game.hud.campaign_target_index == 0, "route map did not expose all six operations")
	game._deploy_campaign_stage()
	test.check(game.state == "playing" and game.campaign_stage_index == 0, "first route deployment did not start Stage 1")

	game.score = 1000
	game.hud.set_score(game.score)
	game.lives = 2
	for stage_index in range(STAGES.size()):
		test.check(game.campaign_stage_index == stage_index and game.active_stage_definition == STAGES[stage_index], "campaign entered the wrong Stage %d definition" % (stage_index + 1))
		test.check(is_equal_approx(game.coop_enemy_health_scale(), expected_health[stage_index]) and is_equal_approx(game.coop_enemy_damage_scale(), expected_damage[stage_index]), "Stage %d runtime difficulty did not match route data" % (stage_index + 1))
		game.stage_time_remaining = 100.0
		game._victory()
		game._tick_victory(1.6)
		game._tick_victory(2.4)
		test.check(game.victory_phase == &"complete" and game.completed_stage_count == stage_index + 1, "Stage %d settlement did not complete exactly once" % (stage_index + 1))
		test.check(game.victory_clear_bonus == expected_clear[stage_index] and game.lives == 2, "Stage %d settlement changed bonus/lives unexpectedly" % (stage_index + 1))
		if stage_index < STAGES.size() - 1:
			game._open_campaign_map(stage_index + 1)
			test.check(game.hud.campaign_target_index == stage_index + 1 and game.hud.campaign_completed_count == stage_index + 1, "route map did not advance after Stage %d" % (stage_index + 1))
			game._deploy_campaign_stage()
			await test.tree.process_frame

	test.check(game.score == 74500, "six stage settlements did not preserve and tally the expected score")
	test.check(STAGES.all(func(stage: Resource): return stage.scenes.size() == 3 and stage.is_valid_stage()), "campaign transitions mutated cached stage resources")
	game._complete_first_half_campaign()
	test.check(game.state == "campaign_complete" and game.hud.mode == "campaign_complete", "Stage 5 did not enter the campaign sector report")
	test.check(game.score == 94500 and game.hud.campaign_display_score == 94500, "campaign completion bonus was not applied exactly once")
	game._complete_first_half_campaign()
	test.check(game.score == 94500, "campaign completion bonus was applied more than once")
	test.check(game.local_player_registry.slot_at(0).remaining_lives == 2 and game.lives == 2, "six-stage route did not preserve remaining continues")
	await test.dispose(game)
