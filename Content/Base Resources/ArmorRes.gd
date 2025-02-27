class_name ArmorResource extends ItemResource

# ===================== ARMOR RESOURCE =====================
# Base class for all armors

# Variables
@export var armor_class: int = 0
@export var armor_type: String = ""
@export var armor_group: String = ""
@export var armor_penalties: Dictionary = {}
@export var max_dex: int = 0

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
			_is_activatable : bool = false, _activation_cost : int = 0, _activation_description : String = "", 
			_price : int = 0, _weight : int = 0, _armor_class : int = 0, _armor_type : String = "", 
			_armor_group : String = "", _armor_penalty : Dictionary = {}, _max_dex : int = 0) -> void:
	super._init(name, desc, _traits, _is_activatable, _activation_cost, _activation_description, _price, _weight)
	armor_class = _armor_class
	armor_type = _armor_type
	armor_group = _armor_group
	armor_penalties = _armor_penalty
	max_dex = _max_dex

# ===================== ARMOR FUNCTIONS =====================
