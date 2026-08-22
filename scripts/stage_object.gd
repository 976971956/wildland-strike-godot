class_name StageObject
extends Node2D

const HurtboxScript = preload("res://core/combat/combat_hurtbox.gd")
const EnvironmentObjectDataScript = preload("res://core/stages/environment_object_data.gd")
const MEDIUM_IMPACT = preload("res://data/impacts/medium.tres")

var game: Node
var definition: Resource
var health := 1
var direction := 1
var contact_cooldown := 0.0
var roll_angle := 0.0
var flash_timer := 0.0
var is_defeated := false
var hurtbox
var carrier: Node
var carried := false
var thrown := false
var throw_owner: Node
var throw_velocity := Vector2.ZERO
var throw_timer := 0.0
var throw_spin := 0.0
var throw_damage_snapshot := 0


func setup(p_game: Node, p_definition: Resource) -> void:
	game = p_game
	definition = p_definition
	position = definition.position
	health = definition.health
	direction = definition.initial_direction
	z_index = int(position.y)
	if definition.kind in [EnvironmentObjectDataScript.ObjectKind.BREAKABLE, EnvironmentObjectDataScript.ObjectKind.CARRYABLE]:
		_register_breakable_groups()
		hurtbox = HurtboxScript.new()
		add_child(hurtbox)
		hurtbox.setup(self, definition.size * 0.45)
	else:
		add_to_group("stage_hazards")
		if definition.kind == EnvironmentObjectDataScript.ObjectKind.ROAD_HAZARD:
			add_to_group("road_hazards")
	add_to_group("stage_objects")
	queue_redraw()


func _physics_process(delta: float) -> void:
	flash_timer = maxf(0.0, flash_timer - delta)
	if carried:
		if not is_instance_valid(carrier) or carrier.is_defeated:
			drop_from_carrier()
		else:
			position = carrier.position + Vector2(0.0, -118.0 - carrier.z_height)
			z_index = int(carrier.position.y) + 8
			queue_redraw()
			return
	if thrown:
		throw_timer = maxf(0.0, throw_timer - delta)
		position += throw_velocity * delta
		throw_spin += signf(throw_velocity.x) * delta * 9.0
		z_index = int(position.y) + 9
		if _resolve_thrown_contact():
			return
		if throw_timer <= 0.0:
			_land_from_throw()
		queue_redraw()
		return
	if definition.kind == EnvironmentObjectDataScript.ObjectKind.WATER_CURRENT:
		contact_cooldown = maxf(0.0, contact_cooldown - delta)
		roll_angle += delta * 4.0
		_resolve_water_current(delta)
		queue_redraw()
		return
	if definition.kind == EnvironmentObjectDataScript.ObjectKind.ROAD_HAZARD:
		queue_redraw()
		return
	if definition.kind != EnvironmentObjectDataScript.ObjectKind.ROLLING_HAZARD:
		queue_redraw()
		return
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	position.x += direction * definition.move_speed * delta
	if position.x <= definition.move_min_x or position.x >= definition.move_max_x:
		position.x = clampf(position.x, definition.move_min_x, definition.move_max_x)
		direction *= -1
	roll_angle += direction * definition.move_speed * delta / maxf(definition.size.x * 0.5, 1.0)
	z_index = int(position.y)
	_resolve_hazard_contact()
	queue_redraw()


func take_stage_hit(amount: int, _impact_direction: int) -> bool:
	if is_defeated or carried or thrown or definition.kind not in [EnvironmentObjectDataScript.ObjectKind.BREAKABLE, EnvironmentObjectDataScript.ObjectKind.CARRYABLE]:
		return false
	health -= amount
	flash_timer = 0.1
	if health <= 0:
		_destroy_object()
	queue_redraw()
	return true


func impact_by_vehicle(amount: int, impact_direction: int) -> bool:
	if is_defeated or definition.kind != EnvironmentObjectDataScript.ObjectKind.ROAD_HAZARD:
		return false
	health -= amount
	flash_timer = 0.12
	if health <= 0:
		_destroy_object()
	else:
		position.x += impact_direction * 34.0
	queue_redraw()
	return true


func pick_up_by(fighter: Node) -> bool:
	if definition.kind != EnvironmentObjectDataScript.ObjectKind.CARRYABLE or is_defeated or carried or thrown or not is_instance_valid(fighter):
		return false
	carrier = fighter
	carried = true
	throw_owner = null
	throw_velocity = Vector2.ZERO
	_unregister_breakable_groups()
	if hurtbox != null:
		hurtbox.enabled = false
	game.play_sfx(&"pickup")
	queue_redraw()
	return true


func drop_from_carrier() -> void:
	if not carried:
		return
	var previous_carrier := carrier
	carried = false
	carrier = null
	if is_instance_valid(previous_carrier):
		position = previous_carrier.position + Vector2(previous_carrier.facing * 42.0, 0.0)
	_register_breakable_groups()
	if hurtbox != null:
		hurtbox.enabled = true
	z_index = int(position.y)
	queue_redraw()


func throw_from(fighter: Node, throw_direction: int) -> bool:
	if not carried or fighter != carrier:
		return false
	carried = false
	carrier = null
	thrown = true
	throw_owner = fighter
	# Keep the collision origin on the beat-em-up floor plane. The prop artwork
	# itself is drawn above this origin while it travels.
	position = fighter.position + Vector2(throw_direction * 46.0, 0.0)
	throw_velocity = Vector2(throw_direction * definition.throw_speed, 0.0)
	throw_timer = definition.throw_lifetime
	throw_damage_snapshot = maxi(1, roundi(definition.throw_damage * fighter.damage_scale * fighter.grapple_power))
	_unregister_breakable_groups()
	if hurtbox != null:
		hurtbox.enabled = false
	game.play_sfx(&"prop_throw")
	queue_redraw()
	return true


func _resolve_thrown_contact() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_defeated or enemy == throw_owner or not _overlaps_actor(enemy):
			continue
		var impact_direction := 1 if throw_velocity.x >= 0.0 else -1
		var health_before: int = enemy.health
		enemy.take_hit(throw_damage_snapshot, Vector2(impact_direction * 460.0, -62.0), true, false, 0.0, true)
		if enemy.health < health_before:
			game.hit_confirm(enemy.position - Vector2(0.0, 48.0), 3, impact_direction, true, MEDIUM_IMPACT)
			_finish_throw_impact()
			return true
	for stage_object in get_tree().get_nodes_in_group("breakables"):
		if stage_object == self or not is_instance_valid(stage_object) or stage_object.is_defeated or not _overlaps_actor(stage_object):
			continue
		var impact_direction := 1 if throw_velocity.x >= 0.0 else -1
		stage_object.take_stage_hit(throw_damage_snapshot, impact_direction)
		game.hit_confirm(stage_object.position - Vector2(0.0, 34.0), 3, impact_direction, true, MEDIUM_IMPACT)
		_finish_throw_impact()
		return true
	return false


func _finish_throw_impact() -> void:
	if definition.break_on_throw_hit:
		_destroy_object()
	else:
		_land_from_throw()


func _land_from_throw() -> void:
	thrown = false
	throw_owner = null
	throw_velocity = Vector2.ZERO
	throw_timer = 0.0
	position.y = clampf(position.y, 475.0, 645.0)
	_register_breakable_groups()
	if hurtbox != null:
		hurtbox.enabled = true
	z_index = int(position.y)
	queue_redraw()


func _destroy_object() -> void:
	if is_defeated:
		return
	is_defeated = true
	carried = false
	thrown = false
	carrier = null
	_unregister_breakable_groups()
	game.add_score(definition.defeat_score)
	if not definition.drop_id.is_empty():
		game.spawn_pickup(position, definition.drop_id)
	game.play_sfx(&"prop_break")
	queue_free()


func _register_breakable_groups() -> void:
	if not is_in_group("breakables"):
		add_to_group("breakables")
	if definition.kind == EnvironmentObjectDataScript.ObjectKind.CARRYABLE and not is_in_group("carryables"):
		add_to_group("carryables")


func _unregister_breakable_groups() -> void:
	remove_from_group("breakables")
	remove_from_group("carryables")


func _resolve_hazard_contact() -> void:
	if contact_cooldown > 0.0:
		return
	var local_players: Array[Node] = game.get_active_players() if game.has_method("get_active_players") else [game.player]
	for fighter in local_players:
		if not is_instance_valid(fighter) or fighter.is_defeated or not _overlaps_actor(fighter):
			continue
		fighter.take_hit(
			definition.contact_damage,
			Vector2(direction * 290.0, -35.0),
			false,
			0.0,
			true,
			MEDIUM_IMPACT
		)
		contact_cooldown = 0.68
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_defeated or not _overlaps_actor(enemy):
			continue
		var health_before: int = enemy.health
		enemy.take_hit(
			definition.contact_damage,
			Vector2(direction * 330.0, -45.0),
			true,
			false,
			0.0,
			true
		)
		if enemy.health < health_before:
			game.hit_confirm(enemy.position - Vector2(0.0, 48.0), 2, direction, true, MEDIUM_IMPACT)
			contact_cooldown = 0.68
		return


func _resolve_water_current(delta: float) -> void:
	var actors_in_current: Array[Node] = []
	actors_in_current.append_array(game.get_active_players() if game.has_method("get_active_players") else [game.player])
	actors_in_current.append_array(get_tree().get_nodes_in_group("enemies"))
	for actor in actors_in_current:
		if not is_instance_valid(actor) or actor.is_defeated or not _overlaps_actor(actor):
			continue
		actor.position.x += definition.initial_direction * definition.move_speed * delta
		actor.position.y += sin(roll_angle + actor.get_instance_id()) * 4.0 * delta
		if contact_cooldown > 0.0:
			continue
		if actor.is_in_group("player"):
			actor.take_hit(definition.contact_damage, Vector2(definition.initial_direction * 150.0, 0.0), false, 0.0, false, MEDIUM_IMPACT)
		else:
			actor.take_hit(definition.contact_damage, Vector2(definition.initial_direction * 180.0, 0.0), false, false, 0.0, false)
		contact_cooldown = 1.15
		game.play_sfx(&"water_surge")


func _overlaps_actor(actor: Node) -> bool:
	return (
		absf(actor.position.x - position.x) < definition.size.x * 0.5 + 18.0
		and absf(actor.position.y - position.y) < definition.size.y * 0.38 + 18.0
	)


func _draw() -> void:
	if definition.kind == EnvironmentObjectDataScript.ObjectKind.ROLLING_HAZARD:
		_draw_hazard()
	elif definition.kind == EnvironmentObjectDataScript.ObjectKind.WATER_CURRENT:
		_draw_water_current()
	elif definition.kind == EnvironmentObjectDataScript.ObjectKind.ROAD_HAZARD:
		_draw_road_hazard()
	elif definition.kind == EnvironmentObjectDataScript.ObjectKind.CARRYABLE:
		_draw_carryable()
	else:
		_draw_breakable()


func _draw_breakable() -> void:
	var half: Vector2 = definition.size * 0.5
	_draw_oval(Vector2(0.0, 5.0), half.x * 0.8, 8.0, Color(0.02, 0.03, 0.04, 0.4))
	var body_color := Color("#f0c06a") if flash_timer > 0.0 else Color("#8a5735")
	draw_rect(Rect2(-half.x, -definition.size.y, definition.size.x, definition.size.y), body_color)
	draw_rect(Rect2(-half.x + 5.0, -definition.size.y + 5.0, definition.size.x - 10.0, definition.size.y - 10.0), Color("#5e3b2b"), false, 5.0)
	draw_line(Vector2(-half.x + 7.0, -definition.size.y + 7.0), Vector2(half.x - 7.0, -7.0), Color("#c78a4e"), 6.0)
	draw_line(Vector2(half.x - 7.0, -definition.size.y + 7.0), Vector2(-half.x + 7.0, -7.0), Color("#c78a4e"), 6.0)


func _draw_road_hazard() -> void:
	var half: Vector2 = definition.size * 0.5
	_draw_oval(Vector2(0.0, 7.0), half.x, 9.0, Color(0.02, 0.03, 0.04, 0.45))
	var hazard_color: Color = Color.WHITE if flash_timer > 0.0 else definition.color
	if "oil" in String(definition.object_id):
		_draw_oval(Vector2.ZERO, half.x, half.y * 0.35, Color(0.04, 0.05, 0.05, 0.78))
		for index in range(3):
			draw_circle(Vector2(-half.x * 0.55 + index * half.x * 0.55, -4.0 - index % 2 * 4.0), 5.0, Color(0.18, 0.2, 0.17, 0.68))
		return
	draw_rect(Rect2(-half.x, -definition.size.y, definition.size.x, definition.size.y), hazard_color)
	for index in range(4):
		var stripe_x: float = -half.x + index * definition.size.x * 0.25
		draw_colored_polygon(PackedVector2Array([
			Vector2(stripe_x, -definition.size.y),
			Vector2(stripe_x + definition.size.x * 0.12, -definition.size.y),
			Vector2(stripe_x + definition.size.x * 0.25, 0.0),
			Vector2(stripe_x + definition.size.x * 0.13, 0.0),
		]), Color("#f2c43d"))
	draw_rect(Rect2(-half.x, -definition.size.y, definition.size.x, definition.size.y), Color("#3b3126"), false, 4.0)


func _draw_hazard() -> void:
	var radius: float = definition.size.x * 0.5
	_draw_oval(Vector2(0.0, 7.0), radius, 8.0, Color(0.02, 0.03, 0.04, 0.42))
	draw_set_transform(Vector2(0.0, -radius), roll_angle, Vector2.ONE)
	draw_circle(Vector2.ZERO, radius, Color("#9b3e2f"))
	draw_arc(Vector2.ZERO, radius - 4.0, 0.0, TAU, 28, Color("#e27b43"), 5.0)
	draw_line(Vector2(-radius + 4.0, 0.0), Vector2(radius - 4.0, 0.0), Color("#4a2525"), 6.0)
	draw_line(Vector2(0.0, -radius + 4.0), Vector2(0.0, radius - 4.0), Color("#4a2525"), 6.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_carryable() -> void:
	var half: Vector2 = definition.size * 0.5
	_draw_oval(Vector2(0.0, 5.0), half.x * 0.8, 7.0, Color(0.02, 0.03, 0.04, 0.4))
	draw_set_transform(Vector2(0.0, -half.y), throw_spin if thrown else 0.0, Vector2.ONE)
	if "tire" in String(definition.object_id):
		draw_circle(Vector2.ZERO, half.x, Color("#202429"))
		draw_arc(Vector2.ZERO, half.x - 4.0, 0.0, TAU, 28, definition.color, 6.0)
		draw_circle(Vector2.ZERO, half.x * 0.38, Color("#0a0d10"))
	elif "canister" in String(definition.object_id):
		draw_rect(Rect2(-half.x, -half.y, definition.size.x, definition.size.y), definition.color)
		draw_rect(Rect2(-half.x + 5.0, -half.y + 5.0, definition.size.x - 10.0, definition.size.y - 10.0), definition.color.lightened(0.25), false, 4.0)
		draw_line(Vector2(-half.x, 0.0), Vector2(half.x, 0.0), Color("#f2c85b"), 5.0)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-half.x, half.y * 0.6), Vector2(-half.x * 0.55, -half.y), Vector2(half.x * 0.65, -half.y * 0.75), Vector2(half.x, half.y)]), definition.color)
		draw_line(Vector2(-half.x * 0.6, -half.y * 0.65), Vector2(half.x * 0.65, half.y * 0.55), definition.color.lightened(0.3), 5.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_water_current() -> void:
	var half: Vector2 = definition.size * 0.5
	draw_rect(Rect2(-half.x, -half.y, definition.size.x, definition.size.y), Color(0.08, 0.45, 0.56, 0.16))
	var flow := fmod(roll_angle * 20.0, 72.0)
	for index in range(6):
		var x: float = -half.x + fmod(index * 74.0 + flow, definition.size.x)
		draw_line(Vector2(x, -half.y * 0.45), Vector2(x + definition.initial_direction * 34.0, half.y * 0.35), Color(0.58, 0.9, 0.94, 0.36), 3.0)


func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(25):
		var angle := TAU * index / 24.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
