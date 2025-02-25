class_name AffinityResource extends Resource

# Base class for all affinities

# Variables
@export var a_name: String = ""
@export var description: String = ""
@export var traits: Array[TraitResource] = []
@export var forced_attributes: Dictionary = {}
@export var free_attributes: int = 0
@export var skills: Array[SkillResource] = []
@export var perks: Array[PerkResource] = []
@export var extra: Dictionary = {}

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
            _forced_attributes : Dictionary = {}, _free_attributes : int = 0, 
            _skills : Array[SkillResource] = [], _perks : Array[PerkResource] = []) -> void:
    a_name = name
    description = desc
    self.traits = _traits
    forced_attributes = _forced_attributes
    free_attributes = _free_attributes
    self.skills = _skills
    self.perks = _perks

# Helper functions

# Get the attributes bonuses that are forced by the affinity by name.
# Args: String
# Returns: int
func get_forced_attribute(attribute: String) -> int:
    if forced_attributes.has(attribute):
        return forced_attributes[attribute] as int
    else:
        push_warning("Attribute " + attribute + " not found in affinity " + a_name)
        return 0

# Get all the names of forced attributes of the affinity
# Args: None
# Returns: Array[String]
func get_forced_attributes() -> Array[String]:
    return forced_attributes.keys() as Array[String]