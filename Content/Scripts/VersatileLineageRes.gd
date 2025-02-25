class_name VersatileLineageResource extends LineageResource

# Base class for all versatile lineages
@export var traits : Array[TraitResource] = []
@export var society : String = ""
@export var beliefs : String = ""
@export var base_languages : Array[String] = []
@export var additional_languages : Array[String] = []
@export var special_abilities : Array[AbilityResource] = []
@export var lineages : Array[LineageResource] = []

# Initialization
func _init(name : String = "", desc : String = "", _feats : Array[FeatResource] = [],
                _perks : Array[PerkResource] = [], _extra : Dictionary = {}, _traits : Array[TraitResource] = [],
                _society : String = "", _beliefs : String = "", _base_languages : Array[String] = [],
                _additional_languages : Array[String] = [], _special_abilities : Array[AbilityResource] = [], _lineages : Array[LineageResource] = []) -> void:
    super._init(name, desc, _feats, _perks, _extra)
    traits = _traits
    society = _society
    beliefs = _beliefs
    base_languages = _base_languages
    additional_languages = _additional_languages
    special_abilities = _special_abilities
    lineages = _lineages