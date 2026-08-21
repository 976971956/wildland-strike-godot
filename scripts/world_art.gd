extends Node2D

const WORLD_W := 4200.0
const STAGE_TEXTURE: Texture2D = preload("res://assets/backgrounds/ruined_city_stage.png")

var scenes: Array[Resource] = []

func _ready() -> void:
	queue_redraw()


func configure(stage_definition: Resource) -> void:
	scenes = stage_definition.scenes if stage_definition != null else []
	queue_redraw()


func _draw() -> void:
	if scenes.is_empty():
		draw_texture_rect(STAGE_TEXTURE, Rect2(0.0, 0.0, WORLD_W, 720.0), false)
		return
	for scene in scenes:
		_draw_scene(scene)


func _draw_scene(scene: Resource) -> void:
	var width: float = scene.end_x - scene.start_x
	var rect := Rect2(scene.start_x, 0.0, width, 720.0)
	var texture: Texture2D = scene.background_texture if scene.background_texture != null else STAGE_TEXTURE
	draw_texture_rect(texture, rect, false)
