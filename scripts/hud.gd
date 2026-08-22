extends Control

var health := 120
var max_health := 120
var score := 0
var lives := 2
var boss_health := 0
var boss_max := 0
var boss_name := "WARDEN"
var boss_phase := 1
var banner := ""
var banner_sub := ""
var banner_time := 0.0
var mode := "title"
var stage_time_remaining := 0.0
var dialogue_speaker := ""
var dialogue_line := ""
var dialogue_time := 0.0
var weapon_name := ""
var weapon_ammo := 0
var victory_phase := &"none"
var victory_time_bonus := 0
var victory_life_bonus := 0
var victory_clear_bonus := 0
var victory_final_score := 0
var victory_stage_number := 1
var victory_stage_name := "THE RUINED DISTRICT"
var victory_clear_message := "AREA SECURED"
var victory_has_next := false
var campaign_stage_nodes: Array[Dictionary] = []
var campaign_target_index := 0
var campaign_completed_count := 0
var campaign_display_score := 0
var campaign_display_lives := 2
var campaign_final_bonus := 0
var stage_area := 1
var stage_area_total := 1
var stage_hostiles := 0
var arena_locked := false
var force_touch_layout := false
var player_name := "RANGER"
var player_color := Color("#f5dc7c")
var hero_roster: Array[Resource] = []
var selected_hero_index := 0
var local_player_states: Array[Dictionary] = []
var local_player_selections: Array[Dictionary] = []
var animation_preview_hero: Resource
var profile_high_scores: Array[Dictionary] = []
var option_values: Dictionary = {}
var option_selected_index := 0
var option_return_to_game := false
var continue_offer_times := {}
var final_score_rank := -1
var accessibility_ui_scale := 1.0
var control_bindings := {}
var control_selected_index := 0
var pending_rebind_action := ""
var font: Font

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	font = ThemeDB.fallback_font
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if banner_time > 0.0:
		banner_time -= delta
		queue_redraw()
	if dialogue_time > 0.0:
		dialogue_time -= delta
		queue_redraw()
	if float(health) / maxf(max_health, 1) < 0.3 or (mode == "playing" and stage_time_remaining <= 30.0):
		queue_redraw()

func set_player_health(current: int, maximum: int) -> void:
	health = current
	max_health = maximum
	_update_primary_player_state({"health": current, "max_health": maximum})
	queue_redraw()

func set_score(value: int) -> void:
	score = value
	queue_redraw()

func set_lives(value: int) -> void:
	lives = value
	_update_primary_player_state({"lives": value})
	queue_redraw()

func set_boss_health(current: int, maximum: int) -> void:
	boss_health = current
	boss_max = maximum
	queue_redraw()


func set_boss_identity(display_name: String, phase_number: int) -> void:
	boss_name = display_name
	boss_phase = maxi(phase_number, 1)
	queue_redraw()


func show_dialogue(speaker: String, line: String, duration: float = 2.8) -> void:
	dialogue_speaker = speaker
	dialogue_line = line
	dialogue_time = maxf(duration, 0.0)
	queue_redraw()

func show_banner(text: String, subtext: String = "", duration: float = 2.0) -> void:
	banner = text
	banner_sub = subtext
	banner_time = duration
	queue_redraw()

func set_mode(value: String) -> void:
	mode = value
	queue_redraw()


func set_arcade_profile(scores: Array, settings: Dictionary) -> void:
	profile_high_scores.clear()
	for entry in scores:
		if entry is Dictionary:
			profile_high_scores.append(entry.duplicate(true))
	option_values = settings.duplicate(true)
	accessibility_ui_scale = clampf(float(settings.get("ui_scale", 1.0)), 0.85, 1.2)
	queue_redraw()


func _scaled_font_size(base_size: int) -> int:
	return maxi(roundi(base_size * accessibility_ui_scale), 10)


func set_options(settings: Dictionary, selected_index: int, returning_to_game: bool) -> void:
	option_values = settings.duplicate(true)
	option_selected_index = clampi(selected_index, 0, 9)
	option_return_to_game = returning_to_game
	mode = "options"
	queue_redraw()


func set_controls(bindings: Dictionary, selected_index: int, pending_action: String) -> void:
	control_bindings = bindings.duplicate(true)
	control_selected_index = clampi(selected_index, 0, 7)
	pending_rebind_action = pending_action
	mode = "controls"
	queue_redraw()


func set_continue_offer(slot_index: int, seconds: float) -> void:
	if seconds < 0.0:
		continue_offer_times.erase(slot_index)
	else:
		continue_offer_times[slot_index] = seconds
	queue_redraw()


func set_final_score_rank(rank: int) -> void:
	final_score_rank = rank
	queue_redraw()


func set_player_identity(display_name: String, color: Color) -> void:
	player_name = display_name
	player_color = color
	_update_primary_player_state({"name": display_name, "color": color})
	queue_redraw()


func set_hero_roster(definitions: Array, selected_index: int) -> void:
	hero_roster.clear()
	for definition in definitions:
		if definition != null:
			hero_roster.append(definition)
	selected_hero_index = clampi(selected_index, 0, maxi(hero_roster.size() - 1, 0))
	queue_redraw()


func set_local_player_selections(selections: Array) -> void:
	local_player_selections.clear()
	for selection in selections:
		local_player_selections.append(selection.duplicate())
	local_player_selections.sort_custom(func(a, b): return int(a.slot_index) < int(b.slot_index))
	queue_redraw()


func set_local_player_state(
	slot_index: int,
	display_name: String,
	color: Color,
	current_health: int,
	maximum_health: int,
	remaining_lives: int,
	current_weapon_name := "",
	current_weapon_ammo := 0,
	down := false
) -> void:
	var state := {
		"slot_index": slot_index,
		"name": display_name,
		"color": color,
		"health": current_health,
		"max_health": maximum_health,
		"lives": remaining_lives,
		"weapon_name": current_weapon_name,
		"weapon_ammo": current_weapon_ammo,
		"down": down,
		"down_time": -1.0,
	}
	var existing_index := _local_player_state_index(slot_index)
	if existing_index >= 0:
		local_player_states[existing_index] = state
	else:
		local_player_states.append(state)
	local_player_states.sort_custom(func(a, b): return int(a.slot_index) < int(b.slot_index))
	if slot_index == 0:
		player_name = display_name
		player_color = color
		health = current_health
		max_health = maximum_health
		lives = remaining_lives
		weapon_name = current_weapon_name
		weapon_ammo = current_weapon_ammo
	queue_redraw()


func set_local_player_down_timer(slot_index: int, seconds: float) -> void:
	var existing_index := _local_player_state_index(slot_index)
	if existing_index < 0:
		return
	local_player_states[existing_index]["down"] = seconds >= 0.0 or is_equal_approx(seconds, -2.0)
	local_player_states[existing_index]["down_time"] = seconds
	queue_redraw()


func remove_local_player_state(slot_index: int) -> void:
	var existing_index := _local_player_state_index(slot_index)
	if existing_index >= 0:
		local_player_states.remove_at(existing_index)
	queue_redraw()


func _local_player_state_index(slot_index: int) -> int:
	for index in range(local_player_states.size()):
		if int(local_player_states[index].slot_index) == slot_index:
			return index
	return -1


func _update_primary_player_state(changes: Dictionary) -> void:
	var index := _local_player_state_index(0)
	if index < 0:
		return
	for key in changes:
		local_player_states[index][key] = changes[key]


func set_hero_animation_preview(hero: Resource) -> void:
	animation_preview_hero = hero
	queue_redraw()


func set_stage_time(seconds: float) -> void:
	stage_time_remaining = maxf(0.0, seconds)
	queue_redraw()


func set_weapon(display_name: String, ammo: int) -> void:
	weapon_name = display_name
	weapon_ammo = maxi(ammo, 0)
	_update_primary_player_state({"weapon_name": display_name, "weapon_ammo": weapon_ammo})
	queue_redraw()


func set_stage_progress(area: int, total: int, hostiles: int, locked: bool) -> void:
	var next_area := clampi(area, 1, maxi(total, 1))
	var next_total := maxi(total, 1)
	var next_hostiles := maxi(hostiles, 0)
	if (
		next_area == stage_area
		and next_total == stage_area_total
		and next_hostiles == stage_hostiles
		and locked == arena_locked
	):
		return
	stage_area = next_area
	stage_area_total = next_total
	stage_hostiles = next_hostiles
	arena_locked = locked
	queue_redraw()


static func dialogue_panel_rect(touch_layout: bool) -> Rect2:
	return Rect2(310, 350, 560, 116) if touch_layout else Rect2(270, 540, 740, 92)


static func wrap_dialogue_line(line: String, max_characters: int = 42) -> PackedStringArray:
	var lines := PackedStringArray()
	var current := ""
	for word in line.split(" ", false):
		var candidate := word if current.is_empty() else current + " " + word
		if candidate.length() > max_characters and not current.is_empty():
			lines.append(current)
			current = word
		else:
			current = candidate
	if not current.is_empty():
		lines.append(current)
	return lines


func _touch_layout_active() -> bool:
	return force_touch_layout or DisplayServer.is_touchscreen_available() or "--touch-preview" in OS.get_cmdline_user_args()


func set_victory_summary(time_bonus: int, life_bonus: int, clear_bonus: int, final_score: int) -> void:
	victory_time_bonus = maxi(time_bonus, 0)
	victory_life_bonus = maxi(life_bonus, 0)
	victory_clear_bonus = maxi(clear_bonus, 0)
	victory_final_score = maxi(final_score, 0)
	mode = "victory"
	queue_redraw()


func set_victory_phase(value: StringName) -> void:
	victory_phase = value
	queue_redraw()


func set_victory_context(stage_number: int, stage_name: String, clear_message: String, has_next: bool) -> void:
	victory_stage_number = maxi(stage_number, 1)
	victory_stage_name = stage_name
	victory_clear_message = clear_message
	victory_has_next = has_next
	queue_redraw()


func set_campaign_map(stages: Array, target_index: int, completed_count: int, current_score: int, current_lives: int) -> void:
	campaign_stage_nodes.clear()
	for stage in stages:
		campaign_stage_nodes.append({
			"number": stage.stage_number,
			"name": stage.display_name,
			"subtitle": stage.route_subtitle,
			"position": stage.map_position,
			"threat": stage.enemy_health_scale,
			"bonus": stage.clear_bonus,
		})
	campaign_target_index = clampi(target_index, 0, maxi(campaign_stage_nodes.size() - 1, 0))
	campaign_completed_count = clampi(completed_count, 0, campaign_stage_nodes.size())
	campaign_display_score = maxi(current_score, 0)
	campaign_display_lives = current_lives
	mode = "campaign_map"
	queue_redraw()


func set_campaign_complete(final_score: int, completion_bonus: int, current_lives: int) -> void:
	campaign_display_score = maxi(final_score, 0)
	campaign_final_bonus = maxi(completion_bonus, 0)
	campaign_display_lives = current_lives
	mode = "campaign_complete"
	queue_redraw()


func set_ending(final_score: int, current_lives: int) -> void:
	campaign_display_score = maxi(final_score, 0)
	campaign_display_lives = current_lives
	mode = "ending"
	queue_redraw()


func set_credits(final_score: int) -> void:
	campaign_display_score = maxi(final_score, 0)
	mode = "credits"
	queue_redraw()

func _draw() -> void:
	var ratio := clampf(float(health)/maxf(max_health,1),0.0,1.0)
	var danger_pulse := 0.72 + sin(Time.get_ticks_msec() * 0.012) * 0.28
	if mode == "playing":
		_draw_local_player_panels(danger_pulse)
	if mode == "playing":
		var total_seconds := ceili(stage_time_remaining)
		var minutes := int(total_seconds / 60)
		var seconds := total_seconds % 60
		var timer_color := Color("#ef5b50") if total_seconds <= 30 else Color("#f4dc83")
		var multiplayer_hud := local_player_states.size() > 1
		var timer_x := 800.0 if multiplayer_hud else 578.0
		var timer_width := 108.0 if multiplayer_hud else 124.0
		draw_rect(Rect2(timer_x, 20, timer_width, 48), Color(0.035, 0.045, 0.07, 0.88))
		draw_rect(Rect2(timer_x, 20, timer_width, 4), timer_color)
		draw_string(font, Vector2(timer_x, 54), "%02d:%02d" % [minutes, seconds], HORIZONTAL_ALIGNMENT_CENTER, timer_width, _scaled_font_size(24), timer_color)
		if not multiplayer_hud and not weapon_name.is_empty() and weapon_ammo > 0:
			draw_rect(Rect2(474, 20, 92, 48), Color(0.035, 0.045, 0.07, 0.88))
			draw_rect(Rect2(474, 20, 92, 4), Color("#74c9aa"))
			draw_string(font, Vector2(478, 42), weapon_name, HORIZONTAL_ALIGNMENT_CENTER, 84, 13, Color("#d8efe7"))
			draw_string(font, Vector2(478, 61), "×%02d" % weapon_ammo, HORIZONTAL_ALIGNMENT_CENTER, 84, 16, Color.WHITE)
		if boss_max <= 0 or boss_health <= 0:
			var status_color := Color("#ef6a56") if arena_locked else Color("#70d0ad")
			var objective_x := 922.0 if multiplayer_hud else 882.0
			var objective_width := 322.0 if multiplayer_hud else 362.0
			draw_rect(Rect2(objective_x, 20, objective_width, 64), Color(0.035, 0.045, 0.07, 0.9))
			draw_rect(Rect2(objective_x, 20, objective_width, 4), status_color)
			draw_string(font, Vector2(objective_x + 18, 48), "AREA %d/%d" % [stage_area, stage_area_total], HORIZONTAL_ALIGNMENT_LEFT, 125, _scaled_font_size(19), Color("#f4dc83"))
			var objective := "HOSTILES  %02d" % stage_hostiles if arena_locked else "ADVANCE  →"
			draw_string(font, Vector2(objective_x + 137, 48), objective, HORIZONTAL_ALIGNMENT_RIGHT, objective_width - 155, _scaled_font_size(19), status_color)
			draw_string(font, Vector2(objective_x + 18, 72), "COMBAT ZONE LOCKED" if arena_locked else "ROUTE OPEN", HORIZONTAL_ALIGNMENT_LEFT, objective_width - 36, 13, Color("#b8c8c3"))
		if ratio < 0.3:
			draw_string(font, Vector2(350, 99), "DANGER", HORIZONTAL_ALIGNMENT_RIGHT, 48, 13, Color(1.0, 0.32, 0.24, danger_pulse))

	# Keyboard hints are hidden on touch devices where virtual controls replace them.
	if mode == "playing" and not _touch_layout_active():
		draw_rect(Rect2(22,674,715,30),Color(0.02,0.03,0.045,0.72))
		draw_string(font,Vector2(35,696),"MOVE WASD/ARROWS   ATTACK J/Z   JUMP K/X   COMMAND DOWN>FORWARD+ATTACK   SPECIAL ATTACK+JUMP",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#dbe4df"))

	if boss_max > 0 and boss_health > 0 and mode == "playing":
		draw_rect(Rect2(778,34,466,49),Color(0.04,0.025,0.04,0.9))
		draw_string(font,Vector2(798,56),"%s  // PHASE %d" % [boss_name, boss_phase],HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#ffcf5e"))
		draw_rect(Rect2(798,63,424,10),Color("#3b1d27"))
		draw_rect(Rect2(798,63,424.0*boss_health/boss_max,10),Color("#e94845"))

	if banner_time > 0.0 and mode == "playing":
		draw_rect(Rect2(350,260,580,110),Color(0.025,0.035,0.05,0.82))
		draw_rect(Rect2(350,260,580,4),Color("#efbf4d"))
		draw_string(font,Vector2(350,310),banner,HORIZONTAL_ALIGNMENT_CENTER,580,34,Color("#ffe17c"))
		draw_string(font,Vector2(350,344),banner_sub,HORIZONTAL_ALIGNMENT_CENTER,580,18,Color("#d5e0db"))

	if dialogue_time > 0.0 and mode == "playing":
		var touch_dialogue := _touch_layout_active()
		var dialogue_rect := dialogue_panel_rect(touch_dialogue)
		draw_rect(dialogue_rect, Color(0.025, 0.018, 0.025, 0.94))
		draw_rect(Rect2(dialogue_rect.position, Vector2(7, dialogue_rect.size.y)), Color("#d84a35"))
		var dialogue_text_width := dialogue_rect.size.x - 48.0
		draw_string(font, dialogue_rect.position + Vector2(24, 30), dialogue_speaker, HORIZONTAL_ALIGNMENT_LEFT, dialogue_text_width, _scaled_font_size(18), Color("#f0b65b"))
		if touch_dialogue:
			var wrapped := wrap_dialogue_line(dialogue_line)
			for line_index in range(mini(wrapped.size(), 2)):
				draw_string(font, dialogue_rect.position + Vector2(24, 65 + line_index * 25), wrapped[line_index], HORIZONTAL_ALIGNMENT_LEFT, dialogue_text_width, _scaled_font_size(18), Color.WHITE)
		else:
			draw_string(font, dialogue_rect.position + Vector2(24, 67), dialogue_line, HORIZONTAL_ALIGNMENT_LEFT, dialogue_text_width, _scaled_font_size(24), Color.WHITE)
	if mode == "playing" and not continue_offer_times.is_empty():
		_draw_continue_offer()

	if mode == "title":
		draw_rect(Rect2(0,0,size.x,size.y),Color(0.01,0.02,0.035,0.58))
		var top_score := int(profile_high_scores[0].score) if not profile_high_scores.is_empty() else 0
		draw_string(font, Vector2(0, 48), "HI  %08d" % top_score, HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color("#9fc9bd"))
		draw_string(font,Vector2(0,210),"WILDLAND STRIKE",HORIZONTAL_ALIGNMENT_CENTER,size.x,68,Color("#f1c14f"))
		draw_string(font,Vector2(0,258),"ARCADE SURVIVAL",HORIZONTAL_ALIGNMENT_CENTER,size.x,27,Color("#d0eee3"))
		draw_rect(Rect2(size.x/2-210,330,420,64),Color(0.03,0.05,0.07,0.9))
		draw_rect(Rect2(size.x/2-210,330,420,4),Color("#e55045"))
		draw_string(font,Vector2(size.x/2-210,371),"TAP / ENTER TO START",HORIZONTAL_ALIGNMENT_CENTER,420,24,Color.WHITE)
		draw_string(font,Vector2(0,448),"JUMP: HIGH SCORES     SPECIAL: OPTIONS",HORIZONTAL_ALIGNMENT_CENTER,size.x,18,Color("#b9c7c2"))
		draw_string(font,Vector2(0,486),"AN ORIGINAL CLEAN-ROOM ARCADE CAMPAIGN",HORIZONTAL_ALIGNMENT_CENTER,size.x,16,Color("#718f88"))
	elif mode == "attract":
		_draw_attract_screen()
	elif mode == "high_scores":
		_draw_high_score_screen()
	elif mode == "options":
		_draw_options_screen()
	elif mode == "controls":
		_draw_controls_screen()
	elif mode == "select":
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.008, 0.014, 0.025, 1.0))
		draw_string(font, Vector2(0, 72), "SELECT OPERATIVE", HORIZONTAL_ALIGNMENT_CENTER, size.x, 42, Color("#f2c756"))
		draw_string(font, Vector2(0, 105), "FOUR ROLES // ONE MISSION", HORIZONTAL_ALIGNMENT_CENTER, size.x, 17, Color("#9fc9bd"))
		for index in range(hero_roster.size()):
			_draw_hero_card(hero_roster[index], index, _hero_card_selected(index))
		var select_hint := "TAP A CARD TWICE TO DEPLOY" if _touch_layout_active() else "EACH PLAYER CHOOSES     A / START  READY     BACK  CANCEL"
		draw_string(font, Vector2(0, 664), select_hint, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color.WHITE)
	elif mode == "hero_animation":
		_draw_hero_animation_preview()
	elif mode == "campaign_map":
		_draw_campaign_map()
	elif mode == "victory":
		draw_rect(Rect2(0,0,size.x,size.y),Color(0.01,0.02,0.03,0.63))
		draw_rect(Rect2(318, 142, 644, 438), Color(0.025, 0.035, 0.05, 0.94))
		draw_rect(Rect2(318, 142, 644, 6), Color("#f2c756"))
		draw_string(font, Vector2(318, 207), "STAGE %d CLEAR" % victory_stage_number, HORIZONTAL_ALIGNMENT_CENTER, 644, 43, Color("#f2c756"))
		draw_string(font, Vector2(318, 238), victory_stage_name, HORIZONTAL_ALIGNMENT_CENTER, 644, 19, Color("#f0bd5b"))
		draw_string(font, Vector2(318, 266), victory_clear_message, HORIZONTAL_ALIGNMENT_CENTER, 644, 17, Color("#d6dfdb"))
		if victory_phase == &"bonus" or victory_phase == &"complete":
			draw_string(font, Vector2(390, 326), "TIME BONUS", HORIZONTAL_ALIGNMENT_LEFT, 300, 21, Color("#a7d9cc"))
			draw_string(font, Vector2(720, 326), "%07d" % victory_time_bonus, HORIZONTAL_ALIGNMENT_RIGHT, 170, 21, Color.WHITE)
			draw_string(font, Vector2(390, 366), "LIFE BONUS", HORIZONTAL_ALIGNMENT_LEFT, 300, 21, Color("#a7d9cc"))
			draw_string(font, Vector2(720, 366), "%07d" % victory_life_bonus, HORIZONTAL_ALIGNMENT_RIGHT, 170, 21, Color.WHITE)
			draw_string(font, Vector2(390, 406), "CLEAR BONUS", HORIZONTAL_ALIGNMENT_LEFT, 300, 21, Color("#a7d9cc"))
			draw_string(font, Vector2(720, 406), "%07d" % victory_clear_bonus, HORIZONTAL_ALIGNMENT_RIGHT, 170, 21, Color.WHITE)
			draw_line(Vector2(390, 430), Vector2(890, 430), Color("#f2c756"), 2.0)
			draw_string(font, Vector2(390, 470), "FINAL SCORE", HORIZONTAL_ALIGNMENT_LEFT, 300, 24, Color("#f2c756"))
			draw_string(font, Vector2(690, 470), "%08d" % victory_final_score, HORIZONTAL_ALIGNMENT_RIGHT, 200, 24, Color.WHITE)
		if victory_phase == &"complete":
			var victory_hint := "TAP / ENTER FOR ROUTE MAP" if victory_has_next else "TAP / ENTER FOR CAMPAIGN REPORT"
			draw_string(font, Vector2(318, 538), victory_hint, HORIZONTAL_ALIGNMENT_CENTER, 644, 20, Color("#d6dfdb"))
	elif mode == "ending":
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.006, 0.012, 0.025, 0.96))
		for band in range(9):
			var band_y := 110.0 + band * 64.0
			draw_line(Vector2(0, band_y), Vector2(size.x, band_y - 86.0), Color(0.12, 0.42, 0.38, 0.12), 2.0)
		draw_circle(Vector2(640, 232), 112.0, Color(0.16, 0.76, 0.54, 0.1))
		draw_arc(Vector2(640, 232), 112.0, 0.0, TAU, 48, Color(0.38, 0.92, 0.7, 0.5), 5.0)
		draw_arc(Vector2(640, 232), 78.0, 0.0, TAU, 48, Color(1.0, 0.26, 0.7, 0.44), 4.0)
		draw_string(font, Vector2(0, 113), "THE GENESIS CORE IS SILENT", HORIZONTAL_ALIGNMENT_CENTER, size.x, 42, Color("#f2c756"))
		draw_string(font, Vector2(220, 385), "THE LOCKDOWN BREAKS. THE CAPTIVE WILDLANDS ARE FREE.", HORIZONTAL_ALIGNMENT_CENTER, 840, 22, Color("#c8e8df"))
		draw_string(font, Vector2(220, 430), "ABOVE THE MOUNTAIN, THE FIRST CLEAN DAWN RETURNS.", HORIZONTAL_ALIGNMENT_CENTER, 840, 22, Color("#a7d9cc"))
		draw_string(font, Vector2(220, 500), "OPERATIVES RETURNED  %d     FINAL SCORE  %08d" % [maxi(campaign_display_lives, 0), campaign_display_score], HORIZONTAL_ALIGNMENT_CENTER, 840, 20, Color.WHITE)
		draw_string(font, Vector2(0, 636), "TAP / ENTER FOR CREDITS", HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color("#f2c756"))
	elif mode == "credits":
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.008, 0.014, 0.025, 0.98))
		draw_rect(Rect2(302, 56, 676, 604), Color(0.02, 0.034, 0.05, 0.96))
		draw_rect(Rect2(302, 56, 676, 6), Color("#f2c756"))
		draw_string(font, Vector2(302, 122), "WILDLAND STRIKE", HORIZONTAL_ALIGNMENT_CENTER, 676, 42, Color("#f2c756"))
		draw_string(font, Vector2(302, 154), "AN ORIGINAL CLEAN-ROOM ARCADE CAMPAIGN", HORIZONTAL_ALIGNMENT_CENTER, 676, 17, Color("#9fc9bd"))
		var credit_lines := [
			["GAME DESIGN & DIRECTION", "WILDLAND STRIKE TEAM"],
			["ENGINE & TOOLS", "GODOT ENGINE"],
			["ORIGINAL ART & AUDIO", "CLEAN-ROOM PRODUCTION"],
			["COMBAT / CAMPAIGN / MOBILE", "PROJECT CONTRIBUTORS"],
			["QUALITY ASSURANCE", "DETERMINISTIC + WEB + iOS"],
		]
		for index in range(credit_lines.size()):
			var y := 228.0 + index * 70.0
			draw_string(font, Vector2(340, y), credit_lines[index][0], HORIZONTAL_ALIGNMENT_LEFT, 285, 16, Color("#a7d9cc"))
			draw_string(font, Vector2(645, y), credit_lines[index][1], HORIZONTAL_ALIGNMENT_RIGHT, 295, 18, Color.WHITE)
		draw_line(Vector2(360, 575), Vector2(920, 575), Color("#f2c756"), 2.0)
		draw_string(font, Vector2(302, 612), "THANK YOU FOR PLAYING  //  %08d" % campaign_display_score, HORIZONTAL_ALIGNMENT_CENTER, 676, 20, Color("#f2c756"))
		draw_string(font, Vector2(0, 694), "TAP / ENTER FOR FINAL REPORT", HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color("#d6dfdb"))
	elif mode == "campaign_complete":
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.008, 0.014, 0.025, 0.92))
		draw_rect(Rect2(280, 112, 720, 488), Color(0.025, 0.04, 0.055, 0.98))
		draw_rect(Rect2(280, 112, 720, 7), Color("#f2c756"))
		draw_string(font, Vector2(280, 202), "CAMPAIGN COMPLETE", HORIZONTAL_ALIGNMENT_CENTER, 720, 44, Color("#f2c756"))
		draw_string(font, Vector2(280, 245), "%d-STAGE WILDLAND FRONT SECURED" % maxi(campaign_stage_nodes.size(), campaign_completed_count), HORIZONTAL_ALIGNMENT_CENTER, 720, 21, Color("#b7e8df"))
		draw_string(font, Vector2(355, 335), "FRONT COMPLETION BONUS", HORIZONTAL_ALIGNMENT_LEFT, 360, 22, Color("#a7d9cc"))
		draw_string(font, Vector2(740, 335), "%08d" % campaign_final_bonus, HORIZONTAL_ALIGNMENT_RIGHT, 180, 22, Color.WHITE)
		draw_string(font, Vector2(355, 395), "REMAINING CONTINUES", HORIZONTAL_ALIGNMENT_LEFT, 360, 22, Color("#a7d9cc"))
		draw_string(font, Vector2(740, 395), "%02d" % campaign_display_lives, HORIZONTAL_ALIGNMENT_RIGHT, 180, 22, Color.WHITE)
		draw_line(Vector2(355, 430), Vector2(925, 430), Color("#f2c756"), 2.0)
		draw_string(font, Vector2(355, 482), "FINAL SCORE", HORIZONTAL_ALIGNMENT_LEFT, 330, 27, Color("#f2c756"))
		draw_string(font, Vector2(700, 482), "%08d" % campaign_display_score, HORIZONTAL_ALIGNMENT_RIGHT, 225, 27, Color.WHITE)
		if final_score_rank >= 0:
			draw_string(font, Vector2(280, 522), "LOCAL RANK  #%02d" % (final_score_rank + 1), HORIZONTAL_ALIGNMENT_CENTER, 720, 17, Color("#9fc9bd"))
		draw_string(font, Vector2(280, 555), "TAP / ENTER TO RETURN TO TITLE", HORIZONTAL_ALIGNMENT_CENTER, 720, 19, Color("#d6dfdb"))
	elif mode == "gameover":
		draw_rect(Rect2(0,0,size.x,size.y),Color(0.01,0.02,0.03,0.63))
		draw_string(font,Vector2(0,278),"GAME OVER",HORIZONTAL_ALIGNMENT_CENTER,size.x,54,Color("#ed5a4c"))
		draw_string(font,Vector2(0,338),"FINAL SCORE  %08d"%score,HORIZONTAL_ALIGNMENT_CENTER,size.x,25,Color.WHITE)
		if final_score_rank >= 0:
			draw_string(font, Vector2(0, 374), "LOCAL RANK  #%02d" % (final_score_rank + 1), HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color("#f2c756"))
		draw_string(font,Vector2(0,402),"TAP / ENTER TO RESTART",HORIZONTAL_ALIGNMENT_CENTER,size.x,20,Color("#d6dfdb"))


func _draw_attract_screen() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.006, 0.014, 0.026, 0.97))
	draw_rect(Rect2(120, 72, 1040, 560), Color(0.025, 0.045, 0.06, 0.96))
	draw_rect(Rect2(120, 72, 1040, 6), Color("#f2c756"))
	draw_string(font, Vector2(120, 132), "HOW TO SURVIVE THE WILDLANDS", HORIZONTAL_ALIGNMENT_CENTER, 1040, 34, Color("#f2c756"))
	var tips := [
		["MOVE", "EIGHT DIRECTIONS // DOUBLE TAP TO RUN"],
		["STRIKE", "FOUR-HIT CHAIN // RUN + AIR ATTACKS"],
		["GRAPPLE", "CLOSE ATTACK // STRIKE OR THROW"],
		["SPECIAL", "ATTACK + JUMP // COSTS HEALTH ON HIT"],
		["CO-OP", "REVIVE ALLIES // LINK SPECIALS"],
	]
	for index in range(tips.size()):
		var y := 202.0 + index * 66.0
		draw_string(font, Vector2(184, y), tips[index][0], HORIZONTAL_ALIGNMENT_LEFT, 160, 18, Color("#9fc9bd"))
		draw_string(font, Vector2(350, y), tips[index][1], HORIZONTAL_ALIGNMENT_LEFT, 730, 20, Color.WHITE)
	draw_string(font, Vector2(120, 590), "8 STAGES  //  4 OPERATIVES  //  1–3 LOCAL PLAYERS", HORIZONTAL_ALIGNMENT_CENTER, 1040, 18, Color("#b7e8df"))
	draw_string(font, Vector2(0, 690), "TAP / ENTER TO JOIN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color("#f2c756"))


func _draw_high_score_screen() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.008, 0.014, 0.025, 0.98))
	draw_rect(Rect2(340, 58, 600, 604), Color(0.025, 0.04, 0.055, 0.98))
	draw_rect(Rect2(340, 58, 600, 6), Color("#f2c756"))
	draw_string(font, Vector2(340, 118), "LOCAL HIGH SCORES", HORIZONTAL_ALIGNMENT_CENTER, 600, 34, Color("#f2c756"))
	draw_string(font, Vector2(380, 157), "RANK   OPERATIVE       SCORE       STAGE / TEAM", HORIZONTAL_ALIGNMENT_LEFT, 520, 14, Color("#9fc9bd"))
	for index in range(10):
		var y := 205.0 + index * 39.0
		if index < profile_high_scores.size():
			var entry: Dictionary = profile_high_scores[index]
			draw_string(font, Vector2(382, y), "%02d     %-12s   %08d     %d / P%d" % [index + 1, String(entry.name), int(entry.score), int(entry.stage), int(entry.players)], HORIZONTAL_ALIGNMENT_LEFT, 520, 16, Color.WHITE if index > 2 else Color("#f2c756"))
		else:
			draw_string(font, Vector2(382, y), "%02d     ---            00000000     - / --" % (index + 1), HORIZONTAL_ALIGNMENT_LEFT, 520, 16, Color("#4e6268"))
	draw_string(font, Vector2(0, 700), "TAP / ENTER TO RETURN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color("#d6dfdb"))


func _draw_options_screen() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.006, 0.012, 0.023, 0.96))
	draw_rect(Rect2(338, 82, 604, 544), Color(0.025, 0.04, 0.055, 0.99))
	draw_rect(Rect2(338, 82, 604, 6), Color("#f2c756"))
	draw_string(font, Vector2(338, 145), "PAUSED // OPTIONS" if option_return_to_game else "OPTIONS", HORIZONTAL_ALIGNMENT_CENTER, 604, 36, Color("#f2c756"))
	var labels := ["MUSIC VOLUME", "EFFECTS VOLUME", "TOUCH SIZE", "TOUCH LAYOUT", "UI SIZE", "SCREEN SHAKE", "HIT FLASH", "HAPTICS", "HIGH-CONTRAST CUES", "REMAP CONTROLS"]
	var keys := ["music_volume", "sfx_volume", "touch_scale", "touch_layout", "ui_scale", "screen_shake", "hit_flash", "haptics", "high_contrast_cues", "controls"]
	for index in range(labels.size()):
		var y := 174.0 + index * 44.0
		var selected := index == option_selected_index
		if selected:
			draw_rect(Rect2(378, y - 27, 524, 36), Color(0.16, 0.32, 0.31, 0.58))
			draw_rect(Rect2(378, y - 27, 5, 36), Color("#f2c756"))
		draw_string(font, Vector2(402, y), labels[index], HORIZONTAL_ALIGNMENT_LEFT, 290, _scaled_font_size(17), Color.WHITE if selected else Color("#a7b8b3"))
		draw_string(font, Vector2(700, y), _option_value_label(keys[index]), HORIZONTAL_ALIGNMENT_RIGHT, 170, _scaled_font_size(17), Color("#f2c756") if selected else Color("#9fc9bd"))
	draw_string(font, Vector2(338, 622), "UP/DOWN SELECT     LEFT/RIGHT CHANGE     TAP SIDES", HORIZONTAL_ALIGNMENT_CENTER, 604, 14, Color("#9fc9bd"))
	draw_string(font, Vector2(0, 690), "ENTER / PAUSE TO %s" % ("RESUME" if option_return_to_game else "RETURN"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 19, Color("#f2c756"))


func _option_value_label(key: String) -> String:
	if key == "controls":
		return "OPEN  >"
	if key == "touch_layout":
		return String(option_values.get(key, "classic")).replace("_", " ").to_upper()
	if key in ["music_volume", "sfx_volume", "touch_scale", "ui_scale"]:
		return "%d%%" % roundi(float(option_values.get(key, 1.0)) * 100.0)
	return "ON" if bool(option_values.get(key, true)) else "OFF"


func _draw_controls_screen() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.006, 0.012, 0.023, 0.97))
	draw_rect(Rect2(338, 70, 604, 570), Color(0.025, 0.04, 0.055, 0.99))
	draw_rect(Rect2(338, 70, 604, 6), Color("#f2c756"))
	draw_string(font, Vector2(338, 128), "REMAP CONTROLS", HORIZONTAL_ALIGNMENT_CENTER, 604, 34, Color("#f2c756"))
	var actions := ["move_left", "move_right", "move_up", "move_down", "attack", "jump", "special", "pause"]
	var labels := ["MOVE LEFT", "MOVE RIGHT", "MOVE UP", "MOVE DOWN", "ATTACK", "JUMP", "SPECIAL", "PAUSE"]
	for index in range(actions.size()):
		var y := 184.0 + index * 50.0
		var selected := index == control_selected_index
		if selected:
			draw_rect(Rect2(378, y - 29, 524, 40), Color(0.16, 0.32, 0.31, 0.58))
			draw_rect(Rect2(378, y - 29, 5, 40), Color("#f2c756"))
		draw_string(font, Vector2(402, y), labels[index], HORIZONTAL_ALIGNMENT_LEFT, 260, _scaled_font_size(17), Color.WHITE if selected else Color("#a7b8b3"))
		var key_label := OS.get_keycode_string(int(control_bindings.get(actions[index], 0)))
		if pending_rebind_action == actions[index]:
			key_label = "PRESS A KEY..."
		draw_string(font, Vector2(670, y), key_label, HORIZONTAL_ALIGNMENT_RIGHT, 200, _scaled_font_size(17), Color("#f2c756") if selected else Color("#9fc9bd"))
	draw_string(font, Vector2(338, 606), "ATTACK TO REBIND     ESC CANCELS CAPTURE", HORIZONTAL_ALIGNMENT_CENTER, 604, 14, Color("#9fc9bd"))
	draw_string(font, Vector2(0, 690), "ENTER / PAUSE TO RETURN", HORIZONTAL_ALIGNMENT_CENTER, size.x, 19, Color("#f2c756"))


func _draw_continue_offer() -> void:
	var slot_index: int = int(continue_offer_times.keys()[0])
	var seconds: float = float(continue_offer_times[slot_index])
	var panel := Rect2(380, 205, 520, 280)
	draw_rect(panel, Color(0.018, 0.025, 0.04, 0.96))
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 7)), Color("#e55045"))
	draw_string(font, Vector2(380, 275), "PLAYER %d CONTINUE?" % (slot_index + 1), HORIZONTAL_ALIGNMENT_CENTER, 520, 34, Color("#f2c756"))
	draw_circle(Vector2(640, 356), 58.0, Color(0.2, 0.04, 0.05, 0.9))
	draw_arc(Vector2(640, 356), 58.0, 0.0, TAU, 48, Color("#e55045"), 6.0)
	draw_string(font, Vector2(582, 375), "%d" % maxi(ceili(seconds), 0), HORIZONTAL_ALIGNMENT_CENTER, 116, 52, Color.WHITE)
	draw_string(font, Vector2(380, 448), "ATTACK / START TO CONTINUE", HORIZONTAL_ALIGNMENT_CENTER, 520, 19, Color("#b7e8df"))


func _draw_campaign_map() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.008, 0.016, 0.028, 0.97))
	for band in range(7):
		var y := 118.0 + band * 72.0
		draw_line(Vector2(0, y), Vector2(size.x, y - 36.0), Color(0.08, 0.16, 0.19, 0.22), 2.0)
	draw_string(font, Vector2(0, 62), "WILDLAND CAMPAIGN ROUTE", HORIZONTAL_ALIGNMENT_CENTER, size.x, 38, Color("#f2c756"))
	draw_string(font, Vector2(0, 94), "ACTIVE FRONT // %d OPERATIONS" % campaign_stage_nodes.size(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 17, Color("#9fc9bd"))
	for index in range(campaign_stage_nodes.size() - 1):
		var from: Vector2 = campaign_stage_nodes[index].position
		var to: Vector2 = campaign_stage_nodes[index + 1].position
		var route_color := Color("#6fcdb1") if index < campaign_completed_count else Color("#344950")
		draw_line(from, to, route_color, 8.0)
		draw_line(from, to, Color(0.02, 0.04, 0.05, 0.8), 2.0)
	for index in range(campaign_stage_nodes.size()):
		var node: Dictionary = campaign_stage_nodes[index]
		var point: Vector2 = node.position
		var completed := index < campaign_completed_count
		var selected := index == campaign_target_index
		var locked := index > campaign_target_index
		var node_color := Color("#59c7a6") if completed else (Color("#f2c756") if selected else Color("#42545b"))
		if selected:
			draw_circle(point, 42.0 + sin(Time.get_ticks_msec() * 0.006) * 4.0, Color(node_color, 0.18))
		draw_circle(point, 31.0, Color(0.02, 0.035, 0.045, 0.96))
		draw_arc(point, 31.0, 0, TAU, 32, node_color, 5.0)
		draw_string(font, point + Vector2(-31, 8), "%d" % int(node.number), HORIZONTAL_ALIGNMENT_CENTER, 62, 22, node_color)
		var label_rect := Rect2(point.x - 112.0, point.y + 43.0, 224.0, 62.0)
		draw_rect(label_rect, Color(0.02, 0.035, 0.05, 0.92))
		draw_string(font, label_rect.position + Vector2(8, 23), String(node.name), HORIZONTAL_ALIGNMENT_CENTER, 208, 15, Color("#dce8e3") if not locked else Color("#718087"))
		draw_string(font, label_rect.position + Vector2(8, 47), "CLEARED" if completed else String(node.subtitle), HORIZONTAL_ALIGNMENT_CENTER, 208, 13, node_color)
	if not campaign_stage_nodes.is_empty():
		var target: Dictionary = campaign_stage_nodes[campaign_target_index]
		draw_rect(Rect2(310, 570, 660, 96), Color(0.025, 0.045, 0.06, 0.96))
		draw_rect(Rect2(310, 570, 660, 5), Color("#f2c756"))
		draw_string(font, Vector2(332, 606), "NEXT  STAGE %d // %s" % [int(target.number), String(target.name)], HORIZONTAL_ALIGNMENT_LEFT, 460, 19, Color.WHITE)
		draw_string(font, Vector2(332, 638), "THREAT %.2fx   CLEAR %05d   SCORE %08d   CONTINUES %d" % [float(target.threat), int(target.bonus), campaign_display_score, campaign_display_lives], HORIZONTAL_ALIGNMENT_LEFT, 610, 15, Color("#b7e8df"))
		draw_string(font, Vector2(310, 700), "TAP / ENTER TO DEPLOY", HORIZONTAL_ALIGNMENT_CENTER, 660, 19, Color("#f2c756"))


func _draw_local_player_panels(danger_pulse: float) -> void:
	if local_player_states.size() <= 1:
		_draw_player_panel({
			"slot_index": 0,
			"name": player_name,
			"color": player_color,
			"health": health,
			"max_health": max_health,
			"lives": lives,
			"weapon_name": weapon_name,
			"weapon_ammo": weapon_ammo,
			"down": false,
			"down_time": -1.0,
		}, Rect2(22, 20, 430, 82), danger_pulse, true)
		return
	var panel_width := 250.0
	for index in range(local_player_states.size()):
		_draw_player_panel(local_player_states[index], Rect2(14 + index * 260, 20, panel_width, 64), danger_pulse, false)


func _draw_player_panel(state_data: Dictionary, panel: Rect2, danger_pulse: float, full_size: bool) -> void:
	var color: Color = state_data.color
	var current_health: int = int(state_data.health)
	var maximum_health: int = maxi(int(state_data.max_health), 1)
	var health_ratio := clampf(float(current_health) / maximum_health, 0.0, 1.0)
	var down: bool = bool(state_data.down)
	draw_rect(panel, Color(0.035, 0.045, 0.07, 0.9))
	draw_rect(Rect2(panel.position, Vector2(panel.size.x, 5 if full_size else 4)), color if not down else Color("#a73535"))
	var compact_primary := not full_size and int(state_data.slot_index) == 0
	var name_width := panel.size.x - (128.0 if full_size else (112.0 if compact_primary else 70.0))
	draw_string(font, panel.position + Vector2(14, 28), "P%d  %s" % [int(state_data.slot_index) + 1, state_data.name], HORIZONTAL_ALIGNMENT_LEFT, name_width, 16 if not full_size else 20, color.lightened(0.3))
	if full_size:
		draw_string(font, panel.position + Vector2(293, 28), "%08d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	elif compact_primary:
		draw_string(font, panel.position + Vector2(142, 28), "%08d" % score, HORIZONTAL_ALIGNMENT_RIGHT, 95, 13, Color.WHITE)
	var bar_x := panel.position.x + 14.0
	var bar_y := panel.position.y + (41.0 if full_size else 38.0)
	var bar_width := panel.size.x - (78.0 if full_size else 52.0)
	draw_rect(Rect2(bar_x, bar_y, bar_width, 18 if full_size else 13), Color("#271b25"))
	var health_color := Color(1.0, 0.18 + danger_pulse * 0.12, 0.12, 1.0) if health_ratio < 0.3 else color.lightened(0.12)
	if down:
		health_color = Color("#8a3030")
	draw_rect(Rect2(bar_x + 3, bar_y + 3, (bar_width - 6) * health_ratio, 12 if full_size else 7), health_color)
	draw_string(font, panel.position + Vector2(panel.size.x - 48, panel.size.y - 17), "×%d" % int(state_data.lives), HORIZONTAL_ALIGNMENT_LEFT, -1, 15 if not full_size else 18, Color("#b7e8df"))
	if down:
		var down_time: float = float(state_data.get("down_time", -1.0))
		var down_label := "OUT" if is_equal_approx(down_time, -2.0) else ("DOWN %.1f" % down_time if down_time >= 0.0 else "DOWN")
		draw_string(font, panel.position + Vector2(panel.size.x - 92, 28), down_label, HORIZONTAL_ALIGNMENT_RIGHT, 80, 13, Color("#ff7568"))
	elif not String(state_data.weapon_name).is_empty() and int(state_data.weapon_ammo) > 0:
		draw_string(font, panel.position + Vector2(panel.size.x - 82, 28), "%s %02d" % [state_data.weapon_name, int(state_data.weapon_ammo)], HORIZONTAL_ALIGNMENT_RIGHT, 70, 11, Color("#b7e8df"))


func _hero_card_selected(hero_index: int) -> bool:
	if local_player_selections.is_empty():
		return hero_index == selected_hero_index
	for selection in local_player_selections:
		if int(selection.hero_index) == hero_index:
			return true
	return false


func _draw_hero_card(hero: Resource, index: int, selected: bool) -> void:
	var card_width := 280.0
	var gap := 24.0
	var total_width := card_width * 4.0 + gap * 3.0
	var card_x := (size.x - total_width) * 0.5 + index * (card_width + gap)
	var card_rect := Rect2(card_x, 138, card_width, 470)
	var edge_color: Color = hero.accent_color if selected else Color(0.24, 0.31, 0.34, 0.82)
	draw_rect(card_rect, Color(0.035, 0.055, 0.075, 0.98))
	draw_rect(Rect2(card_rect.position, Vector2(card_width, 7 if selected else 3)), edge_color)
	if selected:
		draw_rect(card_rect.grow(4), Color(edge_color, 0.18), false, 4.0)
	var source_cell := Vector2(
		hero.sprite_sheet.get_width() / float(hero.sprite_columns),
		hero.sprite_sheet.get_height() / float(hero.sprite_rows)
	)
	draw_texture_rect_region(
		hero.sprite_sheet,
		Rect2(card_x + 50, 156, 180, 180),
		Rect2(Vector2.ZERO, source_cell)
	)
	draw_rect(Rect2(card_x + 38, 346, card_width - 76, 3), hero.accent_color)
	draw_string(font, Vector2(card_x, 385), hero.display_name, HORIZONTAL_ALIGNMENT_CENTER, card_width, 28, Color.WHITE)
	draw_string(font, Vector2(card_x + 10, 415), hero.role_title, HORIZONTAL_ALIGNMENT_CENTER, card_width - 20, 15, hero.accent_color.lightened(0.25))
	_draw_hero_stat(card_x + 32, 452, "VIT", float(hero.max_health) / 150.0, hero.primary_color)
	_draw_hero_stat(card_x + 32, 482, "SPD", hero.move_speed / 290.0, hero.primary_color)
	_draw_hero_stat(card_x + 32, 512, "PWR", hero.damage_scale / 1.3, hero.primary_color)
	_draw_hero_stat(card_x + 32, 542, "TECH", hero.item_efficiency / 1.5, hero.primary_color)
	if selected:
		var badges: Array[String] = []
		for selection in local_player_selections:
			if int(selection.hero_index) == index:
				badges.append("P%d %s" % [int(selection.slot_index) + 1, "READY" if bool(selection.ready) else "SELECTING"])
		if badges.is_empty():
			badges.append("P1 SELECTING")
		draw_string(font, Vector2(card_x + 8, 590), "  •  ".join(PackedStringArray(badges)), HORIZONTAL_ALIGNMENT_CENTER, card_width - 16, 15, hero.accent_color.lightened(0.25))


func _draw_hero_stat(x: float, y: float, label: String, value: float, color: Color) -> void:
	draw_string(font, Vector2(x, y), label, HORIZONTAL_ALIGNMENT_LEFT, 48, 13, Color("#b7c8c3"))
	draw_rect(Rect2(x + 52, y - 11, 160, 10), Color(0.09, 0.12, 0.14, 1.0))
	draw_rect(Rect2(x + 52, y - 11, 160 * clampf(value, 0.0, 1.0), 10), color.lightened(0.18))


func _draw_hero_animation_preview() -> void:
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.008, 0.014, 0.025, 1.0))
	if animation_preview_hero == null:
		return
	var hero := animation_preview_hero
	draw_string(font, Vector2(0, 54), "%s // 24-FRAME ACTION GRID" % hero.display_name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, hero.accent_color)
	var source_cell := Vector2(
		hero.sprite_sheet.get_width() / float(hero.sprite_columns),
		hero.sprite_sheet.get_height() / float(hero.sprite_rows)
	)
	var tile_size := Vector2(188, 138)
	var gap := Vector2(12, 9)
	var start := Vector2(46, 104)
	for row in range(hero.sprite_rows):
		for column in range(hero.sprite_columns):
			var tile_pos := start + Vector2(column * (tile_size.x + gap.x), row * (tile_size.y + gap.y))
			draw_rect(Rect2(tile_pos, tile_size), Color(0.035, 0.055, 0.075, 0.98))
			draw_rect(Rect2(tile_pos, Vector2(tile_size.x, 2)), Color(hero.primary_color, 0.7))
			draw_texture_rect_region(
				hero.sprite_sheet,
				Rect2(tile_pos + Vector2(30, 5), Vector2(128, 128)),
				Rect2(Vector2(column, row) * source_cell, source_cell)
			)
	draw_string(font, Vector2(0, 710), "IDLE / MOVE / COMBAT / AIR / DAMAGE / WEAPON / VICTORY", HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Color("#b7c8c3"))
