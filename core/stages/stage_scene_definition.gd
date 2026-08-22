class_name StageSceneDefinition
extends Resource

enum VisualTheme {
	RUINS,
	COURTYARD,
	PLANT,
	FLOODED_CYPRESS,
	FLOODED_CAMP,
	SPILLWAY,
	HIGHWAY_CANYON,
	HIGHWAY_CHECKPOINT,
	HIGHWAY_OVERPASS,
	INDUSTRIAL_MOTOR_POOL,
	INDUSTRIAL_ASSEMBLY,
	INDUSTRIAL_CRUCIBLE,
}

@export var scene_id: StringName
@export var display_name := ""
@export var transition_subtitle := ""
@export var start_x := 0.0
@export var end_x := 1280.0
@export var environment_id: StringName
@export var visual_theme := VisualTheme.RUINS
@export var background_texture: Texture2D
@export var encounters: Array[Resource] = []
@export var environment_objects: Array[Resource] = []


func is_valid_scene() -> bool:
	if (
		scene_id.is_empty()
		or display_name.is_empty()
		or environment_id.is_empty()
		or background_texture == null
		or end_x <= start_x
	):
		return false
	var encounter_ids := {}
	var previous_trigger := -1.0
	for encounter in encounters:
		if encounter == null or not encounter.has_method("is_valid_encounter") or not encounter.is_valid_encounter():
			return false
		if encounter_ids.has(encounter.encounter_id):
			return false
		if encounter.trigger_x < start_x or encounter.trigger_x >= end_x or encounter.trigger_x <= previous_trigger:
			return false
		encounter_ids[encounter.encounter_id] = true
		previous_trigger = encounter.trigger_x
	var object_ids := {}
	for environment_object in environment_objects:
		if (
			environment_object == null
			or not environment_object.has_method("is_valid_object")
			or not environment_object.is_valid_object()
			or environment_object.position.x < start_x
			or environment_object.position.x >= end_x
			or object_ids.has(environment_object.object_id)
		):
			return false
		object_ids[environment_object.object_id] = true
	return true
