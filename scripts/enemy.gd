class_name StreetEnemy
extends CharacterBody2D

const SPRITE_SHEET: Texture2D = preload("res://assets/sprites/enemy_sheet.png")
const RAPTOR_SHEET: Texture2D = preload("res://assets/sprites/raptor_sheet.png")

var game: Node
var player: Node
var enemy_type := "grunt"
var max_health := 42
var health := 42
var damage := 8
var speed := 115.0
var facing := -1
var attack_timer := 0.0
var hurt_timer := 0.0
var stun_timer := 0.0
var invulnerable := 0.0
var attack_hit_done := false
var is_defeated := false
var grabbed := false
var grabbed_owner: Node = null
var fall_velocity := Vector2.ZERO
var death_timer := 0.0
var walk_phase := 0.0
var tint := Color("#a84a55")

func setup(p_game: Node, p_player: Node, p_type: String) -> void:
	game = p_game
	player = p_player
	enemy_type = p_type
	add_to_group("enemies")
	if p_type == "brute":
		max_health = 78
		health = 78
		damage = 13
		speed = 82.0
		tint = Color("#8359a3")
	elif p_type == "boss":
		max_health = 260
		health = 260
		damage = 18
		speed = 105.0
		tint = Color("#bc5337")
		scale = Vector2(1.25, 1.25)
	elif p_type == "raptor":
		max_health = 58
		health = 58
		damage = 11
		speed = 152.0
		tint = Color("#6d9140")
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 17.0
	capsule.height = 46.0
	shape.shape = capsule
	shape.position.y = -22
	add_child(shape)

func _physics_process(delta: float) -> void:
	z_index = int(position.y)
	if is_defeated:
		death_timer -= delta
		position += fall_velocity * delta
		fall_velocity = fall_velocity.move_toward(Vector2.ZERO, 330.0 * delta)
		modulate.a = clampf(death_timer * 2.0, 0.0, 1.0)
		if death_timer <= 0.0:
			game.enemy_removed(self)
			queue_free()
		queue_redraw()
		return
	if grabbed:
		if not is_instance_valid(grabbed_owner):
			release_grab()
		else:
			position = grabbed_owner.position + Vector2(grabbed_owner.facing * 31.0, 1.0)
			facing = -grabbed_owner.facing
			queue_redraw()
			return
	attack_timer = maxf(0.0, attack_timer - delta)
	hurt_timer = maxf(0.0, hurt_timer - delta)
	stun_timer = maxf(0.0, stun_timer - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	if hurt_timer > 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 420.0 * delta)
	elif stun_timer > 0.0:
		velocity = Vector2.ZERO
	elif is_instance_valid(player) and not player.is_defeated:
		_think(delta)
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	position.y = clampf(position.y, 455.0, 665.0)
	position.x = clampf(position.x, 60.0, game.stage_limit + 80.0)
	walk_phase += velocity.length() * delta * 0.025
	_check_attack()
	queue_redraw()

func _think(_delta: float) -> void:
	var offset: Vector2 = player.position - position
	facing = 1 if offset.x > 0 else -1
	var y_dist := absf(offset.y)
	var x_dist := absf(offset.x)
	if attack_timer > 0.0:
		velocity = Vector2.ZERO
		return
	if x_dist < 62.0 and y_dist < 36.0:
		attack_timer = 0.72 if enemy_type != "boss" else 0.52
		attack_hit_done = false
		velocity = Vector2.ZERO
		game.play_sfx("enemy_swing")
		return
	var target := Vector2.ZERO
	if x_dist > 48.0:
		target.x = signf(offset.x)
	if y_dist > 18.0:
		target.y = signf(offset.y) * 0.72
	velocity = target.normalized() * speed

func _check_attack() -> void:
	if attack_timer <= 0.0 or attack_hit_done or not is_instance_valid(player):
		return
	var hit_time := 0.36 if enemy_type != "boss" else 0.27
	if attack_timer < hit_time:
		attack_hit_done = true
		if position.distance_to(player.position) < (76.0 if enemy_type == "boss" else 65.0):
			player.take_hit(damage, Vector2(facing * 240.0, 0))

func take_hit(amount: int, knockback: Vector2, launch: bool) -> void:
	if is_defeated or invulnerable > 0.0:
		return
	health -= amount
	hurt_timer = 0.25 if not launch else 0.46
	stun_timer = hurt_timer
	velocity = knockback
	invulnerable = 0.08
	if launch:
		velocity = knockback
	if enemy_type == "boss":
		game.boss_health_changed(health, max_health)
	if health <= 0:
		_die(knockback)
	queue_redraw()

func _die(knockback: Vector2) -> void:
	is_defeated = true
	grabbed = false
	remove_from_group("enemies")
	death_timer = 0.75
	fall_velocity = knockback * 0.72
	var defeat_score := 2000 if enemy_type == "boss" else (650 if enemy_type == "raptor" else (500 if enemy_type == "brute" else 250))
	game.add_score(defeat_score)
	game.play_sfx("enemy_down")

func can_be_grabbed() -> bool:
	return enemy_type not in ["boss", "raptor"] and not grabbed and hurt_timer <= 0.0

func grabbed_by(owner: Node) -> void:
	grabbed = true
	grabbed_owner = owner
	velocity = Vector2.ZERO
	stun_timer = 2.0

func release_grab() -> void:
	grabbed = false
	grabbed_owner = null
	stun_timer = 0.25

func thrown(force: Vector2) -> void:
	release_grab()
	take_hit(22, force, true)

func _draw() -> void:
	if enemy_type == "raptor":
		_draw_raptor()
		return
	var body_scale := 1.12 if enemy_type == "brute" else 1.0
	_draw_oval(Vector2(0,2), 34.0 * body_scale, 9.0, Color(0.02,0.03,0.04,0.42))
	var row := 0 if enemy_type == "grunt" else (1 if enemy_type == "brute" else 2)
	var column := 0
	if is_defeated or hurt_timer > 0.0:
		column = 3
	elif attack_timer > 0.0:
		column = 2
	elif velocity.length() > 10.0:
		column = 1 if int(walk_phase) % 2 == 0 else 0
	var cell := Vector2(SPRITE_SHEET.get_width() / 4.0, SPRITE_SHEET.get_height() / 3.0)
	var target_size := Vector2(174.0, 174.0) * body_scale
	var target_rect := Rect2(-target_size.x * 0.5, -target_size.y + 14.0, target_size.x, target_size.y)
	var source_rect := Rect2(column * cell.x, row * cell.y, cell.x, cell.y)
	var tint_color := Color(1.0, 0.72, 0.66) if hurt_timer > 0.0 else Color.WHITE
	# Enemy source art faces left, opposite to the player sheet.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-facing, 1.0))
	draw_texture_rect_region(SPRITE_SHEET, target_rect, source_rect, tint_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if enemy_type == "brute" and health > 0:
		draw_rect(Rect2(-31,-170,62,6), Color("#351f28"))
		draw_rect(Rect2(-31,-170,62.0*health/max_health,6), Color("#f06454"))

func _draw_raptor() -> void:
	_draw_oval(Vector2(0, 2), 49.0, 11.0, Color(0.02,0.03,0.04,0.44))
	var column := 0
	if is_defeated or hurt_timer > 0.0:
		column = 3
	elif attack_timer > 0.0:
		column = 2
	elif velocity.length() > 10.0:
		column = 1 if int(walk_phase) % 2 == 0 else 0
	var cell := Vector2(RAPTOR_SHEET.get_width() / 4.0, RAPTOR_SHEET.get_height())
	var source_rect := Rect2(column * cell.x, 0.0, cell.x, cell.y)
	var target_size := Vector2(222.0, 322.0)
	var target_rect := Rect2(-target_size.x * 0.5, -target_size.y + 32.0, target_size.x, target_size.y)
	var tint_color := Color(1.0, 0.66, 0.58) if hurt_timer > 0.0 else Color.WHITE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-facing, 1.0))
	draw_texture_rect_region(RAPTOR_SHEET, target_rect, source_rect, tint_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	draw_colored_polygon(pts, color)
