extends SceneTree

const CELL_COUNT := 8
const CELL_SIZE := Vector2i(320, 320)
const CONTENT_LIMIT := Vector2i(296, 292)
const ALPHA_THRESHOLD := 0.08


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("usage: -- <forge-regent-source> <forge-regent-sheet>")
		quit(2)
		return
	var source := Image.load_from_file(ProjectSettings.globalize_path(args[0]))
	if source == null or source.is_empty():
		push_error("unable to load Forge Regent source")
		quit(3)
		return
	source.convert(Image.FORMAT_RGBA8)
	var components := _extract_components(source)
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pixels.size() > b.pixels.size())
	if components.size() < CELL_COUNT:
		push_error("Forge Regent source contains only %d isolated poses" % components.size())
		quit(4)
		return
	components.resize(CELL_COUNT)
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.minimum.x < b.minimum.x)
	var poses: Array[Image] = []
	var largest_size := Vector2i.ONE
	for component in components:
		var pose := _component_image(source, component)
		poses.append(pose)
		largest_size.x = maxi(largest_size.x, pose.get_width())
		largest_size.y = maxi(largest_size.y, pose.get_height())
	var scale_factor := minf(
		float(CONTENT_LIMIT.x) / float(largest_size.x),
		float(CONTENT_LIMIT.y) / float(largest_size.y)
	)
	var output := Image.create(CELL_SIZE.x * CELL_COUNT, CELL_SIZE.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	for index in range(CELL_COUNT):
		var pose := poses[index]
		var target_size := Vector2i(
			maxi(1, roundi(pose.get_width() * scale_factor)),
			maxi(1, roundi(pose.get_height() * scale_factor))
		)
		pose.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
		var destination := Vector2i(
			index * CELL_SIZE.x + int((CELL_SIZE.x - target_size.x) * 0.5),
			CELL_SIZE.y - target_size.y - 8
		)
		output.blit_rect(pose, Rect2i(Vector2i.ZERO, target_size), destination)
	var error := output.save_png(ProjectSettings.globalize_path(args[1]))
	if error != OK:
		push_error("unable to save Forge Regent sheet: %s" % error_string(error))
		quit(5)
		return
	print("INDUSTRIAL_ASSETS_EXPORTED boss_columns=%d size=%dx%d" % [CELL_COUNT, output.get_width(), output.get_height()])
	quit()


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
