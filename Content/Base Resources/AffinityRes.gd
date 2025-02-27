class_name AffinityResource extends Resource

# ===================== AFFINITY RESOURCE =====================
# Base class for all affinities

# Variables
@export var a_name: String = ""
@export var description: String = ""
@export var traits: Array = []
@export var forced_attributes: Dictionary = {}
@export var free_attributes: int = 0
@export var skills: Array = []
@export var perks: Array = []
@export var extra: Dictionary = {}

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array = [], 
            _forced_attributes : Dictionary = {}, _free_attributes : int = 0, 
            _skills : Array = [], _perks : Array = [], _extra: Dictionary = {}) -> void:
    a_name = name
    description = desc
    traits = _traits
    forced_attributes = _forced_attributes
    free_attributes = _free_attributes
    skills = _skills
    perks = _perks
    extra = _extra

# ===================== AFFINITY FUNCTIONS =====================

# Get the name of the affinity
# Args: None
# Returns: String - Name of the affinity
func get_resource_name() -> String:
    return a_name

# Get the attributes bonuses that are forced by the affinity by name.
# Args: String
# Returns: int
func get_forced_attribute(attribute: String) -> int:
    if forced_attributes.has(attribute):
        return forced_attributes[attribute] as int
    else:
        ErrorUtility.log_warning("Attribute " + attribute + " not found in affinity " + a_name)
        return 0

# Get all the names of forced attributes of the affinity
# Args: None
# Returns: Array[String]
func get_forced_attributes() -> Array:
    return forced_attributes.keys() as Array