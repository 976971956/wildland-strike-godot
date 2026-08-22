class_name HeldItemMotion
extends RefCounted


static func locomotion_pose(
	walk_phase: float,
	movement_weight: float,
	offset_amplitude := Vector2(2.0, 3.0),
	rotation_amplitude := 0.08
) -> Dictionary:
	var weight := clampf(movement_weight, 0.0, 1.0)
	var angle := walk_phase * PI * 0.5
	return {
		"offset": Vector2(
			sin(angle) * offset_amplitude.x,
			-cos(angle * 2.0) * offset_amplitude.y
		) * weight,
		"rotation": sin(angle + PI * 0.18) * rotation_amplitude * weight,
	}


static func breathing_pose(visual_clock: float, amplitude := Vector2(0.7, 1.1), rotation_amplitude := 0.018) -> Dictionary:
	var angle := visual_clock * 2.4
	return {
		"offset": Vector2(sin(angle * 0.5) * amplitude.x, sin(angle) * amplitude.y),
		"rotation": sin(angle * 0.72) * rotation_amplitude,
	}


static func smoothing_weight(response: float, delta: float) -> float:
	if delta <= 0.0:
		return 1.0
	return 1.0 - exp(-maxf(response, 0.0) * delta)
