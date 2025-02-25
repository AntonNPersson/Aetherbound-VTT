class_name FeatResource extends Resource

# Base class for all feats

# Variables
@export var f_name: String = ""
@export var description: String = ""
@export var traits: Array[TraitResource] = []
@export var costs: Dictionary = {
	"AP": 0,
	"MP": 0,
	"KP": 0,
	"SP": 0,
	"PP": 0
}
@export var requirements: String = ""
@export var prerequisites: String = ""
@export var level: int = 0
@export var frequency: int = 0
@export var modifiers : Dictionary = {}
@export var extra : Dictionary = {}

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
			_costs : Dictionary = {}, _requirements : String = "", 
			_prerequisites : String = "", _level : int = 0, _frequency : int = 0, 
			_modifiers : Dictionary = {}) -> void:
	f_name = name
	description = desc
	self.traits = _traits
	costs = _costs if _costs.size() > 0 else {"AP": 0, "MP": 0, "KP": 0, "SP": 0, "PP": 0}
	requirements = _requirements
	prerequisites = _prerequisites
	level = _level
	frequency = _frequency
	modifiers = _modifiers

# Helper functions

# Get the value of the modifier from name of the modifier
# Args: String
# Returns: int
func get_modifier(modifier: String) -> int:
	if modifiers.has(modifier):
		return modifiers[modifier] as int
	else:
		push_warning("Modifier '%s' not found in feat '%s'" % [modifier, f_name])
		return 0

# Get all the names of modifiers of the feat
# Args: None
# Returns: Array[String]
func get_modifiers() -> Array[String]:
	return modifiers.keys() as Array[String]