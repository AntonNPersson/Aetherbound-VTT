class_name AttributeResource extends Resource

# ===================== ATTRIBUTE RESOURCE =====================
# Base class for all attributes

# Variables
@export var a_name: String = ""
@export var description: String = ""
@export var value: int = 0
@export var added_value: int = 0
@export var saving_throw_value: int = 0
@export var skills: Array = []

# Initialization
func _init(name: String = "", desc: String = "", val: int = 0, add_val: int = 0, _saving_throw_value: int = 0, _skills: Array = []) -> void:
	a_name = name
	description = desc
	value = val
	added_value = add_val
	saving_throw_value = _saving_throw_value

# ===================== ATTRIBUTE FUNCTIONS =====================

# Get the name of the attribute
# Args: None
# Returns: String - Name of the attribute
func get_resource_name() -> String:
	return a_name

# Returns the total value of the attribute
# Args: None
# Returns: int
func get_total_value() -> int:
	return value + added_value

# Returns the added value of the attribute
# Args: None
# Returns: int
func get_added_value() -> int:
	return added_value

# Returns the saving throw value of the attribute
# Args: None
# Returns: int
func get_saving_throw_value() -> int:
	return saving_throw_value