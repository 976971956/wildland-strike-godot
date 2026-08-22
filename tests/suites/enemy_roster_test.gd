extends RefCounted

const EnemyDefinitionScript = preload("res://core/combat/enemy_definition.gd")
const EncounterRecipeCatalogScript = preload("res://core/stages/encounter_recipe_catalog.gd")
const EncounterWaveDataScript = preload("res://core/stages/encounter_wave_data.gd")
const SfxLibraryScript = preload("res://scripts/sfx_library.gd")
const STANDARD_ENEMIES := [
	preload("res://data/enemies/grunt.tres"),
	preload("res://data/enemies/brute.tres"),
	preload("res://data/enemies/hunter.tres"),
	preload("res://data/enemies/knife_raider.tres"),
	preload("res://data/enemies/demolitionist.tres"),
	preload("res://data/enemies/shield_guard.tres"),
]
const ELITE_ENEMIES := [
	preload("res://data/enemies/elite_enforcer.tres"),
	preload("res://data/enemies/elite_blade.tres"),
	preload("res://data/enemies/elite_bombardier.tres"),
	preload("res://data/enemies/elite_bulwark.tres"),
]
const KNIFE_RAIDER = preload("res://data/enemies/knife_raider.tres")
const DEMOLITIONIST = preload("res://data/enemies/demolitionist.tres")
const SHIELD_GUARD = preload("res://data/enemies/shield_guard.tres")
const ELITE_ENFORCER = preload("res://data/enemies/elite_enforcer.tres")
const ELITE_BLADE = preload("res://data/enemies/elite_blade.tres")
const ELITE_BOMBARDIER = preload("res://data/enemies/elite_bombardier.tres")


func run(test) -> void:
	var known_ids := {}
	for definition: Resource in STANDARD_ENEMIES:
		test.check(definition.is_valid_definition(), "%s standard definition is invalid" % definition.enemy_id)
		test.check(definition.rank == EnemyDefinitionScript.Rank.STANDARD, "%s lost standard rank" % definition.enemy_id)
		known_ids[definition.enemy_id] = true
	test.check(STANDARD_ENEMIES.size() >= 5, "standard human roster is below the release floor")

	var elite_behaviors := {}
	for definition: Resource in ELITE_ENEMIES:
		test.check(definition.is_valid_definition(), "%s elite definition is invalid" % definition.enemy_id)
		test.check(definition.rank == EnemyDefinitionScript.Rank.ELITE, "%s lost elite rank" % definition.enemy_id)
		test.check(definition.outgoing_damage_scale > 1.0, "%s elite lost outgoing damage scaling" % definition.enemy_id)
		test.check(definition.stun_duration_scale < 1.0, "%s elite lost stun resistance" % definition.enemy_id)
		test.check(definition.knockdown_armor > 0, "%s elite lost knockdown armor" % definition.enemy_id)
		elite_behaviors[definition.behavior_kind] = true
		known_ids[definition.enemy_id] = true
	test.check(ELITE_ENEMIES.size() >= 4 and elite_behaviors.size() == 4, "elite roster does not expose four systemic behavior families")

	test.check(KNIFE_RAIDER.behavior_kind == EnemyDefinitionScript.BehaviorKind.DUELIST, "knife specialist lost duelist behavior")
	test.check(DEMOLITIONIST.behavior_kind == EnemyDefinitionScript.BehaviorKind.RANGED and DEMOLITIONIST.ranged_weapon.kind == 1, "demolition specialist lost delayed explosive behavior")
	test.check(SHIELD_GUARD.guard_capacity > 0 and SHIELD_GUARD.guard_damage_scale < 0.5, "shield specialist lost frontal guard")
	for event in [&"knife_slash", &"shield_block", &"shield_break", &"elite_armor"]:
		test.check(SfxLibraryScript.has_event(event), "%s roster feedback event is missing" % event)

	var generated_textures := {}
	for definition: Resource in [STANDARD_ENEMIES[2], STANDARD_ENEMIES[3], STANDARD_ENEMIES[4], STANDARD_ENEMIES[5]] + ELITE_ENEMIES:
		var image: Image = definition.sprite_sheet.get_image()
		test.check(image.get_size() == Vector2i(2560, 320), "%s roster sheet is not an isolated 8x320 strip" % definition.enemy_id)
		test.check(image.detect_alpha() != Image.ALPHA_NONE, "%s roster sheet lost transparent gutters" % definition.enemy_id)
		generated_textures[definition.sprite_sheet.resource_path] = true
	test.check(generated_textures.size() == 8, "generated specialist and elite sheets are not unique")

	for dinosaur_id in [&"compy", &"raptor", &"ankylosaur", &"triceratops"]:
		known_ids[dinosaur_id] = true
	for recipe: Resource in EncounterRecipeCatalogScript.ALL:
		test.check(recipe.is_valid_recipe(), "%s encounter recipe is invalid" % recipe.recipe_id)
		var base_spawns: Array[Resource] = recipe.build_spawns(0, 3)
		var repeat_spawns: Array[Resource] = recipe.build_spawns(0, 3)
		var hard_spawns: Array[Resource] = recipe.build_spawns(3, 3)
		test.check(_spawn_signature(base_spawns) == _spawn_signature(repeat_spawns), "%s recipe is not deterministic" % recipe.recipe_id)
		test.check(hard_spawns.size() >= base_spawns.size() and hard_spawns.size() <= recipe.max_combatants, "%s difficulty expansion exceeds its budget" % recipe.recipe_id)
		for index in range(hard_spawns.size()):
			var spawn: Resource = hard_spawns[index]
			test.check(known_ids.has(spawn.enemy_id), "%s recipe references unknown enemy %s" % [recipe.recipe_id, spawn.enemy_id])
			test.check(spawn.offset == recipe.formation_offsets[index], "%s recipe formation order drifted" % recipe.recipe_id)
	var recipe_wave := EncounterWaveDataScript.new()
	recipe_wave.wave_id = &"recipe_test"
	recipe_wave.recipe = EncounterRecipeCatalogScript.ELITE_ASSAULT
	recipe_wave.recipe_difficulty_tier = 2
	recipe_wave.recipe_variant_seed = 5
	test.check(recipe_wave.is_valid_wave(), "recipe-backed encounter wave is invalid")
	test.check(recipe_wave.spawn_count() == recipe_wave.resolved_spawns().size(), "recipe-backed wave count does not match expansion")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game.set_process(false)
	game.player.set_physics_process(false)
	game._start_game()
	game.player.position = Vector2(500.0, 540.0)
	for existing in test.tree.get_nodes_in_group("enemies"):
		existing.set_physics_process(false)
	var hunter: Node = _spawn_frozen(game, Vector2(680.0, 540.0), "hunter")
	test.check(hunter.has_method("held_weapon_visual") and hunter.has_method("held_weapon_pose"), "ranged enemy still draws a rigid primitive instead of the shared held-weapon model")
	if hunter.has_method("held_weapon_visual") and hunter.has_method("held_weapon_pose"):
		test.check(not hunter.held_weapon_visual().is_empty(), "ranged enemy held-weapon model is missing")
		hunter.velocity = Vector2(100.0, 0.0)
		hunter.walk_phase = 0.0
		var hunter_pose_a: Dictionary = hunter.held_weapon_pose()
		hunter.walk_phase = 0.5
		var hunter_pose_b: Dictionary = hunter.held_weapon_pose()
		test.check(
			Vector2(hunter_pose_a.get("origin", Vector2.ZERO)).distance_to(hunter_pose_b.get("origin", Vector2.ZERO)) > 1.0
			and absf(float(hunter_pose_a.get("rotation", 0.0)) - float(hunter_pose_b.get("rotation", 0.0))) > 0.01,
			"enemy-held weapon remains rigid during locomotion"
		)
		hunter.velocity = Vector2.ZERO
		hunter.behavior_phase = hunter.BehaviorPhase.TELEGRAPH
		hunter.behavior_timer = hunter.definition.telegraph_duration
		var aim_start: Dictionary = hunter.held_weapon_pose()
		hunter.behavior_timer = 0.0
		var aim_contact: Dictionary = hunter.held_weapon_pose()
		test.check(
			Vector2(aim_start.get("origin", Vector2.ZERO)).distance_to(aim_contact.get("origin", Vector2.ZERO)) > 5.0
			and absf(float(aim_start.get("rotation", 0.0)) - float(aim_contact.get("rotation", 0.0))) > 0.05,
			"enemy weapon does not raise through telegraph into its firing pose"
		)
		hunter.behavior_phase = hunter.BehaviorPhase.RECOVER
		hunter.behavior_timer = hunter.definition.recovery_duration
		var recoil_pose: Dictionary = hunter.held_weapon_pose()
		hunter.behavior_phase = hunter.BehaviorPhase.NEUTRAL
		var recovered_pose: Dictionary = hunter.held_weapon_pose()
		test.check(Vector2(recoil_pose.get("origin", Vector2.ZERO)).x < Vector2(recovered_pose.get("origin", Vector2.ZERO)).x - 5.0, "enemy weapon has no authored firing recoil")

	var knife: Node = _spawn_frozen(game, Vector2(760.0, 540.0), "knife_raider")
	knife._think(1.0 / 60.0)
	test.check(knife.last_behavior_event == &"duelist_feint", "knife specialist did not open with a readable feint")
	knife._think(KNIFE_RAIDER.telegraph_duration + 0.01)
	test.check(knife.last_behavior_event == &"duelist_lunge" and knife.velocity.length() > KNIFE_RAIDER.speed, "knife specialist did not convert feint into its lunge")
	knife._cancel_behavior()
	knife.behavior_cooldown_timer = 0.0
	knife.position = Vector2(570.0, 540.0)
	knife._think(1.0 / 60.0)
	test.check(knife.last_behavior_event == &"duelist_disengage" and not is_zero_approx(knife.velocity.y), "cornered knife specialist did not disengage diagonally")

	var shield: Node = _spawn_frozen(game, Vector2(760.0, 540.0), "shield_guard")
	var shield_health: int = shield.health
	shield.take_hit(20, Vector2(300.0, -40.0), true)
	test.check(shield.health == shield_health - roundi(20 * SHIELD_GUARD.guard_damage_scale), "front guard did not reduce damage")
	test.check(shield.guard_points == 8 and not shield.knockdown_state, "front guard did not absorb launch or spend guard capacity")
	shield.invulnerable = 0.0
	shield.hurt_timer = 0.0
	shield.stun_timer = 0.0
	shield.take_hit(20, Vector2(300.0, -40.0), true)
	test.check(shield.guard_points == 0 and shield.last_behavior_event == &"guard_break", "guard depletion did not enter break state")
	shield._physics_process(SHIELD_GUARD.guard_recovery_duration + 0.01)
	test.check(shield.guard_points == SHIELD_GUARD.guard_capacity and shield.last_behavior_event == &"guard_restored", "broken shield did not recover on its data-owned timer")

	var rear_hit_guard: Node = _spawn_frozen(game, Vector2(820.0, 540.0), "shield_guard")
	var rear_health: int = rear_hit_guard.health
	rear_hit_guard.take_hit(20, Vector2(-300.0, -40.0), true)
	test.check(rear_hit_guard.health == rear_health - 20 and rear_hit_guard.knockdown_state, "rear attack was incorrectly blocked by the shield")

	var elite: Node = _spawn_frozen(game, Vector2(900.0, 540.0), "elite_enforcer")
	for armor_hit in range(ELITE_ENFORCER.knockdown_armor):
		elite.take_hit(10, Vector2(300.0, -50.0), true)
		test.check(not elite.knockdown_state and elite.knockdown_armor_remaining == ELITE_ENFORCER.knockdown_armor - armor_hit - 1, "elite armor did not consume one launch cleanly")
		elite.invulnerable = 0.0
		elite.hurt_timer = 0.0
		elite.stun_timer = 0.0
	elite.take_hit(10, Vector2(300.0, -50.0), true)
	test.check(elite.knockdown_state, "elite remained launch-armored after its authored charges were spent")

	var blade: Node = _spawn_frozen(game, game.player.position + Vector2(42.0, 0.0), "elite_blade")
	game.player.invulnerable = 0.0
	var player_health: int = game.player.health
	blade.combat_target = game.player
	blade._start_attack()
	blade.attack_timer = blade.current_attack.hit_trigger_remaining - 0.01
	blade._check_attack()
	var expected_blade_damage := roundi(ELITE_BLADE.attack.damage * ELITE_BLADE.outgoing_damage_scale)
	test.check(game.player.health == player_health - expected_blade_damage, "elite melee damage scale did not reach the player")

	var bombardier: Node = _spawn_frozen(game, Vector2(880.0, 540.0), "elite_bombardier")
	bombardier.combat_target = game.player
	bombardier._fire_ranged_weapon()
	var projectiles: Array[Node] = test.tree.get_nodes_in_group("weapon_projectiles")
	test.check(not projectiles.is_empty() and is_equal_approx(projectiles.back().source_power_scale_snapshot, ELITE_BOMBARDIER.outgoing_damage_scale), "elite explosive projectile lost source power scaling")

	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemy.gd")
	test.check(not enemy_source.contains("enemy_type ==") and enemy_source.contains("definition.rank"), "roster runtime is not definition-driven")
	var director_source := FileAccess.get_file_as_string("res://stages/encounter_director.gd")
	test.check(director_source.contains("resolved_spawns"), "encounter director bypasses reusable recipe expansion")
	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(probe_source.contains("enemy_roster_preview=2"), "full enemy roster Web fixture is missing")
	test.check(probe_source.contains("held_item_motion_preview=1") and probe_source.contains("_animate_held_item_preview"), "animated player/enemy/prop held-item Web fixture is missing")
	await test.dispose(game)


func _spawn_signature(spawns: Array[Resource]) -> Array[String]:
	var result: Array[String] = []
	for spawn in spawns:
		result.append("%s@%s" % [spawn.enemy_id, spawn.offset])
	return result


func _spawn_frozen(game: Node, position: Vector2, enemy_type: String) -> Node:
	game.spawn_enemy(position, enemy_type)
	var enemy: Node = game.actors.get_child(game.actors.get_child_count() - 1)
	enemy.set_physics_process(false)
	return enemy
