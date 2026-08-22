extends RefCounted

const PickupDefinitionScript = preload("res://core/items/pickup_definition.gd")
const PickupCatalogScript = preload("res://core/items/pickup_catalog.gd")
const PickupScript = preload("res://scripts/pickup.gd")


func run(test) -> void:
	var ids := {}
	var food_count := 0
	var score_count := 0
	var last_food_heal := 0
	var last_food_score := 0
	var last_score_value := 0
	test.check(PickupCatalogScript.ALL.size() == 8, "pickup catalog must contain four food and four score tiers")
	for item: Resource in PickupCatalogScript.ALL:
		test.check(item.is_valid_pickup(), "%s pickup definition is invalid" % item.display_name)
		test.check(not ids.has(item.pickup_id), "%s duplicates a pickup id" % item.display_name)
		ids[item.pickup_id] = true
		if item.kind == PickupDefinitionScript.PickupKind.FOOD:
			food_count += 1
			test.check(item.heal_amount > last_food_heal and item.score_value > last_food_score, "%s does not advance the food tier curve" % item.display_name)
			last_food_heal = item.heal_amount
			last_food_score = item.score_value
		else:
			score_count += 1
			test.check(item.score_value > last_score_value, "%s does not advance the treasure score curve" % item.display_name)
			last_score_value = item.score_value
	test.check(food_count == 4 and score_count == 4, "pickup family split drifted")
	var pickup_ids := PickupCatalogScript.explicit_pickup_ids()
	test.check(pickup_ids.size() == 8, "typed pickup drop IDs are incomplete")
	var atlas_indices := {}
	for pickup_id in pickup_ids:
		var atlas_index := PickupScript.item_atlas_index(pickup_id)
		test.check(atlas_index >= 0, "%s has no production pickup artwork" % pickup_id)
		test.check(not atlas_indices.has(atlas_index), "%s reuses another item pickup cell" % pickup_id)
		atlas_indices[atlas_index] = true
	test.check(atlas_indices.size() == 8, "item pickup atlas does not expose eight unique models")
	test.check(PickupScript.ITEM_PICKUP_ATLAS.get_width() == 640 and PickupScript.ITEM_PICKUP_ATLAS.get_height() == 320, "item pickup atlas grid drifted")
	test.check(PickupScript.item_atlas_index("food") == 1, "legacy food reward alias lost its ration model")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	var teammate: Node = game.join_local_player(0, 1)
	game._start_game()
	game.set_process(false)
	game.player.set_physics_process(false)
	teammate.set_physics_process(false)

	for food: Resource in [PickupCatalogScript.SNACK, PickupCatalogScript.RATION, PickupCatalogScript.MEAL, PickupCatalogScript.FEAST]:
		game.player.health = 10
		var score_before: int = game.score
		game.spawn_pickup(game.player.position, String(food.pickup_id))
		var pickup: Node = test.tree.get_nodes_in_group("pickups").back()
		pickup.set_process(false)
		test.check(pickup.collect(game.player), "%s could not be collected" % food.display_name)
		var expected_health := mini(game.player.max_health, 10 + roundi(food.heal_amount * game.player.item_efficiency))
		test.check(game.player.health == expected_health, "%s healing tier ignored hero efficiency or cap" % food.display_name)
		test.check(game.score == score_before + food.score_value, "%s score tier drifted" % food.display_name)
		await test.tree.process_frame

	for treasure: Resource in [PickupCatalogScript.TOKEN, PickupCatalogScript.BADGE, PickupCatalogScript.RELIC, PickupCatalogScript.INTEL]:
		var health_before: int = game.player.health
		var score_before: int = game.score
		game.spawn_pickup(game.player.position, String(treasure.pickup_id))
		var pickup: Node = test.tree.get_nodes_in_group("pickups").back()
		pickup.set_process(false)
		test.check(pickup.collect(game.player), "%s could not be collected" % treasure.display_name)
		test.check(game.player.health == health_before, "%s treasure incorrectly healed the collector" % treasure.display_name)
		test.check(game.score == score_before + treasure.score_value, "%s award value drifted" % treasure.display_name)
		await test.tree.process_frame

	var tire: Node = _carryable_by_id(test, &"avenue_tire")
	test.check(tire != null, "Stage 1 carryable tire fixture is missing")
	if tire != null:
		game.player.position = tire.position
		game.player.attack_timer = 0.0
		game.player._start_attack()
		test.check(game.player.carried_prop == tire and tire.carried, "attack near a carryable did not pick it up")
		test.check(not tire.is_in_group("carryables") and not tire.is_in_group("breakables"), "carried prop remained targetable in the world")
		tire._physics_process(0.0)
		test.check(tire.position.y < game.player.position.y - 90.0, "carried prop did not follow above the fighter")

		game.spawn_enemy(game.player.position + Vector2(115.0, 0.0), "grunt")
		var target: Node = test.tree.get_nodes_in_group("enemies").back()
		target.set_physics_process(false)
		target.invulnerable = 0.0
		teammate.position = target.position
		var target_health: int = target.health
		var teammate_health: int = teammate.health
		var score_before_throw: int = game.score
		game.player.attack_timer = 0.0
		game.player._start_attack()
		test.check(game.player.carried_prop == null and tire.thrown, "second attack did not throw the carried prop")
		tire._physics_process(0.1)
		test.check(target.health == target_health - tire.throw_damage_snapshot and target.knockdown_state, "thrown prop did not damage and launch the enemy")
		test.check(teammate.health == teammate_health, "thrown prop damaged a same-team local player")
		test.check(tire.is_defeated and game.score == score_before_throw + tire.definition.defeat_score, "throw impact did not consume and score the prop")
		# Keep the co-op safety witness from automatically collecting the impact drop.
		teammate.position += Vector2(180.0, 0.0)
		await test.tree.process_frame
		var drops: Array[Node] = test.tree.get_nodes_in_group("pickups")
		test.check(not drops.is_empty() and drops.back().item_definition == PickupCatalogScript.BADGE, "destroyed tire did not create its typed score drop")

	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(probe_source.contains("prop_item_preview=1"), "reproducible prop/item Web preview is missing")
	await test.dispose(game)


func _carryable_by_id(test, object_id: StringName) -> Node:
	for stage_object in test.tree.get_nodes_in_group("carryables"):
		if stage_object.definition.object_id == object_id:
			return stage_object
	return null
