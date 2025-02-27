class_name MuseResource extends Resource

# Base class for all muses

# Variables
@export var m_name: String = ""
@export var description: String = ""
@export var feat: FeatResource = null
@export var spell: SpellResource = null

# Initialization
func _init(name : String = "", desc : String = "", _feat : FeatResource = null, _spell : SpellResource = null) -> void:
	m_name = name
	description = desc
	feat = _feat
	spell = _spell

# Helper functions

# Get the name of the muse
# Args: None
# Returns: String - Name of the muse
func get_resource_name() -> String:
	return m_name