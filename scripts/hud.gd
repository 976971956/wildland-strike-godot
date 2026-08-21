extends Control

var health := 120
var max_health := 120
var score := 0
var lives := 2
var boss_health := 0
var boss_max := 0
var banner := ""
var banner_sub := ""
var banner_time := 0.0
var mode := "title"
var stage_time_remaining := 0.0
var weapon_name := ""
var weapon_ammo := 0
var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	if banner_time > 0.0:
		banner_time -= delta
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

func _draw() -> void:
	# Arcade HUD panel.
	draw_rect(Rect2(22,20,430,82), Color(0.035,0.045,0.07,0.88))
	draw_rect(Rect2(22,20,430,5), Color("#efbf4d"))
	draw_string(font, Vector2(39,48), "RANGER  1", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f5dc7c"))
	draw_string(font, Vector2(315,48), "%08d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
	draw_rect(Rect2(39,61,360,23), Color("#271b25"))
	var ratio := clampf(float(health)/maxf(max_health,1),0.0,1.0)
	draw_rect(Rect2(43,65,352*ratio,15), Color("#e84d45") if ratio < 0.3 else Color("#e8b844"))
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

	# Keyboard hints are hidden on touch devices where virtual controls replace them.
	if not DisplayServer.is_touchscreen_available() and "--touch-preview" not in OS.get_cmdline_user_args():
		draw_rect(Rect2(22,674,715,30),Color(0.02,0.03,0.045,0.72))
		draw_string(font,Vector2(35,696),"MOVE WASD/ARROWS   ATTACK J/Z   JUMP K/X   COMMAND DOWN>FORWARD+ATTACK   SPECIAL ATTACK+JUMP",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#dbe4df"))

	if boss_max > 0 and boss_health > 0 and mode == "playing":
		draw_rect(Rect2(778,34,466,49),Color(0.04,0.025,0.04,0.9))
		draw_string(font,Vector2(798,56),"WASTELAND LORD",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#ffcf5e"))
		draw_rect(Rect2(798,63,424,10),Color("#3b1d27"))
		draw_rect(Rect2(798,63,424.0*boss_health/boss_max,10),Color("#e94845"))

	if banner_time > 0.0 and mode == "playing":
		draw_rect(Rect2(350,260,580,110),Color(0.025,0.035,0.05,0.82))
		draw_rect(Rect2(350,260,580,4),Color("#efbf4d"))
		draw_string(font,Vector2(350,310),banner,HORIZONTAL_ALIGNMENT_CENTER,580,34,Color("#ffe17c"))
		draw_string(font,Vector2(350,344),banner_sub,HORIZONTAL_ALIGNMENT_CENTER,580,18,Color("#d5e0db"))

	if mode == "title":
		draw_rect(Rect2(0,0,size.x,size.y),Color(0.01,0.02,0.035,0.58))
		draw_string(font,Vector2(0,210),"WILDLAND STRIKE",HORIZONTAL_ALIGNMENT_CENTER,size.x,68,Color("#f1c14f"))
		draw_string(font,Vector2(0,258),"ARCADE SURVIVAL",HORIZONTAL_ALIGNMENT_CENTER,size.x,27,Color("#d0eee3"))
		draw_rect(Rect2(size.x/2-210,330,420,64),Color(0.03,0.05,0.07,0.9))
		draw_rect(Rect2(size.x/2-210,330,420,4),Color("#e55045"))
		draw_string(font,Vector2(size.x/2-210,371),"TAP / ENTER TO START",HORIZONTAL_ALIGNMENT_CENTER,420,24,Color.WHITE)
		draw_string(font,Vector2(0,445),"AN ORIGINAL ARCADE TRIBUTE",HORIZONTAL_ALIGNMENT_CENTER,size.x,18,Color("#b9c7c2"))
	elif mode == "gameover" or mode == "victory":
		draw_rect(Rect2(0,0,size.x,size.y),Color(0.01,0.02,0.03,0.63))
		var title := "MISSION COMPLETE" if mode == "victory" else "GAME OVER"
		var col := Color("#f2c756") if mode == "victory" else Color("#ed5a4c")
		draw_string(font,Vector2(0,278),title,HORIZONTAL_ALIGNMENT_CENTER,size.x,54,col)
		draw_string(font,Vector2(0,338),"FINAL SCORE  %08d"%score,HORIZONTAL_ALIGNMENT_CENTER,size.x,25,Color.WHITE)
		draw_string(font,Vector2(0,402),"TAP / ENTER TO RESTART",HORIZONTAL_ALIGNMENT_CENTER,size.x,20,Color("#d6dfdb"))
