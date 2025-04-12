extends Node
const GAME_VERSION = "0.1.0"
enum DamageType { PHYSICAL, FIRE, COLD, ACID, POISON, PIERCING, SLASHING, BLUDGEONING, LIGHTNING, THUNDER, NECROTIC, PSYCHIC, RADIANT }
enum DamageCategory { MELEE, RANGED, MAGIC, NATURAL, UNARMED }
enum Condition { BLINDED, POISONED, FRIGHTENED}
enum MonsterSize { TINY, SMALL, MEDIUM, LARGE, HUGE, GARGANTUAN }
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
