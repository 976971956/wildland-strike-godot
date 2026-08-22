extends RefCounted

const SfxLibrary = preload("res://scripts/sfx_library.gd")
const MusicDirector = preload("res://scripts/music_director.gd")
const HudScript = preload("res://scripts/hud.gd")


func run(test) -> void:
	var event_names := SfxLibrary.event_names()
	test.check(event_names.size() >= 24, "final SFX library lost event coverage")
	test.check(SfxLibrary.has_event(&"hit") and SfxLibrary.has_event(&"heavy"), "core impact events are missing")
	test.check(SfxLibrary.has_event(&"gunshot") and SfxLibrary.has_event(&"explosion"), "weapon SFX events are missing")
	test.check(SfxLibrary.has_event(&"boss_warning") and SfxLibrary.has_event(&"boss_phase"), "boss SFX events are missing")

	for kind in event_names:
		var cfg := SfxLibrary.profile(kind)
		test.check(cfg.duration > 0.0 and cfg.frequency > 0.0, "%s SFX timing is invalid" % kind)
		test.check(cfg.priority >= 1 and cfg.priority <= 8, "%s SFX priority is invalid" % kind)
		test.check(cfg.volume_db <= 0.0 and cfg.volume_db >= -18.0, "%s SFX mix level is unsafe" % kind)

	var light_profile := SfxLibrary.profile(&"hit")
	var heavy_profile := SfxLibrary.profile(&"heavy")
	var explosion_profile := SfxLibrary.profile(&"explosion")
	test.check(heavy_profile.priority > SfxLibrary.profile(&"swing").priority, "heavy impacts no longer outrank swing voices")
	test.check(heavy_profile.volume_db > light_profile.volume_db, "heavy impact is not louder than light hit")
	test.check(explosion_profile.duck_db < heavy_profile.duck_db, "explosion does not own the strongest music space")

	var first_hit := SfxLibrary.build_stream(&"hit")
	var second_hit := SfxLibrary.build_stream(&"hit")
	var heavy_hit := SfxLibrary.build_stream(&"heavy")
	test.check(first_hit.mix_rate == SfxLibrary.SAMPLE_RATE, "SFX sample rate drifted")
	test.check(first_hit.data == second_hit.data, "procedural SFX generation is not deterministic")
	test.check(first_hit.data != heavy_hit.data, "light and heavy impacts share the same waveform")
	test.check(SfxLibrary.profile(&"missing_event").event == SfxLibrary.FALLBACK_EVENT, "unknown SFX did not use safe fallback")

	for folder in ["res://data/attacks", "res://data/weapons"]:
		for file_name in DirAccess.get_files_at(folder):
			if not file_name.ends_with(".tres"):
				continue
			var resource: Resource = load(folder.path_join(file_name))
			var event: StringName = resource.sound_event if folder.ends_with("attacks") else resource.fire_sfx
			test.check(SfxLibrary.has_event(event), "%s references unmixed SFX %s" % [file_name, event])

	var director := MusicDirector.new()
	test.tree.root.add_child(director)
	director.duck(-5.0, 0.16)
	test.check(director.last_duck_db == -5.0 and director.last_duck_duration == 0.16, "music duck request was not observable")
	director.duck(2.0, 1.0)
	test.check(director.last_duck_db == -5.0, "invalid positive duck changed the mix")
	director.queue_free()
	await test.tree.process_frame

	var desktop_dialogue := HudScript.dialogue_panel_rect(false)
	var touch_dialogue := HudScript.dialogue_panel_rect(true)
	test.check(touch_dialogue.position.y < desktop_dialogue.position.y, "touch dialogue was not lifted above controls")
	test.check(touch_dialogue.size.x < desktop_dialogue.size.x and touch_dialogue.size.x >= 540.0, "touch dialogue does not preserve a safe readable width")
	var wrapped_dialogue := HudScript.wrap_dialogue_line("SAFE AREA CONTROLS KEEP EVERY IMPORTANT ACTION INSIDE THE PLAYABLE DISPLAY")
	test.check(wrapped_dialogue.size() == 2 and wrapped_dialogue[0].length() <= 42, "touch dialogue did not wrap into two readable lines")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	test.check(game.hud.stage_area == 1 and game.hud.stage_area_total == 4, "HUD initial Stage 1 progress is incorrect")
	game._start_game()
	game.encounter_director.force_start_encounter(0)
	test.check(game.hud.arena_locked and game.hud.stage_hostiles > 0, "HUD did not expose active hostile count")
	game.play_sfx(&"heavy")
	test.check(game.music_director.last_duck_db == heavy_profile.duck_db, "heavy impact did not duck music by its profile")
	var game_source := FileAccess.get_file_as_string("res://scripts/game.gd")
	test.check(game_source.contains("_select_sfx_voice"), "SFX playback lost priority-aware voice allocation")
	test.check(game_source.contains("range(8)"), "SFX voice pool no longer supports dense encounters")
	var hud_source := FileAccess.get_file_as_string("res://scripts/hud.gd")
	test.check(hud_source.contains("HOSTILES") and hud_source.contains("ADVANCE"), "HUD objective states are not rendered")
	test.check(hud_source.contains("DANGER"), "critical-health warning is missing")
	await test.dispose(game)
