class_name ConditionResource extends Resource

# Base class for all conditions

# Variables
@export var c_name: String = ""
@export var description: String = ""
@export var traits : Array[TraitResource] = []
@export var modifiers : Dictionary = {}
@export var saving_throw_type : String = ""
@export var saving_throw_dc : int = 0
@export var onset_time : int = 0
@export var maximum_duration : int = 0
@export var frequency : int = 0

# Initializing
func _init(name : String = "", desc : String = "", 
			_traits : Array[TraitResource] = [], _modifiers : Dictionary = {}, 
			_saving_throw_type : String = "", _saving_throw_dc : int = 0, 
			_onset_time : int = 0, _maximum_duration : int = 0, _frequency : int = 0):
	self.c_name = name
	self.description = desc
	self.traits = _traits
	self.modifiers = _modifiers
	self.saving_throw_type = _saving_throw_type
	self.saving_throw_dc = _saving_throw_dc
	self.onset_time = _onset_time
	self.maximum_duration = _maximum_duration
	self.frequency = _frequency

# Helper functions

# Get the modifier value for a given modifier
# Args: String
# Returns: int
func get_modifier(modifier: String) -> int:
	if modifiers.has(modifier):
		return modifiers[modifier] as int
	else:
		push_warning("Modifier '" + modifier + "' not found in condition '" + c_name + "'. Returning 0 as default.")
		return 0

# Get all the names of modifiers of the condition
# Args: None
# Returns: Array
func get_modifiers() -> Array:
	return modifiers.keys() as Array