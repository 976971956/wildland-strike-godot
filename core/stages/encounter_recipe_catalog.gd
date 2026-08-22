class_name EncounterRecipeCatalog
extends RefCounted

const STREET_PATROL = preload("res://data/encounter_recipes/street_patrol.tres")
const DEMOLITION_CROSSFIRE = preload("res://data/encounter_recipes/demolition_crossfire.tres")
const ELITE_ASSAULT = preload("res://data/encounter_recipes/elite_assault.tres")
const ECOLOGY_COLLISION = preload("res://data/encounter_recipes/ecology_collision.tres")

const ALL := [
	STREET_PATROL,
	DEMOLITION_CROSSFIRE,
	ELITE_ASSAULT,
	ECOLOGY_COLLISION,
]


static func by_id(recipe_id: StringName) -> Resource:
	for recipe in ALL:
		if recipe.recipe_id == recipe_id:
			return recipe
	return null
