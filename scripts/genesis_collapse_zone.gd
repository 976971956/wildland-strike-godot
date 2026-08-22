class_name GenesisCollapseZone
extends Node2D

const MEDIUM_IMPACT = preload("res://data/impacts/medium.tres")

var game: Node
var source_actor: Node
var damage := 22
var warning_timer := 0.6
var active_timer := 0.22
var linger_timer := 0.34
var active := false
var resolved := false
var visual_clock := 0.0
var hit_actor_ids := {}


func setup(p_game: Node, p_source_actor: Node, p_position: Vector2, p_damage: int) -> void:
	game = p_game
	source_actor = p_source_actor
	position = p_position
	damage = maxi(1, p_damage)
	z_index = int(position.y) + 8
	add_to_group("stage_effects")
	add_to_group("genesis_collapse_zones")
	queue_redraw()


func _physics_process(delta: float) -> void:
	visual_clock += delta
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
	fighter.take_hit(damage, Vector2(direction * 320.0, -126.0), false, 0.09, true, MEDIUM_IMPACT)
	if fighter.health < health_before:
		hit_actor_ids[fighter.get_instance_id()] = true


func _try_hit_enemy(target: Node) -> void:
	if not _can_hit(target):
		return
	var health_before: int = target.health
	var direction := 1 if target.position.x >= position.x else -1
	target.take_hit(damage, Vector2(direction * 320.0, -126.0), true, false, 0.09, true)
	if target.health < health_before:
		hit_actor_ids[target.get_instance_id()] = true


func _can_hit(actor: Node) -> bool:
	return (
		is_instance_valid(actor)
		and not actor.is_defeated
		and not hit_actor_ids.has(actor.get_instance_id())
		and absf(actor.position.x - position.x) <= 118.0
		and absf(actor.position.y - position.y) <= 62.0
	)


func _draw() -> void:
	var pulse := 0.62 + sin(visual_clock * 19.0) * 0.17
	var alpha := 0.88 if active else (pulse if warning_timer > 0.0 else 0.24)
	for ring_index in range(3):
		var ring_radius := 42.0 + ring_index * 34.0
		var ring_color := Color(0.28, 1.0, 0.64, alpha) if ring_index % 2 == 0 else Color(1.0, 0.18, 0.72, alpha)
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 32, ring_color, 5.0 if active else 3.0)
	for shard_index in range(8):
		var angle := TAU * shard_index / 8.0 + visual_clock * 0.8
		var origin := Vector2(cos(angle) * 58.0, sin(angle) * 24.0)
		var tip := origin + Vector2(cos(angle) * 28.0, sin(angle) * 14.0)
		draw_line(origin, tip, Color(1.0, 0.78, 0.32, alpha), 4.0)
	if active:
		draw_circle(Vector2.ZERO, 32.0, Color(1.0, 1.0, 1.0, 0.34))
