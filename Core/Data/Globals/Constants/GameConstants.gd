extends Node
const GAME_VERSION = "0.1.0"
enum DamageType { PHYSICAL, FIRE, COLD, ACID, POISON, PIERCING, SLASHING, BLUDGEONING, LIGHTNING, THUNDER, NECROTIC, PSYCHIC, RADIANT }
enum DamageCategory { MELEE, RANGED, MAGIC, NATURAL, UNARMED }
enum Condition { BLINDED, POISONED, FRIGHTENED}
enum MonsterSize { TINY, SMALL, MEDIUM, LARGE, HUGE, GARGANTUAN }
enum SensePrecision { PRECISE, IMPRECISE, VAGUE }
enum CostType { AP, HP, SP, AEP }
enum MonsterTemplateType { WEAK, ELITE}
enum WeaponGroup { AXE, BOMB, BOW, BRAWLING, CLUB, CROSSBOW, DART, FLAIL, HAMMER, KNIFE, PICK, POLEARM, SHIELD, SLING, SPEAR, SWORD}
enum WeaponProficiencyCategory { SIMPLE, MARTIAL, UNARMED, ADVANCED }
enum ArmorProficiencyCategory { LIGHT, MEDIUM, HEAVY, SHIELD, UNARMORED }

const CURRENCY_ORDER = ["platinum", "gold", "silver", "copper"]
const CURRENCY_VALUES = {
	"copper": 1.0,
	"silver": 10.0,  # 1 silver = 10 copper
	"gold": 100.0,   # 1 gold = 100 copper
	"platinum": 1000.0,  # 1 platinum = 1000 copper
	# You could easily add more here, e.g., "platinum": 1000.0
}
const MONSTER_TILE_DIMENSIONS = {
	MonsterSize.TINY: 1,
	MonsterSize.SMALL: 1,
	MonsterSize.MEDIUM: 1,
	MonsterSize.LARGE: 2,
	MonsterSize.HUGE: 3,
	MonsterSize.GARGANTUAN: 4
}
const ALLOWED_MONSTER_TRAITS = [
	"Creature Type",
	"Monster",
	"Rarity",
	"Elemental",
	"Energy",
	"Alignment",
	"Size"
]
enum MovementState { LAND, FLY, SWIM, CLIMB, BURROW }
enum ProficiencyRanks { UNTRAINED, NOVICE, ADEPT, EXPERT, MASTER }
const RANKS : Dictionary = {
	ProficiencyRanks.UNTRAINED: -2,
	ProficiencyRanks.NOVICE: 2,
	ProficiencyRanks.ADEPT: 4,
	ProficiencyRanks.EXPERT: 6,
	ProficiencyRanks.MASTER: 8
}

const MONSTER_SKILLS: Dictionary = {
	"Acrobatics": 0,
	"Alchemy": 0,
	"Arcana": 0,
	"Athletics": 0,
	"Crafting": 0,
	"Deception": 0,
	"Diplomacy": 0,
	"Empathy": 0,  
	"Enchanting": 0, 
	"Intimidation": 0,
	"Lore": 0,   
	"Medicine": 0,
	"Nature": 0,
	"Occultism": 0,
	"Performance": 0,
	"Religion": 0,
	"Society": 0,
	"Stealth": 0,
	"Survival": 0,
	"Thievery": 0
}

enum MonsterAbilityCategory { PROACTIVE, AUTOMATIC, PASSIVE } # Helps differentiate

const CARRYING_CAPACITY: Dictionary = {
	MonsterSize.TINY: 50,
	MonsterSize.SMALL: 100,
	MonsterSize.MEDIUM: 150,
	MonsterSize.LARGE: 300,
	MonsterSize.HUGE: 600,
	MonsterSize.GARGANTUAN: 1200
}

const PLAYER_SKILLS: Dictionary = {
	"Acrobatics": ProficiencyRanks.UNTRAINED,
	"Alchemy": ProficiencyRanks.UNTRAINED,
	"Arcana": ProficiencyRanks.UNTRAINED,
	"Athletics": ProficiencyRanks.UNTRAINED,
	"Crafting": ProficiencyRanks.UNTRAINED,
	"Deception": ProficiencyRanks.UNTRAINED,
	"Diplomacy": ProficiencyRanks.UNTRAINED,
	"Empathy": ProficiencyRanks.UNTRAINED,
	"Enchanting": ProficiencyRanks.UNTRAINED,
	"Intimidation": ProficiencyRanks.UNTRAINED,
	"Lore": ProficiencyRanks.UNTRAINED,
	"Medicine": ProficiencyRanks.UNTRAINED,
	"Nature": ProficiencyRanks.UNTRAINED,
	"Occultism": ProficiencyRanks.UNTRAINED,
	"Performance": ProficiencyRanks.UNTRAINED,
	"Religion": ProficiencyRanks.UNTRAINED,
	"Society": ProficiencyRanks.UNTRAINED,
	"Stealth": ProficiencyRanks.UNTRAINED,
	"Survival": ProficiencyRanks.UNTRAINED,
	"Thievery": ProficiencyRanks.UNTRAINED,
}

func get_damage_type_as_string(damage_type: DamageType) -> String:
	match damage_type:
		DamageType.PHYSICAL: return "Physical"
		DamageType.FIRE: return "Fire"
		DamageType.COLD: return "Cold"
		DamageType.ACID: return "Acid"
		DamageType.POISON: return "Poison"
		DamageType.PIERCING: return "Piercing"
		DamageType.SLASHING: return "Slashing"
		DamageType.BLUDGEONING: return "Bludgeoning"
		DamageType.LIGHTNING: return "Lightning"
		DamageType.THUNDER: return "Thunder"
		DamageType.NECROTIC: return "Necrotic"
		DamageType.PSYCHIC: return "Psychic"
		DamageType.RADIANT: return "Radiant"
		_:
			printerr("Error: Unknown damage type.")
			return "Unknown"

func get_damage_type_from_string(damage_type: String) -> DamageType:
	damage_type = damage_type.to_lower()
	match damage_type:
		"physical": return DamageType.PHYSICAL
		"fire": return DamageType.FIRE
		"cold": return DamageType.COLD
		"acid": return DamageType.ACID
		"poison": return DamageType.POISON
		"piercing": return DamageType.PIERCING
		"slashing": return DamageType.SLASHING
		"bludgeoning": return DamageType.BLUDGEONING
		"lightning": return DamageType.LIGHTNING
		"thunder": return DamageType.THUNDER
		"necrotic": return DamageType.NECROTIC
		"psychic": return DamageType.PSYCHIC
		"radiant": return DamageType.RADIANT
		_:
			printerr("Error: Unknown damage type.")
			return DamageType.PHYSICAL

func get_monster_size_as_string(size: MonsterSize) -> String:
	match size:
		MonsterSize.TINY: return "Tiny"
		MonsterSize.SMALL: return "Small"
		MonsterSize.MEDIUM: return "Medium"
		MonsterSize.LARGE: return "Large"
		MonsterSize.HUGE: return "Huge"
		MonsterSize.GARGANTUAN: return "Gargantuan"
		_:
			printerr("Error: Unknown monster size.")
			return "Unknown"

func get_damage_category_as_string(category: DamageCategory) -> String:
	match category:
		DamageCategory.MELEE: return "Melee"
		DamageCategory.RANGED: return "Ranged"
		DamageCategory.MAGIC: return "Magic"
		DamageCategory.NATURAL: return "Natural"
		DamageCategory.UNARMED: return "Unarmed"
		_:
			printerr("Error: Unknown damage category.")
			return "Unknown"

func get_damage_category_from_string(category: String) -> DamageCategory:
	category = category.to_lower()
	match category:
		"melee": return DamageCategory.MELEE
		"ranged": return DamageCategory.RANGED
		"magic": return DamageCategory.MAGIC
		"natural": return DamageCategory.NATURAL
		"unarmed": return DamageCategory.UNARMED
		_:
			printerr("Error: Unknown damage category.")
			return DamageCategory.MELEE

func get_condition_as_string(condition: Condition) -> String:
	match condition:
		Condition.BLINDED: return "Blinded"
		Condition.POISONED: return "Poisoned"
		Condition.FRIGHTENED: return "Frightened"
		_:
			printerr("Error: Unknown condition.")
			return "Unknown"

func get_monster_ability_category_as_string(category: MonsterAbilityCategory) -> String:
	match category:
		MonsterAbilityCategory.PROACTIVE: return "Proactive"
		MonsterAbilityCategory.AUTOMATIC: return "Automatic"
		MonsterAbilityCategory.PASSIVE: return "Passive"
		_:
			printerr("Error: Unknown monster ability category.")
			return "Unknown"

func get_template_type_as_string(template_type: MonsterTemplateType) -> String:
	match template_type:
		MonsterTemplateType.WEAK: return "Weak"
		MonsterTemplateType.ELITE: return "Elite"
		_:
			printerr("Error: Unknown monster template type.")
			return "Unknown"

func get_weapon_group_as_string(weapon_group: WeaponGroup) -> String:
	match weapon_group:
		WeaponGroup.AXE: return "Axe"
		WeaponGroup.BOMB: return "Bomb"
		WeaponGroup.BOW: return "Bow"
		WeaponGroup.BRAWLING: return "Brawling"
		WeaponGroup.CLUB: return "Club"
		WeaponGroup.CROSSBOW: return "Crossbow"
		WeaponGroup.DART: return "Dart"
		WeaponGroup.FLAIL: return "Flail"
		WeaponGroup.HAMMER: return "Hammer"
		WeaponGroup.KNIFE: return "Knife"
		WeaponGroup.PICK: return "Pick"
		WeaponGroup.POLEARM: return "Polearm"
		WeaponGroup.SHIELD: return "Shield"
		WeaponGroup.SLING: return "Sling"
		WeaponGroup.SPEAR: return "Spear"
		WeaponGroup.SWORD: return "Sword"
		_:
			printerr("Error: Unknown weapon group.")
			return "Unknown"

func get_weapon_group_from_string(weapon_group: String) -> WeaponGroup:
	weapon_group = weapon_group.to_lower()
	match weapon_group:
		"axe": return WeaponGroup.AXE
		"bomb": return WeaponGroup.BOMB
		"bow": return WeaponGroup.BOW
		"brawling": return WeaponGroup.BRAWLING
		"club": return WeaponGroup.CLUB
		"crossbow": return WeaponGroup.CROSSBOW
		"dart": return WeaponGroup.DART
		"flail": return WeaponGroup.FLAIL
		"hammer": return WeaponGroup.HAMMER
		"knife": return WeaponGroup.KNIFE
		"pick": return WeaponGroup.PICK
		"polearm": return WeaponGroup.POLEARM
		"shield": return WeaponGroup.SHIELD
		"sling": return WeaponGroup.SLING
		"spear": return WeaponGroup.SPEAR
		"sword": return WeaponGroup.SWORD
		_:
			printerr("Error: Unknown weapon group.")
			return WeaponGroup.BRAWLING

func get_proficiency_rank_as_string(rank: ProficiencyRanks) -> String:
	match rank:
		ProficiencyRanks.UNTRAINED: return "Untrained"
		ProficiencyRanks.NOVICE: return "Novice"
		ProficiencyRanks.ADEPT: return "Adept"
		ProficiencyRanks.EXPERT: return "Expert"
		ProficiencyRanks.MASTER: return "Master"
		_:
			printerr("Error: Unknown proficiency rank.")
			return "Unknown"

func get_weapon_proficiency_category_as_string(weapon_proficiency: WeaponProficiencyCategory) -> String:
	match weapon_proficiency:
		WeaponProficiencyCategory.SIMPLE: return "Simple"
		WeaponProficiencyCategory.MARTIAL: return "Martial"
		WeaponProficiencyCategory.UNARMED: return "Unarmed"
		WeaponProficiencyCategory.ADVANCED: return "Advanced"
		_:
			printerr("Error: Unknown weapon proficiency category.")
			return "Unknown"

func get_armor_proficiency_category_as_string(armor_proficiency: ArmorProficiencyCategory) -> String:
	match armor_proficiency:
		ArmorProficiencyCategory.LIGHT: return "Light"
		ArmorProficiencyCategory.MEDIUM: return "Medium"
		ArmorProficiencyCategory.HEAVY: return "Heavy"
		ArmorProficiencyCategory.SHIELD: return "Shield"
		ArmorProficiencyCategory.UNARMORED: return "Unarmored"
		_:
			printerr("Error: Unknown armor proficiency category.")
			return "Unknown"

func get_weapon_proficiency_from_string(weapon_proficiency: String) -> WeaponProficiencyCategory:
	weapon_proficiency = weapon_proficiency.to_lower()
	match weapon_proficiency:
		"simple": return WeaponProficiencyCategory.SIMPLE
		"martial": return WeaponProficiencyCategory.MARTIAL
		"unarmed": return WeaponProficiencyCategory.UNARMED
		"advanced": return WeaponProficiencyCategory.ADVANCED
		_:
			printerr("Error: Unknown weapon proficiency category.")
			return WeaponProficiencyCategory.UNARMED

func get_armor_proficiency_from_string(armor_proficiency: String) -> ArmorProficiencyCategory:
	armor_proficiency = armor_proficiency.to_lower()
	match armor_proficiency:
		"light armor": return ArmorProficiencyCategory.LIGHT
		"medium armor": return ArmorProficiencyCategory.MEDIUM
		"heavy armor": return ArmorProficiencyCategory.HEAVY
		"shield": return ArmorProficiencyCategory.SHIELD
		"unarmored defense": return ArmorProficiencyCategory.UNARMORED
		_:
			printerr("Error: Unknown armor proficiency category.")
			return ArmorProficiencyCategory.UNARMORED

func has_template_in_name(monster_name: String, _type: MonsterTemplateType) -> bool:
	# Get the string representation for each known template
	var template_string = get_template_type_as_string(_type)

	if monster_name.ends_with(" (" + template_string + ")"):
		return true
	else:
		return false

func has_any_template_in_name(monster_name: String) -> bool:
	for key_name in MonsterTemplateType.keys():
		var template_type = MonsterTemplateType[key_name]
		if has_template_in_name(monster_name, template_type):
			return true
	return false

func extract_template_suffix_from_name(monster_name: String) -> String:
	# Iterate through all defined enum member NAMES (keys)
	for key_name in MonsterTemplateType.keys():
		# Get the actual enum VALUE (e.g., MonsterTemplateType.WEAK) from its key name
		var template_type = MonsterTemplateType[key_name]

		# Get the string representation for this specific template type
		var template_string = get_template_type_as_string(template_type)

		# Skip if the template type doesn't have a string representation (e.g., a NONE type)
		if template_string.is_empty():
			continue

		# --- Case-insensitive check (same as before) ---
		var pattern_to_find = " (" + template_string + ")"
		var pattern_len = pattern_to_find.length()

		if monster_name.length() >= pattern_len:
			var actual_suffix = monster_name.right(pattern_len)
			if actual_suffix.to_lower() == pattern_to_find.to_lower():
				return actual_suffix # Found it! Return the actual suffix found.
	return "" # No known template suffix found

func strip_template_suffix_from_name(monster_name: String) -> String:
	var suffix = extract_template_suffix_from_name(monster_name) # Now uses the dynamic extract
	if not suffix.is_empty():
		return monster_name.substr(0, monster_name.length() - suffix.length())
	else:
		return monster_name

func get_height_constraints_from_size(_size: MonsterSize) -> Dictionary:
	const METER_TO_FEET: float = 3.28084
	var height_constraints: Dictionary = {
		MonsterSize.TINY: {"min": 0.1 * METER_TO_FEET, "max": 0.6 * METER_TO_FEET},
		MonsterSize.SMALL: {"min": 0.6 * METER_TO_FEET, "max": 1.2 * METER_TO_FEET},
		MonsterSize.MEDIUM: {"min": 1.2 * METER_TO_FEET, "max": 2.1 * METER_TO_FEET},
		MonsterSize.LARGE: {"min": 2.4 * METER_TO_FEET, "max": 4.6 * METER_TO_FEET},
		MonsterSize.HUGE: {"min": 4.6 * METER_TO_FEET, "max": 9.1 * METER_TO_FEET},
		MonsterSize.GARGANTUAN: {"min": 9.1 * METER_TO_FEET, "max": 18.3 * METER_TO_FEET}
	}
	return height_constraints[_size]

func get_weight_constraints_from_size(_size: MonsterSize) -> Dictionary:
	var weight_constraints: Dictionary = {
		MonsterSize.TINY: {"min": 1.0, "max": 20.0},
		MonsterSize.SMALL: {"min": 20.0, "max": 150.0},
		MonsterSize.MEDIUM: {"min": 80.0, "max": 400.0},
		MonsterSize.LARGE: {"min": 200.0, "max": 1500.0},
		MonsterSize.HUGE: {"min": 1000.0, "max": 10000.0},
		MonsterSize.GARGANTUAN: {"min": 5000.0, "max": 50000.0}
	}
	return weight_constraints[_size]

func get_average_weight_from_size(_size: MonsterSize) -> int:
	var weight_average: Dictionary = {
		MonsterSize.TINY: 5,
		MonsterSize.SMALL: 75,
		MonsterSize.MEDIUM: 100,
		MonsterSize.LARGE: 250,
		MonsterSize.HUGE: 2100,
		MonsterSize.GARGANTUAN: 9000
	}
	return weight_average[_size]

func get_size_multiplier_from_size(_size: MonsterSize) -> float:
	var size_multiplier: Dictionary = {
		MonsterSize.TINY: 1,
		MonsterSize.SMALL: 25,
		MonsterSize.MEDIUM: 30,
		MonsterSize.LARGE: 100,
		MonsterSize.HUGE: 480,
		MonsterSize.GARGANTUAN: 1920
	}
	return size_multiplier[_size]
