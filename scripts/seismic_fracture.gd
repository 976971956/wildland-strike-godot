class_name SeismicFracture
extends Node2D

const MEDIUM_IMPACT = preload("res://data/impacts/medium.tres")

var game: Node
var source_actor: Node
var damage := 18
var warning_timer := 0.48
var active_timer := 0.18
var linger_timer := 0.34
var active := false
var resolved := false
var pulse := 0.0
var hit_actor_ids := {}


func setup(p_game: Node, p_source_actor: Node, p_position: Vector2, p_damage: int) -> void:
	game = p_game
	source_actor = p_source_actor
	position = p_position
	damage = maxi(1, p_damage)
	z_index = int(position.y) + 7
	add_to_group("stage_effects")
	add_to_group("seismic_fractures")
	queue_redraw()


func _physics_process(delta: float) -> void:
	pulse += delta
	if warning_timer > 0.0:
		warning_timer = maxf(0.0, warning_timer - delta)
		if warning_timer <= 0.0:
			active = true
			_resolve_damage()
	elif active_timer > 0.0:
		active_timer = maxf(0.0, active_timer - delta)
	else:
		active = false
		linger_timer = maxf(0.0, linger_timer - delta)
		if linger_timer <= 0.0:
			queue_free()
	queue_redraw()


func _resolve_damage() -> void:
	if resolved:
		return
	resolved = true
	for fighter in game.get_active_players():
		_try_hit_player(fighter)
	for target in get_tree().get_nodes_in_group("enemies"):
		if target != source_actor and is_instance_valid(target) and target.definition.faction != source_actor.definition.faction:
			_try_hit_enemy(target)
	game.play_sfx(&"heavy")


func _try_hit_player(fighter: Node) -> void:
	if not _can_hit(fighter):
		return
	var health_before: int = fighter.health
	var direction := 1 if fighter.position.x >= position.x else -1
	fighter.take_hit(damage, Vector2(direction * 280.0, -112.0), false, 0.08, true, MEDIUM_IMPACT)
	if fighter.health < health_before:
		hit_actor_ids[fighter.get_instance_id()] = true


func _try_hit_enemy(target: Node) -> void:
	if not _can_hit(target):
		return
	var health_before: int = target.health
	var direction := 1 if target.position.x >= position.x else -1
	target.take_hit(damage, Vector2(direction * 280.0, -112.0), true, false, 0.08, true)
	if target.health < health_before:
		hit_actor_ids[target.get_instance_id()] = true


func _can_hit(actor: Node) -> bool:
	return (
		is_instance_valid(actor)
		and not actor.is_defeated
		and not hit_actor_ids.has(actor.get_instance_id())
		and absf(actor.position.x - position.x) <= 104.0
		and absf(actor.position.y - position.y) <= 58.0
	)


func _draw() -> void:
	var warning_alpha := 0.62 + sin(pulse * 18.0) * 0.16
	draw_arc(Vector2.ZERO, 96.0, 0.0, TAU, 28, Color(0.42, 0.92, 1.0, warning_alpha if warning_timer > 0.0 else 0.28), 4.0)
	for branch in range(7):
		var angle := -PI * 0.86 + branch * PI * 0.28
		var length := 42.0 + branch % 3 * 20.0
		var endpoint := Vector2(cos(angle) * length, sin(angle) * length * 0.34)
		draw_polyline(PackedVector2Array([Vector2.ZERO, endpoint * 0.52 + Vector2(0.0, branch % 2 * 7.0), endpoint]), Color(0.3, 0.8, 0.92, 0.68 if active else 0.34), 4.0)
	if active:
		for rock_index in range(6):
			var rock_x := -78.0 + rock_index * 31.0
			draw_colored_polygon(PackedVector2Array([Vector2(rock_x - 9.0, 2.0), Vector2(rock_x, -24.0 - rock_index % 2 * 11.0), Vector2(rock_x + 11.0, 2.0)]), Color("#7e734f"))
