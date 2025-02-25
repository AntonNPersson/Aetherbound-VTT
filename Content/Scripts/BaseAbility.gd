extends Resource
class_name AbilityResource

# Base class for all abilities

# Variables
@export var a_name: String = ""
@export var description: String = ""
@export var traits: Array[TraitResource] = []
@export var costs: Dictionary = {
    "AP": 0,
    "MP": 0,
    "KP": 0,
    "SP": 0,
    "PP": 0
}
@export var range : int = 0
@export var targets : int = 0
@export var defense : Dictionary = {}
@export var duration : int = 0
@export var area : int = 0
@export var area_type : String = ""
@export var activation_type : String = ""
@export var cooldown : int = 0

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
            _costs : Dictionary = {}, _range : int = 0, _targets : int = 0, 
            _defense : Dictionary = {}, _duration : int = 0, _area : int = 0, 
            _area_type : String = "", _activation_type : String = "", _cooldown : int = 0):
    a_name = name
    description = desc
    self.traits = _traits
    self.costs = _costs
    self.range = _range
    self.targets = _targets
    self.defense = _defense
    self.duration = _duration
    self.area = _area
    self.area_type = _area_type
    self.activation_type = _activation_type
    self.cooldown = _cooldown

# Helper functions

# Get the cost of the ability from name of the cost
# Args: String
# Returns: int
func get_cost(cost: String) -> int:
    if costs.has(cost):
        return costs[cost] as int
    else:
        push_warning("Cost " + cost + " not found in ability " + a_name)
        return 0

# Get all the names of costs of the ability
# Args: None
# Returns: Array
func get_costs() -> Array[String]:
    var actual_costs := costs.keys().filter(func(cost): return costs[cost] > 0)

    if actual_costs.is_empty():
        push_warning("No costs found for ability '" + a_name + "'")
        return []

    return actual_costs as Array[String]
