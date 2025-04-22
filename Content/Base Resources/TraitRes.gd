class_name TraitResource extends Resource

# Base class for all traits

# Variables
@export var t_name: String = ""
@export_multiline var description: String = ""
@export var category : Array = []
@export var parameters: Dictionary = {}
# Helper functions

# Get the name of the trait
# Args: None
# Returns: String - Name of the trait
func get_resource_name() -> String:
	if not parameters.is_empty():
		if t_name == "Thrown" and parameters.has("range"):
			return "Thrown %s ft." % parameters.range
		elif t_name == "Versatile" and parameters.has("damage_type"):
			return "Versatile %s" % parameters.damage_type.capitalize()
		# Add other parameterized formats here...
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

func get_dictionary() -> Dictionary:
	var dict = {}
	dict["name"] = get_resource_name()
	dict["description"] = description
	return dict