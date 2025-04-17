class_name BaseProficiencyResource extends Resource
# ===================== PROFICIENCY RESOURCE =====================
# Base class for all proficiencies
# Variables
@export var name: String = ""
@export var description: String = ""
@export var proficiency: GameConst.ProficiencyRanks = GameConst.ProficiencyRanks.UNTRAINED

# ===================== PROFICIENCY FUNCTIONS =====================
# Get the name of the proficiency
# Args: None
# Returns: String - Name of the proficiency
func get_resource_name() -> String:
    return name

# Get the proficiency rank
# Args: None
# Returns: int - Proficiency rank
func get_proficiency() -> GameConst.ProficiencyRanks:
    return proficiency

# Get the proficiency modifier
# Args: None
# Returns: int - Proficiency modifier
func get_proficiency_modifier() -> int:
    return GameConst.RANKS[proficiency]