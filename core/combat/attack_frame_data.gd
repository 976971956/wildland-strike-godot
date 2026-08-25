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
@export var vertical_velocity_override := 0.0

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
@export var impact_profile: Resource
@export_range(1, 4, 1) var priority := 1
@export_range(1, 8, 1) var max_hits := 1
@export_range(0.0, 1.0, 0.001) var repeat_hit_interval := 0.0
@export var can_grab := false
@export var grab_range := 0.0
@export var throw_collision_damage := 0
@export_range(0.0, 1.0, 0.001) var hit_stun_bonus := 0.0

@export_group("Counter Hit")
@export var counter_hit_damage_bonus := 0
@export_range(1.0, 3.0, 0.01) var counter_hit_knockback_scale := 1.0
@export var counter_hit_launch := false
@export_range(0.0, 1.0, 0.001) var counter_hit_stun_bonus := 0.0

@export_group("Area Effect")
@export var effect_radius := 0.0
@export var radial_horizontal_scale := 0.0
@export var self_damage := 0
@export var invulnerable_duration := 0.0


func is_valid_frame_data() -> bool:
	if attack_id.is_empty() or duration <= 0.0:
		return false
	if hit_trigger_remaining < 0.0 or hit_trigger_remaining > duration:
		return false
	if counter_hit_damage_bonus < 0 or counter_hit_knockback_scale < 1.0 or counter_hit_stun_bonus < 0.0:
		return false
	if priority < 1 or priority > 4 or max_hits < 1:
		return false
	if max_hits > 1 and (repeat_hit_interval <= 0.0 or repeat_hit_interval >= duration):
		return false
	if throw_collision_damage < 0 or hit_stun_bonus < 0.0:
		return false
	if impact_profile == null or not impact_profile.is_valid_profile():
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
