class_name ItemResource extends Resource

# ===================== ITEM RESOURCE =====================
# Base class for all items

# Variables
@export var i_name: String = ""
@export var description: String = ""
@export var traits: Array = []
@export var is_activatable: bool = false
@export var activation_cost: int = 0
@export var activation_description: String = ""
@export var price: int = 0
@export var weight: int = 0

# ===================== ITEM FUNCTIONS =====================

# Get the name of the item
# Args: None
# Returns: String - Name of the item
func get_resource_name() -> String: return i_name
func get_traits() -> Array: return traits
func get_description() -> String: return description
func get_price() -> int: return price
func get_weight() -> int: return weight