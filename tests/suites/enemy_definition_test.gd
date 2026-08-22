extends RefCounted

const EnemyDefinitionScript = preload("res://core/combat/enemy_definition.gd")
const DEFINITIONS := [
	preload("res://data/enemies/grunt.tres"),
	preload("res://data/enemies/brute.tres"),
	preload("res://data/enemies/raptor.tres"),
	preload("res://data/enemies/hunter.tres"),
	preload("res://data/enemies/boss.tres"),
	preload("res://data/enemies/compy.tres"),
	preload("res://data/enemies/ankylosaur.tres"),
	preload("res://data/enemies/triceratops.tres"),
	preload("res://data/enemies/knife_raider.tres"),
	preload("res://data/enemies/demolitionist.tres"),
	preload("res://data/enemies/shield_guard.tres"),
	preload("res://data/enemies/elite_enforcer.tres"),
	preload("res://data/enemies/elite_blade.tres"),
	preload("res://data/enemies/elite_bombardier.tres"),
	preload("res://data/enemies/elite_bulwark.tres"),
]


func run(test) -> void:
	var ids := {}
	for definition in DEFINITIONS:
		test.check(definition != null, "enemy definition failed to load")
		test.check(definition.is_valid_definition(), "%s definition is invalid" % definition.enemy_id)
		test.check(not ids.has(definition.enemy_id), "%s is a duplicate enemy id" % definition.enemy_id)
		ids[definition.enemy_id] = true

	var grunt = DEFINITIONS[0]
	var brute = DEFINITIONS[1]
	var raptor = DEFINITIONS[2]
	var hunter = DEFINITIONS[3]
	var boss = DEFINITIONS[4]
	test.check(grunt.max_health == 42 and grunt.speed == 115.0 and grunt.defeat_score == 250, "grunt stats drifted")
	test.check(brute.max_health == 78 and brute.speed == 82.0 and brute.defeat_score == 500, "brute stats drifted")
	test.check(raptor.max_health == 58 and raptor.speed == 152.0 and raptor.defeat_score == 650, "raptor stats drifted")
	test.check(hunter.max_health == 50 and hunter.speed == 98.0 and hunter.defeat_score == 450, "hunter stats drifted")
	test.check(boss.max_health == 260 and boss.speed == 105.0 and boss.defeat_score == 2000, "boss stats drifted")
	test.check(grunt.can_be_grabbed and brute.can_be_grabbed, "humanoid grab rules drifted")
	test.check(not raptor.can_be_grabbed and not boss.can_be_grabbed, "raptor or boss grab immunity drifted")
	test.check(brute.show_health_bar and brute.body_scale == 1.12, "brute presentation data drifted")
	test.check(boss.is_boss and boss.actor_scale == Vector2(1.25, 1.25), "boss presentation data drifted")
	test.check(boss.behavior_kind == EnemyDefinitionScript.BehaviorKind.BOSS, "boss lost its unique behavior kind")
	test.check(boss.boss_phases.size() == 2, "boss phase definition count drifted")
	test.check(raptor.visual_kind == EnemyDefinitionScript.VisualKind.RAPTOR, "raptor visual kind drifted")
	test.check(raptor.faction == EnemyDefinitionScript.Faction.NEUTRAL_CREATURE, "raptor neutral faction drifted")
	test.check(grunt.faction == EnemyDefinitionScript.Faction.HUMAN_ENEMY, "human enemy faction drifted")
	test.check(hunter.behavior_kind == EnemyDefinitionScript.BehaviorKind.RANGED and hunter.ranged_weapon != null, "hunter ranged definition drifted")
	test.check(raptor.target_size == Vector2(222, 322), "raptor sprite layout drifted")
	var invalid_definition = EnemyDefinitionScript.new()
	test.check(not invalid_definition.is_valid_definition(), "empty enemy definition should be invalid")

	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemy.gd")
	test.check(not enemy_source.contains("if p_type"), "enemy setup still branches on type")
	test.check(not enemy_source.contains("enemy_type =="), "enemy behavior still branches on type")
	test.check(not enemy_source.contains("enemy_type !="), "enemy behavior still branches on type")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.position = Vector2(500.0, 540.0)
	await test.wait_physics_frames(2)
	var spawned: Array[Node] = test.tree.get_nodes_in_group("enemies")
	test.check(spawned.size() == 3, "enemy-definition fixture failed to spawn first wave")
	for enemy in spawned:
		enemy.set_physics_process(false)
		test.check(enemy.definition != null and enemy.definition.enemy_id == enemy.enemy_type, "spawned enemy lost its definition")
		test.check(enemy.max_health == enemy.definition.max_health, "spawned enemy ignored definition health")
		test.check(enemy.speed == enemy.definition.speed, "spawned enemy ignored definition speed")
		test.check(enemy.current_attack == enemy.definition.attack, "spawned enemy ignored definition attack")

	game.spawn_enemy(Vector2(1200.0, 540.0), "brute")
	game.spawn_enemy(Vector2(1300.0, 540.0), "boss")
	game.spawn_enemy(Vector2(1400.0, 540.0), "unknown")
	game.spawn_enemy(Vector2(1500.0, 540.0), "hunter")
	var brute_enemy: Node = null
	var boss_enemy: Node = null
	var fallback_enemy: Node = null
	var hunter_enemy: Node = null
	for enemy in test.tree.get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
		if enemy.position.x == 1200.0:
			brute_enemy = enemy
		elif enemy.position.x == 1300.0:
			boss_enemy = enemy
		elif enemy.position.x == 1400.0:
			fallback_enemy = enemy
		elif enemy.position.x == 1500.0:
			hunter_enemy = enemy
	test.check(brute_enemy != null and brute_enemy.definition == brute, "brute did not resolve its typed definition")
	test.check(boss_enemy != null and boss_enemy.definition == boss, "boss did not resolve its typed definition")
	test.check(fallback_enemy != null and fallback_enemy.definition == grunt, "unknown enemy did not use the safe grunt definition")
	test.check(hunter_enemy != null and hunter_enemy.definition == hunter, "hunter did not resolve its typed definition")
	if brute_enemy != null:
		var score_before: int = game.score
		brute_enemy.take_hit(999, Vector2.ZERO, true)
		test.check(game.score == score_before + brute.defeat_score, "defeat score did not come from enemy definition")
	if boss_enemy != null:
		test.check(not boss_enemy.can_be_grabbed(), "boss ignored definition grab immunity")
	await test.dispose(game)
