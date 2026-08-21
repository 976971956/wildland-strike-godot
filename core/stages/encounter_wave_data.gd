class_name EncounterWaveData
extends Resource

@export var wave_id: StringName
@export_range(0.0, 10.0, 0.05) var reinforcement_delay := 0.0
@export var spawns: Array[Resource] = []


func is_valid_wave() -> bool:
	if wave_id.is_empty() or spawns.is_empty():
		return false
	for spawn in spawns:
		if spawn == null or not spawn.has_method("is_valid_spawn") or not spawn.is_valid_spawn():
			return false
	return true
