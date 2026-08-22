class_name WeaponDefinition
extends Resource

enum WeaponKind {
	MELEE,
	EXPLOSIVE,
	FIREARM,
}

@export var weapon_id: StringName
@export var display_name := ""
@export var behavior_id: StringName
@export var kind := WeaponKind.MELEE
@export_range(1, 99, 1) var capacity := 1
@export_range(0, 100, 1) var damage := 0
@export_range(0, 100, 1) var melee_bonus_damage := 0
@export_range(0.5, 2.0, 0.05) var melee_reach_scale := 1.0
@export_range(0.5, 2.5, 0.05) var melee_knockback_scale := 1.0
@export_range(0.0, 1.0, 0.05) var melee_stun_bonus := 0.0
@export var melee_force_launch := false
@export_range(0.0, 200.0, 1.0) var chain_radius := 0.0
@export_range(0, 50, 1) var chain_damage := 0
@export var projectile_speed := 0.0
@export_range(0.0, 5.0, 0.05) var projectile_lifetime := 0.0
@export_range(1, 8, 1) var shots_per_use := 1
@export_range(0.0, 160.0, 1.0) var spread_depth := 0.0
@export_range(1, 8, 1) var penetration_count := 1
@export_range(0.0, 600.0, 1.0) var projectile_deceleration := 0.0
@export_range(0.0, 5.0, 0.05) var fuse_duration := 0.0
@export_range(0.0, 300.0, 1.0) var explosion_radius := 0.0
@export var detonate_on_contact := false
@export var stationary := false
@export_range(0.0, 2.0, 0.05) var arm_delay := 0.0
@export_range(0.0, 200.0, 1.0) var trigger_radius := 0.0
@export_range(0.0, 5.0, 0.05) var lingering_duration := 0.0
@export_range(0.05, 2.0, 0.05) var lingering_tick_interval := 0.25
@export_range(0, 50, 1) var lingering_damage := 0
@export var impact_profile: Resource
@export var fire_sfx: StringName
@export var blast_sfx: StringName = &"explosion"
@export var color := Color.WHITE

@export_group("Held Visual")
@export var held_crop := Rect2()
@export var held_grip := Vector2.ZERO
@export_range(0.1, 1.5, 0.01) var held_scale := 0.5
@export_range(-1, 1, 2) var held_asset_facing := 1
@export_range(-3.14, 3.14, 0.01) var held_idle_rotation := 0.0
@export_range(-3.14, 3.14, 0.01) var held_contact_rotation := 0.0


func is_valid_weapon() -> bool:
	if weapon_id.is_empty() or display_name.is_empty() or behavior_id.is_empty() or capacity <= 0 or impact_profile == null or not has_valid_held_visual():
		return false
	if not impact_profile.has_method("is_valid_profile") or not impact_profile.is_valid_profile():
		return false
	if kind == WeaponKind.MELEE:
		return (
			melee_bonus_damage > 0
			and damage == 0
			and melee_reach_scale >= 0.5
			and melee_knockback_scale >= 0.5
			and ((chain_radius <= 0.0 and chain_damage == 0) or (chain_radius > 0.0 and chain_damage > 0))
		)
	if kind == WeaponKind.FIREARM:
		return (
			damage > 0
			and projectile_speed > 0.0
			and projectile_lifetime > 0.0
			and shots_per_use >= 1
			and penetration_count >= 1
			and not fire_sfx.is_empty()
		)
	if kind == WeaponKind.EXPLOSIVE:
		return (
			damage > 0
			and projectile_lifetime > 0.0
			and explosion_radius > 0.0
			and (stationary or projectile_speed > 0.0)
			and (fuse_duration > 0.0 or detonate_on_contact or trigger_radius > 0.0)
			and (not stationary or (arm_delay > 0.0 and trigger_radius > 0.0))
			and ((lingering_duration <= 0.0 and lingering_damage == 0) or (lingering_duration > 0.0 and lingering_damage > 0))
			and not fire_sfx.is_empty()
			and not blast_sfx.is_empty()
		)
	return false


func has_valid_held_visual() -> bool:
	return (
		held_crop.size.x > 0.0
		and held_crop.size.y > 0.0
		and held_grip.x >= 0.0
		and held_grip.y >= 0.0
		and held_grip.x <= held_crop.size.x
		and held_grip.y <= held_crop.size.y
		and held_scale > 0.0
		and absi(held_asset_facing) == 1
	)
