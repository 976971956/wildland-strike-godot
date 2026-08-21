extends RefCounted

const HurtboxScript = preload("res://core/combat/combat_hurtbox.gd")
const HitboxScript = preload("res://core/combat/combat_hitbox.gd")


func run(test) -> void:
	var fixture := Node2D.new()
	test.tree.root.add_child(fixture)
	var attacker := Node2D.new()
	var target := Node2D.new()
	fixture.add_child(attacker)
	fixture.add_child(target)
	var hitbox = HitboxScript.new()
	attacker.add_child(hitbox)
	hitbox.setup(attacker)
	var hurtbox = HurtboxScript.new()
	target.add_child(hurtbox)
	hurtbox.setup(target)

	hitbox.configure_box(Vector2(29.0, 0.0), Vector2(23.0, 28.0), 1)
	target.position = Vector2(69.9, 0.0)
	test.check(hitbox.overlaps(hurtbox), "forward box should include the legacy 70px range interior")
	target.position.x = 70.0
	test.check(not hitbox.overlaps(hurtbox), "forward box should exclude the legacy 70px boundary")
	target.position = Vector2(-11.9, 0.0)
	test.check(hitbox.overlaps(hurtbox), "rear grace should include positions above -12px")
	target.position.x = -12.0
	test.check(not hitbox.overlaps(hurtbox), "rear grace should exclude the -12px boundary")
	target.position = Vector2(30.0, 45.9)
	test.check(hitbox.overlaps(hurtbox), "lane box should include depth below 46px")
	target.position.y = 46.0
	test.check(not hitbox.overlaps(hurtbox), "lane box should exclude the 46px boundary")
	hitbox.configure_box(Vector2(29.0, 0.0), Vector2(23.0, 28.0), -1)
	target.position = Vector2(-69.9, 0.0)
	test.check(hitbox.overlaps(hurtbox), "box did not mirror with fighter facing")

	hitbox.configure_circle(47.0, 1)
	target.position = Vector2(64.9, 0.0)
	test.check(hitbox.overlaps(hurtbox), "circle should include the legacy 65px range interior")
	target.position.x = 65.0
	test.check(not hitbox.overlaps(hurtbox), "circle should exclude the legacy 65px boundary")
	hurtbox.enabled = false
	target.position.x = 10.0
	test.check(not hitbox.overlaps(hurtbox), "disabled hurtbox should reject hits")
	hurtbox.enabled = true
	hitbox.set_debug_visible(true)
	hurtbox.set_debug_visible(true)
	test.check(hitbox.debug_visible and hurtbox.debug_visible, "combat debug visualization did not enable")
	await test.tree.process_frame
	hitbox.deactivate()
	test.check(not hitbox.overlaps(hurtbox), "inactive hitbox should reject hits")
	await test.dispose(fixture)

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game._start_game()
	game.player.position = Vector2(500.0, 540.0)
	await test.wait_physics_frames(2)
	var enemies: Array[Node] = test.tree.get_nodes_in_group("enemies")
	test.check(not enemies.is_empty(), "integrated hitbox fixture failed to spawn")
	if not enemies.is_empty():
		for index in range(enemies.size()):
			var spawned_enemy = enemies[index]
			spawned_enemy.set_physics_process(false)
			spawned_enemy.position = Vector2(1000.0 + index * 100.0, 620.0)
		var enemy = enemies[0]
		enemy.position = game.player.position + Vector2(69.0, 0.0)
		var enemy_health: int = enemy.health
		game.player.facing = 1
		game.player._start_attack()
		test.check(game.player.attack_hitbox.active, "player attack did not activate its hitbox")
		test.check(game.player.attack_hitbox.overlaps(enemy.hurtbox), "integrated player hitbox did not overlap target")
		game.player.attack_timer = 0.17
		game.player._check_attack_hit()
		test.check(enemy.health < enemy_health, "player attack did not resolve through explicit hurtbox")

		game.player.invulnerable = 0.0
		enemy.facing = -1
		enemy.position = game.player.position + Vector2(64.0, 0.0)
		enemy.attack_timer = 0.35
		enemy.attack_hit_done = false
		enemy.attack_hitbox.configure_circle(47.0, enemy.facing)
		var player_health: int = game.player.health
		enemy._check_attack()
		test.check(game.player.health < player_health, "enemy attack did not resolve through explicit hurtbox")
	await test.dispose(game)
