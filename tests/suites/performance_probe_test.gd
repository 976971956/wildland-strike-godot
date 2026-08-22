extends RefCounted

const PerformanceProbe = preload("res://scripts/performance_probe.gd")


func run(test) -> void:
	var empty_summary := PerformanceProbe.summarize(PackedFloat64Array())
	test.check(empty_summary.is_empty(), "empty performance sample should produce no summary")

	var samples := PackedFloat64Array([16.0, 16.0, 16.0, 20.0, 40.0])
	var summary: Dictionary = PerformanceProbe.summarize(samples)
	test.check(summary["sample_frames"] == 5, "performance sample count is incorrect")
	test.check(is_equal_approx(summary["average_ms"], 21.6), "average frame time is incorrect")
	test.check(is_equal_approx(summary["average_fps"], 1000.0 / 21.6), "average FPS is incorrect")
	test.check(summary["p50_ms"] == 16.0, "P50 frame time is incorrect")
	test.check(summary["p95_ms"] == 40.0, "P95 frame time is incorrect")
	test.check(summary["p99_ms"] == 40.0, "P99 frame time is incorrect")
	test.check(summary["frames_over_20_ms"] == 1, "over-20ms frame count is incorrect")
	test.check(summary["frames_over_33_ms"] == 1, "over-33ms frame count is incorrect")
	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(
		probe_source.contains("__wildlandPerformanceJson")
		and probe_source.contains("data-wildland-performance"),
		"Web benchmark result is not exposed to browser automation"
	)
	test.check(probe_source.contains("boss_preview=1") and probe_source.contains("boss_preview=2"), "reproducible boss visual previews are missing")
	test.check(probe_source.contains("scene_preview=2") and probe_source.contains("scene_preview=3"), "reproducible scene-art previews are missing")
	test.check(probe_source.contains("victory_preview=1"), "reproducible victory presentation preview is missing")
	test.check(probe_source.contains("stage2_preview=2") and probe_source.contains("_start_stage_2_preview"), "reproducible Stage 2 visual preview is missing")
	test.check(probe_source.contains("stage3_preview=2") and probe_source.contains("_start_stage_3_preview"), "reproducible Stage 3 vehicle preview is missing")
	test.check(probe_source.contains("stage4_preview=2") and probe_source.contains("_start_stage_4_preview"), "reproducible Stage 4 industrial preview is missing")
	test.check(probe_source.contains("roster_preview=1"), "reproducible enemy-roster preview is missing")
	test.check(probe_source.contains("hud_preview=1") and probe_source.contains("hud_preview=2"), "desktop/touch HUD previews are missing")
	test.check(probe_source.contains("stage_acceptance=1"), "reproducible Web Stage 1 acceptance entry is missing")
	test.check(probe_source.contains("__wildlandStageAcceptanceJson"), "Web Stage 1 acceptance result is not observable")
	test.check(probe_source.contains("formation_acceptance=1"), "reproducible Web enemy-formation acceptance entry is missing")
