class_name StageAmbience
extends Node2D

const REDRAW_INTERVAL := 1.0 / 20.0

var scenes: Array[Resource] = []
var animation_time := 0.0
var redraw_accumulator := 0.0


func configure(stage_scenes: Array[Resource]) -> void:
	scenes = stage_scenes
	queue_redraw()


func _process(delta: float) -> void:
	animation_time += delta
	redraw_accumulator += delta
	if redraw_accumulator >= REDRAW_INTERVAL:
		redraw_accumulator = fmod(redraw_accumulator, REDRAW_INTERVAL)
		queue_redraw()


func ambience_signature(scene_index: int, time: float) -> Dictionary:
	if scene_index < 0 or scene_index >= scenes.size():
		return {}
	var scene := scenes[scene_index]
	return {
		"scene_id": scene.scene_id,
		"pulse": snappedf((sin(time * (2.1 + scene.visual_theme * 0.4)) + 1.0) * 0.5, 0.001),
		"drift": snappedf(fmod(time * (18.0 + scene.visual_theme * 7.0), 96.0), 0.001),
	}


func _draw() -> void:
	for scene in scenes:
		match scene.visual_theme:
			0:
				_draw_ruins(scene)
			1:
				_draw_courtyard(scene)
			2:
				_draw_plant(scene)
			3:
				_draw_flooded_cypress(scene)
			4:
				_draw_flooded_camp(scene)
			5:
				_draw_spillway(scene)
			6:
				_draw_highway_canyon(scene)
			7:
				_draw_highway_checkpoint(scene)
			8:
				_draw_highway_overpass(scene)


func _draw_ruins(scene: Resource) -> void:
	var pulse := (sin(animation_time * 5.2) + 1.0) * 0.5
	var fire_x: float = scene.start_x + 116.0
	draw_circle(Vector2(fire_x, 431.0), 8.0 + pulse * 5.0, Color(1.0, 0.31, 0.08, 0.52))
	draw_circle(Vector2(fire_x + 4.0, 423.0 - pulse * 5.0), 5.0 + pulse * 3.0, Color(1.0, 0.73, 0.18, 0.68))
	for i in range(7):
		var drift := fmod(animation_time * (11.0 + i * 1.7) + i * 37.0, 126.0)
		var ember_x: float = scene.start_x + 70.0 + fmod(i * 151.0 + drift * 0.35, maxf(scene.end_x - scene.start_x - 140.0, 1.0))
		var ember_y: float = 438.0 - drift
		draw_rect(Rect2(ember_x, ember_y, 3.0, 3.0), Color(1.0, 0.48, 0.12, 0.48))
	for i in range(4):
		var smoke_lift := fmod(animation_time * 17.0 + i * 21.0, 84.0)
		draw_circle(
			Vector2(fire_x + sin(animation_time * 1.3 + i) * 12.0, 408.0 - smoke_lift),
			12.0 + i * 3.0,
			Color(0.12, 0.12, 0.14, 0.16 * (1.0 - smoke_lift / 100.0))
		)


func _draw_courtyard(scene: Resource) -> void:
	var width: float = scene.end_x - scene.start_x
	for i in range(9):
		var rain_x: float = scene.start_x + fmod(i * 173.0 + animation_time * 84.0, width)
		var rain_y: float = 322.0 + fmod(i * 47.0 + animation_time * 138.0, 250.0)
		draw_line(Vector2(rain_x, rain_y), Vector2(rain_x - 7.0, rain_y + 18.0), Color(0.55, 0.78, 0.86, 0.22), 2.0)
	for i in range(5):
		var ripple_phase := fmod(animation_time * 26.0 + i * 23.0, 72.0)
		var center := Vector2(scene.start_x + 160.0 + i * 282.0, 580.0 + (i % 2) * 35.0)
		draw_polyline(_ellipse_points(center, 12.0 + ripple_phase, 3.0 + ripple_phase * 0.12), Color(0.48, 0.78, 0.83, 0.22 * (1.0 - ripple_phase / 78.0)), 2.0)


func _draw_plant(scene: Resource) -> void:
	var alert := (sin(animation_time * 6.8) + 1.0) * 0.5
	for i in range(4):
		var light_x: float = scene.start_x + 178.0 + i * 392.0
		draw_circle(Vector2(light_x, 393.0), 7.0 + alert * 3.0, Color(1.0, 0.12, 0.05, 0.28 + alert * 0.42))
	for vent_index in range(3):
		var vent_x: float = scene.start_x + 420.0 + vent_index * 510.0
		for puff_index in range(4):
			var rise := fmod(animation_time * (22.0 + vent_index * 3.0) + puff_index * 28.0, 108.0)
			var sway := sin(animation_time * 1.7 + puff_index + vent_index) * 13.0
			draw_circle(
				Vector2(vent_x + sway, 454.0 - rise),
				9.0 + puff_index * 3.0,
				Color(0.72, 0.78, 0.76, 0.15 * (1.0 - rise / 118.0))
			)


func _draw_flooded_cypress(scene: Resource) -> void:
	_draw_monsoon(scene, 1.0)
	var flash := maxf(0.0, sin(animation_time * 0.73) - 0.985) * 35.0
	if flash > 0.0:
		draw_rect(Rect2(scene.start_x, 0.0, scene.end_x - scene.start_x, 430.0), Color(0.66, 0.82, 1.0, minf(flash, 0.2)))


func _draw_flooded_camp(scene: Resource) -> void:
	_draw_monsoon(scene, 0.78)
	for index in range(4):
		var pulse := (sin(animation_time * 4.4 + index) + 1.0) * 0.5
		draw_circle(Vector2(scene.start_x + 260.0 + index * 330.0, 410.0), 5.0 + pulse * 2.0, Color(1.0, 0.58, 0.18, 0.34 + pulse * 0.28))


func _draw_spillway(scene: Resource) -> void:
	for index in range(8):
		var drift := fmod(animation_time * (18.0 + index) + index * 19.0, 94.0)
		draw_circle(Vector2(scene.start_x + 180.0 + index * 146.0 + sin(animation_time + index) * 12.0, 472.0 - drift), 9.0 + index % 3 * 3.0, Color(0.7, 0.88, 0.92, 0.13 * (1.0 - drift / 100.0)))
	for index in range(5):
		var ripple := fmod(animation_time * 34.0 + index * 27.0, 88.0)
		draw_polyline(_ellipse_points(Vector2(scene.start_x + 190.0 + index * 255.0, 610.0), 16.0 + ripple, 4.0 + ripple * 0.1), Color(0.54, 0.85, 0.9, 0.2 * (1.0 - ripple / 92.0)), 2.0)


func _draw_monsoon(scene: Resource, strength: float) -> void:
	var width: float = scene.end_x - scene.start_x
	for index in range(14):
		var rain_x: float = scene.start_x + fmod(index * 127.0 + animation_time * 128.0, width)
		var rain_y: float = 275.0 + fmod(index * 61.0 + animation_time * 182.0, 360.0)
		draw_line(Vector2(rain_x, rain_y), Vector2(rain_x - 9.0, rain_y + 24.0), Color(0.62, 0.84, 0.92, 0.2 * strength), 2.0)


func _draw_highway_canyon(scene: Resource) -> void:
	var width: float = scene.end_x - scene.start_x
	for index in range(8):
		var dust_x: float = scene.start_x + fmod(index * 193.0 - animation_time * (48.0 + index * 2.0), width)
		var dust_y := 618.0 + index % 3 * 19.0
		draw_line(Vector2(dust_x, dust_y), Vector2(dust_x + 78.0, dust_y - 8.0), Color(0.86, 0.55, 0.28, 0.12), 5.0)


func _draw_highway_checkpoint(scene: Resource) -> void:
	for index in range(6):
		var pulse := (sin(animation_time * 5.2 + index * 0.8) + 1.0) * 0.5
		draw_circle(Vector2(scene.start_x + 145.0 + index * 220.0, 414.0), 5.0 + pulse * 2.0, Color(1.0, 0.22, 0.08, 0.28 + pulse * 0.4))
	for index in range(5):
		var spark_x: float = scene.start_x + fmod(index * 281.0 + animation_time * 94.0, scene.end_x - scene.start_x)
		draw_line(Vector2(spark_x, 468.0), Vector2(spark_x - 11.0, 480.0), Color(1.0, 0.72, 0.2, 0.3), 2.0)


func _draw_highway_overpass(scene: Resource) -> void:
	_draw_monsoon(scene, 0.58)
	var flash := maxf(0.0, sin(animation_time * 0.91) - 0.987) * 42.0
	if flash > 0.0:
		draw_rect(Rect2(scene.start_x, 0.0, scene.end_x - scene.start_x, 520.0), Color(0.68, 0.76, 1.0, minf(flash, 0.23)))
	for index in range(6):
		var drift := fmod(animation_time * 30.0 + index * 24.0, 88.0)
		draw_polyline(_ellipse_points(Vector2(scene.start_x + 160.0 + index * 220.0, 616.0), 12.0 + drift, 3.0 + drift * 0.08), Color(0.48, 0.7, 0.94, 0.17 * (1.0 - drift / 92.0)), 2.0)


func _ellipse_points(center: Vector2, radius_x: float, radius_y: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(25):
		var angle := TAU * i / 24.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
