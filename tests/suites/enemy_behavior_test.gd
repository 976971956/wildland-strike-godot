extends RefCounted

const StreetEnemyScript = preload("res://scripts/enemy.gd")
const EnemyDefinitionScript = preload("res://core/combat/enemy_definition.gd")
const GRUNT = preload("res://data/enemies/grunt.tres")
const BRUTE = preload("res://data/enemies/brute.tres")
const RAPTOR = preload("res://data/enemies/raptor.tres")
const HUNTER = preload("res://data/enemies/hunter.tres")


func run(test) -> void:
	test.check(GRUNT.behavior_kind == EnemyDefinitionScript.BehaviorKind.FLANKER, "grunt lost flanker behavior")
	test.check(BRUTE.behavior_kind == EnemyDefinitionScript.BehaviorKind.CHARGER, "brute lost charger behavior")
	test.check(RAPTOR.behavior_kind == EnemyDefinitionScript.BehaviorKind.POUNCER, "raptor lost pouncer behavior")
	test.check(HUNTER.behavior_kind == EnemyDefinitionScript.BehaviorKind.RANGED, "hunter lost ranged behavior")
	var behavior_kinds := {
		GRUNT.behavior_kind: true,
		BRUTE.behavior_kind: true,
		RAPTOR.behavior_kind: true,
		HUNTER.behavior_kind: true,
	}
	test.check(behavior_kinds.size() == 4, "Stage 1 enemy types do not have distinct behaviors")
	test.check(BRUTE.telegraph_duration > RAPTOR.telegraph_duration, "brute charge should telegraph longer than raptor pounce")
	test.check(RAPTOR.burst_speed_scale > BRUTE.burst_speed_scale, "raptor pounce should be faster than brute charge")
	test.check(RAPTOR.retreat_distance > RAPTOR.attack_distance, "raptor retreat band is invalid")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game.set_process(false)
	game.player.set_physics_process(false)
	game._start_game()
	game.player.position = Vector2(500.0, 540.0)

	var grunt: Node = _spawn_frozen(game, Vector2(760.0, 610.0), "grunt")
	grunt._think(1.0 / 60.0)
	test.check(grunt.behavior_phase == StreetEnemyScript.BehaviorPhase.NEUTRAL, "grunt should stay in continuous flanker movement")
	test.check(grunt.velocity.x < 0.0 and grunt.velocity.y < 0.0, "grunt did not close distance on an offset lane")
	test.check(grunt.velocity.length() <= GRUNT.speed + 0.01, "grunt flanker exceeded configured speed")

	var brute: Node = _spawn_frozen(game, Vector2(820.0, 540.0), "brute")
	brute._think(1.0 / 60.0)
	test.check(brute.behavior_phase == StreetEnemyScript.BehaviorPhase.TELEGRAPH, "brute did not enter charge telegraph")
	test.check(brute.last_behavior_event == &"charge_telegraph", "brute charge telegraph event was not observable")
	test.check(brute.velocity == Vector2.ZERO, "brute moved during charge telegraph")
	brute._think(BRUTE.telegraph_duration + 0.01)
	test.check(brute.behavior_phase == StreetEnemyScript.BehaviorPhase.BURST, "brute did not transition from telegraph to charge")
	test.check(is_equal_approx(brute.velocity.length(), BRUTE.speed * BRUTE.burst_speed_scale), "brute charge ignored burst speed")
	test.check(is_zero_approx(brute.velocity.y), "brute charge should stay on a straight lane")
	brute._think(BRUTE.burst_duration + 0.01)
	test.check(brute.behavior_phase == StreetEnemyScript.BehaviorPhase.RECOVER, "brute charge did not enter recovery")
	test.check(brute.velocity == Vector2.ZERO, "brute moved during charge recovery")
	brute._think(BRUTE.recovery_duration + 0.01)
	test.check(brute.behavior_phase == StreetEnemyScript.BehaviorPhase.NEUTRAL, "brute did not leave charge recovery")
	test.check(brute.behavior_cooldown_timer > 0.0, "brute charge did not start its cooldown")

	var raptor: Node = _spawn_frozen(game, Vector2(760.0, 585.0), "raptor")
	raptor._think(1.0 / 60.0)
	test.check(raptor.behavior_phase == StreetEnemyScript.BehaviorPhase.TELEGRAPH, "raptor did not enter pounce telegraph")
	test.check(raptor.last_behavior_event == &"pounce_telegraph", "raptor pounce telegraph event was not observable")
	raptor._think(RAPTOR.telegraph_duration + 0.01)
	test.check(raptor.behavior_phase == StreetEnemyScript.BehaviorPhase.BURST, "raptor did not transition from telegraph to pounce")
	test.check(is_equal_approx(raptor.velocity.length(), RAPTOR.speed * RAPTOR.burst_speed_scale), "raptor pounce ignored burst speed")
	test.check(not is_zero_approx(raptor.velocity.y), "raptor pounce did not track the player's depth lane")
	raptor._cancel_behavior()
	raptor.behavior_cooldown_timer = 0.0
	raptor.position = Vector2(590.0, 540.0)
	raptor._think(1.0 / 60.0)
	test.check(raptor.behavior_phase == StreetEnemyScript.BehaviorPhase.EVADE, "cornered raptor did not retreat")
	test.check(raptor.last_behavior_event == &"retreat", "raptor retreat event was not observable")
	test.check(raptor.velocity.x > 0.0 and not is_zero_approx(raptor.velocity.y), "raptor retreat did not break away diagonally")
	raptor._think(RAPTOR.retreat_duration + 0.01)
	test.check(raptor.behavior_phase == StreetEnemyScript.BehaviorPhase.RECOVER, "raptor retreat did not enter recovery")

	var hunter: Node = _spawn_frozen(game, Vector2(840.0, 540.0), "hunter")
	hunter._think(1.0 / 60.0)
	test.check(hunter.behavior_phase == StreetEnemyScript.BehaviorPhase.TELEGRAPH, "hunter did not enter ranged aim")
	test.check(hunter.last_behavior_event == &"ranged_aim", "hunter ranged aim event was not observable")
	test.check(hunter.velocity == Vector2.ZERO, "hunter moved during ranged aim")
	hunter._think(HUNTER.telegraph_duration + 0.01)
	var projectiles: Array[Node] = test.tree.get_nodes_in_group("weapon_projectiles")
	test.check(projectiles.size() == 1, "hunter did not fire one configured projectile")
	test.check(hunter.behavior_phase == StreetEnemyScript.BehaviorPhase.RECOVER, "hunter did not enter shot recovery")
	test.check(hunter.behavior_event_history.has(&"ranged_fire"), "hunter ranged fire event was not observable")
	if not projectiles.is_empty():
		game.player.invulnerable = 0.0
		var player_health: int = game.player.health
		projectiles[0].position = game.player.position
		test.check(projectiles[0]._resolve_direct_hit(), "hunter projectile did not hit the player")
		test.check(game.player.health == player_health - HUNTER.ranged_weapon.damage, "hunter projectile ignored weapon damage")
		projectiles[0].queue_free()
		await test.tree.process_frame
	hunter._think(HUNTER.recovery_duration + 0.01)
	test.check(hunter.behavior_phase == StreetEnemyScript.BehaviorPhase.NEUTRAL, "hunter did not leave shot recovery")
	test.check(hunter.behavior_cooldown_timer > 0.0, "hunter shot did not start cooldown")
	hunter.behavior_cooldown_timer = 0.0
	hunter.position = Vector2(650.0, 540.0)
	hunter._think(1.0 / 60.0)
	test.check(hunter.velocity.x > 0.0 and hunter.last_behavior_event == &"range_retreat", "cornered hunter did not retreat from player")
	hunter.position = Vector2(1050.0, 540.0)
	hunter._think(1.0 / 60.0)
	test.check(hunter.velocity.x < 0.0, "distant hunter did not close to firing range")

	var formation: Array[Node] = []
	for index in range(4):
		var member := _spawn_frozen(game, Vector2(1180.0, 560.0), "grunt")
		formation.append(member)
	var lane_offsets := {}
	for member in formation:
		lane_offsets[member.approach_lane_offset] = true
	test.check(lane_offsets.size() == 4, "simultaneous enemies were assigned duplicate formation lanes")
	for _frame in range(90):
		for member in formation:
			member._think(1.0 / 60.0)
		for member in formation:
			member.position += member.velocity * (1.0 / 60.0)
	var minimum_formation_distance := INF
	for first_index in range(formation.size()):
		for second_index in range(first_index + 1, formation.size()):
			minimum_formation_distance = minf(
				minimum_formation_distance,
				formation[first_index].position.distance_to(formation[second_index].position)
			)
	test.check(
		minimum_formation_distance >= 45.0,
		"same-side enemies still travel as a visibly attached clump (minimum %.2f, lanes %s, positions %s)" % [
			minimum_formation_distance,
			formation.map(func(member): return member.approach_lane_offset),
			formation.map(func(member): return member.position),
		]
	)
	var velocity_signs := {}
	for member in formation:
		velocity_signs[signf(member.velocity.y)] = true
	test.check(velocity_signs.size() >= 2, "formation steering did not split enemy depth movement")

	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemy.gd")
	test.check(not enemy_source.contains("enemy_type =="), "enemy behavior branches on enemy id")
	test.check(not enemy_source.contains("enemy_type !="), "enemy behavior branches on enemy id")
	test.check(enemy_source.contains("definition.behavior_kind"), "enemy AI is not driven by typed definition data")
	test.check(
		enemy_source.contains("FORMATION_LANES")
		and enemy_source.contains("SEPARATION_DISTANCE")
		and enemy_source.contains("MIN_ENEMY_CENTER_DISTANCE"),
		"enemy formation spacing is no longer explicit"
	)
	await test.dispose(game)


func _spawn_frozen(game: Node, position: Vector2, enemy_type: String) -> Node:
	game.spawn_enemy(position, enemy_type)
	var enemy: Node = game.actors.get_child(game.actors.get_child_count() - 1)
	enemy.set_physics_process(false)
	return enemy
