class_name SkillResource extends Resource

# Base class for all skills

# Variables
@export var s_name: String = ""
@export var description: String = ""
@export var key_attribute: AttributeResource = null
@export var proficiency : ProficiencyResource = null
@export var untrained_actions: Array[ActionResource] = []
@export var trained_actions: Array[ActionResource] = []

func _init(name : String = "", desc : String = "", key_attrs : AttributeResource = null, proficiency: ProficiencyResource = null, 
            untrained_acts : Array[ActionResource] = [], trained_acts : Array[ActionResource] = []):
    s_name = name
    description = desc
    key_attribute = key_attrs
    proficiency = ProficiencyResource.new("Untrained", -2) if proficiency == null else proficiency
    untrained_actions = untrained_acts
    trained_actions = trained_acts

# Helper functions

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

# Get skill check of the skill
# Args: None
# Returns: int
func get_skill_check_value() -> int:
    return key_attribute.get_total_value() + get_proficiency_bonus()

# Get the dc of the skill
# Args: None
# Returns: int
func get_dc_value() -> int:
    return 10 + get_skill_check_value()

# Get specific action by name
# Args: name (String) - Name of the action
# Returns: ActionResource - The matching action resource
func get_action_by_name(name: String) -> ActionResource:
    var action = find_action_by_name(name)
    
    if action == null:
        push_error("Action '%s' not found in skill '%s'" % [name, s_name])
    
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
    
    return null