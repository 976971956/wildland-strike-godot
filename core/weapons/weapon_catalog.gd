class_name WeaponCatalog
extends RefCounted

const MACHETE = preload("res://data/weapons/machete.tres")
const PIPE = preload("res://data/weapons/pipe.tres")
const WHIP = preload("res://data/weapons/whip.tres")
const SHOCK_BATON = preload("res://data/weapons/shock_baton.tres")
const PISTOL = preload("res://data/weapons/pistol.tres")
const SHOTGUN = preload("res://data/weapons/shotgun.tres")
const RIFLE = preload("res://data/weapons/rifle.tres")
const SMG = preload("res://data/weapons/smg.tres")
const GRENADE = preload("res://data/weapons/grenade.tres")
const MOLOTOV = preload("res://data/weapons/molotov.tres")
const ROCKET = preload("res://data/weapons/rocket.tres")
const MINE = preload("res://data/weapons/mine.tres")

const ALL := [
	MACHETE, PIPE, WHIP, SHOCK_BATON,
	PISTOL, SHOTGUN, RIFLE, SMG,
	GRENADE, MOLOTOV, ROCKET, MINE,
]

const PICKUP_MAP := {
	"weapon": MACHETE,
	"weapon_melee": MACHETE,
	"weapon_firearm": PISTOL,
	"weapon_explosive": GRENADE,
	"weapon_machete": MACHETE,
	"weapon_pipe": PIPE,
	"weapon_whip": WHIP,
	"weapon_shock_baton": SHOCK_BATON,
	"weapon_pistol": PISTOL,
	"weapon_shotgun": SHOTGUN,
	"weapon_rifle": RIFLE,
	"weapon_smg": SMG,
	"weapon_grenade": GRENADE,
	"weapon_molotov": MOLOTOV,
	"weapon_rocket": ROCKET,
	"weapon_mine": MINE,
}

const ATLAS_INDEX_BY_WEAPON_ID := {
	&"machete": 0,
	&"pipe": 1,
	&"whip": 2,
	&"shock_baton": 3,
	&"pistol": 4,
	&"shotgun": 5,
	&"rifle": 6,
	&"smg": 7,
	&"grenade": 8,
	&"molotov": 9,
	&"rocket": 10,
	&"mine": 11,
}


static func from_pickup_id(pickup_id: String) -> Resource:
	return PICKUP_MAP.get(pickup_id, MACHETE)


static func atlas_index_for_weapon(weapon: Resource) -> int:
	if weapon == null:
		return -1
	return int(ATLAS_INDEX_BY_WEAPON_ID.get(weapon.weapon_id, -1))


static func atlas_index_for_pickup_id(pickup_id: String) -> int:
	if not PICKUP_MAP.has(pickup_id):
		return -1
	return atlas_index_for_weapon(PICKUP_MAP[pickup_id])


static func explicit_pickup_ids() -> PackedStringArray:
	return PackedStringArray([
		"weapon_machete", "weapon_pipe", "weapon_whip", "weapon_shock_baton",
		"weapon_pistol", "weapon_shotgun", "weapon_rifle", "weapon_smg",
		"weapon_grenade", "weapon_molotov", "weapon_rocket", "weapon_mine",
	])
