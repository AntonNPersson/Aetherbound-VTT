class_name TraitResource extends Resource

# Base class for all traits

# Variables
@export var t_name: String = ""
@export var description: String = ""
@export var category : String = ""

# Initialization
func _init(name : String = "", desc : String = "", _category : String = "") -> void:
	t_name = name
	description = desc
	category = _category

# Helper functions

# Get the name of the trait
# Args: None
# Returns: String - Name of the trait
func get_resource_name() -> String:
	return t_name
