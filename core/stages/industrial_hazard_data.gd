class_name IndustrialHazardData
extends EnvironmentObjectData

enum HazardKind {
	CONVEYOR,
	PISTON_PRESS,
	FURNACE_VENT,
}

@export var hazard_kind := HazardKind.CONVEYOR
@export_range(0.4, 8.0, 0.05) var cycle_duration := 2.8
@export_range(0.1, 2.0, 0.05) var warning_duration := 0.65
@export_range(0.1, 1.5, 0.05) var active_duration := 0.35
@export_range(0.0, 8.0, 0.05) var cycle_offset := 0.0


func is_valid_object() -> bool:
	if kind != ObjectKind.INDUSTRIAL_HAZARD or object_id.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return false
	if hazard_kind == HazardKind.CONVEYOR:
		return move_speed > 0.0 and initial_direction != 0 and contact_damage == 0
	return (
		contact_damage > 0
		and cycle_duration > warning_duration + active_duration
		and warning_duration > 0.0
		and active_duration > 0.0
	)
