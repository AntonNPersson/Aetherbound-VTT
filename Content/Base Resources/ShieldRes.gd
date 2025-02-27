class_name ShieldResource extends ItemResource

# ===================== SHIELD RESOURCE =====================
# Base class for all shields

# Variables
@export var armor_class: int = 0
@export var shield_penalties: Dictionary = {}
@export var max_dex: int = 0
@export var hardness: int = 0
@export var hit_points: int = 0
@export var broken_threshold: int = 0

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
			_is_activatable : bool = false, _activation_cost : int = 0, _activation_description : String = "", 
			_price : int = 0, _weight : int = 0, _armor_class : int = 0, _shield_penalty : Dictionary = {}, 
			_max_dex : int = 0, _hardness : int = 0, _hit_points : int = 0, _broken_threshold : int = 0) -> void:
	super._init(name, desc, _traits, _is_activatable, _activation_cost, _activation_description, _price, _weight)
	armor_class = _armor_class
	shield_penalties = _shield_penalty
	max_dex = _max_dex
	hardness = _hardness
	hit_points = _hit_points
	broken_threshold = _broken_threshold

# ===================== SHIELD FUNCTIONS =====================
# Check if the shield is broken
# Args: None
# Returns: bool
func is_broken() -> bool:
	return hit_points <= broken_threshold