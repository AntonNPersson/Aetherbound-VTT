class_name MonsterSheet extends Resource

# Basic info
@export var monster_name: String = "Default Monster"
@export var flavor_text: String = ""
@export_multiline var description: String = ""
@export var texture: Texture2D = null

# Basic stats
@export var level: int = 0
@export var gender: String = "Male"
@export var size: GameConst.MonsterSize = GameConst.MonsterSize.MEDIUM
@export var base_speed: int = 30 # Base speed
@export var base_swim_speed: int = 0 # Swim speed
@export var base_fly_speed: int = 0 # Fly speed
@export var base_climb_speed: int = 0 # Climb speed
@export var base_burrow_speed: int = 0 # Burrow speed
@export var base_armor_class: int = 10

# Attributes (Storing Scores)
@export var might_modifier: int = 0
@export var agility_modifier: int = 0
@export var endurance_modifier: int = 0
@export var intelligence_modifier: int = 0
@export var insight_modifier: int = 0
@export var charisma_modifier: int = 0

# Defenses
@export var damage_immunities: Array = []
@export var damage_resistances: Array = []
@export var damage_weaknesses: Array = []
@export var condition_immunities: Array = []

@export var might_saving_throw: int = 0
@export var agility_saving_throw: int = 0
@export var endurance_saving_throw: int = 0
@export var intelligence_saving_throw: int = 0
@export var insight_saving_throw: int = 0
@export var charisma_saving_throw: int = 0

# Stat resources (Maximums/Base)
@export var max_hit_points: int = 10 # Often calculated from Endurance + Hit Dice
@export var max_temporary_hit_points: int = 0 # Temporary HP
@export var max_actions: int = 3  # Example: Base number of actions per turn
@export var max_bonus_actions: int = 0 # Example: Bonus actions
@export var max_reactions: int = 1 # Example: Reactions per round
@export var max_aether_points: int = 0  # Example: Mana/Spell points
@export var max_stamina_points: int = 0 # Example: Stamina points

# Senses
@export var perception_modifier: int = 0 # Usually 10 + Wis mod (+ prof if skilled)

# Extra (Using dedicated Resources is recommended)
@export var species: SpecieResource = null 
@export var traits: Array = []
@export var languages: Array = ["Common"]
@export var skills: Dictionary = GameConst.MONSTER_SKILLS # List names of proficient skills
@export var equipped_items: Dictionary = {}
@export var loot_table: Array = [] # List of items/loot
@export var automatic_abilities: Array = [] # Actions, reactions, etc.
@export var proactive_abilities: Array = [] # Abilities that can be used proactively
@export var spells: Array = []
@export var talents: Array = [] # What are these? Clarify or merge.
@export var senses: Dictionary = {} # List of senses (darkvision, blindsight, etc.)
@export var attacks: Array = [] # List of attacks (melee, ranged, etc.)

# Current variables
@export var current_hit_points: int = 10
@export var current_temporary_hit_points: int = 0
@export var current_aether_points: int = 0
@export var current_stamina_points: int = 0
# Current Action Economy
@export var current_actions_available: int = 1
@export var current_bonus_actions_available: int = 1
@export var current_reactions_available: int = 1
# Current Derived Stats
@export var current_armor_class: int = 10 # Calculated from base_ac, agility_modifier, armor, effects
@export var current_speed: int = 30       # Calculated from base_speed, armor, effects
@export var current_movement_state: GameConst.MovementState = GameConst.MovementState.LAND
# Conditions and Effects
@export var current_conditions: Array = [] # Condition enums/strings
@export var active_effects: Array= [] # Active effects with durations/modifiers

# --- Initialization Logic ---
func initialize_runtime_state():
	# Calculate max values based on level, class, species, *modifiers*
	max_hit_points = calculate_max_hp()
	current_hit_points = max_hit_points
	current_temporary_hit_points = 0

	# max_aether_points = calculate_max_aether() # Implement based on class/level/modifiers
	current_aether_points = max_aether_points
	current_stamina_points = max_stamina_points

	reset_turn_resources()
	recalculate_derived_stats() # Recalculate AC, Speed, DC etc.
	# recalculate_weight()
	current_conditions.clear()
	active_effects.clear()
	print(monster_name + " runtime state initialized.")

func reset_turn_resources():
	current_actions_available = max_actions
	current_bonus_actions_available = max_bonus_actions
	current_reactions_available = max_reactions

func calculate_max_hp() -> int:
	# NEED TO CHANGE THIS
	var base_hp = 8 # Example base
	var hit_die_avg = 4 # Example for d6 Hit Die (average is 3.5, round up?)
	return base_hp + (level * (hit_die_avg + endurance_modifier))

func calculate_max_aether():
	pass

func recalculate_derived_stats():
	# Recalculates derived stats based on current state, should be called at the start of each turn

	# Recalculates AC, Speed, DC based on modifiers, proficiency, equipment, effects
	var final_ac = base_armor_class
	final_ac += agility_modifier # Directly add the modifier
	# Add bonuses from armor (equipped_items["armor"]?), shield, spells (active_effects) etc.
	current_armor_class = final_ac

	var final_speed = 0
	if current_movement_state == GameConst.MovementState.SWIM:
		final_speed += base_swim_speed
	elif current_movement_state == GameConst.MovementState.FLY:
		final_speed += base_fly_speed
	elif current_movement_state == GameConst.MovementState.CLIMB:
		final_speed += base_climb_speed
	elif current_movement_state == GameConst.MovementState.BURROW:
		final_speed += base_burrow_speed
	elif current_movement_state == GameConst.MovementState.LAND:
		final_speed += base_speed
	# Add/subtract modifiers from armor, effects, conditions
	current_speed = max(0, final_speed) # Speed usually can't be negative
 
	print(monster_name + " derived stats recalculated.")
	pass # Implement actual calculations fully

# --- Damage/Healing/Resource Spending ---
func take_damage(amount: int, damage_type): # Add DamageType enum later
	if current_temporary_hit_points > 0:
		var absorbed = min(amount, current_temporary_hit_points)
		current_temporary_hit_points -= absorbed
		amount -= absorbed
		if amount <= 0: return

	current_hit_points -= amount
	current_hit_points = max(0, current_hit_points)
	print(monster_name + " took damage. Current HP: " + str(current_hit_points))
	if current_hit_points == 0:
		# Handle death/dying state
		pass

func heal(amount: int):
	current_hit_points += amount
	current_hit_points = min(current_hit_points, max_hit_points)
	print(monster_name + " healed. Current HP: " + str(current_hit_points))

# Add functions for spending aether, hero points, actions, etc.
func spend_action_point() -> bool:
	if current_actions_available > 0:
		current_actions_available -= 1
		return true
	return false

func spend_reaction() -> bool:
	if current_reactions_available > 0:
		current_reactions_available -= 1
		return true
	return false

func spend_bonus_action() -> bool:
	if current_bonus_actions_available > 0:
		current_bonus_actions_available -= 1
		return true
	return false

func spend_aether(cost: int) -> bool:
	if current_aether_points >= cost:
		current_aether_points -= cost
		return true
	print(monster_name + " does not have enough Aether points.")
	return false


# --- Getters and Setters ---
func set_unit_movement_state(state: GameConst.MovementState):
	current_movement_state = state
	print(monster_name + " movement state set to: " + str(current_movement_state))

func set_unit_size(size: GameConst.MonsterSize):
	self.size = size
	print(monster_name + " size set to: " + str(size))

func set_unit_size_by_name(size_name: String):
	match size_name.to_lower():
		"tiny": size = GameConst.MonsterSize.TINY
		"small": size = GameConst.MonsterSize.SMALL
		"medium": size = GameConst.MonsterSize.MEDIUM
		"large": size = GameConst.MonsterSize.LARGE
		"huge": size = GameConst.MonsterSize.HUGE
		"gargantuan": size = GameConst.MonsterSize.GARGANTUAN
		_:
			ErrorUtility.print_error("Invalid size name: " + size_name)
			return
	print(monster_name + " size set to: " + str(size))

func set_unit_name(name: String):
	monster_name = name
	print("Monster name set to: " + monster_name)

func set_unit_texture(texture: Texture2D):
	if texture and texture is Texture2D:
		self.texture = texture
		print(monster_name + " texture set.")
	else:
		ErrorUtility.print_error("Invalid texture provided.")

func set_unit_level(level: Variant):
	var value = safe_integer_typecast(level)
	if value == -1:
		return
	self.level = value
	print(monster_name + " level set to: " + str(self.level))

func set_unit_max_hit_points(hp: Variant):
	var value = safe_integer_typecast(hp)
	if value == -1:
		return
	self.max_hit_points = value
	self.current_hit_points = value # Reset current HP to max
	print(monster_name + " max hit points set to: " + str(self.max_hit_points))

func set_unit_temporary_hit_points(hp: Variant):
	var value = safe_integer_typecast(hp)
	if value == -1:
		return
	self.max_temporary_hit_points = value
	print(monster_name + " temporary hit points set to: " + str(self.max_temporary_hit_points))

func set_unit_base_speed(speed: Variant):
	var value = safe_integer_typecast(speed)
	if value == -1:
		return
	self.base_speed = value
	print(monster_name + " base speed set to: " + str(self.base_speed))

func set_unit_base_swim_speed(speed: Variant):
	var value = safe_integer_typecast(speed)
	if value == -1:
		return
	self.base_swim_speed = value
	print(monster_name + " base swim speed set to: " + str(self.base_swim_speed))

func set_unit_base_fly_speed(speed: Variant):
	var value = safe_integer_typecast(speed)
	if value == -1:
		return
	self.base_fly_speed = value
	print(monster_name + " base fly speed set to: " + str(self.base_fly_speed))

func set_unit_base_climb_speed(speed: Variant):
	var value = safe_integer_typecast(speed)
	if value == -1:
		return
	self.base_climb_speed = value
	print(monster_name + " base climb speed set to: " + str(self.base_climb_speed))

func set_unit_base_burrow_speed(speed: Variant):
	var value = safe_integer_typecast(speed)
	if value == -1:
		return
	self.base_burrow_speed = value
	print(monster_name + " base burrow speed set to: " + str(self.base_burrow_speed))

func set_unit_base_armor_class(ac: Variant):
	var value = safe_integer_typecast(ac)
	if value == -1:
		return
	self.base_armor_class = value
	print(monster_name + " base armor class set to: " + str(self.base_armor_class))

func set_unit_might_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.might_modifier = value
	print(monster_name + " might modifier set to: " + str(self.might_modifier))

func set_unit_agility_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.agility_modifier = value
	print(monster_name + " agility modifier set to: " + str(self.agility_modifier))

func set_unit_endurance_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.endurance_modifier = value
	print(monster_name + " endurance modifier set to: " + str(self.endurance_modifier))

func set_unit_intelligence_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.intelligence_modifier = value
	print(monster_name + " cognition modifier set to: " + str(self.intelligence_modifier))

func set_unit_insight_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.insight_modifier = value
	print(monster_name + " insight modifier set to: " + str(self.insight_modifier))

func set_unit_charisma_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.charisma_modifier = value
	print(monster_name + " charisma modifier set to: " + str(self.charisma_modifier))

func set_unit_perception_modifier(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.perception_modifier = value
	print(monster_name + " perception modifier set to: " + str(self.perception_modifier))

func set_unit_might_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.might_saving_throw = value
	print(monster_name + " might saving throw set to: " + str(self.might_saving_throw))

func set_unit_agility_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.agility_saving_throw = value
	print(monster_name + " agility saving throw set to: " + str(self.agility_saving_throw))

func set_unit_endurance_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.endurance_saving_throw = value
	print(monster_name + " endurance saving throw set to: " + str(self.endurance_saving_throw))

func set_unit_intelligence_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.intelligence_saving_throw = value
	print(monster_name + " intelligence saving throw set to: " + str(self.intelligence_saving_throw))

func set_unit_insight_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.insight_saving_throw = value
	print(monster_name + " insight saving throw set to: " + str(self.insight_saving_throw))

func set_unit_charisma_saving_throw(modifier: Variant):
	var value = safe_integer_typecast(modifier)
	if value == -1:
		return
	self.charisma_saving_throw = value
	print(monster_name + " charisma saving throw set to: " + str(self.charisma_saving_throw))

func set_unit_gender(gender: String):
	if gender.to_lower() == "male" or gender.to_lower() == "female":
		self.gender = gender.capitalize()
		print(monster_name + " gender set to: " + gender)
		return

	ErrorUtility.print_error("Invalid gender.")

func set_senses(senses: Dictionary):
	if senses and senses is Dictionary:
		self.senses = senses
		print(monster_name + " senses set.")
	else:
		ErrorUtility.print_error("Invalid senses provided.")

func set_languages(languages: Array):
	if languages and languages is Array:
		self.languages = languages
		print(monster_name + " languages set.")
	else:
		ErrorUtility.print_error("Invalid languages provided.")

func get_unit_name() -> String:
	return monster_name

func get_unit_texture() -> Texture2D:
	if texture == null:
		ErrorUtility.log_error("Texture not set for " + monster_name + ", returning default texture.")
		return load("res://Assets/Tokens/Default/Default.webp")
	return texture

func get_unit_level() -> int:
	return level

func get_unit_max_hit_points() -> int:
	return max_hit_points

func get_unit_temporary_hit_points() -> int:
	return max_temporary_hit_points

func get_unit_base_speed() -> int:
	return base_speed

func get_unit_base_swim_speed() -> int:
	return base_swim_speed

func get_unit_base_fly_speed() -> int:
	return base_fly_speed

func get_unit_base_climb_speed() -> int:
	return base_climb_speed

func get_unit_base_burrow_speed() -> int:
	return base_burrow_speed

func get_unit_base_armor_class() -> int:
	return base_armor_class

func get_unit_might_modifier() -> int:
	return might_modifier

func get_unit_agility_modifier() -> int:
	return agility_modifier

func get_unit_endurance_modifier() -> int:
	return endurance_modifier

func get_unit_intelligence_modifier() -> int:
	return intelligence_modifier

func get_unit_insight_modifier() -> int:
	return insight_modifier

func get_unit_charisma_modifier() -> int:
	return charisma_modifier

func get_unit_perception_modifier() -> int:
	return perception_modifier

func get_unit_might_saving_throw() -> int:
	return might_saving_throw

func get_unit_agility_saving_throw() -> int:
	return agility_saving_throw

func get_unit_endurance_saving_throw() -> int:
	return endurance_saving_throw

func get_unit_intelligence_saving_throw() -> int:
	return intelligence_saving_throw

func get_unit_insight_saving_throw() -> int:
	return insight_saving_throw

func get_unit_charisma_saving_throw() -> int:
	return charisma_saving_throw

func get_unit_size_modifier() -> int:
	return GameConst.MONSTER_SIZE_MODIFIER[size]

func get_unit_size() -> GameConst.MonsterSize:
	return size

func get_unit_size_name() -> String:
	match size:
		GameConst.MonsterSize.TINY: return "Tiny"
		GameConst.MonsterSize.SMALL: return "Small"
		GameConst.MonsterSize.MEDIUM: return "Medium"
		GameConst.MonsterSize.LARGE: return "Large"
		GameConst.MonsterSize.HUGE: return "Huge"
		GameConst.MonsterSize.GARGANTUAN: return "Gargantuan"
	return "Undefined Size"

func get_unit_gender() -> String:
	return gender

func get_traits() -> Array:
	return traits

func get_senses() -> Dictionary:
	return senses

func get_languages() -> Array:
	return languages

func get_skills() -> Dictionary:
	return skills

func get_weaknesses() -> Array:
	return damage_weaknesses

func get_resistances() -> Array:
	return damage_resistances

func get_immunities() -> Array:
	return damage_immunities

func get_skill_modifier(skill_name: String) -> int:
	if skills.has(skill_name):
		return skills[skill_name]
	else:
		ErrorUtility.print_error("Skill '" + skill_name + "' not found in " + monster_name)
		return 0

func add_trait(traitt: TraitResource) -> void:
	# 1. Initial checks for validity and uniqueness
	if not traitt or not traitt is TraitResource:
		ErrorUtility.print_error("Invalid TraitResource provided.")
		return
	if traitt in traits:
		ErrorUtility.print_error("Trait '" + traitt.get_resource_name() + "' already exists on " + monster_name)
		return

	# 2. Check if at least one category is allowed
	var is_allowed: bool = false
	var trait_categories = traitt.get_categories() # Get the categories once

	# Check if categories were retrieved correctly
	if not trait_categories is Array:
		ErrorUtility.print_error("Could not retrieve categories for trait: " + traitt.get_resource_name())
		return

	# Iterate through the trait's categories
	for cat in trait_categories:
		# If we find ANY category that IS allowed...
		if cat in GameConst.ALLOWED_MONSTER_TRAITS:
			is_allowed = true # Set the flag to true
			break # Stop checking, we only need one match

	# 3. Add the trait ONLY if the flag was set to true
	if is_allowed:
		traits.append(traitt)
		traits.sort_custom(_sort_traits) # Sort the traits after adding
		print(monster_name + " added trait: " + traitt.get_resource_name())
	else:
		# Optionally, provide a more informative error if no category was allowed
		var categories_str = ", ".join(trait_categories)
		ErrorUtility.print_error("Trait '" + traitt.get_resource_name() + "' was not added. None of its categories (" + categories_str + ") are allowed for monsters.")

func remove_trait(traitt: TraitResource) -> void:
	if traitt and traitt in traits:
		traits.erase(traitt)
		print(monster_name + " removed trait: " + traitt.get_resource_name())
	else:
		ErrorUtility.print_error("Trait not found or invalid.")

# Helper functions

func safe_integer_typecast(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return value
	elif typeof(value) == TYPE_FLOAT:
		return int(round(value))
	elif typeof(value) == TYPE_STRING:
		value = value.strip_edges()
		if value.is_valid_int():
			return int(value)
		else:
			ErrorUtility.print_error("Value needs to be a whole number, not: " + value)
	else:
		ErrorUtility.print_error("Value needs to be a whole number.")
	return -1

func get_sheet_as_dictionary() -> Dictionary:
	var sheet_dict: Dictionary = {}

	# Iterate through the properties defined in the script
	for prop_info in self.get_property_list():
		var prop_name: String = prop_info.name

		if prop_name == "script" or prop_name == "name" or prop_name == "owner" or prop_name == "path":
			continue

		var value: Variant = self.get(prop_name)
		var value_type: int = typeof(value)

		# --- Handle Specific Resource Types ---

		# 1. Single Resource Instances (like Species)
		if value is SpecieResource:
			# Store the name if valid, otherwise null
			sheet_dict[prop_name] = value.get_resource_name() if is_instance_valid(value) else null
			# print("Processed %s: %s" % [prop_name, sheet_dict[prop_name]]) # Debug
			continue # Move to next property

		# 2. Texture Resource (Store Path)
		elif value is Texture2D:
			# Store the resource path if it exists, otherwise null
			sheet_dict[prop_name] = value.resource_path if is_instance_valid(value) and not value.resource_path.is_empty() else null
			# print("Processed %s: %s" % [prop_name, sheet_dict[prop_name]]) # Debug
			continue # Move to next property

		# --- Handle Arrays that might contain Resources ---
		elif value_type == TYPE_ARRAY:
			var needs_processing = false
			# Check if the property name matches known resource arrays
			if prop_name == "traits" or prop_name == "spells": # Add other resource array names if needed
				needs_processing = true

			if needs_processing:
				var name_array: Array = []
				for element in value:
					# Check if the element is a Resource and has the expected method
					if element is Resource and element.has_method("get_resource_name"):
						name_array.append(element.get_resource_name() if is_instance_valid(element) else null)
					else:
						# If it's not a resource we expect or invalid, store null or handle differently
						# For safety, let's store null here, but you could store the original element if needed
						name_array.append(null)
						if is_instance_valid(element):
							printerr("Warning: Element in array '%s' is not a recognized resource or lacks get_resource_name(): %s" % [prop_name, element])
						else:
							printerr("Warning: Found invalid instance in array '%s'" % prop_name)

				sheet_dict[prop_name] = name_array
				# print("Processed %s: %s" % [prop_name, sheet_dict[prop_name]]) # Debug
				continue # Move to next property
			# Else: If it's an array but not one we process, fall through to default copy

		# --- Handle Enum for Size (Store Name) ---
		elif prop_name == "size" and value_type == TYPE_INT: # Assuming size is stored as int internally
			sheet_dict[prop_name] = get_unit_size_name()
			# print("Processed %s: %s" % [prop_name, sheet_dict[prop_name]]) # Debug
			continue # Move to next property

		# --- Default: Copy other types directly ---
		# Includes primitives (int, float, bool, string), standard arrays (like languages, skills),
		# dictionaries (like senses, equipped_items), and other Enums (like damage types)
		sheet_dict[prop_name] = value
		# print("Copied %s directly (Type: %s)" % [prop_name, typeof(value)]) # Debug

	return sheet_dict

func initialize_from_dict(data: Dictionary):
	# Use .get(key, default_value) to safely access dictionary keys
	# The default value should be the variable's own default value
	monster_name = data.get("monster_name", monster_name)
	flavor_text = data.get("flavor_text", flavor_text)
	description = data.get("description", description)
	texture = data.get("texture", texture) # Assuming parser handles Texture loading/path
	level = data.get("level", level)
	gender = data.get("gender", gender)
	size = data.get("size", size) # Assumes parser provides the correct Enum integer
	base_speed = data.get("base_speed", base_speed)
	base_swim_speed = data.get("base_swim_speed", base_swim_speed)
	base_fly_speed = data.get("base_fly_speed", base_fly_speed)
	base_climb_speed = data.get("base_climb_speed", base_climb_speed)
	base_burrow_speed = data.get("base_burrow_speed", base_burrow_speed)
	base_armor_class = data.get("base_armor_class", base_armor_class)

	might_modifier = data.get("might_modifier", might_modifier)
	agility_modifier = data.get("agility_modifier", agility_modifier)
	endurance_modifier = data.get("endurance_modifier", endurance_modifier)
	intelligence_modifier = data.get("intelligence_modifier", intelligence_modifier)
	insight_modifier = data.get("insight_modifier", insight_modifier)
	charisma_modifier = data.get("charisma_modifier", charisma_modifier)

	# Ensure arrays/dicts are handled correctly (might need deep copy if modifying later)
	damage_immunities = data.get("damage_immunities", []).duplicate()
	damage_resistances = data.get("damage_resistances", []).duplicate()
	damage_weaknesses = data.get("damage_weaknesses", []).duplicate()
	condition_immunities = data.get("condition_immunities", []).duplicate()

	might_saving_throw = data.get("might_saving_throw", might_saving_throw)
	agility_saving_throw = data.get("agility_saving_throw", agility_saving_throw)
	endurance_saving_throw = data.get("endurance_saving_throw", endurance_saving_throw)
	intelligence_saving_throw = data.get("intelligence_saving_throw", intelligence_saving_throw)
	insight_saving_throw = data.get("insight_saving_throw", insight_saving_throw)
	charisma_saving_throw = data.get("charisma_saving_throw", charisma_saving_throw)

	max_hit_points = data.get("max_hit_points", max_hit_points)
	max_temporary_hit_points = data.get("max_temporary_hit_points", max_temporary_hit_points)
	max_actions = data.get("max_actions", max_actions) # Make sure parser adds these if needed
	max_bonus_actions = data.get("max_bonus_actions", max_bonus_actions) # Make sure parser adds these if needed
	max_reactions = data.get("max_reactions", max_reactions) # Make sure parser adds these if needed
	max_aether_points = data.get("max_aether_points", max_aether_points)
	max_stamina_points = data.get("max_stamina_points", max_stamina_points)

	perception_modifier = data.get("perception_modifier", perception_modifier)

	species = data.get("species", species) # Assumes parser provides the loaded SpecieResource
	traits = data.get("traits", []).duplicate() # Assumes parser provides Array[TraitResource]
	languages = data.get("languages", ["Common"]).duplicate()
	skills = Helper.update_common_key_values(skills, data.get("skills", {})) # Assumes parser provides Dictionary[SkillResource]
	equipped_items = data.get("equipped_items", {}).duplicate(true)
	loot_table = data.get("loot_table", []).duplicate(true)
	automatic_abilities = data.get("automatic_abilities", []).duplicate(true) # Need deep copy?
	proactive_abilities = data.get("proactive_abilities", []).duplicate(true) # Need deep copy?
	spells = data.get("spells", {}).duplicate() # Assumes parser provides Array[SpellResource]
	talents = data.get("talents", []).duplicate(true) # Need deep copy?
	senses = data.get("senses", {}).duplicate(true)
	attacks = data.get("attacks", []).duplicate(true) # Need deep copy?

	# Initialize runtime state based on newly set max values etc.
	# It's often better to call this *after* creation, but doing basic setup here is ok
	current_hit_points = max_hit_points
	current_temporary_hit_points = 0
	current_aether_points = max_aether_points
	current_stamina_points = max_stamina_points
	current_actions_available = max_actions
	current_bonus_actions_available = max_bonus_actions
	current_reactions_available = max_reactions
	current_armor_class = base_armor_class # Start with base, recalculate later
	current_speed = base_speed # Start with base, recalculate later
	current_conditions.clear()
	active_effects.clear()

	print("MonsterSheet '%s' initialized from dictionary." % monster_name)

func _get_trait_sort_value(traitt: TraitResource) -> int:
	if not traitt or not traitt is TraitResource:
		return 4 # Put invalid traits last

	var categories = traitt.get_categories()
	if not categories is Array:
		return 3 # Default to "Other" if categories are invalid

	var min_value = 3 # Default priority (Other)
	for cat in categories:
		if cat == "Rarity":
			min_value = min(min_value, 0) # Highest priority
		elif cat == "Alignment":
			min_value = min(min_value, 1) # Second priority
		elif cat == "Size":
			min_value = min(min_value, 2) # Third priority
		# No need for explicit 'else', it stays 3 if none of the above match

	return min_value

func _sort_traits(a: TraitResource, b: TraitResource) -> bool:
	var value_a = _get_trait_sort_value(a)
	var value_b = _get_trait_sort_value(b)

	if value_a < value_b:
		# 'a' belongs to a higher priority category group
		return true
	elif value_a > value_b:
		# 'b' belongs to a higher priority category group
		return false
	else:
		# Both 'a' and 'b' are in the same category group (e.g., both Alignment)
		# Sort alphabetically by name as a tie-breaker
		var name_a = a.get_resource_name() if a else ""
		var name_b = b.get_resource_name() if b else ""
		return name_a < name_b
