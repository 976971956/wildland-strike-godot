class_name StageDefinition
extends Resource

@export var stage_id: StringName
@export_range(1, 8, 1) var stage_number := 1
@export var display_name := ""
@export var route_subtitle := ""
@export var clear_message := "AREA SECURED"
@export var map_position := Vector2.ZERO
@export_range(0.0, 3600.0, 1.0) var time_limit_seconds := 0.0
@export_range(0.5, 3.0, 0.01) var enemy_health_scale := 1.0
@export_range(0.5, 3.0, 0.01) var enemy_damage_scale := 1.0
@export_range(0, 50000, 100) var clear_bonus := 5000
@export_range(0, 100, 1) var time_bonus_per_second := 10
@export_range(0, 10000, 100) var life_bonus_per_continue := 1000
@export var scenes: Array[Resource] = []
@export var vehicle_sequence: Resource


func is_valid_stage() -> bool:
	if stage_id.is_empty() or display_name.is_empty() or route_subtitle.is_empty() or clear_message.is_empty() or scenes.is_empty():
		return false
	if map_position == Vector2.ZERO or enemy_health_scale < 1.0 or enemy_damage_scale < 1.0 or clear_bonus <= 0 or time_bonus_per_second <= 0 or life_bonus_per_continue <= 0:
		return false
	var scene_ids := {}
	var previous_end := -1.0
	var encounter_ids := {}
	for scene in scenes:
		if scene == null or not scene.has_method("is_valid_scene") or not scene.is_valid_scene():
			return false
		if scene_ids.has(scene.scene_id) or scene.start_x < previous_end:
			return false
		scene_ids[scene.scene_id] = true
		previous_end = scene.end_x
		for encounter in scene.encounters:
			if encounter_ids.has(encounter.encounter_id):
				return false
			if encounter.unlock_right > end_x():
				return false
			encounter_ids[encounter.encounter_id] = true
	if vehicle_sequence != null:
		if not vehicle_sequence.has_method("is_valid_vehicle_stage") or not vehicle_sequence.is_valid_vehicle_stage():
			return false
		if vehicle_sequence.start_x < scenes[0].start_x or vehicle_sequence.end_x > end_x():
			return false
	return true


func is_vehicle_stage() -> bool:
	return vehicle_sequence != null and vehicle_sequence.has_method("is_valid_vehicle_stage") and vehicle_sequence.is_valid_vehicle_stage()


func all_encounters() -> Array[Resource]:
	var result: Array[Resource] = []
	for scene in scenes:
		result.append_array(scene.encounters)
	return result


func end_x() -> float:
	return scenes[-1].end_x if not scenes.is_empty() else 1280.0
