class_name FighterCommandMoveController
extends RefCounted

const INPUT_WINDOW := 0.42
const INPUT_THRESHOLD := 0.45

enum InputKind {
	NEUTRAL,
	DOWN,
	FORWARD,
	OTHER,
}

var phase := 0
var input_window := 0.0
var sequence_facing := 1
var previous_kind := InputKind.NEUTRAL


func tick(delta: float) -> void:
	input_window = maxf(input_window - maxf(delta, 0.0), 0.0)
	if input_window <= 0.0:
		cancel()


func update(move: Vector2, facing: int) -> void:
	var reference_facing := sequence_facing if phase > 0 else facing
	var kind := classify(move, reference_facing)
	if kind == previous_kind:
		return
	previous_kind = kind
	if kind == InputKind.NEUTRAL:
		return
	if phase == 0:
		if kind == InputKind.DOWN:
			phase = 1
			sequence_facing = 1 if facing >= 0 else -1
			input_window = INPUT_WINDOW
		return
	if phase == 1:
		if kind == InputKind.FORWARD:
			phase = 2
			input_window = INPUT_WINDOW
		elif kind != InputKind.DOWN:
			cancel()
		return
	if phase == 2 and kind == InputKind.DOWN:
		phase = 1
		sequence_facing = 1 if facing >= 0 else -1
		input_window = INPUT_WINDOW
	elif phase == 2 and kind != InputKind.FORWARD:
		cancel()


func is_ready() -> bool:
	return phase == 2 and input_window > 0.0


func consume_attack() -> bool:
	var accepted := is_ready()
	cancel()
	return accepted


func cancel() -> void:
	phase = 0
	input_window = 0.0
	previous_kind = InputKind.NEUTRAL


static func classify(move: Vector2, facing: int) -> int:
	if move.length() < INPUT_THRESHOLD:
		return InputKind.NEUTRAL
	var normalized := move.normalized()
	if normalized.y > 0.55 and absf(normalized.x) < 0.75:
		return InputKind.DOWN
	if normalized.x * (1 if facing >= 0 else -1) > 0.55 and absf(normalized.y) < 0.85:
		return InputKind.FORWARD
	return InputKind.OTHER
