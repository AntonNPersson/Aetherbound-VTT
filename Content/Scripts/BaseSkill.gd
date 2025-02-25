class_name SkillResource extends Resource

# Base class for all skills

# Variables
@export var s_name: String = ""
@export var description: String = ""
@export var key_attributes : Array[String] = []
@export var untrained_actions: Array[ActionResource] = []
@export var trained_actions: Array[ActionResource] = []

func _init(name : String = "", desc : String = "", key_attrs : Array[String] = [], 
            untrained_acts : Array[ActionResource] = [], trained_acts : Array[ActionResource] = []):
    s_name = name
    description = desc
    key_attributes = key_attrs
    untrained_actions = untrained_acts
    trained_actions = trained_acts

# Helper functions

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