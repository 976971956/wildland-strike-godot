class_name ComboDefinition
extends Resource

@export var fighter_id: StringName
@export var attacks: Array[AttackFrameData] = []
@export_range(1, 8, 1) var finisher_from_step := 3
@export_range(1, 8, 1) var finisher_step := 4
@export_range(0.0, 1.0, 0.001) var finisher_input_open_remaining := 0.20
@export_range(0.0, 1.0, 0.001) var finisher_input_close_remaining := 0.04
@export_range(0.0, 1.0, 0.001) var input_buffer_duration := 0.24


func is_valid_definition() -> bool:
	if fighter_id.is_empty() or attacks.size() < finisher_step:
		return false
	if finisher_from_step < 1 or finisher_step != finisher_from_step + 1:
		return false
	if finisher_input_close_remaining < 0.0:
		return false
	if finisher_input_open_remaining <= finisher_input_close_remaining:
		return false
	for attack in attacks:
		if attack == null or not attack.is_valid_frame_data():
			return false
	return true


func attack_for_step(step: int) -> AttackFrameData:
	if step < 1 or step > attacks.size():
		return null
	return attacks[step - 1]


func is_finisher_input_open(current_step: int, attack_remaining: float) -> bool:
	return (
		current_step == finisher_from_step
		and attack_remaining <= finisher_input_open_remaining
		and attack_remaining >= finisher_input_close_remaining
	)
