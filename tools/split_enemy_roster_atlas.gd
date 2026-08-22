extends SceneTree

const COLUMNS := 8
const ROWS := 8
const CELL_SIZE := Vector2i(320, 320)
const CONTENT_LIMIT := Vector2i(292, 286)
const ALPHA_THRESHOLD := 0.12
const BLACK_KEY_THRESHOLD := 0.045


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != ROWS + 1:
		push_error("usage: -- <source.png> <row-0.png> ... <row-7.png>")
		quit(2)
		return
	var source := Image.load_from_file(ProjectSettings.globalize_path(args[0]))
	if source == null:
		push_error("failed to load enemy roster atlas: %s" % args[0])
		quit(3)
		return
	source.convert(Image.FORMAT_RGBA8)
	for row in range(ROWS):
		var output := Image.create(CELL_SIZE.x * COLUMNS, CELL_SIZE.y, false, Image.FORMAT_RGBA8)
		output.fill(Color.TRANSPARENT)
		var source_row := source.get_region(_row_rect(source.get_size(), row))
		_key_black_background(source_row)
		var components := _extract_components(source_row)
		components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pixels.size() > b.pixels.size())
		if components.size() < COLUMNS:
			push_error("row %d contains only %d isolated actors" % [row, components.size()])
			quit(5)
			return
		components.resize(COLUMNS)
		components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.minimum.x < b.minimum.x)
		for column in range(COLUMNS):
			var pose := _component_image(source_row, components[column])
			var scale_factor := minf(
				float(CONTENT_LIMIT.x) / float(pose.get_width()),
				float(CONTENT_LIMIT.y) / float(pose.get_height())
			)
			var scaled_size := Vector2i(
				maxi(1, roundi(pose.get_width() * scale_factor)),
				maxi(1, roundi(pose.get_height() * scale_factor))
			)
			pose.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
			var destination := Vector2i(
				column * CELL_SIZE.x + int((CELL_SIZE.x - scaled_size.x) * 0.5),
				CELL_SIZE.y - scaled_size.y - 10
			)
			output.blit_rect(pose, Rect2i(Vector2i.ZERO, scaled_size), destination)
		var output_path := ProjectSettings.globalize_path(args[row + 1])
		var save_error := output.save_png(output_path)
		if save_error != OK:
			push_error("failed to save enemy roster row: %s" % args[row + 1])
			quit(4)
			return
		print("ENEMY_ROSTER_ROW_EXPORTED row=%d components=%d path=%s" % [row, components.size(), args[row + 1]])
	quit()


func _row_rect(source_size: Vector2i, row: int) -> Rect2i:
	var y0 := roundi(float(source_size.y) * row / ROWS)
	var y1 := roundi(float(source_size.y) * (row + 1) / ROWS)
	return Rect2i(0, y0, source_size.x, y1 - y0)


func _key_black_background(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a < ALPHA_THRESHOLD or maxf(pixel.r, maxf(pixel.g, pixel.b)) <= BLACK_KEY_THRESHOLD:
				pixel.a = 0.0
				image.set_pixel(x, y, pixel)


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
				minimum.x = mini(minimum.x, point.x)
				minimum.y = mini(minimum.y, point.y)
				maximum.x = maxi(maximum.x, point.x)
				maximum.y = maxi(maximum.y, point.y)
				for neighbor in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var next: Vector2i = point + neighbor
					if next.x < 0 or next.y < 0 or next.x >= size.x or next.y >= size.y:
						continue
					var next_index: int = next.y * size.x + next.x
					if visited[next_index] != 0 or image.get_pixelv(next).a < ALPHA_THRESHOLD:
						continue
					visited[next_index] = 1
					stack.append(next)
			if pixels.size() >= 90:
				components.append({"pixels": pixels, "minimum": minimum, "maximum": maximum})
	return components


func _component_image(source: Image, component: Dictionary) -> Image:
	var minimum: Vector2i = component.minimum
	var maximum: Vector2i = component.maximum
	var component_size := maximum - minimum + Vector2i.ONE
	var output := Image.create(component_size.x, component_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for pixel_index in component.pixels:
		var source_point := Vector2i(pixel_index % source.get_width(), pixel_index / source.get_width())
		output.set_pixelv(source_point - minimum, source.get_pixelv(source_point))
	return output
