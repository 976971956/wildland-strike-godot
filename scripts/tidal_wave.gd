class_name TidalWave
extends Node2D

const MEDIUM_IMPACT = preload("res://data/impacts/medium.tres")

var game: Node
var source_actor: Node
var direction := 1
var speed := 520.0
var lifetime := 1.35
var damage := 20
var hit_targets := {}


func setup(p_game: Node, p_source: Node, p_direction: int, p_damage: int) -> void:
	game = p_game
	source_actor = p_source
	direction = 1 if p_direction >= 0 else -1
	damage = maxi(p_damage, 1)
	position = p_source.position + Vector2(direction * 82.0, 0.0)
	z_index = int(position.y) + 18
	add_to_group("stage_effects")
	queue_redraw()


func _physics_process(delta: float) -> void:
	lifetime -= delta
	position.x += direction * speed * delta
	_resolve_hits()
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()


func _resolve_hits() -> void:
	for fighter in game.get_active_players():
		if not is_instance_valid(fighter) or fighter.is_defeated or hit_targets.has(fighter) or absf(fighter.position.x - position.x) > 74.0 or absf(fighter.position.y - position.y) > 92.0:
			continue
		hit_targets[fighter] = true
		fighter.take_hit(damage, Vector2(direction * 390.0, -42.0), false, 0.0, true, MEDIUM_IMPACT)


func _draw() -> void:
	var points := PackedVector2Array([Vector2(-82, 22), Vector2(-64, -46), Vector2(-20, -76), Vector2(18, -44), Vector2(54, -68), Vector2(88, 18)])
	if direction < 0:
		for index in range(points.size()):
			points[index].x *= -1.0
	draw_colored_polygon(points, Color(0.18, 0.68, 0.78, 0.52))
	draw_polyline(points, Color(0.78, 0.96, 1.0, 0.82), 6.0)
	for index in range(5):
		draw_circle(Vector2(-direction * 40.0 + index * direction * 20.0, -38.0 - index % 2 * 16.0), 7.0, Color(0.75, 0.95, 1.0, 0.58))
