class_name WeaponDefinition
extends Resource

enum WeaponKind {
	MELEE,
	EXPLOSIVE,
	FIREARM,
}

@export var weapon_id: StringName
@export var display_name := ""
@export var kind := WeaponKind.MELEE
@export_range(1, 99, 1) var capacity := 1
@export_range(0, 100, 1) var damage := 0
@export_range(0, 100, 1) var melee_bonus_damage := 0
@export var projectile_speed := 0.0
@export_range(0.0, 5.0, 0.05) var projectile_lifetime := 0.0
@export_range(0.0, 5.0, 0.05) var fuse_duration := 0.0
@export_range(0.0, 300.0, 1.0) var explosion_radius := 0.0
@export var impact_profile: Resource
@export var fire_sfx: StringName
@export var color := Color.WHITE


func is_valid_weapon() -> bool:
	if weapon_id.is_empty() or display_name.is_empty() or capacity <= 0 or impact_profile == null:
		return false
	if not impact_profile.has_method("is_valid_profile") or not impact_profile.is_valid_profile():
		return false
	if kind == WeaponKind.MELEE:
		return melee_bonus_damage > 0 and damage == 0
	if kind == WeaponKind.FIREARM:
		return damage > 0 and projectile_speed > 0.0 and projectile_lifetime > 0.0 and not fire_sfx.is_empty()
	if kind == WeaponKind.EXPLOSIVE:
		return damage > 0 and projectile_speed > 0.0 and fuse_duration > 0.0 and explosion_radius > 0.0
	return false
