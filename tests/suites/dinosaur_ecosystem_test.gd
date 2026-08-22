extends RefCounted

const EnemyDefinitionScript = preload("res://core/combat/enemy_definition.gd")
const StreetEnemyScript = preload("res://scripts/enemy.gd")
const DINOSAURS := [
	preload("res://data/enemies/compy.tres"),
	preload("res://data/enemies/raptor.tres"),
	preload("res://data/enemies/ankylosaur.tres"),
	preload("res://data/enemies/triceratops.tres"),
]


func run(test) -> void:
	var ids := {}
	var behaviors := {}
	var textures := {}
	var sleeping_archetypes := 0
	for dinosaur: Resource in DINOSAURS:
		test.check(dinosaur.is_valid_definition(), "%s dinosaur definition is invalid" % dinosaur.enemy_id)
		test.check(dinosaur.dinosaur_archetype, "%s is not marked as a dinosaur archetype" % dinosaur.enemy_id)
		test.check(dinosaur.faction == EnemyDefinitionScript.Faction.NEUTRAL_CREATURE, "%s lost neutral-creature faction" % dinosaur.enemy_id)
		test.check(not dinosaur.can_be_grabbed, "%s can incorrectly be grabbed" % dinosaur.enemy_id)
		test.check(not ids.has(dinosaur.enemy_id), "%s duplicates a dinosaur id" % dinosaur.enemy_id)
		test.check(not textures.has(dinosaur.sprite_sheet.resource_path), "%s reuses another dinosaur sheet" % dinosaur.enemy_id)
		ids[dinosaur.enemy_id] = true
		textures[dinosaur.sprite_sheet.resource_path] = true
		behaviors[dinosaur.behavior_kind] = true
		sleeping_archetypes += int(dinosaur.starts_sleeping)
		var image: Image = dinosaur.sprite_sheet.get_image()
		test.check(image.get_size() == Vector2i(2560, 320), "%s atlas is not an isolated 8x320 strip" % dinosaur.enemy_id)
		test.check(image.detect_alpha() != Image.ALPHA_NONE, "%s atlas lost transparent gutters" % dinosaur.enemy_id)
	test.check(ids.size() == 4 and textures.size() == 4, "dinosaur catalog does not contain four visually distinct archetypes")
	test.check(behaviors.size() == 4, "dinosaur archetypes do not own four distinct behavior families")
	test.check(sleeping_archetypes == 2, "authored sleeping dinosaur distribution drifted")

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	game.set_process(false)
	game.player.set_physics_process(false)
	game._start_game()
	game.player.position = Vector2(300.0, 540.0)

	var ankylosaur: Node = _spawn_frozen(game, Vector2(1200.0, 555.0), "ankylosaur")
	test.check(ankylosaur.creature_state == StreetEnemyScript.CreatureState.SLEEPING, "ankylosaur did not spawn sleeping")
	test.check(ankylosaur._visual_column() == 1, "sleeping dinosaur did not use the sleep pose")
	ankylosaur._think(1.0 / 60.0)
	test.check(ankylosaur.velocity == Vector2.ZERO, "sleeping dinosaur entered ordinary AI movement")
	test.check(not ankylosaur._try_wake_from_proximity(), "distant player incorrectly woke the sleeping dinosaur")

	var raider: Node = _spawn_frozen(game, Vector2(1350.0, 555.0), "grunt")
	test.check(ankylosaur._try_wake_from_proximity(), "nearby opposing faction did not wake the dinosaur")
	test.check(ankylosaur.creature_state == StreetEnemyScript.CreatureState.NEUTRAL, "woken dinosaur skipped the neutral state")
	test.check(ankylosaur.last_behavior_event == &"creature_woke", "wake transition was not observable")
	ankylosaur._update_combat_target()
	test.check(ankylosaur.combat_target == raider, "woken dinosaur did not select the nearby human faction")

	var enrage_damage: int = ankylosaur.health - ceili(ankylosaur.max_health * ankylosaur.definition.enrage_health_ratio) + 1
	ankylosaur.take_hit(enrage_damage, Vector2.ZERO, false)
	test.check(ankylosaur.creature_state == StreetEnemyScript.CreatureState.ENRAGED, "health threshold did not enrage the dinosaur")
	test.check(is_equal_approx(ankylosaur.speed, ankylosaur.base_speed * ankylosaur.definition.enrage_speed_scale), "enrage speed multiplier drifted")
	test.check(ankylosaur.last_behavior_event == &"creature_enraged", "enrage transition was not observable")
	ankylosaur.hurt_timer = 0.0
	ankylosaur.stun_timer = 0.0
	ankylosaur.invulnerable = 0.0
	ankylosaur.position = raider.position - Vector2(60.0, 0.0)
	ankylosaur.combat_target = raider
	ankylosaur._think(1.0 / 60.0)
	var human_health_before: int = raider.health
	ankylosaur.attack_timer = ankylosaur.current_attack.hit_trigger_remaining - 0.01
	ankylosaur._check_attack()
	var expected_enraged_damage := roundi(ankylosaur.current_attack.damage * ankylosaur.definition.enrage_damage_scale)
	test.check(raider.health == human_health_before - expected_enraged_damage, "enraged damage multiplier did not apply across factions")

	var triceratops: Node = _spawn_frozen(game, Vector2(520.0, 555.0), "triceratops")
	test.check(triceratops.creature_state == StreetEnemyScript.CreatureState.SLEEPING, "triceratops did not spawn sleeping")
	test.check(triceratops._try_wake_from_proximity(), "nearby player did not wake the triceratops")
	var compy: Node = _spawn_frozen(game, Vector2(760.0, 555.0), "compy")
	var raptor: Node = _spawn_frozen(game, Vector2(770.0, 555.0), "raptor")
	compy._update_combat_target()
	raptor._update_combat_target()
	test.check(compy.combat_target != raptor and raptor.combat_target != compy, "neutral dinosaurs targeted their own faction")
	test.check(compy.creature_state == StreetEnemyScript.CreatureState.NEUTRAL and raptor.creature_state == StreetEnemyScript.CreatureState.NEUTRAL, "active dinosaur neutral state drifted")

	var probe_source := FileAccess.get_file_as_string("res://scripts/performance_probe.gd")
	test.check(probe_source.contains("dinosaur_ecosystem_preview=1"), "reproducible dinosaur Web fixture is missing")
	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemy.gd")
	test.check(enemy_source.contains("definition.dinosaur_archetype") and enemy_source.contains("CreatureState"), "dinosaur ecology state is not data-driven")
	await test.dispose(game)


func _spawn_frozen(game: Node, position: Vector2, enemy_type: String) -> Node:
	game.spawn_enemy(position, enemy_type)
	var enemy: Node = game.actors.get_child(game.actors.get_child_count() - 1)
	enemy.set_physics_process(false)
	return enemy
