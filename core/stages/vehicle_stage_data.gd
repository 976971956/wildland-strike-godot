class_name VehicleStageData
extends Resource

@export var vehicle_id: StringName
@export var display_name := ""
@export var start_x := 260.0
@export var end_x := 4100.0
@export var lane_positions := PackedFloat32Array([490.0, 560.0, 630.0])

@export_group("Driving")
@export_range(40.0, 600.0, 1.0) var minimum_speed := 105.0
@export_range(60.0, 900.0, 1.0) var maximum_speed := 360.0
@export_range(10.0, 800.0, 1.0) var acceleration := 185.0
@export_range(10.0, 800.0, 1.0) var braking := 270.0
@export_range(10.0, 500.0, 1.0) var passive_drag := 54.0
@export_range(40.0, 600.0, 1.0) var lane_steering_speed := 250.0

@export_group("Combat")
@export_range(1, 1000, 1) var hull_health := 260
@export_range(1, 100, 1) var collision_damage := 22
@export_range(1, 200, 1) var ram_damage := 46
@export_range(0.1, 3.0, 0.05) var ram_cooldown := 0.55
@export var mounted_weapon: Resource
@export_range(0.05, 2.0, 0.05) var mounted_attack_cooldown := 0.24


func is_valid_vehicle_stage() -> bool:
	if (
		vehicle_id.is_empty()
		or display_name.is_empty()
		or end_x <= start_x
		or lane_positions.size() < 2
		or minimum_speed <= 0.0
		or maximum_speed <= minimum_speed
		or acceleration <= 0.0
		or braking <= 0.0
		or passive_drag <= 0.0
		or lane_steering_speed <= 0.0
		or hull_health <= 0
		or collision_damage <= 0
		or ram_damage <= collision_damage
		or ram_cooldown <= 0.0
		or mounted_attack_cooldown <= 0.0
		or mounted_weapon == null
		or not mounted_weapon.has_method("is_valid_weapon")
		or not mounted_weapon.is_valid_weapon()
	):
		return false
	var previous_lane := -INF
	for lane_y in lane_positions:
		if lane_y <= previous_lane:
			return false
		previous_lane = lane_y
	return true
