class_name WeaponResource extends ItemResource

# ===================== WEAPON RESOURCE =====================
# Base class for all weapons

# Variables
@export var damage_string: String = "1d4"
@export var level: int = 0
@export var damage_type: GameConst.DamageType = GameConst.DamageType.BLUDGEONING
@export var weapon_group: GameConst.WeaponGroup = GameConst.WeaponGroup.BRAWLING
@export var damage_category: GameConst.DamageCategory = GameConst.DamageCategory.MELEE
@export var weapon_proficiency_category : GameConst.WeaponProficiencyCategory = GameConst.WeaponProficiencyCategory.SIMPLE
@export var damage_bonus: int = 0
@export var hand_requirement: int = 1
@export var range: int = 5

# ===================== WEAPON FUNCTIONS =====================

func get_level() -> int: return level
func get_damage_string() -> String: return damage_string
func get_damage_type() -> GameConst.DamageType: return damage_type
func get_weapon_group() -> GameConst.WeaponGroup: return weapon_group
func get_damage_category() -> GameConst.DamageCategory: return damage_category
func get_weapon_proficiency_category() -> GameConst.WeaponProficiencyCategory: return weapon_proficiency_category
func get_damage_bonus() -> int: return damage_bonus
func get_hand_requirement() -> int: return hand_requirement
func get_range() -> int: return range

func initialize_from_dict(data: Dictionary) -> void:
	super.initialize_from_dict(data)
	damage_string = data.get("damage string", damage_string)
	damage_type = GameConst.get_damage_type_from_string(data.get("damage type", "bludgeoning").to_lower())
	weapon_group = GameConst.get_weapon_group_from_string(data.get("weapon group", "brawling").to_lower())
	damage_category = GameConst.get_damage_category_from_string(data.get("damage category", "melee").to_lower())
	weapon_proficiency_category = GameConst.get_weapon_proficiency_from_string(data.get("weapon proficiency category", "simple").to_lower())
	damage_bonus = data.get("damage bonus", damage_bonus)
	hand_requirement = data.get("hand requirement", hand_requirement)
	range = data.get("range", range)
	if range == 0:
		range = 5

func get_dictionary() -> Dictionary:
	var weapon_dict: Dictionary = super.get_dictionary()
	weapon_dict["Damage"] = damage_string
	weapon_dict["Level"] = level
	weapon_dict["Damage Type"] = GameConst.get_damage_type_as_string(damage_type)
	weapon_dict["Weapon Group"] = GameConst.get_weapon_group_as_string(weapon_group)
	weapon_dict["Damage Category"] = GameConst.get_damage_category_as_string(damage_category)
	weapon_dict["Weapon Proficiency Category"] = GameConst.get_weapon_proficiency_category_as_string(weapon_proficiency_category)
	weapon_dict["Damage Bonus"] = damage_bonus
	weapon_dict["Hand Requirement"] = hand_requirement
	weapon_dict["Range"] = range
	return weapon_dict
