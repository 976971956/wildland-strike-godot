extends Control

const JOYSTICK_RADIUS := 78.0
const KNOB_RADIUS := 32.0
const BUTTON_RADIUS := 54.0
const EDGE_PADDING := 22.0
const JOYSTICK_DEADZONE := 0.12

var game
var enabled_for_device := false
var joystick_touch := -1
var joystick_center := Vector2(150, 580)
var joystick_knob := Vector2(150, 580)
var button_touches: Dictionary = {}
var font: Font
var safe_area_override := Rect2()

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
		if game.state == "options":
			_handle_options_touch(event.position)
			get_viewport().set_input_as_handled()
			return
		if game.state == "controls":
			if event.position.y >= size.y - 74.0:
				game._return_to_options()
			else:
				game.control_selected_index = clampi(int((event.position.y - 159.0) / 50.0), 0, game.REBIND_ACTIONS.size() - 1)
				game._begin_control_rebind()
			get_viewport().set_input_as_handled()
			return
		if game.state == "title" and event.position.y >= 410.0 and event.position.y <= 500.0:
			if event.position.x < size.x * 0.5:
				game._open_high_scores()
			else:
				game._open_options("title")
			get_viewport().set_input_as_handled()
			return
		if game.state == "select":
			var card_width := size.x / maxf(game.HERO_DEFINITIONS.size(), 1)
			var selected_index := clampi(int(event.position.x / card_width), 0, game.HERO_DEFINITIONS.size() - 1)
			if selected_index == game.selected_hero_index:
				game.confirm_hero_selection()
			else:
				game.select_hero(selected_index)
			get_viewport().set_input_as_handled()
			return
		if game.state != "playing":
			_pulse_start()
			get_viewport().set_input_as_handled()
			return
		if event.position.distance_to(_pause_center()) <= 38.0 * _control_scale():
			_pulse_action("pause")
		elif _point_on_joystick_side(event.position) and joystick_touch < 0:
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
			_reset_joystick()
			_release_directions()
		elif button_touches.has(event.index):
			Input.action_release(button_touches[event.index])
			button_touches.erase(event.index)

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index != joystick_touch:
		return
	var offset := event.position - joystick_center
	var radius := JOYSTICK_RADIUS * _control_scale()
	if offset.length() > radius:
		offset = offset.normalized() * radius
	joystick_knob = joystick_center + offset
	_update_joystick(offset / radius)
	get_viewport().set_input_as_handled()

func _update_joystick(value: Vector2) -> void:
	_release_directions()
	var resolved := _smooth_joystick_value(value)
	_set_virtual_move(resolved)
	if resolved.x < 0.0:
		Input.action_press("move_left", absf(resolved.x))
	elif resolved.x > 0.0:
		Input.action_press("move_right", absf(resolved.x))
	if resolved.y < 0.0:
		Input.action_press("move_up", absf(resolved.y))
	elif resolved.y > 0.0:
		Input.action_press("move_down", absf(resolved.y))


func _smooth_joystick_value(value: Vector2) -> Vector2:
	var magnitude := minf(value.length(), 1.0)
	if magnitude <= JOYSTICK_DEADZONE:
		return Vector2.ZERO
	var strength := inverse_lerp(JOYSTICK_DEADZONE, 1.0, magnitude)
	return value.normalized() * strength


func _set_virtual_move(value: Vector2) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.player):
		return
	var source = game.player.input_source
	if source != null and source.has_method("set_virtual_move"):
		source.set_virtual_move(value)

func _release_directions() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)
	_set_virtual_move(Vector2.ZERO)

func _button_at(point: Vector2) -> String:
	var centers := _button_centers()
	var radius := BUTTON_RADIUS * _control_scale()
	if point.distance_to(centers.attack) <= radius * 1.25:
		return "attack"
	if point.distance_to(centers.jump) <= radius * 1.2:
		return "jump"
	if point.distance_to(centers.special) <= radius * 1.1:
		return "special"
	return ""

func _button_centers() -> Dictionary:
	var safe := _safe_rect()
	var scale := _control_scale()
	var compact := String(game.settings.get("touch_layout", "classic")) == "compact"
	var horizontal_multiplier := 0.86 if compact else 1.0
	var attack_offset := 96.0 * scale * horizontal_multiplier
	var secondary_offset := 218.0 * scale * horizontal_multiplier
	if String(game.settings.get("touch_layout", "classic")) == "left_handed":
		return {
			"attack": Vector2(safe.position.x + attack_offset, safe.end.y - 106.0 * scale),
			"jump": Vector2(safe.position.x + secondary_offset, safe.end.y - 72.0 * scale),
			"special": Vector2(safe.position.x + secondary_offset, safe.end.y - 198.0 * scale)
		}
	return {
		"attack": Vector2(safe.end.x - attack_offset, safe.end.y - 106.0 * scale),
		"jump": Vector2(safe.end.x - secondary_offset, safe.end.y - 72.0 * scale),
		"special": Vector2(safe.end.x - secondary_offset, safe.end.y - 198.0 * scale)
	}

func _pulse_start() -> void:
	_pulse_action("start")


func _pulse_action(action: String) -> void:
	Input.action_press(action)
	get_tree().create_timer(0.12, true).timeout.connect(func(): Input.action_release(action))


func _handle_options_touch(point: Vector2) -> void:
	if point.y >= size.y - 74.0:
		game._close_options()
		return
	var option_index := clampi(int((point.y - 139.0) / 38.0), 0, game.OPTION_KEYS.size() - 1)
	game.options_selected_index = option_index
	game._adjust_option(-1 if point.x < size.x * 0.5 else 1)


func _control_scale() -> float:
	if not is_instance_valid(game):
		return 1.0
	return clampf(float(game.settings.get("touch_scale", 1.0)), 0.75, 1.35)


func _point_on_joystick_side(point: Vector2) -> bool:
	if String(game.settings.get("touch_layout", "classic")) == "left_handed":
		return point.x > size.x * 0.54
	return point.x < size.x * 0.46


func _safe_rect() -> Rect2:
	if safe_area_override.size.x > 0.0 and safe_area_override.size.y > 0.0:
		return safe_area_override
	var fallback := Rect2(Vector2(EDGE_PADDING, EDGE_PADDING), size - Vector2.ONE * EDGE_PADDING * 2.0)
	if DisplayServer.get_name() == "headless":
		return fallback
	var window_size := Vector2(DisplayServer.window_get_size())
	var display_safe := Rect2(DisplayServer.get_display_safe_area())
	if window_size.x <= 0.0 or window_size.y <= 0.0 or display_safe.size.x <= 0.0 or display_safe.size.y <= 0.0:
		return fallback
	var scale := Vector2(size.x / window_size.x, size.y / window_size.y)
	var safe := Rect2(display_safe.position * scale, display_safe.size * scale)
	safe.position += Vector2.ONE * EDGE_PADDING
	safe.size -= Vector2.ONE * EDGE_PADDING * 2.0
	return safe


func _pause_center() -> Vector2:
	var safe := _safe_rect()
	return Vector2(safe.end.x - 32.0 * _control_scale(), safe.position.y + 102.0 * _control_scale())


func _reset_joystick() -> void:
	var safe := _safe_rect()
	var scale := _control_scale()
	var joystick_x := safe.end.x - 112.0 * scale if String(game.settings.get("touch_layout", "classic")) == "left_handed" else safe.position.x + 112.0 * scale
	joystick_center = Vector2(joystick_x, safe.end.y - 106.0 * scale)
	joystick_knob = joystick_center

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_directions()
		for action in button_touches.values():
			Input.action_release(action)
		button_touches.clear()
		joystick_touch = -1
		if is_instance_valid(game) and game.has_method("handle_application_focus_lost"):
			game.handle_application_focus_lost()

func _draw() -> void:
	if not enabled_for_device or not is_instance_valid(game) or game.state != "playing":
		return
	if joystick_touch < 0:
		_reset_joystick()
	var scale := _control_scale()
	var joystick_radius := JOYSTICK_RADIUS * scale
	var knob_radius := KNOB_RADIUS * scale
	# High-contrast translucent controls remain readable on bright stages.
	draw_circle(joystick_center, joystick_radius, Color(0.02, 0.04, 0.05, 0.48))
	draw_arc(joystick_center, joystick_radius, 0, TAU, 48, Color(0.95, 0.82, 0.36, 0.68), 4)
	draw_circle(joystick_knob, knob_radius, Color(0.82, 0.88, 0.84, 0.52))
	var centers := _button_centers()
	_draw_action_button(centers.attack, "A", Color("#df5548"), Input.is_action_pressed("attack"), 25, scale)
	_draw_action_button(centers.jump, "B", Color("#d8a63d"), Input.is_action_pressed("jump"), 25, scale)
	_draw_action_button(centers.special, "A+B", Color("#347f75"), Input.is_action_pressed("special"), 15, scale)
	var pause := _pause_center()
	draw_circle(pause, 30.0 * scale, Color(0.01, 0.02, 0.03, 0.68))
	draw_arc(pause, 30.0 * scale, 0.0, TAU, 32, Color(0.95, 0.82, 0.36, 0.82), 3.0)
	draw_rect(Rect2(pause + Vector2(-8.0, -10.0) * scale, Vector2(5.0, 20.0) * scale), Color.WHITE)
	draw_rect(Rect2(pause + Vector2(3.0, -10.0) * scale, Vector2(5.0, 20.0) * scale), Color.WHITE)

func _draw_action_button(center: Vector2, label: String, color: Color, pressed: bool, font_size: int = 25, control_scale: float = 1.0) -> void:
	var radius := BUTTON_RADIUS * control_scale * (0.91 if pressed else 1.0)
	var fill := color
	fill.a = 0.78 if pressed else 0.56
	draw_circle(center, radius, Color(0.01, 0.02, 0.03, 0.55))
	draw_circle(center, radius - 5.0, fill)
	draw_arc(center, radius, 0, TAU, 40, Color(1, 0.92, 0.62, 0.78), 3)
	draw_string(font, center + Vector2(-radius, 8.0 * control_scale), label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, roundi(font_size * control_scale), Color.WHITE)
