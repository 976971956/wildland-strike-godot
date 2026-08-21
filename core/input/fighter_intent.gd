class_name FighterIntent
extends RefCounted

var move := Vector2.ZERO
var jump_pressed := false
var attack_pressed := false
var special_pressed := false


func _init(
	p_move: Vector2 = Vector2.ZERO,
	p_jump_pressed: bool = false,
	p_attack_pressed: bool = false,
	p_special_pressed: bool = false
) -> void:
	move = p_move.limit_length(1.0)
	jump_pressed = p_jump_pressed
	attack_pressed = p_attack_pressed
	special_pressed = p_special_pressed


func has_action() -> bool:
	return jump_pressed or attack_pressed or special_pressed
