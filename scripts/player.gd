class_name PlayerFighter
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal defeated

const SPEED := 255.0
const MAX_HEALTH := 120
const SPRITE_SHEET: Texture2D = preload("res://assets/sprites/ranger_sheet.png")
const FighterStateMachineScript = preload("res://actors/fighters/fighter_state_machine.gd")
const HurtboxScript = preload("res://core/combat/combat_hurtbox.gd")
const HitboxScript = preload("res://core/combat/combat_hitbox.gd")
var health := MAX_HEALTH
var facing := 1
var z_height := 0.0
var z_velocity := 0.0
var attack_timer := 0.0
var attack_hit_done := false
var attack_buffer := 0.0
var attack_lunge := 0.0
var combo_step := 0
var combo_window := 0.0
var hurt_timer := 0.0
var invulnerable := 0.0
var special_timer := 0.0
var grabbed_enemy: Node = null
var weapon_hits := 0
var is_defeated := false
var walk_phase := 0.0
var game: Node
var state_machine = FighterStateMachineScript.new()
var hurtbox
var attack_hitbox
var fighter_state: int:
	get:
		return state_machine.current_state

func setup(p_game: Node) -> void:
	game = p_game
	state_machine.force_transition(FighterStateMachineScript.State.IDLE)
	add_to_group("player")
	# Player and enemies block each other, while enemies use a separate layer so
	# they can steer apart without forming a rigid moving clump.
	collision_layer = 1
	collision_mask = 2
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 18.0
	capsule.height = 48.0
	shape.shape = capsule
	shape.position.y = -22
	add_child(shape)
	hurtbox = HurtboxScript.new()
	add_child(hurtbox)
	hurtbox.setup(self)
	attack_hitbox = HitboxScript.new()
	add_child(attack_hitbox)
	attack_hitbox.setup(self)

func _physics_process(delta: float) -> void:
	state_machine.tick(delta)
	if is_defeated:
		state_machine.transition(FighterStateMachineScript.State.DEFEATED)
		return
	z_index = int(position.y)
	attack_timer = maxf(attack_timer - delta, 0.0)
	attack_buffer = maxf(attack_buffer - delta, 0.0)
	attack_lunge = move_toward(attack_lunge, 0.0, 760.0 * delta)
	combo_window = maxf(combo_window - delta, 0.0)
	hurt_timer = maxf(hurt_timer - delta, 0.0)
	invulnerable = maxf(invulnerable - delta, 0.0)
	special_timer = maxf(special_timer - delta, 0.0)
	if combo_window <= 0.0 and attack_timer <= 0.0:
		combo_step = 0

	if z_height > 0.0 or z_velocity != 0.0:
		z_velocity -= 980.0 * delta
		z_height += z_velocity * delta
		if z_height <= 0.0:
			z_height = 0.0
			z_velocity = 0.0

	if hurt_timer <= 0.0 and special_timer <= 0.0:
		_read_input()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)

	move_and_slide()
	position.x = clampf(position.x, 80.0, game.stage_limit)
	position.y = clampf(position.y, 455.0, 665.0)
	walk_phase += velocity.length() * delta * 0.025
	_check_attack_hit()
	if attack_buffer > 0.0 and attack_timer <= 0.105 and hurt_timer <= 0.0 and special_timer <= 0.0:
		attack_buffer = 0.0
		_start_attack()
	_sync_fighter_state()
	queue_redraw()

func _read_input() -> void:
	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_scale := 0.42 if attack_timer > 0.0 else 1.0
	velocity = input_vec * SPEED * move_scale + Vector2(facing * attack_lunge, 0.0)
	if absf(input_vec.x) > 0.15:
		facing = 1 if input_vec.x > 0.0 else -1
	if Input.is_action_just_pressed("jump") and z_height <= 0.0 and attack_timer <= 0.0:
		z_velocity = 510.0
		z_height = 2.0
		game.play_sfx("jump")
	if Input.is_action_just_pressed("attack"):
		if attack_timer > 0.105:
			attack_buffer = 0.24
		else:
			_start_attack()
	if Input.is_action_just_pressed("special") and z_height <= 5.0 and health > 12 and special_timer <= 0.0:
		_start_special()

func _start_attack() -> void:
	if attack_timer > 0.11:
		return
	if is_instance_valid(grabbed_enemy):
		state_machine.transition(FighterStateMachineScript.State.ATTACK)
		attack_hitbox.deactivate()
		grabbed_enemy.thrown(Vector2(facing * 560.0, -80.0))
		grabbed_enemy = null
		attack_timer = 0.42
		game.play_sfx("heavy")
		return
	attack_hit_done = false
	state_machine.transition(FighterStateMachineScript.State.ATTACK)
	if z_height > 15.0:
		combo_step = 4
		attack_timer = 0.34
		attack_lunge = 170.0
	else:
		combo_step = combo_step % 3 + 1 if combo_window > 0.0 else 1
		attack_timer = 0.26 if combo_step < 3 else 0.43
		combo_window = 0.62
		attack_lunge = [105.0, 132.0, 185.0][combo_step - 1]
	_configure_attack_hitbox()
	game.play_sfx("swing")

func _start_special() -> void:
	state_machine.transition(FighterStateMachineScript.State.SPECIAL)
	attack_hitbox.deactivate()
	health -= 7
	health_changed.emit(health, MAX_HEALTH)
	special_timer = 0.62
	attack_timer = 0.62
	attack_hit_done = true
	invulnerable = 0.7
	game.play_sfx("special")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and position.distance_to(enemy.position) < 115.0:
			enemy.take_hit(18, Vector2((enemy.position.x - position.x) * 4.0, -45.0), true)
			var hit_direction := 1 if enemy.position.x >= position.x else -1
			game.hit_confirm(enemy.position - Vector2(0, 50), 3, hit_direction, false)
	game._hit_stop(0.105)

func _check_attack_hit() -> void:
	if attack_timer <= 0.0 or attack_hit_done or special_timer > 0.0:
		return
	var trigger := 0.18 if combo_step != 3 else 0.31
	if attack_timer > trigger:
		return
	attack_hit_done = true
	var best: Node = null
	var best_dist := 9999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_defeated:
			continue
		var dx: float = (enemy.position.x - position.x) * facing
		var dy: float = absf(enemy.position.y - position.y)
		if attack_hitbox.overlaps(enemy.hurtbox):
			var dist: float = absf(dx) + dy
			if dist < best_dist:
				best = enemy
				best_dist = dist
	if best:
		var damage := 10 + combo_step * 2
		var used_weapon := weapon_hits > 0
		if weapon_hits > 0:
			damage += 7
			weapon_hits -= 1
		var launch := combo_step >= 3 or combo_step == 4
		var knockback_strength := 430.0 if launch else (155.0 if combo_step == 2 else 118.0)
		best.take_hit(damage, Vector2(facing * knockback_strength, -35.0), launch)
		var impact_strength := 3 if launch else (2 if combo_step == 2 or used_weapon else 1)
		game.hit_confirm(best.position - Vector2(0, 50), impact_strength, facing)
		if combo_step == 1 and z_height <= 0.0 and best.can_be_grabbed() and best_dist < 39.0:
			grabbed_enemy = best
			best.grabbed_by(self)
	attack_hitbox.deactivate()


func _configure_attack_hitbox() -> void:
	var attack_range := 92.0 if weapon_hits > 0 else 70.0
	if combo_step == 4:
		attack_range = 86.0
	var target_half_width: float = hurtbox.half_extents.x
	var left_edge: float = -12.0 + target_half_width
	var right_edge: float = attack_range - target_half_width
	var center_x: float = (left_edge + right_edge) * 0.5
	var half_width: float = (right_edge - left_edge) * 0.5
	var half_depth: float = 46.0 - hurtbox.half_extents.y
	attack_hitbox.configure_box(Vector2(center_x, 0.0), Vector2(half_width, half_depth), facing)

func take_hit(damage: int, knockback: Vector2) -> void:
	if invulnerable > 0.0 or is_defeated:
		return
	if is_instance_valid(grabbed_enemy):
		grabbed_enemy.release_grab()
		grabbed_enemy = null
	health = maxi(health - damage, 0)
	health_changed.emit(health, MAX_HEALTH)
	hurt_timer = 0.42
	invulnerable = 0.65
	velocity = knockback
	game.hit_confirm(position - Vector2(0, 55), 2, -signi(int(knockback.x)))
	game.play_sfx("hurt")
	if health <= 0:
		is_defeated = true
		state_machine.transition(FighterStateMachineScript.State.DEFEATED)
		defeated.emit()
	else:
		state_machine.transition(FighterStateMachineScript.State.HURT)
	queue_redraw()


func revive(respawn_position: Vector2) -> void:
	health = MAX_HEALTH
	is_defeated = false
	invulnerable = 2.2
	position = respawn_position
	state_machine.force_transition(FighterStateMachineScript.State.IDLE)
	health_changed.emit(health, MAX_HEALTH)
	queue_redraw()

func heal(amount: int) -> void:
	health = mini(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)
	game.play_sfx("pickup")

func give_weapon() -> void:
	weapon_hits = 12
	game.play_sfx("pickup")


func _sync_fighter_state() -> void:
	var next_state := FighterStateMachineScript.State.IDLE
	if is_defeated:
		next_state = FighterStateMachineScript.State.DEFEATED
	elif hurt_timer > 0.0:
		next_state = FighterStateMachineScript.State.HURT
	elif special_timer > 0.0:
		next_state = FighterStateMachineScript.State.SPECIAL
	elif attack_timer > 0.0:
		next_state = FighterStateMachineScript.State.ATTACK
	elif is_instance_valid(grabbed_enemy):
		next_state = FighterStateMachineScript.State.GRAB_HOLD
	elif z_height > 0.0 or z_velocity != 0.0:
		next_state = FighterStateMachineScript.State.AIRBORNE
	elif velocity.length() > 20.0:
		next_state = FighterStateMachineScript.State.MOVE
	state_machine.transition(next_state)

func _draw() -> void:
	var jump_offset := Vector2(0, -z_height)
	# Ground shadow remains anchored while the sprite rises during jumps.
	_draw_oval(Vector2(0, 1), 29.0, 9.0, Color(0.02,0.03,0.04,0.42))
	var frame := _visual_frame()
	var cell := Vector2(SPRITE_SHEET.get_width() / 5.0, SPRITE_SHEET.get_height() / 3.0)
	var target_size := Vector2(154.0, 171.0)
	var target_rect := Rect2(-target_size.x * 0.5, -target_size.y + 16.0, target_size.x, target_size.y)
	var source_rect := Rect2(frame.x * cell.x, frame.y * cell.y, cell.x, cell.y)
	var tint_color := Color(1.0, 0.72, 0.72) if hurt_timer > 0.0 else Color.WHITE
	draw_set_transform(jump_offset, 0.0, Vector2(facing, 1.0))
	draw_texture_rect_region(SPRITE_SHEET, target_rect, source_rect, tint_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if weapon_hits > 0:
		draw_line(jump_offset + Vector2(22*facing,-62), jump_offset + Vector2(63*facing,-73), Color("#e8eee4"), 8)
		draw_line(jump_offset + Vector2(56*facing,-71), jump_offset + Vector2(69*facing,-82), Color("#7c382c"), 6)
	if special_timer > 0.0:
		draw_arc(jump_offset + Vector2(0,-64), 76, 0, TAU, 32, Color("#ffe37a"), 7)

func _visual_frame() -> Vector2i:
	if is_defeated or hurt_timer > 0.0:
		return Vector2i(2, 2)
	if special_timer > 0.0:
		return Vector2i(3, 1)
	if is_instance_valid(grabbed_enemy):
		return Vector2i(3, 2)
	if z_height > 12.0:
		return Vector2i(1, 2) if attack_timer > 0.0 else Vector2i(0, 2)
	if attack_timer > 0.0:
		if combo_step == 1:
			return Vector2i(1 if attack_timer < 0.18 else 0, 1)
		if combo_step == 2:
			return Vector2i(2, 1)
		return Vector2i(3, 1)
	if velocity.length() > 20.0:
		return Vector2i(2 + int(walk_phase) % 3, 0)
	return Vector2i(int(walk_phase * 0.2) % 2, 0)

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	draw_colored_polygon(pts, color)
