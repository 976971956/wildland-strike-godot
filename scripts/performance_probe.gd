class_name RuntimePerformanceProbe
extends Node

const WARMUP_FRAMES := 60
const SAMPLE_FRAMES := 300
const LOG_PREFIX := "WEB_PERFORMANCE_BASELINE "

var warmup_frames := 0
var frame_times_ms := PackedFloat64Array()
var scenario := "title"


func _ready() -> void:
	var is_web := OS.has_feature("web")
	set_process(is_web)
	if is_web:
		var query_string := String(JavaScriptBridge.eval("window.location.search"))
		if "baseline_benchmark=1" in query_string:
			scenario = "four_enemy_wave"
			call_deferred("_start_combat_benchmark")
		elif "boss_preview=2" in query_string:
			scenario = "boss_overdrive_preview"
			call_deferred("_start_boss_preview", true)
		elif "boss_preview=1" in query_string:
			scenario = "boss_command_preview"
			call_deferred("_start_boss_preview", false)
		elif "scene_preview=3" in query_string:
			scenario = "processing_plant_preview"
			call_deferred("_start_scene_preview", 2)
		elif "scene_preview=2" in query_string:
			scenario = "flooded_courtyard_preview"
			call_deferred("_start_scene_preview", 1)


func _process(delta: float) -> void:
	if warmup_frames < WARMUP_FRAMES:
		warmup_frames += 1
		return
	frame_times_ms.append(delta * 1000.0)
	if frame_times_ms.size() < SAMPLE_FRAMES:
		return
	var result := summarize(frame_times_ms)
	result["scenario"] = scenario
	var result_json := JSON.stringify(result)
	print(LOG_PREFIX + result_json)
	if OS.has_feature("web"):
		var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
		browser_window.__wildlandPerformanceJson = result_json
		var browser_document: JavaScriptObject = JavaScriptBridge.get_interface("document")
		browser_document.body.setAttribute("data-wildland-performance", result_json)
	set_process(false)


func _start_combat_benchmark() -> void:
	var game := get_parent()
	if not game.has_method("_start_game") or game.encounter_director.get_encounter_count() < 3:
		scenario = "benchmark_setup_failed"
		return
	game._start_game()
	var encounter: Resource = game.encounter_director.get_encounter(2)
	game.player.position = Vector2(encounter.origin_x, 560.0)
	game.encounter_director.force_start_encounter(2)


func _start_boss_preview(force_overdrive: bool) -> void:
	var game := get_parent()
	if not game.has_method("_start_game") or game.encounter_director.get_encounter_count() < 4:
		scenario = "boss_preview_setup_failed"
		return
	game._start_game()
	var encounter: Resource = game.encounter_director.get_encounter(3)
	game.player.position = Vector2(encounter.origin_x, 560.0)
	game.encounter_director._update_scene(encounter.origin_x)
	game.encounter_director.force_start_encounter(3)
	# The normal campaign enters the plant well before the boss trigger. A
	# direct visual-QA jump suppresses that unrelated scene-entry card.
	game.hud.banner_time = 0.0
	if not force_overdrive:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.definition.is_boss:
			enemy.invulnerable = 0.0
			enemy.take_hit(9999, Vector2(300.0, -60.0), true)
			return


func _start_scene_preview(scene_index: int) -> void:
	var game := get_parent()
	if (
		not game.has_method("_start_game")
		or scene_index < 0
		or scene_index >= game.encounter_director.scenes.size()
	):
		scenario = "scene_preview_setup_failed"
		return
	game._start_game()
	var scene: Resource = game.encounter_director.scenes[scene_index]
	var camera_center_x: float = (scene.start_x + scene.end_x) * 0.5
	game.encounter_director.completed = true
	game.player.position = Vector2(camera_center_x - 280.0, 560.0)
	game.camera.position.x = camera_center_x
	game.encounter_director._update_scene(game.player.position.x)
	game.hud.banner_time = 0.0
	game.player.set_physics_process(false)


static func summarize(samples_ms: PackedFloat64Array) -> Dictionary:
	if samples_ms.is_empty():
		return {}
	var sorted := samples_ms.duplicate()
	sorted.sort()
	var total_ms := 0.0
	var frames_over_20_ms := 0
	var frames_over_33_ms := 0
	for frame_ms in samples_ms:
		total_ms += frame_ms
		if frame_ms > 20.0:
			frames_over_20_ms += 1
		if frame_ms > 33.34:
			frames_over_33_ms += 1
	var average_ms := total_ms / samples_ms.size()
	return {
		"sample_frames": samples_ms.size(),
		"average_ms": average_ms,
		"average_fps": 1000.0 / average_ms,
		"p50_ms": _percentile(sorted, 0.50),
		"p95_ms": _percentile(sorted, 0.95),
		"p99_ms": _percentile(sorted, 0.99),
		"frames_over_20_ms": frames_over_20_ms,
		"frames_over_33_ms": frames_over_33_ms,
	}


static func _percentile(sorted_samples: PackedFloat64Array, fraction: float) -> float:
	var index := clampi(ceili(sorted_samples.size() * fraction) - 1, 0, sorted_samples.size() - 1)
	return sorted_samples[index]
