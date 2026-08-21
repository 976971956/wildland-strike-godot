class_name ArcadeTestContext
extends RefCounted

var tree: SceneTree
var suite_name: String
var assertions := 0
var failures := 0


func _init(p_tree: SceneTree, p_suite_name: String) -> void:
	tree = p_tree
	suite_name = p_suite_name


func check(value: bool, message: String) -> void:
	assertions += 1
	if value:
		return
	failures += 1
	push_error("TEST [%s]: %s" % [suite_name, message])


func wait_physics_frames(count: int) -> void:
	for _frame in range(count):
		await tree.physics_frame


func instantiate_main() -> Node:
	var packed_scene: PackedScene = load("res://main.tscn")
	check(packed_scene != null, "main scene failed to load")
	if packed_scene == null:
		return null
	var game := packed_scene.instantiate()
	tree.root.add_child(game)
	await tree.process_frame
	return game


func dispose(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
		await tree.process_frame
	Engine.time_scale = 1.0
