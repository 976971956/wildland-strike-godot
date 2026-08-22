class_name ArcadeProfile
extends RefCounted

const CURRENT_VERSION := 2
const MAX_HIGH_SCORES := 10
const DEFAULT_PATH := "user://wildland_strike_profile.cfg"

const DEFAULT_SETTINGS := {
	"music_volume": 0.8,
	"sfx_volume": 0.9,
	"screen_shake": true,
	"hit_flash": true,
	"haptics": true,
	"high_contrast_cues": true,
	"touch_scale": 1.0,
	"touch_layout": "classic",
	"ui_scale": 1.0,
	"language": "en",
}
const DEFAULT_BINDINGS := {
	"move_left": KEY_A,
	"move_right": KEY_D,
	"move_up": KEY_W,
	"move_down": KEY_S,
	"attack": KEY_J,
	"jump": KEY_K,
	"special": KEY_L,
	"pause": KEY_P,
}

var file_path := DEFAULT_PATH
var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var high_scores: Array[Dictionary] = []
var bindings: Dictionary = DEFAULT_BINDINGS.duplicate(true)
var loaded_version := CURRENT_VERSION


func _init(path := DEFAULT_PATH) -> void:
	file_path = String(path)


func load_profile() -> int:
	settings = DEFAULT_SETTINGS.duplicate(true)
	bindings = DEFAULT_BINDINGS.duplicate(true)
	high_scores.clear()
	loaded_version = CURRENT_VERSION
	if file_path.is_empty():
		return OK
	var config := ConfigFile.new()
	var error := config.load(file_path)
	if error == ERR_FILE_NOT_FOUND:
		return OK
	if error != OK:
		return error
	loaded_version = int(config.get_value("profile", "version", 0))
	if loaded_version <= 0:
		_load_legacy_settings(config)
	else:
		for key in DEFAULT_SETTINGS:
			settings[key] = config.get_value("settings", key, DEFAULT_SETTINGS[key])
	if loaded_version >= 2:
		for action in DEFAULT_BINDINGS:
			bindings[action] = int(config.get_value("bindings", action, DEFAULT_BINDINGS[action]))
	var stored_scores: Array = config.get_value("scores", "entries", [])
	for entry in stored_scores:
		if entry is Dictionary:
			high_scores.append(_normalize_score(entry))
	_normalize_settings()
	_normalize_bindings()
	_sort_and_trim_scores()
	loaded_version = CURRENT_VERSION
	return OK


func save_profile() -> int:
	if file_path.is_empty():
		return OK
	_normalize_settings()
	_sort_and_trim_scores()
	var config := ConfigFile.new()
	config.set_value("profile", "version", CURRENT_VERSION)
	for key in DEFAULT_SETTINGS:
		config.set_value("settings", key, settings[key])
	for action in DEFAULT_BINDINGS:
		config.set_value("bindings", action, bindings[action])
	config.set_value("scores", "entries", high_scores)
	return config.save(file_path)


func set_setting(key: String, value: Variant) -> bool:
	if not DEFAULT_SETTINGS.has(key):
		return false
	settings[key] = value
	_normalize_settings()
	return true


func set_binding(action: String, physical_keycode: int) -> bool:
	if not DEFAULT_BINDINGS.has(action) or physical_keycode <= 0:
		return false
	bindings[action] = physical_keycode
	_normalize_bindings()
	return true


func record_score(value: int, stage_number: int, player_count: int, operative_name := "RANGER") -> int:
	if value <= 0:
		return -1
	var entry := _normalize_score({
		"name": operative_name,
		"score": value,
		"stage": stage_number,
		"players": player_count,
		"date": Time.get_date_string_from_system(),
	})
	high_scores.append(entry)
	_sort_and_trim_scores()
	for index in range(high_scores.size()):
		if high_scores[index] == entry:
			return index
	return -1


func top_score() -> int:
	return int(high_scores[0].score) if not high_scores.is_empty() else 0


func _load_legacy_settings(config: ConfigFile) -> void:
	var music_percent := float(config.get_value("audio", "music_percent", 80.0))
	var sfx_percent := float(config.get_value("audio", "sfx_percent", 90.0))
	settings.music_volume = music_percent / 100.0
	settings.sfx_volume = sfx_percent / 100.0
	settings.screen_shake = bool(config.get_value("accessibility", "shake", true))
	settings.hit_flash = bool(config.get_value("accessibility", "flash", true))
	settings.haptics = bool(config.get_value("mobile", "haptics", true))


func _normalize_settings() -> void:
	settings.music_volume = clampf(float(settings.get("music_volume", 0.8)), 0.0, 1.0)
	settings.sfx_volume = clampf(float(settings.get("sfx_volume", 0.9)), 0.0, 1.0)
	settings.screen_shake = bool(settings.get("screen_shake", true))
	settings.hit_flash = bool(settings.get("hit_flash", true))
	settings.haptics = bool(settings.get("haptics", true))
	settings.high_contrast_cues = bool(settings.get("high_contrast_cues", true))
	settings.touch_scale = clampf(float(settings.get("touch_scale", 1.0)), 0.75, 1.35)
	var touch_layout := String(settings.get("touch_layout", "classic")).to_lower()
	settings.touch_layout = touch_layout if touch_layout in ["classic", "compact", "left_handed"] else "classic"
	settings.ui_scale = clampf(float(settings.get("ui_scale", 1.0)), 0.85, 1.2)
	var language := String(settings.get("language", "en")).to_lower()
	settings.language = language if language in ["en", "zh"] else "en"


func _normalize_bindings() -> void:
	for action in DEFAULT_BINDINGS:
		var keycode := int(bindings.get(action, DEFAULT_BINDINGS[action]))
		bindings[action] = keycode if keycode > 0 else DEFAULT_BINDINGS[action]


func _normalize_score(entry: Dictionary) -> Dictionary:
	var name := String(entry.get("name", "RANGER")).strip_edges().to_upper()
	if name.is_empty():
		name = "RANGER"
	return {
		"name": name.left(12),
		"score": maxi(int(entry.get("score", 0)), 0),
		"stage": clampi(int(entry.get("stage", 1)), 1, 8),
		"players": clampi(int(entry.get("players", 1)), 1, 3),
		"date": String(entry.get("date", "")),
	}


func _sort_and_trim_scores() -> void:
	high_scores.sort_custom(func(a: Dictionary, b: Dictionary):
		if int(a.score) == int(b.score):
			return int(a.stage) > int(b.stage)
		return int(a.score) > int(b.score)
	)
	while high_scores.size() > MAX_HIGH_SCORES:
		high_scores.pop_back()
