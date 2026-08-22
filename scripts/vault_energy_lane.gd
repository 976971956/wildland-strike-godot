class_name VaultEnergyLane
extends Node2D

const MEDIUM_IMPACT = preload("res://data/impacts/medium.tres")

var game: Node
var source_actor: Node
var damage := 17
var warning_timer := 0.52
var active_timer := 0.2
var linger_timer := 0.24
var lane_half_width := 210.0
var lane_half_height := 34.0
var active := false
var resolved := false
var visual_clock := 0.0
var hit_actor_ids := {}
var energy_color := Color(0.28, 0.92, 1.0, 1.0)


func setup(p_game: Node, p_source_actor: Node, p_position: Vector2, p_damage: int, p_color: Color) -> void:
	game = p_game
	source_actor = p_source_actor
	position = p_position
	damage = maxi(1, p_damage)
	energy_color = p_color
	z_index = int(position.y) + 7
	add_to_group("stage_effects")
	add_to_group("vault_energy_lanes")
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
	game.play_sfx(&"industrial_impact")


func _try_hit_player(fighter: Node) -> void:
	if not _can_hit(fighter):
		return
	var health_before: int = fighter.health
	var direction := 1 if fighter.position.x >= position.x else -1
	fighter.take_hit(damage, Vector2(direction * 300.0, -72.0), false, 0.06, true, MEDIUM_IMPACT)
	if fighter.health < health_before:
		hit_actor_ids[fighter.get_instance_id()] = true


func _try_hit_enemy(target: Node) -> void:
	if not _can_hit(target):
		return
	var health_before: int = target.health
	var direction := 1 if target.position.x >= position.x else -1
	target.take_hit(damage, Vector2(direction * 300.0, -72.0), true, false, 0.06, true)
	if target.health < health_before:
		hit_actor_ids[target.get_instance_id()] = true


func _can_hit(actor: Node) -> bool:
	return (
		is_instance_valid(actor)
		and not actor.is_defeated
		and not hit_actor_ids.has(actor.get_instance_id())
		and absf(actor.position.x - position.x) <= lane_half_width
		and absf(actor.position.y - position.y) <= lane_half_height
	)


func _draw() -> void:
	var pulse := 0.62 + sin(visual_clock * 20.0) * 0.16
	var alpha := 0.82 if active else (pulse if warning_timer > 0.0 else 0.22)
	draw_rect(Rect2(-lane_half_width, -lane_half_height, lane_half_width * 2.0, lane_half_height * 2.0), Color(energy_color.r, energy_color.g, energy_color.b, alpha * (0.34 if active else 0.12)))
	for offset in [-18.0, 0.0, 18.0]:
		draw_line(Vector2(-lane_half_width, offset), Vector2(lane_half_width, offset), Color(energy_color.r, energy_color.g, energy_color.b, alpha), 5.0 if active else 3.0)
	for index in range(7):
		var marker_x := -lane_half_width + 28.0 + index * (lane_half_width * 2.0 - 56.0) / 6.0
		draw_polyline(PackedVector2Array([Vector2(marker_x - 8.0, -lane_half_height), Vector2(marker_x, -lane_half_height + 9.0), Vector2(marker_x + 8.0, -lane_half_height)]), Color(1.0, 0.82, 0.28, alpha), 3.0)
