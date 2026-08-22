class_name ArcadeSfxLibrary
extends RefCounted

const SAMPLE_RATE := 22050
const FALLBACK_EVENT := &"ui_confirm"

# frequency, duration, harmonic ratio/gain, noise gain, pitch drop,
# voice volume, priority, music duck and duck duration.
const PROFILES := {
	&"start": [520.0, 0.22, 1.50, 0.18, 0.08, -7.0, 3, -2.0, 0.12],
	&"alert": [230.0, 0.18, 2.00, 0.22, 0.22, -8.0, 3, -3.0, 0.14],
	&"jump": [420.0, 0.09, 1.50, 0.08, -0.18, -11.0, 1, 0.0, 0.0],
	&"swing": [180.0, 0.055, 2.35, 0.26, 0.42, -12.0, 1, 0.0, 0.0],
	&"heavy_swing": [118.0, 0.095, 1.42, 0.48, 0.52, -7.0, 4, -2.0, 0.08],
	&"whip_crack": [520.0, 0.055, 2.60, 0.72, 0.38, -6.0, 4, -2.5, 0.08],
	&"shock": [740.0, 0.11, 1.76, 0.28, -0.18, -5.0, 5, -3.0, 0.12],
	&"enemy_swing": [132.0, 0.065, 1.72, 0.30, 0.46, -13.0, 1, 0.0, 0.0],
	&"dinosaur_wake": [174.0, 0.22, 1.34, 0.38, 0.24, -6.0, 5, -3.0, 0.14],
	&"dinosaur_enrage": [88.0, 0.34, 1.82, 0.62, 0.48, -2.5, 7, -7.0, 0.28],
	&"hit": [112.0, 0.075, 2.35, 0.68, 0.52, -4.5, 4, -2.5, 0.07],
	&"heavy": [74.0, 0.13, 1.48, 0.74, 0.58, -2.5, 6, -5.0, 0.13],
	&"hurt": [96.0, 0.10, 1.32, 0.52, 0.34, -7.0, 4, -2.0, 0.09],
	&"special": [650.0, 0.18, 1.25, 0.18, -0.12, -5.0, 5, -3.5, 0.12],
	&"team_attack": [820.0, 0.28, 1.50, 0.42, 0.24, -2.0, 8, -8.0, 0.24],
	&"impact_crack": [188.0, 0.085, 3.10, 0.82, 0.60, -3.0, 6, -4.0, 0.10],
	&"impact_snap": [312.0, 0.04, 2.75, 0.48, 0.35, -7.0, 4, -1.5, 0.05],
	&"impact_clash": [425.0, 0.075, 1.41, 0.38, 0.18, -4.0, 6, -4.0, 0.10],
	&"body_slam": [58.0, 0.17, 1.50, 0.78, 0.64, -2.0, 7, -6.5, 0.16],
	&"special_burst": [760.0, 0.15, 1.20, 0.34, 0.30, -3.5, 6, -5.0, 0.14],
	&"enemy_down": [62.0, 0.20, 1.37, 0.72, 0.68, -5.0, 5, -3.5, 0.14],
	&"boss_warning": [145.0, 0.32, 1.50, 0.34, 0.42, -3.0, 7, -7.0, 0.28],
	&"boss_phase": [52.0, 0.38, 2.00, 0.56, 0.62, -1.5, 8, -8.0, 0.34],
	&"gunshot": [930.0, 0.085, 0.50, 0.84, 0.72, -3.0, 6, -5.5, 0.10],
	&"shotgun": [152.0, 0.14, 1.25, 0.96, 0.64, -1.5, 8, -8.0, 0.20],
	&"rifle": [710.0, 0.12, 0.72, 0.88, 0.66, -2.0, 7, -6.5, 0.15],
	&"smg_burst": [1120.0, 0.13, 0.52, 0.78, 0.58, -4.0, 6, -5.0, 0.13],
	&"throw": [264.0, 0.075, 1.33, 0.44, 0.40, -6.0, 4, -2.5, 0.08],
	&"molotov_throw": [310.0, 0.10, 1.38, 0.46, 0.44, -5.0, 4, -2.5, 0.10],
	&"fire_burst": [86.0, 0.27, 2.10, 0.86, 0.28, -2.0, 7, -7.0, 0.24],
	&"rocket_launch": [96.0, 0.24, 1.60, 0.82, -0.24, -1.5, 8, -8.0, 0.22],
	&"mine_drop": [196.0, 0.09, 1.50, 0.28, 0.34, -7.0, 4, -2.0, 0.08],
	&"prop_throw": [152.0, 0.11, 1.40, 0.52, 0.48, -5.0, 5, -3.5, 0.11],
	&"prop_break": [92.0, 0.16, 2.20, 0.88, 0.62, -2.5, 7, -6.0, 0.17],
	&"explosion": [54.0, 0.24, 1.70, 0.92, 0.72, -1.0, 8, -9.0, 0.24],
	&"pickup": [880.0, 0.12, 1.50, 0.08, -0.22, -7.0, 3, -1.5, 0.08],
	&"victory": [740.0, 0.35, 1.25, 0.12, -0.08, -3.5, 7, -6.0, 0.28],
	&"bonus_tally": [1040.0, 0.22, 1.50, 0.06, -0.10, -6.0, 4, -2.0, 0.10],
	&"ui_confirm": [440.0, 0.07, 1.50, 0.05, 0.04, -10.0, 2, 0.0, 0.0],
}


static func has_event(kind: StringName) -> bool:
	return PROFILES.has(kind)


static func event_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for kind in PROFILES:
		names.append(kind)
	names.sort()
	return names


static func profile(kind: StringName) -> Dictionary:
	var resolved: StringName = kind if PROFILES.has(kind) else FALLBACK_EVENT
	var values: Array = PROFILES[resolved]
	return {
		"event": resolved,
		"frequency": float(values[0]),
		"duration": float(values[1]),
		"harmonic_ratio": float(values[2]),
		"harmonic_gain": 0.18,
		"noise_gain": float(values[3]),
		"pitch_drop": float(values[4]),
		"volume_db": float(values[5]),
		"priority": int(values[6]),
		"duck_db": float(values[7]),
		"duck_duration": float(values[8]),
	}


static func build_stream(kind: StringName) -> AudioStreamWAV:
	var cfg := profile(kind)
	var count := maxi(1, int(SAMPLE_RATE * cfg.duration))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var event_seed := _event_seed(cfg.event)
	for sample_index in range(count):
		var progress := float(sample_index) / count
		var envelope := pow(maxf(1.0 - progress, 0.0), 2.25)
		var frequency: float = cfg.frequency * (1.0 - progress * cfg.pitch_drop)
		frequency = maxf(frequency, 24.0)
		var time := float(sample_index) / SAMPLE_RATE
		var fundamental := sin(TAU * frequency * time)
		var harmonic := sin(TAU * frequency * cfg.harmonic_ratio * time + 0.35)
		var transient := pow(maxf(1.0 - progress * 4.5, 0.0), 1.8)
		var deterministic_noise := _noise_sample(sample_index, event_seed)
		var wave: float = fundamental * 0.72 + harmonic * cfg.harmonic_gain
		wave += deterministic_noise * cfg.noise_gain * transient
		var sample := int(clampf(wave * envelope, -1.0, 1.0) * 28000.0)
		bytes[sample_index * 2] = sample & 0xff
		bytes[sample_index * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


static func _event_seed(kind: StringName) -> int:
	var result := 216613626
	for character in String(kind).to_utf8_buffer():
		result = int((result ^ character) * 16777619) & 0x7fffffff
	return result


static func _noise_sample(sample_index: int, seed_value: int) -> float:
	var value := sin((sample_index + seed_value % 997) * 12.9898) * 43758.5453
	return (value - floor(value)) * 2.0 - 1.0
