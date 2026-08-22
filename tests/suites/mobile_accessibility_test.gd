extends RefCounted

const ArcadeProfileScript = preload("res://core/persistence/arcade_profile.gd")


func run(test) -> void:
	var profile = ArcadeProfileScript.new("")
	profile.load_profile()
	test.check(profile.settings.has("touch_scale") and profile.settings.has("ui_scale"), "mobile sizing settings are missing from the profile")
	test.check(profile.settings.high_contrast_cues, "color-independent telegraph cues must default on")
	profile.set_setting("touch_scale", 99.0)
	profile.set_setting("ui_scale", 0.1)
	test.check(is_equal_approx(float(profile.settings.touch_scale), 1.35), "touch scale did not clamp to its safe maximum")
	test.check(is_equal_approx(float(profile.settings.ui_scale), 0.85), "UI scale did not clamp to its readable minimum")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	var controls: Control = game.touch_controls
	controls.size = Vector2(1280.0, 720.0)
	controls.enabled_for_device = true
	controls.visible = true
	controls.safe_area_override = Rect2(72.0, 34.0, 1136.0, 642.0)
	game.settings.touch_scale = 1.35
	controls._reset_joystick()
	var safe: Rect2 = controls._safe_rect()
	var centers: Dictionary = controls._button_centers()
	test.check(safe.has_point(controls.joystick_center), "safe-area joystick escaped the usable display")
	for action in ["attack", "jump", "special"]:
		test.check(safe.has_point(centers[action]), "safe-area %s control escaped the usable display" % action)
	test.check(safe.has_point(controls._pause_center()), "safe-area pause control escaped the usable display")
	test.check(centers.attack.distance_to(centers.jump) > controls.BUTTON_RADIUS * game.settings.touch_scale * 1.7, "scaled attack/jump hit targets overlap")
	test.check(centers.jump.distance_to(centers.special) > controls.BUTTON_RADIUS * game.settings.touch_scale * 1.7, "scaled jump/special hit targets overlap")
	game.settings.touch_layout = "left_handed"
	controls._reset_joystick()
	var mirrored_centers: Dictionary = controls._button_centers()
	test.check(controls.joystick_center.x > 640.0, "left-handed layout did not move the joystick to the right")
	test.check(mirrored_centers.attack.x < 640.0 and controls._point_on_joystick_side(Vector2(1100.0, 600.0)), "left-handed layout did not mirror action/joystick routing")
	game.settings.touch_layout = "classic"
	controls._reset_joystick()

	game._start_game()
	Input.action_release("pause")
	controls._handle_touch(_touch_event(90, controls._pause_center(), true))
	test.check(Input.is_action_pressed("pause"), "touch pause button did not reach the shared action map")
	game._process(0.0)
	test.check(game.state == "options" and test.tree.paused, "touch pause button did not freeze live gameplay")
	Input.action_release("pause")

	var initial_touch_scale := float(game.settings.touch_scale)
	controls._handle_touch(_touch_event(91, Vector2(1000.0, 274.0), true))
	test.check(game.options_selected_index == 2 and float(game.settings.touch_scale) >= initial_touch_scale, "touch options did not select and adjust touch size")
	test.check(is_equal_approx(game.hud.accessibility_ui_scale, float(game.settings.ui_scale)), "profile UI scale did not reach the HUD")
	controls._handle_touch(_touch_event(92, Vector2(640.0, 690.0), true))
	test.check(game.state == "playing" and not test.tree.paused, "touch resume target did not safely resume gameplay")

	game.settings.high_contrast_cues = false
	test.check(not game.high_contrast_cues_enabled(), "high-contrast cue toggle did not apply independently")
	game.settings.high_contrast_cues = true
	controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	test.check(game.state == "options" and test.tree.paused, "mobile focus loss did not automatically pause gameplay")
	test.check(controls.joystick_touch == -1 and controls.button_touches.is_empty(), "mobile focus loss retained active touch ownership")
	Input.action_release("pause")
	await test.dispose(game)


func _touch_event(index: int, position: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	return event
