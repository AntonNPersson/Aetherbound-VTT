class_name StageConditionResource extends ConditionResource

# Base class for all stage conditions

# Variables
@export var stage: int = 0
@export var max_stage: int = 0
@export var interval : int = 0
@export var stackable : bool = false
@export var modifier_scaling : Dictionary = {}

# Initializing
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
			_modifiers : Dictionary = {}, _saving_throw_type : String = "", _saving_throw_dc : int = 0, 
			_onset_time : int = 0, _maximum_duration : int = 0, _frequency : int = 0, 
			_stage : int = 0, _max_stage : int = 0, _interval : int = 0, 
			_stackable : bool = false, _modifier_scaling : Dictionary = {}):
	super._init(name, desc, _traits, _modifiers, _saving_throw_type, _saving_throw_dc, _onset_time, _maximum_duration, _frequency)

	self.stage = _stage
	self.max_stage = _max_stage
	self.interval = _interval
	self.stackable = _stackable
	self.modifier_scaling = _modifier_scaling

# Helper functions

# Add a stage to the condition, increasing the modifiers
# Args: None
# Returns: None
func add_stage() -> void:
	if stage < max_stage:
		stage += 1
		update_modifiers(true)
	else:
		push_warning("Stage " + str(stage) + " is already at maximum.")

# Remove a stage from the condition, decreasing the modifiers
# Args: None
# Returns: None
func remove_stage() -> void:
	if stage > 0:
		stage -= 1
		update_modifiers(false)
	else:
		push_warning("Stage " + str(stage) + " is already at minimum.")

# Internal helper to update the modifiers based on scaling and stage changes
# Args: is_adding (bool) - Whether the stage is being increased or decreased
# Returns: None
func update_modifiers(is_adding: bool) -> void:
	for modifier in modifier_scaling.keys():
		if modifier_scaling.has(modifier):
			var scale = modifier_scaling[modifier]
			if is_adding:
				modifiers[modifier] += scale
			else:
				modifiers[modifier] -= scale
		else:
			push_error("Modifier scaling for '" + modifier + "' not found in condition '" + c_name + "'.")