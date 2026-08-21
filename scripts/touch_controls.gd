extends Control

const JOYSTICK_RADIUS := 78.0
const KNOB_RADIUS := 32.0
const BUTTON_RADIUS := 54.0

var game
var enabled_for_device := false
var joystick_touch := -1
var joystick_center := Vector2(150, 580)
var joystick_knob := Vector2(150, 580)
var button_touches: Dictionary = {}
var font: Font

func _ready() -> void:
	game = get_parent().get_parent()
	font = ThemeDB.fallback_font
	enabled_for_device = DisplayServer.is_touchscreen_available() or "--touch-preview" in OS.get_cmdline_user_args()
	set_process(enabled_for_device)
	set_process_input(enabled_for_device)
	visible = enabled_for_device
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not enabled_for_device or not is_instance_valid(game):
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if game.state != "playing":
			_pulse_start()
			get_viewport().set_input_as_handled()
			return
		if event.position.x < size.x * 0.46 and joystick_touch < 0:
			joystick_touch = event.index
			joystick_center = event.position
			joystick_knob = event.position
			_update_joystick(Vector2.ZERO)
		else:
			var action := _button_at(event.position)
			if action != "":
				button_touches[event.index] = action
				Input.action_press(action)
		get_viewport().set_input_as_handled()
	else:
		if event.index == joystick_touch:
			joystick_touch = -1
			joystick_center = Vector2(150, size.y - 132)
			joystick_knob = joystick_center
			_release_directions()
		elif button_touches.has(event.index):
			Input.action_release(button_touches[event.index])
			button_touches.erase(event.index)

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != joystick_touch:
		return
	var offset := event.position - joystick_center
	if offset.length() > JOYSTICK_RADIUS:
		offset = offset.normalized() * JOYSTICK_RADIUS
	joystick_knob = joystick_center + offset
	_update_joystick(offset / JOYSTICK_RADIUS)
	get_viewport().set_input_as_handled()

func _update_joystick(value: Vector2) -> void:
	_release_directions()
	if value.x < -0.18:
		Input.action_press("move_left", absf(value.x))
	elif value.x > 0.18:
		Input.action_press("move_right", absf(value.x))
	if value.y < -0.18:
		Input.action_press("move_up", absf(value.y))
	elif value.y > 0.18:
		Input.action_press("move_down", absf(value.y))

func _release_directions() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)

func _button_at(point: Vector2) -> String:
	var centers := _button_centers()
	if point.distance_to(centers.attack) <= BUTTON_RADIUS * 1.25:
		return "attack"
	if point.distance_to(centers.jump) <= BUTTON_RADIUS * 1.2:
		return "jump"
	if point.distance_to(centers.special) <= BUTTON_RADIUS * 1.1:
		return "special"
	return ""

func _button_centers() -> Dictionary:
	return {
		"attack": Vector2(size.x - 118, size.y - 122),
		"jump": Vector2(size.x - 250, size.y - 82),
		"special": Vector2(size.x - 250, size.y - 218)
	}

func _pulse_start() -> void:
	Input.action_press("start")
	get_tree().create_timer(0.12).timeout.connect(func(): Input.action_release("start"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_directions()
		for action in button_touches.values():
			Input.action_release(action)
		button_touches.clear()
		joystick_touch = -1

func _draw() -> void:
	if not enabled_for_device or not is_instance_valid(game) or game.state != "playing":
		return
	if joystick_touch < 0:
		joystick_center = Vector2(150, size.y - 132)
		joystick_knob = joystick_center
	# High-contrast translucent controls remain readable on bright stages.
	draw_circle(joystick_center, JOYSTICK_RADIUS, Color(0.02, 0.04, 0.05, 0.48))
	draw_arc(joystick_center, JOYSTICK_RADIUS, 0, TAU, 48, Color(0.95, 0.82, 0.36, 0.68), 4)
	draw_circle(joystick_knob, KNOB_RADIUS, Color(0.82, 0.88, 0.84, 0.52))
	var centers := _button_centers()
	_draw_action_button(centers.attack, "A", Color("#df5548"), Input.is_action_pressed("attack"))
	_draw_action_button(centers.jump, "B", Color("#d8a63d"), Input.is_action_pressed("jump"))
	_draw_action_button(centers.special, "A+B", Color("#347f75"), Input.is_action_pressed("special"), 15)

func _draw_action_button(center: Vector2, label: String, color: Color, pressed: bool, font_size: int = 25) -> void:
	var radius := BUTTON_RADIUS * (0.91 if pressed else 1.0)
	var fill := color
	fill.a = 0.78 if pressed else 0.56
	draw_circle(center, radius, Color(0.01, 0.02, 0.03, 0.55))
	draw_circle(center, radius - 5.0, fill)
	draw_arc(center, radius, 0, TAU, 40, Color(1, 0.92, 0.62, 0.78), 3)
	draw_string(font, center + Vector2(-radius, 8), label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, font_size, Color.WHITE)
