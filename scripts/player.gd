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
const AttackFrameDataScript = preload("res://core/combat/attack_frame_data.gd")
const ActionInputSourceScript = preload("res://core/input/action_input_source.gd")
const RunControllerScript = preload("res://actors/fighters/run_controller.gd")
const COMBO_DEFINITION = preload("res://data/fighters/ranger_combo.tres")
const AIR_ATTACK = preload("res://data/attacks/player_air.tres")
const THROW_ATTACK = preload("res://data/attacks/player_throw.tres")
const SPECIAL_ATTACK = preload("res://data/attacks/player_special.tres")
const RUN_SPEED_MULTIPLIER := 1.65
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
var finisher_armed := false
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
var current_attack
var input_source
var run_controller = RunControllerScript.new()
var is_running: bool:
	get:
		return run_controller.running
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
	input_source = ActionInputSourceScript.new()
	add_child(input_source)

func _physics_process(delta: float) -> void:
	state_machine.tick(delta)
	if is_defeated:
		state_machine.transition(FighterStateMachineScript.State.DEFEATED)
		return
	z_index = int(position.y)
	attack_timer = maxf(attack_timer - delta, 0.0)
	run_controller.tick(delta)
	attack_buffer = maxf(attack_buffer - delta, 0.0)
	attack_lunge = move_toward(attack_lunge, 0.0, 760.0 * delta)
	combo_window = maxf(combo_window - delta, 0.0)
	hurt_timer = maxf(hurt_timer - delta, 0.0)
	invulnerable = maxf(invulnerable - delta, 0.0)
	special_timer = maxf(special_timer - delta, 0.0)
	if combo_window <= 0.0 and attack_timer <= 0.0:
		combo_step = 0
		finisher_armed = false

	if z_height > 0.0 or z_velocity != 0.0:
		z_velocity -= 980.0 * delta
		z_height += z_velocity * delta
		if z_height <= 0.0:
			z_height = 0.0
			z_velocity = 0.0

	if hurt_timer <= 0.0 and special_timer <= 0.0:
		_apply_intent(input_source.sample_intent())
	else:
		run_controller.cancel()
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

func _apply_intent(intent) -> void:
	if intent == null:
		run_controller.update(Vector2.ZERO)
		velocity = Vector2(facing * attack_lunge, 0.0)
		return
	var input_vec: Vector2 = intent.move
	run_controller.update(input_vec)
	var movement_speed := SPEED * (RUN_SPEED_MULTIPLIER if is_running else 1.0)
	var move_scale := 0.42 if attack_timer > 0.0 else 1.0
	velocity = input_vec * movement_speed * move_scale + Vector2(facing * attack_lunge, 0.0)
	if absf(input_vec.x) > 0.15:
		facing = 1 if input_vec.x > 0.0 else -1
	if intent.jump_pressed and z_height <= 0.0 and attack_timer <= 0.0:
		z_velocity = 510.0
		z_height = 2.0
		game.play_sfx("jump")
	if intent.attack_pressed:
		_handle_attack_intent()
	if intent.special_pressed and z_height <= 5.0 and health > 12 and special_timer <= 0.0:
		_start_special()


func set_intent_source(source) -> void:
	input_source = source


func _handle_attack_intent() -> void:
	if combo_step == COMBO_DEFINITION.finisher_from_step and combo_window > 0.0:
		if attack_timer <= 0.0:
			_reset_combo()
			_start_attack()
		elif COMBO_DEFINITION.is_finisher_input_open(combo_step, attack_timer):
			finisher_armed = true
			attack_buffer = COMBO_DEFINITION.input_buffer_duration
		return
	if attack_timer > 0.105:
		attack_buffer = COMBO_DEFINITION.input_buffer_duration
	else:
		_start_attack()

func _start_attack() -> void:
	if attack_timer > 0.11:
		return
	run_controller.cancel()
	if is_instance_valid(grabbed_enemy):
		_reset_combo()
		state_machine.transition(FighterStateMachineScript.State.ATTACK)
		current_attack = THROW_ATTACK
		attack_hit_done = true
		attack_hitbox.deactivate()
		grabbed_enemy.thrown(Vector2(facing * current_attack.knockback.x, current_attack.knockback.y))
		grabbed_enemy = null
		attack_timer = current_attack.duration
		game.play_sfx(current_attack.sound_event)
		return
	attack_hit_done = false
	state_machine.transition(FighterStateMachineScript.State.ATTACK)
	if z_height > 15.0:
		combo_step = 4
		current_attack = AIR_ATTACK
	else:
		if combo_step == COMBO_DEFINITION.finisher_from_step and combo_window > 0.0:
			combo_step = COMBO_DEFINITION.finisher_step if finisher_armed else 1
		elif combo_window > 0.0:
			combo_step = combo_step % COMBO_DEFINITION.attacks.size() + 1
		else:
			combo_step = 1
		current_attack = COMBO_DEFINITION.attack_for_step(combo_step)
		finisher_armed = false
	attack_timer = current_attack.duration
	# Air attacks keep any still-running ground combo window, matching the
	# original controller behavior. Ground combo resources refresh it.
	if current_attack.combo_window > 0.0:
		combo_window = current_attack.combo_window
	attack_lunge = current_attack.lunge_speed
	_configure_attack_hitbox()
	game.play_sfx(current_attack.sound_event)

func _start_special() -> void:
	run_controller.cancel()
	_reset_combo()
	state_machine.transition(FighterStateMachineScript.State.SPECIAL)
	current_attack = SPECIAL_ATTACK
	attack_hitbox.deactivate()
	health -= current_attack.self_damage
	health_changed.emit(health, MAX_HEALTH)
	special_timer = current_attack.duration
	attack_timer = current_attack.duration
	attack_hit_done = true
	invulnerable = current_attack.invulnerable_duration
	game.play_sfx(current_attack.sound_event)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and position.distance_to(enemy.position) < current_attack.effect_radius:
			enemy.take_hit(
				current_attack.damage,
				Vector2(
					(enemy.position.x - position.x) * current_attack.radial_horizontal_scale,
					current_attack.knockback.y
				),
				current_attack.launch
			)
			var hit_direction := 1 if enemy.position.x >= position.x else -1
			game.hit_confirm(enemy.position - Vector2(0, 50), current_attack.impact_strength, hit_direction, false)
	game._hit_stop(current_attack.hit_stop_duration)

func _check_attack_hit() -> void:
	if attack_timer <= 0.0 or attack_hit_done or special_timer > 0.0 or current_attack == null:
		return
	if attack_timer > current_attack.hit_trigger_remaining:
		return
	attack_hit_done = true
	var best: Node = null
	var best_dist := 9999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_defeated or enemy.invulnerable > 0.0:
			continue
		var dx: float = (enemy.position.x - position.x) * facing
		var dy: float = absf(enemy.position.y - position.y)
		if attack_hitbox.overlaps(enemy.hurtbox):
			var dist: float = absf(dx) + dy
			if dist < best_dist:
				best = enemy
				best_dist = dist
	if best:
		var damage: int = current_attack.damage
		var used_weapon := weapon_hits > 0
		if used_weapon:
			damage += current_attack.weapon_bonus_damage
			weapon_hits -= 1
		var launch: bool = current_attack.launch
		best.take_hit(
			damage,
			Vector2(facing * current_attack.knockback.x, current_attack.knockback.y),
			launch
		)
		var impact_strength: int = (
			current_attack.weapon_impact_strength
			if used_weapon and current_attack.weapon_impact_strength > 0
			else current_attack.impact_strength
		)
		game.hit_confirm(best.position - Vector2(0, 50), impact_strength, facing)
		if current_attack.can_grab and z_height <= 0.0 and best.can_be_grabbed() and best_dist < current_attack.grab_range:
			grabbed_enemy = best
			best.grabbed_by(self)
	attack_hitbox.deactivate()


func _configure_attack_hitbox() -> void:
	if current_attack == null:
		attack_hitbox.deactivate()
		return
	if current_attack.hitbox_shape == AttackFrameDataScript.HitboxShape.BOX:
		var geometry: Array[Vector2] = current_attack.box_geometry(weapon_hits > 0)
		attack_hitbox.configure_box(geometry[0], geometry[1], facing)
	elif current_attack.hitbox_shape == AttackFrameDataScript.HitboxShape.CIRCLE:
		attack_hitbox.configure_circle(current_attack.circle_radius, facing)
	else:
		attack_hitbox.deactivate()

func take_hit(damage: int, knockback: Vector2) -> void:
	if invulnerable > 0.0 or is_defeated:
		return
	run_controller.cancel()
	_reset_combo()
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
	run_controller.cancel()
	_reset_combo()
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


func _reset_combo() -> void:
	combo_step = 0
	combo_window = 0.0
	attack_buffer = 0.0
	finisher_armed = false


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
	elif is_running and velocity.length() > 20.0:
		next_state = FighterStateMachineScript.State.RUN
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
		if combo_step == 4:
			return Vector2i(4, 1)
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
