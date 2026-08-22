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
const LocalPlayerRegistryScript = preload("res://core/input/local_player_registry.gd")
const DeviceInputSourceScript = preload("res://core/input/device_input_source.gd")
const STAGE_1_DEFINITION = preload("res://data/stages/stage_1/stage_1.tres")
const HERO_DEFINITIONS := [
	preload("res://data/heroes/ranger.tres"),
	preload("res://data/heroes/mara.tres"),
	preload("res://data/heroes/kestrel.tres"),
	preload("res://data/heroes/atlas.tres"),
]

@onready var actors: Node2D = $Actors
@onready var camera: Camera2D = $Camera2D
@onready var hud: Control = $HUD/UI
@onready var world_art: Node2D = $WorldArt

var player
var players: Array[Node] = []
var local_player_registry = LocalPlayerRegistryScript.new()
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
var selected_hero_index := 0
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
var shared_camera_zoom := 1.0
var joy_selection_axis_latch := {}

const PLAYER_SPAWN_OFFSETS := [
	Vector2(0.0, 0.0),
	Vector2(-72.0, -58.0),
	Vector2(-72.0, 58.0),
]
const MIN_SAFE_SPAWN_DISTANCE := 70.0
const MIN_SHARED_CAMERA_ZOOM := 0.72

func _ready() -> void:
	local_player_registry.reset_with_keyboard(selected_hero_index)
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
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_create_stage_objects()
	stage_time_remaining = STAGE_1_DEFINITION.time_limit_seconds
	hud.set_stage_time(stage_time_remaining)
	_sync_hud_stage_progress()
	hud.set_hero_roster(HERO_DEFINITIONS, selected_hero_index)
	_sync_selection_hud()
	hud.set_mode("title")
	set_process(true)

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
		if Input.is_action_just_pressed("start"):
			_open_character_select()
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
	if state == "victory":
		_tick_victory(delta)
		if victory_phase == &"complete" and Input.is_action_just_pressed("start"):
			get_tree().reload_current_scene()
		return
	if state == "gameover":
		if Input.is_action_just_pressed("start"):
			get_tree().reload_current_scene()
		return
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
	hud.show_banner("READY", "CLEAR EVERY ENEMY IN THE BLOCK", 2.1)
	music_director.play_cue(MusicDirectorScript.Cue.STAGE)
	play_sfx("start")


func selected_hero() -> Resource:
	return HERO_DEFINITIONS[clampi(selected_hero_index, 0, HERO_DEFINITIONS.size() - 1)]


func _open_character_select() -> void:
	state = "select"
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
		_start_game()
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
		hud.show_banner("PLAYER %d JOINED" % (slot.slot_index + 1), fighter.hero_display_name, 1.2)
		play_sfx(&"ui_confirm")
	else:
		_sync_selection_hud()
	return fighter


func leave_local_player(device_id: int) -> bool:
	var slot = local_player_registry.slot_for_device(device_id)
	if slot == null or slot.slot_index == 0:
		return false
	var fighter := player_for_slot(slot.slot_index)
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


func _sync_local_player_hud(fighter: Node) -> void:
	if not is_instance_valid(hud) or not is_instance_valid(fighter):
		return
	var weapon_display_name := ""
	if fighter.equipped_weapon != null:
		weapon_display_name = fighter.equipped_weapon.display_name
	hud.set_local_player_state(
		fighter.local_slot_index,
		fighter.hero_display_name,
		fighter.hero_definition.primary_color,
		fighter.health,
		fighter.max_health,
		lives,
		weapon_display_name,
		fighter.weapon_ammo,
		fighter.is_defeated
	)


func lead_player_x() -> float:
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
			"position": Vector2(clampf(active_players[0].position.x + 280.0, half_view_width, 4200.0 - half_view_width), 360.0),
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
	target_x = clampf(target_x, half_visible_width, 4200.0 - half_visible_width)
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
	if not connected:
		leave_local_player(device_id)

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


func _on_local_player_health(current: int, maximum: int, fighter: Node) -> void:
	_sync_local_player_hud(fighter)
	if fighter == player:
		_on_player_health(current, maximum)


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
		_set_local_players_physics(false)
		hud.set_mode("gameover")


func _on_local_player_defeated(fighter: Node) -> void:
	_sync_local_player_hud(fighter)
	if fighter == player:
		_on_player_defeated()
		return
	fighter.set_physics_process(false)
	if get_active_players().is_empty():
		state = "gameover"
		music_director.play_cue(MusicDirectorScript.Cue.SILENT)
		_set_local_players_physics(false)
		hud.set_mode("gameover")
	else:
		hud.show_banner("PLAYER %d DOWN" % (fighter.local_slot_index + 1), "TEAMMATE REVIVE ARRIVES NEXT", 1.2)

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
	_set_local_players_physics(false)
	for fighter in get_local_players():
		fighter.set_victory_pose(1)
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
