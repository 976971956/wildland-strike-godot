extends RefCounted

const HEROES := [
	preload("res://data/heroes/ranger.tres"),
	preload("res://data/heroes/mara.tres"),
	preload("res://data/heroes/kestrel.tres"),
	preload("res://data/heroes/atlas.tres"),
]


func run(test) -> void:
	for hero in HEROES:
		var texture: Texture2D = hero.sprite_sheet
		test.check(texture != null, "%s animation sheet is missing" % hero.hero_id)
		if texture == null:
			continue
		test.check(texture.get_width() == 1536 and texture.get_height() == 1024, "%s animation sheet is not 1536x1024" % hero.hero_id)
		test.check(hero.sprite_columns == 6 and hero.sprite_rows == 4, "%s animation grid is not 6x4" % hero.hero_id)
		var image: Image = texture.get_image()
		test.check(image != null and image.detect_alpha() != Image.ALPHA_NONE, "%s animation sheet lost alpha" % hero.hero_id)
		if image == null:
			continue
		test.check(image.get_pixel(0, 0).a < 0.02, "%s animation background is not transparent" % hero.hero_id)
		var cell_width: int = image.get_width() / hero.sprite_columns
		var cell_height: int = image.get_height() / hero.sprite_rows
		for row in range(hero.sprite_rows):
			for column in range(hero.sprite_columns):
				var stats := _frame_stats(image, Rect2i(column * cell_width, row * cell_height, cell_width, cell_height))
				var frame_label := "%s frame %d,%d" % [hero.hero_id, column, row]
				test.check(stats.opaque_samples >= 120, "%s has no readable character silhouette" % frame_label)
				test.check(stats.transparent_samples >= 3000, "%s lacks a clean transparent cell gutter" % frame_label)

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	for index in range(HEROES.size()):
		game.select_hero(index)
		game.player.apply_hero_definition(game.selected_hero())
		test.check(game.player.hero_sprite_sheet == HEROES[index].sprite_sheet, "%s sheet did not reach player rendering" % HEROES[index].hero_id)
		test.check(game.player.hero_sprite_columns == 6 and game.player.hero_sprite_rows == 4, "%s rendering grid drifted" % HEROES[index].hero_id)
	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(probe_source.contains("hero_animation_preview=atlas"), "reproducible Web hero-animation preview is missing")
	await test.dispose(game)


func _frame_stats(image: Image, rect: Rect2i) -> Dictionary:
	var opaque_samples := 0
	var transparent_samples := 0
	for y in range(rect.position.y + 2, rect.end.y - 2, 2):
		for x in range(rect.position.x + 2, rect.end.x - 2, 2):
			if image.get_pixel(x, y).a >= 0.25:
				opaque_samples += 1
			else:
				transparent_samples += 1
	return {"opaque_samples": opaque_samples, "transparent_samples": transparent_samples}
