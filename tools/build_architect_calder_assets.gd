extends SceneTree

const COLUMNS := 8
const ROWS := 3
const CELL_SIZE := Vector2i(320, 320)
const CONTENT_LIMIT := Vector2i(300, 296)
const ALPHA_THRESHOLD := 0.16


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("usage: -- <architect-calder-edit-source> <architect-calder-sheet>")
		quit(2)
		return
	var source := Image.load_from_file(ProjectSettings.globalize_path(args[0]))
	if source == null or source.is_empty():
		push_error("unable to load Architect Calder source")
		quit(3)
		return
	source.convert(Image.FORMAT_RGBA8)
	_clear_checker_background(source)
	var row_cuts: Array[int] = [0]
	for boundary in range(1, ROWS):
		row_cuts.append(_best_horizontal_cut(source, roundi(float(boundary) * source.get_height() / ROWS), 34))
	row_cuts.append(source.get_height())
	var output := Image.create(CELL_SIZE.x * COLUMNS, CELL_SIZE.y * ROWS, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for row in range(ROWS):
		var row_image := source.get_region(Rect2i(0, row_cuts[row], source.get_width(), row_cuts[row + 1] - row_cuts[row]))
		var components := _extract_components(row_image)
		components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pixels.size() > b.pixels.size())
		if components.size() < COLUMNS:
			push_error("Architect Calder row %d has only %d complete pose components" % [row, components.size()])
			quit(4)
			return
		components = components.slice(0, COLUMNS)
		components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.minimum.x < b.minimum.x)
		var poses: Array[Image] = []
		var largest_size := Vector2i.ONE
		for column in range(COLUMNS):
			var pose := _component_image(row_image, components[column])
			if pose.is_empty():
				push_error("empty Architect Calder pose row=%d column=%d" % [row, column])
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
		push_error("unable to save Architect Calder sheet: %s" % error_string(error))
		quit(5)
		return
	print("ARCHITECT_CALDER_ASSETS_EXPORTED columns=%d rows=%d size=%dx%d" % [COLUMNS, ROWS, output.get_width(), output.get_height()])
	quit()


func _clear_checker_background(image: Image) -> void:
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
		var index := point.y * size.x + point.x
		if visited[index] != 0:
			continue
		visited[index] = 1
		var color := image.get_pixelv(point)
		var brightest := maxf(color.r, maxf(color.g, color.b))
		var darkest := minf(color.r, minf(color.g, color.b))
		var is_checker := darkest >= 0.78 and brightest - darkest <= 0.1
		# Isolation edit uses an exact #000000 field. Keep near-black armor and
		# outlines; only the mathematically black connected background is keyed.
		var is_black_key := brightest <= 0.008
		if not is_checker and not is_black_key:
			continue
		image.set_pixelv(point, Color.TRANSPARENT)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = point + offset
			if next.x >= 0 and next.y >= 0 and next.x < size.x and next.y < size.y:
				stack.append(next)


func _component_image(source: Image, component: Dictionary) -> Image:
	var minimum: Vector2i = component.minimum
	var maximum: Vector2i = component.maximum
	var output := Image.create(maximum.x - minimum.x + 1, maximum.y - minimum.y + 1, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for pixel_index in component.pixels:
		var point := Vector2i(pixel_index % source.get_width(), pixel_index / source.get_width())
		output.set_pixelv(point - minimum, source.get_pixelv(point))
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
						var next: Vector2i = point + Vector2i(offset_x, offset_y)
						if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y:
							continue
						var next_index := next.y * size.x + next.x
						if visited[next_index] != 0 or image.get_pixelv(next).a < ALPHA_THRESHOLD:
							continue
						visited[next_index] = 1
						stack.append(next)
			if pixels.size() >= 60:
				components.append({"pixels": pixels, "minimum": minimum, "maximum": maximum})
	return components


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
