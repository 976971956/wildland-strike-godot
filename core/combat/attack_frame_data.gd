class_name AttackFrameData
extends Resource

enum HitboxShape {
	NONE,
	BOX,
	CIRCLE,
}

@export_group("Identity")
@export var attack_id: StringName
@export var sound_event: StringName

@export_group("Timing")
@export_range(0.0, 5.0, 0.001) var duration := 0.0
@export_range(0.0, 5.0, 0.001) var hit_trigger_remaining := 0.0
@export_range(0.0, 5.0, 0.001) var combo_window := 0.0

@export_group("Motion")
@export var lunge_speed := 0.0

@export_group("Hitbox")
@export var hitbox_shape := HitboxShape.NONE
@export var box_center := Vector2.ZERO
@export var box_half_extents := Vector2.ZERO
@export var circle_radius := 0.0
@export var weapon_box_center := Vector2.ZERO
@export var weapon_box_half_extents := Vector2.ZERO

@export_group("Outcome")
@export var damage := 0
@export var weapon_bonus_damage := 0
@export var knockback := Vector2.ZERO
@export var launch := false
@export_range(0, 3, 1) var impact_strength := 1
@export_range(0, 3, 1) var weapon_impact_strength := 0
@export var can_grab := false
@export var grab_range := 0.0

@export_group("Area Effect")
@export var effect_radius := 0.0
@export var radial_horizontal_scale := 0.0
@export var self_damage := 0
@export var invulnerable_duration := 0.0
@export var hit_stop_duration := 0.0


func is_valid_frame_data() -> bool:
	if attack_id.is_empty() or duration <= 0.0:
		return false
	if hit_trigger_remaining < 0.0 or hit_trigger_remaining > duration:
		return false
	if hitbox_shape == HitboxShape.BOX:
		return box_half_extents.x > 0.0 and box_half_extents.y > 0.0
	if hitbox_shape == HitboxShape.CIRCLE:
		return circle_radius > 0.0
	return true


func box_geometry(weapon_active: bool) -> Array[Vector2]:
	if weapon_active and weapon_box_half_extents != Vector2.ZERO:
		return [weapon_box_center, weapon_box_half_extents]
	return [box_center, box_half_extents]
