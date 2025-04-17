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

func get_resource_name():
	return name

func get_dictionary():
	return Helper.clean_dictionary({
		"name": name,
		"description": description,
		"category": GameConst.get_monster_ability_category_as_string(category),
		"AP Cost": ap_cost,
		"SP Cost": sp_cost,
		"ÆP Cost": æp_cost,
		"DC": str(dc) + " " + check_type,
		"Critical Success": effects_critical_success,
		"Success": effects_success,
		"Failure": effects_failure,
		"Critical Failure": effects_critical_failure
	})

func adjust_damage_string(damage: int) -> void:
	additional_damage_string = Helper.adjust_damage_string(additional_damage_string, damage)

func adjust_dc(_dc: int) -> void:
	self.dc += _dc
	description = adjust_dcs_in_string(description, _dc)

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

func adjust_dcs_in_string(text: String, adjustment: int, min_dc: int = 1) -> String:
	if adjustment == 0:
		return text # No change needed

	var regex = RegEx.new()
	# Regex Pattern Explanation:
	# ([Dd][Cc]) : Group 1: Capture "DC", "Dc", "dC", or "dc".
	# (\s*)     : Group 2: Capture zero or more whitespace characters between DC and the number.
	# (\d+)     : Group 3: Capture one or more digits (the actual DC number).
	var pattern = "([Dd][Cc])(\\s*)(\\d+)"
	var err = regex.compile(pattern)
	if err != OK:
		printerr("Failed to compile DC adjustment regex.")
		return text # Return original on error

	# Find all matches in the text
	var matches = regex.search_all(text)

	# If no matches found, return original text
	if matches.is_empty():
		return text

	# It's safer to rebuild the string or iterate backwards when modifying length.
	# We'll iterate backwards to avoid messing up indices of earlier matches.
	var modified_text = text # Start with a copy

	for i in range(matches.size() - 1, -1, -1): # Iterate from last match to first
		var match: RegExMatch = matches[i]

		# Extract the captured parts from this specific match
		var dc_prefix = match.get_string(1) # The "DC", "dc", etc. part
		var space_part = match.get_string(2) # The whitespace (if any)
		var number_str = match.get_string(3) # The number as a string

		# Calculate the new DC value
		var original_dc = number_str.to_int()
		var new_dc = original_dc + adjustment
		new_dc = max(min_dc, new_dc) # Clamp to minimum value

		# Construct the replacement string part
		var replacement_part = dc_prefix + space_part + str(new_dc)

		# Get the start and end positions of the full match in the *current* modified_text
		# Note: Using get_start()/get_end() directly works because we iterate backwards.
		# Changes made later in the string don't affect the start/end indices of earlier matches.
		var start_index = match.get_start()
		var end_index = match.get_end()

		# Replace the matched portion in the modified_text string
		modified_text = modified_text.substr(0, start_index) + replacement_part + modified_text.substr(end_index)

	return modified_text
