class_name ArcadePickup
extends Node2D

const WeaponDefinitionScript = preload("res://core/weapons/weapon_definition.gd")
const WeaponCatalogScript = preload("res://core/weapons/weapon_catalog.gd")
const PickupDefinitionScript = preload("res://core/items/pickup_definition.gd")
const PickupCatalogScript = preload("res://core/items/pickup_catalog.gd")
const ArcadeFont = preload("res://assets/fonts/NotoSansSC-Variable.ttf")

var kind := "food"
var game
var life := 18.0
var phase := 0.0
var weapon_definition: Resource
var item_definition: Resource

func setup(p_game, p_kind: String) -> void:
	game = p_game
	kind = p_kind
	item_definition = PickupCatalogScript.from_pickup_id(kind)
	weapon_definition = null if item_definition != null else WeaponCatalogScript.from_pickup_id(kind)
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
		collect(collector)
		return
	if life <= 0.0:
		queue_free()
	queue_redraw()


func collect(collector: Node) -> bool:
	if not is_instance_valid(collector) or collector.is_defeated:
		return false
	if item_definition != null:
		if item_definition.kind == PickupDefinitionScript.PickupKind.FOOD:
			collector.heal(item_definition.heal_amount)
		game.add_score(item_definition.score_value)
	else:
		collector.give_weapon(kind)
		game.add_score(400)
	queue_free()
	return true

func _draw() -> void:
	var bob := sin(phase) * 3.0
	_draw_oval(Vector2(0,4), 20, 6, Color(0.02,0.03,0.04,0.35))
	if item_definition != null:
		_draw_item_pickup(bob)
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
	draw_string(ArcadeFont, label_rect.position, game.localized_content(weapon_definition.display_name), HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 12, Color("#fff0bd"))


func _draw_item_pickup(bob: float) -> void:
	var icon_position := Vector2(0.0, -16.0 + bob)
	var icon_size: float = item_definition.icon_size
	if item_definition.kind == PickupDefinitionScript.PickupKind.FOOD:
		draw_circle(icon_position, icon_size, item_definition.color)
		draw_circle(icon_position + Vector2(-icon_size * 0.28, -icon_size * 0.24), icon_size * 0.44, item_definition.color.lightened(0.25))
		draw_line(icon_position + Vector2(2.0, -icon_size), icon_position + Vector2(8.0, -icon_size - 8.0), Color("#45291f"), 4.0)
		draw_colored_polygon(PackedVector2Array([icon_position + Vector2(7.0, -icon_size - 7.0), icon_position + Vector2(17.0, -icon_size - 9.0), icon_position + Vector2(10.0, -icon_size + 1.0)]), Color("#55a34d"))
	else:
		var points := PackedVector2Array()
		for index in range(8):
			var radius := icon_size if index % 2 == 0 else icon_size * 0.52
			var angle := -PI * 0.5 + TAU * index / 8.0
			points.append(icon_position + Vector2(cos(angle), sin(angle)) * radius)
		draw_colored_polygon(points, item_definition.color)
		draw_circle(icon_position, icon_size * 0.3, item_definition.color.lightened(0.35))
	var label_rect := Rect2(-62.0, 5.0 + bob, 124.0, 20.0)
	draw_string(ArcadeFont, label_rect.position, game.localized_content(item_definition.display_name), HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 12, Color("#fff0bd"))
