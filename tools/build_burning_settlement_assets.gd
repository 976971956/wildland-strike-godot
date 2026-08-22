extends SceneTree

const COLUMNS := 8
const ROWS := 2
const CELL_SIZE := Vector2i(320, 320)
const CONTENT_LIMIT := Vector2i(296, 292)
# Faint smoke/effect pixels can bridge otherwise isolated poses in generated
# source. Runtime silhouettes remain opaque well above this cutoff.
const ALPHA_THRESHOLD := 0.22


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("usage: -- <cinder-matriarch-source> <cinder-matriarch-sheet>")
		quit(2)
		return
	var source := Image.load_from_file(ProjectSettings.globalize_path(args[0]))
	if source == null or source.is_empty():
		push_error("unable to load Cinder Matriarch source")
		quit(3)
		return
	source.convert(Image.FORMAT_RGBA8)
	_clear_edge_background(source)
	var row_cut := _best_horizontal_cut(source, roundi(source.get_height() * 0.5), 64)
	var row_cuts: Array[int] = [0, row_cut, source.get_height()]
	var output := Image.create(CELL_SIZE.x * COLUMNS, CELL_SIZE.y * ROWS, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for row in range(ROWS):
		var column_cuts: Array[int] = [0]
		for boundary in range(1, COLUMNS):
			column_cuts.append(_best_vertical_cut(source, roundi(float(boundary) * source.get_width() / COLUMNS), 82, row_cuts[row], row_cuts[row + 1]))
		column_cuts.append(source.get_width())
		var poses: Array[Image] = []
		var largest_size := Vector2i.ONE
		for column in range(COLUMNS):
			var rect := Rect2i(column_cuts[column], row_cuts[row], column_cuts[column + 1] - column_cuts[column], row_cuts[row + 1] - row_cuts[row])
			var pose := _trim_cell(source.get_region(rect))
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
		push_error("unable to save Cinder Matriarch sheet: %s" % error_string(error))
		quit(6)
		return
	print("BURNING_SETTLEMENT_ASSETS_EXPORTED columns=%d rows=%d size=%dx%d" % [COLUMNS, ROWS, output.get_width(), output.get_height()])
	quit()


func _trim_cell(cell: Image) -> Image:
	var minimum := cell.get_size()
	var maximum := Vector2i(-1, -1)
	for y in range(cell.get_height()):
		for x in range(cell.get_width()):
			if cell.get_pixel(x, y).a < ALPHA_THRESHOLD:
				continue
			minimum = minimum.min(Vector2i(x, y))
			maximum = maximum.max(Vector2i(x, y))
	if maximum.x < minimum.x or maximum.y < minimum.y:
		return Image.new()
	return cell.get_region(Rect2i(minimum, maximum - minimum + Vector2i.ONE))


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
	# Some image-service edits bake a pale checkerboard despite requesting alpha.
	# Remove only bright, near-neutral pixels before the dark-edge flood; saturated
	# cyan/orange highlights and all charcoal silhouette pixels are preserved.
	for y in range(size.y):
		for x in range(size.x):
			var checker: Color = image.get_pixel(x, y)
			var brightest := maxf(checker.r, maxf(checker.g, checker.b))
			var darkest := minf(checker.r, minf(checker.g, checker.b))
			if darkest > 0.72 and brightest - darkest < 0.12:
				image.set_pixel(x, y, Color.TRANSPARENT)
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
		if maxf(color.r, maxf(color.g, color.b)) > 0.075:
			continue
		image.set_pixelv(point, Color.TRANSPARENT)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = point + offset
			if next.x >= 0 and next.y >= 0 and next.x < size.x and next.y < size.y:
				stack.append(next)


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
			if pixels.size() >= 160:
				components.append({"pixels": pixels, "minimum": minimum, "maximum": maximum})
	return components


func _component_image(source: Image, component: Dictionary) -> Image:
	var minimum: Vector2i = component.minimum
	var maximum: Vector2i = component.maximum
	var output := Image.create(maximum.x - minimum.x + 1, maximum.y - minimum.y + 1, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for pixel_index in component.pixels:
		var source_point := Vector2i(pixel_index % source.get_width(), pixel_index / source.get_width())
		output.set_pixelv(source_point - minimum, source.get_pixelv(source_point))
	return output
