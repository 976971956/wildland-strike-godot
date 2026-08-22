class_name HighwayVehicle
extends Node2D

const HEAVY_IMPACT = preload("res://data/impacts/heavy.tres")
const INTERCEPTOR_SHEET: Texture2D = preload("res://assets/sprites/desert_interceptor_sheet.png")
const INTERCEPTOR_CELL_SIZE := Vector2(360.0, 240.0)

var game: Node
var definition: Resource
var speed := 0.0
var hull_health := 1
var lane_index := 1
var target_lane_y := 560.0
var ram_cooldown := 0.0
var hazard_cooldown := 0.0
var attack_cooldowns := {}
var shot_count := 0
var ram_count := 0
var hazard_hit_count := 0
var drive_time := 0.0
var disabled_timer := 0.0
var last_drive_event: StringName = &"mounted"
var event_history: Array[StringName] = []


func setup(p_game: Node, p_definition: Resource) -> void:
	game = p_game
	definition = p_definition
	position = Vector2(definition.start_x, definition.lane_positions[definition.lane_positions.size() / 2])
	lane_index = definition.lane_positions.size() / 2
	target_lane_y = definition.lane_positions[lane_index]
	speed = definition.minimum_speed
	hull_health = definition.hull_health
	add_to_group("player_vehicle")
	z_index = int(position.y) - 4
	_record_event(&"mounted")
	_mount_players()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if game == null or definition == null or game.state != "playing":
		return
	drive_time += delta
	ram_cooldown = maxf(0.0, ram_cooldown - delta)
	hazard_cooldown = maxf(0.0, hazard_cooldown - delta)
	disabled_timer = maxf(0.0, disabled_timer - delta)
	for slot_index in attack_cooldowns.keys().duplicate():
		attack_cooldowns[slot_index] = maxf(0.0, float(attack_cooldowns[slot_index]) - delta)
	var intents := _sample_player_intents()
	var primary_intent = intents.get(0)
	if primary_intent != null:
		_apply_drive_intent(primary_intent.move, delta)
	for slot_index in intents:
		var intent = intents[slot_index]
		if intent.attack_pressed or intent.special_pressed:
			_fire_mounted_weapon(int(slot_index))
	if disabled_timer <= 0.0:
		var progression_limit: float = minf(definition.end_x, game.stage_limit - 40.0)
		position.x = minf(position.x + speed * delta, progression_limit)
	position.y = move_toward(position.y, target_lane_y, definition.lane_steering_speed * delta)
	z_index = int(position.y) - 4
	_mount_players()
	_resolve_contacts()
	queue_redraw()


func apply_drive_input(move: Vector2, delta: float) -> void:
	_apply_drive_intent(move.limit_length(1.0), delta)


func request_mounted_attack(slot_index: int) -> bool:
	return _fire_mounted_weapon(slot_index)


func apply_external_collision(amount: int) -> void:
	if hazard_cooldown <= 0.0:
		_take_collision(maxi(amount, 1))


func _sample_player_intents() -> Dictionary:
	var result := {}
	for fighter in game.get_active_players():
		if fighter.input_source != null and fighter.input_source.has_method("sample_intent"):
			result[fighter.local_slot_index] = fighter.input_source.sample_intent()
	return result


func _apply_drive_intent(move: Vector2, delta: float) -> void:
	if disabled_timer > 0.0:
		speed = move_toward(speed, definition.minimum_speed, definition.braking * delta)
		return
	if move.x > 0.1:
		speed = move_toward(speed, definition.maximum_speed, definition.acceleration * move.x * delta)
		_record_event(&"accelerating")
	elif move.x < -0.1:
		speed = move_toward(speed, definition.minimum_speed, definition.braking * -move.x * delta)
		_record_event(&"braking")
	else:
		speed = move_toward(speed, definition.minimum_speed, definition.passive_drag * delta)
	if absf(move.y) > 0.55 and absf(position.y - target_lane_y) <= 8.0:
		var next_lane := clampi(lane_index + (1 if move.y > 0.0 else -1), 0, definition.lane_positions.size() - 1)
		if next_lane != lane_index:
			lane_index = next_lane
			target_lane_y = definition.lane_positions[lane_index]
			_record_event(&"lane_changed")


func _fire_mounted_weapon(slot_index: int) -> bool:
	if float(attack_cooldowns.get(slot_index, 0.0)) > 0.0:
		return false
	var fighter: Node = game.player_for_slot(slot_index)
	if not is_instance_valid(fighter) or fighter.is_defeated:
		return false
	attack_cooldowns[slot_index] = definition.mounted_attack_cooldown
	var muzzle := position + _seat_offset(slot_index) + Vector2(74.0, -72.0)
	var target := _nearest_enemy_ahead(muzzle)
	for shot_index in range(definition.mounted_weapon.shots_per_use):
		game.spawn_weapon_projectile(
			fighter,
			definition.mounted_weapon,
			&"players",
			muzzle,
			1,
			target,
			shot_index,
			definition.mounted_weapon.shots_per_use
		)
	shot_count += 1
	game.play_sfx(definition.mounted_weapon.fire_sfx)
	_record_event(&"mounted_fire")
	return true


func _nearest_enemy_ahead(origin: Vector2) -> Node:
	var best: Node = null
	var best_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_defeated or enemy.position.x < origin.x - 40.0:
			continue
		var distance := origin.distance_to(enemy.position)
		if distance < best_distance:
			best = enemy
			best_distance = distance
	return best


func _resolve_contacts() -> void:
	if hazard_cooldown <= 0.0:
		for hazard in get_tree().get_nodes_in_group("road_hazards"):
			if not is_instance_valid(hazard) or not _overlaps_position(hazard.position, hazard.definition.size * 0.5):
				continue
			_take_collision(hazard.definition.contact_damage)
			hazard.impact_by_vehicle(definition.ram_damage, 1)
			break
	if ram_cooldown > 0.0:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_defeated or not _overlaps_position(enemy.position, Vector2(28.0, 28.0)):
			continue
		var health_before: int = enemy.health
		enemy.take_hit(definition.ram_damage, Vector2(560.0, -55.0), true, false, 0.0, true)
		if enemy.health < health_before:
			ram_count += 1
			ram_cooldown = definition.ram_cooldown
			game.hit_confirm(enemy.position - Vector2(0.0, 55.0), 3, 1, true, HEAVY_IMPACT)
			game.play_sfx(&"vehicle_ram")
			_record_event(&"ram_hit")
		return


func _take_collision(amount: int) -> void:
	hull_health = maxi(0, hull_health - amount)
	hazard_cooldown = 0.72
	hazard_hit_count += 1
	speed = maxf(definition.minimum_speed, speed * 0.55)
	disabled_timer = 0.24
	game.hit_confirm(position - Vector2(0.0, 52.0), 3, 1, true, HEAVY_IMPACT)
	game.play_sfx(&"vehicle_crash")
	_record_event(&"hazard_collision")
	if hull_health <= 0:
		_hull_breakdown()


func _hull_breakdown() -> void:
	hull_health = definition.hull_health
	disabled_timer = 1.1
	for fighter in game.get_active_players():
		fighter.invulnerable = 0.0
		fighter.take_hit(definition.collision_damage, Vector2(-180.0, -25.0), false, 0.0, true, HEAVY_IMPACT)
	_record_event(&"hull_breakdown")


func _mount_players() -> void:
	for fighter in game.get_local_players():
		if not is_instance_valid(fighter) or fighter.is_defeated:
			continue
		fighter.position = position + _seat_offset(fighter.local_slot_index)
		fighter.facing = 1
		fighter.velocity = Vector2.ZERO
		fighter.visible = false


func _seat_offset(slot_index: int) -> Vector2:
	var seats := [Vector2(8.0, -4.0), Vector2(-46.0, -32.0), Vector2(-48.0, 34.0)]
	return seats[clampi(slot_index, 0, seats.size() - 1)]


func _overlaps_position(other_position: Vector2, half_size: Vector2) -> bool:
	return absf(other_position.x - position.x) < 118.0 + half_size.x and absf(other_position.y - position.y) < 44.0 + half_size.y


func _record_event(event: StringName) -> void:
	if last_drive_event == event and event in [&"accelerating", &"braking"]:
		return
	last_drive_event = event
	event_history.append(event)
	if event_history.size() > 24:
		event_history.pop_front()


func release_players() -> void:
	for fighter in game.get_local_players():
		if is_instance_valid(fighter) and not fighter.is_defeated:
			fighter.visible = true
			fighter.set_physics_process(game.state == "playing")
	remove_from_group("player_vehicle")


func _draw() -> void:
	_draw_oval(Vector2(-2.0, 4.0), 128.0, 15.0, Color(0.02, 0.03, 0.04, 0.46))
	var column := 3 if disabled_timer > 0.0 else (1 + int(drive_time * 8.0) % 2 if speed > definition.minimum_speed + 35.0 else 0)
	var source_rect := Rect2(column * INTERCEPTOR_CELL_SIZE.x, 0.0, INTERCEPTOR_CELL_SIZE.x, INTERCEPTOR_CELL_SIZE.y)
	draw_texture_rect_region(INTERCEPTOR_SHEET, Rect2(-145.0, -184.0, 290.0, 184.0), source_rect)
	draw_rect(Rect2(-112.0, 13.0, 224.0, 8.0), Color("#242a2e"))
	draw_rect(Rect2(-112.0, 13.0, 224.0 * hull_health / float(definition.hull_health), 8.0), Color("#63d879"))


func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(25):
		var angle := TAU * index / 24.0
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
