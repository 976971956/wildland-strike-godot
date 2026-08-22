class_name ArcadeMusicDirector
extends Node

enum Cue {
	SILENT,
	TITLE,
	STAGE,
	BOSS,
	VICTORY,
	ENDING,
	CREDITS,
}

const SAMPLE_RATE := 22050
const BASE_VOLUME_DB := -12.0

var current_cue := Cue.SILENT
var current_variant := 0
var cue_history: Array[int] = []
var variant_history: Array[int] = []
var stream_cache := {}
var player: AudioStreamPlayer
var duck_time_remaining := 0.0
var duck_volume_db := 0.0
var last_duck_db := 0.0
var last_duck_duration := 0.0
var master_volume_ratio := 0.8


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	player = AudioStreamPlayer.new()
	player.volume_db = _base_volume_db()
	add_child(player)
	set_process(true)


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	duck_time_remaining = maxf(0.0, duck_time_remaining - delta)
	if duck_time_remaining > 0.0:
		player.volume_db = minf(player.volume_db, _base_volume_db() + duck_volume_db)
	else:
		duck_volume_db = move_toward(duck_volume_db, 0.0, delta * 24.0)
		player.volume_db = move_toward(player.volume_db, _base_volume_db() + duck_volume_db, delta * 30.0)


func set_master_volume_ratio(value: float) -> void:
	master_volume_ratio = clampf(value, 0.0, 1.0)
	if is_instance_valid(player):
		player.volume_db = _base_volume_db() + duck_volume_db


func _base_volume_db() -> float:
	return -80.0 if master_volume_ratio <= 0.0 else BASE_VOLUME_DB + linear_to_db(master_volume_ratio)


func duck(amount_db: float, duration: float) -> void:
	if amount_db >= 0.0 or duration <= 0.0:
		return
	last_duck_db = amount_db
	last_duck_duration = duration
	duck_volume_db = minf(duck_volume_db, amount_db)
	duck_time_remaining = maxf(duck_time_remaining, duration)
	if is_instance_valid(player):
		player.volume_db = minf(player.volume_db, _base_volume_db() + duck_volume_db)


func play_cue(cue: int, variant: int = 0) -> void:
	var resolved_variant := posmod(variant, 8) if cue in [Cue.STAGE, Cue.BOSS] else 0
	if cue == current_cue and resolved_variant == current_variant:
		return
	current_cue = cue
	current_variant = resolved_variant
	cue_history.append(cue)
	variant_history.append(resolved_variant)
	if cue_history.size() > 16:
		cue_history.pop_front()
		variant_history.pop_front()
	if not is_instance_valid(player):
		return
	if cue == Cue.SILENT:
		player.stop()
		return
	var cache_key := "%d:%d" % [cue, resolved_variant]
	if not stream_cache.has(cache_key):
		stream_cache[cache_key] = build_stream(cue, resolved_variant)
	player.stream = stream_cache[cache_key]
	player.play()


static func build_stream(cue: int, variant: int = 0) -> AudioStreamWAV:
	var bpm := 126.0
	var melody := PackedInt32Array([64, 67, 71, 67, 62, 64, 67, -1, 64, 67, 74, 71, 67, 64, 62, -1, 59, 62, 67, 64, 59, 62, 64, -1, 57, 59, 62, 64, 67, 64, 62, -1])
	var bass := PackedInt32Array([40, 40, 43, 43, 38, 38, 35, 35])
	var looped := true
	var arrangement := posmod(variant, 8)
	var duty := 0.34
	var lead_gain := 0.34
	if cue == Cue.TITLE:
		bpm = 112.0
		melody = PackedInt32Array([52, 55, 59, 64, 62, 59, 55, -1, 52, 55, 60, 64, 67, 64, 60, -1, 59, 62, 67, 71, 67, 64, 62, -1])
		bass = PackedInt32Array([28, 35, 36, 31, 28, 35])
		duty = 0.28
	elif cue == Cue.STAGE:
		var stage_transpositions := PackedInt32Array([0, 2, -2, 5, -5, 3, -3, 7])
		melody = _arrange_sequence(melody, stage_transpositions[arrangement], arrangement * 3)
		bass = _arrange_sequence(bass, stage_transpositions[arrangement], arrangement)
		bpm = [126.0, 132.0, 118.0, 138.0, 124.0, 142.0, 130.0, 146.0][arrangement]
		duty = 0.24 + arrangement * 0.025
		lead_gain = 0.31 + (arrangement % 3) * 0.025
	elif cue == Cue.BOSS:
		bpm = [148.0, 154.0, 144.0, 160.0, 150.0, 164.0, 156.0, 168.0][arrangement]
		melody = PackedInt32Array([52, -1, 52, 55, 58, 57, 55, -1, 52, 64, 63, 58, 57, 55, 52, -1, 50, -1, 50, 55, 58, 57, 53, -1, 50, 62, 61, 58, 57, 53, 50, -1])
		bass = PackedInt32Array([28, 28, 31, 31, 26, 26, 25, 25])
		var boss_transpositions := PackedInt32Array([0, 1, -2, 3, -4, 5, -5, 7])
		melody = _arrange_sequence(melody, boss_transpositions[arrangement], arrangement * 2)
		bass = _arrange_sequence(bass, boss_transpositions[arrangement], arrangement)
		duty = 0.46 - arrangement * 0.02
		lead_gain = 0.38
	elif cue == Cue.VICTORY:
		bpm = 132.0
		melody = PackedInt32Array([60, 64, 67, 72, 67, 72, 76, 79, 76, 79, 84, 88, 84, 88, 91, 96])
		bass = PackedInt32Array([36, 43, 48, 55])
		looped = false
	elif cue == Cue.ENDING:
		bpm = 96.0
		melody = PackedInt32Array([55, 59, 62, 67, 71, 67, 64, 62, 59, 62, 67, 71, 74, 71, 67, 64, 62, 59, 55, -1, 60, 64, 67, 72])
		bass = PackedInt32Array([31, 38, 36, 43, 31, 36])
		looped = false
		duty = 0.22
	elif cue == Cue.CREDITS:
		bpm = 108.0
		melody = PackedInt32Array([60, 64, 67, 72, 71, 67, 64, -1, 57, 60, 64, 69, 67, 64, 60, -1, 55, 59, 62, 67, 64, 62, 59, -1])
		bass = PackedInt32Array([36, 43, 33, 40, 31, 38])
		duty = 0.30
	elif cue != Cue.TITLE:
		return _empty_stream()

	var step_duration := 60.0 / bpm * 0.5
	var duration := step_duration * melody.size()
	var sample_count := ceili(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time := float(sample_index) / SAMPLE_RATE
		var step := mini(int(time / step_duration), melody.size() - 1)
		var local_time := fmod(time, step_duration)
		var step_progress := local_time / step_duration
		var envelope := pow(maxf(1.0 - step_progress, 0.0), 1.65)
		var value := 0.0
		var melody_note := melody[step]
		if melody_note >= 0:
			var melody_frequency := _midi_frequency(melody_note)
			value += _pulse_wave(time, melody_frequency, duty) * envelope * lead_gain
			value += sin(TAU * melody_frequency * 2.0 * time) * envelope * 0.08
		var bass_note := bass[(step / 4) % bass.size()]
		var bass_frequency := _midi_frequency(bass_note)
		value += _pulse_wave(time, bass_frequency, 0.5) * 0.19
		if step % 4 == 0:
			var kick_envelope := pow(maxf(1.0 - local_time / minf(step_duration, 0.16), 0.0), 2.4)
			value += sin(TAU * (82.0 - local_time * 190.0) * local_time) * kick_envelope * 0.38
		if step % 8 == 4:
			var snare_envelope := pow(maxf(1.0 - local_time / minf(step_duration, 0.13), 0.0), 3.0)
			var metallic_noise := sin(sample_index * 1.731) + sin(sample_index * 0.517)
			value += metallic_noise * snare_envelope * 0.13
		var sample := int(clampf(value, -1.0, 1.0) * 27000.0)
		bytes[sample_index * 2] = sample & 0xff
		bytes[sample_index * 2 + 1] = (sample >> 8) & 0xff

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looped else AudioStreamWAV.LOOP_DISABLED
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream


static func _arrange_sequence(source: PackedInt32Array, transposition: int, rotation: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(source.size())
	for index in range(source.size()):
		var note := source[posmod(index + rotation, source.size())]
		result[index] = note + transposition if note >= 0 else -1
	return result


static func _empty_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = PackedByteArray([0, 0])
	return stream


static func _midi_frequency(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)


static func _pulse_wave(time: float, frequency: float, duty: float) -> float:
	return 1.0 if fmod(time * frequency, 1.0) < duty else -1.0
