class_name SpecieResource extends Resource

# ===================== SPECIE RESOURCE =====================
# Base class for all species

# Variables
@export var s_name: String = ""
@export var description: String = ""
@export var traits: Array = []
@export var society : String = ""
@export var beliefs : String = ""
@export var hit_points : int = 0
@export var stamina_points : int = 0
@export var size : int = 0
@export var speed : int = 0
@export var base_languages : Array = []
@export var additional_languages : Array = []
@export var lineages : Array = []
@export var abilities : Array = []
@export var feats : Array = []

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array = [], _society : String = "", _beliefs : String = "", 
            _hit_points : int = 0, _stamina_points : int = 0, _size : int = 0, _speed : int = 0, 
            _base_languages : Array = [], _additional_languages : Array = [], _lineages : Array = [], 
            _special_abilities : Array = [], _feats : Array = []):
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
    abilities = _special_abilities
    feats = _feats

# ===================== SPECIE FUNCTIONS =====================

# Get the name of the species
# Args: None
# Returns: String - Name of the species
func get_resource_name() -> String:
    return s_name

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