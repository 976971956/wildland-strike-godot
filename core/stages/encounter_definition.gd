class_name EncounterDefinition
extends Resource

@export var encounter_id: StringName
@export var trigger_x := 0.0
@export var origin_x := 0.0
@export var arena_right := 1280.0
@export var unlock_right := 1280.0
@export var banner_title := "FIGHT!"
@export var banner_subtitle := "DEFEAT THEM ALL TO ADVANCE"
@export var reward_id: StringName
@export var waves: Array[Resource] = []


func is_valid_encounter() -> bool:
	if (
		encounter_id.is_empty()
		or trigger_x < 0.0
		or origin_x < trigger_x
		or arena_right <= origin_x
		or unlock_right < arena_right
		or waves.is_empty()
	):
		return false
	var wave_ids := {}
	for wave in waves:
		if wave == null or not wave.has_method("is_valid_wave") or not wave.is_valid_wave():
			return false
		if wave_ids.has(wave.wave_id):
			return false
		wave_ids[wave.wave_id] = true
	return true


func total_spawn_count() -> int:
	var total := 0
	for wave in waves:
		total += wave.spawn_count()
	return total
