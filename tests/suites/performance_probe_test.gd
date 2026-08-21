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
