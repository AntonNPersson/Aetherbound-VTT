class_name SpecieResource extends Resource

# ===================== SPECIE RESOURCE =====================
# Base class for all species

# Variables
@export var s_name: String = ""
@export_multiline var description: String = ""
@export var traits: Array = []
@export_multiline var society : String = ""
@export_multiline var beliefs : String = ""
@export var hit_points : int = 0
@export var stamina_points : int = 0
@export var size : GameConst.MonsterSize = GameConst.MonsterSize.MEDIUM
@export var speed : int = 0
@export var base_languages : Array = []
@export var additional_languages : Array = []
@export var lineages : Array = []
@export var abilities : Array = []
@export var perks : Array = []

# ===================== SPECIE FUNCTIONS =====================

# Get the name of the species
# Args: None
# Returns: String - Name of the species
func get_resource_name() -> String: return s_name
func get_description() -> String: return description
func get_hit_points() -> int: return hit_points
func get_stamina_points() -> int: return stamina_points
func get_size() -> GameConst.MonsterSize: return size
func get_speed() -> int: return speed
func get_size_as_string() -> String: return GameConst.get_monster_size_as_string(size)
func get_base_languages() -> Array: return base_languages
func get_additional_languages() -> Array: return additional_languages
func get_lineages() -> Array: return lineages
func get_traits() -> Array: return traits
func get_society() -> String: return society
func get_beliefs() -> String: return beliefs
func get_abilities() -> Array: return abilities
func get_perks() -> Array: return perks
func get_perk_names() -> Array:
	var perk_names : Array = []
	for perk in self.perks:
		if perk.has_method("get_resource_name"):
			perk_names.append(perk.get_resource_name())
		else:
			push_warning("Perk " + perk + " does not have a resource name.")
	return perk_names

func get_trait_names() -> Array:
	var trait_names : Array = []
	for traitt in self.traits:
		if traitt.has_method("get_resource_name"):
			trait_names.append(traitt.get_resource_name())
		else:
			push_warning("Trait " + traitt + " does not have a resource name.")
	return trait_names

# Get all the perks of a specific level
# Args: int
# Returns: Array[FeatResource]
func get_feat_at_level(level: int) -> Array[FeatResource]:
	var _feats : Array[FeatResource] = []
	for feat in self.perks:
		if feat.level == level:
			_feats.append(feat)

	if _feats.is_empty():
		push_warning("No perks found at level %d for species '%s'" % [level, s_name])
	return _feats as Array
