extends SceneTree

const CELL_COUNT := 8
const CELL_SIZE := Vector2i(320, 320)
const CONTENT_LIMIT := Vector2i(300, 296)
const CART_SIZE := Vector2i(256, 160)
const CART_CONTENT_LIMIT := Vector2i(242, 148)
const ALPHA_THRESHOLD := 0.08


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 4:
		push_error("usage: -- <titan-warden-source> <titan-warden-sheet> <mine-cart-source> <mine-cart-sprite>")
		quit(2)
		return
	var source := Image.load_from_file(ProjectSettings.globalize_path(args[0]))
	if source == null or source.is_empty():
		push_error("unable to load Titan Warden source")
		quit(3)
		return
	source.convert(Image.FORMAT_RGBA8)
	_clear_checker_background(source)
	var cuts: Array[int] = [0]
	for boundary in range(1, CELL_COUNT):
		cuts.append(_best_vertical_cut(source, roundi(float(boundary) * source.get_width() / CELL_COUNT), 54))
	cuts.append(source.get_width())
	var poses: Array[Image] = []
	var largest_size := Vector2i.ONE
	for index in range(CELL_COUNT):
		var pose := _trim_cell(source.get_region(Rect2i(cuts[index], 0, cuts[index + 1] - cuts[index], source.get_height())))
		if pose == null or pose.is_empty():
			push_error("Titan Warden pose %d is empty" % index)
			quit(4)
			return
		poses.append(pose)
		largest_size.x = maxi(largest_size.x, pose.get_width())
		largest_size.y = maxi(largest_size.y, pose.get_height())
	var scale_factor := minf(float(CONTENT_LIMIT.x) / largest_size.x, float(CONTENT_LIMIT.y) / largest_size.y)
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
		push_error("unable to save Titan Warden sheet: %s" % error_string(error))
		quit(5)
		return
	var cart_source := Image.load_from_file(ProjectSettings.globalize_path(args[2]))
	if cart_source == null or cart_source.is_empty():
		push_error("unable to load jungle mine cart source")
		quit(6)
		return
	cart_source.convert(Image.FORMAT_RGBA8)
	_clear_checker_background(cart_source)
	var cart_pose := _trim_cell(cart_source)
	if cart_pose == null or cart_pose.is_empty():
		push_error("jungle mine cart source contains no isolated cart")
		quit(7)
		return
	var cart_scale := minf(float(CART_CONTENT_LIMIT.x) / cart_pose.get_width(), float(CART_CONTENT_LIMIT.y) / cart_pose.get_height())
	var cart_target := Vector2i(maxi(1, roundi(cart_pose.get_width() * cart_scale)), maxi(1, roundi(cart_pose.get_height() * cart_scale)))
	cart_pose.resize(cart_target.x, cart_target.y, Image.INTERPOLATE_NEAREST)
	var cart_output := Image.create(CART_SIZE.x, CART_SIZE.y, false, Image.FORMAT_RGBA8)
	cart_output.fill(Color.TRANSPARENT)
	var cart_destination := Vector2i(int((CART_SIZE.x - cart_target.x) * 0.5), CART_SIZE.y - cart_target.y - 4)
	cart_output.blit_rect(cart_pose, Rect2i(Vector2i.ZERO, cart_target), cart_destination)
	error = cart_output.save_png(ProjectSettings.globalize_path(args[3]))
	if error != OK:
		push_error("unable to save jungle mine cart sprite: %s" % error_string(error))
		quit(8)
		return
	print("JUNGLE_MINE_ASSETS_EXPORTED boss_columns=%d boss_size=%dx%d cart_size=%dx%d" % [CELL_COUNT, output.get_width(), output.get_height(), cart_output.get_width(), cart_output.get_height()])
	quit()


func _best_vertical_cut(image: Image, approximate: int, radius: int) -> int:
	var best_x := approximate
	var best_count := image.get_height() + 1
	for x in range(maxi(1, approximate - radius), mini(image.get_width() - 1, approximate + radius + 1)):
		var count := 0
		for y in range(image.get_height()):
			if image.get_pixel(x, y).a >= ALPHA_THRESHOLD:
				count += 1
		if count < best_count:
			best_count = count
			best_x = x
	return best_x


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


func _clear_checker_background(image: Image) -> void:
	var size := image.get_size()
	for y in range(size.y):
		for x in range(size.x):
			var color := image.get_pixel(x, y)
			var brightest := maxf(color.r, maxf(color.g, color.b))
			var darkest := minf(color.r, minf(color.g, color.b))
			if darkest > 0.72 and brightest - darkest < 0.12:
				image.set_pixel(x, y, Color.TRANSPARENT)
