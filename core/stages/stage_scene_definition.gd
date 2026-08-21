class_name StageSceneDefinition
extends Resource

@export var scene_id: StringName
@export var start_x := 0.0
@export var end_x := 1280.0
@export var environment_id: StringName
@export var encounters: Array[Resource] = []


func is_valid_scene() -> bool:
	if scene_id.is_empty() or environment_id.is_empty() or end_x <= start_x:
		return false
	var encounter_ids := {}
	var previous_trigger := -1.0
	for encounter in encounters:
		if encounter == null or not encounter.has_method("is_valid_encounter") or not encounter.is_valid_encounter():
			return false
		if encounter_ids.has(encounter.encounter_id):
			return false
		if encounter.trigger_x < start_x or encounter.unlock_right > end_x or encounter.trigger_x <= previous_trigger:
			return false
		encounter_ids[encounter.encounter_id] = true
		previous_trigger = encounter.trigger_x
	return true
