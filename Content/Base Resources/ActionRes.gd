class_name ActionResource extends Resource
# Ignored warnings
@warning_ignore("shadowed_variable")

# ===================== ACTION RESOURCE =====================
# Base class for all actions

# Variables
@export var a_name: String = ""
@export var description: String = ""
@export var traits : Array = []
@export var costs : Dictionary = {
	"AP": 0,
	"MP": 0,
	"KP": 0,
	"SP": 0,
	"PP": 0
}
@export var type : String = ""
@export var proficiency_required : String = ""
@export var targets : int = 0
@export var range : int = 0
@export var duration : int = 0
@export var requirements : String = ""
@export var extra : Dictionary = {}

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array = [], 
			_costs : Dictionary = {}, _type : String = "", _proficiency_required : String = "", _targets : int = 0, 
			_range : int = 0, _duration : int = 0, _requirements : String = "", _extra : Dictionary = {}) -> void:
	a_name = name
	description = desc
	traits = _traits
	costs = _costs if _costs.size() > 0 else {"AP": 0, "MP": 0, "KP": 0, "SP": 0, "PP": 0}
	type = _type
	proficiency_required = _proficiency_required
	targets = _targets
	range = _range
	duration = _duration
	requirements = _requirements
	extra = _extra

# ===================== ACTION FUNCTIONS =====================

# Get the name of the action
# Args: None
# Returns: String - Name of the action
func get_resource_name() -> String:
	return a_name

# Get the cost of the action from name of the cost
# Args: String
# Returns: int
func get_cost(cost: String) -> int:
	if costs.has(cost):
		return costs[cost] if costs[cost] > 0 else 0 as int
	else:
		ErrorUtility.log_warning("Cost " + cost + " not found in action " + a_name)
		return 0

# Get all the names of costs of the action
# Args: None
# Returns: Array[String]
func get_costs() -> Array:
	var actual_costs := costs.keys().filter(func(cost): return costs[cost] > 0)

	if actual_costs.is_empty():
		ErrorUtility.log_warning("No costs found for action '" + a_name + "'")
		return []

	return actual_costs as Array