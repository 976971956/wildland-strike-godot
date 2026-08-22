class_name FurnaceWave
extends Node2D

const MEDIUM_IMPACT = preload("res://data/impacts/medium.tres")

var game: Node
var source_actor: Node
var direction := 1
var damage := 12
var lifetime := 1.15
var speed := 410.0
var hit_actor_ids := {}


func setup(p_game: Node, p_source: Node, p_direction: int, p_damage: int) -> void:
	game = p_game
	source_actor = p_source
	direction = 1 if p_direction >= 0 else -1
	damage = maxi(1, p_damage)
	position = p_source.position + Vector2(direction * 52.0, 0.0)
	z_index = int(position.y) + 6
	add_to_group("furnace_waves")
	queue_redraw()


func _physics_process(delta: float) -> void:
	lifetime -= delta
	position.x += direction * speed * delta
	for fighter in game.get_active_players():
		_try_hit_player(fighter)
	for target in get_tree().get_nodes_in_group("enemies"):
		if target != source_actor and is_instance_valid(target) and target.definition.faction != source_actor.definition.faction:
			_try_hit_enemy(target)
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()


func _try_hit_player(fighter: Node) -> void:
	if not _can_hit(fighter):
		return
	var health_before: int = fighter.health
	fighter.take_hit(damage, Vector2(direction * 310.0, -36.0), false, 0.05, true, MEDIUM_IMPACT)
	if fighter.health < health_before:
		hit_actor_ids[fighter.get_instance_id()] = true


func _try_hit_enemy(target: Node) -> void:
	if not _can_hit(target):
		return
	var health_before: int = target.health
	target.take_hit(damage, Vector2(direction * 310.0, -36.0), false, false, 0.05, true)
	if target.health < health_before:
		hit_actor_ids[target.get_instance_id()] = true


func _can_hit(actor: Node) -> bool:
	return (
		is_instance_valid(actor)
		and not actor.is_defeated
		and not hit_actor_ids.has(actor.get_instance_id())
		and absf(actor.position.x - position.x) <= 58.0
		and absf(actor.position.y - position.y) <= 48.0
	)


func _draw() -> void:
	var pulse := 0.72 + sin(Time.get_ticks_msec() * 0.028) * 0.18
	draw_colored_polygon(PackedVector2Array([
		Vector2(-54.0, 4.0),
		Vector2(-38.0, -24.0),
		Vector2(-18.0, -10.0),
		Vector2(0.0, -52.0),
		Vector2(18.0, -12.0),
		Vector2(42.0, -34.0),
		Vector2(58.0, 4.0),
	]), Color(1.0, 0.26, 0.04, pulse))
	draw_polyline(PackedVector2Array([Vector2(-54.0, 4.0), Vector2(0.0, -32.0), Vector2(58.0, 4.0)]), Color(1.0, 0.86, 0.26, 0.9), 6.0)
