class_name InstinctResource extends Resource

# Base class for all instincts

# Variables
@export var i_name: String = ""
@export var description: String = ""
@export var traits: Array[TraitResource] = []
@export var anathema: String = ""
@export var instinct_ability: AbilityResource = null
@export var rage_bonus_damage: int = 0
@export var rage_bonus_resistance: Dictionary = {}
@export var instinct_table: Dictionary = {}
@export var additional_instinct_table: Dictionary = {}

# Initialization
func _init(name : String = "", desc : String = "", _traits : Array[TraitResource] = [], 
			_anathema : String = "", _instinct_ability : AbilityResource = null, _rage_bonus_damage : int = 0, 
			_rage_bonus_resistance : Dictionary = {}, _instinct_table : Dictionary = {}, 
			_additional_instinct_table : Dictionary = {}) -> void:
	i_name = name
	description = desc
	self.traits = _traits
	anathema = _anathema
	instinct_ability = _instinct_ability
	rage_bonus_damage = _rage_bonus_damage
	rage_bonus_resistance = _rage_bonus_resistance
	instinct_table = _instinct_table
	additional_instinct_table = _additional_instinct_table

# Helper functions

# Get the name of the instinct
# Args: None
# Returns: String - Name of the instinct
func get_resource_name() -> String:
	return i_name