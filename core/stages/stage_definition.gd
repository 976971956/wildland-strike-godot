class_name StageDefinition
extends Resource

@export var stage_id: StringName
@export_range(1, 8, 1) var stage_number := 1
@export var display_name := ""
@export_range(0.0, 3600.0, 1.0) var time_limit_seconds := 0.0
@export var scenes: Array[Resource] = []


func is_valid_stage() -> bool:
	if stage_id.is_empty() or display_name.is_empty() or scenes.is_empty():
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
	return true


func all_encounters() -> Array[Resource]:
	var result: Array[Resource] = []
	for scene in scenes:
		result.append_array(scene.encounters)
	return result


func end_x() -> float:
	return scenes[-1].end_x if not scenes.is_empty() else 1280.0
