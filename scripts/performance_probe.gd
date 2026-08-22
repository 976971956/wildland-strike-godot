class_name RuntimePerformanceProbe
extends Node

const WeaponCatalogScript = preload("res://core/weapons/weapon_catalog.gd")
const PickupCatalogScript = preload("res://core/items/pickup_catalog.gd")
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
		if "mobile_accessibility_preview=1" in query_string:
			scenario = "mobile_safe_area_preview"
			call_deferred("_start_mobile_accessibility_preview")
		elif "arcade_shell_preview=5" in query_string:
			scenario = "control_remap_preview"
			call_deferred("_start_arcade_shell_preview", 5)
		elif "arcade_shell_preview=4" in query_string:
			scenario = "continue_countdown_preview"
			call_deferred("_start_arcade_shell_preview", 4)
		elif "arcade_shell_preview=3" in query_string:
			scenario = "pause_options_preview"
			call_deferred("_start_arcade_shell_preview", 3)
		elif "arcade_shell_preview=2" in query_string:
			scenario = "local_high_scores_preview"
			call_deferred("_start_arcade_shell_preview", 2)
		elif "arcade_shell_preview=1" in query_string:
			scenario = "attract_screen_preview"
			call_deferred("_start_arcade_shell_preview", 1)
		elif "enemy_roster_preview=2" in query_string:
			scenario = "full_enemy_roster_preview"
			call_deferred("_start_full_enemy_roster_preview")
		elif "stage8_preview=2" in query_string:
			scenario = "stage_8_architect_calder_preview"
			call_deferred("_start_stage_8_preview", true)
		elif "stage8_preview=1" in query_string:
			scenario = "stage_8_genesis_protocol_preview"
			call_deferred("_start_stage_8_preview", false)
		elif "stage7_preview=2" in query_string:
			scenario = "stage_7_vault_sentinels_preview"
			call_deferred("_start_stage_7_preview", true)
		elif "stage7_preview=1" in query_string:
			scenario = "stage_7_underground_vault_preview"
			call_deferred("_start_stage_7_preview", false)
		elif "stage6_preview=2" in query_string:
			scenario = "stage_6_titan_warden_preview"
			call_deferred("_start_stage_6_preview", true)
		elif "stage6_preview=1" in query_string:
			scenario = "stage_6_jungle_mine_preview"
			call_deferred("_start_stage_6_preview", false)
		elif "stage5_preview=2" in query_string:
			scenario = "stage_5_transformation_boss_preview"
			call_deferred("_start_stage_5_preview", true)
		elif "stage5_preview=1" in query_string:
			scenario = "stage_5_burning_settlement_preview"
			call_deferred("_start_stage_5_preview", false)
		elif "stage4_preview=2" in query_string:
			scenario = "stage_4_foundry_boss_preview"
			call_deferred("_start_stage_4_preview", true)
		elif "stage4_preview=1" in query_string:
			scenario = "stage_4_industrial_preview"
			call_deferred("_start_stage_4_preview", false)
		elif "stage3_preview=2" in query_string:
			scenario = "stage_3_vehicle_boss_preview"
			call_deferred("_start_stage_3_preview", true)
		elif "stage3_preview=1" in query_string:
			scenario = "stage_3_highway_preview"
			call_deferred("_start_stage_3_preview", false)
		elif "stage2_preview=2" in query_string:
			scenario = "stage_2_boss_preview"
			call_deferred("_start_stage_2_preview", true)
		elif "stage2_preview=1" in query_string:
			scenario = "stage_2_environment_preview"
			call_deferred("_start_stage_2_preview", false)
		elif "dinosaur_ecosystem_preview=1" in query_string:
			scenario = "dinosaur_ecosystem_preview"
			call_deferred("_start_dinosaur_ecosystem_preview")
		elif "prop_item_preview=1" in query_string:
			scenario = "prop_item_preview"
			call_deferred("_start_prop_item_preview")
		elif "weapon_sandbox_preview=1" in query_string:
			scenario = "weapon_sandbox_preview"
			call_deferred("_start_weapon_sandbox_preview")
		elif "local_coop_preview=3" in query_string:
			scenario = "local_coop_preview"
			call_deferred("_start_local_coop_preview")
		elif "local_coop_select=3" in query_string:
			scenario = "local_coop_select"
			call_deferred("_start_local_coop_select_preview")
		elif "coop_revive_preview=1" in query_string:
			scenario = "coop_revive_preview"
			call_deferred("_start_coop_revive_preview")
		elif "team_attack_preview=1" in query_string:
			scenario = "team_attack_preview"
			call_deferred("_start_team_attack_preview")
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
		elif "campaign_flow_preview=2" in query_string:
			scenario = "campaign_complete_preview"
			call_deferred("_start_campaign_flow_preview", true)
		elif "credits_preview=1" in query_string:
			scenario = "campaign_credits_preview"
			call_deferred("_start_campaign_epilogue_preview", true)
		elif "ending_preview=1" in query_string:
			scenario = "campaign_ending_preview"
			call_deferred("_start_campaign_epilogue_preview", false)
		elif "campaign_flow_preview=1" in query_string:
			scenario = "campaign_map_preview"
			call_deferred("_start_campaign_flow_preview", false)
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


func _start_arcade_shell_preview(preview_kind: int) -> void:
	var game := get_parent()
	var preview_scores: Array[Dictionary] = [
		{"name": "RANGER", "score": 136500, "stage": 8, "players": 1, "date": "2026-08-22"},
		{"name": "KESTREL", "score": 121250, "stage": 8, "players": 3, "date": "2026-08-22"},
		{"name": "ATLAS", "score": 98400, "stage": 7, "players": 2, "date": "2026-08-22"},
	]
	game.arcade_profile.high_scores.assign(preview_scores)
	game.hud.set_arcade_profile(preview_scores, game.settings)
	if preview_kind == 1:
		game._open_attract()
	elif preview_kind == 2:
		game._open_high_scores()
	elif preview_kind == 3:
		game._start_game()
		game._open_options("playing")
	elif preview_kind == 4:
		game._start_game()
		game.player.set_physics_process(false)
		game.hud.set_continue_offer(0, 7.4)
	else:
		game._open_options("title")
		game.options_selected_index = game.OPTION_KEYS.size() - 1
		game._open_controls()
	game.set_process(false)


func _start_mobile_accessibility_preview() -> void:
	var game := get_parent()
	game.settings.touch_scale = 1.2
	game.settings.ui_scale = 1.15
	game.settings.high_contrast_cues = true
	game._apply_settings()
	game._start_game()
	for stage_step in range(3):
		game._advance_campaign_stage()
	game.player.position = Vector2(700.0, 560.0)
	game.player.set_physics_process(false)
	game.hud.force_touch_layout = true
	game.hud.show_dialogue("ACCESSIBILITY", "SAFE-AREA CONTROLS // PATTERNED WARNINGS // LARGE UI", 99.0)
	var controls = game.touch_controls
	controls.size = Vector2(1280.0, 720.0)
	controls.enabled_for_device = true
	controls.visible = true
	controls.safe_area_override = Rect2(70.0, 28.0, 1140.0, 654.0)
	controls.queue_redraw()
	for hazard in game.get_tree().get_nodes_in_group("industrial_hazards"):
		hazard.industrial_warning_active = true
		hazard.set_physics_process(false)
		if String(hazard.definition.object_id) == "press_alpha":
			hazard.position = Vector2(620.0, 610.0)
	game.set_process(false)


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


func _start_team_attack_preview() -> void:
	var game := get_parent()
	var second: Node = game.join_local_player(0, 1)
	if second == null:
		scenario = "team_attack_setup_failed"
		return
	game._start_game()
	game.encounter_director.completed = true
	game.player.position = Vector2(650.0, 555.0)
	second.position = Vector2(760.0, 555.0)
	game.player.set_physics_process(false)
	second.set_physics_process(false)
	for enemy_position in [Vector2(590.0, 515.0), Vector2(710.0, 585.0), Vector2(835.0, 525.0)]:
		game.spawn_enemy(enemy_position, "grunt")
		var enemy: Node = get_tree().get_nodes_in_group("enemies").back()
		enemy.set_physics_process(false)
	game.player._request_special()
	second._request_special()
	game.hud.show_banner("TEAM ATTACK!", "P1 + P2 LINK // 3 TARGETS", 999.0)
	game.set_process(false)


func _start_weapon_sandbox_preview() -> void:
	var game := get_parent()
	game._start_game()
	game.encounter_director.completed = true
	for stage_object in get_tree().get_nodes_in_group("breakables") + get_tree().get_nodes_in_group("stage_hazards"):
		stage_object.visible = false
		stage_object.set_process(false)
		stage_object.set_physics_process(false)
	game.player.position = Vector2(145.0, 555.0)
	game.player.set_physics_process(false)
	var pickup_ids := WeaponCatalogScript.explicit_pickup_ids()
	for index in range(pickup_ids.size()):
		var column := index % 6
		var row := index / 6
		game.spawn_pickup(Vector2(310.0 + column * 170.0, 500.0 + row * 132.0), pickup_ids[index])
		var pickup: Node = get_tree().get_nodes_in_group("pickups").back()
		pickup.set_process(false)
	game.hud.show_banner("12-WEAPON SANDBOX", "MELEE // FIREARMS // EXPLOSIVES", 999.0)
	game.set_process(false)


func _start_prop_item_preview() -> void:
	var game := get_parent()
	game._start_game()
	game.encounter_director.completed = true
	game.player.position = Vector2(155.0, 555.0)
	game.player.set_physics_process(false)
	for stage_object in get_tree().get_nodes_in_group("breakables") + get_tree().get_nodes_in_group("stage_hazards"):
		stage_object.visible = false
		stage_object.set_process(false)
		stage_object.set_physics_process(false)
	var carryables := get_tree().get_nodes_in_group("carryables")
	for index in range(carryables.size()):
		var stage_object: Node = carryables[index]
		stage_object.visible = true
		stage_object.position = Vector2(285.0 if index == 1 else 1160.0, 570.0 + index * 18.0)
	if not carryables.is_empty():
		carryables[0].pick_up_by(game.player)
		game.player.carried_prop = carryables[0]
		carryables[0]._physics_process(0.0)
		carryables[0].set_physics_process(false)
	var item_ids := PickupCatalogScript.explicit_pickup_ids()
	for index in range(item_ids.size()):
		var column := index % 4
		var row := index / 4
		game.spawn_pickup(Vector2(430.0 + column * 190.0, 500.0 + row * 135.0), item_ids[index])
		var pickup: Node = get_tree().get_nodes_in_group("pickups").back()
		pickup.set_process(false)
	game.hud.show_banner("PROPS + PICKUP TIERS", "CARRY // THROW // HEAL // SCORE", 999.0)
	game.set_process(false)


func _start_dinosaur_ecosystem_preview() -> void:
	var game := get_parent()
	game._start_game()
	game.encounter_director.completed = true
	game.player.visible = false
	game.player.set_physics_process(false)
	for existing_enemy in get_tree().get_nodes_in_group("enemies"):
		existing_enemy.remove_from_group("enemies")
		existing_enemy.visible = false
		existing_enemy.set_physics_process(false)
	for stage_object in get_tree().get_nodes_in_group("breakables") + get_tree().get_nodes_in_group("stage_hazards"):
		stage_object.visible = false
		stage_object.set_physics_process(false)
	var preview_data := [
		{"type": "compy", "position": Vector2(250.0, 555.0), "label": "COMPY // NEUTRAL"},
		{"type": "raptor", "position": Vector2(505.0, 585.0), "label": "RAPTOR // HUNTING"},
		{"type": "ankylosaur", "position": Vector2(805.0, 570.0), "label": "ANKYLOSAUR // SLEEPING"},
		{"type": "triceratops", "position": Vector2(1110.0, 585.0), "label": "TRICERATOPS // ENRAGED"},
	]
	for index in range(preview_data.size()):
		var preview: Dictionary = preview_data[index]
		game.spawn_enemy(preview.position, preview.type)
		var dinosaur: Node = get_tree().get_nodes_in_group("enemies").back()
		dinosaur.set_physics_process(false)
		dinosaur.invulnerable = 999.0
		dinosaur.facing = -1
		if preview.type == "triceratops":
			dinosaur._enrage_creature()
		dinosaur.queue_redraw()
		var label := Label.new()
		label.position = Vector2(preview.position.x - 105.0, 640.0)
		label.size = Vector2(210.0, 28.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = preview.label
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color("#fff0bd"))
		game.hud.add_child(label)
	game.hud.show_banner("DINOSAUR ECOSYSTEM", "NEUTRAL // SLEEP // ENRAGE // CROSS-FACTION", 999.0)
	game.set_process(false)


func _start_full_enemy_roster_preview() -> void:
	var game := get_parent()
	game._start_game()
	game.encounter_director.completed = true
	game.player.visible = false
	game.player.set_physics_process(false)
	for existing_enemy in get_tree().get_nodes_in_group("enemies"):
		existing_enemy.remove_from_group("enemies")
		existing_enemy.visible = false
		existing_enemy.set_physics_process(false)
	for stage_object in get_tree().get_nodes_in_group("breakables") + get_tree().get_nodes_in_group("stage_hazards"):
		stage_object.visible = false
		stage_object.set_physics_process(false)
	var preview_data := [
		{"type": "grunt", "label": "GRUNT", "column": 0, "row": 0},
		{"type": "brute", "label": "BRUTE", "column": 1, "row": 0},
		{"type": "hunter", "label": "HUNTER", "column": 2, "row": 0},
		{"type": "knife_raider", "label": "KNIFE", "column": 3, "row": 0},
		{"type": "demolitionist", "label": "DEMOLITION", "column": 4, "row": 0},
		{"type": "shield_guard", "label": "SHIELD", "column": 0, "row": 1},
		{"type": "elite_enforcer", "label": "ELITE ENFORCER", "column": 1, "row": 1},
		{"type": "elite_blade", "label": "ELITE BLADE", "column": 2, "row": 1},
		{"type": "elite_bombardier", "label": "ELITE BOMBER", "column": 3, "row": 1},
		{"type": "elite_bulwark", "label": "ELITE BULWARK", "column": 4, "row": 1},
	]
	for preview: Dictionary in preview_data:
		var actor_position := Vector2(135.0 + preview.column * 252.0, 350.0 + preview.row * 250.0)
		game.spawn_enemy(actor_position, preview.type)
		var enemy: Node = get_tree().get_nodes_in_group("enemies").back()
		enemy.set_physics_process(false)
		enemy.invulnerable = 999.0
		enemy.facing = -1
		enemy.visual_clock = 0.58
		if preview.type in ["knife_raider", "elite_blade"]:
			enemy.behavior_phase = enemy.BehaviorPhase.TELEGRAPH
		if preview.type in ["demolitionist", "elite_bombardier"]:
			enemy.attack_timer = enemy.current_attack.duration
		enemy.queue_redraw()
		var label := Label.new()
		label.position = Vector2(actor_position.x - 118.0, actor_position.y + 8.0)
		label.size = Vector2(236.0, 24.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = preview.label
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override(
			"font_color",
			Color("#ffd052") if preview.row == 1 and preview.column > 0 else Color("#d9f1f2")
		)
		game.hud.add_child(label)
	game.hud.banner_time = 0.0
	game.hud.dialogue_time = 0.0
	var title := Label.new()
	title.position = Vector2(0.0, 106.0)
	title.size = Vector2(1280.0, 42.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "FULL ENEMY ROSTER"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#ffd052"))
	game.hud.add_child(title)
	var subtitle := Label.new()
	subtitle.position = Vector2(0.0, 143.0)
	subtitle.size = Vector2(1280.0, 28.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = "6 STANDARD // 4 ELITE // RECIPE-READY"
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color("#d9f1f2"))
	game.hud.add_child(subtitle)
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


func _start_stage_2_preview(show_boss: bool) -> void:
	var game := get_parent()
	if not game.has_method("_advance_campaign_stage"):
		scenario = "stage_2_preview_setup_failed"
		return
	game._advance_campaign_stage()
	if show_boss:
		var encounter: Resource = game.encounter_director.get_encounter(3)
		game.player.position = Vector2(encounter.origin_x - 280.0, 590.0)
		game.camera.position.x = 3600.0
		game.encounter_director._update_scene(game.player.position.x)
		game.encounter_director.force_start_encounter(3)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
			enemy.facing = -1
			enemy.invulnerable = 999.0
			enemy.behavior_phase = enemy.BehaviorPhase.TELEGRAPH
			enemy.behavior_timer = 999.0
			enemy.queue_redraw()
	else:
		var scene: Resource = game.encounter_director.scenes[0]
		game.player.position = Vector2(620.0, 585.0)
		game.camera.position.x = (scene.start_x + scene.end_x) * 0.5
		game.encounter_director.completed = true
		game.encounter_director._update_scene(game.player.position.x)
	game.player.set_physics_process(false)
	game.hud.banner_time = 0.0
	game.hud.dialogue_time = 0.0
	game.set_process(false)


func _start_stage_3_preview(show_boss: bool) -> void:
	var game := get_parent()
	if not game.has_method("_advance_campaign_stage"):
		scenario = "stage_3_preview_setup_failed"
		return
	game._advance_campaign_stage()
	game._advance_campaign_stage()
	if not is_instance_valid(game.highway_vehicle):
		scenario = "stage_3_preview_setup_failed"
		return
	var vehicle: Node = game.highway_vehicle
	vehicle.set_physics_process(false)
	if show_boss:
		vehicle.position = Vector2(3500.0, 560.0)
		vehicle._mount_players()
		game.camera.position.x = 3600.0
		game.encounter_director._update_scene(vehicle.position.x)
		game.encounter_director.force_start_encounter(4)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
			enemy.facing = -1
			enemy.invulnerable = 999.0
			enemy.behavior_phase = enemy.BehaviorPhase.TELEGRAPH
			enemy.behavior_timer = 999.0
			enemy.queue_redraw()
	else:
		vehicle.position = Vector2(690.0, 560.0)
		vehicle._mount_players()
		game.camera.position.x = 700.0
		game.encounter_director.completed = true
		game.encounter_director._update_scene(vehicle.position.x)
	game.hud.banner_time = 0.0
	game.hud.dialogue_time = 0.0
	game.set_process(false)


func _start_stage_4_preview(show_boss: bool) -> void:
	var game := get_parent()
	if not game.has_method("_advance_campaign_stage"):
		scenario = "stage_4_preview_setup_failed"
		return
	for _stage in range(3):
		game._advance_campaign_stage()
	if game.active_stage_definition.stage_id != &"stage_4":
		scenario = "stage_4_preview_setup_failed"
		return
	if show_boss:
		game.player.position = Vector2(3540.0, 590.0)
		game.camera.position.x = 3600.0
		game.encounter_director._update_scene(game.player.position.x)
		game.encounter_director.force_start_encounter(4)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
			enemy.facing = -1
			enemy.invulnerable = 999.0
			enemy.behavior_phase = enemy.BehaviorPhase.TELEGRAPH
			enemy.behavior_timer = 999.0
			enemy.queue_redraw()
	else:
		game.player.position = Vector2(2360.0, 585.0)
		game.camera.position.x = 2240.0
		game.encounter_director.completed = true
		game.encounter_director._update_scene(game.player.position.x)
	game.player.set_physics_process(false)
	game.hud.banner_time = 0.0
	game.hud.dialogue_time = 0.0
	game.set_process(false)


func _start_stage_5_preview(show_boss: bool) -> void:
	var game := get_parent()
	if not game.has_method("_advance_campaign_stage"):
		scenario = "stage_5_preview_setup_failed"
		return
	for _stage in range(4):
		game._advance_campaign_stage()
	if game.active_stage_definition.stage_id != &"stage_5":
		scenario = "stage_5_preview_setup_failed"
		return
	if show_boss:
		game.player.position = Vector2(3540.0, 590.0)
		game.camera.position.x = 3600.0
		game.encounter_director._update_scene(game.player.position.x)
		game.encounter_director.force_start_encounter(4)
		var preview_boss: Node = null
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.definition.enemy_id == &"cinder_matriarch":
				preview_boss = enemy
		if preview_boss != null:
			preview_boss.set_physics_process(false)
			preview_boss.facing = -1
			preview_boss.invulnerable = 0.0
			preview_boss.take_hit(9999, Vector2(280.0, -30.0), true)
			preview_boss.boss_transition_timer = 0.0
			preview_boss.invulnerable = 999.0
			preview_boss.behavior_phase = preview_boss.BehaviorPhase.TELEGRAPH
			preview_boss.behavior_timer = 999.0
			preview_boss.queue_redraw()
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy != preview_boss:
				enemy.queue_free()
	else:
		game.player.position = Vector2(2180.0, 585.0)
		game.camera.position.x = 2100.0
		game.encounter_director.completed = true
		game.encounter_director._update_scene(game.player.position.x)
	game.player.set_physics_process(false)
	game.hud.banner_time = 0.0
	game.hud.dialogue_time = 0.0
	game.set_process(false)


func _start_stage_6_preview(show_boss: bool) -> void:
	var game := get_parent()
	if not game.has_method("_advance_campaign_stage"):
		scenario = "stage_6_preview_setup_failed"
		return
	for _stage in range(5):
		game._advance_campaign_stage()
	if game.active_stage_definition.stage_id != &"stage_6":
		scenario = "stage_6_preview_setup_failed"
		return
	if show_boss:
		game.player.position = Vector2(3540.0, 590.0)
		game.camera.position.x = 3600.0
		game.encounter_director._update_scene(game.player.position.x)
		game.encounter_director.force_start_encounter(4)
		var preview_boss: Node = null
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.definition.enemy_id == &"titan_warden":
				preview_boss = enemy
		if preview_boss != null:
			preview_boss.set_physics_process(false)
			preview_boss.facing = -1
			preview_boss.invulnerable = 0.0
			preview_boss.take_hit(9999, Vector2(280.0, -30.0), true)
			preview_boss.boss_transition_timer = 0.0
			preview_boss.invulnerable = 999.0
			preview_boss.behavior_phase = preview_boss.BehaviorPhase.TELEGRAPH
			preview_boss.behavior_timer = 999.0
			preview_boss.queue_redraw()
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy != preview_boss:
				enemy.queue_free()
		for hazard in get_tree().get_nodes_in_group("jungle_hazards"):
			hazard.set_physics_process(false)
			hazard.jungle_damage_active = false
			hazard.jungle_warning_active = hazard.definition.hazard_kind == 2
			hazard.queue_redraw()
	else:
		game.player.position = Vector2(2180.0, 585.0)
		game.camera.position.x = 2100.0
		game.encounter_director.completed = true
		game.encounter_director._update_scene(game.player.position.x)
	game.player.set_physics_process(false)
	game.hud.banner_time = 0.0
	game.hud.dialogue_time = 0.0
	game.set_process(false)


func _start_stage_7_preview(show_boss: bool) -> void:
	var game := get_parent()
	if not game.has_method("_advance_campaign_stage"):
		scenario = "stage_7_preview_setup_failed"
		return
	for _stage in range(6):
		game._advance_campaign_stage()
	if game.active_stage_definition.stage_id != &"stage_7":
		scenario = "stage_7_preview_setup_failed"
		return
	if show_boss:
		game.player.position = Vector2(3515.0, 580.0)
		game.camera.position.x = 3600.0
		game.encounter_director._update_scene(game.player.position.x)
		game.encounter_director.force_start_encounter(4)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not String(enemy.definition.enemy_id).begins_with("vault_sentinel"):
				enemy.queue_free()
				continue
			enemy.set_physics_process(false)
			enemy.facing = -1
			enemy.invulnerable = 0.0
			enemy.take_hit(9999, Vector2(280.0, -30.0), true)
			enemy.boss_transition_timer = 0.0
			enemy.hurt_timer = 0.0
			enemy.stun_timer = 0.0
			enemy.knockdown_state = false
			enemy.invulnerable = 999.0
			enemy.behavior_phase = enemy.BehaviorPhase.TELEGRAPH
			enemy.behavior_timer = 999.0
			enemy.queue_redraw()
		for hazard in get_tree().get_nodes_in_group("vault_hazards"):
			hazard.set_physics_process(false)
			hazard.vault_damage_active = false
			hazard.vault_warning_active = true
			hazard.queue_redraw()
	else:
		game.player.position = Vector2(2130.0, 585.0)
		game.camera.position.x = 2100.0
		game.encounter_director.completed = true
		game.encounter_director._update_scene(game.player.position.x)
		for hazard in get_tree().get_nodes_in_group("vault_hazards"):
			hazard.set_physics_process(false)
			hazard.vault_damage_active = false
			hazard.vault_warning_active = true
			hazard.queue_redraw()
	game.player.set_physics_process(false)
	game.hud.banner_time = 0.0
	game.hud.dialogue_time = 0.0
	game.set_process(false)


func _start_stage_8_preview(show_boss: bool) -> void:
	var game := get_parent()
	if not game.has_method("_advance_campaign_stage"):
		scenario = "stage_8_preview_setup_failed"
		return
	for _stage in range(7):
		game._advance_campaign_stage()
	if game.active_stage_definition.stage_id != &"stage_8":
		scenario = "stage_8_preview_setup_failed"
		return
	if show_boss:
		game.player.position = Vector2(3515.0, 580.0)
		game.camera.position.x = 3600.0
		game.encounter_director._update_scene(game.player.position.x)
		game.encounter_director.force_start_encounter(4)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.definition.enemy_id != &"architect_calder":
				enemy.queue_free()
				continue
			enemy.set_physics_process(false)
			enemy.facing = -1
			enemy.invulnerable = 999.0
			enemy.behavior_phase = enemy.BehaviorPhase.TELEGRAPH
			enemy.behavior_timer = 999.0
			enemy.queue_redraw()
	else:
		game.player.position = Vector2(2150.0, 585.0)
		game.camera.position.x = 2100.0
		game.encounter_director.completed = true
		game.encounter_director._update_scene(game.player.position.x)
	for hazard in get_tree().get_nodes_in_group("lab_hazards"):
		hazard.set_physics_process(false)
		hazard.lab_damage_active = false
		hazard.lab_warning_active = true
		hazard.queue_redraw()
	game.player.set_physics_process(false)
	game.hud.banner_time = 0.0
	game.hud.dialogue_time = 0.0
	game.set_process(false)


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


func _start_campaign_flow_preview(complete: bool) -> void:
	var game := get_parent()
	if not game.has_method("_open_campaign_map") or not game.has_method("_complete_first_half_campaign"):
		scenario = "campaign_flow_preview_setup_failed"
		return
	game.score = 68420
	game.hud.set_score(game.score)
	game.lives = 1
	game.campaign_stage_index = 7 if complete else 4
	game.active_stage_definition = game.CAMPAIGN_STAGE_DEFINITIONS[game.campaign_stage_index]
	game.completed_stage_count = 8 if complete else 5
	if complete:
		game._complete_first_half_campaign()
		game._open_credits()
		game._open_campaign_report()
	else:
		game._open_campaign_map(5)
	game.set_process(false)
	game.player.set_physics_process(false)


func _start_campaign_epilogue_preview(show_credits: bool) -> void:
	var game := get_parent()
	if not game.has_method("_complete_first_half_campaign"):
		scenario = "campaign_epilogue_preview_setup_failed"
		return
	game.score = 136500
	game.hud.set_score(game.score)
	game.lives = 2
	game.campaign_stage_index = 7
	game.active_stage_definition = game.CAMPAIGN_STAGE_DEFINITIONS[7]
	game.completed_stage_count = 8
	game.campaign_completion_bonus_applied = true
	game._complete_first_half_campaign()
	if show_credits:
		game._open_credits()
	game.set_process(false)
	game.player.set_physics_process(false)


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
