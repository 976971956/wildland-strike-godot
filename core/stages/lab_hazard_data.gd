class_name LabHazardData
extends EnvironmentObjectData

enum HazardKind {
	ARC_FIELD,
	MUTAGEN_POOL,
	CORE_SURGE,
}

@export var hazard_kind := HazardKind.ARC_FIELD
@export_range(0.8, 9.0, 0.05) var cycle_duration := 3.5
@export_range(0.1, 2.0, 0.05) var warning_duration := 0.7
@export_range(0.1, 2.5, 0.05) var active_duration := 0.7
@export_range(0.0, 9.0, 0.05) var cycle_offset := 0.0
@export_range(0.1, 1.0, 0.05) var movement_scale := 0.62


func is_valid_object() -> bool:
	if kind != ObjectKind.LAB_HAZARD or object_id.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return false
	if contact_damage <= 0 or cycle_duration <= warning_duration + active_duration:
		return false
	if warning_duration <= 0.0 or active_duration <= 0.0:
		return false
	if hazard_kind == HazardKind.MUTAGEN_POOL:
		return movement_scale > 0.0 and movement_scale < 1.0
	if hazard_kind == HazardKind.CORE_SURGE:
		return move_speed > 0.0 and initial_direction != 0
	return hazard_kind == HazardKind.ARC_FIELD
