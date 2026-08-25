class_name HeroDefinition
extends Resource

@export var hero_id: StringName
@export var display_name := ""
@export var role_title := ""
@export_multiline var role_summary := ""
@export var primary_color := Color.WHITE
@export var accent_color := Color.WHITE
@export var sprite_sheet: Texture2D
@export_group("Skills")
@export var command_skill_name := ""
@export_multiline var command_skill_summary := ""
@export var command_attack: Resource
@export var defensive_skill_name := ""
@export_multiline var defensive_skill_summary := ""
@export var defensive_special: Resource
@export_group("Stats")
@export_range(1, 12, 1) var sprite_columns := 6
@export_range(1, 12, 1) var sprite_rows := 4
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
		and sprite_sheet != null
		and not command_skill_name.is_empty()
		and not command_skill_summary.is_empty()
		and command_attack != null
		and command_attack.has_method("is_valid_frame_data")
		and command_attack.is_valid_frame_data()
		and not defensive_skill_name.is_empty()
		and not defensive_skill_summary.is_empty()
		and defensive_special != null
		and defensive_special.has_method("is_valid_frame_data")
		and defensive_special.is_valid_frame_data()
		and sprite_sheet.get_width() % sprite_columns == 0
		and sprite_sheet.get_height() % sprite_rows == 0
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
