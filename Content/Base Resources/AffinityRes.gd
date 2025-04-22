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

# ===================== AFFINITY FUNCTIONS =====================

# Get the name of the affinity
# Args: None
# Returns: String - Name of the affinity
func get_resource_name() -> String: return a_name
func get_description() -> String: return description
func get_forced_attributes() -> Array: return forced_attributes.keys() as Array
func get_skills() -> Array: return skills
func get_perks() -> Array: return perks
func get_free_attributes() -> int: return free_attributes
func get_traits() -> Array: return traits

func get_trait_names() -> Array:
	var trait_names: Array = []
	for traitt in traits:
		if traitt.has_method("get_resource_name"):
			trait_names.append(traitt.get_resource_name())
		else:
			ErrorUtility.log_warning("Trait " + traitt + " does not have a resource name.")
	return trait_names

func get_forced_attribute(attribute: String) -> int:
	if forced_attributes.has(attribute):
		return forced_attributes[attribute] as int
	else:
		ErrorUtility.log_warning("Attribute " + attribute + " not found in affinity " + a_name)
		return 0

func get_skill_proficiencies() -> Dictionary:
	var proficiencies: Dictionary = {}
	for skill in skills:
		if skill.has_method("get_resource_name"):
			proficiencies[skill.get_resource_name()] = skill.get_proficiency_rank()
		else:
			ErrorUtility.log_warning("Skill " + skill + " does not have a resource name.")
	return proficiencies

func get_skill_names() -> Array:
	var skill_names: Array = []
	for skill in skills:
		if skill.has_method("get_resource_name"):
			skill_names.append(skill.get_resource_name())
		else:
			ErrorUtility.log_warning("Skill " + skill + " does not have a resource name.")
	return skill_names


func get_perk_names() -> Array:
	var perk_names: Array = []
	for perk in perks:
		if perk.has_method("get_resource_name"):
			perk_names.append(perk.get_resource_name())
		else:
			ErrorUtility.log_warning("Perk " + perk + " does not have a resource name.")
	return perk_names
