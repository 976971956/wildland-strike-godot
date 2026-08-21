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
const CLASH_IMPACT = preload("res://data/impacts/clash.tres")
const ENEMY_DEFINITIONS := {
	"grunt": preload("res://data/enemies/grunt.tres"),
	"brute": preload("res://data/enemies/brute.tres"),
	"raptor": preload("res://data/enemies/raptor.tres"),
	"hunter": preload("res://data/enemies/hunter.tres"),
	"boss": preload("res://data/enemies/boss.tres"),
}

enum BehaviorPhase {
	NEUTRAL,
	TELEGRAPH,
	BURST,
	EVADE,
	RECOVER,
}

var game: Node
var player: Node
var combat_target: Node
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
var throw_impact_profile: Resource = null
var throw_collision_targets := {}
var wall_collision_done := false
var last_hit_was_counter := false
var behavior_phase := BehaviorPhase.NEUTRAL
var behavior_timer := 0.0
var behavior_cooldown_timer := 0.0
var behavior_direction := Vector2.ZERO
var last_behavior_event: StringName = &"neutral"
var behavior_event_history: Array[StringName] = []
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
	combat_target = p_player
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
	else:
		_update_combat_target()
	if (
		hurt_timer <= 0.0
		and wake_up_timer <= 0.0
		and stun_timer <= 0.0
		and is_instance_valid(combat_target)
		and not combat_target.is_defeated
	):
		_think(delta)
	elif hurt_timer <= 0.0 and wake_up_timer <= 0.0 and stun_timer <= 0.0:
		velocity = Vector2.ZERO
	move_and_slide()
	_resolve_throw_collisions()
	position.y = clampf(position.y, 455.0, 665.0)
	position.x = clampf(position.x, 60.0, game.stage_limit + 80.0)
	walk_phase += velocity.length() * delta * 0.025
	_check_attack()
	_sync_fighter_state()
	queue_redraw()

func _think(delta: float) -> void:
	if not is_instance_valid(combat_target):
		velocity = Vector2.ZERO
		return
	var player_offset: Vector2 = combat_target.position - position
	facing = 1 if player_offset.x > 0 else -1
	behavior_cooldown_timer = maxf(0.0, behavior_cooldown_timer - delta)
	if attack_timer > 0.0:
		velocity = Vector2.ZERO
		return
	if behavior_phase != BehaviorPhase.NEUTRAL:
		_advance_behavior_phase(delta, player_offset)
		return
	match definition.behavior_kind:
		EnemyDefinitionScript.BehaviorKind.CHARGER:
			_think_charger(player_offset)
		EnemyDefinitionScript.BehaviorKind.POUNCER:
			_think_pouncer(player_offset)
		EnemyDefinitionScript.BehaviorKind.PRESSURE:
			_think_pressure(player_offset)
		EnemyDefinitionScript.BehaviorKind.RANGED:
			_think_ranged(player_offset)
		_:
			_think_flanker(player_offset)


func _think_flanker(player_offset: Vector2) -> void:
	if _try_start_contact_attack(player_offset):
		return
	_approach_player(player_offset, true)


func _think_charger(player_offset: Vector2) -> void:
	if _try_start_contact_attack(player_offset):
		return
	var x_dist := absf(player_offset.x)
	if (
		behavior_cooldown_timer <= 0.0
		and x_dist >= definition.burst_min_distance
		and x_dist <= definition.burst_max_distance
		and absf(player_offset.y) <= definition.lane_tolerance
	):
		_begin_telegraph(Vector2(signf(player_offset.x), 0.0), &"charge_telegraph")
		return
	_approach_player(player_offset, true)


func _think_pouncer(player_offset: Vector2) -> void:
	var distance := player_offset.length()
	if behavior_cooldown_timer <= 0.0 and distance < definition.retreat_distance:
		_begin_evade(player_offset)
		return
	if _try_start_contact_attack(player_offset):
		return
	if (
		behavior_cooldown_timer <= 0.0
		and distance >= definition.burst_min_distance
		and distance <= definition.burst_max_distance
		and absf(player_offset.y) <= definition.lane_tolerance * 1.45
	):
		_begin_telegraph(player_offset.normalized(), &"pounce_telegraph")
		return
	_approach_player(player_offset, false)


func _think_pressure(player_offset: Vector2) -> void:
	if _try_start_contact_attack(player_offset):
		return
	_approach_player(player_offset, false)


func _think_ranged(player_offset: Vector2) -> void:
	var x_distance := absf(player_offset.x)
	var lane_distance := absf(player_offset.y)
	if x_distance < definition.preferred_range_min:
		var escape := Vector2(-signf(player_offset.x), signf(player_offset.y) * 0.35).normalized()
		velocity = escape * speed
		_record_behavior_event(&"range_retreat")
		return
	if x_distance > definition.preferred_range_max or lane_distance > definition.lane_tolerance:
		_approach_player(player_offset, false)
		return
	if behavior_cooldown_timer <= 0.0:
		_begin_telegraph(Vector2(signf(player_offset.x), 0.0), &"ranged_aim")
		return
	velocity = Vector2.ZERO


func _try_start_contact_attack(player_offset: Vector2) -> bool:
	if absf(player_offset.x) >= definition.attack_distance or absf(player_offset.y) >= definition.lane_tolerance:
		return false
	_start_attack()
	return true


func _start_attack() -> void:
	attack_timer = current_attack.duration
	attack_hit_done = false
	state_machine.transition(FighterStateMachineScript.State.ATTACK)
	attack_hitbox.configure_circle(current_attack.circle_radius, facing)
	velocity = Vector2.ZERO
	game.play_sfx(current_attack.sound_event)
	_record_behavior_event(&"attack")


func _approach_player(player_offset: Vector2, use_lane_offset: bool) -> void:
	var offset := player_offset
	if use_lane_offset:
		offset.y += approach_lane_offset
	var target := Vector2.ZERO
	if absf(player_offset.x) > definition.attack_distance * 0.78:
		target.x = signf(offset.x)
	if absf(offset.y) > definition.lane_tolerance * 0.5:
		target.y = signf(offset.y) * definition.vertical_approach_scale
	var desired_velocity := target.normalized() * speed
	var separation := _enemy_separation()
	if separation != Vector2.ZERO:
		desired_velocity += separation * speed * 0.92
	velocity = desired_velocity.limit_length(speed)


func _begin_telegraph(direction: Vector2, event: StringName) -> void:
	behavior_phase = BehaviorPhase.TELEGRAPH
	behavior_timer = definition.telegraph_duration
	behavior_direction = direction if direction != Vector2.ZERO else Vector2(facing, 0.0)
	facing = 1 if behavior_direction.x >= 0.0 else -1
	velocity = Vector2.ZERO
	_record_behavior_event(event)
	queue_redraw()


func _begin_burst() -> void:
	behavior_phase = BehaviorPhase.BURST
	behavior_timer = definition.burst_duration
	velocity = behavior_direction * speed * definition.burst_speed_scale
	_record_behavior_event(
		&"charge_burst"
		if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.CHARGER
		else &"pounce_burst"
	)
	queue_redraw()


func _begin_evade(player_offset: Vector2) -> void:
	behavior_phase = BehaviorPhase.EVADE
	behavior_timer = definition.retreat_duration
	var vertical_side := -1.0 if approach_lane_offset <= 0.0 else 1.0
	behavior_direction = Vector2(-signf(player_offset.x), vertical_side * 0.7).normalized()
	velocity = behavior_direction * speed * 1.18
	_record_behavior_event(&"retreat")
	queue_redraw()


func _begin_recovery() -> void:
	behavior_phase = BehaviorPhase.RECOVER
	behavior_timer = definition.recovery_duration
	velocity = Vector2.ZERO
	_record_behavior_event(&"recovery")
	queue_redraw()


func _advance_behavior_phase(delta: float, player_offset: Vector2) -> void:
	behavior_timer = maxf(0.0, behavior_timer - delta)
	match behavior_phase:
		BehaviorPhase.TELEGRAPH:
			velocity = Vector2.ZERO
			if behavior_timer <= 0.0:
				if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.RANGED:
					_fire_ranged_weapon()
				else:
					_begin_burst()
		BehaviorPhase.BURST:
			facing = 1 if behavior_direction.x >= 0.0 else -1
			velocity = behavior_direction * speed * definition.burst_speed_scale
			if _try_start_contact_attack(player_offset):
				_begin_recovery()
			elif behavior_timer <= 0.0:
				_begin_recovery()
		BehaviorPhase.EVADE:
			velocity = behavior_direction * speed * 1.18
			if behavior_timer <= 0.0:
				_begin_recovery()
		BehaviorPhase.RECOVER:
			velocity = Vector2.ZERO
			if behavior_timer <= 0.0:
				behavior_phase = BehaviorPhase.NEUTRAL
				behavior_cooldown_timer = definition.behavior_cooldown
				_record_behavior_event(&"ready")
				queue_redraw()


func _fire_ranged_weapon() -> void:
	game.spawn_weapon_projectile(
		self,
		definition.ranged_weapon,
		&"enemy",
		position + Vector2(facing * 34.0, 0.0),
		facing,
		combat_target
	)
	game.play_sfx(definition.ranged_weapon.fire_sfx)
	_record_behavior_event(&"ranged_fire")
	_begin_recovery()


func _cancel_behavior() -> void:
	behavior_phase = BehaviorPhase.NEUTRAL
	behavior_timer = 0.0
	behavior_direction = Vector2.ZERO
	velocity = Vector2.ZERO


func _record_behavior_event(event: StringName) -> void:
	last_behavior_event = event
	behavior_event_history.append(event)
	if behavior_event_history.size() > 16:
		behavior_event_history.pop_front()


func _update_combat_target() -> void:
	var candidates: Array[Node] = []
	if is_instance_valid(player) and not player.is_defeated:
		candidates.append(player)
	for other in get_tree().get_nodes_in_group("enemies"):
		if (
			other == self
			or not is_instance_valid(other)
			or other.is_defeated
			or other.grabbed
			or other.definition.faction == definition.faction
			or position.distance_to(other.position) > definition.opposing_faction_target_radius
		):
			continue
		candidates.append(other)
	if candidates.is_empty():
		combat_target = null
		return
	var best_target: Node = candidates[0]
	var best_distance: float = position.distance_to(best_target.position)
	for candidate in candidates:
		var candidate_distance: float = position.distance_to(candidate.position)
		if candidate_distance < best_distance:
			best_target = candidate
			best_distance = candidate_distance
	if is_instance_valid(combat_target) and candidates.has(combat_target):
		var current_distance: float = position.distance_to(combat_target.position)
		if current_distance <= best_distance + 64.0:
			return
	if combat_target != best_target:
		combat_target = best_target
		_cancel_behavior()
		_record_behavior_event(&"target_player" if best_target == player else &"target_enemy")

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
	if attack_timer <= 0.0 or attack_hit_done or not is_instance_valid(combat_target):
		return
	if attack_timer < current_attack.hit_trigger_remaining:
		attack_hit_done = true
		if attack_hitbox.overlaps(combat_target.hurtbox):
			var priority_outcome: int = AttackPriorityRulesScript.resolve(current_attack, combat_target)
			if not AttackPriorityRulesScript.allows_hit(priority_outcome):
				game.hit_confirm((position + combat_target.position) * 0.5 - Vector2(0, 45), 1, facing, false, CLASH_IMPACT)
				lose_priority_clash()
				return
			var counter_hit: bool = (
				priority_outcome == AttackPriorityRulesScript.Outcome.WIN
				and CounterHitRulesScript.is_counterable(combat_target)
			)
			var resolved_damage: int = CounterHitRulesScript.damage_for(current_attack, counter_hit)
			var resolved_knockback: Vector2 = CounterHitRulesScript.knockback_for(current_attack, facing, counter_hit)
			var stun_bonus: float = CounterHitRulesScript.stun_bonus_for(current_attack, counter_hit)
			var force_interrupt: bool = AttackPriorityRulesScript.interrupts_defender(priority_outcome)
			if combat_target == player:
				player.take_hit(
					resolved_damage,
					resolved_knockback,
					counter_hit,
					stun_bonus,
					force_interrupt,
					current_attack.impact_profile
				)
			else:
				var target_health_before: int = combat_target.health
				combat_target.take_hit(
					resolved_damage,
					resolved_knockback,
					current_attack.launch,
					counter_hit,
					stun_bonus,
					force_interrupt
				)
				if combat_target.health < target_health_before:
					game.hit_confirm(
						combat_target.position - Vector2(0.0, 48.0),
						current_attack.impact_strength,
						facing,
						true,
						current_attack.impact_profile
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
	_cancel_behavior()
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
	_cancel_behavior()
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
	_cancel_behavior()
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


func thrown(damage: int, force: Vector2, collision_damage: int, impact_profile: Resource = null) -> void:
	release_grab()
	invulnerable = 0.0
	throw_collision_active = collision_damage > 0
	throw_collision_damage = collision_damage
	throw_impact_profile = impact_profile
	throw_collision_targets.clear()
	wall_collision_done = false
	take_hit(damage, force, true)


func lose_priority_clash() -> void:
	_cancel_behavior()
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
			game.hit_confirm(position - Vector2(0, 46), 3, impact_direction, true, throw_impact_profile)
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
			game.hit_confirm(
				(position + other.position) * 0.5 - Vector2(0, 48),
				3,
				impact_direction,
				true,
				throw_impact_profile
			)
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
	_draw_behavior_cue()
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
	var tint_color: Color = Color.WHITE if flash_timer > 0.0 else (definition.hurt_tint if hurt_timer > 0.0 else definition.tint)
	# Enemy source art faces left, opposite to the player sheet.
	draw_set_transform(Vector2(recoil_offset, impact_squash * 18.0), 0.0, Vector2(-facing * (1.0 + impact_squash), 1.0 - impact_squash))
	draw_texture_rect_region(definition.sprite_sheet, target_rect, source_rect, tint_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.RANGED and not is_defeated:
		draw_line(Vector2(facing * 15.0, -57.0), Vector2(facing * 44.0, -57.0), Color("#b9c6ca"), 9.0)
		draw_line(Vector2(facing * 20.0, -53.0), Vector2(facing * 17.0, -44.0), Color("#624438"), 6.0)
	if definition.show_health_bar and health > 0:
		draw_rect(Rect2(-31,-170,62,6), Color("#351f28"))
		draw_rect(Rect2(-31,-170,62.0*health/max_health,6), Color("#f06454"))


func _draw_behavior_cue() -> void:
	if behavior_phase != BehaviorPhase.TELEGRAPH:
		return
	var pulse := 0.72 + sin(Time.get_ticks_msec() * 0.028) * 0.18
	var cue_color := Color(1.0, 0.47, 0.16, pulse)
	if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.POUNCER:
		cue_color = Color(0.62, 0.95, 0.28, pulse)
	elif definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.RANGED:
		cue_color = Color(1.0, 0.82, 0.25, pulse)
	draw_arc(Vector2(0.0, -12.0), 37.0, 0.0, TAU, 28, cue_color, 4.0)
	if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.CHARGER:
		draw_line(Vector2(facing * 22.0, -12.0), Vector2(facing * 92.0, -12.0), cue_color, 5.0)
	elif definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.RANGED:
		draw_line(Vector2(facing * 18.0, -48.0), Vector2(facing * 150.0, -48.0), cue_color, 3.0)

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
	var tint_color: Color = Color.WHITE if flash_timer > 0.0 else (definition.hurt_tint if hurt_timer > 0.0 else definition.tint)
	draw_set_transform(Vector2(recoil_offset, impact_squash * 18.0), 0.0, Vector2(-facing * (1.0 + impact_squash), 1.0 - impact_squash))
	draw_texture_rect_region(definition.sprite_sheet, target_rect, source_rect, tint_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	draw_colored_polygon(pts, color)
