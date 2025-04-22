class_name ArmorResource extends ItemResource

# ===================== ARMOR RESOURCE =====================
# Base class for all armors

# Variables
@export var ac_bonus : int = 0
@export var level: int = 0
@export var defense: GameConst.ArmorProficiencyCategory = GameConst.ArmorProficiencyCategory.LIGHT
@export var armor_group: String = ""
@export var might_requirement: int = 0
@export var check_penalty: int = 0
@export var speed_penalty: int = 0
@export var agi_cap: int = 0


# ===================== ARMOR FUNCTIONS =====================

func get_ac_bonus() -> int: return ac_bonus
func get_level() -> int: return level
func get_defense() -> GameConst.ArmorProficiencyCategory: return defense
func get_armor_group() -> String: return armor_group
func get_might_requirement() -> int: return might_requirement
func get_check_penalty() -> int: return check_penalty
func get_speed_penalty() -> int: return speed_penalty
func get_agi_cap() -> int: return agi_cap
func get_defense_as_string() -> String:
	return GameConst.get_armor_proficiency_as_string(defense)

func initialize_from_dict(data: Dictionary) -> void:
	super.initialize_from_dict(data)
	ac_bonus = data.get("ac_bonus", ac_bonus)
	level = data.get("level", level)
	defense = GameConst.get_armor_proficiency_from_string(data.get("defense", "light armor").to_lower())
	armor_group = data.get("armor_group", armor_group)
	might_requirement = data.get("might", might_requirement)
	check_penalty = data.get("check_penalty", check_penalty)
	speed_penalty = data.get("speed_penalty", speed_penalty)
	agi_cap = data.get("agi_cap", agi_cap)

func get_dictionary() -> Dictionary:
	var armor_dict: Dictionary = super.get_dictionary()
	armor_dict["AC Bonus"] = ac_bonus
	armor_dict["level"] = level
	armor_dict["Defense Type"] = GameConst.get_armor_proficiency_category_as_string(defense)
	armor_dict["Armor Group"] = armor_group
	armor_dict["Might Requirement"] = might_requirement
	armor_dict["Check Penalty"] = check_penalty
	armor_dict["Speed Penalty"] = speed_penalty
	armor_dict["Agility Cap"] = agi_cap
	return armor_dict
