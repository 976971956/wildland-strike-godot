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
var direction := 1
var velocity := Vector2.ZERO
var lifetime := 0.0
var fuse_timer := 0.0
var exploded := false
var spin := 0.0


func setup(
	p_game: Node,
	p_source_actor: Node,
	p_definition: Resource,
	p_team: StringName,
	p_position: Vector2,
	p_direction: int,
	p_target_actor: Node = null
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
	position = p_position
	direction = 1 if p_direction >= 0 else -1
	velocity = Vector2(direction * definition.projectile_speed, 0.0)
	lifetime = definition.projectile_lifetime
	fuse_timer = definition.fuse_duration
	z_index = int(position.y) + 4
	add_to_group("weapon_projectiles")
	queue_redraw()


func _physics_process(delta: float) -> void:
	if exploded:
		return
	lifetime = maxf(0.0, lifetime - delta)
	position += velocity * delta
	if definition.kind == WeaponDefinitionScript.WeaponKind.EXPLOSIVE:
		velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta)
		spin += direction * delta * 7.5
		fuse_timer = maxf(0.0, fuse_timer - delta)
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
		if is_instance_valid(resolved_target) and not resolved_target.is_defeated and _can_damage_actor(resolved_target) and position.distance_to(resolved_target.position) < 34.0:
			if resolved_target.is_in_group("player"):
				var resolved_damage: int = definition.damage
				resolved_damage = maxi(1, roundi(resolved_damage * damage_scale_snapshot))
				resolved_target.take_hit(
					resolved_damage,
					Vector2(direction * 250.0, 0.0),
					false,
					0.0,
					true,
					definition.impact_profile
				)
			else:
				var health_before: int = resolved_target.health
				resolved_target.take_hit(
					definition.damage,
					Vector2(direction * 250.0, 0.0),
					false,
					false,
					0.0,
					true
				)
				if resolved_target.health < health_before:
					game.hit_confirm(
						resolved_target.position - Vector2(0.0, 48.0),
						2,
						direction,
						true,
						definition.impact_profile
					)
			return true
		return false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == source_actor or not is_instance_valid(enemy) or enemy.is_defeated or not _can_damage_actor(enemy):
			continue
		if position.distance_to(enemy.position) >= 38.0:
			continue
		var health_before: int = enemy.health
		enemy.take_hit(definition.damage, Vector2(direction * 320.0, 0.0), false, false, 0.0, true)
		if enemy.health < health_before:
			game.hit_confirm(enemy.position - Vector2(0.0, 48.0), 2, direction, true, definition.impact_profile)
		return true
	for stage_object in get_tree().get_nodes_in_group("breakables"):
		if position.distance_to(stage_object.position) < 38.0:
			var impact_position: Vector2 = stage_object.position - Vector2(0.0, 34.0)
			stage_object.take_stage_hit(definition.damage, direction)
			game.hit_confirm(impact_position, 2, direction, true, definition.impact_profile)
			return true
	return false


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


func _explode() -> void:
	if exploded:
		return
	exploded = true
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == source_actor or not is_instance_valid(enemy) or enemy.is_defeated or not _can_damage_actor(enemy):
			continue
		if position.distance_to(enemy.position) > definition.explosion_radius:
			continue
		var blast_direction := 1 if enemy.position.x >= position.x else -1
		enemy.take_hit(definition.damage, Vector2(blast_direction * 430.0, -65.0), true, false, 0.0, true)
	for stage_object in get_tree().get_nodes_in_group("breakables"):
		if position.distance_to(stage_object.position) <= definition.explosion_radius:
			stage_object.take_stage_hit(definition.damage, direction)
	game.hit_confirm(position - Vector2(0.0, 24.0), 3, direction, true, definition.impact_profile)
	game.play_sfx("explosion")
	queue_free()


func _draw() -> void:
	if definition == null:
		return
	var draw_offset := Vector2(0.0, -48.0)
	if definition.kind == WeaponDefinitionScript.WeaponKind.FIREARM:
		draw_line(draw_offset + Vector2(-direction * 14.0, 0.0), draw_offset + Vector2(direction * 10.0, 0.0), Color("#ffe28a"), 5.0)
		draw_circle(draw_offset + Vector2(direction * 12.0, 0.0), 4.0, Color.WHITE)
	else:
		draw_set_transform(draw_offset, spin, Vector2.ONE)
		draw_circle(Vector2.ZERO, 10.0, definition.color)
		draw_rect(Rect2(-3.0, -15.0, 6.0, 7.0), Color("#d1b36f"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
