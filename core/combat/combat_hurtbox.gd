class_name CombatHurtbox
extends Node2D

var actor: Node
var combat_team: StringName
var combat_owner_id := -1
var half_extents := Vector2(18.0, 18.0)
var radius := 18.0
var enabled := true
var debug_visible := false


func setup(p_actor: Node, p_half_extents: Vector2 = Vector2(18.0, 18.0)) -> void:
	actor = p_actor
	combat_team = p_actor.combat_team if "combat_team" in p_actor else &""
	combat_owner_id = p_actor.combat_owner_id if "combat_owner_id" in p_actor else int(p_actor.get_instance_id())
	half_extents = p_half_extents
	radius = minf(half_extents.x, half_extents.y)
	debug_visible = bool(ProjectSettings.get_setting("debug/combat/show_hitboxes", false))
	queue_redraw()


func set_debug_visible(visible: bool) -> void:
	debug_visible = visible
	queue_redraw()


func _draw() -> void:
	if not debug_visible:
		return
	var rect := Rect2(-half_extents, half_extents * 2.0)
	draw_rect(rect, Color(0.16, 0.78, 1.0, 0.16), true)
	draw_rect(rect, Color(0.16, 0.78, 1.0, 0.9), false, 2.0)
