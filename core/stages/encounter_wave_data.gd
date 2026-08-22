class_name EncounterWaveData
extends Resource

@export var wave_id: StringName
@export_range(0.0, 10.0, 0.05) var reinforcement_delay := 0.0
@export var spawns: Array[Resource] = []
@export var recipe: Resource
@export_range(0, 5, 1) var recipe_difficulty_tier := 0
@export var recipe_variant_seed := 0


func is_valid_wave() -> bool:
	if wave_id.is_empty() or (spawns.is_empty() and recipe == null) or (not spawns.is_empty() and recipe != null):
		return false
	if recipe != null:
		return recipe.has_method("is_valid_recipe") and recipe.is_valid_recipe() and not resolved_spawns().is_empty()
	for spawn in spawns:
		if spawn == null or not spawn.has_method("is_valid_spawn") or not spawn.is_valid_spawn():
			return false
	return true


func resolved_spawns() -> Array[Resource]:
	if recipe != null and recipe.has_method("build_spawns"):
		return recipe.build_spawns(recipe_difficulty_tier, recipe_variant_seed)
	return spawns


func spawn_count() -> int:
	return resolved_spawns().size()
