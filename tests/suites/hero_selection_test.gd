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
	var command_attack_ids := {}
	var special_attack_ids := {}
	var skill_profile_ids := {}
	for hero in HEROES:
		test.check(hero.is_valid_hero(), "%s hero definition is invalid" % hero.hero_id)
		test.check(not ids.has(hero.hero_id), "%s hero id is duplicated" % hero.hero_id)
		test.check(not names.has(hero.display_name), "%s hero name is duplicated" % hero.display_name)
		test.check(not roles.has(hero.role_title), "%s hero role is duplicated" % hero.role_title)
		ids[hero.hero_id] = true
		names[hero.display_name] = true
		roles[hero.role_title] = true
		stat_vectors[hero.stat_vector()] = true
		var has_skill_contract: bool = (
			"command_skill_name" in hero
			and "command_skill_summary" in hero
			and "command_attack" in hero
			and "defensive_skill_name" in hero
			and "defensive_skill_summary" in hero
			and "defensive_special" in hero
		)
		test.check(has_skill_contract, "%s has no authored command/special skill contract" % hero.hero_id)
		if has_skill_contract:
			var command_attack: Resource = hero.command_attack
			var defensive_special: Resource = hero.defensive_special
			test.check(not hero.command_skill_name.is_empty() and not hero.command_skill_summary.is_empty(), "%s command skill is not explained on character select" % hero.hero_id)
			test.check(not hero.defensive_skill_name.is_empty() and not hero.defensive_skill_summary.is_empty(), "%s defensive skill is not explained on character select" % hero.hero_id)
			test.check(command_attack != null and command_attack.is_valid_frame_data(), "%s command skill has invalid frame data" % hero.hero_id)
			test.check(defensive_special != null and defensive_special.is_valid_frame_data(), "%s defensive skill has invalid frame data" % hero.hero_id)
			if command_attack != null and defensive_special != null:
				test.check(not command_attack_ids.has(command_attack.attack_id), "%s reuses another hero's command attack" % hero.hero_id)
				test.check(not special_attack_ids.has(defensive_special.attack_id), "%s reuses another hero's defensive special" % hero.hero_id)
				command_attack_ids[command_attack.attack_id] = true
				special_attack_ids[defensive_special.attack_id] = true
				for attack in [command_attack, defensive_special]:
					var profile: Resource = attack.impact_profile
					test.check(profile != null and "burst_color" in profile and "impact_scale" in profile, "%s skill has no authored impact silhouette" % attack.attack_id)
					if profile != null and "burst_color" in profile:
						skill_profile_ids[profile.profile_id] = profile.burst_color
	test.check(stat_vectors.size() == 4, "hero stat profiles are not mechanically distinct")
	test.check(command_attack_ids.size() == 4 and special_attack_ids.size() == 4, "the four heroes do not own eight distinct skills")
	test.check(skill_profile_ids.size() == 8, "hero command/special impacts do not have eight distinct feedback profiles")
	test.check(HEROES[0].hero_id == &"ranger" and HEROES[0].max_health == 120, "Ranger baseline drifted")
	test.check(HEROES[1].item_efficiency == 1.5, "technician item advantage drifted")
	test.check(HEROES[2].move_speed == 290.0 and HEROES[2].aerial_control == 1.4, "scout mobility advantage drifted")
	test.check(HEROES[3].max_health == 150 and HEROES[3].grapple_power == 1.5, "grappler power advantage drifted")
	if "command_attack" in HEROES[1]:
		test.check(HEROES[1].command_attack.max_hits == 3 and HEROES[1].command_attack.hit_stun_bonus >= 0.16, "Mara lost her three-pulse control command")
		test.check(HEROES[2].command_attack.lunge_speed >= 460.0 and HEROES[2].command_attack.duration <= 0.42, "Kestrel lost her fast traversal command")
		test.check(HEROES[3].command_attack.damage >= 25 and HEROES[3].command_attack.knockback.x >= 700.0, "Atlas lost his single heavy command")
		test.check(HEROES[1].defensive_special.effect_radius >= 145.0, "Mara lost her wide control special")
		test.check(HEROES[2].defensive_special.self_damage <= 5 and HEROES[2].defensive_special.duration <= 0.46, "Kestrel lost her low-cost fast special")
		test.check(HEROES[3].defensive_special.damage >= 24 and HEROES[3].defensive_special.effect_radius >= 140.0, "Atlas lost his high-impact crowd special")
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
	test.check(game.state == "campaign_map" and game.hud.mode == "campaign_map", "hero confirmation did not open the campaign route")
	game._deploy_campaign_stage()
	test.check(game.state == "playing" and game.hud.mode == "playing", "campaign route did not deploy Stage 1")
	test.check(game.player.hero_id == &"kestrel" and game.player.hero_display_name == "KESTREL", "selected hero identity was not applied")
	test.check(game.player.max_health == 90 and game.player.health == 90, "selected hero vitality was not applied")
	test.check(game.player.move_speed == 290.0 and game.player.run_speed_multiplier == 1.8, "selected hero movement was not applied")
	test.check(game.player.damage_scale == 0.85 and game.player.aerial_control == 1.4, "selected hero combat profile was not applied")
	test.check(game.player.hero_sprite_sheet == HEROES[2].sprite_sheet, "selected hero animation sheet was not applied")
	if "command_attack_definition" in game.player and "special_attack_definition" in game.player:
		test.check(game.player.command_attack_definition == HEROES[2].command_attack, "selected hero command skill did not reach the fighter runtime")
		test.check(game.player.special_attack_definition == HEROES[2].defensive_special, "selected hero defensive special did not reach the fighter runtime")
	else:
		test.check(false, "fighter runtime has no per-hero skill definitions")
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
	game.player.weapon_hits = 0
	for hero in HEROES:
		game.player.apply_hero_definition(hero)
		game.player.attack_timer = 0.0
		game.player.special_timer = 0.0
		game.player.z_height = 0.0
		game.player._start_command_attack()
		test.check(game.player.current_attack == hero.command_attack, "%s command input selected another hero's skill" % hero.hero_id)
		game.player.attack_timer = 0.0
		game.player.special_timer = 0.0
		game.player._start_special()
		test.check(game.player.current_attack == hero.defensive_special, "%s defensive chord selected another hero's skill" % hero.hero_id)
		test.check(game.player.invulnerable == hero.defensive_special.invulnerable_duration, "%s defensive skill ignored its invulnerability plan" % hero.hero_id)
	game.player.health = health_before
	var touch_source := FileAccess.get_file_as_string("res://scripts/touch_controls.gd")
	test.check(touch_source.contains("game.state == \"select\""), "touch selection routing is missing")
	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(probe_source.contains("hero_select_preview=1"), "reproducible Web hero-select preview is missing")
	test.check(probe_source.contains("hero_command_preview=") and probe_source.contains("_start_hero_skill_preview"), "reproducible per-hero command-skill Web preview is missing")
	test.check(probe_source.contains("hero_special_preview=") and probe_source.contains("A+B DEFENSIVE SPECIAL"), "reproducible per-hero defensive-skill Web preview is missing")
	await test.dispose(game)
