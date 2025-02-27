class_name SkillResource extends Resource

# ===================== SKILL RESOURCE =====================
# Base class for all skills

# Variables
@export var s_name: String = ""
@export var description: String = ""
@export var key_attribute: String = ""
@export var proficiency : ProficiencyResource = null
@export var untrained_actions: Array = []
@export var trained_actions: Array = []

func _init(name : String = "", desc : String = "", key_attrs : String = "", _proficiency: ProficiencyResource = null, 
            untrained_acts : Array = [], trained_acts : Array = []):
    s_name = name
    description = desc
    key_attribute = key_attrs
    proficiency = ProficiencyResource.new("Untrained", -2) if proficiency == null else _proficiency
    untrained_actions = untrained_acts
    trained_actions = trained_acts

# ===================== SKILL FUNCTIONS =====================

# Get name of the skill
# Args: None
# Returns: String - Name of the skill
func get_resource_name() -> String:
    return s_name

# Get proficiency rank of the skill
# Args: None
# Returns: String
func get_proficiency_rank() -> String:
    return proficiency.get_rank()

# Get the proficiency bonus of the skill
# Args: None
# Returns: int - Proficiency bonus of the skill
func get_proficiency_bonus() -> int:
    return proficiency.get_modifier()

# Add proficiency rank to the skill
# Args: None
# Returns: void
func add_proficiency_rank() -> void:
    proficiency.add_rank()

# Remove proficiency rank from the skill
# Args: None
# Returns: void
func remove_proficiency_rank() -> void:
    proficiency.remove_rank()

# Get specific action by name
# Args: name (String) - Name of the action
# Returns: ActionResource - The matching action resource
func get_action_by_name(name: String) -> ActionResource:
    var action = find_action_by_name(name)
    
    if action == null:
        ErrorUtility.log_error("Action '%s' not found in skill '%s'" % [name, s_name])
    
    return action

# Internal helper to find action by name in untrained or trained actions
# Args: name (String) - Name of the action
# Returns: ActionResource or null if not found
func find_action_by_name(name: String) -> ActionResource:
    # Check untrained actions first
    for action in untrained_actions:
        if action.a_name == name:
            return action
    
    # Check trained actions next
    for action in trained_actions:
        if action.a_name == name:
            return action
    
    ErrorUtility.log_warning("Action '%s' not found in skill '%s'" % [name, s_name])
    return null