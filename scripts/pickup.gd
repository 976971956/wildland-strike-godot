class_name ArcadePickup
extends Node2D

const WeaponDefinitionScript = preload("res://core/weapons/weapon_definition.gd")
const WeaponCatalogScript = preload("res://core/weapons/weapon_catalog.gd")

var kind := "food"
var game
var life := 18.0
var phase := 0.0
var weapon_definition: Resource

func setup(p_game, p_kind: String) -> void:
	game = p_game
	kind = p_kind
	weapon_definition = null if kind == "food" else WeaponCatalogScript.from_pickup_id(kind)
	add_to_group("pickups")
	z_index = int(position.y) + 1

func _process(delta: float) -> void:
	life -= delta
	phase += delta * 4.0
	var collector: Node = null
	var collector_distance := INF
	var candidates: Array[Node] = game.get_active_players() if game.has_method("get_active_players") else [game.player]
	for fighter in candidates:
		if not is_instance_valid(fighter) or fighter.is_defeated:
			continue
		var distance := position.distance_to(fighter.position)
		if distance < 42.0 and distance < collector_distance:
			collector = fighter
			collector_distance = distance
	if collector != null:
		if kind == "food":
			collector.heal(28)
		else:
			collector.give_weapon(kind)
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
	elif weapon_definition != null:
		_draw_weapon_pickup(bob)

func _draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * i / 24.0
		pts.append(center + Vector2(cos(a)*rx, sin(a)*ry))
	draw_colored_polygon(pts, color)


func _draw_weapon_pickup(bob: float) -> void:
	var weapon_color: Color = weapon_definition.color
	if weapon_definition.kind == WeaponDefinitionScript.WeaponKind.MELEE:
		var length: float = 42.0 * weapon_definition.melee_reach_scale
		draw_line(Vector2(-length * 0.45, -7.0 + bob), Vector2(length * 0.45, -29.0 + bob), weapon_color.lightened(0.25), 8.0)
		draw_line(Vector2(length * 0.28, -27.0 + bob), Vector2(length * 0.48, -36.0 + bob), weapon_color.darkened(0.35), 6.0)
		if weapon_definition.chain_radius > 0.0:
			draw_arc(Vector2(0.0, -20.0 + bob), 19.0, -PI * 0.9, PI * 0.25, 12, Color("#76efff"), 3.0)
	elif weapon_definition.kind == WeaponDefinitionScript.WeaponKind.FIREARM:
		var barrel: float = 46.0 if weapon_definition.penetration_count > 1 else 38.0
		draw_line(Vector2(-barrel * 0.5, -17.0 + bob), Vector2(barrel * 0.5, -17.0 + bob), weapon_color.lightened(0.28), 10.0)
		draw_line(Vector2(-5.0, -12.0 + bob), Vector2(-10.0, 0.0 + bob), weapon_color.darkened(0.35), 8.0)
		for pellet_index in range(mini(weapon_definition.shots_per_use, 5)):
			draw_circle(Vector2(24.0 + pellet_index * 4.0, -22.0 + bob + pellet_index * 2.5), 2.2, Color("#ffe68a"))
	else:
		if weapon_definition.stationary:
			draw_rect(Rect2(-18.0, -20.0 + bob, 36.0, 13.0), weapon_color)
			draw_circle(Vector2(0.0, -15.0 + bob), 4.0, Color("#ff6a47"))
		elif weapon_definition.detonate_on_contact:
			draw_rect(Rect2(-22.0, -24.0 + bob, 44.0, 12.0), weapon_color)
			draw_colored_polygon(PackedVector2Array([Vector2(-22.0, -26.0 + bob), Vector2(-32.0, -18.0 + bob), Vector2(-22.0, -10.0 + bob)]), Color("#ffb347"))
		else:
			draw_circle(Vector2(0.0, -17.0 + bob), 13.0, weapon_color)
			draw_rect(Rect2(-4.0, -34.0 + bob, 8.0, 8.0), Color("#d5b96d"))
	var label_rect := Rect2(-62.0, 5.0 + bob, 124.0, 20.0)
	draw_string(ThemeDB.fallback_font, label_rect.position, weapon_definition.display_name, HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 12, Color("#fff0bd"))
