class_name DisasterHazardData
extends EnvironmentObjectData

enum HazardKind {
	FIRE_PATCH,
	SMOKE_CLOUD,
	CISTERN_JET,
}

@export var hazard_kind := HazardKind.FIRE_PATCH
@export_range(0.6, 8.0, 0.05) var cycle_duration := 3.0
@export_range(0.1, 2.0, 0.05) var warning_duration := 0.7
@export_range(0.1, 2.0, 0.05) var active_duration := 0.65
@export_range(0.0, 8.0, 0.05) var cycle_offset := 0.0
@export_range(0.1, 1.0, 0.05) var movement_scale := 0.55


func is_valid_object() -> bool:
	if kind != ObjectKind.DISASTER_HAZARD or object_id.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return false
	if contact_damage <= 0 or cycle_duration <= warning_duration + active_duration:
		return false
	if warning_duration <= 0.0 or active_duration <= 0.0:
		return false
	if hazard_kind == HazardKind.SMOKE_CLOUD:
		return movement_scale > 0.0 and movement_scale < 1.0
	if hazard_kind == HazardKind.CISTERN_JET:
		return move_speed > 0.0 and initial_direction != 0
	return hazard_kind == HazardKind.FIRE_PATCH
