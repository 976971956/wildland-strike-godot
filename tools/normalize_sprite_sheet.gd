extends SceneTree

const ALPHA_THRESHOLD := 0.12
const NEIGHBORS := [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 4 or args.size() > 5:
		push_error("usage: -- <png> <columns> <rows> <minimum-component-pixels> [maximum-component-gap]")
		quit(2)
		return
	var path: String = args[0]
	var columns := int(args[1])
	var rows := int(args[2])
	var minimum_component_pixels := int(args[3])
	var maximum_component_gap := float(args[4]) if args.size() == 5 else 40.0
	var global_path := ProjectSettings.globalize_path(path)
	var image := Image.load_from_file(global_path)
	if image == null or columns <= 0 or rows <= 0:
		push_error("invalid sprite sheet or grid: %s" % path)
		quit(3)
		return
	if image.get_width() % columns != 0 or image.get_height() % rows != 0:
		push_error("sprite sheet does not divide into the requested grid: %s" % path)
		quit(4)
		return
	var cell_size := Vector2i(int(image.get_width() / columns), int(image.get_height() / rows))
	var removed_components := 0
	var removed_pixels := 0
	for row in range(rows):
		for column in range(columns):
			var result := _normalize_cell(image, Vector2i(column, row) * cell_size, cell_size, minimum_component_pixels, maximum_component_gap)
			removed_components += result.components
			removed_pixels += result.pixels
	var save_error := image.save_png(global_path)
	if save_error != OK:
		push_error("failed to save normalized sprite sheet: %s" % path)
		quit(5)
		return
	print("SPRITE_NORMALIZED %s removed_components=%d removed_pixels=%d" % [path, removed_components, removed_pixels])
	quit()


func _normalize_cell(image: Image, origin: Vector2i, size: Vector2i, minimum_component_pixels: int, maximum_component_gap: float) -> Dictionary:
	var visited := PackedByteArray()
	visited.resize(size.x * size.y)
	var removed_components := 0
	var removed_pixels := 0
	var components: Array[Dictionary] = []
	for local_y in range(size.y):
		for local_x in range(size.x):
			var point := origin + Vector2i(local_x, local_y)
			var color := image.get_pixelv(point)
			if color.a < ALPHA_THRESHOLD:
				if color.a > 0.0:
					color.a = 0.0
					image.set_pixelv(point, color)
				continue
			var start_index := local_y * size.x + local_x
			if visited[start_index] != 0:
				continue
			var stack: Array[Vector2i] = [Vector2i(local_x, local_y)]
			var component := PackedInt32Array()
			var component_min := Vector2i(local_x, local_y)
			var component_max := component_min
			visited[start_index] = 1
			while not stack.is_empty():
				var local_point: Vector2i = stack.pop_back()
				component.append(local_point.y * size.x + local_point.x)
				component_min.x = mini(component_min.x, local_point.x)
				component_min.y = mini(component_min.y, local_point.y)
				component_max.x = maxi(component_max.x, local_point.x)
				component_max.y = maxi(component_max.y, local_point.y)
				for neighbor in NEIGHBORS:
					var next: Vector2i = local_point + neighbor
					if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y:
						continue
					var next_index := next.y * size.x + next.x
					if visited[next_index] != 0:
						continue
					if image.get_pixelv(origin + next).a < ALPHA_THRESHOLD:
						continue
					visited[next_index] = 1
					stack.append(next)
			components.append({"pixels": component, "minimum": component_min, "maximum": component_max})
	if components.is_empty():
		return {"components": 0, "pixels": 0}
	var main_component_index := 0
	for index in range(1, components.size()):
		if components[index].pixels.size() > components[main_component_index].pixels.size():
			main_component_index = index
	var main_component: Dictionary = components[main_component_index]
	var main_proximity := _build_proximity_mask(main_component.pixels, size, ceili(maximum_component_gap))
	for index in range(components.size()):
		var component: Dictionary = components[index]
		var remove_component: bool = component.pixels.size() < minimum_component_pixels
		if index != main_component_index and not _component_touches_mask(component.pixels, main_proximity):
			remove_component = true
		if not remove_component:
			continue
		removed_components += 1
		removed_pixels += component.pixels.size()
		for pixel_index in component.pixels:
			var local_point := Vector2i(pixel_index % size.x, pixel_index / size.x)
			var final_point := origin + local_point
			var pixel := image.get_pixelv(final_point)
			pixel.a = 0.0
			image.set_pixelv(final_point, pixel)
	return {"components": removed_components, "pixels": removed_pixels}


func _build_proximity_mask(main_pixels: PackedInt32Array, size: Vector2i, distance: int) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(size.x * size.y)
	var frontier := PackedInt32Array()
	for pixel_index in main_pixels:
		mask[pixel_index] = 1
		frontier.append(pixel_index)
	for _step in range(distance):
		var next_frontier := PackedInt32Array()
		for pixel_index in frontier:
			var point := Vector2i(pixel_index % size.x, pixel_index / size.x)
			for neighbor in NEIGHBORS:
				var next: Vector2i = point + neighbor
				if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y:
					continue
				var next_index: int = next.y * size.x + next.x
				if mask[next_index] != 0:
					continue
				mask[next_index] = 1
				next_frontier.append(next_index)
		frontier = next_frontier
	return mask


func _component_touches_mask(component_pixels: PackedInt32Array, mask: PackedByteArray) -> bool:
	for pixel_index in component_pixels:
		if mask[pixel_index] != 0:
			return true
	return false
