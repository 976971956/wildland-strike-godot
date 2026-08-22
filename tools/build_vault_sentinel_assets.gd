extends SceneTree

const COLUMNS := 8
const ROWS := 2
const CELL_SIZE := Vector2i(320, 320)
const CONTENT_LIMIT := Vector2i(298, 294)
const ALPHA_THRESHOLD := 0.18


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("usage: -- <vault-sentinels-source> <vault-sentinels-sheet>")
		quit(2)
		return
	var source := Image.load_from_file(ProjectSettings.globalize_path(args[0]))
	if source == null or source.is_empty():
		push_error("unable to load Vault Sentinels source")
		quit(3)
		return
	source.convert(Image.FORMAT_RGBA8)
	_clear_edge_background(source)
	var row_cut := _best_horizontal_cut(source, roundi(source.get_height() * 0.5), 70)
	var row_cuts: Array[int] = [0, row_cut, source.get_height()]
	var output := Image.create(CELL_SIZE.x * COLUMNS, CELL_SIZE.y * ROWS, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for row in range(ROWS):
		var column_cuts: Array[int] = [0]
		for boundary in range(1, COLUMNS):
			column_cuts.append(_best_vertical_cut(source, roundi(float(boundary) * source.get_width() / COLUMNS), 76, row_cuts[row], row_cuts[row + 1]))
		column_cuts.append(source.get_width())
		var poses: Array[Image] = []
		var largest_size := Vector2i.ONE
		for column in range(COLUMNS):
			var rect := Rect2i(column_cuts[column], row_cuts[row], column_cuts[column + 1] - column_cuts[column], row_cuts[row + 1] - row_cuts[row])
			var pose := _trim_cell(source.get_region(rect))
			if pose.is_empty():
				push_error("empty Vault Sentinel pose row=%d column=%d" % [row, column])
				quit(4)
				return
			poses.append(pose)
			largest_size.x = maxi(largest_size.x, pose.get_width())
			largest_size.y = maxi(largest_size.y, pose.get_height())
		var scale_factor := minf(float(CONTENT_LIMIT.x) / largest_size.x, float(CONTENT_LIMIT.y) / largest_size.y)
		for column in range(COLUMNS):
			var pose := poses[column]
			var target_size := Vector2i(maxi(1, roundi(pose.get_width() * scale_factor)), maxi(1, roundi(pose.get_height() * scale_factor)))
			pose.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
			var destination := Vector2i(column * CELL_SIZE.x + int((CELL_SIZE.x - target_size.x) * 0.5), row * CELL_SIZE.y + CELL_SIZE.y - target_size.y - 8)
			output.blit_rect(pose, Rect2i(Vector2i.ZERO, target_size), destination)
	var error := output.save_png(ProjectSettings.globalize_path(args[1]))
	if error != OK:
		push_error("unable to save Vault Sentinels sheet: %s" % error_string(error))
		quit(5)
		return
	print("VAULT_SENTINEL_ASSETS_EXPORTED columns=%d rows=%d size=%dx%d" % [COLUMNS, ROWS, output.get_width(), output.get_height()])
	quit()


func _trim_cell(cell: Image) -> Image:
	var components := _extract_components(cell)
	if components.is_empty():
		return Image.new()
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pixels.size() > b.pixels.size())
	var component: Dictionary = components[0]
	var minimum: Vector2i = component.minimum
	var maximum: Vector2i = component.maximum
	var output := Image.create(maximum.x - minimum.x + 1, maximum.y - minimum.y + 1, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for pixel_index in component.pixels:
		var point := Vector2i(pixel_index % cell.get_width(), pixel_index / cell.get_width())
		output.set_pixelv(point - minimum, cell.get_pixelv(point))
	return output


func _extract_components(image: Image) -> Array[Dictionary]:
	var size := image.get_size()
	var visited := PackedByteArray()
	visited.resize(size.x * size.y)
	var components: Array[Dictionary] = []
	for y in range(size.y):
		for x in range(size.x):
			var start_index := y * size.x + x
			if visited[start_index] != 0 or image.get_pixel(x, y).a < ALPHA_THRESHOLD:
				continue
			visited[start_index] = 1
			var stack: Array[Vector2i] = [Vector2i(x, y)]
			var pixels := PackedInt32Array()
			var minimum := Vector2i(x, y)
			var maximum := minimum
			while not stack.is_empty():
				var point: Vector2i = stack.pop_back()
				pixels.append(point.y * size.x + point.x)
				minimum = minimum.min(point)
				maximum = maximum.max(point)
				for offset_y in range(-1, 2):
					for offset_x in range(-1, 2):
						if offset_x == 0 and offset_y == 0:
							continue
						var next := point + Vector2i(offset_x, offset_y)
						if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y:
							continue
						var next_index := next.y * size.x + next.x
						if visited[next_index] != 0 or image.get_pixelv(next).a < ALPHA_THRESHOLD:
							continue
						visited[next_index] = 1
						stack.append(next)
			if pixels.size() >= 80:
				components.append({"pixels": pixels, "minimum": minimum, "maximum": maximum})
	return components


func _best_vertical_cut(image: Image, approximate: int, radius: int, top: int, bottom: int) -> int:
	var best_x := approximate
	var best_count := image.get_height() + 1
	for x in range(maxi(1, approximate - radius), mini(image.get_width() - 1, approximate + radius + 1)):
		var count := 0
		for y in range(top, bottom):
			if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				count += 1
		if count < best_count:
			best_count = count
			best_x = x
	return best_x


func _best_horizontal_cut(image: Image, approximate: int, radius: int) -> int:
	var best_y := approximate
	var best_count := image.get_width() + 1
	for y in range(maxi(1, approximate - radius), mini(image.get_height() - 1, approximate + radius + 1)):
		var count := 0
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				count += 1
		if count < best_count:
			best_count = count
			best_y = y
	return best_y


func _clear_edge_background(image: Image) -> void:
	var size := image.get_size()
	var visited := PackedByteArray()
	visited.resize(size.x * size.y)
	var stack: Array[Vector2i] = []
	for x in range(size.x):
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, size.y - 1))
	for y in range(size.y):
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(size.x - 1, y))
	while not stack.is_empty():
		var point: Vector2i = stack.pop_back()
		var index: int = point.y * size.x + point.x
		if visited[index] != 0:
			continue
		visited[index] = 1
		var color: Color = image.get_pixelv(point)
		if color.a >= ALPHA_THRESHOLD and maxf(color.r, maxf(color.g, color.b)) > 0.06:
			continue
		image.set_pixelv(point, Color.TRANSPARENT)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = point + offset
			if next.x >= 0 and next.y >= 0 and next.x < size.x and next.y < size.y:
				stack.append(next)
