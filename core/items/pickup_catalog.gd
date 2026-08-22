class_name PickupCatalog
extends RefCounted

const SNACK = preload("res://data/items/food_snack.tres")
const RATION = preload("res://data/items/food_ration.tres")
const MEAL = preload("res://data/items/food_meal.tres")
const FEAST = preload("res://data/items/food_feast.tres")
const TOKEN = preload("res://data/items/score_token.tres")
const BADGE = preload("res://data/items/score_badge.tres")
const RELIC = preload("res://data/items/score_relic.tres")
const INTEL = preload("res://data/items/score_intel.tres")

const ALL := [SNACK, RATION, MEAL, FEAST, TOKEN, BADGE, RELIC, INTEL]
const MAP := {
	"food": RATION,
	"food_snack": SNACK,
	"food_ration": RATION,
	"food_meal": MEAL,
	"food_feast": FEAST,
	"score_token": TOKEN,
	"score_badge": BADGE,
	"score_relic": RELIC,
	"score_intel": INTEL,
}


static func from_pickup_id(pickup_id: String) -> Resource:
	return MAP.get(pickup_id)


static func explicit_pickup_ids() -> PackedStringArray:
	return PackedStringArray([
		"food_snack", "food_ration", "food_meal", "food_feast",
		"score_token", "score_badge", "score_relic", "score_intel",
	])
