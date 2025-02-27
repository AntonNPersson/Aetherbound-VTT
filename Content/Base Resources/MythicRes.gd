class_name MythicResource extends Resource

# Base class for all mythic resources

# Variables
@export var m_name: String = ""
@export var description: String = ""
@export var anathema: String = ""
@export var edict: String = ""

# Initialization
func _init(name : String = "", desc : String = "", _anathema : String = "", _edict : String = "") -> void:
	m_name = name
	description = desc
	anathema = _anathema
	edict = _edict

# Helper functions

# Get the name of the mythic resource
# Args: None
# Returns: String
func get_resource_name() -> String:
	return m_name