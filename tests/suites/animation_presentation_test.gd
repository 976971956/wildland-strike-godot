extends RefCounted

const PlayerScript = preload("res://scripts/player.gd")
const StageAmbienceScript = preload("res://scripts/stage_ambience.gd")
const STAGE_1 = preload("res://data/stages/stage_1/stage_1.tres")
const COMBO_1 = preload("res://data/attacks/player_combo_1.tres")
const RUN_ATTACK = preload("res://data/attacks/player_run.tres")
const APEX_ATTACK = preload("res://data/attacks/player_apex.tres")
const DIVE_ATTACK = preload("res://data/attacks/player_dive.tres")
const MACHETE = preload("res://data/weapons/machete.tres")
const PISTOL = preload("res://data/weapons/pistol.tres")


func run(test) -> void:
	test.check(PlayerScript.SPRITE_COLUMNS == 6 and PlayerScript.SPRITE_ROWS == 4, "Ranger sheet grid is not 6x4")
	test.check(PlayerScript.SPRITE_SHEET.get_width() == 1536, "Ranger sheet width drifted")
	test.check(PlayerScript.SPRITE_SHEET.get_height() == 1024, "Ranger sheet height drifted")
	var source_image: Image = PlayerScript.SPRITE_SHEET.get_image()
	test.check(source_image != null and source_image.detect_alpha() != Image.ALPHA_NONE, "Ranger sheet lost transparent alpha")

	var player := PlayerScript.new()
	test.check(player._visual_frame() == Vector2i(0, 0), "idle frame mapping drifted")
	player.visual_clock = 0.6
	test.check(player._visual_frame() == Vector2i(1, 0), "idle breathing frame is not animated")
	player.velocity = Vector2(100.0, 0.0)
	player.walk_phase = 0.0
	test.check(player._visual_frame() == Vector2i(2, 0), "walk cycle start frame drifted")
	player.walk_phase = 3.0
	test.check(player._visual_frame() == Vector2i(5, 0), "walk cycle does not use all four movement frames")
	player.velocity = Vector2.ZERO
	player.attack_timer = 0.3
	player.current_attack = COMBO_1
	player.combo_step = 1
	test.check(player._visual_frame() == Vector2i(0, 1), "jab startup frame drifted")
	player.attack_timer = 0.1
	test.check(player._visual_frame() == Vector2i(1, 1), "jab contact frame drifted")
	player.current_attack = RUN_ATTACK
	test.check(player._visual_frame() == Vector2i(4, 1), "running attack frame drifted")
	player.special_timer = 0.2
	test.check(player._visual_frame() == Vector2i(5, 1), "defensive special frame drifted")
	player.special_timer = 0.0
	player.attack_timer = 0.2
	player.current_attack = APEX_ATTACK
	player.z_height = 60.0
	test.check(player._visual_frame() == Vector2i(1, 2), "airborne kick frame drifted")
	player.current_attack = DIVE_ATTACK
	test.check(player._visual_frame() == Vector2i(2, 2), "dive kick frame drifted")
	player.z_height = 0.0
	player.hurt_timer = 0.2
	test.check(player._visual_frame() == Vector2i(4, 2), "hurt recoil frame drifted")
	player.hurt_timer = 0.0
	player.is_defeated = true
	test.check(player._visual_frame() == Vector2i(0, 3), "defeated ground frame drifted")
	player.is_defeated = false
	player.attack_timer = 0.2
	player.current_attack = COMBO_1
	player.equipped_weapon = MACHETE
	player.weapon_ammo = 3
	test.check(player._visual_frame() == Vector2i(0, 1), "machete startup reused the hero sheet's baked duplicate weapon frame")
	player.equipped_weapon = PISTOL
	player.weapon_ammo = 4
	player.attack_timer = 0.1
	test.check(player._visual_frame() == Vector2i(1, 1), "pistol contact reused the hero sheet's baked duplicate firearm frame")
	player.attack_timer = 0.0
	player.weapon_ammo = 0
	player.equipped_weapon = null
	player.set_victory_pose(1)
	test.check(player._visual_frame() == Vector2i(4, 3), "victory pose one drifted")
	player.set_victory_pose(2)
	test.check(player._visual_frame() == Vector2i(5, 3), "victory pose two drifted")
	player.free()

	var ambience := StageAmbienceScript.new()
	ambience.configure(STAGE_1.scenes)
	test.check(ambience.scenes.size() == 3, "Stage 1 ambience did not receive all scenes")
	var ruins_zero: Dictionary = ambience.ambience_signature(0, 0.0)
	var ruins_later: Dictionary = ambience.ambience_signature(0, 0.75)
	test.check(ruins_zero.scene_id == &"ruined_avenue", "ruins ambience identity drifted")
	test.check(ruins_zero.pulse != ruins_later.pulse and ruins_zero.drift != ruins_later.drift, "ruins ambience is not time-varying")
	test.check(ambience.ambience_signature(1, 0.0).scene_id == &"flooded_courtyard", "courtyard ambience identity drifted")
	test.check(ambience.ambience_signature(2, 0.0).scene_id == &"processing_plant", "plant ambience identity drifted")
	test.check(ambience.ambience_signature(3, 0.0).is_empty(), "invalid ambience scene did not return empty signature")
	ambience.free()

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.stage_time_remaining = 10.2
	game.lives = 1
	game._victory()
	test.check(game.player.victory_pose_phase == 1, "victory did not activate Ranger pose one")
	game._tick_victory(1.6)
	game._tick_victory(2.4)
	test.check(game.player.victory_pose_phase == 2, "settlement completion did not activate Ranger pose two")
	test.check(is_instance_valid(game.world_art.ambience), "world art did not install its animated ambience layer")
	await test.dispose(game)
