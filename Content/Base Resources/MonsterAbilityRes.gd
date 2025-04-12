class_name MonsterAbilityResource extends Resource

@export var name: String = "Ability Name"
@export var category: GameConst.MonsterAbilityCategory = GameConst.MonsterAbilityCategory.PROACTIVE
@export var traits: Array = [] # e.g., ["Fire", "Electricity"]
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
@export var additional_damage_string: String = "" # e.g., "1d6"
@export var additional_damage_type: String = "" # e.g., "piercing", "slashing", etc.

# You might add other fields as needed based on ability complexity

func initialize_from_dict(data: Dictionary, p_category: GameConst.MonsterAbilityCategory) -> void:
	self.category = p_category

	self.name = data.get("name", "N/A")
	self.description = data.get("description", "N/A")
	self.ap_cost = data.get("AP_cost", 0)
	self.sp_cost = data.get("SP_cost", 0)
	self.æp_cost = data.get("ÆP_cost", 0)
	self.traits = Cache._load_resource_name_array(data.get("traits", []), "TraitResource")
	var damage_data = data.get("damage", [])
	if typeof(damage_data) == TYPE_ARRAY and not damage_data.is_empty():
		for damage in damage_data:
			for i in range(damage.size()):
				additional_damage_string = damage[0]
				additional_damage_type = damage[1]
	self.dc = data.get("DC", 0)
	self.check_type = data.get("check", "")
	var effects_data = data.get("effects", {})
	if typeof(effects_data) == TYPE_DICTIONARY:
		self.effects_critical_success = effects_data.get("critical_success", "")
		self.effects_success = effects_data.get("success", "")
		self.effects_failure = effects_data.get("failure", "")
		self.effects_critical_failure = effects_data.get("critical_failure", "")
