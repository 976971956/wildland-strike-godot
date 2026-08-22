class_name HeroDefinition
extends Resource

@export var hero_id: StringName
@export var display_name := ""
@export var role_title := ""
@export_multiline var role_summary := ""
@export var primary_color := Color.WHITE
@export var accent_color := Color.WHITE
@export_range(60, 240, 1) var max_health := 120
@export_range(160.0, 340.0, 1.0) var move_speed := 255.0
@export_range(1.2, 2.2, 0.01) var run_multiplier := 1.65
@export_range(0.6, 1.6, 0.01) var damage_scale := 1.0
@export_range(0.6, 1.8, 0.01) var item_efficiency := 1.0
@export_range(0.6, 1.8, 0.01) var aerial_control := 1.0
@export_range(0.6, 1.8, 0.01) var grapple_power := 1.0


func is_valid_hero() -> bool:
	return (
		not hero_id.is_empty()
		and not display_name.is_empty()
		and not role_title.is_empty()
		and not role_summary.is_empty()
		and max_health >= 60
		and move_speed >= 160.0
		and run_multiplier >= 1.2
		and damage_scale > 0.0
		and item_efficiency > 0.0
		and aerial_control > 0.0
		and grapple_power > 0.0
	)


func stat_vector() -> Vector4:
	return Vector4(damage_scale, item_efficiency, aerial_control, grapple_power)
