extends SceneTree

const CELL_SIZE := Vector2i(160, 160)
const CONTENT_LIMIT := Vector2i(144, 132)
const ALPHA_THRESHOLD := 0.06

const ITEM_SOURCE := "res://assets/sprites/item_pickups_source.png"
const ITEM_OUTPUT := "res://assets/sprites/item_pickups_atlas.png"
const ITEM_COLUMNS := 4
const ITEM_ROWS := 2
# Generated source order ends with INTEL then RELIC; runtime catalog order is
# RELIC then INTEL.
const ITEM_SOURCE_ORDER := [0, 1, 2, 3, 4, 5, 7, 6]

const WEAPON_SOURCE := "res://assets/sprites/weapon_pickups_source.png"
const WEAPON_OUTPUT := "res://assets/sprites/weapon_pickups_atlas.png"
const WEAPON_COLUMNS := 4
const WEAPON_ROWS := 3
# Generated source order places SMG before RIFLE; runtime catalog does the
# reverse so definition indices remain stable.
const WEAPON_SOURCE_ORDER := [0, 1, 2, 3, 4, 5, 7, 6, 8, 9, 10, 11]


func _initialize() -> void:
	var item_result := _build_atlas(ITEM_SOURCE, ITEM_OUTPUT, ITEM_COLUMNS, ITEM_ROWS, ITEM_SOURCE_ORDER, false)
	if item_result != OK:
		quit(item_result)
		return
	var weapon_result := _build_atlas(WEAPON_SOURCE, WEAPON_OUTPUT, WEAPON_COLUMNS, WEAPON_ROWS, WEAPON_SOURCE_ORDER, true)
	if weapon_result != OK:
		quit(weapon_result)
		return
	print("PICKUP_ASSETS_EXPORTED items=%s weapons=%s cell=%dx%d" % [ITEM_OUTPUT, WEAPON_OUTPUT, CELL_SIZE.x, CELL_SIZE.y])
	quit(0)


func _build_atlas(source_path: String, output_path: String, columns: int, rows: int, source_order: Array, isolate_largest_component: bool) -> int:
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Unable to load pickup source: %s" % source_path)
		return 2
	source.convert(Image.FORMAT_RGBA8)
	_clear_checker_background(source)
	var source_cell := Vector2i(source.get_width() / columns, source.get_height() / rows)
	if source_cell.x * columns != source.get_width() or source_cell.y * rows != source.get_height():
		push_error("Pickup source does not divide into an exact grid: %s" % source_path)
		return 3
	if source_order.size() != columns * rows:
		push_error("Pickup source order does not cover every cell: %s" % source_path)
		return 4

	var output := Image.create(CELL_SIZE.x * columns, CELL_SIZE.y * rows, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for output_index in range(source_order.size()):
		var source_index: int = source_order[output_index]
		var source_position := Vector2i(source_index % columns, source_index / columns) * source_cell
		var cell := source.get_region(Rect2i(source_position, source_cell))
		if isolate_largest_component:
			_keep_largest_component(cell)
		var bounds := _visible_bounds(cell)
		if bounds.size.x <= 0 or bounds.size.y <= 0:
			push_error("Pickup source cell %d is empty: %s" % [source_index, source_path])
			return 5
		var isolated := cell.get_region(bounds)
		var scale_factor := minf(float(CONTENT_LIMIT.x) / isolated.get_width(), float(CONTENT_LIMIT.y) / isolated.get_height())
		var target_size := Vector2i(
			maxi(1, roundi(isolated.get_width() * scale_factor)),
			maxi(1, roundi(isolated.get_height() * scale_factor))
		)
		isolated.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
		var output_cell_position := Vector2i(output_index % columns, output_index / columns) * CELL_SIZE
		var destination := output_cell_position + Vector2i(
			(CELL_SIZE.x - target_size.x) / 2,
			CELL_SIZE.y - target_size.y - 8
		)
		output.blit_rect(isolated, Rect2i(Vector2i.ZERO, target_size), destination)

	var error := output.save_png(output_path)
	if error != OK:
		push_error("Unable to save pickup atlas %s: %s" % [output_path, error_string(error)])
		return 6
	return OK


func _keep_largest_component(image: Image) -> void:
	# Weapons occasionally cross a generated grid boundary by a few pixels. An
	# eight-connected flood fill keeps the actual weapon and discards those
	# neighboring-cell fragments without hand-painting the generated source.
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	visited.fill(0)
	var largest := PackedInt32Array()
	for y in range(height):
		for x in range(width):
			var start := y * width + x
			if visited[start] != 0 or image.get_pixel(x, y).a <= ALPHA_THRESHOLD:
				continue
			var component := PackedInt32Array()
			var queue := PackedInt32Array([start])
			visited[start] = 1
			var cursor := 0
			while cursor < queue.size():
				var current := queue[cursor]
				cursor += 1
				component.append(current)
				var current_x := current % width
				var current_y := current / width
				for offset_y in range(-1, 2):
					for offset_x in range(-1, 2):
						if offset_x == 0 and offset_y == 0:
							continue
						var neighbor_x := current_x + offset_x
						var neighbor_y := current_y + offset_y
						if neighbor_x < 0 or neighbor_x >= width or neighbor_y < 0 or neighbor_y >= height:
							continue
						var neighbor := neighbor_y * width + neighbor_x
						if visited[neighbor] != 0:
							continue
						visited[neighbor] = 1
						if image.get_pixel(neighbor_x, neighbor_y).a > ALPHA_THRESHOLD:
							queue.append(neighbor)
			if component.size() > largest.size():
				largest = component

	var keep := PackedByteArray()
	keep.resize(width * height)
	keep.fill(0)
	for pixel in largest:
		keep[pixel] = 1
	for y in range(height):
		for x in range(width):
			if keep[y * width + x] == 0:
				image.set_pixel(x, y, Color.TRANSPARENT)


func _visible_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= ALPHA_THRESHOLD:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _clear_checker_background(image: Image) -> void:
	# The isolation edit uses two bright neutral checker colors. Remove only
	# near-neutral light pixels; the pickups retain colored highlights and dark
	# outlines, while checker pixels inside weapon loops disappear as well.
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var brightest := maxf(color.r, maxf(color.g, color.b))
			var darkest := minf(color.r, minf(color.g, color.b))
			if darkest > 0.78 and brightest - darkest < 0.045:
				image.set_pixel(x, y, Color.TRANSPARENT)
