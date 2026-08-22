class_name StreetEnemy
extends CharacterBody2D

const FighterStateMachineScript = preload("res://actors/fighters/fighter_state_machine.gd")
const HurtboxScript = preload("res://core/combat/combat_hurtbox.gd")
const HitboxScript = preload("res://core/combat/combat_hitbox.gd")
const CounterHitRulesScript = preload("res://core/combat/counter_hit_rules.gd")
const AttackPriorityRulesScript = preload("res://core/combat/attack_priority_rules.gd")
const EnemyDefinitionScript = preload("res://core/combat/enemy_definition.gd")
const BossPhaseDataScript = preload("res://core/combat/boss_phase_data.gd")
const MAX_CHAIN_HITS := 6
const CHAIN_RESET_DURATION := 0.85
const FORMATION_LANES := [0.0, -1.0, 1.0, -2.0, 2.0, -3.0, 3.0]
const FORMATION_LANE_SPACING := 36.0
const SEPARATION_DISTANCE := 92.0
const MIN_ENEMY_CENTER_DISTANCE := 56.0
const CLASH_IMPACT = preload("res://data/impacts/clash.tres")
const ENEMY_DEFINITIONS := {
	"grunt": preload("res://data/enemies/grunt.tres"),
	"brute": preload("res://data/enemies/brute.tres"),
	"raptor": preload("res://data/enemies/raptor.tres"),
	"compy": preload("res://data/enemies/compy.tres"),
	"ankylosaur": preload("res://data/enemies/ankylosaur.tres"),
	"triceratops": preload("res://data/enemies/triceratops.tres"),
	"hunter": preload("res://data/enemies/hunter.tres"),
	"knife_raider": preload("res://data/enemies/knife_raider.tres"),
	"demolitionist": preload("res://data/enemies/demolitionist.tres"),
	"shield_guard": preload("res://data/enemies/shield_guard.tres"),
	"elite_enforcer": preload("res://data/enemies/elite_enforcer.tres"),
	"elite_blade": preload("res://data/enemies/elite_blade.tres"),
	"elite_bombardier": preload("res://data/enemies/elite_bombardier.tres"),
	"elite_bulwark": preload("res://data/enemies/elite_bulwark.tres"),
	"boss": preload("res://data/enemies/boss.tres"),
	"mirewarden": preload("res://data/enemies/mirewarden.tres"),
	"iron_vulture": preload("res://data/enemies/iron_vulture.tres"),
	"forge_regent": preload("res://data/enemies/forge_regent.tres"),
	"cinder_matriarch": preload("res://data/enemies/cinder_matriarch.tres"),
	"titan_warden": preload("res://data/enemies/titan_warden.tres"),
	"vault_sentinel_orin": preload("res://data/enemies/vault_sentinel_orin.tres"),
	"vault_sentinel_nyx": preload("res://data/enemies/vault_sentinel_nyx.tres"),
}

enum BehaviorPhase {
	NEUTRAL,
	TELEGRAPH,
	BURST,
	EVADE,
	RECOVER,
}

enum CreatureState {
	NONE,
	NEUTRAL,
	SLEEPING,
	ENRAGED,
}

var game: Node
var player: Node
var combat_target: Node
var combat_team: StringName = &"human_enemies"
var combat_owner_id := -1
var health_scale_snapshot := 1.0
var damage_scale_snapshot := 1.0
var source_power_scale_snapshot := 1.0
var enemy_type := "grunt"
var definition: Resource
var max_health := 42
var health := 42
var speed := 115.0
var base_speed := 115.0
var creature_state := CreatureState.NONE
var knockdown_armor_remaining := 0
var guard_points := 0
var guard_recovery_timer := 0.0
var guard_flash_timer := 0.0
var last_guarded_damage := 0
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
var visual_clock := 0.0
var approach_lane_offset := 0.0
var formation_slot := 0
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
var boss_phase_index := -1
var current_boss_phase: Resource = null
var boss_transition_timer := 0.0
var boss_special_pose_timer := 0.0
var boss_special_pose_column := -1
var fighter_state: int:
	get:
		return state_machine.current_state

func setup(p_game: Node, p_player: Node, p_type: String, p_formation_slot: int = -1) -> void:
	game = p_game
	player = p_player
	combat_target = p_player
	definition = ENEMY_DEFINITIONS.get(p_type, ENEMY_DEFINITIONS["grunt"])
	enemy_type = String(definition.enemy_id)
	combat_team = &"neutral_creatures" if definition.faction == EnemyDefinitionScript.Faction.NEUTRAL_CREATURE else &"human_enemies"
	combat_owner_id = p_formation_slot if p_formation_slot >= 0 else int(get_instance_id())
	health_scale_snapshot = game.coop_enemy_health_scale() if game.has_method("coop_enemy_health_scale") else 1.0
	damage_scale_snapshot = game.coop_enemy_damage_scale() if game.has_method("coop_enemy_damage_scale") else 1.0
	source_power_scale_snapshot = definition.outgoing_damage_scale
	current_attack = definition.attack
	max_health = maxi(1, roundi(definition.max_health * health_scale_snapshot))
	health = max_health
	base_speed = definition.speed
	speed = base_speed
	knockdown_armor_remaining = definition.knockdown_armor
	guard_points = definition.guard_capacity
	if definition.dinosaur_archetype:
		creature_state = CreatureState.SLEEPING if definition.starts_sleeping else CreatureState.NEUTRAL
	scale = definition.actor_scale
	state_machine.force_transition(FighterStateMachineScript.State.IDLE)
	add_to_group("enemies")
	# Enemies collide with the player (layer 1), but not with one another.
	# Soft separation below keeps their spacing natural instead of making them
	# push each other around as one joined body.
	collision_layer = 2
	collision_mask = 1
	formation_slot = p_formation_slot if p_formation_slot >= 0 else posmod(int(get_instance_id()), FORMATION_LANES.size())
	approach_lane_offset = FORMATION_LANES[formation_slot % FORMATION_LANES.size()] * FORMATION_LANE_SPACING
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
	if definition.is_boss:
		boss_phase_index = 0
		_apply_boss_phase(false)
		game.boss_spawned(self, current_boss_phase)

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
	boss_transition_timer = maxf(0.0, boss_transition_timer - delta)
	boss_special_pose_timer = maxf(0.0, boss_special_pose_timer - delta)
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
	guard_flash_timer = maxf(0.0, guard_flash_timer - delta)
	if guard_points <= 0 and definition.guard_capacity > 0 and not is_defeated:
		guard_recovery_timer = maxf(0.0, guard_recovery_timer - delta)
		if guard_recovery_timer <= 0.0:
			guard_points = definition.guard_capacity
			_record_behavior_event(&"guard_restored")
	recoil_offset = move_toward(recoil_offset, 0.0, 95.0 * delta)
	impact_squash = move_toward(impact_squash, 0.0, 5.5 * delta)
	if hurt_timer > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	elif wake_up_timer > 0.0:
		velocity = Vector2.ZERO
	elif stun_timer > 0.0 or boss_transition_timer > 0.0:
		velocity = Vector2.ZERO
	elif creature_state == CreatureState.SLEEPING:
		_try_wake_from_proximity()
		velocity = Vector2.ZERO
		if creature_state != CreatureState.SLEEPING:
			_update_combat_target()
	else:
		_update_combat_target()
	if (
		hurt_timer <= 0.0
		and wake_up_timer <= 0.0
		and stun_timer <= 0.0
		and boss_transition_timer <= 0.0
		and creature_state != CreatureState.SLEEPING
		and is_instance_valid(combat_target)
		and not combat_target.is_defeated
	):
		_think(delta)
	elif hurt_timer <= 0.0 and wake_up_timer <= 0.0 and stun_timer <= 0.0 and boss_transition_timer <= 0.0:
		velocity = Vector2.ZERO
	move_and_slide()
	_resolve_visible_overlap()
	_resolve_throw_collisions()
	position.y = clampf(position.y, 455.0, 665.0)
	position.x = clampf(position.x, 60.0, game.stage_limit + 80.0)
	walk_phase += velocity.length() * delta * 0.025
	visual_clock += delta
	_check_attack()
	_sync_fighter_state()
	queue_redraw()

func _think(delta: float) -> void:
	if creature_state == CreatureState.SLEEPING:
		velocity = Vector2.ZERO
		return
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
		EnemyDefinitionScript.BehaviorKind.BOSS:
			_think_boss(player_offset)
		EnemyDefinitionScript.BehaviorKind.DUELIST:
			_think_duelist(player_offset)
		_:
			_think_flanker(player_offset)


func _try_wake_from_proximity() -> bool:
	if creature_state != CreatureState.SLEEPING:
		return false
	for candidate in _ecology_hostiles():
		if position.distance_to(candidate.position) <= definition.wake_radius:
			_wake_creature()
			return true
	return false


func _wake_creature() -> void:
	if creature_state != CreatureState.SLEEPING:
		return
	creature_state = CreatureState.NEUTRAL
	visual_clock = 0.0
	_record_behavior_event(&"creature_woke")
	game.play_sfx(&"dinosaur_wake")
	queue_redraw()


func _enrage_creature() -> void:
	if not definition.dinosaur_archetype or creature_state == CreatureState.ENRAGED:
		return
	if creature_state == CreatureState.SLEEPING:
		_wake_creature()
	creature_state = CreatureState.ENRAGED
	speed = base_speed * definition.enrage_speed_scale
	behavior_cooldown_timer = 0.0
	_record_behavior_event(&"creature_enraged")
	game.play_sfx(&"dinosaur_enrage")
	queue_redraw()


func _ecology_hostiles() -> Array[Node]:
	var candidates: Array[Node] = []
	if game != null and game.has_method("get_active_players"):
		for fighter in game.get_active_players():
			if is_instance_valid(fighter) and not fighter.is_defeated:
				candidates.append(fighter)
	for other in get_tree().get_nodes_in_group("enemies"):
		if (
			other != self
			and is_instance_valid(other)
			and not other.is_defeated
			and not other.grabbed
			and other.definition.faction != definition.faction
		):
			candidates.append(other)
	return candidates


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


func _think_duelist(player_offset: Vector2) -> void:
	var distance := player_offset.length()
	if behavior_cooldown_timer <= 0.0 and distance < definition.retreat_distance:
		_begin_duelist_evade(player_offset)
		return
	if _try_start_contact_attack(player_offset):
		return
	if (
		behavior_cooldown_timer <= 0.0
		and distance >= definition.burst_min_distance
		and distance <= definition.burst_max_distance
		and absf(player_offset.y) <= definition.lane_tolerance * 1.35
	):
		_begin_telegraph(player_offset.normalized(), &"duelist_feint")
		return
	_approach_player(player_offset, true)


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


func _think_boss(player_offset: Vector2) -> void:
	if current_boss_phase == null:
		_think_pressure(player_offset)
		return
	if _try_start_contact_attack(player_offset):
		return
	var distance := player_offset.length()
	if (
		behavior_cooldown_timer <= 0.0
		and distance >= current_boss_phase.special_min_distance
		and distance <= current_boss_phase.special_max_distance
		and absf(player_offset.y) <= definition.lane_tolerance * 1.45
	):
		_begin_telegraph(player_offset.normalized(), &"boss_special_telegraph")
		return
	_approach_player(player_offset, false)


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
		# Preserve the magnitude of each formation lane. A sign-only steer gives
		# two enemies on the same side identical velocities, which makes them
		# appear glued together even when soft separation is active.
		var lane_weight := clampf(absf(offset.y) / 96.0, 0.25, 1.0)
		target.y = signf(offset.y) * definition.vertical_approach_scale * lane_weight
	var desired_velocity := target.normalized() * speed
	var separation := _enemy_separation()
	if separation != Vector2.ZERO:
		# Separation breaks initial overlap, while the persistent formation lane
		# remains dominant so two agents do not swap into the same moving slot.
		desired_velocity += separation * speed * 0.72
	if use_lane_offset:
		var lane_correction := clampf(offset.y * 2.2, -speed * 0.9, speed * 0.9)
		desired_velocity.y += lane_correction
	velocity = desired_velocity.limit_length(speed)


func _begin_telegraph(direction: Vector2, event: StringName) -> void:
	behavior_phase = BehaviorPhase.TELEGRAPH
	behavior_timer = (
		current_boss_phase.telegraph_duration
		if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.BOSS
		else definition.telegraph_duration
	)
	behavior_direction = direction if direction != Vector2.ZERO else Vector2(facing, 0.0)
	facing = 1 if behavior_direction.x >= 0.0 else -1
	velocity = Vector2.ZERO
	_record_behavior_event(event)
	queue_redraw()


func _begin_burst() -> void:
	behavior_phase = BehaviorPhase.BURST
	behavior_timer = definition.burst_duration
	velocity = behavior_direction * speed * definition.burst_speed_scale
	var burst_event := &"pounce_burst"
	if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.CHARGER:
		burst_event = &"charge_burst"
	elif definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.DUELIST:
		burst_event = &"duelist_lunge"
	_record_behavior_event(burst_event)
	queue_redraw()


func _begin_evade(player_offset: Vector2) -> void:
	behavior_phase = BehaviorPhase.EVADE
	behavior_timer = definition.retreat_duration
	var vertical_side := -1.0 if approach_lane_offset <= 0.0 else 1.0
	behavior_direction = Vector2(-signf(player_offset.x), vertical_side * 0.7).normalized()
	velocity = behavior_direction * speed * 1.18
	_record_behavior_event(&"retreat")
	queue_redraw()


func _begin_duelist_evade(player_offset: Vector2) -> void:
	behavior_phase = BehaviorPhase.EVADE
	behavior_timer = definition.retreat_duration
	var vertical_side := -1.0 if approach_lane_offset <= 0.0 else 1.0
	behavior_direction = Vector2(-signf(player_offset.x), vertical_side).normalized()
	velocity = behavior_direction * speed * 1.32
	_record_behavior_event(&"duelist_disengage")
	queue_redraw()


func _begin_recovery() -> void:
	behavior_phase = BehaviorPhase.RECOVER
	behavior_timer = (
		current_boss_phase.recovery_duration
		if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.BOSS
		else definition.recovery_duration
	)
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
				elif definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.BOSS:
					_execute_boss_special()
				else:
					_begin_burst()
		BehaviorPhase.BURST:
			facing = 1 if behavior_direction.x >= 0.0 else -1
			var burst_scale: float = (
				current_boss_phase.burst_speed_scale
				if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.BOSS
				else definition.burst_speed_scale
			)
			velocity = behavior_direction * speed * burst_scale
			if _try_start_contact_attack(player_offset):
				_begin_recovery()
			elif behavior_timer <= 0.0:
				_begin_recovery()
		BehaviorPhase.EVADE:
			var evade_scale := 1.32 if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.DUELIST else 1.18
			velocity = behavior_direction * speed * evade_scale
			if behavior_timer <= 0.0:
				_begin_recovery()
		BehaviorPhase.RECOVER:
			velocity = Vector2.ZERO
			if behavior_timer <= 0.0:
				behavior_phase = BehaviorPhase.NEUTRAL
				behavior_cooldown_timer = (
					current_boss_phase.special_cooldown
					if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.BOSS
					else definition.behavior_cooldown
				)
				if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.BOSS:
					current_attack = current_boss_phase.attack
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


func _execute_boss_special() -> void:
	current_attack = current_boss_phase.special_attack
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.TIDAL_WAVE:
		game.spawn_tidal_wave(self, facing, current_attack.damage)
		game.play_sfx(&"water_surge")
		_record_behavior_event(&"boss_tidal_wave")
		_begin_recovery()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.RUSH:
		behavior_phase = BehaviorPhase.BURST
		behavior_timer = current_boss_phase.burst_duration
		velocity = behavior_direction * speed * current_boss_phase.burst_speed_scale
		_record_behavior_event(&"boss_rush")
		queue_redraw()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.ROAD_RAM:
		behavior_phase = BehaviorPhase.BURST
		behavior_timer = current_boss_phase.burst_duration
		velocity = behavior_direction * speed * current_boss_phase.burst_speed_scale
		_record_behavior_event(&"boss_road_ram")
		game.play_sfx(&"vehicle_ram")
		queue_redraw()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.MINE_DROP:
		game.spawn_road_mine(self, current_attack.damage)
		game.play_sfx(&"mine_drop")
		_record_behavior_event(&"boss_mine_drop")
		_begin_recovery()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.MAGNET_PULL:
		boss_special_pose_column = 4
		boss_special_pose_timer = current_boss_phase.recovery_duration
		game.apply_magnetic_pull(self, current_attack.damage, current_boss_phase.special_max_distance)
		_record_behavior_event(&"boss_magnet_pull")
		_begin_recovery()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.FURNACE_BLAST:
		boss_special_pose_column = 5
		boss_special_pose_timer = current_boss_phase.recovery_duration
		game.spawn_furnace_blast(self, current_attack.damage)
		_record_behavior_event(&"boss_furnace_blast")
		_begin_recovery()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.EMBER_SURGE:
		boss_special_pose_column = 4
		boss_special_pose_timer = current_boss_phase.recovery_duration
		game.spawn_furnace_blast(self, current_attack.damage)
		game.play_sfx(&"industrial_impact")
		_record_behavior_event(&"boss_ember_surge")
		_begin_recovery()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.CISTERN_BURST:
		boss_special_pose_column = 4
		boss_special_pose_timer = current_boss_phase.recovery_duration
		for direction in [-1, 1]:
			game.spawn_tidal_wave(self, direction, current_attack.damage)
		game.play_sfx(&"water_surge")
		_record_behavior_event(&"boss_cistern_burst")
		_begin_recovery()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.SEISMIC_FRACTURE:
		boss_special_pose_column = 4
		boss_special_pose_timer = current_boss_phase.recovery_duration
		game.spawn_seismic_fractures(self, current_attack.damage)
		_record_behavior_event(&"boss_seismic_fracture")
		_begin_recovery()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.TITAN_CALL:
		boss_special_pose_column = 4
		boss_special_pose_timer = current_boss_phase.recovery_duration
		game.spawn_seismic_fractures(self, current_attack.damage, true)
		_record_behavior_event(&"boss_titan_call")
		_begin_recovery()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.BARRIER_PULSE:
		boss_special_pose_column = 4
		boss_special_pose_timer = current_boss_phase.recovery_duration
		game.spawn_vault_energy_lanes(self, current_attack.damage)
		_record_behavior_event(&"boss_barrier_pulse")
		_begin_recovery()
		return
	if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.SYNC_CROSSFIRE:
		boss_special_pose_column = 4
		boss_special_pose_timer = current_boss_phase.recovery_duration
		game.spawn_vault_energy_lanes(self, current_attack.damage, true)
		_record_behavior_event(&"boss_sync_crossfire")
		_begin_recovery()
		return
	_start_attack()
	_record_behavior_event(&"boss_slam")
	_begin_recovery()


func _apply_boss_phase(notify_game: bool) -> void:
	if boss_phase_index < 0 or boss_phase_index >= definition.boss_phases.size():
		return
	current_boss_phase = definition.boss_phases[boss_phase_index]
	current_attack = current_boss_phase.attack
	speed = definition.speed * current_boss_phase.speed_scale
	behavior_cooldown_timer = 0.0
	if notify_game:
		game.boss_phase_changed(self, current_boss_phase, boss_phase_index)
	queue_redraw()


func _try_advance_boss_phase() -> bool:
	if not definition.is_boss or boss_phase_index + 1 >= definition.boss_phases.size():
		return false
	var next_phase: Resource = definition.boss_phases[boss_phase_index + 1]
	var threshold_health := ceili(max_health * next_phase.health_threshold_ratio)
	if health > threshold_health:
		return false
	health = maxi(health, threshold_health)
	boss_phase_index += 1
	_cancel_behavior()
	attack_timer = 0.0
	attack_hit_done = true
	attack_hitbox.deactivate()
	hurt_timer = 0.0
	stun_timer = 0.0
	wake_up_timer = 0.0
	knockdown_state = false
	hard_knockdown_lockout = false
	boss_transition_timer = 1.0
	invulnerable = 1.0
	velocity = Vector2.ZERO
	state_machine.transition(FighterStateMachineScript.State.STUN)
	_apply_boss_phase(true)
	_record_behavior_event(&"boss_phase_changed")
	return true


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
	if game != null and game.has_method("get_active_players"):
		for fighter in game.get_active_players():
			candidates.append(fighter)
	elif is_instance_valid(player) and not player.is_defeated:
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
		_record_behavior_event(&"target_player" if best_target.is_in_group("player") else &"target_enemy")

func _enemy_separation() -> Vector2:
	var separation := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other) or other.is_defeated or other.grabbed:
			continue
		var away: Vector2 = position - other.position
		var distance := away.length()
		if distance >= SEPARATION_DISTANCE:
			continue
		if distance < 0.01:
			var side := -1.0 if get_instance_id() < other.get_instance_id() else 1.0
			away = Vector2(0.35, side)
			distance = 1.0
		# Favor vertical spreading so enemies still approach from both sides
		# without stacking their sprites on the same depth lane.
		away = Vector2(away.x * 0.48, away.y * 1.35).normalized()
		var proximity_weight := pow(1.0 - distance / SEPARATION_DISTANCE, 1.35)
		separation += away * proximity_weight
	return separation.limit_length(1.0)


func _resolve_visible_overlap() -> void:
	for other in get_tree().get_nodes_in_group("enemies"):
		if (
			other == self
			or not is_instance_valid(other)
			or other.is_defeated
			or other.grabbed
			or get_instance_id() > other.get_instance_id()
		):
			continue
		var away: Vector2 = position - other.position
		var distance := away.length()
		if distance >= MIN_ENEMY_CENTER_DISTANCE:
			continue
		if distance < 0.01:
			var lane_delta: float = approach_lane_offset - other.approach_lane_offset
			var vertical_side := signf(lane_delta)
			if is_zero_approx(vertical_side):
				vertical_side = -1.0 if formation_slot < other.formation_slot else 1.0
			away = Vector2(0.18, vertical_side).normalized()
		else:
			away = Vector2(away.x * 0.35, away.y * 1.25).normalized()
		var correction := (MIN_ENEMY_CENTER_DISTANCE - distance) * 0.5
		position += away * correction
		other.position -= away * correction

func _check_attack() -> void:
	if attack_timer <= 0.0 or attack_hit_done or not is_instance_valid(combat_target):
		return
	if attack_timer < current_attack.hit_trigger_remaining:
		attack_hit_done = true
		if attack_hitbox.can_damage(combat_target.hurtbox) and attack_hitbox.overlaps(combat_target.hurtbox):
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
			if creature_state == CreatureState.ENRAGED:
				resolved_damage = maxi(1, roundi(resolved_damage * definition.enrage_damage_scale))
			resolved_damage = maxi(1, roundi(resolved_damage * source_power_scale_snapshot))
			if combat_target.is_in_group("player"):
				resolved_damage = maxi(1, roundi(resolved_damage * damage_scale_snapshot))
			var resolved_knockback: Vector2 = CounterHitRulesScript.knockback_for(current_attack, facing, counter_hit)
			var stun_bonus: float = CounterHitRulesScript.stun_bonus_for(current_attack, counter_hit)
			var force_interrupt: bool = AttackPriorityRulesScript.interrupts_defender(priority_outcome)
			if combat_target.is_in_group("player"):
				combat_target.take_hit(
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


func _can_guard_hit(knockback: Vector2) -> bool:
	return (
		definition.guard_capacity > 0
		and guard_points > 0
		and guard_recovery_timer <= 0.0
		and attack_timer <= 0.0
		and hurt_timer <= 0.0
		and wake_up_timer <= 0.0
		and absf(knockback.x) > 0.01
		and signf(knockback.x) == -facing
	)

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
	if creature_state == CreatureState.SLEEPING:
		_wake_creature()
	var guarded := _can_guard_hit(knockback)
	var guard_broken := false
	if guarded:
		var incoming_damage := amount
		amount = maxi(1, roundi(amount * definition.guard_damage_scale))
		guard_points = maxi(0, guard_points - incoming_damage)
		last_guarded_damage = amount
		guard_flash_timer = 0.16
		launch = false
		counter_hit = false
		knockback *= 0.22
		_record_behavior_event(&"guard_block")
		game.play_sfx(&"shield_block")
		if guard_points <= 0:
			guard_broken = true
			guard_recovery_timer = definition.guard_recovery_duration
			counter_stun_bonus = maxf(counter_stun_bonus, definition.guard_break_duration)
			force_interrupt = true
			_record_behavior_event(&"guard_break")
			game.play_sfx(&"shield_break")
	_cancel_behavior()
	_register_chain_hit()
	if chain_hit_count >= MAX_CHAIN_HITS:
		launch = true
		hard_knockdown_lockout = true
		knockback.y = minf(knockback.y, -45.0)
	if launch and knockdown_armor_remaining > 0:
		knockdown_armor_remaining -= 1
		launch = false
		hard_knockdown_lockout = false
		knockback.y = maxf(0.0, knockback.y)
		_record_behavior_event(&"elite_armor")
		game.play_sfx(&"elite_armor")
	health -= amount
	if (
		definition.dinosaur_archetype
		and health > 0
		and creature_state != CreatureState.ENRAGED
		and health <= ceili(max_health * definition.enrage_health_ratio)
	):
		_enrage_creature()
	last_hit_was_counter = counter_hit
	if counter_hit or launch or force_interrupt:
		attack_timer = 0.0
		attack_hit_done = true
		attack_hitbox.deactivate()
	var resolved_hurt_duration := (0.08 if guarded and not guard_broken and not launch else (0.25 if not launch else 0.46))
	hurt_timer = (resolved_hurt_duration + counter_stun_bonus) * definition.stun_duration_scale
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
		_try_advance_boss_phase()
		game.boss_health_changed(health, max_health, self)
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
		game.boss_health_changed(health, max_health, self)
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
		_try_advance_boss_phase()
		game.boss_health_changed(health, max_health, self)
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
	elif stun_timer > 0.0 or boss_transition_timer > 0.0:
		next_state = FighterStateMachineScript.State.STUN
	elif attack_timer > 0.0:
		next_state = FighterStateMachineScript.State.ATTACK
	elif velocity.length() > 10.0:
		next_state = FighterStateMachineScript.State.MOVE
	state_machine.transition(next_state)

func _draw() -> void:
	_draw_creature_state_cue()
	_draw_behavior_cue()
	_draw_rank_cue()
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
	var column := _visual_column()
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
	var source_rect := Rect2(column * cell.x, _visual_sprite_row() * cell.y, cell.x, cell.y)
	var base_tint: Color = current_boss_phase.tint if definition.is_boss and current_boss_phase != null else definition.tint
	var tint_color: Color = Color.WHITE if flash_timer > 0.0 else (definition.hurt_tint if hurt_timer > 0.0 else base_tint)
	# Enemy source art faces left, opposite to the player sheet.
	draw_set_transform(Vector2(recoil_offset, impact_squash * 18.0), 0.0, Vector2(-facing * (1.0 + impact_squash), 1.0 - impact_squash))
	draw_texture_rect_region(definition.sprite_sheet, target_rect, source_rect, tint_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.RANGED and not is_defeated:
		if definition.ranged_weapon.kind == 1:
			draw_circle(Vector2(facing * 39.0, -54.0), 9.0, definition.ranged_weapon.color)
			draw_line(Vector2(facing * 38.0, -65.0), Vector2(facing * 45.0, -73.0), Color("#f0b55a"), 3.0)
		else:
			draw_line(Vector2(facing * 15.0, -57.0), Vector2(facing * 44.0, -57.0), Color("#b9c6ca"), 9.0)
			draw_line(Vector2(facing * 20.0, -53.0), Vector2(facing * 17.0, -44.0), Color("#624438"), 6.0)
	elif definition.is_boss and not is_defeated:
		_draw_boss_overlay()
	if definition.show_health_bar and health > 0:
		draw_rect(Rect2(-31,-170,62,6), Color("#351f28"))
		draw_rect(Rect2(-31,-170,62.0*health/max_health,6), Color("#f06454"))
	_draw_guard_cue()


func _draw_rank_cue() -> void:
	if definition.rank != EnemyDefinitionScript.Rank.ELITE or is_defeated:
		return
	var pulse := 0.34 + sin(Time.get_ticks_msec() * 0.012) * 0.08
	draw_arc(Vector2(0.0, -5.0), definition.shadow_half_extents.x + 10.0, 0.0, TAU, 28, Color(1.0, 0.72, 0.18, pulse), 4.0)
	for index in range(2):
		var y := -183.0 - index * 8.0
		draw_polyline(PackedVector2Array([Vector2(-9.0, y + 5.0), Vector2(0.0, y), Vector2(9.0, y + 5.0)]), Color("#ffd052"), 3.0)


func _draw_guard_cue() -> void:
	if definition.guard_capacity <= 0 or is_defeated:
		return
	var bar_color := Color("#70e5f2") if guard_points > 0 else Color("#e25a3d")
	if guard_flash_timer > 0.0:
		bar_color = Color.WHITE
	draw_rect(Rect2(-31.0, -182.0, 62.0, 5.0), Color("#172a31"))
	draw_rect(Rect2(-31.0, -182.0, 62.0 * guard_points / float(definition.guard_capacity), 5.0), bar_color)


func _draw_behavior_cue() -> void:
	if behavior_phase != BehaviorPhase.TELEGRAPH:
		return
	var pulse := 0.72 + sin(Time.get_ticks_msec() * 0.028) * 0.18
	var cue_color := Color(1.0, 0.47, 0.16, pulse)
	if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.POUNCER:
		cue_color = Color(0.62, 0.95, 0.28, pulse)
	elif definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.RANGED:
		cue_color = Color(1.0, 0.82, 0.25, pulse)
	elif definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.BOSS:
		cue_color = Color(1.0, 0.2, 0.08, pulse)
	draw_arc(Vector2(0.0, -12.0), 37.0, 0.0, TAU, 28, cue_color, 4.0)
	if definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.CHARGER:
		draw_line(Vector2(facing * 22.0, -12.0), Vector2(facing * 92.0, -12.0), cue_color, 5.0)
	elif definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.RANGED:
		draw_line(Vector2(facing * 18.0, -48.0), Vector2(facing * 150.0, -48.0), cue_color, 3.0)
	elif definition.behavior_kind == EnemyDefinitionScript.BehaviorKind.BOSS:
		if String(definition.enemy_id).begins_with("vault_sentinel"):
			var energy_color := Color(1.0, 0.58, 0.12, pulse) if "nyx" in String(definition.enemy_id) else Color(0.28, 0.92, 1.0, pulse)
			for lane_offset in [-42.0, 0.0, 42.0]:
				draw_line(Vector2(facing * 46.0, lane_offset), Vector2(facing * 225.0, lane_offset), energy_color, 4.0)
			if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.SYNC_CROSSFIRE:
				draw_arc(Vector2.ZERO, 72.0, 0.0, TAU, 30, energy_color, 5.0)
		elif definition.visual_kind == EnemyDefinitionScript.VisualKind.VEHICLE:
			draw_line(Vector2(facing * 72.0, -10.0), Vector2(facing * 245.0, -10.0), cue_color, 6.0)
			for index in range(3):
				var chevron_x: float = facing * (118.0 + index * 48.0)
				draw_polyline(PackedVector2Array([
					Vector2(chevron_x - facing * 16.0, -28.0),
					Vector2(chevron_x, -10.0),
					Vector2(chevron_x - facing * 16.0, 8.0),
				]), cue_color, 5.0)
		elif definition.visual_kind == EnemyDefinitionScript.VisualKind.EXOSUIT:
			if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.MAGNET_PULL:
				draw_line(Vector2(facing * 42.0, -74.0), Vector2(facing * 224.0, -74.0), Color(0.18, 0.9, 1.0, pulse), 5.0)
				for index in range(4):
					draw_arc(Vector2(facing * (74.0 + index * 42.0), -74.0), 11.0, -PI * 0.6, PI * 0.6, 12, Color(0.38, 0.95, 1.0, pulse), 3.0)
			elif current_boss_phase.special_kind in [BossPhaseDataScript.SpecialKind.SEISMIC_FRACTURE, BossPhaseDataScript.SpecialKind.TITAN_CALL]:
				for side in ([-1.0, 1.0] if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.TITAN_CALL else [float(facing)]):
					draw_line(Vector2(side * 46.0, 3.0), Vector2(side * 238.0, 3.0), Color(0.28, 0.9, 1.0, pulse), 5.0)
					for index in range(4):
						var crack_x: float = side * (78.0 + index * 46.0)
						draw_polyline(PackedVector2Array([Vector2(crack_x - 12.0, -8.0), Vector2(crack_x, 3.0), Vector2(crack_x + 9.0, 14.0)]), Color(0.46, 0.96, 1.0, pulse), 4.0)
			else:
				for side in [-1.0, 1.0]:
					draw_line(Vector2(side * 48.0, 2.0), Vector2(side * 205.0, 2.0), cue_color, 5.0)
					for index in range(3):
						var flame_x: float = side * (86.0 + index * 46.0)
						draw_colored_polygon(PackedVector2Array([
							Vector2(flame_x - 12.0, 2.0),
							Vector2(flame_x, -22.0 - index * 3.0),
							Vector2(flame_x + 12.0, 2.0),
						]), Color(1.0, 0.42, 0.06, pulse * 0.72))
		elif definition.visual_kind == EnemyDefinitionScript.VisualKind.TRANSFORMING:
			if current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.RUSH:
				draw_line(Vector2(facing * 48.0, 2.0), Vector2(facing * 190.0, 2.0), cue_color, 5.0)
				for index in range(3):
					var rush_x := facing * (92.0 + index * 42.0)
					draw_polyline(PackedVector2Array([Vector2(rush_x - facing * 13.0, -13.0), Vector2(rush_x, 2.0), Vector2(rush_x - facing * 13.0, 17.0)]), cue_color, 4.0)
			elif current_boss_phase.special_kind == BossPhaseDataScript.SpecialKind.CISTERN_BURST:
				for side in [-1.0, 1.0]:
					draw_arc(Vector2(side * 42.0, -4.0), 32.0, -PI * 0.88, -PI * 0.12, 18, Color(0.48, 0.93, 1.0, pulse), 5.0)
			else:
				for side in [-1.0, 1.0]:
					draw_colored_polygon(PackedVector2Array([Vector2(side * 28.0, 3.0), Vector2(side * 48.0, -38.0), Vector2(side * 68.0, 3.0)]), Color(1.0, 0.36, 0.04, pulse * 0.72))
		else:
			draw_arc(Vector2.ZERO, current_boss_phase.special_max_distance * 0.22, 0.0, TAU, 32, cue_color, 6.0)


func _draw_creature_state_cue() -> void:
	if not definition.dinosaur_archetype or is_defeated:
		return
	if creature_state == CreatureState.SLEEPING:
		var sleep_pulse := 0.65 + sin(Time.get_ticks_msec() * 0.006) * 0.2
		for index in range(3):
			var origin := Vector2(30.0 + index * 12.0, -94.0 - index * 15.0)
			draw_string(ThemeDB.fallback_font, origin, "Z", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15 + index * 2, Color(0.62, 0.88, 1.0, sleep_pulse))
	elif creature_state == CreatureState.ENRAGED:
		var rage_pulse := 0.55 + sin(Time.get_ticks_msec() * 0.018) * 0.18
		draw_arc(Vector2(0.0, -42.0), definition.shadow_half_extents.x + 13.0, -PI, 0.0, 24, Color(1.0, 0.2, 0.08, rage_pulse), 6.0)


func _draw_boss_overlay() -> void:
	if String(definition.enemy_id).begins_with("vault_sentinel"):
		var vault_alpha := 0.3 + sin(Time.get_ticks_msec() * 0.02) * 0.12
		var vault_color := Color(1.0, 0.52, 0.1, vault_alpha) if "nyx" in String(definition.enemy_id) else Color(0.2, 0.9, 1.0, vault_alpha)
		draw_arc(Vector2(0.0, -82.0), 48.0 + boss_phase_index * 7.0, -PI, 0.0, 24, vault_color, 6.0)
		if boss_phase_index >= 1:
			for side in [-1.0, 1.0]:
				draw_line(Vector2(side * 18.0, -54.0), Vector2(side * 58.0, -108.0), vault_color, 4.0)
		return
	if definition.visual_kind == EnemyDefinitionScript.VisualKind.VEHICLE:
		var exhaust_pulse := 0.4 + sin(Time.get_ticks_msec() * 0.018) * 0.16
		for index in range(4):
			var spark_origin := Vector2(118.0 + index * 7.0, -38.0 + index * 5.0)
			draw_line(spark_origin, spark_origin + Vector2(18.0 + index * 4.0, 4.0), Color(1.0, 0.44, 0.08, exhaust_pulse), 4.0)
		if boss_phase_index >= 2:
			draw_arc(Vector2(0.0, -62.0), 116.0, -PI * 0.9, -PI * 0.1, 28, Color(1.0, 0.16, 0.04, 0.46), 7.0)
		return
	if definition.visual_kind == EnemyDefinitionScript.VisualKind.EXOSUIT:
		var coil_alpha := 0.36 + sin(Time.get_ticks_msec() * 0.02) * 0.12
		draw_arc(Vector2(facing * 43.0, -82.0), 22.0, 0.0, TAU, 22, Color(0.15, 0.9, 1.0, coil_alpha), 5.0)
		if boss_phase_index >= 2:
			draw_arc(Vector2(0.0, -92.0), 74.0, -PI, 0.0, 28, Color(1.0, 0.38, 0.06, 0.42), 7.0)
		return
	if definition.visual_kind == EnemyDefinitionScript.VisualKind.TRANSFORMING:
		var core_alpha := 0.32 + sin(Time.get_ticks_msec() * 0.022) * 0.12
		var core_color := Color(0.2, 0.9, 1.0, core_alpha) if boss_phase_index == 0 else Color(1.0, 0.28, 0.04, core_alpha + 0.12)
		draw_arc(Vector2(0.0, -88.0), 46.0 + boss_phase_index * 10.0, -PI, 0.0, 24, core_color, 6.0)
		if boss_phase_index >= 1:
			for index in range(4):
				var ember_origin := Vector2(-34.0 + index * 24.0, -142.0 - index % 2 * 11.0)
				draw_line(ember_origin, ember_origin + Vector2(4.0, -14.0), Color(1.0, 0.44, 0.08, core_alpha), 3.0)
		return
	if boss_phase_index >= 1:
		var aura_alpha := 0.22 + sin(Time.get_ticks_msec() * 0.018) * 0.08
		draw_arc(Vector2(0.0, -78.0), 58.0, 0.0, TAU, 30, Color(1.0, 0.16, 0.05, aura_alpha), 9.0)
	draw_line(Vector2(facing * 24.0, -68.0), Vector2(facing * 69.0, -99.0), Color("#422b24"), 13.0)
	draw_line(Vector2(facing * 24.0, -68.0), Vector2(facing * 69.0, -99.0), Color("#8a5b3b"), 7.0)
	var hammer_center := Vector2(facing * 73.0, -101.0)
	var hammer_points := PackedVector2Array([
		hammer_center + Vector2(-20.0, -14.0),
		hammer_center + Vector2(15.0, -14.0),
		hammer_center + Vector2(23.0, -6.0),
		hammer_center + Vector2(18.0, 13.0),
		hammer_center + Vector2(-18.0, 13.0),
		hammer_center + Vector2(-24.0, 5.0),
	])
	draw_colored_polygon(hammer_points, Color("#555d66"))
	hammer_points.append(hammer_points[0])
	draw_polyline(hammer_points, Color("#aab0b4"), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0.0, -111.0), Vector2(12.0, -94.0), Vector2(0.0, -78.0), Vector2(-12.0, -94.0)]), Color("#7e251d"))

func _draw_raptor() -> void:
	_draw_oval(
		Vector2(0, 2),
		definition.shadow_half_extents.x,
		definition.shadow_half_extents.y,
		Color(0.02, 0.03, 0.04, 0.44)
	)
	var column := _visual_column()
	var cell := Vector2(
		definition.sprite_sheet.get_width() / float(definition.sprite_columns),
		definition.sprite_sheet.get_height() / float(definition.sprite_rows)
	)
	var source_rect := Rect2(column * cell.x, _visual_sprite_row() * cell.y, cell.x, cell.y)
	var target_size: Vector2 = definition.target_size
	var target_rect := Rect2(
		-target_size.x * 0.5,
		-target_size.y + definition.target_bottom_offset,
		target_size.x,
		target_size.y
	)
	var base_tint: Color = definition.tint
	if creature_state == CreatureState.ENRAGED:
		base_tint = base_tint.lerp(Color(1.0, 0.4, 0.3, 1.0), 0.2)
	var tint_color: Color = Color.WHITE if flash_timer > 0.0 else (definition.hurt_tint if hurt_timer > 0.0 else base_tint)
	draw_set_transform(Vector2(recoil_offset, impact_squash * 18.0), 0.0, Vector2(-facing * (1.0 + impact_squash), 1.0 - impact_squash))
	draw_texture_rect_region(definition.sprite_sheet, target_rect, source_rect, tint_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _visual_column() -> int:
	if creature_state == CreatureState.SLEEPING:
		return 1
	if is_defeated or knockdown_state:
		return 7
	if hurt_timer > 0.0 or stun_timer > 0.0 or boss_transition_timer > 0.0 or grabbed:
		return 6
	if definition.visual_kind == EnemyDefinitionScript.VisualKind.TRANSFORMING:
		if boss_special_pose_timer > 0.0 and boss_special_pose_column >= 0:
			return boss_special_pose_column
		if attack_timer > 0.0:
			return 2
		if behavior_phase == BehaviorPhase.TELEGRAPH:
			return 3
		if behavior_phase == BehaviorPhase.BURST:
			return 5
		if velocity.length() > 10.0:
			return 1
		return 0
	if definition.visual_kind == EnemyDefinitionScript.VisualKind.EXOSUIT:
		if boss_special_pose_timer > 0.0 and boss_special_pose_column >= 0:
			return boss_special_pose_column
		if attack_timer > 0.0:
			return 2
		if behavior_phase == BehaviorPhase.TELEGRAPH:
			return 3 if current_boss_phase.special_kind in [BossPhaseDataScript.SpecialKind.MAGNET_PULL, BossPhaseDataScript.SpecialKind.SEISMIC_FRACTURE, BossPhaseDataScript.SpecialKind.TITAN_CALL] else 5
		if velocity.length() > 10.0:
			return 1
		return 0
	if attack_timer > 0.0:
		if current_attack != null and attack_timer > current_attack.hit_trigger_remaining:
			return 4
		return 5
	if behavior_phase == BehaviorPhase.TELEGRAPH:
		return 4
	if behavior_phase == BehaviorPhase.BURST:
		return 5
	if velocity.length() > 10.0:
		return 2 + int(walk_phase) % 2
	if definition.dinosaur_archetype:
		return 0
	return int(visual_clock * 2.0) % 2


func _visual_sprite_row() -> int:
	if definition.is_boss and current_boss_phase != null and current_boss_phase.sprite_row_override >= 0:
		return current_boss_phase.sprite_row_override
	return definition.sprite_row

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	draw_colored_polygon(pts, color)
