class_name ProficiencyResource extends Resource

# Base class for all proficiencies

# Variables
@export var p_name: String = ""
@export var description: String = ""
@export var current_rank : String = "Untrained"
@export var current_modifier : int = -2

var sorted_ranks : Array = []

# Constants
const RANKS : Dictionary = {
    "Untrained": -2,
    "Novice": 2,
    "Adept": 4,
    "Expert": 6,
    "Master": 8
}

# Initialization
func _init(name : String = "", desc : String = "", currentRank : String = "Untrained", currentModifier : int = -2, ) -> void:
    self.p_name = name
    self.description = desc
    self.current_rank = currentRank
    self.current_modifier = currentModifier

    sorted_ranks = RANKS.keys()
    sorted_ranks.sort_custom(func(a, b) -> int:
        return RANKS[a] < RANKS[b]
    )

# Helper functions

# Get the modifier for the current rank from the name of the rank
# Args: String
# Returns: int
func set_rank(rank: String) -> void:
    if RANKS.has(rank):
        current_rank = rank
        current_modifier = RANKS[rank]
    else:
        push_error("Invalid rank: " + rank)

# Add a rank to the proficiency, increasing the modifier
# Args: None
# Returns: None
func add_rank() -> void:
    var index = sorted_ranks.find(current_rank)

    if index >= 0 and index < sorted_ranks.size() - 1:
        set_rank(sorted_ranks[index + 1])
    else:
        push_error("Cannot add rank to 'Master'")

# Remove a rank from the proficiency, decreasing the modifier
# Args: None
# Returns: None
func remove_rank() -> void:
    var index = sorted_ranks.find(current_rank)

    if index > 0:
        set_rank(sorted_ranks[index - 1])
    else:
        push_error("Cannot remove rank from 'Untrained'")

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
func get_ranks() -> Array[String]:
    return sorted_ranks as Array[String]

# Get the modifier for a given rank
# Args: String
# Returns: int
func get_rank_modifier(rank: String) -> int:
    if RANKS.has(rank):
        return RANKS[rank] as int
    else:
        push_warning("Invalid rank: '" + rank + "'")
        return -2