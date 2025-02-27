class_name ShieldResource extends ItemResource

# Base class for all shields

# Variables
@export var armor_class: int = 0
@export var shield_penalty: int = 0
@export var max_dex: int = 0
@export var check_penalty: int = 0
@export var spell_failure: int = 0
@export var speed: int = 0
@export var hardness: int = 0
@export var hit_points: int = 0
@export var broken_threshold: int = 0

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
			_is_activatable : bool = false, _activation_cost : int = 0, _activation_description : String = "", 
			_price : int = 0, _weight : int = 0, _armor_class : int = 0, _shield_penalty : int = 0, 
			_max_dex : int = 0, _check_penalty : int = 0, _spell_failure : int = 0, _speed : int = 0, 
			_hardness : int = 0, _hit_points : int = 0, _broken_threshold : int = 0) -> void:
	super._init(name, desc, _traits, _is_activatable, _activation_cost, _activation_description, _price, _weight)
	armor_class = _armor_class
	shield_penalty = _shield_penalty
	max_dex = _max_dex
	check_penalty = _check_penalty
	spell_failure = _spell_failure
	speed = _speed
	hardness = _hardness
	hit_points = _hit_points
	broken_threshold = _broken_threshold

# Helper functions
# Check if the shield is broken
# Args: None
# Returns: bool
func is_broken() -> bool:
	return hit_points <= broken_threshold