extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const ImpactScript = preload("res://scripts/impact_fx.gd")
const StageObjectScript = preload("res://scripts/stage_object.gd")
const WeaponProjectileScript = preload("res://scripts/weapon_projectile.gd")
const TidalWaveScript = preload("res://scripts/tidal_wave.gd")
const HighwayVehicleScript = preload("res://scripts/highway_vehicle.gd")
const RoadMineScript = preload("res://scripts/road_mine.gd")
const FurnaceWaveScript = preload("res://scripts/furnace_wave.gd")
const SeismicFractureScript = preload("res://scripts/seismic_fracture.gd")
const VaultEnergyLaneScript = preload("res://scripts/vault_energy_lane.gd")
const GenesisCollapseZoneScript = preload("res://scripts/genesis_collapse_zone.gd")
const EncounterDirectorScript = preload("res://stages/encounter_director.gd")
const MusicDirectorScript = preload("res://scripts/music_director.gd")
const SfxLibraryScript = preload("res://scripts/sfx_library.gd")
const LocalPlayerRegistryScript = preload("res://core/input/local_player_registry.gd")
const DeviceInputSourceScript = preload("res://core/input/device_input_source.gd")
const ArcadeProfileScript = preload("res://core/persistence/arcade_profile.gd")
const Localization = preload("res://core/localization/arcade_localization.gd")
const STAGE_1_DEFINITION = preload("res://data/stages/stage_1/stage_1.tres")
const STAGE_2_DEFINITION = preload("res://data/stages/stage_2/stage_2.tres")
const STAGE_3_DEFINITION = preload("res://data/stages/stage_3/stage_3.tres")
const STAGE_4_DEFINITION = preload("res://data/stages/stage_4/stage_4.tres")
const STAGE_5_DEFINITION = preload("res://data/stages/stage_5/stage_5.tres")
const STAGE_6_DEFINITION = preload("res://data/stages/stage_6/stage_6.tres")
const STAGE_7_DEFINITION = preload("res://data/stages/stage_7/stage_7.tres")
const STAGE_8_DEFINITION = preload("res://data/stages/stage_8/stage_8.tres")
const CAMPAIGN_STAGE_DEFINITIONS := [STAGE_1_DEFINITION, STAGE_2_DEFINITION, STAGE_3_DEFINITION, STAGE_4_DEFINITION, STAGE_5_DEFINITION, STAGE_6_DEFINITION, STAGE_7_DEFINITION, STAGE_8_DEFINITION]
const TEAM_ATTACK = preload("res://data/attacks/player_team_attack.tres")
const HERO_DEFINITIONS := [
	preload("res://data/heroes/ranger.tres"),
	preload("res://data/heroes/mara.tres"),
	preload("res://data/heroes/kestrel.tres"),
	preload("res://data/heroes/atlas.tres"),
]

@onready var actors: Node2D = $Actors
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD/UI
@onready var touch_controls: Control = $HUD/TouchControls
@onready var world_art: Node2D = $WorldArt

var player
var players: Array[Node] = []
var local_player_registry = LocalPlayerRegistryScript.new()
var stage_limit := 1080.0
var encounter_director: Node
var music_director: Node
var arcade_profile
var settings: Dictionary = ArcadeProfileScript.DEFAULT_SETTINGS.duplicate(true)
var stage_index: int:
	get:
		return encounter_director.current_encounter_index if is_instance_valid(encounter_director) else 0
var wave_active: bool:
	get:
		return encounter_director.active if is_instance_valid(encounter_director) else false
var remaining_enemies: int:
	get:
		return encounter_director.remaining_enemies if is_instance_valid(encounter_director) else 0
var stage_time_remaining := 0.0
var campaign_stage_index := 0
var active_stage_definition: Resource
var highway_vehicle: Node
var stage_timed_out := false
var score := 0
var lives := 2
var state := "title"
var shake_time := 0.0
var shake_strength := 0.0
var hit_stop_serial := 0
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_index := 0
var sfx_stream_cache := {}
var sfx_voice_priorities: Array[int] = []
var sfx_voice_serials: Array[int] = []
var sfx_voice_serial := 0
var enemy_spawn_serial := 0
var selected_hero_index := 0
var sfx_event_history: Array[StringName] = []
var last_impact_profile_id: StringName
var last_hit_stop_duration := 0.0
var last_haptic_duration_ms := 0
var last_haptic_strength := 0.0
var boss_phase_history: Array[StringName] = []
var boss_health_ledger := {}
var boss_node_ledger := {}
var victory_phase := &"none"
var victory_timer := 0.0
var victory_time_bonus := 0
var victory_life_bonus := 0
var victory_clear_bonus := 0
var victory_bonus_applied := false
var campaign_map_target_index := 0
var completed_stage_count := 0
var campaign_completion_bonus := 20000
var campaign_completion_bonus_applied := false
var shared_camera_zoom := 1.0
var joy_selection_axis_latch := {}
var downed_time_remaining := {}
var continue_respawn_time := {}
var team_attack_requests := {}
var team_attack_count := 0
var last_team_attack_participants: Array[int] = []
var last_team_attack_hits := 0
var title_idle_time := 0.0
var options_selected_index := 0
var options_return_state := "title"
var final_score_recorded := false
var final_score_rank := -1
var control_selected_index := 0
var pending_rebind_action := ""
var original_key_events := {}
var disconnected_player_snapshots := {}
var suspended_by_os := false

const PLAYER_SPAWN_OFFSETS := [
	Vector2(0.0, 0.0),
	Vector2(-72.0, -58.0),
	Vector2(-72.0, 58.0),
]
const MIN_SAFE_SPAWN_DISTANCE := 70.0
const MIN_SHARED_CAMERA_ZOOM := 0.72
const COOP_ENEMY_HEALTH_SCALES := [1.0, 1.4, 1.7]
const COOP_ENEMY_DAMAGE_SCALES := [1.0, 1.08, 1.16]
const TEAMMATE_REVIVE_WINDOW := 8.0
const TEAMMATE_REVIVE_DISTANCE := 96.0
const TEAMMATE_REVIVE_HEALTH_RATIO := 0.35
const CONTINUE_RESPAWN_DELAY := 9.0
const ATTRACT_DELAY := 10.0
const TEAM_ATTACK_INPUT_WINDOW := 0.24
const TEAM_ATTACK_LINK_DISTANCE := 190.0
const OPTION_KEYS := ["music_volume", "sfx_volume", "touch_scale", "touch_layout", "ui_scale", "screen_shake", "hit_flash", "haptics", "high_contrast_cues", "subtitles", "language", "controls"]
const REBIND_ACTIONS := ["move_left", "move_right", "move_up", "move_down", "attack", "jump", "special", "pause"]

func _ready() -> void:
	local_player_registry.reset_with_keyboard(selected_hero_index)
	active_stage_definition = CAMPAIGN_STAGE_DEFINITIONS[campaign_stage_index]
	encounter_director = EncounterDirectorScript.new()
	add_child(encounter_director)
	encounter_director.configure(self, active_stage_definition)
	encounter_director.encounter_started.connect(_on_encounter_started)
	encounter_director.encounter_cleared.connect(_on_encounter_cleared)
	encounter_director.scene_entered.connect(_on_scene_entered)
	encounter_director.stage_completed.connect(_victory)
	music_director = MusicDirectorScript.new()
	add_child(music_director)
	arcade_profile = ArcadeProfileScript.new("" if DisplayServer.get_name() == "headless" else ArcadeProfileScript.DEFAULT_PATH)
	arcade_profile.load_profile()
	settings = arcade_profile.settings.duplicate(true)
	_capture_original_key_events()
	world_art.configure(active_stage_definition)
	# Headless CI has no audio device; skip players there to keep tests clean.
	if DisplayServer.get_name() != "headless":
		for i in range(8):
			var audio := AudioStreamPlayer.new()
			add_child(audio)
			sfx_players.append(audio)
			sfx_voice_priorities.append(0)
			sfx_voice_serials.append(0)
	_create_player()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_create_stage_objects()
	_create_vehicle_sequence()
	actors.visible = false
	stage_time_remaining = active_stage_definition.time_limit_seconds
	hud.set_stage_time(stage_time_remaining)
	_sync_hud_stage_progress()
	hud.set_hero_roster(HERO_DEFINITIONS, selected_hero_index)
	hud.set_arcade_profile(arcade_profile.high_scores, settings)
	_sync_selection_hud()
	hud.set_mode("title")
	_apply_settings()
	music_director.play_cue(MusicDirectorScript.Cue.TITLE)
	set_process(true)


func localized_content(value: String) -> String:
	return Localization.content(value, String(settings.get("language", "en")))


func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		suspended_by_os = true
		_save_profile()
		handle_application_focus_lost()
		if is_instance_valid(touch_controls):
			touch_controls._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		suspended_by_os = false

func _create_player() -> void:
	var primary_slot = local_player_registry.slot_at(0)
	player = _create_local_player(primary_slot)
	hud.set_player_identity(player.hero_display_name, selected_hero().primary_color)
	hud.set_player_health(player.health, player.max_health)


func _create_local_player(slot) -> Node:
	if slot == null:
		return null
	var fighter := PlayerScript.new()
	actors.add_child(fighter)
	fighter.position = _find_safe_player_spawn(slot.slot_index)
	var source := DeviceInputSourceScript.new()
	source.configure(slot.device_id, slot.device_id == -1 and DisplayServer.is_touchscreen_available())
	var hero: Resource = HERO_DEFINITIONS[posmod(slot.hero_index, HERO_DEFINITIONS.size())]
	fighter.setup(self, hero, slot.slot_index, slot.device_id, source)
	fighter.health_changed.connect(_on_local_player_health.bind(fighter))
	fighter.defeated.connect(_on_local_player_defeated.bind(fighter))
	fighter.set_physics_process(state == "playing")
	players.append(fighter)
	players.sort_custom(func(a, b): return a.local_slot_index < b.local_slot_index)
	_sync_local_player_hud(fighter)
	return fighter

func _process(delta: float) -> void:
	if state == "title":
		_set_local_players_physics(false)
		title_idle_time += delta
		if Input.is_action_just_pressed("start"):
			_open_character_select()
		elif Input.is_action_just_pressed("jump"):
			_open_high_scores()
		elif Input.is_action_just_pressed("special"):
			_open_options("title")
		elif title_idle_time >= ATTRACT_DELAY:
			_open_attract()
		return
	if state == "attract":
		title_idle_time += delta
		if Input.is_action_just_pressed("start") or Input.is_action_just_pressed("attack"):
			_open_character_select()
		elif title_idle_time >= ATTRACT_DELAY:
			_return_to_title()
		return
	if state == "high_scores":
		if Input.is_action_just_pressed("start") or Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("pause"):
			_return_to_title()
		return
	if state == "options":
		if Input.is_action_just_pressed("move_up"):
			_shift_option_selection(-1)
		elif Input.is_action_just_pressed("move_down"):
			_shift_option_selection(1)
		elif Input.is_action_just_pressed("move_left"):
			_adjust_option(-1)
		elif Input.is_action_just_pressed("move_right"):
			_adjust_option(1)
		if Input.is_action_just_pressed("start") or Input.is_action_just_pressed("pause"):
			_close_options()
		return
	if state == "controls":
		if not pending_rebind_action.is_empty():
			return
		if Input.is_action_just_pressed("move_up"):
			_shift_control_selection(-1)
		elif Input.is_action_just_pressed("move_down"):
			_shift_control_selection(1)
		elif Input.is_action_just_pressed("attack"):
			_begin_control_rebind()
		elif Input.is_action_just_pressed("start") or Input.is_action_just_pressed("pause"):
			_return_to_options()
		return
	if state == "select":
		_set_local_players_physics(false)
		if Input.is_action_just_pressed("move_left"):
			shift_hero_selection_for_slot(0, -1)
		elif Input.is_action_just_pressed("move_right"):
			shift_hero_selection_for_slot(0, 1)
		if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("start"):
			confirm_hero_selection_for_slot(0)
		return
	if state == "campaign_map":
		_set_local_players_physics(false)
		if Input.is_action_just_pressed("start") or Input.is_action_just_pressed("attack"):
			_deploy_campaign_stage()
		return
	if state == "victory":
		_tick_victory(delta)
		if victory_phase == &"complete" and Input.is_action_just_pressed("start"):
			if campaign_stage_index + 1 < CAMPAIGN_STAGE_DEFINITIONS.size():
				_open_campaign_map(campaign_stage_index + 1)
			else:
				_complete_first_half_campaign()
		return
	if state == "campaign_complete":
		if Input.is_action_just_pressed("start"):
			get_tree().reload_current_scene()
		return
	if state == "ending":
		if Input.is_action_just_pressed("start"):
			_open_credits()
		return
	if state == "credits":
		if Input.is_action_just_pressed("start"):
			_open_campaign_report()
		return
	if state == "gameover":
		if Input.is_action_just_pressed("start"):
			get_tree().reload_current_scene()
		return
	if state == "playing" and Input.is_action_just_pressed("pause"):
		_open_options("playing")
		return
	if state == "playing" and not continue_respawn_time.is_empty() and (Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("start")):
		_confirm_continue_for_slot(int(continue_respawn_time.keys()[0]))
		return
	_tick_downed_players(delta)
	_tick_team_attack_requests(delta)
	var active_players := get_active_players()
	if active_players.is_empty():
		return
	stage_time_remaining = maxf(0.0, stage_time_remaining - delta)
	hud.set_stage_time(stage_time_remaining)
	if stage_time_remaining <= 0.0:
		_stage_timeout()
		return
	_update_shared_camera(delta)
	if shake_time > 0.0:
		shake_time -= delta
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength * 0.68, shake_strength * 0.68))
	else:
		camera.offset = camera.offset.move_toward(Vector2.ZERO,delta*80.0)
		shake_strength = move_toward(shake_strength, 0.0, delta * 90.0)
	encounter_director.tick(delta, lead_player_x())
	_sync_hud_stage_progress()

func _start_game() -> void:
	actors.visible = true
	for fighter in players:
		if not is_instance_valid(fighter):
			continue
		var slot = local_player_registry.slot_at(fighter.local_slot_index)
		if slot != null:
			fighter.apply_hero_definition(HERO_DEFINITIONS[posmod(slot.hero_index, HERO_DEFINITIONS.size())])
			_sync_local_player_hud(fighter)
	state = "playing"
	_set_local_players_physics(true)
	hud.set_player_identity(player.hero_display_name, selected_hero().primary_color)
	hud.set_player_health(player.health, player.max_health)
	hud.set_mode("playing")
	hud.show_banner(localized_content("STAGE %d READY") % active_stage_definition.stage_number, localized_content(active_stage_definition.display_name), 2.1)
	music_director.play_cue(MusicDirectorScript.Cue.STAGE, campaign_stage_index)
	play_sfx("start")


func _open_campaign_map(target_index: int = 0) -> void:
	campaign_map_target_index = clampi(target_index, 0, CAMPAIGN_STAGE_DEFINITIONS.size() - 1)
	state = "campaign_map"
	actors.visible = false
	_set_local_players_physics(false)
	music_director.play_cue(MusicDirectorScript.Cue.TITLE)
	hud.set_campaign_map(CAMPAIGN_STAGE_DEFINITIONS, campaign_map_target_index, completed_stage_count, score, lives)
	play_sfx(&"ui_confirm")


func _open_attract() -> void:
	state = "attract"
	title_idle_time = 0.0
	hud.set_mode("attract")


func _open_high_scores() -> void:
	state = "high_scores"
	title_idle_time = 0.0
	hud.set_arcade_profile(arcade_profile.high_scores, settings)
	hud.set_mode("high_scores")
	play_sfx(&"ui_confirm")


func _return_to_title() -> void:
	get_tree().paused = false
	state = "title"
	actors.visible = false
	title_idle_time = 0.0
	hud.set_arcade_profile(arcade_profile.high_scores, settings)
	hud.set_mode("title")
	music_director.play_cue(MusicDirectorScript.Cue.TITLE)


func _open_options(return_state: String) -> void:
	if return_state not in ["title", "playing"]:
		return
	options_return_state = return_state
	state = "options"
	_set_local_players_physics(false)
	if return_state == "playing":
		get_tree().paused = true
	hud.set_options(settings, options_selected_index, return_state == "playing")
	play_sfx(&"ui_confirm")


func _close_options() -> void:
	_save_profile()
	get_tree().paused = false
	state = options_return_state
	if state == "playing":
		_set_local_players_physics(true)
		hud.set_mode("playing")
	else:
		_return_to_title()
	play_sfx(&"ui_confirm")


func _shift_option_selection(direction: int) -> void:
	options_selected_index = posmod(options_selected_index + direction, OPTION_KEYS.size())
	hud.set_options(settings, options_selected_index, options_return_state == "playing")
	play_sfx(&"ui_confirm")


func _adjust_option(direction: int) -> void:
	var key: String = OPTION_KEYS[options_selected_index]
	if key == "controls":
		_open_controls()
		return
	if key in ["music_volume", "sfx_volume"]:
		settings[key] = clampf(snappedf(float(settings[key]) + direction * 0.1, 0.1), 0.0, 1.0)
	elif key == "touch_scale":
		settings[key] = clampf(snappedf(float(settings[key]) + direction * 0.1, 0.1), 0.75, 1.35)
	elif key == "touch_layout":
		var layouts := ["classic", "compact", "left_handed"]
		settings[key] = layouts[posmod(layouts.find(String(settings[key])) + direction, layouts.size())]
	elif key == "ui_scale":
		settings[key] = clampf(snappedf(float(settings[key]) + direction * 0.05, 0.05), 0.85, 1.2)
	elif key == "language":
		var languages := ["en", "zh"]
		settings[key] = languages[posmod(languages.find(String(settings[key])) + direction, languages.size())]
	else:
		settings[key] = not bool(settings[key])
	arcade_profile.set_setting(key, settings[key])
	_apply_settings()
	hud.set_options(settings, options_selected_index, options_return_state == "playing")
	play_sfx(&"ui_confirm")


func _apply_settings() -> void:
	if is_instance_valid(music_director):
		music_director.set_master_volume_ratio(float(settings.get("music_volume", 0.8)))
	if not bool(settings.get("screen_shake", true)):
		shake_time = 0.0
		shake_strength = 0.0
		camera.offset = Vector2.ZERO
	if is_instance_valid(hud) and arcade_profile != null:
		hud.set_arcade_profile(arcade_profile.high_scores, settings)
	if is_instance_valid(touch_controls):
		touch_controls.queue_redraw()
	_apply_control_bindings()


func _save_profile() -> void:
	if arcade_profile == null:
		return
	arcade_profile.settings = settings.duplicate(true)
	arcade_profile.save_profile()
	hud.set_arcade_profile(arcade_profile.high_scores, settings)


func hit_flash_enabled() -> bool:
	return bool(settings.get("hit_flash", true))


func high_contrast_cues_enabled() -> bool:
	return bool(settings.get("high_contrast_cues", true))


func handle_application_focus_lost() -> void:
	if state == "playing":
		_open_options("playing")


func _open_controls() -> void:
	state = "controls"
	pending_rebind_action = ""
	hud.set_controls(arcade_profile.bindings, control_selected_index, pending_rebind_action)
	play_sfx(&"ui_confirm")


func _return_to_options() -> void:
	pending_rebind_action = ""
	state = "options"
	hud.set_options(settings, options_selected_index, options_return_state == "playing")
	play_sfx(&"ui_confirm")


func _shift_control_selection(direction: int) -> void:
	control_selected_index = posmod(control_selected_index + direction, REBIND_ACTIONS.size())
	hud.set_controls(arcade_profile.bindings, control_selected_index, pending_rebind_action)


func _begin_control_rebind() -> void:
	pending_rebind_action = REBIND_ACTIONS[control_selected_index]
	hud.set_controls(arcade_profile.bindings, control_selected_index, pending_rebind_action)


func _commit_control_rebind(keycode: int) -> bool:
	if pending_rebind_action.is_empty() or keycode <= 0:
		return false
	var action := pending_rebind_action
	var previous_key := int(arcade_profile.bindings[action])
	for other_action in REBIND_ACTIONS:
		if other_action != action and int(arcade_profile.bindings[other_action]) == keycode:
			arcade_profile.set_binding(other_action, previous_key)
	arcade_profile.set_binding(action, keycode)
	pending_rebind_action = ""
	_apply_control_bindings()
	_save_profile()
	hud.set_controls(arcade_profile.bindings, control_selected_index, pending_rebind_action)
	return true


func _capture_original_key_events() -> void:
	for action in REBIND_ACTIONS:
		original_key_events[action] = []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				original_key_events[action].append(event.duplicate())


func _apply_control_bindings() -> void:
	if arcade_profile == null:
		return
	for action in REBIND_ACTIONS:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		var key_event := InputEventKey.new()
		key_event.physical_keycode = int(arcade_profile.bindings.get(action, ArcadeProfileScript.DEFAULT_BINDINGS[action]))
		InputMap.action_add_event(action, key_event)


func _restore_original_key_events() -> void:
	for action in original_key_events:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		for event in original_key_events[action]:
			InputMap.action_add_event(action, event)


func _deploy_campaign_stage() -> void:
	if state != "campaign_map":
		return
	if campaign_map_target_index > campaign_stage_index:
		_advance_campaign_stage()
	else:
		_start_game()


func selected_hero() -> Resource:
	return HERO_DEFINITIONS[clampi(selected_hero_index, 0, HERO_DEFINITIONS.size() - 1)]


func _open_character_select() -> void:
	state = "select"
	actors.visible = false
	title_idle_time = 0.0
	final_score_recorded = false
	final_score_rank = -1
	hud.set_final_score_rank(-1)
	local_player_registry.reset_ready()
	hud.set_hero_roster(HERO_DEFINITIONS, selected_hero_index)
	_sync_selection_hud()
	hud.set_mode("select")
	play_sfx(&"ui_confirm")


func select_hero(index: int) -> void:
	select_hero_for_slot(0, index)


func shift_hero_selection(direction: int) -> void:
	shift_hero_selection_for_slot(0, direction)


func confirm_hero_selection() -> void:
	confirm_hero_selection_for_slot(0)


func selected_hero_for_slot(slot_index: int) -> Resource:
	var slot = local_player_registry.slot_at(slot_index)
	if slot == null:
		return null
	return HERO_DEFINITIONS[posmod(slot.hero_index, HERO_DEFINITIONS.size())]


func select_hero_for_slot(slot_index: int, hero_index: int) -> bool:
	var slot = local_player_registry.slot_at(slot_index)
	if slot == null:
		return false
	var resolved_index := posmod(hero_index, HERO_DEFINITIONS.size())
	local_player_registry.set_hero(slot_index, resolved_index)
	if slot_index == 0:
		selected_hero_index = resolved_index
		hud.set_hero_roster(HERO_DEFINITIONS, selected_hero_index)
	_sync_selection_hud()
	play_sfx(&"ui_confirm")
	return true


func shift_hero_selection_for_slot(slot_index: int, direction: int) -> bool:
	var slot = local_player_registry.slot_at(slot_index)
	if slot == null or direction == 0:
		return false
	return select_hero_for_slot(slot_index, slot.hero_index + signi(direction))


func confirm_hero_selection_for_slot(slot_index: int) -> bool:
	if state != "select" or not local_player_registry.set_ready(slot_index, true):
		return false
	_sync_selection_hud()
	play_sfx(&"ui_confirm")
	if local_player_registry.all_ready():
		_open_campaign_map(0)
	return true


func cancel_hero_selection_for_slot(slot_index: int) -> bool:
	if state != "select" or not local_player_registry.set_ready(slot_index, false):
		return false
	_sync_selection_hud()
	return true


func _sync_selection_hud() -> void:
	if not is_instance_valid(hud):
		return
	var selections: Array[Dictionary] = []
	for slot in local_player_registry.active_slots():
		var hero: Resource = HERO_DEFINITIONS[posmod(slot.hero_index, HERO_DEFINITIONS.size())]
		selections.append({
			"slot_index": slot.slot_index,
			"hero_index": slot.hero_index,
			"ready": slot.selection_ready,
			"color": hero.primary_color,
		})
	hud.set_local_player_selections(selections)


func _input(event: InputEvent) -> void:
	if state == "controls" and not pending_rebind_action.is_empty() and event is InputEventKey and event.pressed and not event.echo:
		var keycode := int(event.physical_keycode if event.physical_keycode > 0 else event.keycode)
		if keycode == KEY_ESCAPE:
			pending_rebind_action = ""
			hud.set_controls(arcade_profile.bindings, control_selected_index, pending_rebind_action)
		else:
			_commit_control_rebind(keycode)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X:
		var direction := 0
		if event.axis_value <= -0.65:
			direction = -1
		elif event.axis_value >= 0.65:
			direction = 1
		var previous: int = int(joy_selection_axis_latch.get(event.device, 0))
		joy_selection_axis_latch[event.device] = direction
		if state == "select" and direction != 0 and direction != previous:
			var axis_slot = local_player_registry.slot_for_device(event.device)
			if axis_slot != null:
				shift_hero_selection_for_slot(axis_slot.slot_index, direction)
		return
	if not (event is InputEventJoypadButton) or not event.pressed:
		return
	var slot = local_player_registry.slot_for_device(event.device)
	if state == "playing" and slot != null and continue_respawn_time.has(slot.slot_index) and event.button_index in [JOY_BUTTON_START, JOY_BUTTON_A]:
		_confirm_continue_for_slot(slot.slot_index)
		return
	if state == "playing" and slot != null and event.button_index == JOY_BUTTON_START:
		_open_options("playing")
		return
	if event.button_index == JOY_BUTTON_START:
		if slot == null:
			join_local_player(event.device)
		elif state == "select":
			confirm_hero_selection_for_slot(slot.slot_index)
	elif event.button_index == JOY_BUTTON_BACK:
		if state == "select" and slot != null and slot.selection_ready:
			cancel_hero_selection_for_slot(slot.slot_index)
		else:
			leave_local_player(event.device)
	elif state == "select" and slot != null:
		if event.button_index == JOY_BUTTON_DPAD_LEFT:
			shift_hero_selection_for_slot(slot.slot_index, -1)
		elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
			shift_hero_selection_for_slot(slot.slot_index, 1)
		elif event.button_index == JOY_BUTTON_A:
			confirm_hero_selection_for_slot(slot.slot_index)


func join_local_player(device_id: int, hero_index := -1) -> Node:
	if state not in ["title", "select", "playing"]:
		return null
	if device_id < 0 or local_player_registry.slot_for_device(device_id) != null:
		return null
	var resolved_hero_index := hero_index
	if resolved_hero_index < 0:
		resolved_hero_index = local_player_registry.slots.size() % HERO_DEFINITIONS.size()
	var slot = local_player_registry.join_device(device_id, posmod(resolved_hero_index, HERO_DEFINITIONS.size()))
	if slot == null:
		return null
	var fighter := _create_local_player(slot)
	if fighter == null:
		local_player_registry.leave_device(device_id)
		return null
	if state == "playing":
		fighter.invulnerable = 2.2
		if is_instance_valid(highway_vehicle):
			fighter.set_physics_process(false)
			highway_vehicle._mount_players()
		hud.show_banner(localized_content("PLAYER %d JOINED") % (slot.slot_index + 1), localized_content(fighter.hero_display_name), 1.2)
		play_sfx(&"ui_confirm")
	else:
		_sync_selection_hud()
	return fighter


func _disconnect_local_player(device_id: int) -> bool:
	var slot = local_player_registry.slot_for_device(device_id)
	if slot == null or slot.slot_index == 0:
		return false
	var fighter := player_for_slot(slot.slot_index)
	var snapshot := {
		"slot_index": slot.slot_index,
		"hero_index": slot.hero_index,
		"selection_ready": slot.selection_ready,
		"remaining_lives": slot.remaining_lives,
		"position": fighter.position if is_instance_valid(fighter) else Vector2.ZERO,
		"health": fighter.health if is_instance_valid(fighter) else 1,
	}
	disconnected_player_snapshots[device_id] = snapshot
	if not leave_local_player(device_id):
		disconnected_player_snapshots.erase(device_id)
		return false
	if is_instance_valid(hud):
		hud.show_banner(localized_content("CONTROLLER DISCONNECTED"), localized_content("PLAYER %d RESERVED") % (int(snapshot.slot_index) + 1), 2.0)
	return true


func _reconnect_local_player(device_id: int) -> Node:
	if not disconnected_player_snapshots.has(device_id):
		return null
	var snapshot: Dictionary = disconnected_player_snapshots[device_id]
	var slot = local_player_registry.join_device_at_slot(device_id, int(snapshot.slot_index), int(snapshot.hero_index))
	if slot == null:
		return null
	slot.selection_ready = bool(snapshot.selection_ready)
	slot.remaining_lives = int(snapshot.remaining_lives)
	var fighter := _create_local_player(slot)
	if fighter == null:
		local_player_registry.leave_device(device_id)
		return null
	fighter.health = clampi(int(snapshot.health), 1, fighter.max_health)
	if state in ["playing", "options"]:
		fighter.position = Vector2(snapshot.position)
		fighter.invulnerable = 2.2
		fighter.set_physics_process(state == "playing" and not get_tree().paused)
		if is_instance_valid(highway_vehicle):
			fighter.set_physics_process(false)
			highway_vehicle._mount_players()
	_sync_local_player_hud(fighter)
	_sync_selection_hud()
	disconnected_player_snapshots.erase(device_id)
	if is_instance_valid(hud):
		hud.show_banner(localized_content("CONTROLLER RECONNECTED"), localized_content("PLAYER %d RESTORED") % (slot.slot_index + 1), 1.5)
	play_sfx(&"ui_confirm")
	return fighter


func leave_local_player(device_id: int) -> bool:
	var slot = local_player_registry.slot_for_device(device_id)
	if slot == null or slot.slot_index == 0:
		return false
	var fighter := player_for_slot(slot.slot_index)
	downed_time_remaining.erase(slot.slot_index)
	continue_respawn_time.erase(slot.slot_index)
	team_attack_requests.erase(slot.slot_index)
	local_player_registry.leave_device(device_id)
	hud.remove_local_player_state(slot.slot_index)
	if is_instance_valid(fighter):
		players.erase(fighter)
		fighter.prepare_local_leave()
		fighter.queue_free()
	_sync_selection_hud()
	return true


func player_for_slot(slot_index: int) -> Node:
	for fighter in players:
		if is_instance_valid(fighter) and fighter.local_slot_index == slot_index:
			return fighter
	return null


func get_local_players() -> Array[Node]:
	var result: Array[Node] = []
	for fighter in players:
		if is_instance_valid(fighter):
			result.append(fighter)
	return result


func get_active_players() -> Array[Node]:
	var result: Array[Node] = []
	for fighter in players:
		if is_instance_valid(fighter) and not fighter.is_defeated:
			result.append(fighter)
	return result


func coop_player_count() -> int:
	return clampi(local_player_registry.slots.size(), 1, LocalPlayerRegistryScript.MAX_PLAYERS)


func coop_enemy_health_scale() -> float:
	var stage_scale: float = active_stage_definition.enemy_health_scale if active_stage_definition != null else 1.0
	return COOP_ENEMY_HEALTH_SCALES[coop_player_count() - 1] * stage_scale


func coop_enemy_damage_scale() -> float:
	var stage_scale: float = active_stage_definition.enemy_damage_scale if active_stage_definition != null else 1.0
	return COOP_ENEMY_DAMAGE_SCALES[coop_player_count() - 1] * stage_scale


func try_team_attack(source: Node) -> bool:
	if get_active_players().size() < 2 or not _team_attack_eligible(source):
		return false
	for slot_index in team_attack_requests.keys().duplicate():
		var partner := player_for_slot(int(slot_index))
		if not _team_attack_eligible(partner):
			team_attack_requests.erase(slot_index)
			if is_instance_valid(partner):
				partner.team_attack_charge_timer = 0.0
			continue
		if partner == source or partner.position.distance_to(source.position) > TEAM_ATTACK_LINK_DISTANCE:
			continue
		team_attack_requests.erase(slot_index)
		partner.team_attack_charge_timer = 0.0
		_execute_team_attack([partner, source])
		return true
	team_attack_requests[source.local_slot_index] = TEAM_ATTACK_INPUT_WINDOW
	source.team_attack_charge_timer = TEAM_ATTACK_INPUT_WINDOW
	return true


func cancel_team_attack_request(source: Node) -> void:
	if not is_instance_valid(source):
		return
	team_attack_requests.erase(source.local_slot_index)
	source.team_attack_charge_timer = 0.0


func _team_attack_eligible(fighter: Node) -> bool:
	return (
		is_instance_valid(fighter)
		and not fighter.is_defeated
		and fighter.hurt_timer <= 0.0
		and fighter.special_timer <= 0.0
		and fighter.z_height <= 5.0
		and fighter.health > TEAM_ATTACK.self_damage
	)


func _tick_team_attack_requests(delta: float) -> void:
	for slot_index in team_attack_requests.keys().duplicate():
		var fighter := player_for_slot(int(slot_index))
		if not _team_attack_eligible(fighter):
			team_attack_requests.erase(slot_index)
			if is_instance_valid(fighter):
				fighter.team_attack_charge_timer = 0.0
			continue
		var remaining := maxf(0.0, float(team_attack_requests[slot_index]) - delta)
		team_attack_requests[slot_index] = remaining
		fighter.team_attack_charge_timer = remaining
		if remaining <= 0.0:
			team_attack_requests.erase(slot_index)
			fighter.start_queued_special()


func _execute_team_attack(participants: Array) -> void:
	if participants.size() < 2:
		return
	var center := Vector2.ZERO
	var damage_scale_total := 0.0
	last_team_attack_participants.clear()
	for fighter in participants:
		center += fighter.position
		damage_scale_total += fighter.damage_scale
		last_team_attack_participants.append(fighter.local_slot_index)
		fighter.begin_team_attack(TEAM_ATTACK)
	center /= participants.size()
	var resolved_damage := maxi(1, roundi(TEAM_ATTACK.damage * damage_scale_total / participants.size()))
	last_team_attack_hits = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_defeated:
			continue
		var in_range := false
		for fighter in participants:
			if fighter.position.distance_to(enemy.position) <= TEAM_ATTACK.effect_radius:
				in_range = true
				break
		if not in_range:
			continue
		var enemy_health_before: int = enemy.health
		var direction := 1 if enemy.position.x >= center.x else -1
		enemy.take_hit(
			resolved_damage,
			Vector2(direction * maxf(absf(enemy.position.x - center.x) * TEAM_ATTACK.radial_horizontal_scale, 260.0), TEAM_ATTACK.knockback.y),
			TEAM_ATTACK.launch,
			false,
			0.0,
			true
		)
		if enemy.health < enemy_health_before:
			last_team_attack_hits += 1
			hit_confirm(enemy.position - Vector2(0.0, 50.0), TEAM_ATTACK.impact_strength, direction, false, TEAM_ATTACK.impact_profile)
	if last_team_attack_hits > 0:
		for fighter in participants:
			fighter.apply_team_attack_cost(TEAM_ATTACK.self_damage)
		hit_confirm(center - Vector2(0.0, 52.0), 3, 1, true, TEAM_ATTACK.impact_profile)
	team_attack_count += 1
	last_team_attack_participants.sort()
	var participant_labels := PackedStringArray()
	for slot_index in last_team_attack_participants:
		participant_labels.append("P%d" % (slot_index + 1))
	hud.show_banner(localized_content("TEAM ATTACK!"), localized_content("%s LINK // %d TARGETS") % [" + ".join(participant_labels), last_team_attack_hits], 1.4)
	play_sfx(TEAM_ATTACK.sound_event)


func _sync_local_player_hud(fighter: Node) -> void:
	if not is_instance_valid(hud) or not is_instance_valid(fighter):
		return
	var weapon_display_name := ""
	if fighter.equipped_weapon != null:
		weapon_display_name = fighter.equipped_weapon.display_name
	var slot = local_player_registry.slot_at(fighter.local_slot_index)
	var remaining_lives: int = slot.remaining_lives if slot != null else lives
	hud.set_local_player_state(
		fighter.local_slot_index,
		fighter.hero_display_name,
		fighter.hero_definition.primary_color,
		fighter.health,
		fighter.max_health,
		remaining_lives,
		weapon_display_name,
		fighter.weapon_ammo,
		fighter.is_defeated
	)
	if downed_time_remaining.has(fighter.local_slot_index):
		hud.set_local_player_down_timer(fighter.local_slot_index, float(downed_time_remaining[fighter.local_slot_index]))


func lead_player_x() -> float:
	if is_instance_valid(highway_vehicle):
		return highway_vehicle.position.x
	var lead_x := 0.0
	for fighter in get_active_players():
		lead_x = maxf(lead_x, fighter.position.x)
	return lead_x


func shared_camera_frame() -> Dictionary:
	var active_players := get_active_players()
	var viewport_width := get_viewport_rect().size.x
	if active_players.is_empty():
		return {"position": camera.position, "zoom": shared_camera_zoom}
	if active_players.size() == 1:
		var half_view_width := viewport_width * 0.5
		return {
			"position": Vector2(clampf(active_players[0].position.x + 280.0, half_view_width, active_stage_definition.end_x() - half_view_width), 360.0),
			"zoom": 1.0,
		}
	var minimum_x: float = active_players[0].position.x
	var maximum_x := minimum_x
	for fighter in active_players:
		minimum_x = minf(minimum_x, fighter.position.x)
		maximum_x = maxf(maximum_x, fighter.position.x)
	var required_width := maximum_x - minimum_x + 520.0
	var target_zoom := clampf(viewport_width / maxf(required_width, viewport_width), MIN_SHARED_CAMERA_ZOOM, 1.0)
	var half_visible_width := viewport_width * 0.5 / target_zoom
	var target_x := (minimum_x + maximum_x) * 0.5 + 180.0
	target_x = clampf(target_x, half_visible_width, active_stage_definition.end_x() - half_visible_width)
	return {"position": Vector2(target_x, 360.0), "zoom": target_zoom}


func _update_shared_camera(delta: float) -> void:
	var frame := shared_camera_frame()
	shared_camera_zoom = lerpf(shared_camera_zoom, float(frame.zoom), minf(delta * 4.5, 1.0))
	camera.position = frame.position
	camera.zoom = Vector2.ONE * shared_camera_zoom


func _find_safe_player_spawn(slot_index: int) -> Vector2:
	var anchor: Vector2 = player.position if is_instance_valid(player) else Vector2(260.0, 570.0)
	var preferred: Vector2 = anchor + PLAYER_SPAWN_OFFSETS[clampi(slot_index, 0, PLAYER_SPAWN_OFFSETS.size() - 1)]
	var candidates := [
		preferred,
		preferred + Vector2(-90.0, 0.0),
		preferred + Vector2(0.0, -68.0),
		preferred + Vector2(0.0, 68.0),
		preferred + Vector2(-90.0, -68.0),
		preferred + Vector2(-90.0, 68.0),
	]
	for candidate: Vector2 in candidates:
		candidate.x = clampf(candidate.x, 100.0, stage_limit - 60.0)
		candidate.y = clampf(candidate.y, 475.0, 645.0)
		var safe := true
		for actor in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(actor) and candidate.distance_to(actor.position) < MIN_SAFE_SPAWN_DISTANCE:
				safe = false
				break
		if safe:
			return candidate
	return Vector2(clampf(preferred.x, 100.0, stage_limit - 60.0), clampf(preferred.y, 475.0, 645.0))


func _set_local_players_physics(enabled: bool) -> void:
	for fighter in players:
		if is_instance_valid(fighter):
			fighter.set_physics_process(enabled and not fighter.is_defeated)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		_reconnect_local_player(device_id)
	else:
		_disconnect_local_player(device_id)

func spawn_enemy(pos: Vector2, type: String) -> void:
	var enemy := EnemyScript.new()
	actors.add_child(enemy)
	enemy.position = pos
	enemy.setup(self, player, type, enemy_spawn_serial)
	enemy_spawn_serial += 1
	_sync_hud_stage_progress()


func spawn_pickup(pos: Vector2, item_id: StringName) -> void:
	var item := PickupScript.new()
	actors.add_child(item)
	item.position = pos
	item.setup(self, String(item_id))


func spawn_weapon_projectile(
	source_actor: Node,
	weapon_definition: Resource,
	team: StringName,
	spawn_position: Vector2,
	direction: int,
	target_actor: Node = null,
	shot_index := 0,
	shot_count := 1
) -> Node:
	var projectile := WeaponProjectileScript.new()
	actors.add_child(projectile)
	projectile.setup(self, source_actor, weapon_definition, team, spawn_position, direction, target_actor, shot_index, shot_count)
	return projectile


func spawn_tidal_wave(source_actor: Node, direction: int, damage: int) -> Node:
	var wave := TidalWaveScript.new()
	actors.add_child(wave)
	wave.setup(self, source_actor, direction, damage)
	return wave


func spawn_road_mine(source_actor: Node, damage: int) -> Node:
	var mine := RoadMineScript.new()
	actors.add_child(mine)
	mine.setup(self, source_actor, source_actor.position + Vector2(-72.0 * source_actor.facing, 0.0), damage)
	return mine


func apply_magnetic_pull(source_actor: Node, damage: int, radius: float) -> int:
	var hit_count := 0
	for fighter in get_active_players():
		if not is_instance_valid(fighter) or fighter.position.distance_to(source_actor.position) > radius:
			continue
		var pull_direction := 1 if source_actor.position.x >= fighter.position.x else -1
		var vertical_pull := clampf((source_actor.position.y - fighter.position.y) * 2.2, -210.0, 210.0)
		var health_before: int = fighter.health
		fighter.take_hit(damage, Vector2(pull_direction * 430.0, vertical_pull), false, 0.1, true)
		if fighter.health < health_before:
			hit_count += 1
	for target in get_tree().get_nodes_in_group("enemies"):
		if (
			target == source_actor
			or not is_instance_valid(target)
			or target.is_defeated
			or target.definition.faction == source_actor.definition.faction
			or target.position.distance_to(source_actor.position) > radius
		):
			continue
		var pull_direction := 1 if source_actor.position.x >= target.position.x else -1
		var health_before: int = target.health
		target.take_hit(damage, Vector2(pull_direction * 430.0, -20.0), false, false, 0.1, true)
		if target.health < health_before:
			hit_count += 1
	play_sfx(&"magnet_pull")
	return hit_count


func spawn_furnace_blast(source_actor: Node, damage: int) -> Array[Node]:
	var waves: Array[Node] = []
	for direction in [-1, 1]:
		var wave := FurnaceWaveScript.new()
		actors.add_child(wave)
		wave.setup(self, source_actor, direction, damage)
		waves.append(wave)
	play_sfx(&"furnace_blast")
	return waves


func spawn_seismic_fractures(source_actor: Node, damage: int, both_directions := false) -> Array[Node]:
	var fractures: Array[Node] = []
	var directions: Array[int] = []
	if both_directions:
		directions.assign([-1, 1])
	else:
		directions.append(source_actor.facing)
	for direction in directions:
		for index in range(3):
			var fracture := SeismicFractureScript.new()
			actors.add_child(fracture)
			var fracture_position: Vector2 = source_actor.position + Vector2(direction * (92.0 + index * 112.0), (index - 1) * 34.0)
			fracture.setup(self, source_actor, fracture_position, damage)
			fractures.append(fracture)
	play_sfx(&"boss_phase")
	return fractures


func spawn_vault_energy_lanes(source_actor: Node, damage: int, crossfire := false) -> Array[Node]:
	var lanes: Array[Node] = []
	var lane_positions: Array[Vector2] = []
	if crossfire:
		var center_x: float = source_actor.position.x
		for candidate in get_tree().get_nodes_in_group("enemies"):
			if candidate != source_actor and is_instance_valid(candidate) and not candidate.is_defeated and String(candidate.definition.enemy_id).begins_with("vault_sentinel"):
				center_x = (center_x + candidate.position.x) * 0.5
				break
		for lane_y in [492.0, 540.0, 588.0, 636.0]:
			lane_positions.append(Vector2(center_x, lane_y))
	else:
		for lane_offset in [-54.0, 0.0, 54.0]:
			lane_positions.append(source_actor.position + Vector2(source_actor.facing * 178.0, lane_offset))
	var color := Color(1.0, 0.58, 0.12, 1.0) if "nyx" in String(source_actor.definition.enemy_id) else Color(0.28, 0.92, 1.0, 1.0)
	for lane_position in lane_positions:
		var lane := VaultEnergyLaneScript.new()
		actors.add_child(lane)
		lane.setup(self, source_actor, lane_position, damage, color)
		lanes.append(lane)
	play_sfx(&"boss_phase")
	return lanes


func spawn_genesis_barrage(source_actor: Node, damage: int) -> Array[Node]:
	var lanes: Array[Node] = []
	var lane_positions := [
		Vector2(source_actor.position.x - 54.0, 492.0),
		Vector2(source_actor.position.x + 54.0, 540.0),
		Vector2(source_actor.position.x - 54.0, 588.0),
		Vector2(source_actor.position.x + 54.0, 636.0),
	]
	for index in range(lane_positions.size()):
		var lane := VaultEnergyLaneScript.new()
		actors.add_child(lane)
		var color := Color(0.28, 1.0, 0.62, 1.0) if index % 2 == 0 else Color(1.0, 0.2, 0.72, 1.0)
		lane.setup(self, source_actor, lane_positions[index], damage, color)
		lanes.append(lane)
	play_sfx(&"boss_phase")
	return lanes


func spawn_genesis_collapse(source_actor: Node, damage: int) -> Array[Node]:
	var zones: Array[Node] = []
	var positions: Array[Vector2] = []
	for fighter in get_active_players():
		positions.append(Vector2(fighter.position.x, clampf(fighter.position.y, 500.0, 630.0)))
	for offset in [-230.0, 230.0]:
		positions.append(Vector2(clampf(source_actor.position.x + offset, 3460.0, 4070.0), 570.0))
	for zone_position in positions:
		var duplicate := false
		for existing in zones:
			if existing.position.distance_to(zone_position) < 92.0:
				duplicate = true
				break
		if duplicate:
			continue
		var zone := GenesisCollapseZoneScript.new()
		actors.add_child(zone)
		zone.setup(self, source_actor, zone_position, damage)
		zones.append(zone)
	play_sfx(&"boss_phase")
	return zones


func _create_stage_objects() -> void:
	for scene in active_stage_definition.scenes:
		for object_definition in scene.environment_objects:
			var stage_object := StageObjectScript.new()
			actors.add_child(stage_object)
			stage_object.setup(self, object_definition)


func _create_vehicle_sequence() -> void:
	if not active_stage_definition.has_method("is_vehicle_stage") or not active_stage_definition.is_vehicle_stage():
		highway_vehicle = null
		return
	highway_vehicle = HighwayVehicleScript.new()
	actors.add_child(highway_vehicle)
	highway_vehicle.setup(self, active_stage_definition.vehicle_sequence)
	_set_local_players_physics(false)

func enemy_removed(enemy: Node) -> void:
	encounter_director.enemy_removed(enemy)


func _on_encounter_started(encounter: Resource, _encounter_index: int) -> void:
	hud.show_banner(encounter.banner_title, encounter.banner_subtitle, 1.45)
	play_sfx("alert")
	_sync_hud_stage_progress()


func _on_encounter_cleared(encounter: Resource, _encounter_index: int) -> void:
	_sync_hud_stage_progress()
	if not encounter.reward_id.is_empty():
		hud.show_banner(localized_content("AREA CLEAR"), localized_content("KEEP MOVING RIGHT  →"), 1.8)
		_spawn_reward(encounter.reward_id)


func _on_scene_entered(scene: Resource, _scene_index: int) -> void:
	hud.show_banner(scene.display_name, scene.transition_subtitle, 1.6)


func _spawn_reward(item_id: StringName) -> void:
	spawn_pickup(player.position + Vector2(105,randf_range(-35,35)), item_id)


func _stage_timeout() -> void:
	if stage_timed_out or state != "playing":
		return
	stage_timed_out = true
	state = "gameover"
	music_director.play_cue(MusicDirectorScript.Cue.SILENT)
	_set_local_players_physics(false)
	hud.set_mode("gameover")

func add_score(amount: int) -> void:
	score += amount
	hud.set_score(score)


func weapon_changed(weapon_definition: Resource, ammo: int, source_player: Node = null) -> void:
	if source_player != null:
		_sync_local_player_hud(source_player)
		if source_player != player:
			return
	if weapon_definition == null:
		hud.set_weapon("", 0)
		return
	hud.set_weapon(weapon_definition.display_name, ammo)

func boss_health_changed(current: int, maximum: int, boss: Node = null) -> void:
	if boss == null:
		hud.set_boss_health(current, maximum)
		return
	var boss_id := boss.get_instance_id()
	boss_health_ledger[boss_id] = {"current": maxi(current, 0), "maximum": maximum}
	boss_node_ledger[boss_id] = boss
	_sync_boss_health()


func boss_spawned(boss: Node, phase: Resource) -> void:
	_prune_boss_ledger()
	if boss_health_ledger.is_empty():
		boss_phase_history = [phase.phase_id]
	else:
		boss_phase_history.append(phase.phase_id)
	var boss_id := boss.get_instance_id()
	boss_health_ledger[boss_id] = {"current": boss.health, "maximum": boss.max_health}
	boss_node_ledger[boss_id] = boss
	_sync_boss_identity(1, phase.dialogue_speaker)
	_sync_boss_health()
	hud.show_dialogue(phase.dialogue_speaker, phase.dialogue_line, 2.8)
	music_director.play_cue(MusicDirectorScript.Cue.BOSS, campaign_stage_index)
	play_sfx("boss_warning")
	play_sfx(&"voice_boss")


func boss_phase_changed(boss: Node, phase: Resource, phase_index: int) -> void:
	boss_phase_history.append(phase.phase_id)
	_sync_boss_identity(phase_index + 1, phase.dialogue_speaker)
	hud.show_dialogue(phase.dialogue_speaker, phase.dialogue_line, 2.8)
	play_sfx("boss_phase")
	play_sfx(&"voice_boss")
	if (
		phase.reinforcement_count <= 0
		or not encounter_director.active
	):
		return
	encounter_director.register_dynamic_enemies(phase.reinforcement_count)
	_sync_hud_stage_progress()
	for index in range(phase.reinforcement_count):
		var side := -1.0 if index % 2 == 0 else 1.0
		var spawn_position: Vector2 = boss.position + Vector2(side * (180.0 + index * 45.0), -55.0 + index * 110.0)
		spawn_enemy(spawn_position, String(phase.reinforcement_enemy_id))


func _prune_boss_ledger() -> void:
	for boss_id in boss_node_ledger.keys().duplicate():
		var boss: Node = boss_node_ledger[boss_id]
		if not is_instance_valid(boss):
			boss_node_ledger.erase(boss_id)
			boss_health_ledger.erase(boss_id)


func _sync_boss_health() -> void:
	var current_total := 0
	var maximum_total := 0
	for entry in boss_health_ledger.values():
		current_total += int(entry.current)
		maximum_total += int(entry.maximum)
	hud.set_boss_health(current_total, maximum_total)


func _sync_boss_identity(phase_number: int, fallback_name: String) -> void:
	var identity := "VAULT SENTINELS" if boss_health_ledger.size() > 1 else fallback_name
	hud.set_boss_identity(identity, phase_number)


func _sync_hud_stage_progress() -> void:
	if not is_instance_valid(hud) or not is_instance_valid(encounter_director):
		return
	var encounter_count: int = encounter_director.get_encounter_count()
	hud.set_stage_progress(
		mini(stage_index + 1, encounter_count),
		encounter_count,
		remaining_enemies,
		wave_active
	)

func _on_player_health(current: int, maximum: int) -> void:
	hud.set_player_health(current,maximum)


func _on_local_player_health(current: int, maximum: int, fighter: Node) -> void:
	_sync_local_player_hud(fighter)
	if fighter == player:
		_on_player_health(current, maximum)


func _on_player_defeated() -> void:
	_begin_player_downed(player)


func _on_local_player_defeated(fighter: Node) -> void:
	_sync_local_player_hud(fighter)
	_begin_player_downed(fighter)


func _begin_player_downed(fighter: Node) -> void:
	if not is_instance_valid(fighter) or state != "playing":
		return
	cancel_team_attack_request(fighter)
	fighter.set_physics_process(false)
	var revive_window := TEAMMATE_REVIVE_WINDOW if coop_player_count() > 1 and not get_active_players().is_empty() else 0.0
	downed_time_remaining[fighter.local_slot_index] = revive_window
	hud.set_local_player_down_timer(fighter.local_slot_index, revive_window)
	if revive_window > 0.0:
		hud.show_banner(localized_content("PLAYER %d DOWN") % (fighter.local_slot_index + 1), localized_content("MOVE CLOSE + ATTACK TO REVIVE"), 1.4)


func try_revive_teammate(rescuer: Node) -> bool:
	if state != "playing" or not is_instance_valid(rescuer) or rescuer.is_defeated:
		return false
	var best_target: Node = null
	var best_distance := TEAMMATE_REVIVE_DISTANCE + 1.0
	for slot_index in downed_time_remaining.keys():
		if float(downed_time_remaining[slot_index]) <= 0.0:
			continue
		var candidate := player_for_slot(int(slot_index))
		if not is_instance_valid(candidate) or not candidate.is_defeated:
			continue
		var distance: float = rescuer.position.distance_to(candidate.position)
		if distance <= TEAMMATE_REVIVE_DISTANCE and distance < best_distance:
			best_target = candidate
			best_distance = distance
	if best_target == null:
		return false
	var slot_index: int = best_target.local_slot_index
	downed_time_remaining.erase(slot_index)
	continue_respawn_time.erase(slot_index)
	best_target.revive(best_target.position, TEAMMATE_REVIVE_HEALTH_RATIO)
	best_target.set_physics_process(true)
	_sync_local_player_hud(best_target)
	hud.set_local_player_down_timer(slot_index, -1.0)
	hud.show_banner(localized_content("PLAYER %d REVIVED") % (slot_index + 1), localized_content("35% HEALTH + TEMPORARY INVINCIBILITY"), 1.3)
	play_sfx(&"revive")
	return true


func _tick_downed_players(delta: float) -> void:
	for slot_index in continue_respawn_time.keys().duplicate():
		continue_respawn_time[slot_index] = maxf(0.0, float(continue_respawn_time[slot_index]) - delta)
		hud.set_continue_offer(int(slot_index), float(continue_respawn_time[slot_index]))
		if float(continue_respawn_time[slot_index]) > 0.0:
			continue
		_decline_continue(int(slot_index))
	for slot_index in downed_time_remaining.keys().duplicate():
		var fighter := player_for_slot(int(slot_index))
		if not is_instance_valid(fighter) or not fighter.is_defeated:
			downed_time_remaining.erase(slot_index)
			continue
		var remaining := maxf(0.0, float(downed_time_remaining[slot_index]) - delta)
		downed_time_remaining[slot_index] = remaining
		hud.set_local_player_down_timer(int(slot_index), remaining)
		if remaining <= 0.0:
			_consume_player_continue(fighter)
	_resolve_team_gameover()


func _consume_player_continue(fighter: Node) -> void:
	var slot = local_player_registry.slot_at(fighter.local_slot_index)
	downed_time_remaining.erase(fighter.local_slot_index)
	if slot == null:
		return
	if fighter == player:
		slot.remaining_lives = lives
	slot.remaining_lives -= 1
	if fighter == player:
		lives = slot.remaining_lives
		hud.set_lives(lives)
	_sync_local_player_hud(fighter)
	if slot.remaining_lives >= 0:
		continue_respawn_time[fighter.local_slot_index] = CONTINUE_RESPAWN_DELAY
		hud.set_continue_offer(fighter.local_slot_index, CONTINUE_RESPAWN_DELAY)
		hud.set_local_player_down_timer(fighter.local_slot_index, CONTINUE_RESPAWN_DELAY)
	else:
		hud.set_local_player_down_timer(fighter.local_slot_index, -2.0)
		hud.show_banner(localized_content("PLAYER %d OUT") % (fighter.local_slot_index + 1), localized_content("NO CONTINUES REMAIN"), 1.2)


func _confirm_continue_for_slot(slot_index: int) -> bool:
	if not continue_respawn_time.has(slot_index):
		return false
	continue_respawn_time.erase(slot_index)
	hud.set_continue_offer(slot_index, -1.0)
	var fighter := player_for_slot(slot_index)
	if not is_instance_valid(fighter):
		return false
	fighter.revive(_find_safe_revive_position(fighter))
	fighter.set_physics_process(not get_tree().paused)
	_sync_local_player_hud(fighter)
	hud.set_local_player_down_timer(slot_index, -1.0)
	hud.show_banner(localized_content("PLAYER %d CONTINUE!") % (slot_index + 1), localized_content("TEMPORARY INVINCIBILITY"), 1.2)
	play_sfx(&"start")
	return true


func _decline_continue(slot_index: int) -> void:
	continue_respawn_time.erase(slot_index)
	hud.set_continue_offer(slot_index, -1.0)
	var slot = local_player_registry.slot_at(slot_index)
	if slot != null:
		slot.remaining_lives = -1
		if slot_index == 0:
			lives = -1
			hud.set_lives(lives)
	var fighter := player_for_slot(slot_index)
	if is_instance_valid(fighter):
		_sync_local_player_hud(fighter)
	hud.set_local_player_down_timer(slot_index, -2.0)
	hud.show_banner(localized_content("PLAYER %d OUT") % (slot_index + 1), localized_content("CONTINUE TIME EXPIRED"), 1.2)
	_resolve_team_gameover()


func _find_safe_revive_position(fighter: Node) -> Vector2:
	var anchor: Vector2 = fighter.position - Vector2(70.0, 0.0)
	var active := get_active_players()
	if not active.is_empty():
		anchor = active[0].position - Vector2(70.0, 0.0)
	var candidates := [anchor, anchor + Vector2(0.0, -68.0), anchor + Vector2(0.0, 68.0), anchor - Vector2(85.0, 0.0)]
	for candidate: Vector2 in candidates:
		candidate.x = clampf(candidate.x, 100.0, stage_limit - 60.0)
		candidate.y = clampf(candidate.y, 475.0, 645.0)
		var safe := true
		for actor in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("enemies"):
			if actor != fighter and is_instance_valid(actor) and candidate.distance_to(actor.position) < MIN_SAFE_SPAWN_DISTANCE:
				safe = false
				break
		if safe:
			return candidate
	return Vector2(clampf(anchor.x, 100.0, stage_limit - 60.0), clampf(anchor.y, 475.0, 645.0))


func _resolve_team_gameover() -> void:
	if state != "playing" or not get_active_players().is_empty() or not continue_respawn_time.is_empty() or not downed_time_remaining.is_empty():
		return
	state = "gameover"
	music_director.play_cue(MusicDirectorScript.Cue.SILENT)
	_set_local_players_physics(false)
	_record_final_score()
	hud.set_mode("gameover")

func _victory() -> void:
	if state != "playing":
		return
	state = "victory"
	victory_phase = &"clear"
	victory_timer = 1.6
	victory_time_bonus = ceili(stage_time_remaining) * active_stage_definition.time_bonus_per_second
	victory_life_bonus = maxi(lives, 0) * active_stage_definition.life_bonus_per_continue
	victory_clear_bonus = active_stage_definition.clear_bonus
	victory_bonus_applied = false
	completed_stage_count = maxi(completed_stage_count, campaign_stage_index + 1)
	_set_local_players_physics(false)
	for fighter in get_local_players():
		fighter.set_victory_pose(1)
	hud.set_victory_summary(victory_time_bonus, victory_life_bonus, victory_clear_bonus, score)
	hud.set_victory_context(active_stage_definition.stage_number, active_stage_definition.display_name, active_stage_definition.clear_message, campaign_stage_index + 1 < CAMPAIGN_STAGE_DEFINITIONS.size())
	hud.set_victory_phase(victory_phase)
	music_director.play_cue(MusicDirectorScript.Cue.VICTORY)
	play_sfx("victory")


func _advance_campaign_stage() -> void:
	if campaign_stage_index + 1 >= CAMPAIGN_STAGE_DEFINITIONS.size():
		return
	campaign_stage_index += 1
	active_stage_definition = CAMPAIGN_STAGE_DEFINITIONS[campaign_stage_index]
	boss_health_ledger.clear()
	boss_node_ledger.clear()
	if is_instance_valid(highway_vehicle):
		highway_vehicle.release_players()
	highway_vehicle = null
	for child in actors.get_children():
		if not players.has(child):
			child.queue_free()
	downed_time_remaining.clear()
	continue_respawn_time.clear()
	team_attack_requests.clear()
	stage_timed_out = false
	victory_phase = &"none"
	victory_bonus_applied = false
	stage_limit = 1080.0
	encounter_director.configure(self, active_stage_definition)
	world_art.configure(active_stage_definition)
	actors.visible = true
	for index in range(players.size()):
		var fighter := players[index]
		if not is_instance_valid(fighter):
			continue
		fighter.set_victory_pose(0)
		fighter.position = Vector2(260.0, 570.0) + PLAYER_SPAWN_OFFSETS[clampi(index, 0, PLAYER_SPAWN_OFFSETS.size() - 1)]
		fighter.invulnerable = 1.8
		fighter.set_physics_process(true)
		_sync_local_player_hud(fighter)
	_create_stage_objects()
	_create_vehicle_sequence()
	stage_time_remaining = active_stage_definition.time_limit_seconds
	hud.set_stage_time(stage_time_remaining)
	hud.set_boss_health(0, 0)
	hud.set_mode("playing")
	hud.show_banner(localized_content("STAGE %d") % active_stage_definition.stage_number, localized_content(active_stage_definition.display_name), 2.4)
	state = "playing"
	music_director.play_cue(MusicDirectorScript.Cue.STAGE, campaign_stage_index)
	play_sfx(&"start")
	_sync_hud_stage_progress()


func _complete_first_half_campaign() -> void:
	if campaign_stage_index + 1 < CAMPAIGN_STAGE_DEFINITIONS.size() or completed_stage_count < CAMPAIGN_STAGE_DEFINITIONS.size():
		return
	if not campaign_completion_bonus_applied:
		campaign_completion_bonus_applied = true
		add_score(campaign_completion_bonus)
	state = "ending"
	_set_local_players_physics(false)
	music_director.play_cue(MusicDirectorScript.Cue.ENDING)
	hud.set_ending(score, lives)
	play_sfx(&"victory")


func _open_credits() -> void:
	if state != "ending":
		return
	state = "credits"
	hud.set_credits(score)
	music_director.play_cue(MusicDirectorScript.Cue.CREDITS)
	play_sfx(&"ui_confirm")


func _open_campaign_report() -> void:
	if state != "credits":
		return
	state = "campaign_complete"
	_record_final_score()
	hud.set_campaign_complete(score, campaign_completion_bonus, lives)
	hud.set_final_score_rank(final_score_rank)
	play_sfx(&"ui_confirm")


func _tick_victory(delta: float) -> void:
	victory_timer = maxf(0.0, victory_timer - delta)
	if victory_timer > 0.0:
		return
	if victory_phase == &"clear":
		victory_phase = &"bonus"
		victory_timer = 2.4
		if not victory_bonus_applied:
			victory_bonus_applied = true
			add_score(victory_time_bonus + victory_life_bonus + victory_clear_bonus)
			hud.set_victory_summary(victory_time_bonus, victory_life_bonus, victory_clear_bonus, score)
		hud.set_victory_phase(victory_phase)
		play_sfx("bonus_tally")
	elif victory_phase == &"bonus":
		victory_phase = &"complete"
		for fighter in get_local_players():
			fighter.set_victory_pose(2)
		hud.set_victory_phase(victory_phase)

func hit_confirm(
	pos: Vector2,
	strength: int = 1,
	direction: int = 1,
	freeze: bool = true,
	impact_profile: Resource = null
) -> void:
	strength = clampi(strength, 1, 3)
	var fx := ImpactScript.new()
	actors.add_child(fx)
	fx.position = pos
	fx.setup(strength, direction)
	var shake_duration: float = [0.055, 0.095, 0.15][strength - 1]
	var resolved_shake_strength: float = [4.5, 8.0, 13.0][strength - 1]
	var hit_stop_duration: float = [0.035, 0.055, 0.085][strength - 1]
	var primary_sfx: StringName = &"heavy" if strength >= 2 else &"hit"
	var layer_sfx: StringName = &"impact_crack" if strength >= 3 else &""
	var haptic_duration_ms: int = [18, 32, 52][strength - 1]
	var haptic_strength: float = [0.35, 0.62, 0.9][strength - 1]
	last_impact_profile_id = &"fallback"
	if impact_profile != null:
		shake_duration = impact_profile.camera_shake_duration
		resolved_shake_strength = impact_profile.camera_shake_strength
		hit_stop_duration = impact_profile.hit_stop_duration
		primary_sfx = impact_profile.primary_sfx
		layer_sfx = impact_profile.layer_sfx
		haptic_duration_ms = impact_profile.haptic_duration_ms
		haptic_strength = impact_profile.haptic_strength
		last_impact_profile_id = impact_profile.profile_id
	if bool(settings.get("screen_shake", true)):
		shake_time = maxf(shake_time, shake_duration)
		shake_strength = maxf(shake_strength, resolved_shake_strength)
	play_sfx(primary_sfx)
	if not layer_sfx.is_empty():
		play_sfx(layer_sfx)
	last_haptic_duration_ms = haptic_duration_ms
	last_haptic_strength = haptic_strength
	if bool(settings.get("haptics", true)) and DisplayServer.is_touchscreen_available():
		Input.vibrate_handheld(haptic_duration_ms, haptic_strength)
	if freeze:
		_hit_stop(hit_stop_duration)

func _hit_stop(duration: float) -> void:
	last_hit_stop_duration = duration
	if duration <= 0.0 or DisplayServer.get_name() == "headless":
		return
	hit_stop_serial += 1
	var serial := hit_stop_serial
	Engine.time_scale = 0.06
	await get_tree().create_timer(duration, true, false, true).timeout
	if serial == hit_stop_serial:
		Engine.time_scale = 1.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	_restore_original_key_events()

func play_sfx(kind: StringName) -> void:
	sfx_event_history.append(kind)
	if sfx_event_history.size() > 32:
		sfx_event_history.pop_front()
	var cfg := SfxLibraryScript.profile(kind)
	if is_instance_valid(music_director) and cfg.duck_db < 0.0:
		music_director.duck(cfg.duck_db, cfg.duck_duration)
	if sfx_players.is_empty():
		return
	if not sfx_stream_cache.has(cfg.event):
		sfx_stream_cache[cfg.event] = SfxLibraryScript.build_stream(cfg.event)
	var voice_index := _select_sfx_voice(cfg.priority)
	if voice_index < 0:
		return
	var audio := sfx_players[voice_index]
	sfx_index += 1
	sfx_voice_serial += 1
	sfx_voice_priorities[voice_index] = cfg.priority
	sfx_voice_serials[voice_index] = sfx_voice_serial
	audio.stream = sfx_stream_cache[cfg.event]
	var sfx_ratio := clampf(float(settings.get("sfx_volume", 0.9)), 0.0, 1.0)
	audio.volume_db = -80.0 if sfx_ratio <= 0.0 else cfg.volume_db + linear_to_db(sfx_ratio)
	audio.play()


func _record_final_score() -> void:
	if final_score_recorded or arcade_profile == null:
		return
	final_score_recorded = true
	var operative_name: String = player.hero_display_name if is_instance_valid(player) else "RANGER"
	final_score_rank = arcade_profile.record_score(score, maxi(completed_stage_count, campaign_stage_index + 1), coop_player_count(), operative_name)
	_save_profile()
	hud.set_final_score_rank(final_score_rank)


func _select_sfx_voice(priority: int) -> int:
	for index in range(sfx_players.size()):
		if not sfx_players[index].playing:
			return index
	var candidate := -1
	for index in range(sfx_players.size()):
		if sfx_voice_priorities[index] > priority:
			continue
		if (
			candidate < 0
			or sfx_voice_priorities[index] < sfx_voice_priorities[candidate]
			or (
				sfx_voice_priorities[index] == sfx_voice_priorities[candidate]
				and sfx_voice_serials[index] < sfx_voice_serials[candidate]
			)
		):
			candidate = index
	return candidate
