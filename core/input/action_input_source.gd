class_name ActionInputSource
extends Node

const FighterIntentScript = preload("res://core/input/fighter_intent.gd")


func sample_intent():
	return FighterIntentScript.new(
		Input.get_vector("move_left", "move_right", "move_up", "move_down"),
		Input.is_action_just_pressed("jump"),
		Input.is_action_just_pressed("attack"),
		Input.is_action_just_pressed("special")
	)
