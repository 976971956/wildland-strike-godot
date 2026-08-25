extends RefCounted

const Localization = preload("res://core/localization/arcade_localization.gd")
const MusicDirector = preload("res://scripts/music_director.gd")
const SfxLibrary = preload("res://scripts/sfx_library.gd")
const ArcadeProfile = preload("res://core/persistence/arcade_profile.gd")
const ArcadeFont = preload("res://assets/fonts/NotoSansSC-Variable.ttf")


func run(test) -> void:
	test.check(ArcadeFont.has_char("中".unicode_at(0)) and ArcadeFont.has_char("W".unicode_at(0)), "bundled HUD font lacks Chinese or Latin glyph coverage")
	for language in ["en", "zh"]:
		for key in Localization.UI.en:
			test.check(not Localization.text(key, language).is_empty(), "%s UI text is missing %s" % [language, key])
	for shell_text in [
		"ARCADE SURVIVAL",
		"SELECT OPERATIVE",
		"AREA %d/%d",
		"CAMPAIGN COMPLETE",
		"HOW TO SURVIVE THE WILDLANDS",
		"WILDLAND CAMPAIGN ROUTE",
		"TAP / ENTER TO RESTART",
	]:
		test.check(Localization.content(shell_text, "zh") != shell_text, "shell text lacks Chinese translation: %s" % shell_text)

	var authored_content_count := 0
	for stage_number in range(1, 9):
		var stage: Resource = load("res://data/stages/stage_%d/stage_%d.tres" % [stage_number, stage_number])
		for value in [stage.display_name, stage.route_subtitle, stage.clear_message]:
			test.check(Localization.has_content_translation(value), "stage %d content lacks Chinese translation: %s" % [stage_number, value])
			authored_content_count += 1
		for scene: Resource in stage.scenes:
			for value in [scene.display_name, scene.transition_subtitle]:
				if String(value).is_empty():
					continue
				test.check(Localization.has_content_translation(value), "stage %d scene content lacks Chinese translation: %s" % [stage_number, value])
				authored_content_count += 1
			for encounter: Resource in scene.encounters:
				for value in [encounter.banner_title, encounter.banner_subtitle]:
					if String(value).is_empty():
						continue
					test.check(Localization.has_content_translation(value), "stage %d encounter content lacks Chinese translation: %s" % [stage_number, value])
					authored_content_count += 1
	for file_name in DirAccess.get_files_at("res://data/heroes"):
		if not file_name.ends_with(".tres"):
			continue
		var hero: Resource = load("res://data/heroes".path_join(file_name))
		for value in [hero.display_name, hero.role_title, hero.command_skill_name, hero.defensive_skill_name]:
			test.check(Localization.has_content_translation(value), "%s content lacks Chinese translation: %s" % [file_name, value])
			authored_content_count += 1
	for directory in ["res://data/weapons", "res://data/items"]:
		for file_name in DirAccess.get_files_at(directory):
			if not file_name.ends_with(".tres"):
				continue
			var definition: Resource = load(directory.path_join(file_name))
			test.check(Localization.has_content_translation(definition.display_name), "%s content lacks Chinese translation: %s" % [file_name, definition.display_name])
			authored_content_count += 1
	var vehicle: Resource = load("res://data/stages/stage_3/highway_vehicle.tres")
	test.check(Localization.has_content_translation(vehicle.display_name), "vehicle content lacks Chinese translation: %s" % vehicle.display_name)
	authored_content_count += 1
	test.check(authored_content_count >= 140, "campaign translation coverage did not traverse all authored display content")

	var translated_lines := 0
	for file_name in DirAccess.get_files_at("res://data/enemies"):
		if not file_name.ends_with(".tres"):
			continue
		var definition: Resource = load("res://data/enemies".path_join(file_name))
		if definition == null or not definition.is_boss:
			continue
		for phase: Resource in definition.boss_phases:
			test.check(Localization.has_content_translation(phase.dialogue_speaker), "%s phase %s speaker lacks Chinese translation" % [file_name, phase.phase_id])
			test.check(Localization.has_dialogue_translation(phase.dialogue_line), "%s phase %s lacks Chinese subtitles" % [file_name, phase.phase_id])
			test.check(Localization.dialogue(phase.dialogue_line, "zh") != phase.dialogue_line, "%s phase %s subtitle was not translated" % [file_name, phase.phase_id])
			translated_lines += 1
	test.check(translated_lines == 24, "boss subtitle catalog does not cover all 24 campaign phase lines")

	var profile = ArcadeProfile.new("")
	profile.load_profile()
	test.check(profile.CURRENT_VERSION >= 3 and profile.settings.subtitles, "versioned profile did not default subtitles on")
	profile.set_setting("language", "ZH")
	profile.set_setting("subtitles", false)
	test.check(profile.settings.language == "zh" and not profile.settings.subtitles, "language/subtitle preferences did not normalize")
	profile.set_setting("language", "unsupported")
	test.check(profile.settings.language == "en", "unsupported language did not fall back to English")

	var stage_hashes := {}
	var boss_hashes := {}
	for stage_index in range(8):
		var stage_track := MusicDirector.build_stream(MusicDirector.Cue.STAGE, stage_index)
		var boss_track := MusicDirector.build_stream(MusicDirector.Cue.BOSS, stage_index)
		test.check(stage_track.data.size() > 1000 and stage_track.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Stage %d music is not a playable loop" % (stage_index + 1))
		test.check(boss_track.data.size() > 1000 and boss_track.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Stage %d boss music is not a playable loop" % (stage_index + 1))
		stage_hashes[hash(stage_track.data)] = true
		boss_hashes[hash(boss_track.data)] = true
	test.check(stage_hashes.size() == 8, "campaign stages do not have eight distinct arrangements")
	test.check(boss_hashes.size() == 8, "campaign bosses do not have eight distinct arrangements")
	for cue in [MusicDirector.Cue.TITLE, MusicDirector.Cue.VICTORY, MusicDirector.Cue.ENDING, MusicDirector.Cue.CREDITS]:
		test.check(MusicDirector.build_stream(cue).data.size() > 1000, "shell cue %d is empty" % cue)

	var director := MusicDirector.new()
	test.tree.root.add_child(director)
	director.play_cue(MusicDirector.Cue.STAGE, 0)
	director.play_cue(MusicDirector.Cue.STAGE, 7)
	test.check(director.current_variant == 7 and director.variant_history == [0, 7], "same-cue stage arrangement changes were ignored")
	director.queue_free()
	await test.tree.process_frame

	for voice_event in [&"voice_hero", &"voice_boss", &"voice_creature"]:
		test.check(SfxLibrary.has_event(voice_event), "%s effort voice is absent" % voice_event)
		test.check(SfxLibrary.build_stream(voice_event).data.size() > 1000, "%s effort voice is empty" % voice_event)

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game.options_selected_index = 10
	game._adjust_option(1)
	test.check(game.settings.language == "zh" and game.hud.language == "zh", "language option did not update the HUD immediately")
	game.hud.show_dialogue("COMMANDER VOSS", "This district answers to me.", 3.0)
	test.check(game.hud.dialogue_line == "这片街区由我说了算。" and game.hud.dialogue_time > 0.0, "Chinese boss subtitle did not render")
	var wrapped_chinese: PackedStringArray = game.hud.wrap_dialogue_line("这是一条需要在手机字幕框内自动换行的中文测试文本", 8)
	test.check(wrapped_chinese.size() >= 3 and wrapped_chinese[0].length() <= 8, "Chinese touch subtitles did not wrap by character")
	game.options_selected_index = 9
	game._adjust_option(1)
	game.hud.show_dialogue("COMMANDER VOSS", "This district answers to me.", 3.0)
	test.check(not game.settings.subtitles and game.hud.dialogue_time == 0.0, "subtitle toggle did not suppress dialogue captions")
	test.check(game.music_director.current_cue == MusicDirector.Cue.TITLE, "title music was not active in the arcade shell")
	await test.dispose(game)
