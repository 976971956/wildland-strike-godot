extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const ImpactScript = preload("res://scripts/impact_fx.gd")
const StageObjectScript = preload("res://scripts/stage_object.gd")
const WeaponProjectileScript = preload("res://scripts/weapon_projectile.gd")
const EncounterDirectorScript = preload("res://stages/encounter_director.gd")
const MusicDirectorScript = preload("res://scripts/music_director.gd")
const SfxLibraryScript = preload("res://scripts/sfx_library.gd")
const STAGE_1_DEFINITION = preload("res://data/stages/stage_1/stage_1.tres")

@onready var actors: Node2D = $Actors
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD/UI
@onready var world_art: Node2D = $WorldArt

var player
var stage_limit := 1080.0
var encounter_director: Node
var music_director: Node
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
var sfx_event_history: Array[StringName] = []
var last_impact_profile_id: StringName
var last_hit_stop_duration := 0.0
var last_haptic_duration_ms := 0
var last_haptic_strength := 0.0
var boss_phase_history: Array[StringName] = []
var victory_phase := &"none"
var victory_timer := 0.0
var victory_time_bonus := 0
var victory_life_bonus := 0
var victory_clear_bonus := 0
var victory_bonus_applied := false

func _ready() -> void:
	encounter_director = EncounterDirectorScript.new()
	add_child(encounter_director)
	encounter_director.configure(self, STAGE_1_DEFINITION)
	encounter_director.encounter_started.connect(_on_encounter_started)
	encounter_director.encounter_cleared.connect(_on_encounter_cleared)
	encounter_director.scene_entered.connect(_on_scene_entered)
	encounter_director.stage_completed.connect(_victory)
	music_director = MusicDirectorScript.new()
	add_child(music_director)
	world_art.configure(STAGE_1_DEFINITION)
	# Headless CI has no audio device; skip players there to keep tests clean.
	if DisplayServer.get_name() != "headless":
		for i in range(8):
			var audio := AudioStreamPlayer.new()
			add_child(audio)
			sfx_players.append(audio)
			sfx_voice_priorities.append(0)
			sfx_voice_serials.append(0)
	_create_player()
	_create_stage_objects()
	stage_time_remaining = STAGE_1_DEFINITION.time_limit_seconds
	hud.set_stage_time(stage_time_remaining)
	_sync_hud_stage_progress()
	hud.set_mode("title")
	set_process(true)

func _create_player() -> void:
	player = PlayerScript.new()
	actors.add_child(player)
	player.position = Vector2(260,570)
	player.setup(self)
	player.health_changed.connect(_on_player_health)
	player.defeated.connect(_on_player_defeated)
	hud.set_player_health(player.health, player.MAX_HEALTH)

func _process(delta: float) -> void:
	if state == "title":
		player.set_physics_process(false)
		if Input.is_action_just_pressed("start"):
			_start_game()
		return
	if state == "victory":
		_tick_victory(delta)
		if victory_phase == &"complete" and Input.is_action_just_pressed("start"):
			get_tree().reload_current_scene()
		return
	if state == "gameover":
		if Input.is_action_just_pressed("start"):
			get_tree().reload_current_scene()
		return
	if not is_instance_valid(player):
		return
	stage_time_remaining = maxf(0.0, stage_time_remaining - delta)
	hud.set_stage_time(stage_time_remaining)
	if stage_time_remaining <= 0.0:
		_stage_timeout()
		return
	var half_view_width := get_viewport_rect().size.x * 0.5
	var target_x: float = clampf(player.position.x + 280.0, half_view_width, 4200.0 - half_view_width)
	camera.position.x = target_x
	if shake_time > 0.0:
		shake_time -= delta
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength * 0.68, shake_strength * 0.68))
	else:
		camera.offset = camera.offset.move_toward(Vector2.ZERO,delta*80.0)
		shake_strength = move_toward(shake_strength, 0.0, delta * 90.0)
	encounter_director.tick(delta, player.position.x)
	_sync_hud_stage_progress()

func _start_game() -> void:
	state = "playing"
	player.set_physics_process(true)
	hud.set_mode("playing")
	hud.show_banner("READY", "CLEAR EVERY ENEMY IN THE BLOCK", 2.1)
	music_director.play_cue(MusicDirectorScript.Cue.STAGE)
	play_sfx("start")

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
	target_actor: Node = null
) -> Node:
	var projectile := WeaponProjectileScript.new()
	actors.add_child(projectile)
	projectile.setup(self, source_actor, weapon_definition, team, spawn_position, direction, target_actor)
	return projectile


func _create_stage_objects() -> void:
	for scene in STAGE_1_DEFINITION.scenes:
		for object_definition in scene.environment_objects:
			var stage_object := StageObjectScript.new()
			actors.add_child(stage_object)
			stage_object.setup(self, object_definition)

func enemy_removed(enemy: Node) -> void:
	encounter_director.enemy_removed(enemy)


func _on_encounter_started(encounter: Resource, _encounter_index: int) -> void:
	hud.show_banner(encounter.banner_title, encounter.banner_subtitle, 1.45)
	play_sfx("alert")
	_sync_hud_stage_progress()


func _on_encounter_cleared(encounter: Resource, _encounter_index: int) -> void:
	_sync_hud_stage_progress()
	if not encounter.reward_id.is_empty():
		hud.show_banner("AREA CLEAR", "KEEP MOVING RIGHT  →", 1.8)
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
	player.set_physics_process(false)
	hud.set_mode("gameover")

func add_score(amount: int) -> void:
	score += amount
	hud.set_score(score)


func weapon_changed(weapon_definition: Resource, ammo: int) -> void:
	if weapon_definition == null:
		hud.set_weapon("", 0)
		return
	hud.set_weapon(weapon_definition.display_name, ammo)

func boss_health_changed(current: int, maximum: int) -> void:
	hud.set_boss_health(current,maximum)


func boss_spawned(boss: Node, phase: Resource) -> void:
	boss_phase_history = [phase.phase_id]
	hud.set_boss_identity(phase.dialogue_speaker, 1)
	hud.set_boss_health(boss.health, boss.max_health)
	hud.show_dialogue(phase.dialogue_speaker, phase.dialogue_line, 2.8)
	music_director.play_cue(MusicDirectorScript.Cue.BOSS)
	play_sfx("boss_warning")


func boss_phase_changed(boss: Node, phase: Resource, phase_index: int) -> void:
	boss_phase_history.append(phase.phase_id)
	hud.set_boss_identity(phase.dialogue_speaker, phase_index + 1)
	hud.show_dialogue(phase.dialogue_speaker, phase.dialogue_line, 2.8)
	play_sfx("boss_phase")
	if (
		phase.reinforcement_count <= 0
		or not encounter_director.is_active_encounter(&"plant_boss")
	):
		return
	encounter_director.register_dynamic_enemies(phase.reinforcement_count)
	_sync_hud_stage_progress()
	for index in range(phase.reinforcement_count):
		var side := -1.0 if index % 2 == 0 else 1.0
		var spawn_position: Vector2 = boss.position + Vector2(side * (180.0 + index * 45.0), -55.0 + index * 110.0)
		spawn_enemy(spawn_position, String(phase.reinforcement_enemy_id))


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

func _on_player_defeated() -> void:
	lives -= 1
	hud.set_lives(lives)
	if lives >= 0:
		await get_tree().create_timer(1.1).timeout
		player.revive(player.position - Vector2(70,0))
		hud.show_banner("CONTINUE!", "TEMPORARY INVINCIBILITY", 1.2)
	else:
		state = "gameover"
		music_director.play_cue(MusicDirectorScript.Cue.SILENT)
		player.set_physics_process(false)
		hud.set_mode("gameover")

func _victory() -> void:
	if state != "playing":
		return
	state = "victory"
	victory_phase = &"clear"
	victory_timer = 1.6
	victory_time_bonus = ceili(stage_time_remaining) * 10
	victory_life_bonus = maxi(lives, 0) * 1000
	victory_clear_bonus = 5000
	victory_bonus_applied = false
	player.set_physics_process(false)
	player.set_victory_pose(1)
	hud.set_victory_summary(victory_time_bonus, victory_life_bonus, victory_clear_bonus, score)
	hud.set_victory_phase(victory_phase)
	music_director.play_cue(MusicDirectorScript.Cue.VICTORY)
	play_sfx("victory")


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
		player.set_victory_pose(2)
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
	shake_time = maxf(shake_time, shake_duration)
	shake_strength = maxf(shake_strength, resolved_shake_strength)
	play_sfx(primary_sfx)
	if not layer_sfx.is_empty():
		play_sfx(layer_sfx)
	last_haptic_duration_ms = haptic_duration_ms
	last_haptic_strength = haptic_strength
	if DisplayServer.is_touchscreen_available():
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
	audio.volume_db = cfg.volume_db
	audio.play()


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
