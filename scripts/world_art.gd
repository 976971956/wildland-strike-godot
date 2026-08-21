extends Node2D

const WORLD_W := 4200.0
const STAGE_TEXTURE: Texture2D = preload("res://assets/backgrounds/ruined_city_stage.png")
const StageSceneDefinitionScript = preload("res://core/stages/stage_scene_definition.gd")

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
	var tint := Color.WHITE
	match scene.visual_theme:
		StageSceneDefinitionScript.VisualTheme.COURTYARD:
			tint = Color(0.76, 0.92, 0.93, 1.0)
		StageSceneDefinitionScript.VisualTheme.PLANT:
			tint = Color(0.93, 0.72, 0.64, 1.0)
	draw_texture_rect(STAGE_TEXTURE, rect, false, tint)
	match scene.visual_theme:
		StageSceneDefinitionScript.VisualTheme.COURTYARD:
			_draw_courtyard(scene.start_x, scene.end_x)
		StageSceneDefinitionScript.VisualTheme.PLANT:
			_draw_plant(scene.start_x, scene.end_x)
		_:
			_draw_ruins(scene.start_x, scene.end_x)
	_draw_transition_marker(scene.start_x, scene.display_name)


func _draw_ruins(start_x: float, end_x: float) -> void:
	draw_rect(Rect2(start_x, 0.0, end_x - start_x, 720.0), Color(0.28, 0.12, 0.04, 0.07))
	for x in range(int(start_x) + 150, int(end_x), 310):
		draw_line(Vector2(x, 410), Vector2(x + 95, 360), Color(0.16, 0.24, 0.12, 0.7), 11.0)
		draw_circle(Vector2(x + 98, 358), 26.0, Color(0.18, 0.34, 0.16, 0.72))


func _draw_courtyard(start_x: float, end_x: float) -> void:
	draw_rect(Rect2(start_x, 445.0, end_x - start_x, 220.0), Color(0.05, 0.24, 0.28, 0.18))
	for x in range(int(start_x) + 80, int(end_x), 260):
		_draw_oval(Vector2(x, 596), 78.0, 16.0, Color(0.12, 0.42, 0.48, 0.32))
		draw_line(Vector2(x - 60, 597), Vector2(x + 50, 597), Color(0.48, 0.82, 0.82, 0.22), 3.0)
	for x in range(int(start_x) + 40, int(end_x), 180):
		draw_line(Vector2(x, 420), Vector2(x, 490), Color(0.25, 0.34, 0.35, 0.8), 6.0)
		draw_line(Vector2(x, 435), Vector2(x + 180, 435), Color(0.25, 0.34, 0.35, 0.58), 4.0)


func _draw_plant(start_x: float, end_x: float) -> void:
	draw_rect(Rect2(start_x, 0.0, end_x - start_x, 720.0), Color(0.35, 0.03, 0.035, 0.16))
	for x in range(int(start_x) + 90, int(end_x), 290):
		draw_rect(Rect2(x, 320, 38, 176), Color(0.15, 0.17, 0.18, 0.9))
		draw_rect(Rect2(x + 8, 330, 22, 158), Color(0.43, 0.19, 0.13, 0.72))
		draw_line(Vector2(x + 19, 318), Vector2(x + 19, 270), Color(0.3, 0.31, 0.29, 0.9), 14.0)
	for x in range(int(start_x), int(end_x), 96):
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 648), Vector2(x + 48, 648), Vector2(x + 16, 670), Vector2(x - 32, 670)
		]), Color(0.92, 0.56, 0.13, 0.5))


func _draw_transition_marker(x: float, label: String) -> void:
	if x <= 0.0:
		return
	draw_rect(Rect2(x, 405.0, 8.0, 260.0), Color(0.95, 0.69, 0.2, 0.78))
	draw_rect(Rect2(x + 8.0, 410.0, 190.0, 36.0), Color(0.03, 0.05, 0.06, 0.86))
	draw_string(ThemeDB.fallback_font, Vector2(x + 18.0, 436.0), label, HORIZONTAL_ALIGNMENT_LEFT, 170.0, 16, Color("#ffe184"))


func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(25):
		var angle := TAU * index / 24.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
