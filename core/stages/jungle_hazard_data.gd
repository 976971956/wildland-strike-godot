class_name JungleHazardData
extends EnvironmentObjectData

enum HazardKind {
	SPORE_BLOOM,
	MINE_CART,
	TITAN_STOMP,
}

@export var hazard_kind := HazardKind.SPORE_BLOOM
@export_range(0.8, 9.0, 0.05) var cycle_duration := 3.4
@export_range(0.1, 2.0, 0.05) var warning_duration := 0.75
@export_range(0.1, 2.0, 0.05) var active_duration := 0.55
@export_range(0.0, 9.0, 0.05) var cycle_offset := 0.0
@export_range(0.1, 1.0, 0.05) var movement_scale := 0.62
@export var hazard_texture: Texture2D


func is_valid_object() -> bool:
	if kind != ObjectKind.JUNGLE_HAZARD or object_id.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return false
	if contact_damage <= 0 or cycle_duration <= warning_duration + active_duration:
		return false
	if warning_duration <= 0.0 or active_duration <= 0.0:
		return false
	if hazard_kind == HazardKind.SPORE_BLOOM:
		return movement_scale > 0.0 and movement_scale < 1.0
	if hazard_kind == HazardKind.MINE_CART:
		return move_speed > 0.0 and move_max_x > move_min_x and initial_direction != 0 and hazard_texture != null
	return hazard_kind == HazardKind.TITAN_STOMP
