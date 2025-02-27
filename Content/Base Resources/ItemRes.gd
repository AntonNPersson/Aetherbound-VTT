class_name ItemResource extends Resource

# Base class for all items

# Variables
@export var i_name: String = ""
@export var description: String = ""
@export var traits: Array[TraitResource] = []
@export var is_activatable: bool = false
@export var activation_cost: int = 0
@export var activation_description: String = ""
@export var price: int = 0
@export var weight: int = 0

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
			_is_activatable : bool = false, _activation_cost : int = 0, _activation_description : String = "", 
			_price : int = 0, _weight : int = 0) -> void:
	i_name = name
	description = desc
	self.traits = _traits
	is_activatable = _is_activatable
	activation_cost = _activation_cost
	activation_description = _activation_description
	price = _price
	weight = _weight

# Helper functions

# Get the name of the item
# Args: None
# Returns: String - Name of the item
func get_resource_name() -> String:
	return i_name