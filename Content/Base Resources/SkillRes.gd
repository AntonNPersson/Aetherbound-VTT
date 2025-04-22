class_name SkillResource extends Resource

# ===================== SKILL RESOURCE =====================
# Base class for all skills

# Variables
@export var s_name: String = ""
@export var description: String = ""
@export var key_attribute: String = ""
@export var proficiency : GameConst.ProficiencyRanks = GameConst.ProficiencyRanks.UNTRAINED
@export var untrained_actions: Array = []
@export var trained_actions: Array = []

# ===================== SKILL FUNCTIONS =====================

# Get name of the skill
# Args: None
# Returns: String - Name of the skill
func get_resource_name() -> String:
	return s_name

# Get proficiency rank of the skill
# Args: None
# Returns: String
func get_proficiency_rank() -> int:
	return proficiency

func get_proficiency_rank_as_string() -> String:
	return GameConst.get_proficiency_rank_as_string(proficiency)

# Get the proficiency bonus of the skill
# Args: None
# Returns: int - Proficiency bonus of the skill
func get_proficiency_bonus() -> int:
	return GameConst.RANKS[proficiency]

func reset_proficiency() -> void:
	proficiency = GameConst.ProficiencyRanks.UNTRAINED

# Add proficiency rank to the skill
# Args: None
# Returns: void
func add_proficiency_rank() -> void:
	if proficiency == GameConst.ProficiencyRanks.MASTER:
		ErrorUtility.log_error("Cannot add rank to 'Master'")
		return
	proficiency += 1

# Remove proficiency rank from the skill
# Args: None
# Returns: void
func remove_proficiency_rank() -> void:
	if proficiency == GameConst.ProficiencyRanks.UNTRAINED:
		ErrorUtility.log_error("Cannot remove rank from 'Untrained'")
		return
	proficiency -= 1

func set_proficiency(proficiency: GameConst.ProficiencyRanks) -> void:
	self.proficiency = proficiency

# Get specific action by name
# Args: name (String) - Name of the action
# Returns: ActionResource - The matching action resource
func get_action_by_name(name: String) -> ActionResource:
	var action = find_action_by_name(name)
	
	if action == null:
		ErrorUtility.log_error("Action '%s' not found in skill '%s'" % [name, s_name])
	
	return action

func get_key_attribute() -> String:
	return key_attribute.to_lower()

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

func get_dictionary():
	var dict = {
		"Name": s_name,
		"Description": description,
		"Key Attribute": key_attribute
	}
	return dict
