extends RefCounted

const GRUNT = preload("res://data/enemies/grunt.tres")
const PISTOL = preload("res://data/weapons/pistol.tres")


func run(test) -> void:
	var game: Node = await test.instantiate_main()
	if game == null:
		return
	test.check(game.coop_player_count() == 1, "single-player scaling did not start at one player")
	test.check(game.coop_enemy_health_scale() == 1.0 and game.coop_enemy_damage_scale() == 1.0, "solo enemy scaling drifted from the Stage 1 baseline")
	test.check(game.player.combat_team == &"players" and game.player.combat_owner_id == 0, "player one combat ownership is not explicit")

	var second: Node = game.join_local_player(0, 1)
	test.check(second != null and game.coop_player_count() == 2, "two-player scaling did not follow the joined roster")
	test.check(game.coop_enemy_health_scale() == 1.4 and game.coop_enemy_damage_scale() == 1.08, "two-player tuning values drifted")
	test.check(second.combat_team == &"players" and second.combat_owner_id == 1, "player two did not receive unique ownership inside the player team")
	test.check(not game.player.attack_hitbox.can_damage(second.hurtbox), "friendly player hurtboxes were eligible for player attacks")

	game.spawn_enemy(Vector2(900.0, 560.0), "grunt")
	var two_player_enemy: Node = test.tree.get_nodes_in_group("enemies").back()
	two_player_enemy.set_physics_process(false)
	test.check(two_player_enemy.max_health == roundi(GRUNT.max_health * 1.4), "two-player enemy health was not scaled at spawn")
	test.check(two_player_enemy.health_scale_snapshot == 1.4 and two_player_enemy.damage_scale_snapshot == 1.08, "enemy did not retain its spawn-time co-op tuning snapshot")
	test.check(two_player_enemy.combat_team == &"human_enemies", "human enemy combat faction ownership is missing")
	test.check(game.player.attack_hitbox.can_damage(two_player_enemy.hurtbox), "player attacks rejected a hostile enemy hurtbox")
	test.check(two_player_enemy.attack_hitbox.can_damage(game.player.hurtbox), "enemy attacks rejected a player hurtbox")

	var third: Node = game.join_local_player(1, 2)
	test.check(third != null and game.coop_player_count() == 3, "three-player scaling did not follow the joined roster")
	test.check(game.coop_enemy_health_scale() == 1.7 and game.coop_enemy_damage_scale() == 1.16, "three-player tuning values drifted")
	game.spawn_enemy(Vector2(1020.0, 560.0), "grunt")
	var three_player_enemy: Node = test.tree.get_nodes_in_group("enemies").back()
	three_player_enemy.set_physics_process(false)
	test.check(three_player_enemy.max_health == roundi(GRUNT.max_health * 1.7), "three-player enemy health was not scaled at spawn")
	test.check(two_player_enemy.max_health == roundi(GRUNT.max_health * 1.4), "joining mid-wave rewrote an existing enemy's health budget")

	game.player.invulnerable = 0.0
	three_player_enemy.position = game.player.position + Vector2(64.0, 0.0)
	three_player_enemy.combat_target = game.player
	three_player_enemy.facing = -1
	three_player_enemy.attack_timer = 0.35
	three_player_enemy.attack_hit_done = false
	three_player_enemy.attack_hitbox.configure_circle(47.0, -1)
	var health_before: int = game.player.health
	three_player_enemy._check_attack()
	var expected_damage := roundi(GRUNT.attack.damage * 1.16)
	test.check(game.player.health == health_before - expected_damage, "three-player enemy damage did not use its tuning snapshot")

	var player_projectile: Node = game.spawn_weapon_projectile(second, PISTOL, &"player", second.position, 1)
	test.check(player_projectile.combat_team == &"players" and player_projectile.combat_owner_id == 1, "player projectile lost its source ownership")
	test.check(not player_projectile._can_damage_actor(game.player) and player_projectile._can_damage_actor(three_player_enemy), "player projectile faction filter permits friendly fire or rejects hostiles")
	var enemy_projectile: Node = game.spawn_weapon_projectile(three_player_enemy, PISTOL, &"enemy", three_player_enemy.position, -1, game.player)
	test.check(enemy_projectile.combat_team == &"human_enemies" and enemy_projectile.combat_owner_id == three_player_enemy.combat_owner_id, "enemy projectile lost its faction or source ownership")
	test.check(not enemy_projectile._can_damage_actor(two_player_enemy) and enemy_projectile._can_damage_actor(game.player), "enemy projectile faction filter permits friendly fire or rejects players")
	test.check(enemy_projectile.damage_scale_snapshot == 1.16, "enemy projectile did not inherit the shooter's damage snapshot")

	game.spawn_enemy(Vector2(1120.0, 560.0), "raptor")
	var raptor: Node = test.tree.get_nodes_in_group("enemies").back()
	raptor.set_physics_process(false)
	test.check(raptor.combat_team == &"neutral_creatures", "neutral creature combat faction ownership is missing")
	test.check(raptor.attack_hitbox.can_damage(three_player_enemy.hurtbox), "cross-faction enemy combat was blocked by ownership rules")
	test.check(not three_player_enemy.attack_hitbox.can_damage(two_player_enemy.hurtbox), "same-faction enemies were eligible for friendly fire")

	test.check(game.leave_local_player(1) and game.coop_player_count() == 2, "leaving a player did not lower future spawn scaling")
	test.check(three_player_enemy.health_scale_snapshot == 1.7, "leaving mid-wave rewrote an existing enemy snapshot")
	await test.dispose(game)
