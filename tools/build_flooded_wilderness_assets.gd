extends SceneTree

const BACKGROUND_COUNT := 3
const BACKGROUND_SIZE := Vector2i(1672, 941)
const BOSS_COLUMNS := 8
const BOSS_CELL_SIZE := Vector2i(320, 320)
const BOSS_CONTENT_LIMIT := Vector2i(294, 292)
const ALPHA_THRESHOLD := 0.08


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 6:
		push_error("usage: -- <background-atlas> <boss-source> <background-1> <background-2> <background-3> <boss-sheet>")
		quit(2)
		return
	var background_source := Image.load_from_file(ProjectSettings.globalize_path(args[0]))
	var boss_source := Image.load_from_file(ProjectSettings.globalize_path(args[1]))
	if background_source == null or boss_source == null:
		push_error("failed to load flooded-wilderness source art")
		quit(3)
		return
	for index in range(BACKGROUND_COUNT):
		var left := roundi(float(background_source.get_width()) * index / BACKGROUND_COUNT)
		var right := roundi(float(background_source.get_width()) * (index + 1) / BACKGROUND_COUNT)
		var panel := background_source.get_region(Rect2i(left, 0, right - left, background_source.get_height()))
		panel.resize(BACKGROUND_SIZE.x, BACKGROUND_SIZE.y, Image.INTERPOLATE_LANCZOS)
		if panel.save_png(ProjectSettings.globalize_path(args[index + 2])) != OK:
			push_error("failed to save background panel %d" % index)
			quit(4)
			return
	_build_boss_sheet(boss_source, args[5])
	print("FLOODED_WILDERNESS_ASSETS_EXPORTED backgrounds=%d boss_columns=%d" % [BACKGROUND_COUNT, BOSS_COLUMNS])
	quit()


func _build_boss_sheet(source: Image, output_path: String) -> void:
	source.convert(Image.FORMAT_RGBA8)
	var output := Image.create(BOSS_CELL_SIZE.x * BOSS_COLUMNS, BOSS_CELL_SIZE.y, false, Image.FORMAT_RGBA8)
	output.fill(Color.TRANSPARENT)
	var components := _extract_components(source)
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pixels.size() > b.pixels.size())
	if components.size() < BOSS_COLUMNS:
		push_error("boss source contains only %d isolated poses" % components.size())
		quit(5)
		return
	components.resize(BOSS_COLUMNS)
	components.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.minimum.x < b.minimum.x)
	for column in range(BOSS_COLUMNS):
		var pose := _component_image(source, components[column])
		var scale_factor := minf(
			float(BOSS_CONTENT_LIMIT.x) / float(pose.get_width()),
			float(BOSS_CONTENT_LIMIT.y) / float(pose.get_height())
		)
		var scaled_size := Vector2i(
			maxi(1, roundi(pose.get_width() * scale_factor)),
			maxi(1, roundi(pose.get_height() * scale_factor))
		)
		pose.resize(scaled_size.x, scaled_size.y, Image.INTERPOLATE_NEAREST)
		var destination := Vector2i(
			column * BOSS_CELL_SIZE.x + int((BOSS_CELL_SIZE.x - scaled_size.x) * 0.5),
			BOSS_CELL_SIZE.y - scaled_size.y - 8
		)
		output.blit_rect(pose, Rect2i(Vector2i.ZERO, scaled_size), destination)
	if output.save_png(ProjectSettings.globalize_path(output_path)) != OK:
		push_error("failed to save Mirewarden runtime sheet")
		quit(6)


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
