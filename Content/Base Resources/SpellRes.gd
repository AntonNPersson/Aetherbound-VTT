class_name SpellResource extends Resource

# Base class for all spells

# Variables
@export var s_name: String = ""
@export var description: String = ""
@export var traits: Array[TraitResource] = []
@export var tier: int = 0
@export var costs: Dictionary = {
	"AP": 0,
	"MP": 0,
	"KP": 0,
	"SP": 0,
	"PP": 0,
	"Loci": "None"
}
@export var damage: int = 0
@export var damage_type: String = ""
@export var cooldown: int = 0
@export var range: int = 0
@export var area: int = 0
@export var area_type: String = ""
@export var targets: int = 0
@export var defense_type: String = ""
@export var duration: int = 0
@export var tradition: String = ""
@export var is_heightened: bool = false
@export var heightened_effects: Dictionary = {}
@export var heightened_costs: Dictionary = {}
@export var spell_school: String = ""
@export var spell_type: String = ""
@export var essence_type: String = ""
@export var prerequisites: String = ""
@export var extra: Dictionary = {}

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], _tier : int = 0, 
			_costs : Dictionary = {}, _damage : int = 0, _damage_type : String = "", _cooldown : int = 0, 
			_range : int = 0, _area : int = 0, _area_type : String = "", _targets : int = 0, 
			_defense_type : String = "", _duration : int = 0, _tradition : String = "", _is_heightened : bool = false, 
			_heightened_effects : Dictionary = {}, _heightened_costs : Dictionary = {}, _spell_school : String = "", 
			_spell_type : String = "", _essence_type : String = "", _prerequisites : String = "") -> void:
	s_name = name
	description = desc
	traits = _traits
	tier = _tier
	costs = _costs if _costs.size() > 0 else {"AP": 0, "MP": 0, "KP": 0, "SP": 0, "PP": 0, "Loci": "None"}
	damage = _damage
	damage_type = _damage_type
	cooldown = _cooldown
	range = _range
	area = _area
	area_type = _area_type
	targets = _targets
	defense_type = _defense_type
	duration = _duration
	tradition = _tradition
	is_heightened = _is_heightened
	heightened_effects = _heightened_effects
	heightened_costs = _heightened_costs
	spell_school = _spell_school
	spell_type = _spell_type
	essence_type = _essence_type
	prerequisites = _prerequisites

# Helper functions

# Get the name of the spell
# Args: None
# Returns: String
func get_resource_name() -> String:
	return s_name

# Get the cost of the spell from name of the cost
# Args: String
# Returns: int
func get_cost(cost: String) -> int:
	if costs.has(cost):
		return costs[cost] if costs[cost] > 0 else 0 as int
	else:
		push_warning("Cost " + cost + " not found in spell " + s_name)
		return 0

# Get all the names of costs of the spell
# Args: None
# Returns: Array[String]
func get_costs() -> Array:
	var actual_costs := costs.keys().filter(func(cost): return costs[cost] > 0)

	if actual_costs.is_empty():
		push_warning("No costs found for spell '" + s_name + "'")
		return []

	return actual_costs as Array

# Get the value of the heightened effect from name of the effect
# Args: String
# Returns: int
func get_heightened_effect(effect: String) -> int:
	if heightened_effects.has(effect):
		return heightened_effects[effect] as int
	else:
		push_warning("Heightened effect " + effect + " not found in spell " + s_name)
		return 0

# Get all the names of heightened effects of the spell
# Args: None
# Returns: Array[String]
func get_heightened_effects() -> Array:
	return heightened_effects.keys() as Array