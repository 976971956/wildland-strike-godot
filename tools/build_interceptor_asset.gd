extends SceneTree

const SOURCE_PATH := "res://assets/sprites/desert_interceptor_source.png"
const OUTPUT_PATH := "res://assets/sprites/desert_interceptor_sheet.png"
const CELL_COUNT := 4
const OUTPUT_CELL := Vector2i(360, 240)


func _initialize() -> void:
	var source := Image.load_from_file(SOURCE_PATH)
	if source == null or source.is_empty():
		push_error("Unable to load %s" % SOURCE_PATH)
		quit(1)
		return
	var output := Image.create(OUTPUT_CELL.x * CELL_COUNT, OUTPUT_CELL.y, false, Image.FORMAT_RGBA8)
	output.fill(Color(0.0, 0.0, 0.0, 0.0))
	for index in range(CELL_COUNT):
		var start_x := floori(index * source.get_width() / float(CELL_COUNT))
		var end_x := floori((index + 1) * source.get_width() / float(CELL_COUNT))
		var cell := source.get_region(Rect2i(start_x, 165, end_x - start_x, 390))
		var bounds := _visible_bounds(cell)
		if bounds.size.x <= 0 or bounds.size.y <= 0:
			push_error("Desert Interceptor cell %d contains no visible pixels" % index)
			quit(2)
			return
		var isolated := cell.get_region(bounds)
		var scale_factor := minf(340.0 / isolated.get_width(), 216.0 / isolated.get_height())
		var target_size := Vector2i(maxi(1, roundi(isolated.get_width() * scale_factor)), maxi(1, roundi(isolated.get_height() * scale_factor)))
		isolated.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
		var destination := Vector2i(index * OUTPUT_CELL.x + (OUTPUT_CELL.x - target_size.x) / 2, OUTPUT_CELL.y - target_size.y - 8)
		output.blit_rect(isolated, Rect2i(Vector2i.ZERO, target_size), destination)
	var error := output.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Unable to save %s: %s" % [OUTPUT_PATH, error_string(error)])
		quit(3)
		return
	print("Built %s (%dx%d)" % [OUTPUT_PATH, output.get_width(), output.get_height()])
	quit(0)


func _visible_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.06:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
