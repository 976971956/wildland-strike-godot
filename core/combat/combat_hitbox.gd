class_name CombatHitbox
extends Node2D

enum ShapeKind {
	BOX,
	CIRCLE,
}

var actor: Node
var shape_kind := ShapeKind.BOX
var center_offset := Vector2.ZERO
var half_extents := Vector2.ZERO
var radius := 0.0
var facing := 1
var active := false
var debug_visible := false


func setup(p_actor: Node) -> void:
	actor = p_actor
	debug_visible = bool(ProjectSettings.get_setting("debug/combat/show_hitboxes", false))
	queue_redraw()


func configure_box(p_center_offset: Vector2, p_half_extents: Vector2, p_facing: int) -> void:
	shape_kind = ShapeKind.BOX
	center_offset = p_center_offset
	half_extents = p_half_extents
	facing = 1 if p_facing >= 0 else -1
	active = true
	queue_redraw()


func configure_circle(p_radius: float, p_facing: int) -> void:
	shape_kind = ShapeKind.CIRCLE
	center_offset = Vector2.ZERO
	radius = p_radius
	facing = 1 if p_facing >= 0 else -1
	active = true
	queue_redraw()


func deactivate() -> void:
	active = false
	queue_redraw()


func overlaps(hurtbox) -> bool:
	if not active or hurtbox == null or not hurtbox.enabled:
		return false
	var relative: Vector2 = hurtbox.global_position - global_position
	if shape_kind == ShapeKind.CIRCLE:
		return relative.length() < radius + hurtbox.radius
	var world_center := Vector2(center_offset.x * facing, center_offset.y)
	var distance_from_center: Vector2 = relative - world_center
	return (
		absf(distance_from_center.x) < half_extents.x + hurtbox.half_extents.x
		and absf(distance_from_center.y) < half_extents.y + hurtbox.half_extents.y
	)


func set_debug_visible(visible: bool) -> void:
	debug_visible = visible
	queue_redraw()


func _draw() -> void:
	if not debug_visible or not active:
		return
	var draw_center := Vector2(center_offset.x * facing, center_offset.y)
	if shape_kind == ShapeKind.CIRCLE:
		draw_circle(draw_center, radius, Color(1.0, 0.24, 0.18, 0.15))
		draw_arc(draw_center, radius, 0.0, TAU, 32, Color(1.0, 0.24, 0.18, 0.95), 2.0)
	else:
		var rect := Rect2(draw_center - half_extents, half_extents * 2.0)
		draw_rect(rect, Color(1.0, 0.24, 0.18, 0.15), true)
		draw_rect(rect, Color(1.0, 0.24, 0.18, 0.95), false, 2.0)
