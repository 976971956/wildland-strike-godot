extends RefCounted

const WeaponDefinitionScript = preload("res://core/weapons/weapon_definition.gd")
const WeaponCatalogScript = preload("res://core/weapons/weapon_catalog.gd")
const SfxLibraryScript = preload("res://scripts/sfx_library.gd")


func run(test) -> void:
	var ids := {}
	var behaviors := {}
	var kind_counts := {0: 0, 1: 0, 2: 0}
	test.check(WeaponCatalogScript.ALL.size() == 12, "weapon sandbox must contain exactly twelve launch behaviors")
	for weapon: Resource in WeaponCatalogScript.ALL:
		test.check(weapon.is_valid_weapon(), "%s failed typed weapon validation" % weapon.display_name)
		test.check(not ids.has(weapon.weapon_id), "%s duplicates a weapon id" % weapon.display_name)
		test.check(not behaviors.has(weapon.behavior_id), "%s does not own a distinct behavior" % weapon.display_name)
		test.check(SfxLibraryScript.has_event(weapon.fire_sfx), "%s references an unmixed use cue" % weapon.display_name)
		if weapon.kind == WeaponDefinitionScript.WeaponKind.EXPLOSIVE:
			test.check(SfxLibraryScript.has_event(weapon.blast_sfx), "%s references an unmixed blast cue" % weapon.display_name)
		ids[weapon.weapon_id] = true
		behaviors[weapon.behavior_id] = true
		kind_counts[weapon.kind] += 1
	test.check(kind_counts == {0: 4, 1: 4, 2: 4}, "weapon sandbox must expose four melee, four explosive, and four firearm behaviors")
	var pickup_ids := WeaponCatalogScript.explicit_pickup_ids()
	test.check(pickup_ids.size() == 12, "explicit weapon drop table is incomplete")
	var pickup_resources := {}
	for pickup_id in pickup_ids:
		var weapon: Resource = WeaponCatalogScript.from_pickup_id(pickup_id)
		pickup_resources[weapon.weapon_id] = true
	test.check(pickup_resources.size() == 12, "explicit weapon drops do not resolve to twelve unique resources")

	await _verify_melee_behaviors(test)
	await _verify_firearm_behaviors(test)
	await _verify_explosive_behaviors(test)
	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(probe_source.contains("weapon_sandbox_preview=1"), "reproducible twelve-weapon Web preview is missing")


func _verify_melee_behaviors(test) -> void:
	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.set_process(false)
	game.player.set_physics_process(false)
	game.player.position = Vector2(500.0, 550.0)

	game.player.give_weapon("weapon_whip")
	game.player._start_attack()
	var base_extent: float = game.player.current_attack.weapon_box_half_extents.x
	test.check(is_equal_approx(game.player.attack_hitbox.half_extents.x, base_extent * WeaponCatalogScript.WHIP.melee_reach_scale), "whip did not extend the real melee hitbox")

	game.player.attack_timer = 0.0
	game.player.combo_window = 0.0
	game.player.give_weapon("weapon_pipe")
	game.spawn_enemy(Vector2(570.0, 550.0), "grunt")
	var pipe_target: Node = test.tree.get_nodes_in_group("enemies").back()
	pipe_target.set_physics_process(false)
	pipe_target.invulnerable = 0.0
	var pipe_health_before: int = pipe_target.health
	game.player._start_attack()
	var pipe_base_damage: int = game.player.current_attack.damage
	game.player.attack_timer = game.player.current_attack.hit_trigger_remaining - 0.001
	game.player._check_attack_hit()
	test.check(pipe_target.health == pipe_health_before - pipe_base_damage - WeaponCatalogScript.PIPE.melee_bonus_damage, "pipe did not use its own heavy damage data")
	test.check(pipe_target.knockdown_state and absf(pipe_target.velocity.x) > 150.0, "pipe did not force its heavy launch/knockback behavior")
	test.check(game.player.weapon_ammo == WeaponCatalogScript.PIPE.capacity - 1, "pipe durability did not decrement once")

	pipe_target.queue_free()
	await test.tree.process_frame
	game.player.attack_timer = 0.0
	game.player.combo_window = 0.0
	game.player.give_weapon("weapon_shock_baton")
	game.spawn_enemy(Vector2(570.0, 550.0), "grunt")
	game.spawn_enemy(Vector2(650.0, 550.0), "grunt")
	var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	var shock_primary: Node = enemies[-2]
	var shock_chain: Node = enemies[-1]
	shock_primary.set_physics_process(false)
	shock_chain.set_physics_process(false)
	shock_primary.invulnerable = 0.0
	shock_chain.invulnerable = 0.0
	var shock_primary_health: int = shock_primary.health
	var shock_chain_health: int = shock_chain.health
	game.player._start_attack()
	game.player.attack_timer = game.player.current_attack.hit_trigger_remaining - 0.001
	game.player._check_attack_hit()
	test.check(shock_primary.health < shock_primary_health, "shock baton missed its primary target")
	test.check(shock_chain.health == shock_chain_health - WeaponCatalogScript.SHOCK_BATON.chain_damage, "shock baton did not chain to one nearby target")
	test.check(shock_chain.stun_timer >= WeaponCatalogScript.SHOCK_BATON.melee_stun_bonus, "shock baton chain did not apply its stun identity")
	await test.dispose(game)


func _verify_firearm_behaviors(test) -> void:
	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.set_process(false)
	game.player.set_physics_process(false)
	game.player.position = Vector2(400.0, 550.0)

	game.player.give_weapon("weapon_shotgun")
	_fire_player_weapon(game.player)
	var projectiles: Array[Node] = test.tree.get_nodes_in_group("weapon_projectiles")
	test.check(projectiles.size() == WeaponCatalogScript.SHOTGUN.shots_per_use, "shotgun did not emit its five-pellet depth spread")
	var shotgun_depth_velocities := {}
	for projectile in projectiles:
		shotgun_depth_velocities[snappedf(projectile.velocity.y, 0.01)] = true
		projectile.queue_free()
	test.check(shotgun_depth_velocities.size() == 5, "shotgun pellets do not fan across distinct depth lanes")
	await test.tree.process_frame

	game.player.attack_timer = 0.0
	game.player.combo_window = 0.0
	game.player.give_weapon("weapon_smg")
	_fire_player_weapon(game.player)
	projectiles = test.tree.get_nodes_in_group("weapon_projectiles")
	test.check(projectiles.size() == WeaponCatalogScript.SMG.shots_per_use, "SMG did not emit a three-round burst per ammo unit")
	test.check(game.player.weapon_ammo == WeaponCatalogScript.SMG.capacity - 1, "SMG burst consumed more than one ammo unit")
	for projectile in projectiles:
		projectile.queue_free()
	await test.tree.process_frame

	var rifle_projectile: Node = game.spawn_weapon_projectile(game.player, WeaponCatalogScript.RIFLE, &"player", Vector2(500.0, 550.0), 1)
	var rifle_targets: Array[Node] = []
	for target_x in [620.0, 760.0, 900.0]:
		game.spawn_enemy(Vector2(target_x, 550.0), "grunt")
		var target: Node = test.tree.get_nodes_in_group("enemies").back()
		target.set_physics_process(false)
		target.invulnerable = 0.0
		rifle_targets.append(target)
	for index in range(rifle_targets.size()):
		var target: Node = rifle_targets[index]
		var health_before: int = target.health
		rifle_projectile.position = target.position
		var spent: bool = rifle_projectile._resolve_direct_hit()
		test.check(target.health == health_before - WeaponCatalogScript.RIFLE.damage, "rifle penetration missed target %d" % (index + 1))
		test.check(spent == (index == rifle_targets.size() - 1), "rifle projectile penetration count drifted at target %d" % (index + 1))
	await test.dispose(game)


func _verify_explosive_behaviors(test) -> void:
	var game: Node = await test.instantiate_main()
	if game == null:
		return
	var teammate: Node = game.join_local_player(0, 1)
	game._start_game()
	game.set_process(false)
	game.player.set_physics_process(false)
	teammate.set_physics_process(false)
	game.player.position = Vector2(300.0, 550.0)

	game.spawn_enemy(Vector2(720.0, 550.0), "grunt")
	var rocket_target: Node = test.tree.get_nodes_in_group("enemies").back()
	rocket_target.set_physics_process(false)
	rocket_target.invulnerable = 0.0
	var rocket_health: int = rocket_target.health
	var rocket: Node = game.spawn_weapon_projectile(game.player, WeaponCatalogScript.ROCKET, &"player", rocket_target.position, 1)
	rocket._physics_process(0.01)
	test.check(rocket.exploded and rocket_target.health == rocket_health - WeaponCatalogScript.ROCKET.damage, "rocket did not detonate on contact")
	test.check(rocket_target.knockdown_state, "rocket contact blast did not launch its target")

	game.spawn_enemy(Vector2(1320.0, 550.0), "grunt")
	var mine_target: Node = test.tree.get_nodes_in_group("enemies").back()
	mine_target.set_physics_process(false)
	mine_target.invulnerable = 0.0
	teammate.position = Vector2(1120.0, 550.0)
	var teammate_health: int = teammate.health
	var mine: Node = game.spawn_weapon_projectile(game.player, WeaponCatalogScript.MINE, &"player", teammate.position, 1)
	var mine_position: Vector2 = mine.position
	mine._physics_process(WeaponCatalogScript.MINE.arm_delay * 1.01)
	test.check(not mine.exploded and mine.position == mine_position, "mine moved or treated its nearby teammate as a trigger")
	mine_target.position = mine.position
	mine._physics_process(0.01)
	test.check(mine.exploded, "armed mine did not detect a hostile inside its trigger radius")
	test.check(teammate.health == teammate_health, "mine blast damaged a same-team local player")

	game.spawn_enemy(Vector2(1510.0, 550.0), "grunt")
	var fire_target: Node = test.tree.get_nodes_in_group("enemies").back()
	fire_target.set_physics_process(false)
	fire_target.invulnerable = 0.0
	var molotov: Node = game.spawn_weapon_projectile(game.player, WeaponCatalogScript.MOLOTOV, &"player", fire_target.position, 1)
	var fire_health: int = fire_target.health
	molotov._explode()
	test.check(molotov.exploded and molotov.lingering_timer == WeaponCatalogScript.MOLOTOV.lingering_duration, "molotov did not create its lingering fire field")
	test.check(fire_target.health == fire_health - WeaponCatalogScript.MOLOTOV.damage, "molotov initial blast damage drifted")
	fire_target.invulnerable = 0.0
	molotov._physics_process(WeaponCatalogScript.MOLOTOV.lingering_tick_interval)
	test.check(fire_target.health == fire_health - WeaponCatalogScript.MOLOTOV.damage - WeaponCatalogScript.MOLOTOV.lingering_damage, "molotov fire field did not apply a later damage tick")
	await test.dispose(game)


func _fire_player_weapon(player: Node) -> void:
	player.attack_timer = 0.0
	player.combo_window = 0.0
	player._start_attack()
	player.attack_timer = player.current_attack.hit_trigger_remaining - 0.001
	player._check_attack_hit()
