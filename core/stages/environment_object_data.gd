class_name EnvironmentObjectData
extends Resource

enum ObjectKind {
	BREAKABLE,
	ROLLING_HAZARD,
	CARRYABLE,
	WATER_CURRENT,
	ROAD_HAZARD,
	INDUSTRIAL_HAZARD,
	DISASTER_HAZARD,
	JUNGLE_HAZARD,
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
@export_range(0, 100, 1) var throw_damage := 0
@export_range(0.0, 1200.0, 10.0) var throw_speed := 0.0
@export_range(0.0, 5.0, 0.05) var throw_lifetime := 0.0
@export var break_on_throw_hit := true
@export var color := Color("#8a5735")


func is_valid_object() -> bool:
	if object_id.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return false
	if kind == ObjectKind.BREAKABLE:
		return health > 0 and contact_damage == 0
	if kind == ObjectKind.ROLLING_HAZARD:
		return contact_damage > 0 and move_speed > 0.0 and move_max_x > move_min_x
	if kind == ObjectKind.CARRYABLE:
		return health > 0 and contact_damage == 0 and throw_damage > 0 and throw_speed > 0.0 and throw_lifetime > 0.0
	if kind == ObjectKind.WATER_CURRENT:
		return contact_damage > 0 and move_speed > 0.0 and initial_direction != 0
	if kind == ObjectKind.ROAD_HAZARD:
		return health > 0 and contact_damage > 0 and defeat_score > 0
	if kind == ObjectKind.INDUSTRIAL_HAZARD:
		return false
	if kind == ObjectKind.DISASTER_HAZARD:
		return false
	if kind == ObjectKind.JUNGLE_HAZARD:
		return false
	return false
