class_name FighterRunController
extends RefCounted

const TAP_WINDOW := 0.28
const INPUT_THRESHOLD := 0.35

var previous_direction := -1
var last_tap_direction := -1
var run_direction := -1
var tap_window := 0.0
var running := false
var turned_around := false


func tick(delta: float) -> void:
	tap_window = maxf(tap_window - maxf(delta, 0.0), 0.0)
	if tap_window <= 0.0 and not running:
		last_tap_direction = -1


func update(move: Vector2) -> void:
	turned_around = false
	var current_direction := direction_index(move)
	if current_direction < 0:
		previous_direction = -1
		running = false
		return

	var pressed_edge := previous_direction < 0
	if running:
		var direction_change := _direction_distance(run_direction, current_direction)
		if direction_change >= 3:
			running = false
			turned_around = true
			last_tap_direction = current_direction
			tap_window = TAP_WINDOW
		else:
			run_direction = current_direction
	elif pressed_edge:
		if current_direction == last_tap_direction and tap_window > 0.0:
			running = true
			run_direction = current_direction
			tap_window = 0.0
		else:
			last_tap_direction = current_direction
			tap_window = TAP_WINDOW
	previous_direction = current_direction


func cancel(clear_tap: bool = true) -> void:
	running = false
	run_direction = -1
	turned_around = false
	previous_direction = -1
	if clear_tap:
		last_tap_direction = -1
		tap_window = 0.0


static func direction_index(move: Vector2) -> int:
	if move.length() < INPUT_THRESHOLD:
		return -1
	return posmod(roundi(move.angle() / (PI * 0.25)), 8)


static func direction_vector(index: int) -> Vector2:
	if index < 0:
		return Vector2.ZERO
	return Vector2.RIGHT.rotated(float(posmod(index, 8)) * PI * 0.25)


static func _direction_distance(first: int, second: int) -> int:
	var clockwise := posmod(second - first, 8)
	return mini(clockwise, 8 - clockwise)
