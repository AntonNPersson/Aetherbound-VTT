class_name SpecieResource extends Resource

# Base class for all species

# Variables
@export var s_name: String = ""
@export var description: String = ""
@export var traits: Array[TraitResource] = []
@export var society : String = ""
@export var beliefs : String = ""
@export var hit_points : int = 0
@export var stamina_points : int = 0
@export var size : int = 0
@export var speed : int = 0
@export var base_languages : Array[String] = []
@export var additional_languages : Array[String] = []
@export var lineages : Array[LineageResource] = []
@export var special_abilities : Array[AbilityResource] = []
@export var feats : Array[FeatResource] = []

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], _society : String = "", _beliefs : String = "", 
            _hit_points : int = 0, _stamina_points : int = 0, _size : int = 0, _speed : int = 0, 
            _base_languages : Array[String] = [], _additional_languages : Array[String] = [], _lineages : Array[LineageResource] = [], 
            _special_abilities : Array[AbilityResource] = [], _feats : Array[FeatResource] = []):
    s_name = name
    description = desc
    self.traits = _traits
    society = _society
    beliefs = _beliefs
    hit_points = _hit_points
    stamina_points = _stamina_points
    size = _size
    speed = _speed
    base_languages = _base_languages
    additional_languages = _additional_languages
    lineages = _lineages
    special_abilities = _special_abilities
    feats = _feats

# Helper functions

# Get all the feats of a specific level
# Args: int
# Returns: Array[FeatResource]
func get_feat_at_level(level: int) -> Array[FeatResource]:
    var _feats : Array[FeatResource] = []
    for feat in self.feats:
        if feat.level == level:
            _feats.append(feat)

    if _feats.is_empty():
        push_warning("No feats found at level %d for species '%s'" % [level, s_name])
    return _feats as Array[FeatResource]