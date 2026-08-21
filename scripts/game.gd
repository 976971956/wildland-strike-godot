extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const ImpactScript = preload("res://scripts/impact_fx.gd")

@onready var actors: Node2D = $Actors
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD/UI

var player
var stage_limit := 1080.0
var stage_index := 0
var wave_active := false
var remaining_enemies := 0
var score := 0
var lives := 2
var state := "title"
var shake_time := 0.0
var shake_strength := 0.0
var hit_stop_serial := 0
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_index := 0

var waves := [
	{"x":760.0,"enemies":["grunt","raptor","grunt"]},
	{"x":1530.0,"enemies":["grunt","brute","grunt","grunt"]},
	{"x":2350.0,"enemies":["brute","grunt","brute","grunt"]},
	{"x":3180.0,"enemies":["boss","grunt","grunt"]}
]

func _ready() -> void:
	# Headless CI has no audio device; skip players there to keep tests clean.
	if DisplayServer.get_name() != "headless":
		for i in range(4):
			var audio := AudioStreamPlayer.new()
			add_child(audio)
			sfx_players.append(audio)
	_create_player()
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
	var half_view_width := get_viewport_rect().size.x * 0.5
	var target_x: float = clampf(player.position.x + 280.0, half_view_width, 4200.0 - half_view_width)
	camera.position.x = target_x
	if shake_time > 0.0:
		shake_time -= delta
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength * 0.68, shake_strength * 0.68))
	else:
		camera.offset = camera.offset.move_toward(Vector2.ZERO,delta*80.0)
		shake_strength = move_toward(shake_strength, 0.0, delta * 90.0)
	if not wave_active and stage_index < waves.size():
		var wave: Dictionary = waves[stage_index]
		if player.position.x >= float(wave["x"]) - 330.0:
			_start_wave(wave)
	if stage_index >= waves.size() and not wave_active:
		_victory()

func _start_game() -> void:
	state = "playing"
	player.set_physics_process(true)
	hud.set_mode("playing")
	hud.show_banner("READY", "CLEAR EVERY ENEMY IN THE BLOCK", 2.1)
	play_sfx("start")

func _start_wave(wave: Dictionary) -> void:
	wave_active = true
	var wave_x := float(wave["x"])
	stage_limit = wave_x + 430.0
	var enemy_list: Array = wave["enemies"]
	remaining_enemies = enemy_list.size()
	for i in range(enemy_list.size()):
		var side := 1.0 if i % 2 == 0 else -1.0
		var spawn_x := wave_x + 270.0 + (i/2)*90.0 if side > 0 else wave_x - 250.0 - (i/2)*70.0
		spawn_enemy(Vector2(spawn_x,475.0 + (i*61)%175),enemy_list[i])
	hud.show_banner("FIGHT!", "DEFEAT THEM ALL TO ADVANCE", 1.45)
	play_sfx("alert")

func spawn_enemy(pos: Vector2, type: String) -> void:
	var enemy := EnemyScript.new()
	actors.add_child(enemy)
	enemy.position = pos
	enemy.setup(self,player,type)

func enemy_removed(_enemy: Node) -> void:
	remaining_enemies = maxi(remaining_enemies - 1,0)
	if remaining_enemies == 0 and wave_active:
		wave_active = false
		stage_index += 1
		stage_limit = 4200.0 if stage_index >= waves.size() else float(waves[stage_index]["x"]) + 430.0
		if stage_index < waves.size():
			hud.show_banner("STAGE CLEAR", "KEEP MOVING RIGHT  →", 1.8)
			_spawn_reward()

func _spawn_reward() -> void:
	var item := PickupScript.new()
	actors.add_child(item)
	item.position = player.position + Vector2(105,randf_range(-35,35))
	item.setup(self,"weapon" if stage_index % 2 == 0 else "food")

func add_score(amount: int) -> void:
	score += amount
	hud.set_score(score)

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
	state = "victory"
	player.set_physics_process(false)
	hud.set_mode("victory")
	play_sfx("victory")

func hit_confirm(pos: Vector2, strength: int = 1, direction: int = 1, freeze: bool = true) -> void:
	strength = clampi(strength, 1, 3)
	var fx := ImpactScript.new()
	actors.add_child(fx)
	fx.position = pos
	fx.setup(strength, direction)
	shake_time = maxf(shake_time, [0.055, 0.095, 0.15][strength - 1])
	shake_strength = maxf(shake_strength, [4.5, 8.0, 13.0][strength - 1])
	play_sfx("heavy" if strength >= 2 else "hit")
	if strength >= 3:
		play_sfx("impact_crack")
	if DisplayServer.is_touchscreen_available():
		Input.vibrate_handheld([18, 32, 52][strength - 1], [0.35, 0.62, 0.9][strength - 1])
	if freeze and DisplayServer.get_name() != "headless":
		_hit_stop([0.035, 0.055, 0.085][strength - 1])

func _hit_stop(duration: float) -> void:
	hit_stop_serial += 1
	var serial := hit_stop_serial
	Engine.time_scale = 0.06
	await get_tree().create_timer(duration, true, false, true).timeout
	if serial == hit_stop_serial:
		Engine.time_scale = 1.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func play_sfx(kind: String) -> void:
	if sfx_players.is_empty():
		return
	var settings := {
		"start":[520.0,0.22],"alert":[230.0,0.18],"jump":[420.0,0.09],
		"swing":[180.0,0.045],"enemy_swing":[130.0,0.05],"hit":[110.0,0.055],
		"heavy":[72.0,0.10],"hurt":[95.0,0.09],"special":[650.0,0.18],
		"impact_crack":[185.0,0.075],"enemy_down":[62.0,0.16],
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
