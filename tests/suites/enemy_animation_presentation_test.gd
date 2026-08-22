extends RefCounted

const EnemyScript = preload("res://scripts/enemy.gd")
const DEFINITIONS := {
	"grunt": preload("res://data/enemies/grunt.tres"),
	"brute": preload("res://data/enemies/brute.tres"),
	"hunter": preload("res://data/enemies/hunter.tres"),
	"raptor": preload("res://data/enemies/raptor.tres"),
	"compy": preload("res://data/enemies/compy.tres"),
	"ankylosaur": preload("res://data/enemies/ankylosaur.tres"),
	"triceratops": preload("res://data/enemies/triceratops.tres"),
	"boss": preload("res://data/enemies/boss.tres"),
}


func run(test) -> void:
	for enemy_type in DEFINITIONS:
		var definition: Resource = DEFINITIONS[enemy_type]
		test.check(definition.sprite_columns == 8, "%s animation sheet is not eight columns" % enemy_type)
		test.check(definition.sprite_sheet.get_width() % 8 == 0, "%s sheet width is not evenly sliceable" % enemy_type)
		var source_image: Image = definition.sprite_sheet.get_image()
		test.check(source_image.detect_alpha() != Image.ALPHA_NONE, "%s sheet lost transparent alpha" % enemy_type)
	test.check(DEFINITIONS.grunt.sprite_sheet == DEFINITIONS.hunter.sprite_sheet, "raider and hunter variants no longer share one aligned sheet")
	test.check(DEFINITIONS.brute.sprite_sheet != DEFINITIONS.boss.sprite_sheet, "large enemies should use isolated sheets to prevent cell bleed")
	test.check(DEFINITIONS.grunt.sprite_rows == 1 and DEFINITIONS.brute.sprite_rows == 1 and DEFINITIONS.boss.sprite_rows == 1, "humanoid animation sheets are not isolated single rows")
	test.check(DEFINITIONS.raptor.sprite_rows == 1, "raptor sheet is no longer a single animation row")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	var enemy := EnemyScript.new()
	game.actors.add_child(enemy)
	enemy.setup(game, game.player, "grunt")
	enemy.visual_clock = 0.0
	test.check(enemy._visual_column() == 0, "enemy idle frame one drifted")
	enemy.visual_clock = 0.6
	test.check(enemy._visual_column() == 1, "enemy idle breathing frame drifted")
	enemy.velocity = Vector2(100.0, 0.0)
	enemy.walk_phase = 0.0
	test.check(enemy._visual_column() == 2, "enemy walk frame one drifted")
	enemy.walk_phase = 1.0
	test.check(enemy._visual_column() == 3, "enemy walk frame two drifted")
	enemy.velocity = Vector2.ZERO
	enemy.behavior_phase = EnemyScript.BehaviorPhase.TELEGRAPH
	test.check(enemy._visual_column() == 4, "enemy telegraph frame drifted")
	enemy.behavior_phase = EnemyScript.BehaviorPhase.BURST
	test.check(enemy._visual_column() == 5, "enemy burst frame drifted")
	enemy.behavior_phase = EnemyScript.BehaviorPhase.NEUTRAL
	enemy.attack_timer = enemy.current_attack.duration
	test.check(enemy._visual_column() == 4, "enemy attack windup frame drifted")
	enemy.attack_timer = enemy.current_attack.hit_trigger_remaining - 0.01
	test.check(enemy._visual_column() == 5, "enemy attack contact frame drifted")
	enemy.attack_timer = 0.0
	enemy.hurt_timer = 0.2
	test.check(enemy._visual_column() == 6, "enemy hurt frame drifted")
	enemy.hurt_timer = 0.0
	enemy.knockdown_state = true
	test.check(enemy._visual_column() == 7, "enemy knockdown frame drifted")
	enemy.knockdown_state = false
	enemy.is_defeated = true
	test.check(enemy._visual_column() == 7, "enemy defeated frame drifted")
	enemy.queue_free()
	await test.tree.process_frame

	for enemy_type in DEFINITIONS:
		var actor := EnemyScript.new()
		game.actors.add_child(actor)
		actor.setup(game, game.player, enemy_type)
		actor.visual_clock = 0.6
		var expected_idle_column := 1
		if actor.definition.dinosaur_archetype and not actor.definition.starts_sleeping:
			expected_idle_column = 0
		test.check(actor._visual_column() == expected_idle_column, "%s idle/sleep animation state drifted" % enemy_type)
		if actor.definition.dinosaur_archetype and actor.definition.starts_sleeping:
			actor._wake_creature()
		actor.velocity = Vector2(80.0, 0.0)
		actor.walk_phase = 1.0
		test.check(actor._visual_column() == 3, "%s did not use expanded movement animation" % enemy_type)
		actor.queue_free()
		await test.tree.process_frame
	await test.dispose(game)
