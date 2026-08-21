extends RefCounted

const RunControllerScript = preload("res://actors/fighters/run_controller.gd")
const FighterIntentScript = preload("res://core/input/fighter_intent.gd")
const FighterStateMachineScript = preload("res://actors/fighters/fighter_state_machine.gd")


func run(test) -> void:
	var directions := [
		Vector2.RIGHT,
		Vector2(1, 1),
		Vector2.DOWN,
		Vector2(-1, 1),
		Vector2.LEFT,
		Vector2(-1, -1),
		Vector2.UP,
		Vector2(1, -1),
	]
	for index in range(directions.size()):
		test.check(RunControllerScript.direction_index(directions[index]) == index, "eight-direction quantization failed at %d" % index)
	test.check(RunControllerScript.direction_index(Vector2(0.2, 0.0)) == -1, "run deadzone accepted weak input")

	var controller = RunControllerScript.new()
	controller.update(Vector2.RIGHT)
	test.check(not controller.running and controller.tap_window == controller.TAP_WINDOW, "first tap incorrectly started running")
	controller.update(Vector2.ZERO)
	controller.tick(0.12)
	controller.update(Vector2.RIGHT)
	test.check(controller.running and controller.run_direction == 0, "second same-direction tap did not start running")
	controller.update(Vector2(1.0, 1.0))
	test.check(controller.running and controller.run_direction == 1, "run did not allow adjacent-direction steering")
	controller.update(Vector2.LEFT)
	test.check(not controller.running and controller.turned_around, "hard reverse did not cancel run and report turn")
	test.check(controller.last_tap_direction == 4, "hard reverse was not retained as a new first tap")

	controller.update(Vector2.ZERO)
	controller.tick(0.29)
	controller.update(Vector2.LEFT)
	test.check(not controller.running, "expired double-tap window incorrectly started running")
	controller.update(Vector2.ZERO)
	controller.tick(0.1)
	controller.update(Vector2.UP)
	test.check(not controller.running, "different-direction second tap incorrectly started running")
	controller.cancel()
	test.check(not controller.running and controller.tap_window == 0.0, "run cancellation retained buffered tap")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.set_physics_process(false)
	game.player._apply_intent(FighterIntentScript.new(Vector2.RIGHT))
	game.player._apply_intent(FighterIntentScript.new(Vector2.ZERO))
	game.player.run_controller.tick(0.1)
	game.player._apply_intent(FighterIntentScript.new(Vector2.RIGHT))
	test.check(game.player.is_running, "player did not enter run from double-tap intent")
	test.check(
		is_equal_approx(game.player.velocity.x, game.player.SPEED * game.player.RUN_SPEED_MULTIPLIER),
		"player run speed multiplier drifted"
	)
	game.player._sync_fighter_state()
	test.check(game.player.fighter_state == FighterStateMachineScript.State.RUN, "player run state was not explicit")
	game.player._apply_intent(FighterIntentScript.new(Vector2.LEFT))
	test.check(not game.player.is_running and game.player.facing == -1, "player reverse turn did not cancel run and flip facing")
	test.check(game.player.velocity == Vector2(-game.player.SPEED, 0.0), "reverse turn did not return to walk speed")

	game.player.run_controller.cancel()
	game.player._apply_intent(FighterIntentScript.new(Vector2.DOWN))
	game.player._apply_intent(FighterIntentScript.new(Vector2.ZERO))
	game.player.run_controller.tick(0.1)
	game.player._apply_intent(FighterIntentScript.new(Vector2.DOWN))
	test.check(game.player.is_running and game.player.velocity.y > game.player.SPEED, "vertical double tap did not run")
	game.player.attack_timer = 0.0
	game.player._start_attack()
	test.check(not game.player.is_running, "attack did not cancel running")

	game.player.attack_timer = 0.0
	game.player.hurt_timer = 0.0
	game.player.invulnerable = 0.0
	game.player.run_controller.update(Vector2.ZERO)
	game.player.run_controller.update(Vector2.RIGHT)
	game.player.run_controller.update(Vector2.ZERO)
	game.player.run_controller.tick(0.1)
	game.player.run_controller.update(Vector2.RIGHT)
	test.check(game.player.is_running, "run fixture did not restart")
	game.player.take_hit(1, Vector2.ZERO)
	test.check(not game.player.is_running, "taking damage did not cancel running")
	await test.dispose(game)
