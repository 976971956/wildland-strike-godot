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


func setup(p_game: Node, p_definition: Resource) -> void:
	game = p_game
	definition = p_definition
	position = definition.position
	health = definition.health
	direction = definition.initial_direction
	z_index = int(position.y)
	if definition.kind == EnvironmentObjectDataScript.ObjectKind.BREAKABLE:
		add_to_group("breakables")
		hurtbox = HurtboxScript.new()
		add_child(hurtbox)
		hurtbox.setup(self, definition.size * 0.45)
	else:
		add_to_group("stage_hazards")
	queue_redraw()


func _physics_process(delta: float) -> void:
	flash_timer = maxf(0.0, flash_timer - delta)
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
	if is_defeated or definition.kind != EnvironmentObjectDataScript.ObjectKind.BREAKABLE:
		return false
	health -= amount
	flash_timer = 0.1
	if health <= 0:
		is_defeated = true
		remove_from_group("breakables")
		game.add_score(definition.defeat_score)
		if not definition.drop_id.is_empty():
			game.spawn_pickup(position, definition.drop_id)
		queue_free()
	queue_redraw()
	return true


func _resolve_hazard_contact() -> void:
	if contact_cooldown > 0.0:
		return
	if is_instance_valid(game.player) and not game.player.is_defeated and _overlaps_actor(game.player):
		game.player.take_hit(
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


func _overlaps_actor(actor: Node) -> bool:
	return (
		absf(actor.position.x - position.x) < definition.size.x * 0.5 + 18.0
		and absf(actor.position.y - position.y) < definition.size.y * 0.38 + 18.0
	)


func _draw() -> void:
	if definition.kind == EnvironmentObjectDataScript.ObjectKind.ROLLING_HAZARD:
		_draw_hazard()
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


func _draw_hazard() -> void:
	var radius: float = definition.size.x * 0.5
	_draw_oval(Vector2(0.0, 7.0), radius, 8.0, Color(0.02, 0.03, 0.04, 0.42))
	draw_set_transform(Vector2(0.0, -radius), roll_angle, Vector2.ONE)
	draw_circle(Vector2.ZERO, radius, Color("#9b3e2f"))
	draw_arc(Vector2.ZERO, radius - 4.0, 0.0, TAU, 28, Color("#e27b43"), 5.0)
	draw_line(Vector2(-radius + 4.0, 0.0), Vector2(radius - 4.0, 0.0), Color("#4a2525"), 6.0)
	draw_line(Vector2(0.0, -radius + 4.0), Vector2(0.0, radius - 4.0), Color("#4a2525"), 6.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(25):
		var angle := TAU * index / 24.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
