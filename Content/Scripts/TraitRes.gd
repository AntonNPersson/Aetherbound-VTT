class_name TraitResource extends Resource

# Base class for all traits

# Variables
@export var t_name: String = ""
@export var description: String = ""
@export var modifiers : Dictionary = {}

# Initialization
func _init(name : String = "", desc : String = "", _modifiers : Dictionary = {}) -> void:
	t_name = name
	description = desc
	modifiers = _modifiers

# Helper functions

# Get the value of the modifier from name of the modifier
# Args: String
# Returns: int
func get_modifier(modifier: String) -> int:
	if modifiers.has(modifier):
		return modifiers[modifier] as int
	else:
		push_warning("Modifier " + modifier + " not found in trait " + t_name)
		return 0

# Get all the names of modifiers of the trait
# Args: None
# Returns: Array[String]
func get_modifiers() -> Array:
	return modifiers.keys() as Array
