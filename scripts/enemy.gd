class_name StreetEnemy
extends CharacterBody2D

const FighterStateMachineScript = preload("res://actors/fighters/fighter_state_machine.gd")
const HurtboxScript = preload("res://core/combat/combat_hurtbox.gd")
const HitboxScript = preload("res://core/combat/combat_hitbox.gd")
const CounterHitRulesScript = preload("res://core/combat/counter_hit_rules.gd")
const AttackPriorityRulesScript = preload("res://core/combat/attack_priority_rules.gd")
const EnemyDefinitionScript = preload("res://core/combat/enemy_definition.gd")
const MAX_CHAIN_HITS := 6
const CHAIN_RESET_DURATION := 0.85
const ENEMY_DEFINITIONS := {
	"grunt": preload("res://data/enemies/grunt.tres"),
	"brute": preload("res://data/enemies/brute.tres"),
	"raptor": preload("res://data/enemies/raptor.tres"),
	"boss": preload("res://data/enemies/boss.tres"),
}

var game: Node
var player: Node
var enemy_type := "grunt"
var definition: Resource
var max_health := 42
var health := 42
var speed := 115.0
var facing := -1
var attack_timer := 0.0
var hurt_timer := 0.0
var stun_timer := 0.0
var invulnerable := 0.0
var flash_timer := 0.0
var recoil_offset := 0.0
var impact_squash := 0.0
var attack_hit_done := false
var is_defeated := false
var grabbed := false
var grabbed_owner: Node = null
var fall_velocity := Vector2.ZERO
var death_timer := 0.0
var walk_phase := 0.0
var approach_lane_offset := 0.0
var knockdown_state := false
var wake_up_timer := 0.0
var chain_hit_count := 0
var chain_timer := 0.0
var hard_knockdown_lockout := false
var throw_collision_active := false
var throw_collision_damage := 0
var throw_collision_targets := {}
var wall_collision_done := false
var last_hit_was_counter := false
var state_machine = FighterStateMachineScript.new()
var hurtbox
var attack_hitbox
var current_attack
var fighter_state: int:
	get:
		return state_machine.current_state

func setup(p_game: Node, p_player: Node, p_type: String) -> void:
	game = p_game
	player = p_player
	definition = ENEMY_DEFINITIONS.get(p_type, ENEMY_DEFINITIONS["grunt"])
	enemy_type = String(definition.enemy_id)
	current_attack = definition.attack
	max_health = definition.max_health
	health = max_health
	speed = definition.speed
	scale = definition.actor_scale
	state_machine.force_transition(FighterStateMachineScript.State.IDLE)
	add_to_group("enemies")
	# Enemies collide with the player (layer 1), but not with one another.
	# Soft separation below keeps their spacing natural instead of making them
	# push each other around as one joined body.
	collision_layer = 2
	collision_mask = 1
	approach_lane_offset = float(posmod(int(get_instance_id()), 5) - 2) * 9.0
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 17.0
	capsule.height = 46.0
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
	z_index = int(position.y)
	if is_defeated:
		state_machine.transition(FighterStateMachineScript.State.DEFEATED)
		death_timer -= delta
		position += fall_velocity * delta
		fall_velocity = fall_velocity.move_toward(Vector2.ZERO, 330.0 * delta)
		modulate.a = clampf(death_timer * 2.0, 0.0, 1.0)
		if death_timer <= 0.0:
			game.enemy_removed(self)
			queue_free()
		queue_redraw()
		return
	if grabbed:
		state_machine.transition(FighterStateMachineScript.State.GRABBED)
		if not is_instance_valid(grabbed_owner):
			release_grab()
		else:
			position = grabbed_owner.position + Vector2(grabbed_owner.facing * 31.0, 1.0)
			facing = -grabbed_owner.facing
			queue_redraw()
			return
	attack_timer = maxf(0.0, attack_timer - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	stun_timer = maxf(0.0, stun_timer - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	chain_timer = maxf(0.0, chain_timer - delta)
	if chain_timer <= 0.0 and not hard_knockdown_lockout:
		chain_hit_count = 0
	if knockdown_state and hurt_timer <= 0.0:
		knockdown_state = false
		wake_up_timer = 0.38
		invulnerable = maxf(invulnerable, wake_up_timer)
	elif wake_up_timer > 0.0:
		wake_up_timer = maxf(0.0, wake_up_timer - delta)
		if wake_up_timer <= 0.0:
			hard_knockdown_lockout = false
			chain_hit_count = 0
			chain_timer = 0.0
			throw_collision_active = false
	flash_timer = maxf(0.0, flash_timer - delta)
	recoil_offset = move_toward(recoil_offset, 0.0, 95.0 * delta)
	impact_squash = move_toward(impact_squash, 0.0, 5.5 * delta)
	if hurt_timer > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	elif wake_up_timer > 0.0:
		velocity = Vector2.ZERO
	elif stun_timer > 0.0:
		velocity = Vector2.ZERO
	elif is_instance_valid(player) and not player.is_defeated:
		_think(delta)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	_resolve_throw_collisions()
	position.y = clampf(position.y, 455.0, 665.0)
	position.x = clampf(position.x, 60.0, game.stage_limit + 80.0)
	walk_phase += velocity.length() * delta * 0.025
	_check_attack()
	_sync_fighter_state()
	queue_redraw()

func _think(_delta: float) -> void:
	var player_offset: Vector2 = player.position - position
	var offset: Vector2 = player.position + Vector2(0.0, approach_lane_offset) - position
	facing = 1 if player_offset.x > 0 else -1
	var y_dist := absf(player_offset.y)
	var lane_y_dist := absf(offset.y)
	var x_dist := absf(player_offset.x)
	if attack_timer > 0.0:
		velocity = Vector2.ZERO
		return
	if x_dist < 62.0 and y_dist < 36.0:
		attack_timer = current_attack.duration
		attack_hit_done = false
		state_machine.transition(FighterStateMachineScript.State.ATTACK)
		attack_hitbox.configure_circle(current_attack.circle_radius, facing)
		velocity = Vector2.ZERO
		game.play_sfx(current_attack.sound_event)
		return
	var target := Vector2.ZERO
	if x_dist > 48.0:
		target.x = signf(offset.x)
	if lane_y_dist > 18.0:
		target.y = signf(offset.y) * 0.72
	var desired_velocity := target.normalized() * speed
	var separation := _enemy_separation()
	if separation != Vector2.ZERO:
		desired_velocity += separation * speed * 0.92
	velocity = desired_velocity.limit_length(speed)

func _enemy_separation() -> Vector2:
	var separation := Vector2.ZERO
	const COMFORT_DISTANCE := 58.0
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other) or other.is_defeated or other.grabbed:
			continue
		var away: Vector2 = position - other.position
		var distance := away.length()
		if distance >= COMFORT_DISTANCE:
			continue
		if distance < 0.01:
			var side := -1.0 if get_instance_id() < other.get_instance_id() else 1.0
			away = Vector2(0.35, side)
			distance = 1.0
		# Favor vertical spreading so enemies still approach from both sides
		# without stacking their sprites on the same depth lane.
		away = Vector2(away.x * 0.48, away.y * 1.35).normalized()
		separation += away * (1.0 - distance / COMFORT_DISTANCE)
	return separation.limit_length(1.0)

func _check_attack() -> void:
	if attack_timer <= 0.0 or attack_hit_done or not is_instance_valid(player):
		return
	if attack_timer < current_attack.hit_trigger_remaining:
		attack_hit_done = true
		if attack_hitbox.overlaps(player.hurtbox):
			var priority_outcome: int = AttackPriorityRulesScript.resolve(current_attack, player)
			if not AttackPriorityRulesScript.allows_hit(priority_outcome):
				game.hit_confirm((position + player.position) * 0.5 - Vector2(0, 45), 1, facing, false)
				lose_priority_clash()
				return
			var counter_hit: bool = (
				priority_outcome == AttackPriorityRulesScript.Outcome.WIN
				and CounterHitRulesScript.is_counterable(player)
			)
			player.take_hit(
				CounterHitRulesScript.damage_for(current_attack, counter_hit),
				CounterHitRulesScript.knockback_for(current_attack, facing, counter_hit),
				counter_hit,
				CounterHitRulesScript.stun_bonus_for(current_attack, counter_hit),
				AttackPriorityRulesScript.interrupts_defender(priority_outcome)
			)
		attack_hitbox.deactivate()

func take_hit(
	amount: int,
	knockback: Vector2,
	launch: bool,
	counter_hit := false,
	counter_stun_bonus := 0.0,
	force_interrupt := false
) -> void:
	if is_defeated or invulnerable > 0.0 or hard_knockdown_lockout:
		return
	_register_chain_hit()
	if chain_hit_count >= MAX_CHAIN_HITS:
		launch = true
		hard_knockdown_lockout = true
		knockback.y = minf(knockback.y, -45.0)
	health -= amount
	last_hit_was_counter = counter_hit
	if counter_hit or launch or force_interrupt:
		attack_timer = 0.0
		attack_hit_done = true
		attack_hitbox.deactivate()
	hurt_timer = (0.25 if not launch else 0.46) + counter_stun_bonus
	stun_timer = hurt_timer
	velocity = knockback
	invulnerable = 0.08
	flash_timer = 0.075 if not launch else 0.13
	recoil_offset = signf(knockback.x) * (8.0 if not launch else 15.0)
	impact_squash = 0.16 if not launch else 0.28
	knockdown_state = launch
	wake_up_timer = 0.0
	state_machine.transition(
		FighterStateMachineScript.State.KNOCKDOWN if launch else FighterStateMachineScript.State.HURT
	)
	if launch:
		velocity = knockback
	if definition.is_boss:
		game.boss_health_changed(health, max_health)
	if health <= 0:
		_die(knockback)
	queue_redraw()

func _die(knockback: Vector2) -> void:
	is_defeated = true
	attack_hitbox.deactivate()
	throw_collision_active = false
	state_machine.transition(FighterStateMachineScript.State.DEFEATED)
	grabbed = false
	remove_from_group("enemies")
	death_timer = 0.75
	fall_velocity = knockback * 0.72
	game.add_score(definition.defeat_score)
	game.play_sfx("enemy_down")

func can_be_grabbed() -> bool:
	return (
		definition.can_be_grabbed
		and not is_defeated
		and not grabbed
		and not hard_knockdown_lockout
		and hurt_timer <= 0.0
		and wake_up_timer <= 0.0
	)

func grabbed_by(owner: Node) -> void:
	grabbed = true
	grabbed_owner = owner
	velocity = Vector2.ZERO
	hurt_timer = 0.0
	invulnerable = 0.0
	knockdown_state = false
	wake_up_timer = 0.0
	throw_collision_active = false
	stun_timer = 2.0
	state_machine.transition(FighterStateMachineScript.State.GRABBED)
	attack_hitbox.deactivate()

func release_grab() -> void:
	grabbed = false
	grabbed_owner = null
	stun_timer = 0.25
	state_machine.transition(FighterStateMachineScript.State.STUN)

func take_grab_strike(amount: int, force: Vector2) -> void:
	if not grabbed or is_defeated:
		return
	_register_chain_hit()
	health -= amount
	velocity = force
	flash_timer = 0.09
	recoil_offset = signf(force.x) * 8.0
	impact_squash = 0.18
	if definition.is_boss:
		game.boss_health_changed(health, max_health)
	if health <= 0:
		_die(force)
	else:
		state_machine.transition(FighterStateMachineScript.State.GRABBED)
	queue_redraw()


func thrown(damage: int, force: Vector2, collision_damage: int) -> void:
	release_grab()
	invulnerable = 0.0
	throw_collision_active = collision_damage > 0
	throw_collision_damage = collision_damage
	throw_collision_targets.clear()
	wall_collision_done = false
	take_hit(damage, force, true)


func lose_priority_clash() -> void:
	attack_timer = 0.0
	attack_hit_done = true
	attack_hitbox.deactivate()
	stun_timer = maxf(stun_timer, 0.12)
	velocity = Vector2(-facing * 65.0, 0.0)
	state_machine.transition(FighterStateMachineScript.State.STUN)
	queue_redraw()


func _register_chain_hit() -> void:
	chain_hit_count = chain_hit_count + 1 if chain_timer > 0.0 else 1
	chain_timer = CHAIN_RESET_DURATION


func _resolve_throw_collisions() -> void:
	if not throw_collision_active or is_defeated:
		return
	if not knockdown_state or hurt_timer <= 0.0:
		throw_collision_active = false
		return
	var minimum_x := 60.0
	var maximum_x: float = game.stage_limit + 80.0
	if not wall_collision_done and (position.x <= minimum_x or position.x >= maximum_x):
		wall_collision_done = true
		throw_collision_active = false
		var impact_direction := 1 if velocity.x >= 0.0 else -1
		position.x = clampf(position.x, minimum_x, maximum_x)
		velocity.x *= -0.32
		hurt_timer = maxf(hurt_timer, 0.28)
		stun_timer = maxf(stun_timer, hurt_timer)
		_apply_environment_collision_damage(throw_collision_damage, Vector2(impact_direction * 180.0, -35.0))
		if not is_defeated:
			game.hit_confirm(position - Vector2(0, 46), 3, impact_direction)
		return
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other) or other.is_defeated or other.grabbed:
			continue
		var other_id: int = other.get_instance_id()
		if throw_collision_targets.has(other_id):
			continue
		if absf(position.y - other.position.y) > 32.0 or position.distance_to(other.position) > 48.0:
			continue
		var impact_direction := 1 if velocity.x >= 0.0 else -1
		var health_before: int = other.health
		other.take_hit(
			throw_collision_damage,
			Vector2(impact_direction * 360.0, -45.0),
			true,
			false,
			0.0,
			true
		)
		throw_collision_targets[other_id] = true
		if other.health < health_before:
			throw_collision_active = false
			velocity.x *= 0.45
			game.hit_confirm((position + other.position) * 0.5 - Vector2(0, 48), 3, impact_direction)
		return


func _apply_environment_collision_damage(amount: int, force: Vector2) -> void:
	if amount <= 0 or is_defeated:
		return
	health -= amount
	flash_timer = 0.13
	recoil_offset = signf(force.x) * 15.0
	impact_squash = 0.28
	if definition.is_boss:
		game.boss_health_changed(health, max_health)
	if health <= 0:
		_die(force)
	queue_redraw()


func _sync_fighter_state() -> void:
	var next_state := FighterStateMachineScript.State.IDLE
	if is_defeated:
		next_state = FighterStateMachineScript.State.DEFEATED
	elif grabbed:
		next_state = FighterStateMachineScript.State.GRABBED
	elif hurt_timer > 0.0:
		next_state = (
			FighterStateMachineScript.State.KNOCKDOWN
			if knockdown_state
			else FighterStateMachineScript.State.HURT
		)
	elif wake_up_timer > 0.0:
		next_state = FighterStateMachineScript.State.GET_UP
	elif stun_timer > 0.0:
		next_state = FighterStateMachineScript.State.STUN
	elif attack_timer > 0.0:
		next_state = FighterStateMachineScript.State.ATTACK
	elif velocity.length() > 10.0:
		next_state = FighterStateMachineScript.State.MOVE
	state_machine.transition(next_state)

func _draw() -> void:
	if definition.visual_kind == EnemyDefinitionScript.VisualKind.RAPTOR:
		_draw_raptor()
		return
	var body_scale: float = definition.body_scale
	_draw_oval(
		Vector2(0, 2),
		definition.shadow_half_extents.x * body_scale,
		definition.shadow_half_extents.y,
		Color(0.02, 0.03, 0.04, 0.42)
	)
	var column := 0
	if is_defeated or hurt_timer > 0.0:
		column = 3
	elif attack_timer > 0.0:
		column = 2
	elif velocity.length() > 10.0:
		column = 1 if int(walk_phase) % 2 == 0 else 0
	var cell := Vector2(
		definition.sprite_sheet.get_width() / float(definition.sprite_columns),
		definition.sprite_sheet.get_height() / float(definition.sprite_rows)
	)
	var target_size: Vector2 = definition.target_size * body_scale
	var target_rect := Rect2(
		-target_size.x * 0.5,
		-target_size.y + definition.target_bottom_offset,
		target_size.x,
		target_size.y
	)
	var source_rect := Rect2(column * cell.x, definition.sprite_row * cell.y, cell.x, cell.y)
	var tint_color: Color = Color.WHITE if flash_timer > 0.0 else (definition.hurt_tint if hurt_timer > 0.0 else Color.WHITE)
	# Enemy source art faces left, opposite to the player sheet.
	draw_set_transform(Vector2(recoil_offset, impact_squash * 18.0), 0.0, Vector2(-facing * (1.0 + impact_squash), 1.0 - impact_squash))
	draw_texture_rect_region(definition.sprite_sheet, target_rect, source_rect, tint_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if definition.show_health_bar and health > 0:
		draw_rect(Rect2(-31,-170,62,6), Color("#351f28"))
		draw_rect(Rect2(-31,-170,62.0*health/max_health,6), Color("#f06454"))

func _draw_raptor() -> void:
	_draw_oval(
		Vector2(0, 2),
		definition.shadow_half_extents.x,
		definition.shadow_half_extents.y,
		Color(0.02, 0.03, 0.04, 0.44)
	)
	var column := 0
	if is_defeated or hurt_timer > 0.0:
		column = 3
	elif attack_timer > 0.0:
		column = 2
	elif velocity.length() > 10.0:
		column = 1 if int(walk_phase) % 2 == 0 else 0
	var cell := Vector2(
		definition.sprite_sheet.get_width() / float(definition.sprite_columns),
		definition.sprite_sheet.get_height() / float(definition.sprite_rows)
	)
	var source_rect := Rect2(column * cell.x, definition.sprite_row * cell.y, cell.x, cell.y)
	var target_size: Vector2 = definition.target_size
	var target_rect := Rect2(
		-target_size.x * 0.5,
		-target_size.y + definition.target_bottom_offset,
		target_size.x,
		target_size.y
	)
	var tint_color: Color = Color.WHITE if flash_timer > 0.0 else (definition.hurt_tint if hurt_timer > 0.0 else Color.WHITE)
	draw_set_transform(Vector2(recoil_offset, impact_squash * 18.0), 0.0, Vector2(-facing * (1.0 + impact_squash), 1.0 - impact_squash))
	draw_texture_rect_region(definition.sprite_sheet, target_rect, source_rect, tint_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	draw_colored_polygon(pts, color)
