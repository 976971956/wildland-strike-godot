class_name DeviceInputSource
extends Node

const FighterIntentScript = preload("res://core/input/fighter_intent.gd")
const KEYBOARD_DEVICE := -1
const STICK_DEADZONE := 0.24

var device_id := KEYBOARD_DEVICE
var virtual_actions_enabled := false
var previous_jump_down := false
var previous_attack_down := false
var previous_special_down := false


func configure(p_device_id: int, p_virtual_actions_enabled := false) -> void:
	device_id = p_device_id
	virtual_actions_enabled = p_virtual_actions_enabled
	reset_edges()


func sample_intent():
	if device_id == KEYBOARD_DEVICE:
		if virtual_actions_enabled:
			return FighterIntentScript.new(
				Input.get_vector("move_left", "move_right", "move_up", "move_down"),
				Input.is_action_just_pressed("jump"),
				Input.is_action_just_pressed("attack"),
				Input.is_action_just_pressed("special")
			)
		var move := Vector2(
			float(_key_down(KEY_D) or _key_down(KEY_RIGHT)) - float(_key_down(KEY_A) or _key_down(KEY_LEFT)),
			float(_key_down(KEY_S) or _key_down(KEY_DOWN)) - float(_key_down(KEY_W) or _key_down(KEY_UP))
		).limit_length(1.0)
		return sample_from_state(
			move,
			_key_down(KEY_K) or _key_down(KEY_X),
			_key_down(KEY_J) or _key_down(KEY_Z),
			_key_down(KEY_L) or _key_down(KEY_C)
		)
	var move := Vector2(
		Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	)
	var dpad := Vector2(
		float(Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_RIGHT)) - float(Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_LEFT)),
		float(Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_DOWN)) - float(Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_UP))
	)
	if dpad != Vector2.ZERO:
		move = dpad.normalized()
	elif move.length() < STICK_DEADZONE:
		move = Vector2.ZERO
	else:
		move = move.limit_length(1.0)
	return sample_from_state(
		move,
		Input.is_joy_button_pressed(device_id, JOY_BUTTON_B),
		Input.is_joy_button_pressed(device_id, JOY_BUTTON_A),
		Input.is_joy_button_pressed(device_id, JOY_BUTTON_X)
	)


func sample_from_state(move: Vector2, jump_down: bool, attack_down: bool, special_down: bool):
	var intent = FighterIntentScript.new(
		move,
		jump_down and not previous_jump_down,
		attack_down and not previous_attack_down,
		special_down and not previous_special_down
	)
	previous_jump_down = jump_down
	previous_attack_down = attack_down
	previous_special_down = special_down
	return intent


func reset_edges() -> void:
	previous_jump_down = false
	previous_attack_down = false
	previous_special_down = false


func _key_down(keycode: Key) -> bool:
	return Input.is_physical_key_pressed(keycode)
