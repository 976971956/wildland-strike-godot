class_name PlayerFighter
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal defeated

const SPEED := 255.0
const MAX_HEALTH := 120
const SPRITE_SHEET: Texture2D = preload("res://assets/sprites/ranger_sheet_v2.png")
const SPRITE_COLUMNS := 6
const SPRITE_ROWS := 4
const FighterStateMachineScript = preload("res://actors/fighters/fighter_state_machine.gd")
const HurtboxScript = preload("res://core/combat/combat_hurtbox.gd")
const HitboxScript = preload("res://core/combat/combat_hitbox.gd")
const AttackFrameDataScript = preload("res://core/combat/attack_frame_data.gd")
const CounterHitRulesScript = preload("res://core/combat/counter_hit_rules.gd")
const AttackPriorityRulesScript = preload("res://core/combat/attack_priority_rules.gd")
const ActionInputSourceScript = preload("res://core/input/action_input_source.gd")
const RunControllerScript = preload("res://actors/fighters/run_controller.gd")
const CommandMoveControllerScript = preload("res://actors/fighters/command_move_controller.gd")
const WeaponDefinitionScript = preload("res://core/weapons/weapon_definition.gd")
const COMBO_DEFINITION = preload("res://data/fighters/ranger_combo.tres")
const RUN_ATTACK = preload("res://data/attacks/player_run.tres")
const JUMP_ATTACK = preload("res://data/attacks/player_air.tres")
const APEX_ATTACK = preload("res://data/attacks/player_apex.tres")
const DIVE_ATTACK = preload("res://data/attacks/player_dive.tres")
const COMMAND_ATTACK = preload("res://data/attacks/player_command.tres")
const GRAB_STRIKE_ATTACK = preload("res://data/attacks/player_grab_strike.tres")
const FORWARD_THROW_ATTACK = preload("res://data/attacks/player_throw.tres")
const BACK_THROW_ATTACK = preload("res://data/attacks/player_back_throw.tres")
const COMBO_THROW_ATTACK = preload("res://data/attacks/player_combo_throw.tres")
const SPECIAL_ATTACK = preload("res://data/attacks/player_special.tres")
const CLASH_IMPACT = preload("res://data/impacts/clash.tres")
const MACHETE_WEAPON = preload("res://data/weapons/machete.tres")
const GRENADE_WEAPON = preload("res://data/weapons/grenade.tres")
const PISTOL_WEAPON = preload("res://data/weapons/pistol.tres")
const WEAPON_PICKUPS := {
	"weapon": MACHETE_WEAPON,
	"weapon_melee": MACHETE_WEAPON,
	"weapon_explosive": GRENADE_WEAPON,
	"weapon_firearm": PISTOL_WEAPON,
}
const RUN_SPEED_MULTIPLIER := 1.65
const MAX_GRAB_STRIKES := 3
const GRAB_HOLD_DURATION := 2.0
var health := MAX_HEALTH
var max_health := MAX_HEALTH
var move_speed := SPEED
var run_speed_multiplier := RUN_SPEED_MULTIPLIER
var damage_scale := 1.0
var item_efficiency := 1.0
var aerial_control := 1.0
var grapple_power := 1.0
var hero_definition: Resource
var hero_id: StringName = &"ranger"
var hero_display_name := "RANGER"
var hero_sprite_sheet: Texture2D = SPRITE_SHEET
var hero_sprite_columns := SPRITE_COLUMNS
var hero_sprite_rows := SPRITE_ROWS
var local_slot_index := 0
var input_device_id := -1
var combat_team: StringName = &"players"
var combat_owner_id := 0
var facing := 1
var z_height := 0.0
var z_velocity := 0.0
var attack_timer := 0.0
var attack_hit_done := false
var attack_hits_resolved := 0
var next_hit_remaining := 0.0
var attack_buffer := 0.0
var attack_lunge := 0.0
var combo_step := 0
var combo_window := 0.0
var finisher_armed := false
var hurt_timer := 0.0
var invulnerable := 0.0
var special_timer := 0.0
var team_attack_charge_timer := 0.0
var special_connected := false
var last_hit_was_counter := false
var grabbed_enemy: Node = null
var grab_strike_count := 0
var grab_hold_timer := 0.0
var equipped_weapon: Resource = null
var weapon_ammo := 0
var weapon_hits: int:
	get:
		return weapon_ammo
	set(value):
		weapon_ammo = maxi(value, 0)
		if weapon_ammo > 0 and equipped_weapon == null:
			equipped_weapon = MACHETE_WEAPON
		elif weapon_ammo <= 0:
			equipped_weapon = null
		if game != null:
			_sync_weapon_hud()
var is_defeated := false
var walk_phase := 0.0
var visual_clock := 0.0
var victory_pose_phase := 0
var game: Node
var state_machine = FighterStateMachineScript.new()
var hurtbox
var attack_hitbox
var current_attack
var input_source
var run_controller = RunControllerScript.new()
var command_controller = CommandMoveControllerScript.new()
var is_running: bool:
	get:
		return run_controller.running
var fighter_state: int:
	get:
		return state_machine.current_state

func setup(
	p_game: Node,
	p_hero_definition: Resource = null,
	p_local_slot_index := 0,
	p_input_device_id := -1,
	p_input_source = null
) -> void:
	game = p_game
	local_slot_index = p_local_slot_index
	input_device_id = p_input_device_id
	combat_owner_id = p_local_slot_index
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	apply_hero_definition(p_hero_definition)
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
	input_source = p_input_source if p_input_source != null else ActionInputSourceScript.new()
	if input_source is Node and input_source.get_parent() == null:
		add_child(input_source)


func apply_hero_definition(value: Resource) -> void:
	if value == null or not value.has_method("is_valid_hero") or not value.is_valid_hero():
		return
	hero_definition = value
	hero_id = value.hero_id
	hero_display_name = value.display_name
	hero_sprite_sheet = value.sprite_sheet
	hero_sprite_columns = value.sprite_columns
	hero_sprite_rows = value.sprite_rows
	max_health = value.max_health
	move_speed = value.move_speed
	run_speed_multiplier = value.run_multiplier
	damage_scale = value.damage_scale
	item_efficiency = value.item_efficiency
	aerial_control = value.aerial_control
	grapple_power = value.grapple_power
	health = max_health
	if game != null:
		health_changed.emit(health, max_health)
	queue_redraw()

func _physics_process(delta: float) -> void:
	state_machine.tick(delta)
	if is_defeated:
		state_machine.transition(FighterStateMachineScript.State.DEFEATED)
		return
	z_index = int(position.y)
	attack_timer = maxf(attack_timer - delta, 0.0)
	run_controller.tick(delta)
	command_controller.tick(delta)
	attack_buffer = maxf(attack_buffer - delta, 0.0)
	attack_lunge = move_toward(attack_lunge, 0.0, 760.0 * delta)
	combo_window = maxf(combo_window - delta, 0.0)
	hurt_timer = maxf(hurt_timer - delta, 0.0)
	invulnerable = maxf(invulnerable - delta, 0.0)
	special_timer = maxf(special_timer - delta, 0.0)
	team_attack_charge_timer = maxf(team_attack_charge_timer - delta, 0.0)
	if is_instance_valid(grabbed_enemy):
		grab_hold_timer = maxf(grab_hold_timer - delta, 0.0)
		if grab_hold_timer <= 0.0:
			_release_grabbed_enemy()
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
	visual_clock += delta
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
	command_controller.update(input_vec, facing)
	var movement_speed := move_speed * (run_speed_multiplier if is_running else 1.0)
	var move_scale := 0.42 if attack_timer > 0.0 else 1.0
	velocity = input_vec * movement_speed * move_scale + Vector2(facing * attack_lunge, 0.0)
	if absf(input_vec.x) > 0.15 and not is_instance_valid(grabbed_enemy):
		facing = 1 if input_vec.x > 0.0 else -1
	var defensive_chord: bool = intent.attack_pressed and intent.jump_pressed
	if defensive_chord:
		if z_height <= 5.0 and health > SPECIAL_ATTACK.self_damage and special_timer <= 0.0:
			_request_special()
		return
	if intent.special_pressed:
		if z_height <= 5.0 and health > SPECIAL_ATTACK.self_damage and special_timer <= 0.0:
			_request_special()
		return
	if (
		intent.attack_pressed
		and z_height <= 5.0
		and game.has_method("try_revive_teammate")
		and game.try_revive_teammate(self)
	):
		run_controller.cancel()
		velocity = Vector2.ZERO
		return
	if is_instance_valid(grabbed_enemy):
		velocity = Vector2.ZERO
		if intent.attack_pressed:
			_handle_grab_action(input_vec)
		return
	if intent.jump_pressed and z_height <= 0.0 and attack_timer <= 0.0:
		command_controller.cancel()
		z_velocity = 510.0 * aerial_control
		z_height = 2.0
		game.play_sfx("jump")
	if intent.attack_pressed:
		if z_height <= 0.0 and attack_timer <= 0.105 and command_controller.consume_attack():
			_start_command_attack()
		else:
			_handle_attack_intent()


func set_intent_source(source) -> void:
	input_source = source


func prepare_local_leave() -> void:
	set_physics_process(false)
	run_controller.cancel()
	command_controller.cancel()
	velocity = Vector2.ZERO
	if is_instance_valid(grabbed_enemy):
		_release_grabbed_enemy()
	remove_from_group("player")


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
	var was_running := is_running
	run_controller.cancel()
	command_controller.cancel()
	if is_instance_valid(grabbed_enemy):
		_handle_grab_action(Vector2.ZERO)
		return
	attack_hit_done = false
	state_machine.transition(FighterStateMachineScript.State.ATTACK)
	if z_height > 0.0:
		_reset_combo()
		current_attack = _aerial_attack_for_velocity()
	elif was_running:
		_reset_combo()
		current_attack = RUN_ATTACK
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
	_reset_attack_resolution()
	# Air attacks keep any still-running ground combo window, matching the
	# original controller behavior. Ground combo resources refresh it.
	if current_attack.combo_window > 0.0:
		combo_window = current_attack.combo_window
	attack_lunge = current_attack.lunge_speed
	_configure_attack_hitbox()
	game.play_sfx(current_attack.sound_event)


func _aerial_attack_for_velocity():
	var selected_attack
	if z_velocity > 130.0:
		selected_attack = JUMP_ATTACK
	elif z_velocity >= -130.0:
		selected_attack = APEX_ATTACK
	else:
		selected_attack = DIVE_ATTACK
	if selected_attack.vertical_velocity_override != 0.0:
		z_velocity = selected_attack.vertical_velocity_override
	return selected_attack


func _start_command_attack() -> void:
	if attack_timer > 0.105 or z_height > 0.0:
		return
	run_controller.cancel()
	command_controller.cancel()
	_reset_combo()
	state_machine.transition(FighterStateMachineScript.State.ATTACK)
	current_attack = COMMAND_ATTACK
	attack_hit_done = false
	attack_timer = current_attack.duration
	_reset_attack_resolution()
	attack_lunge = current_attack.lunge_speed
	_configure_attack_hitbox()
	game.play_sfx(current_attack.sound_event)

func _start_special() -> void:
	run_controller.cancel()
	command_controller.cancel()
	_reset_combo()
	_release_grabbed_enemy()
	state_machine.transition(FighterStateMachineScript.State.SPECIAL)
	current_attack = SPECIAL_ATTACK
	attack_hitbox.deactivate()
	special_connected = false
	special_timer = current_attack.duration
	attack_timer = current_attack.duration
	attack_hit_done = true
	invulnerable = current_attack.invulnerable_duration
	game.play_sfx(current_attack.sound_event)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.is_defeated and position.distance_to(enemy.position) < current_attack.effect_radius:
			var priority_outcome: int = AttackPriorityRulesScript.resolve(current_attack, enemy)
			if not AttackPriorityRulesScript.allows_hit(priority_outcome):
				continue
			var enemy_health_before: int = enemy.health
			enemy.take_hit(
				_scaled_damage(current_attack.damage),
				Vector2(
					(enemy.position.x - position.x) * current_attack.radial_horizontal_scale,
					current_attack.knockback.y
				),
				current_attack.launch,
				false,
				0.0,
				AttackPriorityRulesScript.interrupts_defender(priority_outcome)
			)
			if enemy.health < enemy_health_before:
				special_connected = true
				var hit_direction := 1 if enemy.position.x >= position.x else -1
				game.hit_confirm(
					enemy.position - Vector2(0, 50),
					current_attack.impact_strength,
					hit_direction,
					false,
					current_attack.impact_profile
				)
	if special_connected:
		health = maxi(health - current_attack.self_damage, 1)
		health_changed.emit(health, max_health)
		_apply_attacker_recoil(current_attack.impact_profile)
		game._hit_stop(current_attack.impact_profile.hit_stop_duration)


func _request_special() -> void:
	if game.has_method("try_team_attack") and game.try_team_attack(self):
		return
	_start_special()


func start_queued_special() -> void:
	team_attack_charge_timer = 0.0
	if is_defeated or hurt_timer > 0.0 or special_timer > 0.0 or z_height > 5.0 or health <= SPECIAL_ATTACK.self_damage:
		return
	_start_special()


func begin_team_attack(attack_data: Resource) -> void:
	run_controller.cancel()
	command_controller.cancel()
	_reset_combo()
	_release_grabbed_enemy()
	team_attack_charge_timer = 0.0
	state_machine.transition(FighterStateMachineScript.State.SPECIAL)
	current_attack = attack_data
	attack_hitbox.deactivate()
	special_connected = true
	special_timer = attack_data.duration
	attack_timer = attack_data.duration
	attack_hit_done = true
	invulnerable = maxf(invulnerable, attack_data.invulnerable_duration)
	queue_redraw()


func apply_team_attack_cost(amount: int) -> void:
	health = maxi(health - maxi(amount, 0), 1)
	health_changed.emit(health, max_health)
	queue_redraw()

func _check_attack_hit() -> void:
	if attack_timer <= 0.0 or attack_hit_done or special_timer > 0.0 or current_attack == null:
		return
	if attack_timer > next_hit_remaining:
		return
	if _has_projectile_weapon():
		_fire_equipped_weapon()
		return
	var best: Node = null
	var best_dist := 9999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_defeated or enemy.invulnerable > 0.0:
			continue
		var dx: float = (enemy.position.x - position.x) * facing
		var dy: float = absf(enemy.position.y - position.y)
		if attack_hitbox.can_damage(enemy.hurtbox) and attack_hitbox.overlaps(enemy.hurtbox):
			var dist: float = absf(dx) + dy
			if dist < best_dist:
				best = enemy
				best_dist = dist
	if best == null:
		for stage_object in get_tree().get_nodes_in_group("breakables"):
			if not is_instance_valid(stage_object) or stage_object.is_defeated:
				continue
			var dx: float = (stage_object.position.x - position.x) * facing
			var dy: float = absf(stage_object.position.y - position.y)
			if dx < -18.0 or not attack_hitbox.overlaps(stage_object.hurtbox):
				continue
			var dist: float = absf(dx) + dy
			if dist < best_dist:
				best = stage_object
				best_dist = dist
	if best:
		if best.is_in_group("breakables"):
			var used_weapon := weapon_hits > 0
			var damage: int = current_attack.damage
			if used_weapon:
				damage += current_attack.weapon_bonus_damage
				weapon_hits -= 1
			damage = _scaled_damage(damage)
			var impact_position: Vector2 = best.position - Vector2(0.0, best.definition.size.y * 0.45)
			if best.take_stage_hit(damage, facing):
				var impact_strength: int = (
					current_attack.weapon_impact_strength
					if used_weapon and current_attack.weapon_impact_strength > 0
					else current_attack.impact_strength
				)
				game.hit_confirm(impact_position, impact_strength, facing, true, current_attack.impact_profile)
				_apply_attacker_recoil(current_attack.impact_profile)
			_finish_attack_pulse()
			return
		var priority_outcome: int = AttackPriorityRulesScript.resolve(current_attack, best)
		if not AttackPriorityRulesScript.allows_hit(priority_outcome):
			game.hit_confirm((position + best.position) * 0.5 - Vector2(0, 45), 1, facing, false, CLASH_IMPACT)
			lose_priority_clash()
			return
		var will_grab: bool = (
			current_attack.can_grab
			and z_height <= 0.0
			and best.can_be_grabbed()
			and best_dist < current_attack.grab_range
		)
		var counter_hit: bool = (
			priority_outcome == AttackPriorityRulesScript.Outcome.WIN
			and CounterHitRulesScript.is_counterable(best)
		)
		var damage: int = CounterHitRulesScript.damage_for(current_attack, counter_hit)
		var used_weapon := weapon_hits > 0
		if used_weapon:
			damage += current_attack.weapon_bonus_damage
			weapon_hits -= 1
		damage = _scaled_damage(damage)
		var launch: bool = CounterHitRulesScript.launch_for(current_attack, counter_hit)
		var resolved_knockback := CounterHitRulesScript.knockback_for(current_attack, facing, counter_hit)
		var final_pulse: bool = attack_hits_resolved + 1 >= current_attack.max_hits
		if current_attack.max_hits > 1 and not final_pulse:
			launch = false
			resolved_knockback *= 0.35
		var best_health_before: int = best.health
		best.take_hit(
			damage,
			resolved_knockback,
			launch,
			counter_hit,
			CounterHitRulesScript.stun_bonus_for(current_attack, counter_hit),
			AttackPriorityRulesScript.interrupts_defender(priority_outcome)
		)
		if best.health >= best_health_before:
			_finish_attack_pulse()
			return
		var impact_strength: int = (
			current_attack.weapon_impact_strength
			if used_weapon and current_attack.weapon_impact_strength > 0
			else current_attack.impact_strength
		)
		game.hit_confirm(best.position - Vector2(0, 50), impact_strength, facing, true, current_attack.impact_profile)
		_apply_attacker_recoil(current_attack.impact_profile)
		if will_grab and is_instance_valid(best) and not best.is_defeated:
			grabbed_enemy = best
			best.grabbed_by(self)
			grab_strike_count = 0
			grab_hold_timer = GRAB_HOLD_DURATION
			command_controller.cancel()
	_finish_attack_pulse()


func _handle_grab_action(input_vec: Vector2) -> void:
	if not is_instance_valid(grabbed_enemy) or attack_timer > 0.105:
		return
	var relative_x := input_vec.x * facing
	if relative_x > 0.45:
		_perform_throw(FORWARD_THROW_ATTACK, facing)
	elif relative_x < -0.45:
		_perform_throw(BACK_THROW_ATTACK, -facing)
	elif grab_strike_count >= MAX_GRAB_STRIKES:
		_perform_throw(COMBO_THROW_ATTACK, facing)
	else:
		_perform_grab_strike()


func _perform_grab_strike() -> void:
	if not is_instance_valid(grabbed_enemy):
		return
	current_attack = GRAB_STRIKE_ATTACK
	state_machine.transition(FighterStateMachineScript.State.ATTACK)
	attack_timer = current_attack.duration
	attack_hit_done = true
	attack_hitbox.deactivate()
	grab_strike_count += 1
	grab_hold_timer = 0.9
	var force := Vector2(facing * current_attack.knockback.x, current_attack.knockback.y)
	var target_position: Vector2 = grabbed_enemy.position
	grabbed_enemy.take_grab_strike(_scaled_grapple_damage(current_attack.damage), force * grapple_power)
	game.hit_confirm(target_position - Vector2(0, 50), current_attack.impact_strength, facing, true, current_attack.impact_profile)
	_apply_attacker_recoil(current_attack.impact_profile)
	game.play_sfx(current_attack.sound_event)
	if not is_instance_valid(grabbed_enemy) or grabbed_enemy.is_defeated:
		grabbed_enemy = null
		grab_hold_timer = 0.0


func _perform_throw(attack, throw_direction: int) -> void:
	if not is_instance_valid(grabbed_enemy):
		return
	current_attack = attack
	state_machine.transition(FighterStateMachineScript.State.ATTACK)
	attack_timer = current_attack.duration
	attack_hit_done = true
	attack_hitbox.deactivate()
	var target := grabbed_enemy
	var target_position: Vector2 = target.position
	grabbed_enemy = null
	grab_strike_count = 0
	grab_hold_timer = 0.0
	var force := Vector2(
		throw_direction * current_attack.knockback.x * grapple_power,
		current_attack.knockback.y * lerpf(1.0, grapple_power, 0.55)
	)
	target.thrown(
		_scaled_grapple_damage(current_attack.damage),
		force,
		current_attack.throw_collision_damage,
		current_attack.impact_profile
	)
	game.hit_confirm(target_position - Vector2(0, 50), current_attack.impact_strength, throw_direction, true, current_attack.impact_profile)
	_apply_attacker_recoil(current_attack.impact_profile)
	game.play_sfx(current_attack.sound_event)


func _release_grabbed_enemy() -> void:
	if is_instance_valid(grabbed_enemy):
		grabbed_enemy.release_grab()
	grabbed_enemy = null
	grab_strike_count = 0
	grab_hold_timer = 0.0


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

func take_hit(
	damage: int,
	knockback: Vector2,
	counter_hit := false,
	counter_stun_bonus := 0.0,
	force_interrupt := false,
	impact_profile: Resource = null
) -> void:
	if invulnerable > 0.0 or is_defeated:
		return
	if game != null and game.has_method("cancel_team_attack_request"):
		game.cancel_team_attack_request(self)
	run_controller.cancel()
	command_controller.cancel()
	_reset_combo()
	last_hit_was_counter = counter_hit
	if counter_hit or force_interrupt:
		attack_timer = 0.0
		attack_hit_done = true
		attack_hitbox.deactivate()
	if is_instance_valid(grabbed_enemy):
		_release_grabbed_enemy()
	health = maxi(health - damage, 0)
	health_changed.emit(health, max_health)
	hurt_timer = 0.42 + counter_stun_bonus
	invulnerable = 0.65
	velocity = knockback
	game.hit_confirm(position - Vector2(0, 55), 2, -signi(int(knockback.x)), true, impact_profile)
	game.play_sfx("hurt")
	if health <= 0:
		is_defeated = true
		state_machine.transition(FighterStateMachineScript.State.DEFEATED)
		defeated.emit()
	else:
		state_machine.transition(FighterStateMachineScript.State.HURT)
	queue_redraw()


func lose_priority_clash() -> void:
	run_controller.cancel()
	command_controller.cancel()
	_reset_combo()
	attack_timer = 0.0
	attack_hit_done = true
	attack_hitbox.deactivate()
	hurt_timer = maxf(hurt_timer, 0.12)
	velocity = Vector2(-facing * 65.0, 0.0)
	state_machine.transition(FighterStateMachineScript.State.STUN)
	queue_redraw()


func revive(respawn_position: Vector2, health_ratio := 1.0) -> void:
	run_controller.cancel()
	command_controller.cancel()
	_release_grabbed_enemy()
	_reset_combo()
	health = clampi(roundi(max_health * health_ratio), 1, max_health)
	is_defeated = false
	invulnerable = 2.2
	position = respawn_position
	state_machine.force_transition(FighterStateMachineScript.State.IDLE)
	health_changed.emit(health, max_health)
	queue_redraw()

func heal(amount: int) -> void:
	health = mini(max_health, health + roundi(amount * item_efficiency))
	health_changed.emit(health, max_health)
	game.play_sfx("pickup")

func give_weapon(pickup_id: String = "weapon_melee") -> void:
	equipped_weapon = WEAPON_PICKUPS.get(pickup_id, MACHETE_WEAPON)
	weapon_hits = maxi(1, roundi(equipped_weapon.capacity * item_efficiency))
	game.play_sfx("pickup")
	queue_redraw()


func _has_projectile_weapon() -> bool:
	return (
		equipped_weapon != null
		and weapon_ammo > 0
		and equipped_weapon.kind != WeaponDefinitionScript.WeaponKind.MELEE
	)


func _fire_equipped_weapon() -> void:
	if not _has_projectile_weapon():
		return
	game.spawn_weapon_projectile(
		self,
		equipped_weapon,
		&"player",
		position + Vector2(facing * 36.0, 0.0),
		facing
	)
	game.play_sfx(equipped_weapon.fire_sfx)
	weapon_hits -= 1
	# A firearm/explosive consumes exactly one round per attack even when the
	# underlying unarmed attack resource contains multiple contact pulses.
	attack_hits_resolved = current_attack.max_hits
	attack_hit_done = true
	attack_hitbox.deactivate()
	queue_redraw()


func _sync_weapon_hud() -> void:
	if game != null and game.has_method("weapon_changed"):
		game.weapon_changed(equipped_weapon, weapon_ammo, self)


func _scaled_damage(amount: int) -> int:
	return maxi(1, roundi(amount * damage_scale))


func _scaled_grapple_damage(amount: int) -> int:
	return maxi(1, roundi(amount * damage_scale * grapple_power))


func _reset_combo() -> void:
	combo_step = 0
	combo_window = 0.0
	attack_buffer = 0.0
	finisher_armed = false


func _reset_attack_resolution() -> void:
	attack_hits_resolved = 0
	next_hit_remaining = current_attack.hit_trigger_remaining


func _finish_attack_pulse() -> void:
	attack_hits_resolved += 1
	if attack_hits_resolved >= current_attack.max_hits:
		attack_hit_done = true
		attack_hitbox.deactivate()
		return
	next_hit_remaining = maxf(0.0, attack_timer - current_attack.repeat_hit_interval)


func _apply_attacker_recoil(impact_profile: Resource) -> void:
	if impact_profile != null:
		attack_lunge = -impact_profile.attacker_recoil_speed


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
	var cell := Vector2(
		hero_sprite_sheet.get_width() / float(hero_sprite_columns),
		hero_sprite_sheet.get_height() / float(hero_sprite_rows)
	)
	var target_size := Vector2(154.0, 171.0)
	var target_rect := Rect2(-target_size.x * 0.5, -target_size.y + 16.0, target_size.x, target_size.y)
	var source_rect := Rect2(frame.x * cell.x, frame.y * cell.y, cell.x, cell.y)
	var tint_color := Color(1.0, 0.72, 0.72) if hurt_timer > 0.0 else Color.WHITE
	draw_set_transform(jump_offset, 0.0, Vector2(facing, 1.0))
	draw_texture_rect_region(hero_sprite_sheet, target_rect, source_rect, tint_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if weapon_hits > 0 and equipped_weapon != null and equipped_weapon.kind == WeaponDefinitionScript.WeaponKind.MELEE:
		draw_line(jump_offset + Vector2(22*facing,-62), jump_offset + Vector2(63*facing,-73), Color("#e8eee4"), 8)
		draw_line(jump_offset + Vector2(56*facing,-71), jump_offset + Vector2(69*facing,-82), Color("#7c382c"), 6)
	elif weapon_hits > 0 and equipped_weapon != null and equipped_weapon.kind == WeaponDefinitionScript.WeaponKind.FIREARM:
		draw_line(jump_offset + Vector2(18*facing,-61), jump_offset + Vector2(47*facing,-61), Color("#c6d0d5"), 10)
		draw_line(jump_offset + Vector2(24*facing,-58), jump_offset + Vector2(20*facing,-47), Color("#6b4637"), 7)
	elif weapon_hits > 0 and equipped_weapon != null:
		draw_circle(jump_offset + Vector2(26*facing,-57), 9.0, equipped_weapon.color)
	if special_timer > 0.0:
		var special_color := Color("#82e8ff") if current_attack != null and current_attack.attack_id == &"player_team_attack" else Color("#ffe37a")
		draw_arc(jump_offset + Vector2(0,-64), 76, 0, TAU, 32, special_color, 7)
	elif team_attack_charge_timer > 0.0:
		draw_arc(jump_offset + Vector2(0, -64), 64, -PI * 0.5, PI * 1.5, 32, Color("#82e8ff"), 4)

func _visual_frame() -> Vector2i:
	if victory_pose_phase > 0:
		return Vector2i(4 if victory_pose_phase == 1 else 5, 3)
	if is_defeated:
		return Vector2i(0, 3)
	if hurt_timer > 0.0:
		return Vector2i(4, 2)
	if special_timer > 0.0:
		return Vector2i(5, 1)
	if is_instance_valid(grabbed_enemy):
		return Vector2i(3, 2)
	if z_height > 12.0:
		if attack_timer > 0.0 and current_attack != null:
			if current_attack.attack_id == &"player_apex_attack":
				return Vector2i(1, 2)
			if current_attack.attack_id == &"player_dive_attack":
				return Vector2i(2, 2)
			return Vector2i(1, 2)
		return Vector2i(0, 2)
	if attack_timer > 0.0:
		if weapon_ammo > 0 and equipped_weapon != null:
			return Vector2i(
				2 if equipped_weapon.kind == WeaponDefinitionScript.WeaponKind.MELEE else 3,
				3
			)
		if current_attack != null and current_attack.attack_id == &"player_run_attack":
			return Vector2i(4, 1)
		if current_attack != null and current_attack.attack_id == &"player_command_attack":
			return Vector2i(4, 1)
		if combo_step == 1:
			return Vector2i(1 if attack_timer < 0.18 else 0, 1)
		if combo_step == 2:
			return Vector2i(2, 1)
		if combo_step == 4:
			return Vector2i(3, 1)
		return Vector2i(2, 1)
	if velocity.length() > 20.0:
		return Vector2i(2 + int(walk_phase) % 4, 0)
	return Vector2i(int(visual_clock * 2.0) % 2, 0)


func set_victory_pose(phase: int) -> void:
	victory_pose_phase = clampi(phase, 0, 2)
	queue_redraw()

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	draw_colored_polygon(pts, color)
