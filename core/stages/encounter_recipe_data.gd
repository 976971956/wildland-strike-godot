class_name EncounterRecipeData
extends Resource

const EnemySpawnDataScript = preload("res://core/stages/enemy_spawn_data.gd")

@export var recipe_id: StringName
@export var standard_enemy_ids: Array[StringName] = []
@export var elite_enemy_ids: Array[StringName] = []
@export_range(1, 8, 1) var base_standard_count := 2
@export_range(0, 3, 1) var standard_per_difficulty := 1
@export_range(0, 4, 1) var base_elite_count := 0
@export_range(0, 2, 1) var elite_per_difficulty := 1
@export_range(1, 12, 1) var max_combatants := 8
@export_range(0.0, 10.0, 0.05) var reinforcement_delay := 0.0
@export var formation_offsets: Array[Vector2] = []


func is_valid_recipe() -> bool:
	if recipe_id.is_empty() or standard_enemy_ids.is_empty() or formation_offsets.is_empty():
		return false
	if max_combatants > formation_offsets.size() or base_standard_count > max_combatants:
		return false
	if (base_elite_count > 0 or elite_per_difficulty > 0) and elite_enemy_ids.is_empty():
		return false
	var ids := {}
	for enemy_id in standard_enemy_ids + elite_enemy_ids:
		if enemy_id.is_empty() or ids.has(enemy_id):
			return false
		ids[enemy_id] = true
	return true


func resolved_counts(difficulty_tier: int) -> Vector2i:
	var tier := maxi(0, difficulty_tier)
	var elite_count := base_elite_count + tier * elite_per_difficulty
	elite_count = mini(elite_count, max_combatants - 1)
	var standard_count := base_standard_count + tier * standard_per_difficulty
	standard_count = mini(standard_count, max_combatants - elite_count)
	return Vector2i(standard_count, elite_count)


func build_spawns(difficulty_tier: int = 0, variant_seed: int = 0) -> Array[Resource]:
	var result: Array[Resource] = []
	if not is_valid_recipe():
		return result
	var counts := resolved_counts(difficulty_tier)
	_append_pool_spawns(result, standard_enemy_ids, counts.x, variant_seed)
	_append_pool_spawns(result, elite_enemy_ids, counts.y, variant_seed + counts.x + 1)
	return result


func _append_pool_spawns(result: Array[Resource], pool: Array[StringName], count: int, seed_offset: int) -> void:
	if pool.is_empty():
		return
	for index in range(count):
		var spawn := EnemySpawnDataScript.new()
		spawn.enemy_id = pool[posmod(seed_offset + index, pool.size())]
		spawn.offset = formation_offsets[result.size()]
		result.append(spawn)
