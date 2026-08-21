extends RefCounted

const WeaponDefinitionScript = preload("res://core/weapons/weapon_definition.gd")
const MACHETE = preload("res://data/weapons/machete.tres")
const GRENADE = preload("res://data/weapons/grenade.tres")
const PISTOL = preload("res://data/weapons/pistol.tres")
const STAGE_1 = preload("res://data/stages/stage_1/stage_1.tres")


func run(test) -> void:
	var weapons: Array[Resource] = [MACHETE, GRENADE, PISTOL]
	var ids := {}
	var kinds := {}
	for weapon in weapons:
		test.check(weapon != null and weapon.is_valid_weapon(), "weapon resource failed validation")
		test.check(not ids.has(weapon.weapon_id), "weapon id is duplicated")
		test.check(not kinds.has(weapon.kind), "weapon family is duplicated")
		ids[weapon.weapon_id] = true
		kinds[weapon.kind] = true
	test.check(kinds.size() == 3, "first three weapon families are incomplete")
	test.check(not WeaponDefinitionScript.new().is_valid_weapon(), "empty weapon definition should be invalid")
	test.check(MACHETE.melee_bonus_damage == 7 and MACHETE.capacity == 12, "machete tuning drifted")
	test.check(PISTOL.damage == 15 and PISTOL.projectile_speed == 860.0, "pistol tuning drifted")
	test.check(GRENADE.damage == 34 and GRENADE.explosion_radius == 112.0, "grenade tuning drifted")

	var stage_drop_ids := {}
	for scene in STAGE_1.scenes:
		for object_definition in scene.environment_objects:
			if not object_definition.drop_id.is_empty():
				stage_drop_ids[object_definition.drop_id] = true
		for encounter in scene.encounters:
			if not encounter.reward_id.is_empty():
				stage_drop_ids[encounter.reward_id] = true
	test.check(stage_drop_ids.has(&"weapon"), "Stage 1 has no melee weapon reward")
	test.check(stage_drop_ids.has(&"weapon_firearm"), "Stage 1 has no firearm drop")
	test.check(stage_drop_ids.has(&"weapon_explosive"), "Stage 1 has no explosive drop")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.set_physics_process(false)
	game.player.give_weapon("weapon_melee")
	test.check(game.player.equipped_weapon == MACHETE and game.player.weapon_ammo == 12, "legacy melee pickup mapping failed")
	test.check(game.hud.weapon_name == "MACHETE" and game.hud.weapon_ammo == 12, "melee pickup did not update HUD")

	game.player.give_weapon("weapon_firearm")
	test.check(game.player.equipped_weapon == PISTOL and game.player.weapon_ammo == 12, "firearm pickup mapping failed")
	game.player.attack_timer = 0.0
	game.player.combo_window = 0.0
	game.player._start_attack()
	game.player.attack_timer = game.player.current_attack.hit_trigger_remaining - 0.001
	game.player._check_attack_hit()
	var projectiles: Array[Node] = test.tree.get_nodes_in_group("weapon_projectiles")
	test.check(projectiles.size() == 1, "pistol attack did not spawn exactly one projectile")
	test.check(game.player.weapon_ammo == 11 and game.player.attack_hit_done, "pistol attack did not consume exactly one round")
	test.check(game.hud.weapon_name == "PISTOL" and game.hud.weapon_ammo == 11, "pistol ammo HUD drifted")
	if not projectiles.is_empty():
		game.spawn_enemy(Vector2(1050.0, 540.0), "grunt")
		var target: Node = test.tree.get_nodes_in_group("enemies")[-1]
		target.set_physics_process(false)
		target.invulnerable = 0.0
		var health_before: int = target.health
		projectiles[0].position = target.position
		test.check(projectiles[0]._resolve_direct_hit(), "pistol projectile did not resolve a direct hit")
		test.check(target.health == health_before - PISTOL.damage, "pistol projectile damage ignored weapon data")
		projectiles[0].queue_free()
		await test.tree.process_frame

	game.player.give_weapon("weapon_explosive")
	test.check(game.player.equipped_weapon == GRENADE and game.player.weapon_ammo == 3, "explosive pickup mapping failed")
	game.player.attack_timer = 0.0
	game.player.combo_window = 0.0
	game.player._start_attack()
	game.player.attack_timer = game.player.current_attack.hit_trigger_remaining - 0.001
	game.player._check_attack_hit()
	projectiles = test.tree.get_nodes_in_group("weapon_projectiles")
	test.check(projectiles.size() == 1 and projectiles[0].definition == GRENADE, "grenade attack did not spawn its configured projectile")
	test.check(game.player.weapon_ammo == 2 and game.hud.weapon_ammo == 2, "grenade ammo was not consumed and displayed")
	if not projectiles.is_empty():
		game.spawn_enemy(Vector2(1500.0, 540.0), "grunt")
		game.spawn_enemy(Vector2(1590.0, 540.0), "grunt")
		var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
		var blast_a: Node = enemies[-2]
		var blast_b: Node = enemies[-1]
		blast_a.set_physics_process(false)
		blast_b.set_physics_process(false)
		blast_a.invulnerable = 0.0
		blast_b.invulnerable = 0.0
		var health_a: int = blast_a.health
		var health_b: int = blast_b.health
		projectiles[0].position = Vector2(1500.0, 540.0)
		projectiles[0]._explode()
		test.check(blast_a.health == health_a - GRENADE.damage, "grenade center target damage drifted")
		test.check(blast_b.health == health_b - GRENADE.damage, "grenade area target was missed")
		test.check(blast_a.knockdown_state and blast_b.knockdown_state, "grenade did not launch targets")
		test.check(game.last_impact_profile_id == GRENADE.impact_profile.profile_id, "grenade lost configured impact feedback")

	await test.dispose(game)
