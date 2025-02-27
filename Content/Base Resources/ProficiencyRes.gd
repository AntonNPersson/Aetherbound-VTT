class_name ProficiencyResource extends Resource

# ===================== PROFICIENCY RESOURCE =====================
# Base class for all proficiencies

# Variables
@export var current_rank : String = "Untrained"
@export var current_modifier : int = -2

var sorted_ranks : Array = []

# Constants
const RANKS : Dictionary = {
    "untrained": -2,
    "novice": 2,
    "adept": 4,
    "expert": 6,
    "master": 8
}

# Initialization
func _init(currentRank : String = "Untrained", currentModifier : int = -2, ) -> void:
    self.current_rank = currentRank
    self.current_modifier = currentModifier

    sorted_ranks = RANKS.keys()
    sorted_ranks.sort_custom(func(a, b) -> int:
        return RANKS[a] < RANKS[b]
    )

# ===================== PROFICIENCY FUNCTIONS =====================

# Get the name of the proficiency
# Args: None
# Returns: String - Name of the proficiency
func get_resource_name() -> String:
    return current_rank

# Get the modifier for the current rank from the name of the rank
# Args: String
# Returns: int
func set_rank(rank: String) -> void:
    rank = rank.to_lower()
    if RANKS.has(rank):
        current_rank = rank
        current_modifier = RANKS[rank]
    else:
        ErrorUtility.log_error("Invalid rank: " + rank)

# Add a rank to the proficiency, increasing the modifier
# Args: None
# Returns: None
func add_rank() -> void:
    var index = sorted_ranks.find(current_rank)

    if index >= 0 and index < sorted_ranks.size() - 1:
        set_rank(sorted_ranks[index + 1])
    else:
        ErrorUtility.log_error("Cannot add rank to 'Master'")

# Remove a rank from the proficiency, decreasing the modifier
# Args: None
# Returns: None
func remove_rank() -> void:
    var index = sorted_ranks.find(current_rank)

    if index > 0:
        set_rank(sorted_ranks[index - 1])
    else:
        ErrorUtility.log_error("Cannot remove rank from 'Untrained'")

# Get the modifier for the current rank, updating if necessary
# Args: None
# Returns: int
func get_modifier() -> int:
    if current_modifier != RANKS[current_rank]:
        current_modifier = RANKS[current_rank]
    return current_modifier as int

# Get the name of the current rank
# Args: None
# Returns: String
func get_rank() -> String:
    return current_rank as String

# Get all the names of RANKS of the proficiency
# Args: None
# Returns: Array
func get_ranks() -> Array:
    return sorted_ranks as Array

# Get the modifier for a given rank
# Args: String
# Returns: int
func get_rank_modifier(rank: String) -> int:
    rank = rank.to_lower()
    if RANKS.has(rank):
        return RANKS[rank] as int
    else:
        ErrorUtility.log_warning("Invalid rank: '" + rank + "'")
        return -2