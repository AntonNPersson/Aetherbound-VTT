class_name LineageResource extends Resource

# ===================== LINEAGE RESOURCE =====================
# Base class for all lineages

# Variables
@export var l_name: String = ""
@export var description: String = ""
@export var feats: Array = []
@export var perks: Array = []
@export var extra : Dictionary = {}

# Initialization
func _init(name : String = "", desc : String = "", _feats : Array = [], _perks : Array = [], _extra : Dictionary = {}) -> void:
    l_name = name
    description = desc
    feats = _feats
    perks = _perks
    extra = _extra

# ===================== LINEAGE FUNCTIONS =====================

# Get the name of the lineage
# Args: None
# Returns: String - Name of the lineage
func get_resource_name() -> String:
    return l_name