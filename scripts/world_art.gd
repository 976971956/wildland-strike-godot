extends Node2D

const WORLD_W := 4200.0
const STAGE_TEXTURE: Texture2D = preload("res://assets/backgrounds/ruined_city_stage.png")

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Repeat the hand-pixeled background as wide arcade screens.
	for i in range(4):
		draw_texture_rect(STAGE_TEXTURE, Rect2(i * 1280.0, 0.0, 1280.0, 720.0), false)
	# Cover the final camera edge with a cropped continuation.
	draw_texture_rect_region(STAGE_TEXTURE, Rect2(3840.0, 0.0, 360.0, 720.0), Rect2(0.0, 0.0, 470.0, 941.0))
