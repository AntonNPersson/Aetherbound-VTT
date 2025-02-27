class_name WeaponResource extends ItemResource

# ===================== WEAPON RESOURCE =====================
# Base class for all weapons

# Variables
@export var damage: int = 0
@export var damage_type: String = ""
@export var weapon_group: String = ""
@export var hand_requirement: int = 0
@export var range: int = 0

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
			_is_activatable : bool = false, _activation_cost : int = 0, _activation_description : String = "", 
			_price : int = 0, _weight : int = 0, _damage : int = 0, _damage_type : String = "", 
			_weapon_group : String = "", _hand_requirement : int = 0, _range : int = 0) -> void:
	super._init(name, desc, _traits, _is_activatable, _activation_cost, _activation_description, _price, _weight)
	damage = _damage
	damage_type = _damage_type
	weapon_group = _weapon_group
	hand_requirement = _hand_requirement
	range = _range

# ===================== WEAPON FUNCTIONS =====================