@tool
class_name CharacterSheet extends Resource
# --- Basic Info ---
@export var character_name: String = "Default Name"
@export_multiline var tenets: String = ""
@export_multiline var taboos: String = ""
@export var age: int = 20
@export var gender: String = ""
@export var height: float = 1.7
@export var weight: float = 70.0

# --- Core Stats & Progression ---
@export var level: int = 1
@export var experience_points: int = 0
#@export var character_class: ClassResource = null
@export var species: SpecieResource = null
@export var affinity: AffinityResource = null

# --- Base Combat / Derived Stats (Template/Max Values) ---
@export var base_armor_class: int = 10 # Base AC before Agility Mod/Armor/etc.
@export var base_speed: int = 30
@export var base_swim_speed: int = 0
@export var base_fly_speed: int = 0
@export var base_climb_speed: int = 0
@export var base_burrow_speed: int = 0
@export var base_class_dc: int = 8    # Base for Save DCs (e.g., 8 + proficiency + relevant attribute modifier)

# --- Attributes (Modifiers) ---
# These variables store the direct modifier value (e.g., -1, 0, +1, +2).
@export var might_modifier: int = 0
@export var agility_modifier: int = 0
@export var endurance_modifier: int = 0
@export var intelligence_modifier: int = 0
@export var insight_modifier: int = 0
@export var charisma_modifier: int = 0
@export var perception_modifier: int = 0 # Often derived from Insight/Wisdom in other systems

# --- Saving Throws (Modifiers) ---
@export var might_saving_throw: int = 0
@export var agility_saving_throw: int = 0
@export var endurance_saving_throw: int = 0
@export var intelligence_saving_throw: int = 0
@export var insight_saving_throw: int = 0
@export var charisma_saving_throw: int = 0

# --- Stat Resources (Maximums/Base Pools) ---
@export var max_hit_points: int = 10    # Max HP (Calculated: Level, Class, Endurance Modifier)
@export var max_aether_points: int = 0  # Max Mana/Spell points/etc.
@export var max_mythic_points: int = 0
@export var max_hero_points: int = 1
# Action Economy per Turn/Round (Maximums)
@export var max_actions: int = 1
@export var max_bonus_actions: int = 1
@export var max_reactions: int = 1
# Carrying Capacity (Maximum)
# Note: Carrying capacity is often based on the raw *score*. If you only store the modifier,
# you'll need a different formula or assume a base score (like 10 + 2*modifier).
@export var max_carrying_capacity: int = 0

# --- Skills, Feats, Abilities, Spells (Definitions & Known/Proficient) ---
@export var skills: Array = [] # Skill names/enums character is proficient in
@export var perks: Array = [] # Perk resource
@export var spells_known: Array = [] # Spell resource
@export var traits: Array = [] # Trait resource
@export var talents: Array = [] # Talent resource
@export var languages: Array = ["Common"]
@export var weapon_proficiency: Array = [] # Weapon proficiency resource
@export var armor_proficiency: Array = [] # Armor proficiency resource
@export var extra_proficiencies: Array = [] # Extra proficiency resource
@export var archetype = null # Archetype resource (e.g., subclass, specialization)
@export var character_class = null # Class resource (e.g., Fighter, Wizard, etc.)

# --- Inventory & Equipment (Stateful) ---
@export var inventory: Array = []
@export var equipped_items: Dictionary = {
											"main_hand": null,
											"off_hand": null,
											"armor": null,
											"head": null,
											"neck": null,
											"eyes": null,
											"shoulders": null,
											"wrists": null,
											"hands": null,
											"ring_1": null,
											"ring_2": null,
											"feet": null
										} # Keyed by slot (e.g., {"main_hand": weapon_res})
@export var formulas: Array = [] # Formulas for crafting, alchemy, etc.

# --- Current Runtime State ---
@export var current_hit_points: int = 10
@export var current_temporary_hit_points: int = 0
@export var current_aether_points: int = 0
@export var current_mythic_points: int = 0
@export var current_hero_points: int = 1
# Current Action Economy
@export var current_actions_available: int = 1
@export var current_bonus_actions_available: int = 1
@export var current_reactions_available: int = 1
# Current Derived Stats
@export var current_armor_class: int = 10 # Calculated from base_ac, agility_modifier, armor, effects
@export var current_speed: int = 30       # Calculated from base_speed, armor, effects
@export var current_movement_state: GameConst.MovementState = GameConst.MovementState.LAND
@export var current_class_dc: int = 8     # Calculated from base_dc, proficiency, relevant modifier
# Current Load
@export var current_weight_carried: float = 0.0
# Conditions and Effects
@export var current_conditions: Array = [] # Condition enums/strings
@export var active_effects: Array= [] # Active effects with durations/modifiers
@export var current_currency: Dictionary = {"platinum": 0, "gold": 0, "silver": 0, "copper": 0} # Currency dictionary

# --- Initialization Logic ---
func initialize_runtime_state():
	# Calculate max values based on level, class, species, *modifiers*
	max_hit_points = calculate_max_hp() # Now uses endurance_modifier directly
	current_hit_points = max_hit_points
	current_temporary_hit_points = 0

	# max_aether_points = calculate_max_aether() # Implement based on class/level/modifiers
	current_aether_points = max_aether_points
	current_mythic_points = max_mythic_points
	current_hero_points = max_hero_points

	max_carrying_capacity = calculate_carrying_capacity() # Re-evaluate this calculation

	reset_turn_resources()
	recalculate_derived_stats() # Recalculate AC, Speed, DC etc.
	# recalculate_weight()
	current_conditions.clear()
	active_effects.clear()
	print(character_name + " runtime state initialized.")

func reset_turn_resources():
	current_actions_available = max_actions
	current_bonus_actions_available = max_bonus_actions
	current_reactions_available = max_reactions

func reset_after_rest(is_long_rest: bool = true):
	# ... (Healing logic remains similar, uses max_hit_points) ...
	current_hit_points = max_hit_points
	current_temporary_hit_points = 0
	if is_long_rest:
		current_aether_points = max_aether_points
		current_mythic_points = max_mythic_points
		current_hero_points = max_hero_points
	# ... (Handle short rest recovery, condition removal) ...
	reset_turn_resources()
	recalculate_derived_stats()
	print(character_name + " rested. HP: " + str(current_hit_points))

func recalculate_derived_stats():
	# Recalculates derived stats based on current state, should be called at the start of each turn

	# Recalculates AC, Speed, DC based on modifiers, proficiency, equipment, effects
	var final_ac = base_armor_class
	final_ac += agility_modifier # Directly add the modifier
	# Add bonuses from armor (equipped_items["armor"]?), shield, spells (active_effects) etc.
	current_armor_class = final_ac

	var final_speed = base_speed
	# Add/subtract modifiers from armor, effects, conditions
	current_speed = max(0, final_speed) # Speed usually can't be negative

	var primary_casting_mod = get_primary_casting_modifier() # You'll need logic to determine this
	# var proficiency_bonus = calculate_proficiency_bonus(level) # Implement this based on level
	# current_class_dc = base_class_dc + proficiency_bonus + primary_casting_mod

	print(character_name + " derived stats recalculated.")
	pass # Implement actual calculations fully

func calculate_max_hp() -> int:
	# NEED TO CHANGE THIS
	var base_hp = 8 # Example base
	var hit_die_avg = 4 # Example for d6 Hit Die (average is 3.5, round up?)
	return base_hp + (level * (hit_die_avg + endurance_modifier))

func calculate_max_aether():
	pass

func calculate_carrying_capacity() -> int:
	# IMPORTANT: Standard carrying capacity often uses the raw score (e.g., Score * 15 lbs).
	return 75 + (might_modifier * 15)

func calculate_perception_modifier() -> int:
	return get_perception_proficiency_modifier() + get_unit_insight_modifier() # plus items

func set_movement_state(state: GameConst.MovementState):
	current_movement_state = state
	print(character_name + " movement state set to: " + str(state))

func get_unit_name() -> String: return character_name
func get_unit_level() -> int: return level
func get_unit_gender() -> String: return gender
func get_unit_age() -> int: return age
func get_unit_height() -> float: return height
func get_unit_weight() -> float: return weight
func get_unit_species() -> SpecieResource: return species
func get_unit_archetype(): return archetype
func get_unit_archetype_name() -> String: return archetype.get_resource_name() if archetype else "N/A"
func get_unit_class(): return character_class
func get_unit_class_name() -> String: return character_class.get_resource_name() if character_class else "N/A"
func get_unit_species_name() -> String: return species.get_resource_name() if species else "N/A"
func get_unit_might_modifier() -> int: return might_modifier
func get_unit_agility_modifier() -> int: return agility_modifier
func get_unit_endurance_modifier() -> int: return endurance_modifier
func get_unit_intelligence_modifier() -> int: return intelligence_modifier
func get_unit_insight_modifier() -> int: return insight_modifier
func get_unit_charisma_modifier() -> int: return charisma_modifier
func get_unit_perception_modifier() -> int: return calculate_perception_modifier()
func get_unit_might_saving_throw() -> int: return might_saving_throw
func get_unit_agility_saving_throw() -> int: return agility_saving_throw
func get_unit_endurance_saving_throw() -> int: return endurance_saving_throw
func get_unit_intelligence_saving_throw() -> int: return intelligence_saving_throw
func get_unit_insight_saving_throw() -> int: return insight_saving_throw
func get_unit_charisma_saving_throw() -> int: return charisma_saving_throw
func get_unit_base_armor_class() -> int: return base_armor_class
func get_unit_base_speed() -> int: return base_speed
func get_unit_base_swim_speed() -> int: return base_swim_speed
func get_unit_base_fly_speed() -> int: return base_fly_speed
func get_unit_base_climb_speed() -> int: return base_climb_speed
func get_unit_base_burrow_speed() -> int: return base_burrow_speed
func get_current_actions_available() -> int: return current_actions_available
func get_current_bonus_actions_available() -> int: return current_bonus_actions_available
func get_unit_traits() -> Array: return traits

func get_weapon_proficiency_modifier(weapon_prof: GameConst.WeaponProficiencyCategory) -> int:
	for weapon in weapon_proficiency:
		if weapon.has_method("get_proficiency_category"):
			if weapon.get_proficiency_category() == weapon_prof:
				if weapon.has_method("get_proficiency_modifier"):
					return weapon.get_proficiency_modifier()
				else:
					push_warning("Weapon proficiency resource does not have a proficiency modifier method.")
					return 0
	return 0

func get_perception_proficiency_modifier() -> int:
	for prof in extra_proficiencies:
		if prof.has_method("get_resource_name"):
			if prof.get_resource_name() == "Perception":
				if prof.has_method("get_proficiency_modifier"):
					return prof.get_proficiency_modifier()
				else:
					push_warning("Extra proficiency resource does not have a proficiency modifier method.")
					return 0
	return 0

# Updated get_sheet_as_dictionary to handle potential resource saving
func get_sheet_as_dictionary() -> Dictionary:
	var sheet_dict: Dictionary = {}
	for prop in get_property_list():
		var key = prop.name
		var value = get(key)
		if value is Resource: sheet_dict[key] = value.resource_path
		elif value is Array: sheet_dict[key] = array_to_serializable(value)
		elif value is Dictionary: sheet_dict[key] = dict_to_serializable(value)
		else: sheet_dict[key] = value
	return sheet_dict

# Helper for dictionary saving (recursive)
func array_to_serializable(arr: Array) -> Array:
	var new_arr = []
	for item in arr:
		if item is Resource: new_arr.append(item.resource_path)
		elif item is Array: new_arr.append(array_to_serializable(item)) # Handle nested arrays
		elif item is Dictionary: new_arr.append(dict_to_serializable(item)) # Handle nested dicts
		else: new_arr.append(item)
	return new_arr

func dict_to_serializable(dict: Dictionary) -> Dictionary:
	var new_dict = {}
	for key in dict:
		var value = dict[key]
		if value is Resource: new_dict[key] = value.resource_path
		elif value is Array: new_dict[key] = array_to_serializable(value) # Handle nested arrays
		elif value is Dictionary: new_dict[key] = dict_to_serializable(value) # Handle nested dicts
		else: new_dict[key] = value
	return new_dict

# --- Damage/Healing/Resource Spending ---
func take_damage(amount: int, damage_type): # Add DamageType enum later
	if current_temporary_hit_points > 0:
		var absorbed = min(amount, current_temporary_hit_points)
		current_temporary_hit_points -= absorbed
		amount -= absorbed
		if amount <= 0: return

	current_hit_points -= amount
	current_hit_points = max(0, current_hit_points)
	print(character_name + " took damage. Current HP: " + str(current_hit_points))
	if current_hit_points == 0:
		# Handle death/dying state
		pass

func heal(amount: int):
	current_hit_points += amount
	current_hit_points = min(current_hit_points, max_hit_points)
	print(character_name + " healed. Current HP: " + str(current_hit_points))

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
	print(character_name + " does not have enough Aether points.")
	return false

func spend_hero_point() -> bool:
	if current_hero_points > 0:
		current_hero_points -= 1
		return true
	print(character_name + " does not have enough Hero points.")
	return false

func spend_mythic_point() -> bool:
	if current_mythic_points > 0:
		current_mythic_points -= 1
		return true
	print(character_name + " does not have enough Mythic points.")
	return false

# --- Utility ---
# func calculate_proficiency_bonus(char_level: int) -> int:
#    # Example: proficiency bonus progression
#    if char_level < 5: return 2
#    elif char_level < 9: return 3
#    elif char_level < 13: return 4
#    elif char_level < 17: return 5
#    else: return 6

func initialize_from_dict(data: Dictionary) -> void:
	# Initialize the character sheet from a dictionary
	for key in data.keys():
		if has_method(key):
			set(key, data[key])
		else:
			push_warning("Key " + key + " not found in CharacterSheet.")

# You'll need a way to determine the primary casting modifier for DCs, etc.
func get_primary_casting_modifier() -> int:
	return 0 # Default or error case