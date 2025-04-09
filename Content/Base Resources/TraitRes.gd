class_name TraitResource extends Resource

# Base class for all traits

# Variables
@export var t_name: String = ""
@export var description: String = ""
@export var category : Array = []

# Initialization
func _init(name : String = "", desc : String = "", _category : Array = []) -> void:
	t_name = name
	description = desc
	category = _category

# Helper functions

# Get the name of the trait
# Args: None
# Returns: String - Name of the trait
func get_resource_name() -> String:
	return t_name

func get_description() -> String:
	return description

func get_categories() -> Array:
	return category

func get_category(category_name: String) -> String:
	for cat in category:
		if cat == category_name:
			return cat
	return "N/A"

func category_exists(category_name: String) -> bool:
	for category in category:
		if category == category_name:
			return true
	return false