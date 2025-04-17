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
		_:
			printerr("Error: Unknown armor proficiency category.")
			return "Unknown"

func get_armor_proficiency_from_string(armor_proficiency: String) -> ArmorProficiencyCategory:
	armor_proficiency = armor_proficiency.to_lower()
	match armor_proficiency:
		"light armor": return ArmorProficiencyCategory.LIGHT
		"medium armor": return ArmorProficiencyCategory.MEDIUM
		"heavily armored": return ArmorProficiencyCategory.HEAVY
		"shield": return ArmorProficiencyCategory.SHIELD
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
