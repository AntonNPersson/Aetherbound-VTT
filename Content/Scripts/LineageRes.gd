class_name LineageResource extends Resource

# Base class for all lineages

# Variables
@export var l_name: String = ""
@export var description: String = ""
@export var feats: Array[FeatResource] = []
@export var perks: Array[PerkResource] = []
@export var extra : Dictionary = {}

# Initialization
func _init(name : String = "", desc : String = "", _feats : Array[FeatResource] = [], _perks : Array[PerkResource] = [], _extra : Dictionary = {}) -> void:
    l_name = name
    description = desc
    feats = _feats
    perks = _perks
    extra = _extra