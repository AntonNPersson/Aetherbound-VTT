class_name PerkResource extends Resource

# Base class for all perks

# Variables
@export var p_name: String = ""
@export var description: String = ""
@export var traits: Array[TraitResource] = []
@export var costs : Dictionary = {
	"AP": 0,
	"MP": 0,
	"KP": 0,
	"SP": 0,
	"PP": 0
}
@export var category : String = ""
@export var requirements : String = ""
@export var prerequisites : String = ""
@export var level : int = 0
@export var extra : Dictionary = {}

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
			_costs : Dictionary = {}, _category : String = "", _requirements : String = "", 
			_prerequisites : String = "", _level : int = 0):
	p_name = name
	description = desc
	self.traits = _traits
	self.costs = _costs
	category = _category
	requirements = _requirements
	prerequisites = _prerequisites
	level = _level

# Helper functions

# Get the cost of the perk from name of the cost
# Args: String
# Returns: int
func get_cost(cost: String) -> int:
	if costs.has(cost):
		return costs[cost] as int
	else:
		push_warning("Cost " + cost + " not found in perk " + p_name)
		return 0

# Get all the names of costs of the perk
# Args: None
# Returns: Array
func get_costs() -> Array[String]:
	var actual_costs := costs.keys().filter(func(cost): return costs[cost] > 0)

	if actual_costs.is_empty():
		push_warning("No costs found for perk '" + p_name + "'")
		return []

	return actual_costs as Array[String]