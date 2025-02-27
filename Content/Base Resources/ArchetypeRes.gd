class_name ArchetypeResource extends Resource

# Base class for all archetypes

# Variables
@export var a_name: String = ""
@export var description: String = ""
@export var traits: Array[TraitResource] = []
@export var feats: Array[FeatResource] = []
@export var dedication_feat: FeatResource = null

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], _feats : Array[FeatResource] = [], _dedication_feat : FeatResource = null) -> void:
	a_name = name
	description = desc
	traits = _traits
	feats = _feats
	dedication_feat = _dedication_feat

# Helper functions
# Get name of the archetype
# Args: None
# Returns: String
func get_resource_name() -> String:
	return a_name

# Get all the feats of a specific level
# Args: int
# Returns: Array[FeatResource]
func get_feat_at_level(level: int) -> Array[FeatResource]:
	var _feats : Array[FeatResource] = []
	for feat in self.feats:
		if feat.level == level:
			_feats.append(feat)

	if _feats.is_empty():
		push_warning("No feats found at level %d for archetype '%s'" % [level, a_name])
	return _feats as Array[FeatResource]