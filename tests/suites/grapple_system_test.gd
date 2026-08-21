extends RefCounted

const FighterIntentScript = preload("res://core/input/fighter_intent.gd")
const FighterStateMachineScript = preload("res://actors/fighters/fighter_state_machine.gd")
const GRAB_STRIKE = preload("res://data/attacks/player_grab_strike.tres")
const FORWARD_THROW = preload("res://data/attacks/player_throw.tres")
const BACK_THROW = preload("res://data/attacks/player_back_throw.tres")
const COMBO_THROW = preload("res://data/attacks/player_combo_throw.tres")


func run(test) -> void:
	for attack in [GRAB_STRIKE, FORWARD_THROW, BACK_THROW, COMBO_THROW]:
		test.check(attack != null and attack.is_valid_frame_data(), "grapple frame data failed validation")
	test.check(GRAB_STRIKE.damage == 7 and GRAB_STRIKE.duration == 0.24, "grab-strike outcome drifted")
	test.check(FORWARD_THROW.damage == 22 and FORWARD_THROW.knockback == Vector2(560, -80), "forward-throw outcome drifted")
	test.check(BACK_THROW.damage == 26 and BACK_THROW.knockback == Vector2(500, -110), "back-throw outcome drifted")
	test.check(COMBO_THROW.damage == 30 and COMBO_THROW.knockback == Vector2(620, -95), "combo-throw outcome drifted")
	test.check(FighterStateMachineScript.state_name(FighterStateMachineScript.State.GET_UP) == "GET_UP", "get-up state is missing")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.set_physics_process(false)
	game.player.position = Vector2(500.0, 540.0)
	await test.wait_physics_frames(2)
	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		enemy.position = Vector2(1300.0, 620.0)

	var combo_target = _spawn_brute(game, Vector2(535.0, 540.0))
	combo_target.health = 200
	var initial_health: int = combo_target.health
	game.player.facing = 1
	game.player.combo_window = 0.0
	game.player.attack_timer = 0.0
	game.player._start_attack()
	game.player.attack_timer = game.player.current_attack.hit_trigger_remaining - 0.01
	game.player._check_attack_hit()
	test.check(combo_target.health == initial_health - 12, "contact grab did not apply combo-one damage")
	test.check(combo_target.grabbed and game.player.grabbed_enemy == combo_target, "close combo-one hit did not enter grab hold")
	test.check(game.player.grab_strike_count == 0 and game.player.grab_hold_timer == 2.0, "grab hold counters were not initialized")
	test.check(combo_target.fighter_state == FighterStateMachineScript.State.GRABBED, "grab target did not enter grabbed state")
	test.check(combo_target.hurt_timer == 0.0 and combo_target.invulnerable == 0.0, "grab acquisition retained hit immunity")

	var expected_health := initial_health - 12
	for strike_index in range(1, 4):
		game.player.attack_timer = 0.0
		game.player._apply_intent(FighterIntentScript.new(Vector2.ZERO, false, true))
		expected_health -= GRAB_STRIKE.damage
		test.check(combo_target.health == expected_health, "grab strike %d damage drifted" % strike_index)
		test.check(game.player.grab_strike_count == strike_index and combo_target.grabbed, "grab strike %d broke the hold" % strike_index)

	combo_target.attack_timer = combo_target.current_attack.duration
	combo_target.attack_hit_done = false
	combo_target.attack_hitbox.configure_circle(combo_target.current_attack.circle_radius, -1)
	game.player.attack_timer = 0.0
	game.player._apply_intent(FighterIntentScript.new(Vector2.ZERO, false, true))
	expected_health -= COMBO_THROW.damage
	test.check(game.player.current_attack == COMBO_THROW, "fourth neutral grab attack did not select combo throw")
	test.check(game.player.grabbed_enemy == null and not combo_target.grabbed, "combo throw did not release target")
	test.check(combo_target.health == expected_health and combo_target.velocity == Vector2(620, -95), "combo throw outcome drifted")
	test.check(combo_target.knockdown_state and combo_target.fighter_state == FighterStateMachineScript.State.KNOCKDOWN, "combo throw did not knock down")
	test.check(combo_target.attack_timer == 0.0 and not combo_target.attack_hitbox.active, "launch throw did not interrupt enemy attack")
	test.check(game.player.grab_strike_count == 0 and game.player.grab_hold_timer == 0.0, "combo throw retained grab counters")

	var forward_target = _spawn_brute(game, Vector2(535.0, 540.0))
	forward_target.health = 200
	forward_target.grabbed_by(game.player)
	game.player.grabbed_enemy = forward_target
	game.player.grab_hold_timer = 2.0
	game.player.attack_timer = 0.0
	game.player.facing = 1
	game.player._apply_intent(FighterIntentScript.new(Vector2.RIGHT, false, true))
	test.check(game.player.current_attack == FORWARD_THROW, "forward relative input did not select forward throw")
	test.check(forward_target.health == 178 and forward_target.velocity == Vector2(560, -80), "forward throw outcome drifted")
	test.check(game.player.facing == 1, "grab direction incorrectly changed player facing")

	var back_target = _spawn_brute(game, Vector2(535.0, 540.0))
	back_target.health = 200
	back_target.grabbed_by(game.player)
	game.player.grabbed_enemy = back_target
	game.player.grab_hold_timer = 2.0
	game.player.attack_timer = 0.0
	game.player.facing = 1
	game.player._apply_intent(FighterIntentScript.new(Vector2.LEFT, false, true))
	test.check(game.player.current_attack == BACK_THROW, "back relative input did not select back throw")
	test.check(back_target.health == 174 and back_target.velocity == Vector2(-500, -110), "back throw outcome drifted")
	test.check(game.player.facing == 1, "back throw flipped player before resolving")

	var timeout_target = _spawn_brute(game, Vector2(535.0, 540.0))
	timeout_target.grabbed_by(game.player)
	game.player.grabbed_enemy = timeout_target
	game.player.grab_strike_count = 2
	game.player.grab_hold_timer = 0.01
	game.player.hurt_timer = 1.0
	game.player._physics_process(0.02)
	test.check(game.player.grabbed_enemy == null and not timeout_target.grabbed, "expired grab hold did not release target")
	test.check(timeout_target.stun_timer == 0.25 and timeout_target.fighter_state == FighterStateMachineScript.State.STUN, "grab timeout did not apply release stun")
	game.player.hurt_timer = 0.0

	game.player.is_defeated = true
	combo_target._physics_process(0.47)
	test.check(not combo_target.knockdown_state and combo_target.wake_up_timer == 0.38, "knockdown did not enter full get-up window")
	test.check(combo_target.fighter_state == FighterStateMachineScript.State.GET_UP, "wake-up did not enter get-up state")
	test.check(not combo_target.can_be_grabbed(), "get-up target was grabbable")
	var wake_health: int = combo_target.health
	combo_target.take_hit(99, Vector2.ZERO, false)
	test.check(combo_target.health == wake_health, "get-up invulnerability did not reject damage")
	combo_target._physics_process(0.39)
	test.check(combo_target.wake_up_timer == 0.0 and combo_target.invulnerable == 0.0, "get-up timers did not expire")
	test.check(combo_target.fighter_state == FighterStateMachineScript.State.IDLE and combo_target.can_be_grabbed(), "completed get-up did not restore neutral state")

	await test.dispose(game)


func _spawn_brute(game: Node, position: Vector2) -> Node:
	game.spawn_enemy(position, "brute")
	var enemy: Node = game.get_tree().get_nodes_in_group("enemies")[-1]
	enemy.set_physics_process(false)
	return enemy
