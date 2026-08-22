class_name RuntimePerformanceProbe
extends Node

const WARMUP_FRAMES := 60
const SAMPLE_FRAMES := 300
const LOG_PREFIX := "WEB_PERFORMANCE_BASELINE "
const ACCEPTANCE_LOG_PREFIX := "WEB_STAGE_ACCEPTANCE "
const FORMATION_LOG_PREFIX := "WEB_FORMATION_ACCEPTANCE "

var warmup_frames := 0
var frame_times_ms := PackedFloat64Array()
var scenario := "title"


func _ready() -> void:
	var is_web := OS.has_feature("web")
	set_process(is_web)
	if is_web:
		var query_string := String(JavaScriptBridge.eval("window.location.search"))
		if "local_coop_preview=3" in query_string:
			scenario = "local_coop_preview"
			call_deferred("_start_local_coop_preview")
		elif "local_coop_select=3" in query_string:
			scenario = "local_coop_select"
			call_deferred("_start_local_coop_select_preview")
		elif "coop_revive_preview=1" in query_string:
			scenario = "coop_revive_preview"
			call_deferred("_start_coop_revive_preview")
		elif "hero_animation_preview=" in query_string:
			scenario = "hero_animation_preview"
			var hero_index := 1
			if "hero_animation_preview=kestrel" in query_string:
				hero_index = 2
			elif "hero_animation_preview=atlas" in query_string:
				hero_index = 3
			call_deferred("_start_hero_animation_preview", hero_index)
		elif "hero_select_preview=1" in query_string:
			scenario = "hero_select_preview"
			call_deferred("_start_hero_select_preview")
		elif "formation_acceptance=1" in query_string:
			scenario = "enemy_formation_acceptance"
			set_process(false)
			call_deferred("_start_formation_acceptance")
		elif "stage_acceptance=1" in query_string:
			scenario = "stage_1_acceptance"
			set_process(false)
			call_deferred("_start_stage_acceptance")
		elif "hud_preview=2" in query_string:
			scenario = "touch_hud_preview"
			call_deferred("_start_hud_preview", true)
		elif "hud_preview=1" in query_string:
			scenario = "desktop_hud_preview"
			call_deferred("_start_hud_preview", false)
		elif "roster_preview=1" in query_string:
			scenario = "enemy_roster_preview"
			call_deferred("_start_roster_preview")
		elif "baseline_benchmark=1" in query_string:
			scenario = "four_enemy_wave"
			call_deferred("_start_combat_benchmark")
		elif "victory_preview=1" in query_string:
			scenario = "victory_preview"
			call_deferred("_start_victory_preview")
		elif "boss_preview=2" in query_string:
			scenario = "boss_overdrive_preview"
			call_deferred("_start_boss_preview", true)
		elif "boss_preview=1" in query_string:
			scenario = "boss_command_preview"
			call_deferred("_start_boss_preview", false)
		elif "scene_preview=3" in query_string:
			scenario = "processing_plant_preview"
			call_deferred("_start_scene_preview", 2)
		elif "scene_preview=2" in query_string:
			scenario = "flooded_courtyard_preview"
			call_deferred("_start_scene_preview", 1)


func _process(delta: float) -> void:
	if warmup_frames < WARMUP_FRAMES:
		warmup_frames += 1
		return
	frame_times_ms.append(delta * 1000.0)
	if frame_times_ms.size() < SAMPLE_FRAMES:
		return
	var result := summarize(frame_times_ms)
	result["scenario"] = scenario
	var result_json := JSON.stringify(result)
	print(LOG_PREFIX + result_json)
	if OS.has_feature("web"):
		var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
		browser_window.__wildlandPerformanceJson = result_json
		var browser_document: JavaScriptObject = JavaScriptBridge.get_interface("document")
		browser_document.body.setAttribute("data-wildland-performance", result_json)
	set_process(false)


func _start_combat_benchmark() -> void:
	var game := get_parent()
	if not game.has_method("_start_game") or game.encounter_director.get_encounter_count() < 3:
		scenario = "benchmark_setup_failed"
		return
	game._start_game()
	var encounter: Resource = game.encounter_director.get_encounter(2)
	game.player.position = Vector2(encounter.origin_x, 560.0)
	game.encounter_director.force_start_encounter(2)


func _start_hero_select_preview() -> void:
	var game := get_parent()
	if not game.has_method("_open_character_select") or game.HERO_DEFINITIONS.size() != 4:
		scenario = "hero_select_setup_failed"
		return
	game._open_character_select()
	game.select_hero(2)
	game.set_process(false)


func _start_hero_animation_preview(hero_index: int) -> void:
	var game := get_parent()
	if not game.has_method("select_hero") or game.HERO_DEFINITIONS.size() != 4:
		scenario = "hero_animation_setup_failed"
		return
	game.select_hero(hero_index)
	game.hud.set_hero_animation_preview(game.selected_hero())
	game.hud.set_mode("hero_animation")
	game.set_process(false)


func _start_local_coop_preview() -> void:
	var game := get_parent()
	var second: Node = game.join_local_player(0, 1)
	var third: Node = game.join_local_player(1, 2)
	if second == null or third == null:
		scenario = "local_coop_setup_failed"
		return
	game._start_game()
	var preview_players: Array[Node] = game.get_local_players()
	for index in range(preview_players.size()):
		preview_players[index].position = Vector2(460.0 + index * 230.0, 500.0 + index * 65.0)
		preview_players[index].set_physics_process(false)
	game._update_shared_camera(1.0)
	game.hud.show_banner("3 PLAYER LOCAL CO-OP", "KEYBOARD + TWO GAMEPADS", 999.0)
	game.set_process(false)


func _start_local_coop_select_preview() -> void:
	var game := get_parent()
	var second: Node = game.join_local_player(0, 1)
	var third: Node = game.join_local_player(1, 2)
	if second == null or third == null:
		scenario = "local_coop_select_setup_failed"
		return
	game._open_character_select()
	game.select_hero_for_slot(0, 0)
	game.select_hero_for_slot(1, 1)
	game.select_hero_for_slot(2, 2)
	game.local_player_registry.set_ready(0, true)
	game.local_player_registry.set_ready(1, true)
	game._sync_selection_hud()
	game.set_process(false)


func _start_coop_revive_preview() -> void:
	var game := get_parent()
	var second: Node = game.join_local_player(0, 1)
	if second == null:
		scenario = "coop_revive_setup_failed"
		return
	game._start_game()
	game.encounter_director.completed = true
	game.player.position = Vector2(720.0, 555.0)
	second.position = Vector2(800.0, 555.0)
	game.player.set_physics_process(false)
	second.set_physics_process(false)
	second.invulnerable = 0.0
	second.take_hit(second.max_health, Vector2.ZERO)
	game.downed_time_remaining[1] = 5.6
	game.hud.set_local_player_down_timer(1, 5.6)
	game.hud.show_banner("PLAYER 2 DOWN", "MOVE CLOSE + ATTACK TO REVIVE", 999.0)
	game.set_process(false)


func _start_stage_acceptance() -> void:
	var game := get_parent()
	if not game.has_method("_start_game") or game.encounter_director.get_encounter_count() != 4:
		_publish_stage_acceptance({"passed": false, "reason": "setup_failed"})
		return
	game._start_game()
	game.set_process(false)
	game.player.invulnerable = 999.0
	game.player.set_physics_process(false)
	var started_ids: Array[String] = []
	var cleared_ids: Array[String] = []
	game.encounter_director.encounter_started.connect(
		func(encounter: Resource, _index: int) -> void: started_ids.append(String(encounter.encounter_id))
	)
	game.encounter_director.encounter_cleared.connect(
		func(encounter: Resource, _index: int) -> void: cleared_ids.append(String(encounter.encounter_id))
	)
	for encounter_index in range(game.encounter_director.get_encounter_count()):
		var encounter: Resource = game.encounter_director.get_encounter(encounter_index)
		game.player.position.x = encounter.trigger_x
		game.encounter_director.tick(1.0 / 60.0, game.player.position.x)
		for wave_index in range(encounter.waves.size()):
			if wave_index > 0:
				game.encounter_director.tick(1.0, game.player.position.x)
			await _defeat_acceptance_group(game)
		if encounter_index == game.encounter_director.get_encounter_count() - 1:
			await _defeat_acceptance_group(game)
	game.encounter_director.tick(1.0 / 60.0, game.encounter_director.stage_definition.end_x())
	game._tick_victory(1.6)
	game._tick_victory(2.4)
	var expected_ids := ["ruins_intro", "courtyard_reinforcement", "factory_pressure", "plant_boss"]
	var passed: bool = (
		game.encounter_director.completed
		and game.state == "victory"
		and game.victory_phase == &"complete"
		and game.remaining_enemies == 0
		and game.boss_phase_history == [&"command", &"overdrive"]
		and started_ids == expected_ids
		and cleared_ids == expected_ids
		and game.score == 16900
	)
	_publish_stage_acceptance({
		"passed": passed,
		"encounters_started": started_ids,
		"encounters_cleared": cleared_ids,
		"boss_phases": Array(game.boss_phase_history).map(func(value): return String(value)),
		"combat_score": 7500,
		"final_score": game.score,
		"remaining_enemies": game.remaining_enemies,
		"player_health": game.player.health,
		"victory_phase": String(game.victory_phase),
	})


func _start_formation_acceptance() -> void:
	var game := get_parent()
	if not game.has_method("_start_game") or not game.has_method("spawn_enemy"):
		_publish_formation_acceptance({"passed": false, "reason": "setup_failed"})
		return
	game._start_game()
	game.set_process(false)
	game.encounter_director.completed = true
	game.player.position = Vector2(500.0, 560.0)
	game.player.invulnerable = 999.0
	game.player.set_physics_process(false)
	for _index in range(4):
		game.spawn_enemy(Vector2(1180.0, 560.0), "grunt")
	for _frame in range(90):
		await get_tree().physics_frame
	var formation: Array[Node] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_defeated:
			formation.append(enemy)
	var minimum_distance := INF
	var lane_offsets := {}
	for first_index in range(formation.size()):
		lane_offsets[formation[first_index].approach_lane_offset] = true
		for second_index in range(first_index + 1, formation.size()):
			minimum_distance = minf(
				minimum_distance,
				formation[first_index].position.distance_to(formation[second_index].position)
			)
	_publish_formation_acceptance({
		"passed": formation.size() == 4 and lane_offsets.size() == 4 and minimum_distance >= 45.0,
		"enemy_count": formation.size(),
		"unique_lanes": lane_offsets.size(),
		"minimum_distance": snappedf(minimum_distance, 0.01),
	})


func _defeat_acceptance_group(game: Node) -> void:
	var targets: Array[Node] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.is_defeated:
			targets.append(enemy)
	for enemy in targets:
		enemy.set_physics_process(true)
		enemy.invulnerable = 0.0
		enemy.take_hit(9999, Vector2(300.0, -45.0), true)
	for _frame in range(52):
		await get_tree().physics_frame


func _publish_stage_acceptance(result: Dictionary) -> void:
	var result_json := JSON.stringify(result)
	print(ACCEPTANCE_LOG_PREFIX + result_json)
	var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	browser_window.__wildlandStageAcceptanceJson = result_json
	var browser_document: JavaScriptObject = JavaScriptBridge.get_interface("document")
	browser_document.body.setAttribute("data-wildland-stage-acceptance", result_json)


func _publish_formation_acceptance(result: Dictionary) -> void:
	var result_json := JSON.stringify(result)
	print(FORMATION_LOG_PREFIX + result_json)
	var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	browser_window.__wildlandFormationAcceptanceJson = result_json
	var browser_document: JavaScriptObject = JavaScriptBridge.get_interface("document")
	browser_document.body.setAttribute("data-wildland-formation-acceptance", result_json)


func _start_hud_preview(touch_layout: bool) -> void:
	var game := get_parent()
	if not game.has_method("_start_game"):
		scenario = "hud_preview_setup_failed"
		return
	game._start_game()
	game.encounter_director.completed = true
	game.player.position = Vector2(1720.0, 570.0)
	game.player.set_physics_process(false)
	game.camera.position.x = 1950.0
	game.encounter_director._update_scene(1950.0)
	game.player.health = 28
	game.hud.set_player_health(28, game.player.MAX_HEALTH)
	game.score = 12840
	game.hud.set_score(game.score)
	game.stage_time_remaining = 27.4
	game.hud.set_stage_time(game.stage_time_remaining)
	game.hud.set_weapon("PISTOL", 6)
	game.hud.set_stage_progress(2, 4, 3, true)
	game.hud.force_touch_layout = touch_layout
	game.hud.show_dialogue("WARDEN ROURKE", "Seal the courtyard. Do not let the Ranger through.", 99.0)
	game.hud.banner_time = 0.0
	if touch_layout:
		var touch_controls = game.get_node("HUD/TouchControls")
		touch_controls.enabled_for_device = true
		touch_controls.visible = true
		touch_controls.set_process(true)
		touch_controls.queue_redraw()
	game.set_process(false)


func _start_roster_preview() -> void:
	var game := get_parent()
	if not game.has_method("_start_game") or not game.has_method("spawn_enemy"):
		scenario = "roster_preview_setup_failed"
		return
	game._start_game()
	game.encounter_director.completed = true
	game.player.position = Vector2(1325.0, 610.0)
	game.player.facing = 1
	game.player.set_physics_process(false)
	game.camera.position.x = 1950.0
	game.encounter_director._update_scene(1950.0)
	var preview_data := [
		{"type": "grunt", "position": Vector2(1490.0, 535.0), "pose": "idle"},
		{"type": "hunter", "position": Vector2(1705.0, 610.0), "pose": "contact"},
		{"type": "brute", "position": Vector2(1940.0, 535.0), "pose": "idle"},
		{"type": "raptor", "position": Vector2(2175.0, 610.0), "pose": "burst"},
		{"type": "boss", "position": Vector2(2420.0, 535.0), "pose": "idle"},
	]
	var preview_columns := {}
	for preview in preview_data:
		game.spawn_enemy(preview["position"], preview["type"])
		var enemy = game.actors.get_child(game.actors.get_child_count() - 1)
		enemy.set_physics_process(false)
		enemy.facing = -1
		enemy.visual_clock = 0.58
		enemy.invulnerable = 999.0
		enemy.hurtbox.enabled = false
		enemy.attack_hitbox.deactivate()
		enemy.combat_target = game.player
		enemy.is_defeated = false
		enemy.knockdown_state = false
		enemy.hurt_timer = 0.0
		enemy.stun_timer = 0.0
		enemy.boss_transition_timer = 0.0
		match String(preview["pose"]):
			"contact":
				enemy.attack_timer = maxf(0.01, enemy.current_attack.hit_trigger_remaining - 0.01)
			"windup":
				enemy.attack_timer = enemy.current_attack.duration
			"burst":
				enemy.behavior_phase = enemy.BehaviorPhase.BURST
				enemy.behavior_direction = Vector2.LEFT
		enemy.queue_redraw()
		preview_columns[preview["type"]] = enemy._visual_column()
	game.hud.banner_time = 0.0
	game.hud.dialogue_time = 0.0
	var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	browser_window.__wildlandRosterColumns = JSON.stringify(preview_columns)
	print("WEB_ROSTER_PREVIEW " + JSON.stringify(preview_columns))
	game.set_process(false)


func _start_boss_preview(force_overdrive: bool) -> void:
	var game := get_parent()
	if not game.has_method("_start_game") or game.encounter_director.get_encounter_count() < 4:
		scenario = "boss_preview_setup_failed"
		return
	game._start_game()
	var encounter: Resource = game.encounter_director.get_encounter(3)
	game.player.position = Vector2(encounter.origin_x, 560.0)
	game.encounter_director._update_scene(encounter.origin_x)
	game.encounter_director.force_start_encounter(3)
	# The normal campaign enters the plant well before the boss trigger. A
	# direct visual-QA jump suppresses that unrelated scene-entry card.
	game.hud.banner_time = 0.0
	if not force_overdrive:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.definition.is_boss:
			enemy.invulnerable = 0.0
			enemy.take_hit(9999, Vector2(300.0, -60.0), true)
			return


func _start_scene_preview(scene_index: int) -> void:
	var game := get_parent()
	if (
		not game.has_method("_start_game")
		or scene_index < 0
		or scene_index >= game.encounter_director.scenes.size()
	):
		scenario = "scene_preview_setup_failed"
		return
	game._start_game()
	var scene: Resource = game.encounter_director.scenes[scene_index]
	var camera_center_x: float = (scene.start_x + scene.end_x) * 0.5
	game.encounter_director.completed = true
	game.player.position = Vector2(camera_center_x - 280.0, 560.0)
	game.camera.position.x = camera_center_x
	game.encounter_director._update_scene(game.player.position.x)
	game.hud.banner_time = 0.0
	game.player.set_physics_process(false)


func _start_victory_preview() -> void:
	var game := get_parent()
	if not game.has_method("_start_game") or not game.has_method("_victory"):
		scenario = "victory_preview_setup_failed"
		return
	game._start_game()
	game.player.position = Vector2(3500.0, 560.0)
	game.camera.position.x = 3500.0
	game.encounter_director._update_scene(3500.0)
	game.score = 18650
	game.hud.set_score(game.score)
	game.stage_time_remaining = 87.4
	game.lives = 2
	game._victory()
	game._tick_victory(1.6)


static func summarize(samples_ms: PackedFloat64Array) -> Dictionary:
	if samples_ms.is_empty():
		return {}
	var sorted := samples_ms.duplicate()
	sorted.sort()
	var total_ms := 0.0
	var frames_over_20_ms := 0
	var frames_over_33_ms := 0
	for frame_ms in samples_ms:
		total_ms += frame_ms
		if frame_ms > 20.0:
			frames_over_20_ms += 1
		if frame_ms > 33.34:
			frames_over_33_ms += 1
	var average_ms := total_ms / samples_ms.size()
	return {
		"sample_frames": samples_ms.size(),
		"average_ms": average_ms,
		"average_fps": 1000.0 / average_ms,
		"p50_ms": _percentile(sorted, 0.50),
		"p95_ms": _percentile(sorted, 0.95),
		"p99_ms": _percentile(sorted, 0.99),
		"frames_over_20_ms": frames_over_20_ms,
		"frames_over_33_ms": frames_over_33_ms,
	}


static func _percentile(sorted_samples: PackedFloat64Array, fraction: float) -> float:
	var index := clampi(ceili(sorted_samples.size() * fraction) - 1, 0, sorted_samples.size() - 1)
	return sorted_samples[index]
