class_name MonsterAbilityResource extends Resource

enum AbilityCategory { PROACTIVE, AUTOMATIC, PASSIVE } # Helps differentiate

@export var name: String = "Ability Name"
@export var category: AbilityCategory = AbilityCategory.PROACTIVE
@export_multiline var description: String = ""
@export var ap_cost: int = 0 # For proactive
@export var sp_cost: int = 0 # For proactive
@export var æp_cost: int = 0 # For proactive
@export var trigger_condition: String = "" # Describe when automatic ones trigger

# Fields mainly for Automatic/Triggered abilities
@export var dc: int = 0
@export var check_type: String = "" # e.g., "Survival", or use an enum/Attribute reference
@export var effects_critical_success: String = ""
@export var effects_success: String = ""
@export var effects_failure: String = ""
@export var effects_critical_failure: String = ""

# Fields for abilities that add damage (like Sneak Attack)
@export var additional_damage_string: String = "" # e.g., "1d6 precision"

# You might add other fields as needed based on ability complexity