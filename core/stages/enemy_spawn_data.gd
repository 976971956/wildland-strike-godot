class_name EnemySpawnData
extends Resource

@export var enemy_id: StringName
@export var offset := Vector2.ZERO


func is_valid_spawn() -> bool:
	return not enemy_id.is_empty()
