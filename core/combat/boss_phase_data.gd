class_name BossPhaseData
extends Resource

enum SpecialKind {
	GROUND_SLAM,
	RUSH,
	TIDAL_WAVE,
}

@export var phase_id: StringName
@export_range(0.05, 1.0, 0.05) var health_threshold_ratio := 1.0
@export var attack: AttackFrameData
@export var special_attack: AttackFrameData
@export var special_kind := SpecialKind.GROUND_SLAM
@export_range(0.5, 2.0, 0.05) var speed_scale := 1.0
@export_range(0.1, 1.5, 0.01) var telegraph_duration := 0.4
@export_range(0.1, 2.5, 0.05) var special_cooldown := 1.2
@export_range(0.0, 600.0, 1.0) var special_min_distance := 90.0
@export_range(40.0, 900.0, 1.0) var special_max_distance := 300.0
@export_range(1.0, 4.0, 0.05) var burst_speed_scale := 1.0
@export_range(0.0, 1.5, 0.01) var burst_duration := 0.0
@export_range(0.1, 1.5, 0.01) var recovery_duration := 0.5
@export var dialogue_speaker := "WARDEN ROURKE"
@export var dialogue_line := "You should have stayed outside."
@export var reinforcement_enemy_id: StringName
@export_range(0, 6, 1) var reinforcement_count := 0
@export var tint := Color.WHITE


func is_valid_phase() -> bool:
	if (
		phase_id.is_empty()
		or attack == null
		or special_attack == null
		or not attack.is_valid_frame_data()
		or not special_attack.is_valid_frame_data()
		or speed_scale <= 0.0
		or telegraph_duration <= 0.0
		or special_cooldown <= 0.0
		or special_max_distance <= special_min_distance
		or recovery_duration <= 0.0
		or dialogue_speaker.is_empty()
		or dialogue_line.is_empty()
	):
		return false
	if special_kind == SpecialKind.RUSH and (burst_speed_scale <= 1.0 or burst_duration <= 0.0):
		return false
	if reinforcement_count > 0 and reinforcement_enemy_id.is_empty():
		return false
	return true
