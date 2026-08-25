class_name ImpactProfile
extends Resource

@export var profile_id: StringName
@export_range(0.0, 0.25, 0.001) var hit_stop_duration := 0.0
@export_range(0.0, 0.5, 0.001) var camera_shake_duration := 0.0
@export_range(0.0, 30.0, 0.1) var camera_shake_strength := 0.0
@export_range(0.0, 300.0, 1.0) var attacker_recoil_speed := 0.0
@export var primary_sfx: StringName
@export var layer_sfx: StringName
@export_range(0, 250, 1) var haptic_duration_ms := 0
@export_range(0.0, 1.0, 0.01) var haptic_strength := 0.0
@export_group("Silhouette")
@export var burst_color := Color("#ffd65c")
@export var core_color := Color("#fff7d1")
@export_range(0.5, 2.0, 0.01) var impact_scale := 1.0
@export_range(0, 12, 1) var ray_count_bonus := 0


func is_valid_profile() -> bool:
	return (
		not profile_id.is_empty()
		and hit_stop_duration >= 0.0
		and camera_shake_duration >= 0.0
		and camera_shake_strength >= 0.0
		and attacker_recoil_speed >= 0.0
		and not primary_sfx.is_empty()
		and haptic_duration_ms >= 0
		and haptic_strength >= 0.0
		and haptic_strength <= 1.0
		and burst_color.a > 0.0
		and core_color.a > 0.0
		and impact_scale >= 0.5
		and impact_scale <= 2.0
	)
