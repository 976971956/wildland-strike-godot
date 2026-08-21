class_name FighterStateMachine
extends RefCounted

signal changed(previous_state: int, current_state: int)

enum State {
	IDLE,
	MOVE,
	ATTACK,
	AIRBORNE,
	SPECIAL,
	GRAB_HOLD,
	GRABBED,
	HURT,
	STUN,
	KNOCKDOWN,
	DEFEATED,
}

var current_state := State.IDLE
var previous_state := State.IDLE
var elapsed := 0.0
var revision := 0


func transition(next_state: int) -> bool:
	if next_state == current_state:
		return false
	if current_state == State.DEFEATED:
		return false
	_set_state(next_state)
	return true


func force_transition(next_state: int) -> bool:
	if next_state == current_state:
		elapsed = 0.0
		return false
	_set_state(next_state)
	return true


func tick(delta: float) -> void:
	elapsed += maxf(delta, 0.0)


func is_state(expected_state: int) -> bool:
	return current_state == expected_state


static func state_name(state: int) -> String:
	return State.keys()[state] if state >= 0 and state < State.size() else "UNKNOWN"


func _set_state(next_state: int) -> void:
	previous_state = current_state
	current_state = next_state
	elapsed = 0.0
	revision += 1
	changed.emit(previous_state, current_state)
