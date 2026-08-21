class_name ArcadeMusicDirector
extends Node

enum Cue {
	SILENT,
	STAGE,
	BOSS,
	VICTORY,
}

const SAMPLE_RATE := 22050
const BASE_VOLUME_DB := -12.0

var current_cue := Cue.SILENT
var cue_history: Array[int] = []
var stream_cache := {}
var player: AudioStreamPlayer
var duck_time_remaining := 0.0
var duck_volume_db := 0.0
var last_duck_db := 0.0
var last_duck_duration := 0.0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	player = AudioStreamPlayer.new()
	player.volume_db = BASE_VOLUME_DB
	add_child(player)
	set_process(true)


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	duck_time_remaining = maxf(0.0, duck_time_remaining - delta)
	if duck_time_remaining > 0.0:
		player.volume_db = minf(player.volume_db, BASE_VOLUME_DB + duck_volume_db)
	else:
		duck_volume_db = move_toward(duck_volume_db, 0.0, delta * 24.0)
		player.volume_db = move_toward(player.volume_db, BASE_VOLUME_DB + duck_volume_db, delta * 30.0)


func duck(amount_db: float, duration: float) -> void:
	if amount_db >= 0.0 or duration <= 0.0:
		return
	last_duck_db = amount_db
	last_duck_duration = duration
	duck_volume_db = minf(duck_volume_db, amount_db)
	duck_time_remaining = maxf(duck_time_remaining, duration)
	if is_instance_valid(player):
		player.volume_db = minf(player.volume_db, BASE_VOLUME_DB + duck_volume_db)


func play_cue(cue: int) -> void:
	if cue == current_cue:
		return
	current_cue = cue
	cue_history.append(cue)
	if cue_history.size() > 16:
		cue_history.pop_front()
	if not is_instance_valid(player):
		return
	if cue == Cue.SILENT:
		player.stop()
		return
	if not stream_cache.has(cue):
		stream_cache[cue] = build_stream(cue)
	player.stream = stream_cache[cue]
	player.play()


static func build_stream(cue: int) -> AudioStreamWAV:
	var bpm := 126.0
	var melody := PackedInt32Array([64, 67, 71, 67, 62, 64, 67, -1, 64, 67, 74, 71, 67, 64, 62, -1, 59, 62, 67, 64, 59, 62, 64, -1, 57, 59, 62, 64, 67, 64, 62, -1])
	var bass := PackedInt32Array([40, 40, 43, 43, 38, 38, 35, 35])
	var looped := true
	if cue == Cue.BOSS:
		bpm = 148.0
		melody = PackedInt32Array([52, -1, 52, 55, 58, 57, 55, -1, 52, 64, 63, 58, 57, 55, 52, -1, 50, -1, 50, 55, 58, 57, 53, -1, 50, 62, 61, 58, 57, 53, 50, -1])
		bass = PackedInt32Array([28, 28, 31, 31, 26, 26, 25, 25])
	elif cue == Cue.VICTORY:
		bpm = 132.0
		melody = PackedInt32Array([60, 64, 67, 72, 67, 72, 76, 79, 76, 79, 84, 88, 84, 88, 91, 96])
		bass = PackedInt32Array([36, 43, 48, 55])
		looped = false
	elif cue != Cue.STAGE:
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
			value += _pulse_wave(time, melody_frequency, 0.34) * envelope * 0.34
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
