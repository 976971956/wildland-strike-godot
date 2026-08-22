class_name PickupDefinition
extends Resource

enum PickupKind {
	FOOD,
	SCORE,
}

@export var pickup_id: StringName
@export var display_name := ""
@export var kind := PickupKind.FOOD
@export_range(0, 999, 1) var heal_amount := 0
@export_range(0, 10000, 10) var score_value := 0
@export_range(8.0, 32.0, 1.0) var icon_size := 13.0
@export var color := Color.WHITE


func is_valid_pickup() -> bool:
	if pickup_id.is_empty() or display_name.is_empty() or score_value <= 0 or icon_size <= 0.0:
		return false
	if kind == PickupKind.FOOD:
		return heal_amount > 0
	if kind == PickupKind.SCORE:
		return heal_amount == 0
	return false
