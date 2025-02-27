class_name VersatileLineageResource extends LineageResource

# ===================== VERSATILE LINEAGE RESOURCE =====================
# Base class for all versatile lineages
@export var traits : Array = []
@export var society : String = ""
@export var beliefs : String = ""
@export var base_languages : Array = []
@export var additional_languages : Array = []
@export var abilities : Array = []
@export var lineages : Array = []

# Initialization
func _init(name : String = "", desc : String = "", _feats : Array = [],
                _perks : Array = [], _extra : Dictionary = {}, _traits : Array = [],
                _society : String = "", _beliefs : String = "", _base_languages : Array = [],
                _additional_languages : Array = [], _special_abilities : Array = [], _lineages : Array = []) -> void:
    super._init(name, desc, _feats, _perks, _extra)
    traits = _traits
    society = _society
    beliefs = _beliefs
    base_languages = _base_languages
    additional_languages = _additional_languages
    abilities = _special_abilities
    lineages = _lineages

# ===================== VERSATILE LINEAGE FUNCTIONS =====================
