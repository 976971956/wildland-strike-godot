class_name LocalPlayerRegistry
extends RefCounted

const LocalPlayerSlotScript = preload("res://core/input/local_player_slot.gd")
const MAX_PLAYERS := 3
const KEYBOARD_DEVICE := -1

var slots: Array[RefCounted] = []


func reset_with_keyboard(hero_index := 0) -> RefCounted:
	slots.clear()
	return join_device(KEYBOARD_DEVICE, hero_index)


func join_device(device_id: int, hero_index := 0) -> RefCounted:
	var existing := slot_for_device(device_id)
	if existing != null:
		return existing
	if slots.size() >= MAX_PLAYERS:
		return null
	var occupied := {}
	for slot in slots:
		occupied[slot.slot_index] = true
	var available_index := -1
	for slot_index in range(MAX_PLAYERS):
		if not occupied.has(slot_index):
			available_index = slot_index
			break
	if available_index < 0:
		return null
	var slot := LocalPlayerSlotScript.new(available_index, device_id, maxi(hero_index, 0))
	slots.append(slot)
	slots.sort_custom(func(a, b): return a.slot_index < b.slot_index)
	return slot


func leave_device(device_id: int) -> RefCounted:
	for index in range(slots.size()):
		if slots[index].device_id == device_id:
			var removed: RefCounted = slots[index]
			slots.remove_at(index)
			return removed
	return null


func slot_for_device(device_id: int) -> RefCounted:
	for slot in slots:
		if slot.device_id == device_id:
			return slot
	return null


func slot_at(slot_index: int) -> RefCounted:
	for slot in slots:
		if slot.slot_index == slot_index:
			return slot
	return null


func set_hero(slot_index: int, hero_index: int) -> bool:
	var slot := slot_at(slot_index)
	if slot == null:
		return false
	slot.hero_index = maxi(hero_index, 0)
	return true


func active_slots() -> Array[RefCounted]:
	return slots.duplicate()


func is_full() -> bool:
	return slots.size() >= MAX_PLAYERS
