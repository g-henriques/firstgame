class_name DB
## Game data: enemies, weapons and passive upgrades.

const ENEMIES := {
	"bat": {
		"name": "Bat", "sheet": "bat", "hp": 6.0, "speed": 74.0, "damage": 5.0, "xp": 1,
		"from": 0.0, "weight": 6.0,
	},
	"slime": {
		"name": "Slime", "sheet": "slime", "hp": 15.0, "speed": 34.0, "damage": 8.0, "xp": 2,
		"from": 0.0, "weight": 5.0,
	},
	"skeleton": {
		"name": "Skeleton", "sheet": "skeleton", "hp": 26.0, "speed": 46.0, "damage": 10.0, "xp": 3,
		"from": 60.0, "weight": 5.0,
	},
	"ghost": {
		"name": "Ghost", "sheet": "ghost", "hp": 20.0, "speed": 58.0, "damage": 9.0, "xp": 3,
		"from": 150.0, "weight": 3.5, "ghost": true,
	},
	"ogre": {
		"name": "Ogre", "sheet": "ogre", "hp": 110.0, "speed": 30.0, "damage": 18.0, "xp": 10,
		"from": 240.0, "weight": 1.2,
	},
}

const MAX_WEAPON_LEVEL := 5

const WEAPONS := {
	"wand": {
		"name": "Magic Wand",
		"icon": "wand",
		"levels": [
			{"desc": "Fires a magic bolt at the nearest enemy.",
				"damage": 10.0, "cooldown": 1.1, "count": 1, "pierce": 1},
			{"desc": "+3 damage.", "damage": 13.0, "cooldown": 1.0, "count": 1, "pierce": 1},
			{"desc": "+1 bolt.", "damage": 13.0, "cooldown": 0.95, "count": 2, "pierce": 1},
			{"desc": "+5 damage, bolts pierce 1 more enemy.",
				"damage": 18.0, "cooldown": 0.85, "count": 2, "pierce": 2},
			{"desc": "+1 bolt, fires faster.", "damage": 22.0, "cooldown": 0.7, "count": 3, "pierce": 2},
		],
	},
	"knife": {
		"name": "Throwing Knife",
		"icon": "knife",
		"levels": [
			{"desc": "Throws piercing knives where you are facing.",
				"damage": 7.0, "cooldown": 0.9, "count": 1, "pierce": 2},
			{"desc": "+1 knife.", "damage": 8.0, "cooldown": 0.85, "count": 2, "pierce": 2},
			{"desc": "+3 damage, pierces 1 more enemy.",
				"damage": 11.0, "cooldown": 0.75, "count": 2, "pierce": 3},
			{"desc": "+1 knife.", "damage": 12.0, "cooldown": 0.65, "count": 3, "pierce": 3},
			{"desc": "+1 knife, +4 damage.", "damage": 16.0, "cooldown": 0.55, "count": 4, "pierce": 4},
		],
	},
	"aura": {
		"name": "Holy Aura",
		"icon": "aura",
		"levels": [
			{"desc": "Damages and pushes back nearby enemies.",
				"damage": 3.0, "cooldown": 0.6, "radius": 34.0},
			{"desc": "+1 damage, bigger area.", "damage": 4.0, "cooldown": 0.55, "radius": 40.0},
			{"desc": "+1 damage, bigger area.", "damage": 5.0, "cooldown": 0.5, "radius": 46.0},
			{"desc": "+1 damage, hits faster.", "damage": 6.0, "cooldown": 0.42, "radius": 50.0},
			{"desc": "+2 damage, much bigger area.", "damage": 8.0, "cooldown": 0.38, "radius": 60.0},
		],
	},
}

const WEAPON_ORDER := ["wand", "knife", "aura"]

## The 10 passive upgrades (effects applied in Player._recompute_stats).
const PASSIVES := {
	"might": {"name": "Might", "icon": "might", "max": 5, "desc": "+20% damage."},
	"speed": {"name": "Swiftness", "icon": "speed", "max": 5, "desc": "+10% movement speed."},
	"vitality": {"name": "Vitality", "icon": "vitality", "max": 5, "desc": "+20 max health."},
	"recovery": {"name": "Recovery", "icon": "recovery", "max": 5, "desc": "Recover +0.4 health per second."},
	"armor": {"name": "Armor", "icon": "armor", "max": 5, "desc": "-1 damage taken from every hit."},
	"magnet": {"name": "Magnet", "icon": "magnet", "max": 5, "desc": "+40% pickup range."},
	"cooldown": {"name": "Haste", "icon": "cooldown", "max": 5, "desc": "Weapons attack 8% faster."},
	"amount": {"name": "Duplicator", "icon": "amount", "max": 3, "desc": "+1 projectile for every weapon."},
	"area": {"name": "Reach", "icon": "area", "max": 5, "desc": "+15% attack area."},
	"growth": {"name": "Wisdom", "icon": "growth", "max": 5, "desc": "+15% experience gained."},
}

const PASSIVE_ORDER := ["might", "speed", "vitality", "recovery", "armor", "magnet", "cooldown",
	"amount", "area", "growth"]

const HEAL_OPTION := {"name": "Roast Chicken", "icon": "heal", "desc": "Recover 30 health."}


static func is_weapon(id: String) -> bool:
	return WEAPONS.has(id)


static func xp_for_level(level: int) -> float:
	return 5.0 + (level - 1) * 8.0 + floorf(pow(level - 1, 1.5))
