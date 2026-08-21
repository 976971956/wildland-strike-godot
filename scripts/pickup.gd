class_name ArcadePickup
extends Node2D

var kind := "food"
var game
var life := 18.0
var phase := 0.0

func setup(p_game, p_kind: String) -> void:
	game = p_game
	kind = p_kind
	add_to_group("pickups")
	z_index = int(position.y) + 1

func _process(delta: float) -> void:
	life -= delta
	phase += delta * 4.0
	if is_instance_valid(game.player) and position.distance_to(game.player.position) < 42.0:
		if kind == "food":
			game.player.heal(28)
		else:
			game.player.give_weapon()
		game.add_score(400)
		queue_free()
		return
	if life <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var bob := sin(phase) * 3.0
	_draw_oval(Vector2(0,4), 20, 6, Color(0.02,0.03,0.04,0.35))
	if kind == "food":
		draw_circle(Vector2(0,-14+bob), 13, Color("#d8463f"))
		draw_circle(Vector2(-4,-18+bob), 6, Color("#f27a51"))
		draw_line(Vector2(2,-27+bob),Vector2(8,-34+bob),Color("#45291f"),4)
		draw_colored_polygon(PackedVector2Array([Vector2(7,-33+bob),Vector2(17,-35+bob),Vector2(10,-27+bob)]),Color("#55a34d"))
	else:
		draw_line(Vector2(-21,-5+bob),Vector2(20,-27+bob),Color("#d8e1dc"),8)
		draw_line(Vector2(13,-28+bob),Vector2(26,-37+bob),Color("#7f3e2d"),6)
		draw_circle(Vector2(-21,-5+bob),5,Color("#fff0a1"))

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	draw_colored_polygon(pts, color)
