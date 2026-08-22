extends RefCounted

const HeroDefinitionScript = preload("res://core/fighters/hero_definition.gd")
const HEROES := [
	preload("res://data/heroes/ranger.tres"),
	preload("res://data/heroes/mara.tres"),
	preload("res://data/heroes/kestrel.tres"),
	preload("res://data/heroes/atlas.tres"),
]


func run(test) -> void:
	test.check(HEROES.size() == 4, "M4 hero roster no longer contains four operatives")
	var ids := {}
	var names := {}
	var roles := {}
	var stat_vectors := {}
	for hero in HEROES:
		test.check(hero.is_valid_hero(), "%s hero definition is invalid" % hero.hero_id)
		test.check(not ids.has(hero.hero_id), "%s hero id is duplicated" % hero.hero_id)
		test.check(not names.has(hero.display_name), "%s hero name is duplicated" % hero.display_name)
		test.check(not roles.has(hero.role_title), "%s hero role is duplicated" % hero.role_title)
		ids[hero.hero_id] = true
		names[hero.display_name] = true
		roles[hero.role_title] = true
		stat_vectors[hero.stat_vector()] = true
	test.check(stat_vectors.size() == 4, "hero stat profiles are not mechanically distinct")
	test.check(HEROES[0].hero_id == &"ranger" and HEROES[0].max_health == 120, "Ranger baseline drifted")
	test.check(HEROES[1].item_efficiency == 1.5, "technician item advantage drifted")
	test.check(HEROES[2].move_speed == 290.0 and HEROES[2].aerial_control == 1.4, "scout mobility advantage drifted")
	test.check(HEROES[3].max_health == 150 and HEROES[3].grapple_power == 1.5, "grappler power advantage drifted")
	test.check(not HeroDefinitionScript.new().is_valid_hero(), "empty hero definition should be invalid")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	test.check(game.HERO_DEFINITIONS.size() == 4, "game did not expose the four-hero roster")
	test.check(game.selected_hero().hero_id == &"ranger", "new game did not default to Ranger")
	test.check(game.player.hero_id == &"ranger" and game.player.max_health == 120, "Ranger did not initialize through hero data")
	game._open_character_select()
	test.check(game.state == "select" and game.hud.mode == "select", "title did not enter character select")
	test.check(game.hud.hero_roster.size() == 4 and game.hud.selected_hero_index == 0, "HUD character roster did not initialize")
	game.shift_hero_selection(-1)
	test.check(game.selected_hero().hero_id == &"atlas", "left selection did not wrap to Atlas")
	game.shift_hero_selection(1)
	test.check(game.selected_hero().hero_id == &"ranger", "right selection did not wrap to Ranger")
	game.select_hero(2)
	test.check(game.hud.selected_hero_index == 2 and game.selected_hero().hero_id == &"kestrel", "selection did not update HUD and model together")
	game.confirm_hero_selection()
	test.check(game.state == "playing" and game.hud.mode == "playing", "hero confirmation did not start Stage 1")
	test.check(game.player.hero_id == &"kestrel" and game.player.hero_display_name == "KESTREL", "selected hero identity was not applied")
	test.check(game.player.max_health == 90 and game.player.health == 90, "selected hero vitality was not applied")
	test.check(game.player.move_speed == 290.0 and game.player.run_speed_multiplier == 1.8, "selected hero movement was not applied")
	test.check(game.player.damage_scale == 0.85 and game.player.aerial_control == 1.4, "selected hero combat profile was not applied")
	test.check(game.hud.player_name == "KESTREL" and game.hud.max_health == 90, "selected hero identity/health did not reach HUD")
	var health_before: int = game.player.health
	game.player.health = 40
	game.player.heal(20)
	test.check(game.player.health == 58, "Kestrel item-efficiency penalty was not applied")
	game.select_hero(3)
	game.player.apply_hero_definition(game.selected_hero())
	game.player.health = 80
	game.player.heal(20)
	test.check(game.player.health == 96, "Atlas item-efficiency penalty was not applied")
	test.check(game.player._scaled_damage(12) == 16, "Atlas damage advantage was not applied")
	test.check(game.player._scaled_grapple_damage(30) == 59, "Atlas grapple advantage was not applied")
	game.player.give_weapon("weapon_melee")
	test.check(game.player.weapon_ammo == 10, "Atlas weapon-capacity penalty was not applied")
	game.player.health = health_before
	var touch_source := FileAccess.get_file_as_string("res://scripts/touch_controls.gd")
	test.check(touch_source.contains("game.state == \"select\""), "touch selection routing is missing")
	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(probe_source.contains("hero_select_preview=1"), "reproducible Web hero-select preview is missing")
	await test.dispose(game)
