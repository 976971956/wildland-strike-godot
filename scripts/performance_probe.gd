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


func _process(delta: float) -> void:
	if warmup_frames < WARMUP_FRAMES:
		warmup_frames += 1
		return
	frame_times_ms.append(delta * 1000.0)
	if frame_times_ms.size() < SAMPLE_FRAMES:
		return
	var result := summarize(frame_times_ms)
	result["scenario"] = scenario
	print(LOG_PREFIX + JSON.stringify(result))
	set_process(false)


func _start_combat_benchmark() -> void:
	var game := get_parent()
	if not game.has_method("_start_game") or game.waves.size() < 3:
		scenario = "benchmark_setup_failed"
		return
	game._start_game()
	var wave: Dictionary = game.waves[2]
	game.player.position = Vector2(float(wave["x"]), 560.0)
	game._start_wave(wave)


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
