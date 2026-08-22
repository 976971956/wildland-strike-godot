class_name ArcadePickup
extends Node2D

const WeaponCatalogScript = preload("res://core/weapons/weapon_catalog.gd")
const PickupDefinitionScript = preload("res://core/items/pickup_definition.gd")
const PickupCatalogScript = preload("res://core/items/pickup_catalog.gd")
const ArcadeFont = preload("res://assets/fonts/NotoSansSC-Variable.ttf")
const ITEM_PICKUP_ATLAS = preload("res://assets/sprites/item_pickups_atlas.png")
const WEAPON_PICKUP_ATLAS = preload("res://assets/sprites/weapon_pickups_atlas.png")
const PICKUP_CELL_SIZE := Vector2(160.0, 160.0)
const PICKUP_ATLAS_COLUMNS := 4
const ITEM_ATLAS_INDEX := {
	"food": 1,
	"food_snack": 0,
	"food_ration": 1,
	"food_meal": 2,
	"food_feast": 3,
	"score_token": 4,
	"score_badge": 5,
	"score_relic": 6,
	"score_intel": 7,
}
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
	_draw_oval(Vector2(0, 5), 28, 7, Color(0.02, 0.03, 0.04, 0.42))
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
	var index := weapon_atlas_index(kind)
	_draw_pickup_atlas(WEAPON_PICKUP_ATLAS, index, Vector2(112.0, 112.0), bob)
	var label_rect := Rect2(-70.0, 14.0 + bob, 140.0, 20.0)
	draw_string(ArcadeFont, label_rect.position, game.localized_content(weapon_definition.display_name), HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 12, Color("#fff0bd"))


func _draw_item_pickup(bob: float) -> void:
	var index := item_atlas_index(kind)
	_draw_pickup_atlas(ITEM_PICKUP_ATLAS, index, Vector2(100.0, 100.0), bob)
	var label_rect := Rect2(-70.0, 14.0 + bob, 140.0, 20.0)
	draw_string(ArcadeFont, label_rect.position, game.localized_content(item_definition.display_name), HORIZONTAL_ALIGNMENT_CENTER, label_rect.size.x, 12, Color("#fff0bd"))


func _draw_pickup_atlas(atlas: Texture2D, index: int, destination_size: Vector2, bob: float) -> void:
	if index < 0:
		return
	var source_position := Vector2(index % PICKUP_ATLAS_COLUMNS, index / PICKUP_ATLAS_COLUMNS) * PICKUP_CELL_SIZE
	var destination := Rect2(
		Vector2(-destination_size.x * 0.5, -destination_size.y + 10.0 + bob),
		destination_size
	)
	draw_texture_rect_region(atlas, destination, Rect2(source_position, PICKUP_CELL_SIZE))


static func item_atlas_index(pickup_id: String) -> int:
	return ITEM_ATLAS_INDEX.get(pickup_id, -1)


static func weapon_atlas_index(pickup_id: String) -> int:
	return WeaponCatalogScript.atlas_index_for_pickup_id(pickup_id)
