class_name DeityResource extends Resource

# ===================== DEITY RESOURCE =====================
# Base class for all deities

# Variables
@export var d_name: String = ""
@export var description: String = ""
@export var areas_of_concern: Array = []
@export var edicts: Array = []
@export var anathema: Array = []
@export var symbol: String = ""
@export var divine_attribute: String = ""
@export var divine_font: String = ""
@export var divine_consecration: TraitResource = null # This is a trait
@export var divine_skill: SkillResource = null
@export var domains: Array = []
@export var favored_weapon_group: String = ""

# Initialization
func _init(name : String = "", desc : String = "", _areas_of_concern : Array = [], _edicts : Array = [], 
			_anathema : Array = [], _symbol : String = "", _divine_attribute : String = "", 
			_divine_font : String = "", _divine_consecration : TraitResource = null, _divine_skill : SkillResource = null, 
			_domains : Array = [], _favored_weapon_group : String = "") -> void:
	d_name = name
	description = desc
	areas_of_concern = _areas_of_concern
	edicts = _edicts
	anathema = _anathema
	symbol = _symbol
	divine_attribute = _divine_attribute
	divine_font = _divine_font
	divine_consecration = _divine_consecration
	divine_skill = _divine_skill
	domains = _domains
	favored_weapon_group = _favored_weapon_group

# ===================== DEITY FUNCTIONS =====================

# Get the name of the deity
# Args: None
# Returns: String - Name of the deity
func get_resource_name() -> String:
	return d_name