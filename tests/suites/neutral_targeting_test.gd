extends RefCounted

const EnemyDefinitionScript = preload("res://core/combat/enemy_definition.gd")
const StreetEnemyScript = preload("res://scripts/enemy.gd")
const RAPTOR = preload("res://data/enemies/raptor.tres")
const GRUNT = preload("res://data/enemies/grunt.tres")
const HUNTER = preload("res://data/enemies/hunter.tres")


func run(test) -> void:
	test.check(RAPTOR.faction == EnemyDefinitionScript.Faction.NEUTRAL_CREATURE, "raptor is not in the neutral creature faction")
	test.check(GRUNT.faction == EnemyDefinitionScript.Faction.HUMAN_ENEMY, "grunt faction drifted")
	test.check(HUNTER.faction == EnemyDefinitionScript.Faction.HUMAN_ENEMY, "hunter faction drifted")
	test.check(RAPTOR.faction != GRUNT.faction, "raptor and raiders still share a faction")
	test.check(RAPTOR.opposing_faction_target_radius == 520.0, "neutral target acquisition radius drifted")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game.set_process(false)
	game.player.set_physics_process(false)
	game._start_game()
	game.player.position = Vector2(300.0, 540.0)

	var raptor: Node = _spawn_frozen(game, Vector2(1200.0, 540.0), "raptor")
	var grunt: Node = _spawn_frozen(game, Vector2(1255.0, 540.0), "grunt")
	var grunt_ally: Node = _spawn_frozen(game, Vector2(1258.0, 540.0), "grunt")
	raptor._update_combat_target()
	grunt._update_combat_target()
	grunt_ally._update_combat_target()
	test.check(raptor.combat_target == grunt or raptor.combat_target == grunt_ally, "neutral raptor did not target a nearby raider")
	test.check(grunt.combat_target == raptor, "grunt targeted its nearby ally instead of the neutral raptor")
	test.check(grunt_ally.combat_target == raptor, "second grunt did not recognize neutral raptor as opposing")
	test.check(raptor.last_behavior_event == &"target_enemy", "raptor target switch was not observable")
	test.check(grunt.last_behavior_event == &"target_enemy", "human target switch was not observable")

	var raptor_target: Node = raptor.combat_target
	raptor.position = raptor_target.position - Vector2(55.0, 0.0)
	raptor.behavior_cooldown_timer = 1.0
	raptor_target.invulnerable = 0.0
	raptor._think(1.0 / 60.0)
	test.check(raptor.attack_timer > 0.0, "raptor did not start a contact attack against a raider")
	var human_health_before: int = raptor_target.health
	raptor.attack_timer = raptor.current_attack.hit_trigger_remaining - 0.01
	raptor._check_attack()
	test.check(raptor_target.health == human_health_before - RAPTOR.attack.damage, "raptor attack did not damage the human faction")
	test.check(raptor.attack_hit_done, "raptor-versus-human attack resolved more than once")

	grunt.position = raptor.position + Vector2(55.0, 0.0)
	grunt.combat_target = raptor
	grunt.attack_timer = 0.0
	grunt.hurt_timer = 0.0
	grunt.stun_timer = 0.0
	grunt.invulnerable = 0.0
	raptor.attack_timer = 0.0
	raptor.hurt_timer = 0.0
	raptor.stun_timer = 0.0
	raptor.invulnerable = 0.0
	grunt._think(1.0 / 60.0)
	test.check(grunt.attack_timer > 0.0, "human enemy did not retaliate against neutral raptor")
	var raptor_health_before: int = raptor.health
	grunt.attack_timer = grunt.current_attack.hit_trigger_remaining - 0.01
	grunt._check_attack()
	test.check(raptor.health == raptor_health_before - GRUNT.attack.damage, "human enemy attack did not damage neutral raptor")

	grunt.is_defeated = true
	grunt_ally.is_defeated = true
	raptor.combat_target = grunt
	raptor._update_combat_target()
	test.check(raptor.combat_target == game.player, "raptor did not fall back to the player after human targets were defeated")
	var second_raptor: Node = _spawn_frozen(game, raptor.position + Vector2(8.0, 0.0), "raptor")
	raptor._update_combat_target()
	test.check(raptor.combat_target == game.player, "raptor incorrectly targeted its own neutral-creature faction")

	var hunter: Node = _spawn_frozen(game, Vector2(1500.0, 540.0), "hunter")
	hunter._update_combat_target()
	test.check(hunter.combat_target == raptor or hunter.combat_target == second_raptor, "ranged hunter did not select the nearer neutral creature")
	var ranged_target: Node = hunter.combat_target
	ranged_target.invulnerable = 0.0
	hunter._think(1.0 / 60.0)
	test.check(hunter.behavior_phase == StreetEnemyScript.BehaviorPhase.TELEGRAPH, "hunter did not aim at neutral creature target")
	hunter._think(HUNTER.telegraph_duration + 0.01)
	var projectiles: Array[Node] = test.tree.get_nodes_in_group("weapon_projectiles")
	test.check(projectiles.size() == 1 and projectiles[0].target_actor == ranged_target, "hunter projectile did not lock the selected neutral target")
	if not projectiles.is_empty():
		var ranged_health_before: int = ranged_target.health
		projectiles[0].position = ranged_target.position
		test.check(projectiles[0]._resolve_direct_hit(), "enemy projectile did not resolve against neutral target")
		test.check(ranged_target.health == ranged_health_before - HUNTER.ranged_weapon.damage, "enemy projectile damage against neutral target drifted")

	hunter.position = Vector2(2200.0, 540.0)
	hunter.combat_target = ranged_target
	hunter._update_combat_target()
	test.check(hunter.combat_target == game.player, "hunter retained an out-of-range cross-faction target")

	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemy.gd")
	test.check(enemy_source.contains("definition.faction"), "target selection is not data-driven by faction")
	test.check(enemy_source.contains("combat_target"), "enemy combat still assumes the player is the only target")
	await test.dispose(game)


func _spawn_frozen(game: Node, position: Vector2, enemy_type: String) -> Node:
	game.spawn_enemy(position, enemy_type)
	var enemy: Node = game.actors.get_child(game.actors.get_child_count() - 1)
	enemy.set_physics_process(false)
	return enemy
