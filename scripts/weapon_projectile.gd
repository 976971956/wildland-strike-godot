class_name WeaponProjectile
extends Node2D

const WeaponDefinitionScript = preload("res://core/weapons/weapon_definition.gd")

var game: Node
var source_actor: Node
var target_actor: Node
var target_locked := false
var definition: Resource
var team: StringName
var combat_team: StringName
var combat_owner_id := -1
var damage_scale_snapshot := 1.0
var source_power_scale_snapshot := 1.0
var direction := 1
var velocity := Vector2.ZERO
var lifetime := 0.0
var fuse_timer := 0.0
var exploded := false
var spin := 0.0
var shot_index := 0
var shot_count := 1
var remaining_penetrations := 1
var hit_actor_ids := {}
var arm_timer := 0.0
var lingering_timer := 0.0
var lingering_tick_timer := 0.0
var visual_height := 48.0


func setup(
	p_game: Node,
	p_source_actor: Node,
	p_definition: Resource,
	p_team: StringName,
	p_position: Vector2,
	p_direction: int,
	p_target_actor: Node = null,
	p_shot_index := 0,
	p_shot_count := 1
) -> void:
	game = p_game
	source_actor = p_source_actor
	target_actor = p_target_actor
	target_locked = p_target_actor != null
	definition = p_definition
	team = p_team
	combat_team = source_actor.combat_team if is_instance_valid(source_actor) and "combat_team" in source_actor else p_team
	combat_owner_id = source_actor.combat_owner_id if is_instance_valid(source_actor) and "combat_owner_id" in source_actor else -1
	damage_scale_snapshot = source_actor.damage_scale_snapshot if is_instance_valid(source_actor) and "damage_scale_snapshot" in source_actor else 1.0
	source_power_scale_snapshot = source_actor.source_power_scale_snapshot if is_instance_valid(source_actor) and "source_power_scale_snapshot" in source_actor else 1.0
	position = p_position
	direction = 1 if p_direction >= 0 else -1
	shot_index = p_shot_index
	shot_count = maxi(p_shot_count, 1)
	var spread_fraction := 0.0
	if shot_count > 1:
		spread_fraction = lerpf(-1.0, 1.0, float(shot_index) / float(shot_count - 1))
	velocity = Vector2(direction * definition.projectile_speed, spread_fraction * definition.spread_depth)
	lifetime = definition.projectile_lifetime
	fuse_timer = definition.fuse_duration
	arm_timer = definition.arm_delay
	remaining_penetrations = definition.penetration_count
	z_index = int(position.y) + 4
	add_to_group("weapon_projectiles")
	queue_redraw()


func _physics_process(delta: float) -> void:
	if exploded:
		_tick_lingering(delta)
		return
	lifetime = maxf(0.0, lifetime - delta)
	if not definition.stationary:
		position += velocity * delta
	if definition.kind == WeaponDefinitionScript.WeaponKind.EXPLOSIVE:
		arm_timer = maxf(0.0, arm_timer - delta)
		if not definition.stationary:
			velocity.x = move_toward(velocity.x, 0.0, definition.projectile_deceleration * delta)
			spin += direction * delta * 7.5
		fuse_timer = maxf(0.0, fuse_timer - delta)
		if arm_timer <= 0.0 and definition.trigger_radius > 0.0 and _has_explosive_target(definition.trigger_radius):
			_explode()
			return
		if definition.detonate_on_contact and _has_explosive_target(38.0):
			_explode()
			return
		if fuse_timer <= 0.0 or lifetime <= 0.0:
			_explode()
	else:
		if _resolve_direct_hit() or lifetime <= 0.0:
			queue_free()
	queue_redraw()


func _resolve_direct_hit() -> bool:
	if team == &"enemy":
		if target_locked and not is_instance_valid(target_actor):
			return false
		var resolved_target: Node = target_actor if target_locked else _nearest_active_player()
		if _direct_target_is_available(resolved_target, 34.0):
			_damage_direct_target(resolved_target)
			return _register_penetration(resolved_target)
		return false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not _direct_target_is_available(enemy, 38.0):
			continue
		_damage_direct_target(enemy)
		return _register_penetration(enemy)
	for stage_object in get_tree().get_nodes_in_group("breakables"):
		if not hit_actor_ids.has(stage_object.get_instance_id()) and position.distance_to(stage_object.position) < 38.0:
			var impact_position: Vector2 = stage_object.position - Vector2(0.0, 34.0)
			stage_object.take_stage_hit(definition.damage, direction)
			game.hit_confirm(impact_position, 2, direction, true, definition.impact_profile)
			return _register_penetration(stage_object)
	return false


func _direct_target_is_available(actor: Node, radius: float) -> bool:
	return (
		is_instance_valid(actor)
		and actor != source_actor
		and not actor.is_defeated
		and not hit_actor_ids.has(actor.get_instance_id())
		and _can_damage_actor(actor)
		and position.distance_to(actor.position) < radius
	)


func _damage_direct_target(actor: Node) -> void:
	if actor.is_in_group("player"):
		var resolved_damage := maxi(1, roundi(definition.damage * source_power_scale_snapshot * damage_scale_snapshot))
		actor.take_hit(resolved_damage, Vector2(direction * 250.0, 0.0), false, 0.0, true, definition.impact_profile)
		return
	var health_before: int = actor.health
	var resolved_damage := maxi(1, roundi(definition.damage * source_power_scale_snapshot))
	actor.take_hit(resolved_damage, Vector2(direction * 320.0, 0.0), false, false, 0.0, true)
	if actor.health < health_before:
		game.hit_confirm(actor.position - Vector2(0.0, 48.0), 2, direction, true, definition.impact_profile)


func _register_penetration(actor: Node) -> bool:
	hit_actor_ids[actor.get_instance_id()] = true
	remaining_penetrations -= 1
	return remaining_penetrations <= 0


func _nearest_active_player() -> Node:
	var candidates: Array[Node] = game.get_active_players() if game.has_method("get_active_players") else [game.player]
	var nearest: Node = null
	var nearest_distance := INF
	for fighter in candidates:
		if not is_instance_valid(fighter) or fighter.is_defeated:
			continue
		var distance := position.distance_to(fighter.position)
		if distance < nearest_distance:
			nearest = fighter
			nearest_distance = distance
	return nearest


func _can_damage_actor(actor: Node) -> bool:
	if not is_instance_valid(actor) or actor == source_actor:
		return false
	if not "combat_team" in actor or combat_team.is_empty():
		return true
	return actor.combat_team != combat_team


func _has_explosive_target(radius: float) -> bool:
	for actor in _combat_candidates():
		if is_instance_valid(actor) and not actor.is_defeated and _can_damage_actor(actor) and position.distance_to(actor.position) <= radius:
			return true
	if combat_team == &"players":
		for stage_object in get_tree().get_nodes_in_group("breakables"):
			if position.distance_to(stage_object.position) <= radius:
				return true
	return false


func _explode() -> void:
	if exploded:
		return
	exploded = true
	for actor in _combat_candidates():
		if actor == source_actor or not is_instance_valid(actor) or actor.is_defeated or not _can_damage_actor(actor):
			continue
		if position.distance_to(actor.position) > definition.explosion_radius:
			continue
		_damage_explosion_target(actor, definition.damage, true)
	for stage_object in get_tree().get_nodes_in_group("breakables"):
		if position.distance_to(stage_object.position) <= definition.explosion_radius:
			stage_object.take_stage_hit(definition.damage, direction)
	game.hit_confirm(position - Vector2(0.0, 24.0), 3, direction, true, definition.impact_profile)
	game.play_sfx(definition.blast_sfx)
	if definition.lingering_duration > 0.0:
		lingering_timer = definition.lingering_duration
		lingering_tick_timer = definition.lingering_tick_interval
		velocity = Vector2.ZERO
		queue_redraw()
	else:
		queue_free()


func _damage_explosion_target(actor: Node, amount: int, launch: bool) -> void:
	var blast_direction := 1 if actor.position.x >= position.x else -1
	if actor.is_in_group("player"):
		var resolved_damage := maxi(1, roundi(amount * source_power_scale_snapshot * damage_scale_snapshot))
		actor.take_hit(resolved_damage, Vector2(blast_direction * 360.0, -35.0), false, 0.0, true, definition.impact_profile)
	else:
		var resolved_damage := maxi(1, roundi(amount * source_power_scale_snapshot))
		actor.take_hit(resolved_damage, Vector2(blast_direction * 430.0, -65.0 if launch else 0.0), launch, false, 0.0, true)


func _tick_lingering(delta: float) -> void:
	if lingering_timer <= 0.0:
		queue_free()
		return
	lingering_timer = maxf(0.0, lingering_timer - delta)
	lingering_tick_timer = maxf(0.0, lingering_tick_timer - delta)
	if lingering_tick_timer > 0.0:
		queue_redraw()
		return
	lingering_tick_timer = definition.lingering_tick_interval
	for actor in _combat_candidates():
		if actor == source_actor or not is_instance_valid(actor) or actor.is_defeated or not _can_damage_actor(actor):
			continue
		if position.distance_to(actor.position) <= definition.explosion_radius:
			_damage_explosion_target(actor, definition.lingering_damage, false)
	queue_redraw()


func _combat_candidates() -> Array[Node]:
	var candidates: Array[Node] = []
	if game.has_method("get_active_players"):
		for fighter in game.get_active_players():
			candidates.append(fighter)
	elif is_instance_valid(game.player):
		candidates.append(game.player)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		candidates.append(enemy)
	return candidates


func _draw() -> void:
	if definition == null:
		return
	var draw_offset := Vector2(0.0, -visual_height)
	if exploded and lingering_timer > 0.0:
		var pulse := 0.85 + sin(lingering_timer * 13.0) * 0.15
		draw_circle(Vector2(0.0, -8.0), definition.explosion_radius * 0.34, Color(1.0, 0.24, 0.04, 0.18))
		for flame_x in [-24.0, 0.0, 24.0]:
			draw_circle(Vector2(flame_x, -18.0 - absf(flame_x) * 0.15), 10.0 * pulse, Color(1.0, 0.48, 0.08, 0.82))
		return
	if definition.kind == WeaponDefinitionScript.WeaponKind.FIREARM:
		var tracer_width := 7.0 if definition.penetration_count > 1 else 5.0
		draw_line(draw_offset + Vector2(-direction * 14.0, 0.0), draw_offset + Vector2(direction * 10.0, 0.0), definition.color.lightened(0.2), tracer_width)
		draw_circle(draw_offset + Vector2(direction * 12.0, 0.0), 4.0, Color.WHITE)
	elif definition.stationary:
		draw_rect(Rect2(-17.0, -15.0, 34.0, 12.0), definition.color)
		draw_circle(Vector2.ZERO, 5.0, Color("#ff5a3c") if arm_timer <= 0.0 else Color("#ffe07a"))
	elif definition.detonate_on_contact:
		draw_set_transform(draw_offset, 0.0, Vector2.ONE)
		draw_rect(Rect2(-18.0, -6.0, 36.0, 12.0), definition.color)
		draw_colored_polygon(PackedVector2Array([Vector2(-18.0, -8.0), Vector2(-29.0, 0.0), Vector2(-18.0, 8.0)]), Color("#ffb347"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_set_transform(draw_offset, spin, Vector2.ONE)
		draw_circle(Vector2.ZERO, 10.0, definition.color)
		draw_rect(Rect2(-3.0, -15.0, 6.0, 7.0), Color("#d1b36f"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
