extends RefCounted

const LocalPlayerRegistryScript = preload("res://core/input/local_player_registry.gd")
const DeviceInputSourceScript = preload("res://core/input/device_input_source.gd")


func run(test) -> void:
	var registry = LocalPlayerRegistryScript.new()
	var keyboard = registry.reset_with_keyboard(0)
	test.check(keyboard != null and keyboard.slot_index == 0 and keyboard.device_id == -1, "keyboard did not claim stable player-one slot")
	var pad_one = registry.join_device(4, 1)
	var pad_two = registry.join_device(8, 2)
	test.check(pad_one != null and pad_one.slot_index == 1 and pad_one.hero_index == 1, "first gamepad did not claim player-two slot")
	test.check(pad_two != null and pad_two.slot_index == 2 and pad_two.hero_index == 2, "second gamepad did not claim player-three slot")
	test.check(registry.join_device(4, 3) == pad_one and registry.slots.size() == 3, "duplicate device created a duplicate local player")
	test.check(registry.join_device(12, 3) == null and registry.is_full(), "registry exceeded the three-player cap")
	test.check(registry.leave_device(4) == pad_one and registry.slot_for_device(4) == null, "device leave did not release its slot")
	var replacement = registry.join_device(12, 3)
	test.check(replacement != null and replacement.slot_index == 1, "vacated local-player slot was not reused deterministically")
	test.check(registry.set_hero(1, 2) and replacement.hero_index == 2, "slot hero ownership did not update")

	var source := DeviceInputSourceScript.new()
	source.configure(7)
	var pressed = source.sample_from_state(Vector2(0.8, 0.6), true, true, false)
	test.check(pressed.move.is_equal_approx(Vector2(0.8, 0.6)), "device source changed a valid analog vector")
	test.check(pressed.jump_pressed and pressed.attack_pressed and not pressed.special_pressed, "device source lost initial button edges")
	var held = source.sample_from_state(Vector2.ZERO, true, true, false)
	test.check(not held.jump_pressed and not held.attack_pressed, "held device buttons repeated just-pressed edges")
	var released = source.sample_from_state(Vector2.ZERO, false, false, true)
	test.check(released.special_pressed and not released.jump_pressed and not released.attack_pressed, "device source did not isolate per-button edges")
	source.reset_edges()
	test.check(source.sample_from_state(Vector2.ZERO, true, false, false).jump_pressed, "device edge reset did not restore a clean join state")
	source.configure(-1, false)
	Input.action_press("attack")
	test.check(not source.sample_intent().attack_pressed, "desktop keyboard source consumed a global gamepad/touch action")
	Input.action_release("attack")
	source.configure(-1, true)
	Input.action_press("attack")
	test.check(source.sample_intent().attack_pressed, "mobile virtual-action path did not reach player one")
	Input.action_release("attack")
	source.free()

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	test.check(game.players.size() == 1 and game.players[0] == game.player, "legacy player alias no longer identifies local player one")
	test.check(game.player.local_slot_index == 0 and game.player.input_device_id == -1, "primary player did not receive keyboard routing metadata")
	test.check(game.player.input_source.get_script() == DeviceInputSourceScript, "primary player does not use the per-device intent boundary")
	var second: Node = game.join_local_player(0, 1)
	var third: Node = game.join_local_player(1, 2)
	test.check(second != null and second.local_slot_index == 1 and second.input_device_id == 0, "runtime player two join/routing failed")
	test.check(third != null and third.local_slot_index == 2 and third.input_device_id == 1, "runtime player three join/routing failed")
	test.check(second.hero_id == &"mara" and third.hero_id == &"kestrel", "joined players did not receive slot-owned heroes")
	test.check(game.join_local_player(0, 3) == null and game.join_local_player(2, 3) == null, "runtime accepted a duplicate or fourth local player")
	var spawn_distances := [
		game.player.position.distance_to(second.position),
		game.player.position.distance_to(third.position),
		second.position.distance_to(third.position),
	]
	test.check(spawn_distances.min() >= game.MIN_SAFE_SPAWN_DISTANCE, "local players spawned inside the safety radius")

	game._start_game()
	test.check(game.get_active_players().size() == 3, "starting play did not activate all joined players")
	test.check(game.player.is_physics_processing() and second.is_physics_processing() and third.is_physics_processing(), "joined players were not enabled together")
	game.player.set_physics_process(false)
	second.set_physics_process(false)
	third.set_physics_process(false)
	game.player.position = Vector2(400.0, 520.0)
	second.position = Vector2(900.0, 570.0)
	third.position = Vector2(1500.0, 620.0)
	test.check(game.lead_player_x() == 1500.0, "encounter progression does not follow the lead local player")
	var camera_frame: Dictionary = game.shared_camera_frame()
	test.check(camera_frame.zoom < 1.0 and camera_frame.zoom >= game.MIN_SHARED_CAMERA_ZOOM, "shared camera did not widen for a spread team")
	test.check(camera_frame.position.x > game.player.position.x and camera_frame.position.x < third.position.x, "shared camera did not frame the team center")

	game.spawn_enemy(Vector2(1460.0, 620.0), "grunt")
	var enemy: Node = test.tree.get_nodes_in_group("enemies").back()
	enemy.set_physics_process(false)
	enemy._update_combat_target()
	test.check(enemy.combat_target == third, "enemy targeting did not choose the nearest active local player")

	second.health = second.max_health - 30
	game.spawn_pickup(second.position, &"food")
	var pickup: Node = test.tree.get_nodes_in_group("pickups").back()
	pickup.set_process(false)
	pickup._process(0.0)
	test.check(second.health > second.max_health - 30, "pickup collection remained hard-wired to player one")

	test.check(not game.leave_local_player(-1), "runtime allowed the primary keyboard slot to leave")
	test.check(game.leave_local_player(0), "runtime player leave failed")
	await test.tree.process_frame
	test.check(game.get_local_players().size() == 2 and game.local_player_registry.slot_for_device(0) == null, "player leave did not clear runtime and registry state")
	var replacement_player: Node = game.join_local_player(2, 3)
	test.check(replacement_player != null and replacement_player.local_slot_index == 1 and replacement_player.hero_id == &"atlas", "runtime did not reuse the vacated slot safely")

	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(probe_source.contains("local_coop_preview=3"), "reproducible three-player Web preview is missing")
	await test.dispose(game)
