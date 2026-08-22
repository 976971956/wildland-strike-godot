extends RefCounted

const STAGES := [
	preload("res://data/stages/stage_1/stage_1.tres"),
	preload("res://data/stages/stage_2/stage_2.tres"),
	preload("res://data/stages/stage_3/stage_3.tres"),
	preload("res://data/stages/stage_4/stage_4.tres"),
	preload("res://data/stages/stage_5/stage_5.tres"),
	preload("res://data/stages/stage_6/stage_6.tres"),
	preload("res://data/stages/stage_7/stage_7.tres"),
	preload("res://data/stages/stage_8/stage_8.tres"),
]
const HEROES := [
	preload("res://data/heroes/ranger.tres"),
	preload("res://data/heroes/mara.tres"),
	preload("res://data/heroes/kestrel.tres"),
	preload("res://data/heroes/atlas.tres"),
]
const PARTY_HEALTH := [1.0, 1.4, 1.7]
const PARTY_DAMAGE := [1.0, 1.08, 1.16]
const HERO_COMBINATIONS := [
	[0], [1], [2], [3],
	[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3],
	[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3],
]


func run(test) -> void:
	test.check(STAGES.size() == 8 and HERO_COMBINATIONS.size() == 14, "release balance matrix coverage drifted")
	for stage_index in range(STAGES.size()):
		var stage: Resource = STAGES[stage_index]
		for player_count in range(1, 4):
			var health_scale: float = stage.enemy_health_scale * PARTY_HEALTH[player_count - 1]
			var damage_scale: float = stage.enemy_damage_scale * PARTY_DAMAGE[player_count - 1]
			test.check(health_scale >= 1.0 and health_scale <= 2.754, "Stage %d P%d enemy health left the documented release curve" % [stage_index + 1, player_count])
			test.check(damage_scale >= 1.0 and damage_scale <= 1.508, "Stage %d P%d enemy damage left the documented release curve" % [stage_index + 1, player_count])
			if player_count > 1:
				test.check(health_scale > stage.enemy_health_scale and health_scale / player_count < stage.enemy_health_scale, "Stage %d P%d does not add health while rewarding cooperation" % [stage_index + 1, player_count])
				test.check(damage_scale / stage.enemy_damage_scale <= 1.16, "Stage %d P%d co-op damage pressure exceeds the release cap" % [stage_index + 1, player_count])

	for hero: Resource in HEROES:
		var solo_ttk_ratio: float = 1.0 / hero.damage_scale
		var survival_ratio: float = hero.max_health / 120.0
		test.check(solo_ttk_ratio >= 0.75 and solo_ttk_ratio <= 1.18, "%s solo damage falls outside the accepted TTK band" % hero.display_name)
		test.check(survival_ratio >= 0.75 and survival_ratio <= 1.25, "%s health falls outside the accepted survival band" % hero.display_name)
		if hero.hero_id != &"ranger":
			var strengths := 0
			var tradeoffs := 0
			for value in [hero.damage_scale, hero.item_efficiency, hero.aerial_control, hero.grapple_power]:
				strengths += 1 if value > 1.0 else 0
				tradeoffs += 1 if value < 1.0 else 0
			test.check(strengths >= 1 and tradeoffs >= 1, "%s no longer has both a role strength and tradeoff" % hero.display_name)

	for roster: Array in HERO_COMBINATIONS:
		var combined_damage := 0.0
		for hero_index: int in roster:
			combined_damage += HEROES[hero_index].damage_scale
		var encounter_ttk_ratio: float = PARTY_HEALTH[roster.size() - 1] / combined_damage
		if roster.size() == 1:
			test.check(encounter_ttk_ratio >= 0.75 and encounter_ttk_ratio <= 1.18, "solo roster %s left the accepted TTK band" % [roster])
		else:
			test.check(encounter_ttk_ratio >= 0.52 and encounter_ttk_ratio <= 0.82, "co-op roster %s left the accepted teamwork TTK band" % [roster])

	var game: Node = await test.instantiate_main()
	if game == null:
		return
	for stage: Resource in STAGES:
		game.active_stage_definition = stage
		for player_count in range(1, 4):
			while game.coop_player_count() < player_count:
				game.join_local_player(game.coop_player_count() - 1, game.coop_player_count())
			test.check(is_equal_approx(game.coop_enemy_health_scale(), stage.enemy_health_scale * PARTY_HEALTH[player_count - 1]), "Stage %d P%d runtime health scale differs from the matrix" % [stage.stage_number, player_count])
			test.check(is_equal_approx(game.coop_enemy_damage_scale(), stage.enemy_damage_scale * PARTY_DAMAGE[player_count - 1]), "Stage %d P%d runtime damage scale differs from the matrix" % [stage.stage_number, player_count])
		while game.coop_player_count() > 1:
			var last_slot = game.local_player_registry.active_slots().back()
			game.leave_local_player(last_slot.device_id)
	await test.dispose(game)
