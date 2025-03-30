class_name MonsterSheet extends Resource

# Basic info
@export var monster_name: String = "Default Monster"
@export_multiline var description: String = ""

# Basic stats
@export var level: int = 1
@export var size: GameConst.MonsterSize = GameConst.MonsterSize.MEDIUM
@export var speed: int = 30 # Base speed
@export var armor_class: int = 10

# Attributes (Storing Scores)
@export var might_score: int = 10
@export var agility_score: int = 10
@export var endurance_score: int = 10
@export var intelligence_score: int = 10
@export var wisdom_score: int = 10
@export var charisma_score: int = 10

# Defenses
@export var damage_immunities: Array[GameConst.DamageType] = []
@export var damage_resistances: Array[GameConst.DamageType] = []
@export var damage_weaknesses: Array[GameConst.DamageType] = []
@export var condition_immunities: Array[GameConst.Condition] = []

# Stat resources (Maximums/Base)
@export var health_points: int = 10 # Often calculated from Endurance + Hit Dice
@export var action_points: int = 1  # Example: Base number of actions per turn
@export var aether_points: int = 0  # Example: Mana/Spell points

# Senses
@export var perception_score: int = 10 # Usually 10 + Wis mod (+ prof if skilled)

# Offensive stats (Example using dice strings and derived bonuses)
# Note: Bonuses might be calculated elsewhere based on attributes/level/proficiency
# @export var melee_attack_bonus: int = 0 # Or calculate this!
# @export var melee_damage_dice: String = "1d6"

# Extra (Using dedicated Resources is recommended)
@export var traits: Array[TraitResource] = [] # Assuming TraitResource exists
@export var languages: Array = ["Common"]
@export var skills_proficiency: Array[String] = [] # List names of proficient skills
@export var possible_items: Array[ItemResource] = [] # Loot table?
@export var abilities: Array[AbilityResource] = [] # Actions, reactions, etc.
@export var spells: Array[SpellResource] = []
# @export var talents: Array = [] # What are these? Clarify or merge.

# --- Helper function example ---
func get_modifier(score: int) -> int:
	return score

func get_might_modifier() -> int: return get_modifier(might_score)
func get_agility_modifier() -> int: return get_modifier(agility_score)
func get_endurance_modifier() -> int: return get_modifier(endurance_score)
func get_intelligence_modifier() -> int: return get_modifier(intelligence_score)
func get_wisdom_modifier() -> int: return get_modifier(wisdom_score)
func get_charisma_modifier() -> int: return get_modifier(charisma_score)
# ... etc for other attributes

func get_unit_name() -> String:
	return monster_name