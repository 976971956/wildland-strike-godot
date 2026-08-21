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
var stage_area := 1
var stage_area_total := 1
var stage_hostiles := 0
var arena_locked := false
var force_touch_layout := false
var font: Font

func _ready() -> void:
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
	queue_redraw()

func set_score(value: int) -> void:
	score = value
	queue_redraw()

func set_lives(value: int) -> void:
	lives = value
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


func set_stage_time(seconds: float) -> void:
	stage_time_remaining = maxf(0.0, seconds)
	queue_redraw()


func set_weapon(display_name: String, ammo: int) -> void:
	weapon_name = display_name
	weapon_ammo = maxi(ammo, 0)
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
	return Rect2(260, 398, 680, 96) if touch_layout else Rect2(270, 540, 740, 92)


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

func _draw() -> void:
	# Arcade HUD panel.
	draw_rect(Rect2(22,20,430,82), Color(0.035,0.045,0.07,0.88))
	draw_rect(Rect2(22,20,430,5), Color("#efbf4d"))
	draw_string(font, Vector2(39,48), "RANGER  1", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f5dc7c"))
	draw_string(font, Vector2(315,48), "%08d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_rect(Rect2(39,61,360,23), Color("#271b25"))
	var ratio := clampf(float(health)/maxf(max_health,1),0.0,1.0)
	var danger_pulse := 0.72 + sin(Time.get_ticks_msec() * 0.012) * 0.28
	var health_color := Color(1.0, 0.18 + danger_pulse * 0.12, 0.12, 1.0) if ratio < 0.3 else Color("#e8b844")
	draw_rect(Rect2(43,65,352*ratio,15), health_color)
	for x in range(43,396,22):
		draw_line(Vector2(x,65),Vector2(x,80),Color(0,0,0,0.18),2)
	draw_string(font,Vector2(406,82),"×%d"%lives,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#b7e8df"))
	if mode == "playing":
		var total_seconds := ceili(stage_time_remaining)
		var minutes := int(total_seconds / 60)
		var seconds := total_seconds % 60
		var timer_color := Color("#ef5b50") if total_seconds <= 30 else Color("#f4dc83")
		draw_rect(Rect2(578, 20, 124, 48), Color(0.035, 0.045, 0.07, 0.88))
		draw_rect(Rect2(578, 20, 124, 4), timer_color)
		draw_string(font, Vector2(578, 54), "%02d:%02d" % [minutes, seconds], HORIZONTAL_ALIGNMENT_CENTER, 124, 24, timer_color)
		if not weapon_name.is_empty() and weapon_ammo > 0:
			draw_rect(Rect2(474, 20, 92, 48), Color(0.035, 0.045, 0.07, 0.88))
			draw_rect(Rect2(474, 20, 92, 4), Color("#74c9aa"))
			draw_string(font, Vector2(478, 42), weapon_name, HORIZONTAL_ALIGNMENT_CENTER, 84, 13, Color("#d8efe7"))
			draw_string(font, Vector2(478, 61), "×%02d" % weapon_ammo, HORIZONTAL_ALIGNMENT_CENTER, 84, 16, Color.WHITE)
		if boss_max <= 0 or boss_health <= 0:
			var status_color := Color("#ef6a56") if arena_locked else Color("#70d0ad")
			draw_rect(Rect2(882, 20, 362, 64), Color(0.035, 0.045, 0.07, 0.9))
			draw_rect(Rect2(882, 20, 362, 4), status_color)
			draw_string(font, Vector2(900, 48), "AREA %d/%d" % [stage_area, stage_area_total], HORIZONTAL_ALIGNMENT_LEFT, 150, 19, Color("#f4dc83"))
			var objective := "HOSTILES  %02d" % stage_hostiles if arena_locked else "ADVANCE  →"
			draw_string(font, Vector2(1045, 48), objective, HORIZONTAL_ALIGNMENT_RIGHT, 180, 19, status_color)
			draw_string(font, Vector2(900, 72), "COMBAT ZONE LOCKED" if arena_locked else "ROUTE OPEN", HORIZONTAL_ALIGNMENT_LEFT, 325, 13, Color("#b8c8c3"))
		if ratio < 0.3:
			draw_string(font, Vector2(350, 99), "DANGER", HORIZONTAL_ALIGNMENT_RIGHT, 48, 13, Color(1.0, 0.32, 0.24, danger_pulse))

	# Keyboard hints are hidden on touch devices where virtual controls replace them.
	if not _touch_layout_active():
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
		var dialogue_rect := dialogue_panel_rect(_touch_layout_active())
		draw_rect(dialogue_rect, Color(0.025, 0.018, 0.025, 0.94))
		draw_rect(Rect2(dialogue_rect.position, Vector2(7, dialogue_rect.size.y)), Color("#d84a35"))
		var dialogue_text_width := dialogue_rect.size.x - 48.0
		draw_string(font, dialogue_rect.position + Vector2(24, 30), dialogue_speaker, HORIZONTAL_ALIGNMENT_LEFT, dialogue_text_width, 18, Color("#f0b65b"))
		draw_string(font, dialogue_rect.position + Vector2(24, 67), dialogue_line, HORIZONTAL_ALIGNMENT_LEFT, dialogue_text_width, 24, Color.WHITE)

	if mode == "title":
		draw_rect(Rect2(0,0,size.x,size.y),Color(0.01,0.02,0.035,0.58))
		draw_string(font,Vector2(0,210),"WILDLAND STRIKE",HORIZONTAL_ALIGNMENT_CENTER,size.x,68,Color("#f1c14f"))
		draw_string(font,Vector2(0,258),"ARCADE SURVIVAL",HORIZONTAL_ALIGNMENT_CENTER,size.x,27,Color("#d0eee3"))
		draw_rect(Rect2(size.x/2-210,330,420,64),Color(0.03,0.05,0.07,0.9))
		draw_rect(Rect2(size.x/2-210,330,420,4),Color("#e55045"))
		draw_string(font,Vector2(size.x/2-210,371),"TAP / ENTER TO START",HORIZONTAL_ALIGNMENT_CENTER,420,24,Color.WHITE)
		draw_string(font,Vector2(0,445),"AN ORIGINAL ARCADE TRIBUTE",HORIZONTAL_ALIGNMENT_CENTER,size.x,18,Color("#b9c7c2"))
	elif mode == "victory":
		draw_rect(Rect2(0,0,size.x,size.y),Color(0.01,0.02,0.03,0.63))
		draw_rect(Rect2(318, 142, 644, 438), Color(0.025, 0.035, 0.05, 0.94))
		draw_rect(Rect2(318, 142, 644, 6), Color("#f2c756"))
		draw_string(font, Vector2(318, 222), "STAGE 1 CLEAR", HORIZONTAL_ALIGNMENT_CENTER, 644, 50, Color("#f2c756"))
		draw_string(font, Vector2(318, 258), "THE PROCESSING PLANT IS SECURE", HORIZONTAL_ALIGNMENT_CENTER, 644, 18, Color("#d6dfdb"))
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
			draw_string(font, Vector2(318, 538), "TAP / ENTER TO RESTART", HORIZONTAL_ALIGNMENT_CENTER, 644, 20, Color("#d6dfdb"))
	elif mode == "gameover":
		draw_rect(Rect2(0,0,size.x,size.y),Color(0.01,0.02,0.03,0.63))
		draw_string(font,Vector2(0,278),"GAME OVER",HORIZONTAL_ALIGNMENT_CENTER,size.x,54,Color("#ed5a4c"))
		draw_string(font,Vector2(0,338),"FINAL SCORE  %08d"%score,HORIZONTAL_ALIGNMENT_CENTER,size.x,25,Color.WHITE)
		draw_string(font,Vector2(0,402),"TAP / ENTER TO RESTART",HORIZONTAL_ALIGNMENT_CENTER,size.x,20,Color("#d6dfdb"))
