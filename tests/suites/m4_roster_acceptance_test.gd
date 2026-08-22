extends RefCounted

const STAGE_1 = preload("res://data/stages/stage_1/stage_1.tres")
const HERO_COMBINATIONS := [
	[0], [1], [2], [3],
	[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3],
	[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3],
]


func run(test) -> void:
	test.check(HERO_COMBINATIONS.size() == 14, "M4 acceptance matrix must cover four solo, six duo, and four trio runs")
	var completed_labels := PackedStringArray()
	for hero_indices: Array in HERO_COMBINATIONS:
		var label := await _complete_stage_with_roster(test, hero_indices)
		if not label.is_empty():
			completed_labels.append(label)
	test.check(completed_labels.size() == HERO_COMBINATIONS.size(), "not every M4 hero combination completed Stage 1")
	await _verify_mobile_single_player_path(test)


func _complete_stage_with_roster(test, hero_indices: Array) -> String:
	var game: Node = await test.instantiate_main()
	if game == null:
		return ""
	game.select_hero_for_slot(0, int(hero_indices[0]))
	for player_index in range(1, hero_indices.size()):
		var joined: Node = game.join_local_player(player_index - 1, int(hero_indices[player_index]))
		test.check(joined != null, "%s could not join player %d" % [_roster_label(game, hero_indices), player_index + 1])
	game._start_game()
	game.set_process(false)
	var label := _roster_label(game, hero_indices)
	var actual_hero_ids := PackedStringArray()
	for fighter in game.get_local_players():
		fighter.invulnerable = 999.0
		fighter.set_physics_process(false)
		actual_hero_ids.append(String(fighter.hero_id))
	var expected_hero_ids := PackedStringArray()
	for hero_index: int in hero_indices:
		expected_hero_ids.append(String(game.HERO_DEFINITIONS[hero_index].hero_id))
	test.check(actual_hero_ids == expected_hero_ids, "%s did not preserve its selected hero assignments" % label)

	var encounters: Array[Resource] = STAGE_1.all_encounters()
	for encounter_index in range(encounters.size()):
		var encounter: Resource = encounters[encounter_index]
		game.player.position.x = encounter.trigger_x
		game.encounter_director.tick(1.0 / 60.0, game.player.position.x)
		test.check(game.wave_active, "%s failed to start %s" % [label, encounter.encounter_id])
		for wave_index in range(encounter.waves.size()):
			if wave_index > 0:
				game.encounter_director.tick(99.0, game.player.position.x)
			await _defeat_current_group_fast(test, game)
		if encounter_index == encounters.size() - 1:
			# The first pass advances the boss phase and spawns its two hunters.
			await _defeat_current_group_fast(test, game)
		test.check(not game.wave_active, "%s did not clear %s" % [label, encounter.encounter_id])

	game.encounter_director.tick(1.0 / 60.0, STAGE_1.end_x())
	var completed: bool = (
		game.encounter_director.completed
		and game.state == "victory"
		and game.score == 7500
		and game.boss_phase_history == [&"command", &"overdrive"]
	)
	test.check(completed, "%s did not reach the complete Stage 1 victory contract" % label)
	test.check(game.get_local_players().size() == hero_indices.size(), "%s lost a local player during the run" % label)
	game._tick_victory(1.6)
	game._tick_victory(2.4)
	test.check(game.victory_phase == &"complete" and game.score == 16900, "%s did not finish score settlement" % label)
	await test.dispose(game)
	return label if completed else ""


func _defeat_current_group_fast(test, game: Node) -> void:
	var targets: Array[Node] = []
	for enemy in test.tree.get_nodes_in_group("enemies"):
		if not enemy.is_defeated:
			targets.append(enemy)
	for enemy in targets:
		enemy.set_physics_process(false)
		enemy.invulnerable = 0.0
		enemy.hard_knockdown_lockout = false
		enemy.boss_transition_timer = 0.0
		enemy.take_hit(99999, Vector2(300.0, -45.0), true)
	for enemy in targets:
		if is_instance_valid(enemy) and enemy.is_defeated:
			enemy.death_timer = 0.0
			enemy._physics_process(1.0)
	await test.tree.process_frame


func _verify_mobile_single_player_path(test) -> void:
	var game: Node = await test.instantiate_main()
	if game == null:
		return
	var controls: Control = game.get_node("HUD/TouchControls")
	controls.size = Vector2(1280.0, 720.0)
	controls.enabled_for_device = true
	controls.visible = true
	game.player.input_source.virtual_actions_enabled = true
	_release_mobile_actions()

	var title_tap := _touch_event(70, Vector2(640.0, 360.0), true)
	controls._handle_touch(title_tap)
	test.check(Input.is_action_pressed("start"), "mobile title tap did not pulse start")
	game._process(0.0)
	Input.action_release("start")
	test.check(game.state == "select", "mobile title tap did not open character selection")

	var kestrel_card := _touch_event(71, Vector2(800.0, 330.0), true)
	controls._handle_touch(kestrel_card)
	test.check(game.selected_hero_index == 2 and game.state == "select", "mobile card tap did not select the intended hero")
	controls._handle_touch(kestrel_card)
	test.check(game.state == "playing" and game.player.hero_id == &"kestrel", "second mobile card tap did not confirm and start Stage 1")
	game.set_process(false)
	game.player.set_physics_process(false)

	var stick_down := _touch_event(72, Vector2(155.0, 585.0), true)
	controls._handle_touch(stick_down)
	var stick_drag := InputEventScreenDrag.new()
	stick_drag.index = 72
	stick_drag.position = Vector2(215.0, 535.0)
	controls._handle_drag(stick_drag)
	var move_intent = game.player.input_source.sample_intent()
	test.check(move_intent.move.x > 0.4 and move_intent.move.y < -0.4, "mobile joystick did not reach the shared eight-way intent path")
	controls._handle_touch(_touch_event(72, stick_drag.position, false))
	test.check(not Input.is_action_pressed("move_right") and not Input.is_action_pressed("move_up"), "mobile joystick release left movement stuck")

	var centers: Dictionary = controls._button_centers()
	var attack_down := _touch_event(73, centers["attack"], true)
	controls._handle_touch(attack_down)
	var attack_intent = game.player.input_source.sample_intent()
	test.check(attack_intent.attack_pressed, "mobile A button did not reach the fighter attack intent")
	controls._handle_touch(_touch_event(73, centers["attack"], false))

	var jump_down := _touch_event(74, centers["jump"], true)
	controls._handle_touch(jump_down)
	var jump_intent = game.player.input_source.sample_intent()
	test.check(jump_intent.jump_pressed, "mobile B button did not reach the fighter jump intent")
	controls._handle_touch(_touch_event(74, centers["jump"], false))

	var special_down := _touch_event(75, centers["special"], true)
	controls._handle_touch(special_down)
	var special_intent = game.player.input_source.sample_intent()
	test.check(special_intent.special_pressed, "mobile A+B button did not reach the fighter special intent")
	test.check(controls._button_at(centers["attack"]) == "attack" and controls._button_at(centers["jump"]) == "jump" and controls._button_at(centers["special"]) == "special", "mobile action hit regions overlap or route incorrectly")

	controls._handle_touch(stick_down)
	controls._handle_drag(stick_drag)
	controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	test.check(not Input.is_action_pressed("special") and not Input.is_action_pressed("move_right") and controls.joystick_touch == -1, "mobile focus loss left held controls active")
	_release_mobile_actions()
	await test.dispose(game)


func _touch_event(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event


func _release_mobile_actions() -> void:
	for action in ["start", "move_left", "move_right", "move_up", "move_down", "attack", "jump", "special"]:
		Input.action_release(action)


func _roster_label(game: Node, hero_indices: Array) -> String:
	var names := PackedStringArray()
	for hero_index: int in hero_indices:
		names.append(String(game.HERO_DEFINITIONS[hero_index].display_name))
	return "+".join(names)
