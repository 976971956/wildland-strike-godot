class_name EncounterDirector
extends Node

signal encounter_started(encounter: Resource, encounter_index: int)
signal encounter_cleared(encounter: Resource, encounter_index: int)
signal scene_entered(scene: Resource, scene_index: int)
signal stage_completed

var game: Node
var stage_definition: Resource
var encounters: Array[Resource] = []
var scenes: Array[Resource] = []
var current_encounter_index := 0
var current_scene_index := -1
var current_wave_index := -1
var active := false
var remaining_enemies := 0
var reinforcement_timer := 0.0
var completed := false


func configure(p_game: Node, p_stage_definition: Resource) -> void:
	game = p_game
	stage_definition = p_stage_definition
	encounters.clear()
	scenes.clear()
	current_encounter_index = 0
	current_scene_index = -1
	current_wave_index = -1
	active = false
	remaining_enemies = 0
	reinforcement_timer = 0.0
	completed = false
	if (
		stage_definition != null
		and stage_definition.has_method("all_encounters")
		and stage_definition.has_method("is_valid_stage")
		and stage_definition.is_valid_stage()
	):
		encounters = stage_definition.all_encounters()
		scenes = stage_definition.scenes
	if is_instance_valid(game) and not encounters.is_empty():
		game.stage_limit = encounters[0].arena_right


func tick(delta: float, player_x: float) -> void:
	if completed:
		return
	_update_scene(player_x)
	if active:
		if remaining_enemies == 0 and reinforcement_timer > 0.0:
			reinforcement_timer = maxf(0.0, reinforcement_timer - delta)
			if reinforcement_timer <= 0.0:
				_spawn_wave(current_wave_index + 1)
		return
	if current_encounter_index >= encounters.size():
		completed = true
		stage_completed.emit()
		return
	var next_encounter: Resource = encounters[current_encounter_index]
	if player_x >= next_encounter.trigger_x:
		_start_current_encounter()


func force_start_encounter(index: int) -> void:
	if active or index < 0 or index >= encounters.size():
		return
	current_encounter_index = index
	_start_current_encounter()


func enemy_removed(_enemy: Node) -> void:
	if not active or remaining_enemies <= 0:
		return
	remaining_enemies -= 1
	if remaining_enemies > 0:
		return
	var encounter: Resource = encounters[current_encounter_index]
	if current_wave_index + 1 < encounter.waves.size():
		reinforcement_timer = maxf(encounter.waves[current_wave_index + 1].reinforcement_delay, 0.001)
		return
	_complete_current_encounter()


func get_encounter_count() -> int:
	return encounters.size()


func get_encounter(index: int) -> Resource:
	return encounters[index] if index >= 0 and index < encounters.size() else null


func _update_scene(player_x: float) -> void:
	for index in range(scenes.size()):
		var scene: Resource = scenes[index]
		if player_x < scene.start_x or player_x >= scene.end_x:
			continue
		if current_scene_index != index:
			current_scene_index = index
			scene_entered.emit(scene, index)
		return


func _start_current_encounter() -> void:
	if active or current_encounter_index >= encounters.size():
		return
	active = true
	current_wave_index = -1
	remaining_enemies = 0
	reinforcement_timer = 0.0
	var encounter: Resource = encounters[current_encounter_index]
	game.stage_limit = encounter.arena_right
	encounter_started.emit(encounter, current_encounter_index)
	_spawn_wave(0)


func _spawn_wave(index: int) -> void:
	var encounter: Resource = encounters[current_encounter_index]
	if index < 0 or index >= encounter.waves.size():
		return
	current_wave_index = index
	reinforcement_timer = 0.0
	var wave: Resource = encounter.waves[index]
	remaining_enemies = wave.spawns.size()
	for spawn in wave.spawns:
		game.spawn_enemy(Vector2(encounter.origin_x, 0.0) + spawn.offset, String(spawn.enemy_id))


func _complete_current_encounter() -> void:
	var completed_index := current_encounter_index
	var encounter: Resource = encounters[completed_index]
	active = false
	current_wave_index = -1
	remaining_enemies = 0
	reinforcement_timer = 0.0
	current_encounter_index += 1
	game.stage_limit = encounter.unlock_right
	encounter_cleared.emit(encounter, completed_index)
