extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const ImpactScript = preload("res://scripts/impact_fx.gd")
const StageObjectScript = preload("res://scripts/stage_object.gd")
const WeaponProjectileScript = preload("res://scripts/weapon_projectile.gd")
const EncounterDirectorScript = preload("res://stages/encounter_director.gd")
const STAGE_1_DEFINITION = preload("res://data/stages/stage_1/stage_1.tres")

@onready var actors: Node2D = $Actors
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD/UI
@onready var world_art: Node2D = $WorldArt

var player
var stage_limit := 1080.0
var encounter_director: Node
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
var sfx_event_history: Array[StringName] = []
var last_impact_profile_id: StringName
var last_hit_stop_duration := 0.0
var last_haptic_duration_ms := 0
var last_haptic_strength := 0.0

func _ready() -> void:
	encounter_director = EncounterDirectorScript.new()
	add_child(encounter_director)
	encounter_director.configure(self, STAGE_1_DEFINITION)
	encounter_director.encounter_started.connect(_on_encounter_started)
	encounter_director.encounter_cleared.connect(_on_encounter_cleared)
	encounter_director.scene_entered.connect(_on_scene_entered)
	encounter_director.stage_completed.connect(_victory)
	world_art.configure(STAGE_1_DEFINITION)
	# Headless CI has no audio device; skip players there to keep tests clean.
	if DisplayServer.get_name() != "headless":
		for i in range(4):
			var audio := AudioStreamPlayer.new()
			add_child(audio)
			sfx_players.append(audio)
	_create_player()
	_create_stage_objects()
	stage_time_remaining = STAGE_1_DEFINITION.time_limit_seconds
	hud.set_stage_time(stage_time_remaining)
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
	if state == "gameover" or state == "victory":
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

func _start_game() -> void:
	state = "playing"
	player.set_physics_process(true)
	hud.set_mode("playing")
	hud.show_banner("READY", "CLEAR EVERY ENEMY IN THE BLOCK", 2.1)
	play_sfx("start")

func spawn_enemy(pos: Vector2, type: String) -> void:
	var enemy := EnemyScript.new()
	actors.add_child(enemy)
	enemy.position = pos
	enemy.setup(self,player,type)


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


func _on_encounter_cleared(encounter: Resource, _encounter_index: int) -> void:
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
		player.set_physics_process(false)
		hud.set_mode("gameover")

func _victory() -> void:
	if state != "playing":
		return
	state = "victory"
	player.set_physics_process(false)
	hud.set_mode("victory")
	play_sfx("victory")

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
	if sfx_players.is_empty():
		return
	var settings := {
		"start":[520.0,0.22],"alert":[230.0,0.18],"jump":[420.0,0.09],
		"swing":[180.0,0.045],"enemy_swing":[130.0,0.05],"hit":[110.0,0.055],
		"heavy":[72.0,0.10],"hurt":[95.0,0.09],"special":[650.0,0.18],
		"impact_crack":[185.0,0.075],"impact_snap":[310.0,0.035],
		"impact_clash":[420.0,0.055],"body_slam":[58.0,0.12],
		"special_burst":[760.0,0.12],"enemy_down":[62.0,0.16],
		"gunshot":[920.0,0.065],"throw":[260.0,0.055],"explosion":[54.0,0.16],
		"pickup":[880.0,0.11],"victory":[740.0,0.35]
	}
	var cfg: Array = settings.get(kind,[220.0,0.05])
	var stream := _make_tone(float(cfg[0]),float(cfg[1]),kind in ["hit","heavy","impact_crack","hurt","enemy_down"])
	var audio := sfx_players[sfx_index % sfx_players.size()]
	sfx_index += 1
	audio.stream = stream
	audio.volume_db = -4.5 if kind in ["hit", "heavy", "impact_crack"] else -9.0
	audio.play()

func _make_tone(freq: float, duration: float, noisy: bool) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate*duration)
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	for i in range(count):
		var progress := float(i) / count
		var env := pow(1.0 - progress, 2.15)
		var pitch_drop := 1.0 - progress * 0.48
		var wave := sin(TAU * freq * pitch_drop * i / rate)
		if noisy:
			var transient := maxf(1.0 - progress * 4.8, 0.0)
			wave = wave * 0.62 + sin(TAU * freq * 2.35 * i / rate) * 0.17 + randf_range(-0.72, 0.72) * transient
		var sample := int(clampf(wave*env,-1.0,1.0)*28000.0)
		bytes[i*2] = sample & 0xff
		bytes[i*2+1] = (sample >> 8) & 0xff
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav
