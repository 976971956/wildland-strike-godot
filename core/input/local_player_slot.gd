class_name LocalPlayerSlot
extends RefCounted

const KEYBOARD_DEVICE := -1

var slot_index := 0
var device_id := KEYBOARD_DEVICE
var hero_index := 0
var selection_ready := false


func _init(p_slot_index: int = 0, p_device_id: int = KEYBOARD_DEVICE, p_hero_index: int = 0) -> void:
	slot_index = p_slot_index
	device_id = p_device_id
	hero_index = p_hero_index


func is_keyboard() -> bool:
	return device_id == KEYBOARD_DEVICE
