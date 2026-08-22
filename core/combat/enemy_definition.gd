class_name EnemyDefinition
extends Resource

enum VisualKind {
	HUMANOID,
	RAPTOR,
}

enum BehaviorKind {
	FLANKER,
	CHARGER,
	POUNCER,
	PRESSURE,
	RANGED,
	BOSS,
	DUELIST,
}

enum Rank {
	STANDARD,
	ELITE,
	BOSS,
}

enum Faction {
	HUMAN_ENEMY,
	NEUTRAL_CREATURE,
}

@export_group("Identity")
@export var enemy_id: StringName
@export var is_boss := false
@export var rank := Rank.STANDARD

@export_group("Combat")
@export var max_health := 1
@export var speed := 100.0
@export var attack: AttackFrameData
@export var can_be_grabbed := true
@export var defeat_score := 0
@export_range(0.5, 2.0, 0.05) var outgoing_damage_scale := 1.0
@export_range(0.25, 1.0, 0.05) var stun_duration_scale := 1.0
@export_range(0, 4, 1) var knockdown_armor := 0
@export var faction := Faction.HUMAN_ENEMY
@export_range(120.0, 900.0, 1.0) var opposing_faction_target_radius := 520.0

@export_group("Behavior")
@export var behavior_kind := BehaviorKind.FLANKER
@export_range(20.0, 120.0, 1.0) var attack_distance := 62.0
@export_range(12.0, 100.0, 1.0) var lane_tolerance := 36.0
@export_range(0.1, 1.5, 0.05) var vertical_approach_scale := 0.72
@export_range(0.0, 1.5, 0.01) var telegraph_duration := 0.0
@export_range(0.0, 1.5, 0.01) var burst_duration := 0.0
@export_range(1.0, 4.0, 0.05) var burst_speed_scale := 1.0
@export_range(0.0, 1.5, 0.01) var recovery_duration := 0.0
@export_range(0.0, 2.0, 0.01) var behavior_cooldown := 0.0
@export_range(0.0, 600.0, 1.0) var burst_min_distance := 0.0
@export_range(0.0, 800.0, 1.0) var burst_max_distance := 0.0
@export_range(0.0, 240.0, 1.0) var retreat_distance := 0.0
@export_range(0.0, 1.0, 0.01) var retreat_duration := 0.0
@export_range(80.0, 600.0, 1.0) var preferred_range_min := 220.0
@export_range(100.0, 900.0, 1.0) var preferred_range_max := 440.0
@export var ranged_weapon: Resource
@export var boss_phases: Array[Resource] = []

@export_group("Guard")
@export_range(0, 200, 1) var guard_capacity := 0
@export_range(0.05, 1.0, 0.05) var guard_damage_scale := 0.35
@export_range(0.1, 3.0, 0.05) var guard_break_duration := 0.85
@export_range(0.2, 8.0, 0.1) var guard_recovery_duration := 3.0

@export_group("Creature Ecology")
@export var dinosaur_archetype := false
@export var starts_sleeping := false
@export_range(40.0, 500.0, 1.0) var wake_radius := 150.0
@export_range(0.05, 1.0, 0.01) var enrage_health_ratio := 0.5
@export_range(1.0, 2.0, 0.01) var enrage_speed_scale := 1.2
@export_range(1.0, 2.0, 0.01) var enrage_damage_scale := 1.15

@export_group("Presentation")
@export var sprite_sheet: Texture2D
@export var visual_kind := VisualKind.HUMANOID
@export var sprite_columns := 4
@export var sprite_rows := 3
@export var sprite_row := 0
@export var target_size := Vector2(174.0, 174.0)
@export var target_bottom_offset := 14.0
@export var body_scale := 1.0
@export var actor_scale := Vector2.ONE
@export var shadow_half_extents := Vector2(34.0, 9.0)
@export var tint := Color.WHITE
@export var hurt_tint := Color(1.0, 0.68, 0.61)
@export var show_health_bar := false


func is_valid_definition() -> bool:
	var core_valid := (
		not enemy_id.is_empty()
		and max_health > 0
		and speed > 0.0
		and attack != null
		and attack.is_valid_frame_data()
		and sprite_sheet != null
		and sprite_columns > 0
		and sprite_rows > 0
		and target_size.x > 0.0
		and target_size.y > 0.0
	)
	if not core_valid:
		return false
	if behavior_kind < BehaviorKind.FLANKER or behavior_kind > BehaviorKind.DUELIST:
		return false
	if rank < Rank.STANDARD or rank > Rank.BOSS:
		return false
	if is_boss != (rank == Rank.BOSS):
		return false
	if rank == Rank.ELITE and (outgoing_damage_scale <= 1.0 or stun_duration_scale >= 1.0 or knockdown_armor <= 0):
		return false
	if rank == Rank.STANDARD and knockdown_armor > 0:
		return false
	if guard_capacity > 0:
		if guard_damage_scale >= 1.0 or guard_break_duration <= 0.0 or guard_recovery_duration <= guard_break_duration:
			return false
	if attack_distance <= 0.0 or lane_tolerance <= 0.0 or vertical_approach_scale <= 0.0:
		return false
	if faction < Faction.HUMAN_ENEMY or faction > Faction.NEUTRAL_CREATURE:
		return false
	if faction == Faction.NEUTRAL_CREATURE and can_be_grabbed:
		return false
	if opposing_faction_target_radius <= attack_distance:
		return false
	if starts_sleeping and not dinosaur_archetype:
		return false
	if dinosaur_archetype:
		if (
			faction != Faction.NEUTRAL_CREATURE
			or can_be_grabbed
			or visual_kind != VisualKind.RAPTOR
			or wake_radius <= attack_distance
			or enrage_health_ratio <= 0.0
			or enrage_health_ratio > 1.0
			or enrage_speed_scale <= 1.0
			or enrage_damage_scale <= 1.0
		):
			return false
	if behavior_kind in [BehaviorKind.CHARGER, BehaviorKind.POUNCER, BehaviorKind.DUELIST]:
		if (
			telegraph_duration <= 0.0
			or burst_duration <= 0.0
			or burst_speed_scale <= 1.0
			or recovery_duration <= 0.0
			or burst_min_distance < attack_distance
			or burst_max_distance <= burst_min_distance
		):
			return false
	if behavior_kind in [BehaviorKind.POUNCER, BehaviorKind.DUELIST]:
		return retreat_distance > attack_distance and retreat_duration > 0.0
	if behavior_kind == BehaviorKind.RANGED:
		return (
			telegraph_duration > 0.0
			and recovery_duration > 0.0
			and behavior_cooldown > 0.0
			and preferred_range_min > attack_distance
			and preferred_range_max > preferred_range_min
			and ranged_weapon != null
			and ranged_weapon.has_method("is_valid_weapon")
			and ranged_weapon.is_valid_weapon()
		)
	if is_boss:
		if boss_phases.size() < 2:
			return false
		var previous_threshold := 1.01
		var phase_ids := {}
		for phase in boss_phases:
			if phase == null or not phase.has_method("is_valid_phase") or not phase.is_valid_phase():
				return false
			if phase.health_threshold_ratio >= previous_threshold or phase_ids.has(phase.phase_id):
				return false
			previous_threshold = phase.health_threshold_ratio
			phase_ids[phase.phase_id] = true
		if boss_phases[0].health_threshold_ratio != 1.0:
			return false
	return true
