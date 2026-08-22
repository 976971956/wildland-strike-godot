class_name VaultHazardData
extends EnvironmentObjectData

enum HazardKind {
	DECK_SHIFT,
	SECURITY_LASER,
	CRYO_VENT,
}

@export var hazard_kind := HazardKind.DECK_SHIFT
@export_range(0.8, 9.0, 0.05) var cycle_duration := 3.6
@export_range(0.1, 2.0, 0.05) var warning_duration := 0.7
@export_range(0.1, 2.5, 0.05) var active_duration := 0.65
@export_range(0.0, 9.0, 0.05) var cycle_offset := 0.0
@export_range(0.1, 1.0, 0.05) var movement_scale := 0.66


func is_valid_object() -> bool:
	if kind != ObjectKind.VAULT_HAZARD or object_id.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return false
	if contact_damage <= 0 or cycle_duration <= warning_duration + active_duration:
		return false
	if warning_duration <= 0.0 or active_duration <= 0.0:
		return false
	if hazard_kind == HazardKind.DECK_SHIFT:
		return move_speed > 0.0 and initial_direction != 0
	if hazard_kind == HazardKind.CRYO_VENT:
		return movement_scale > 0.0 and movement_scale < 1.0
	return hazard_kind == HazardKind.SECURITY_LASER
