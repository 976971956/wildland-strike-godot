class_name EnemyDefinition
extends Resource

enum VisualKind {
	HUMANOID,
	RAPTOR,
}

@export_group("Identity")
@export var enemy_id: StringName
@export var is_boss := false

@export_group("Combat")
@export var max_health := 1
@export var speed := 100.0
@export var attack: AttackFrameData
@export var can_be_grabbed := true
@export var defeat_score := 0

@export_group("Presentation")
@export var sprite_sheet: Texture2D
@export var visual_kind := VisualKind.HUMANOID
@export var sprite_columns := 4
@export var sprite_rows := 3
@export var sprite_row := 0
@export var target_size := Vector2(174.0, 174.0)
@export var target_bottom_offset := 14.0
@export var body_scale := 1.0
@export var actor_scale := Vector2.ONE
@export var shadow_half_extents := Vector2(34.0, 9.0)
@export var tint := Color.WHITE
@export var hurt_tint := Color(1.0, 0.68, 0.61)
@export var show_health_bar := false


func is_valid_definition() -> bool:
	return (
		not enemy_id.is_empty()
		and max_health > 0
		and speed > 0.0
		and attack != null
		and attack.is_valid_frame_data()
		and sprite_sheet != null
		and sprite_columns > 0
		and sprite_rows > 0
		and target_size.x > 0.0
		and target_size.y > 0.0
	)
