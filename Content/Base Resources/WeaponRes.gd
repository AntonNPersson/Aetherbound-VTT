class_name WeaponResource extends ItemResource

# ===================== WEAPON RESOURCE =====================
# Base class for all weapons

# Variables
@export var damage_string: String = "1d4"
@export var damage_type: GameConst.DamageType = GameConst.DamageType.BLUDGEONING
@export var weapon_group: GameConst.WeaponGroup = GameConst.WeaponGroup.BRAWLING
@export var damage_category: GameConst.DamageCategory = GameConst.DamageCategory.MELEE
@export var weapon_proficiency_category : GameConst.WeaponProficiencyCategory = GameConst.WeaponProficiencyCategory.SIMPLE
@export var damage_bonus: int = 0
@export var hand_requirement: int = 1
@export var range: int = 5

# ===================== WEAPON FUNCTIONS =====================

func get_damage_string() -> String: return damage_string
func get_damage_type() -> GameConst.DamageType: return damage_type
func get_weapon_group() -> GameConst.WeaponGroup: return weapon_group
func get_damage_category() -> GameConst.DamageCategory: return damage_category
func get_weapon_proficiency_category() -> GameConst.WeaponProficiencyCategory: return weapon_proficiency_category
func get_damage_bonus() -> int: return damage_bonus
func get_hand_requirement() -> int: return hand_requirement
func get_range() -> int: return range