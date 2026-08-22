extends RefCounted

const MusicDirectorScript = preload("res://scripts/music_director.gd")


func run(test) -> void:
	var stage_stream: AudioStreamWAV = MusicDirectorScript.build_stream(MusicDirectorScript.Cue.STAGE)
	var boss_stream: AudioStreamWAV = MusicDirectorScript.build_stream(MusicDirectorScript.Cue.BOSS)
	var victory_stream: AudioStreamWAV = MusicDirectorScript.build_stream(MusicDirectorScript.Cue.VICTORY)
	var silent_stream: AudioStreamWAV = MusicDirectorScript.build_stream(MusicDirectorScript.Cue.SILENT)
	test.check(stage_stream.mix_rate == MusicDirectorScript.SAMPLE_RATE, "stage music sample rate drifted")
	test.check(boss_stream.mix_rate == MusicDirectorScript.SAMPLE_RATE, "boss music sample rate drifted")
	test.check(victory_stream.mix_rate == MusicDirectorScript.SAMPLE_RATE, "victory music sample rate drifted")
	test.check(stage_stream.data.size() > 250000, "stage music loop is too short")
	test.check(boss_stream.data.size() > 250000, "boss music loop is too short")
	test.check(victory_stream.data.size() > 100000, "victory fanfare is too short")
	test.check(stage_stream.data.size() != boss_stream.data.size(), "stage and boss music share identical timing")
	test.check(stage_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "stage music does not loop")
	test.check(boss_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "boss music does not loop")
	test.check(victory_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "victory fanfare should not loop")
	test.check(silent_stream.data.size() == 2, "silent fallback stream drifted")
	test.check(is_equal_approx(MusicDirectorScript._midi_frequency(69), 440.0), "music pitch conversion drifted")

	var director := MusicDirectorScript.new()
	test.tree.root.add_child(director)
	director.play_cue(MusicDirectorScript.Cue.STAGE)
	director.play_cue(MusicDirectorScript.Cue.STAGE)
	director.play_cue(MusicDirectorScript.Cue.BOSS)
	test.check(director.current_cue == MusicDirectorScript.Cue.BOSS, "music director did not switch to boss cue")
	test.check(director.cue_history == [MusicDirectorScript.Cue.STAGE, MusicDirectorScript.Cue.BOSS], "music director repeated or lost cue transitions")
	director.queue_free()
	await test.tree.process_frame

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	test.check(game.music_director.current_cue == MusicDirectorScript.Cue.TITLE, "title screen did not begin its original theme")
	game._start_game()
	test.check(game.music_director.current_cue == MusicDirectorScript.Cue.STAGE, "starting Stage 1 did not begin stage music")
	game.encounter_director.force_start_encounter(3)
	test.check(game.music_director.current_cue == MusicDirectorScript.Cue.BOSS, "boss entrance did not switch music")

	game.score = 100
	game.hud.set_score(100)
	game.stage_time_remaining = 123.2
	game.lives = 2
	game._victory()
	test.check(game.state == "victory" and game.victory_phase == &"clear", "victory did not enter the clear announcement phase")
	test.check(game.victory_time_bonus == 1240, "time bonus did not round remaining seconds up")
	test.check(game.victory_life_bonus == 2000 and game.victory_clear_bonus == 5000, "life or clear bonus drifted")
	test.check(game.score == 100 and not game.victory_bonus_applied, "victory bonus applied before the clear announcement")
	test.check(game.hud.mode == "victory" and game.hud.victory_phase == &"clear", "HUD did not show clear announcement")
	test.check(game.music_director.current_cue == MusicDirectorScript.Cue.VICTORY, "victory did not switch to fanfare")

	game._tick_victory(1.6)
	test.check(game.victory_phase == &"bonus" and game.victory_bonus_applied, "victory did not enter bonus phase")
	test.check(game.score == 8340 and game.hud.victory_final_score == 8340, "victory bonuses did not update final score exactly once")
	test.check(game.sfx_event_history.has(&"bonus_tally"), "bonus phase lost tally cue")
	game._tick_victory(0.5)
	test.check(game.score == 8340, "victory bonus was applied more than once")
	game._tick_victory(1.9)
	test.check(game.victory_phase == &"complete" and game.hud.victory_phase == &"complete", "victory flow did not reach restart-ready phase")
	test.check(game.music_director.cue_history == [MusicDirectorScript.Cue.TITLE, MusicDirectorScript.Cue.STAGE, MusicDirectorScript.Cue.BOSS, MusicDirectorScript.Cue.VICTORY], "campaign music transition history drifted")
	await test.dispose(game)
