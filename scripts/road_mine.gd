class_name RoadMineHazard
extends Node2D

var game: Node
var source_actor: Node
var damage := 20
var arm_timer := 0.65
var lifetime := 8.0
var pulse := 0.0
var triggered := false


func setup(p_game: Node, p_source_actor: Node, p_position: Vector2, p_damage: int) -> void:
	game = p_game
	source_actor = p_source_actor
	position = p_position
	damage = p_damage
	add_to_group("stage_effects")
	add_to_group("road_mines")
	z_index = int(position.y) - 2
	queue_redraw()


func _physics_process(delta: float) -> void:
	if triggered:
		return
	arm_timer = maxf(0.0, arm_timer - delta)
	lifetime = maxf(0.0, lifetime - delta)
	pulse += delta
	if lifetime <= 0.0:
		queue_free()
		return
	if arm_timer <= 0.0 and is_instance_valid(game.highway_vehicle):
		var vehicle: Node = game.highway_vehicle
		if absf(vehicle.position.x - position.x) <= 94.0 and absf(vehicle.position.y - position.y) <= 54.0:
			triggered = true
			vehicle.apply_external_collision(damage)
			game.play_sfx(&"road_mine")
			queue_free()
	queue_redraw()


func _draw() -> void:
	var armed_color := Color("#ef442f") if arm_timer <= 0.0 else Color("#e2b63b")
	draw_circle(Vector2.ZERO, 21.0, Color(0.02, 0.03, 0.03, 0.56))
	draw_circle(Vector2(0.0, -5.0), 16.0, Color("#30383d"))
	draw_arc(Vector2(0.0, -5.0), 13.0, 0.0, TAU, 20, Color("#7c8a8f"), 4.0)
	draw_circle(Vector2(0.0, -8.0), 4.0 + sin(pulse * 10.0), armed_color)
	for index in range(6):
		var angle := TAU * index / 6.0
		draw_line(Vector2(cos(angle), sin(angle)) * 13.0 + Vector2(0.0, -5.0), Vector2(cos(angle), sin(angle)) * 25.0 + Vector2(0.0, -5.0), Color("#4a5358"), 5.0)
