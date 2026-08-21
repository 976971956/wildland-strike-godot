class_name EnvironmentObjectData
extends Resource

enum ObjectKind {
	BREAKABLE,
	ROLLING_HAZARD,
}

@export var object_id: StringName
@export var kind := ObjectKind.BREAKABLE
@export var position := Vector2.ZERO
@export var size := Vector2(54.0, 62.0)
@export_range(1, 500, 1) var health := 30
@export_range(0, 100, 1) var contact_damage := 0
@export var drop_id: StringName
@export var move_speed := 0.0
@export var move_min_x := 0.0
@export var move_max_x := 0.0
@export_range(-1, 1, 2) var initial_direction := 1
@export_range(0, 5000, 10) var defeat_score := 0


func is_valid_object() -> bool:
	if object_id.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return false
	if kind == ObjectKind.BREAKABLE:
		return health > 0 and contact_damage == 0
	if kind == ObjectKind.ROLLING_HAZARD:
		return contact_damage > 0 and move_speed > 0.0 and move_max_x > move_min_x
	return false
