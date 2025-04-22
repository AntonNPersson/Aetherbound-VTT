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
@export var size: GameConst.MonsterSize = GameConst.MonsterSize.MEDIUM

# --- Core Stats & Progression ---
@export var level: int = 0
@export var experience_points: int = 0
#@export var character_class: ClassResource = null
@export var species: SpecieResource = null
@export var affinity: AffinityResource = null
@export var lineage: LineageResource = null

# --- Base Combat / Derived Stats (Template/Max Values) ---
@export var base_armor_class: int = 10 # Base AC before Agility Mod/Armor/etc.
@export var base_ac: int = 10
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
@export var max_stamina_points: int = 0 # Max Stamina points (if applicable)
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
@export var current_stamina_points: int = 0
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

@export var main_strike_action: AttackResource = null # Placeholder for strike actions
@export var off_hand_strike_action: AttackResource = null # Placeholder for off-hand strike actions

# --- Initialization Logic ---
func initialize_runtime_state():
	# Calculate max values based on level, class, species, *modifiers*
	main_strike_action = AttackResource.new()
	off_hand_strike_action = AttackResource.new()
	recalculate_derived_stats() # Recalculate AC, Speed, DC etc.
	current_temporary_hit_points = 0

	# max_aether_points = calculate_max_aether() # Implement based on class/level/modifiers
	current_hit_points = max_hit_points
	current_aether_points = max_aether_points
	current_stamina_points = max_stamina_points
	current_mythic_points = max_mythic_points
	current_hero_points = max_hero_points
	current_armor_class = base_armor_class

	reset_turn_resources()
	current_conditions.clear()
	active_effects.clear()
	print(character_name + " runtime state initialized.")
	print("Max Stamina: " + str(max_stamina_points))

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
	main_strike_action.apply_weapon(equipped_items["main_hand"])
	if equipped_items.has("off_hand") and equipped_items["off_hand"] != null and equipped_items["off_hand"] is WeaponResource:
		# Apply off-hand weapon effects if applicable
		off_hand_strike_action.apply_weapon(equipped_items["off_hand"])
	else:
		# If no off-hand item, use the main hand's strike action
		off_hand_strike_action = main_strike_action

	base_armor_class = calculate_armor_class() # Base AC + Armor + Agility Mod
	var final_speed = base_speed
	current_speed = max(0, final_speed) # Speed usually can't be negative
	max_hit_points = calculate_max_hp()
	max_stamina_points = calculate_max_stamina()
	max_carrying_capacity = calculate_carrying_capacity()
	perception_modifier = calculate_perception_modifier() # Derived from skills, insight, etc.
	base_speed = calculate_land_speed() # Base speed + armor penalties

	var primary_casting_mod = get_primary_casting_modifier() # You'll need logic to determine this
	# var proficiency_bonus = calculate_proficiency_bonus(level) # Implement this based on level
	# current_class_dc = base_class_dc + proficiency_bonus + primary_casting_mod

	print(character_name + " derived stats recalculated.")
	pass # Implement actual calculations fully

func calculate_max_hp() -> int:
	if species:
		var base_hp = species.get_hit_points()
		return base_hp + get_unit_endurance_modifier() # + class_hp_bonus + level_hp_bonus
	return get_unit_max_hit_points()

func calculate_max_stamina() -> int:
	if species:
		var base_stamina = species.get_stamina_points()
		return base_stamina + get_unit_endurance_modifier() # + class_stamina_bonus + level_stamina_bonus
	else:
		print("No species found, using default max stamina points.")
	return get_unit_max_stamina_points()

func calculate_armor_class() -> int:
	var ac = base_ac
	var has_armor = equipped_items["armor"] != null
	if has_armor:
		ac += equipped_items["armor"].get_ac_bonus() + min(agility_modifier, equipped_items["armor"].get_agi_cap()) + get_armor_proficiency_modifier(equipped_items["armor"].get_proficiency_category())
	else:
		ac += agility_modifier + get_armor_proficiency_modifier(GameConst.ArmorProficiencyCategory.UNARMORED)

	return ac

func calculate_max_aether():
	pass

func calculate_carrying_capacity() -> int:
	# IMPORTANT: Standard carrying capacity often uses the raw score (e.g., Score * 15 lbs).
	return round(GameConst.get_average_weight_from_size(size) + (GameConst.get_size_multiplier_from_size(size) * might_modifier))

func calculate_perception_modifier() -> int:
	return get_perception_proficiency_modifier() + get_unit_insight_modifier() # plus items

func calculate_land_speed() -> int:
	var speed = base_speed
	if equipped_items.has("armor") and equipped_items["armor"] != null:
		var armor = equipped_items["armor"]
		if armor.has_method("get_speed_penalty"):
			speed -= armor.get_speed_penalty()
	if equipped_items.has("off_hand") and equipped_items["off_hand"] != null:
		var shield = equipped_items["off_hand"]
		if shield.has_method("get_speed_penalty"):
			speed -= shield.get_speed_penalty()
	return max(0, speed)

func set_movement_state(state: GameConst.MovementState):
	current_movement_state = state
	print(character_name + " movement state set to: " + str(state))

func is_item_equipped(item: Resource) -> bool:
	for slot in equipped_items.keys():
		if equipped_items[slot] == item:
			return true
	return false

func equip_item(slot: String, item: Resource):
	if equipped_items.has(slot):
		equipped_items[slot] = item
		print(character_name + " equipped " + item.get_resource_name() + " in slot " + slot)
		if slot == "armor":
			base_armor_class = calculate_armor_class()
		elif slot == "main_hand":
			main_strike_action.apply_weapon(item)
			Bus.equip_main_hand_attack.emit(main_strike_action)
		elif slot == "off_hand":
			off_hand_strike_action.apply_weapon(item)
			Bus.equip_off_hand_attack.emit(off_hand_strike_action)
		else:
			print("Equipped item in slot: " + slot)
	else:
		print("Invalid slot: " + slot)

func unequip_item(item: Resource):
	for slot in equipped_items.keys():
		if equipped_items[slot] == item:
			equipped_items[slot] = null
			print(character_name + " unequipped " + item.get_resource_name() + " from slot " + slot)
			if slot == "armor":
				base_armor_class = calculate_armor_class()
			elif slot == "main_hand":
				main_strike_action = AttackResource.new()
				Bus.equip_main_hand_attack.emit(main_strike_action)
			elif slot == "off_hand":
				off_hand_strike_action = AttackResource.new()
				Bus.equip_off_hand_attack.emit(off_hand_strike_action)
			else:
				print("Unequipped item from slot: " + slot)

func get_unit_name() -> String: return character_name
func get_unit_level() -> int: return level
func get_unit_gender() -> String: return gender
func get_unit_age() -> int: return age
func get_unit_height() -> float: return height
func get_unit_weight() -> float: return weight
func get_unit_size() -> GameConst.MonsterSize: return size
func get_unit_size_as_string() -> String: return GameConst.get_monster_size_as_string(size)
func get_unit_species() -> SpecieResource: return species
func get_unit_archetype(): return archetype
func get_unit_archetype_name() -> String: return archetype.get_resource_name() if archetype else "N/A"
func get_unit_class(): return character_class
func get_unit_class_name() -> String: return character_class.get_resource_name() if character_class else "N/A"
func get_unit_species_name() -> String: return species.get_resource_name() if species else "N/A"
func get_unit_lineage(): return lineage
func get_unit_lineage_name() -> String: return lineage.get_resource_name() if lineage else "N/A"
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
func get_unit_tenets() -> String: return tenets
func get_unit_taboos() -> String: return taboos
func get_unit_languages() -> Array: return languages
func get_unit_skills() -> Array: return skills
func get_unit_perks() -> Array: return perks
func get_unit_spells_known() -> Array: return spells_known
func get_unit_talents() -> Array: return talents
func get_unit_inventory() -> Array: return inventory
func get_unit_formulas() -> Array: return formulas
func get_unit_max_hit_points() -> int: return max_hit_points
func get_unit_current_hit_points() -> int: return current_hit_points
func get_unit_max_temporary_hit_points() -> int: return current_temporary_hit_points
func get_unit_max_aether_points() -> int: return max_aether_points
func get_unit_current_aether_points() -> int: return current_aether_points
func get_unit_max_mythic_points() -> int: return max_mythic_points
func get_unit_current_mythic_points() -> int: return current_mythic_points
func get_unit_max_hero_points() -> int: return max_hero_points
func get_unit_current_hero_points() -> int: return current_hero_points
func get_unit_max_stamina_points() -> int: return max_stamina_points # Assuming stamina is similar to HP
func get_unit_current_stamina_points() -> int: return current_stamina_points # Assuming stamina is similar to HP
func get_unit_equipped_items() -> Dictionary: return equipped_items
func get_unit_proficiencies() -> Array: return extra_proficiencies + armor_proficiency + weapon_proficiency
func get_unit_hit_modifier() -> int:
	if main_strike_action != null:
		return main_strike_action.calculate_attack_modifier(self)
	return 0
func get_unit_damage_string() -> Dictionary:
	if main_strike_action != null:
		return main_strike_action.calculate_damage_details(self)
	else:
		print("Warning: Strike actions not initialized.")
	return {"dice_string": "1d4", "flat_bonus": 0, "damage_type": GameConst.DamageType.BLUDGEONING}

func get_unit_shield_hardness() -> int:
	if equipped_items.has("off_hand") and equipped_items["off_hand"] != null:
		var shield = equipped_items["off_hand"]
		if shield.has_method("get_hardness"):
			return shield.get_hardness()
	return 0
func get_unit_equipped_item(slot: String) -> Resource:
	if equipped_items.has(slot):
		return equipped_items[slot]
	return null
func get_unit_equipped_item_name(slot: String) -> String:
	if equipped_items.has(slot):
		var item = equipped_items[slot]
		if item != null:
			return item.get_resource_name()
	return "N/A"

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

func get_armor_proficiency_modifier(armor_prof: GameConst.ArmorProficiencyCategory) -> int:
	for armor in armor_proficiency:
		if armor.has_method("get_proficiency_category"):
			if armor.get_proficiency_category() == armor_prof:
				if armor.has_method("get_proficiency_modifier"):
					return armor.get_proficiency_modifier()
				else:
					push_warning("Armor proficiency resource does not have a proficiency modifier method.")
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

func get_skill_modifier(skill_name: String) -> int:
	for skill in skills:
		if skill.has_method("get_resource_name"):
			if skill.get_resource_name() == skill_name:
				if skill.has_method("get_proficiency_bonus"):
					var skill_bonus = skill.get_proficiency_bonus()
					var key_attribute = skill.get_key_attribute()
					var attribute_modifier = call("get_unit_" + key_attribute + "_modifier")
					return skill_bonus + attribute_modifier # + item bonus and so on
				else:
					push_warning("Skill resource does not have a proficiency modifier method.")
					return 0
	return 0

# Updated get_sheet_as_dictionary to handle potential resource saving
func get_sheet_as_dictionary() -> Dictionary:
	var sheet_dict: Dictionary = {}
	# Consider using get_script_property_list() if you only want exported/script vars,
	# otherwise get_property_list() includes built-ins you might need to filter.
	for prop in get_script().get_script_property_list():
		if prop.name == "Character Sheet.gd":
			continue # Skip the script itself
		var key = prop.name
		var value = get(key)

		# --- Special Handling for specific keys to reverse initialization ---

		if key == "equipped_items" and value is Dictionary:
			var serializable_equipment = {}
			for slot_key in value.keys():
				var item_resource = value[slot_key]
				if is_instance_valid(item_resource) and item_resource.has_method("get_resource_name"):
					serializable_equipment[slot_key] = item_resource.get_resource_name()
				else:
					# Preserve null or non-resource values
					serializable_equipment[slot_key] = item_resource # Store null explicitly
			sheet_dict[key] = serializable_equipment

		elif key == "skills" and value is Array:
			var serializable_skills = {}
			for skill_resource in value:
				# Check if it's the expected resource and has the needed methods
				if is_instance_valid(skill_resource) and \
				   skill_resource.has_method("get_resource_name") and \
				   skill_resource.has_method("get_proficiency"): # ADJUST method name if needed

					var skill_name = skill_resource.get_resource_name()
					var proficiency_rank = skill_resource.get_proficiency() # ADJUST method name if needed
					serializable_skills[skill_name] = proficiency_rank
				elif skill_resource is String:
					# Handle case where resource wasn't found during init and string was kept
					printerr("Warning: Found raw string '%s' in skills array during serialization." % skill_resource)
					serializable_skills[skill_resource] = 0 # Or some default/null value
				# Else: Skip unexpected items in the array
			sheet_dict[key] = serializable_skills

		elif key == "armor_proficiency" and value is Array:
			var serializable_armor_prof = {}
			for armor_resource in value:
				if is_instance_valid(armor_resource) and \
				   armor_resource.has_method("get_resource_name") and \
				   armor_resource.has_method("get_proficiency"): # ADJUST method name if needed

					var armor_name = armor_resource.get_resource_name()
					var proficiency_rank = armor_resource.get_proficiency() # ADJUST method name if needed
					serializable_armor_prof[armor_name] = proficiency_rank
				elif armor_resource is String:
					printerr("Warning: Found raw string '%s' in armor_proficiency array during serialization." % armor_resource)
					serializable_armor_prof[armor_resource] = 0
			sheet_dict[key] = serializable_armor_prof

		elif key == "weapon_proficiency" and value is Array:
			var serializable_weapon_prof = {}
			for weapon_resource in value:
				if is_instance_valid(weapon_resource) and \
				   weapon_resource.has_method("get_resource_name") and \
				   weapon_resource.has_method("get_proficiency"): # ADJUST method name if needed

					var weapon_name = weapon_resource.get_resource_name()
					var proficiency_rank = weapon_resource.get_proficiency() # ADJUST method name if needed
					serializable_weapon_prof[weapon_name] = proficiency_rank
				elif weapon_resource is String:
					printerr("Warning: Found raw string '%s' in weapon_proficiency array during serialization." % weapon_resource)
					serializable_weapon_prof[weapon_resource] = 0
			sheet_dict[key] = serializable_weapon_prof

		# --- General Handling for other keys ---
		else:
			# Use a recursive helper to serialize other values
			sheet_dict[key] = _serialize_value_recursive(value)

	# Apply the cleaning function AFTER potentially adding unwanted properties from get_property_list()
	return sheet_dict

func get_full_sheet_as_dictionary() -> Dictionary:
	var sheet_dict: Dictionary = {}
	for prop in get_script().get_script_property_list():
		if prop.name == "Character Sheet.gd":
			continue # Skip the script itself
		var key = prop.name
		var value = get(key)
		sheet_dict[key] = value
	return sheet_dict

# Helper for dictionary saving (recursive)
func _serialize_value_recursive(value):
	if is_instance_valid(value) and value.has_method("get_resource_name"):
		# Base case: Convert valid resources with a name method to their name string
		return value.get_resource_name()

	elif value is Array:
		# Recursive case: Array
		var serializable_array = []
		for item in value:
			serializable_array.append(_serialize_value_recursive(item)) # Recurse on items
		return serializable_array

	elif value is Dictionary:
		# Recursive case: Dictionary (Handles nested dictionaries NOT explicitly handled above)
		var serializable_dict = {}
		for dict_key in value.keys():
			# Assuming keys are already serializable (like strings)
			# Recurse on the values
			serializable_dict[dict_key] = _serialize_value_recursive(value[dict_key])
		return serializable_dict

	elif value is Object and not is_instance_valid(value):
		# Handle potentially freed objects gracefully
		return null

	else:
		# Base case: Primitives (int, float, bool, string, null) or unknown objects
		# Make sure Vector2/3, Color etc. are handled if needed, otherwise they might become strings
		# Check if value is serializable directly, otherwise convert or return placeholder
		if typeof(value) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING] or value == null:
			return value
		elif value is Vector2 or value is Vector2i or \
			value is Vector3 or value is Vector3i or \
			value is Color or value is Rect2 or value is Rect2i:
			return value # These are often directly serializable by JSON/Configfile
		else:
			# Unknown complex type - return string representation or null
			printerr("Warning: Encountered non-serializable value of type '%s' during serialization. Converting to string.")
			return str(value)


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
		var original_value = data.get(key) # Use .get() for safety

		# --- Special Handling for Equipped Items ---
		if key == "equipped_items" and original_value is Dictionary:
			var processed_equipment = {}
			for slot_key in original_value.keys():
				var item_name_or_null = original_value[slot_key]
				var processed_item = null

				if item_name_or_null is String and not item_name_or_null.is_empty():
					# Determine expected type based on slot
					var expected_slot_type = Cache.SLOT_TO_RESOURCE_TYPE_MAP.get(slot_key, "ItemResource") # Default to ItemResource
					var resource = Cache.find_loaded_resource_by_name(item_name_or_null, expected_slot_type)
					if is_instance_valid(resource):
						processed_item = resource
					else:
						printerr("Equipped item resource '%s' (Type: %s) not found for slot '%s'. Setting to null." % [item_name_or_null, expected_slot_type, slot_key])
						processed_item = null # Keep it null if resource not found
				else:
					# Preserve null or non-string values
					processed_item = item_name_or_null

				processed_equipment[slot_key] = processed_item
			# Set the entirely processed equipment dictionary
			set(key, processed_equipment)
		elif key == "inventory" and original_value is Array:
			print("Processing inventory...")
			var processed_inventory = []
			for item_name in original_value:
				var item_resource = Cache.find_loaded_resource_by_name(item_name, "ItemResource")
				if is_instance_valid(item_resource):
					processed_inventory.append(item_resource)
					print("Inventory item '%s' added." % item_name)
				else:
					printerr("Inventory item resource '%s' not found. Keeping as string." % item_name)
					processed_inventory.append(item_name) # Keep original string if not found
			# Set the processed inventory array
			set(key, processed_inventory)
		elif key == "skills" and original_value is Dictionary:
			print("Processing skills...")
			var processed_skills = []
			for skill_name in original_value.keys():
				var skill_resource = Cache.find_loaded_resource_by_name(skill_name, "SkillResource")
				if is_instance_valid(skill_resource):
					var skill = skill_resource
					skill.set_proficiency(original_value[skill_name])
					processed_skills.append(skill)
					print("Skill '%s' proficiency set to %d." % [skill_name, original_value[skill_name]])
				else:
					printerr("Skill resource '%s' not found. Keeping as string." % skill_name)
					processed_skills.append(skill_name) # Keep original string if not found
			# Set the processed skills array
			set(key, processed_skills)
		elif key == "armor_proficiency" and original_value is Dictionary:
			print("Processing armor proficiency...")
			var processed_armor_proficiency = []
			for armor_name in original_value.keys():
				var armor_resource = Cache.find_loaded_resource_by_name(armor_name, "ArmorProficiencyResource")
				if is_instance_valid(armor_resource):
					var armor = armor_resource
					armor.set_proficiency(original_value[armor_name])
					processed_armor_proficiency.append(armor)
					print("Armor proficiency '%s' set to %d." % [armor_name, original_value[armor_name]])
				else:
					printerr("Armor proficiency resource '%s' not found. Keeping as string." % armor_name)
					processed_armor_proficiency.append(armor_name) # Keep original string if not found
			# Set the processed armor proficiency array
			set(key, processed_armor_proficiency)
		elif key == "weapon_proficiency" and original_value is Dictionary:
			print("Processing weapon proficiency...")
			var processed_weapon_proficiency = []
			for weapon_name in original_value.keys():
				var weapon_resource = Cache.find_loaded_resource_by_name(weapon_name, "WeaponProficiencyResource")
				if is_instance_valid(weapon_resource):
					var weapon = weapon_resource
					weapon.set_proficiency(original_value[weapon_name])
					processed_weapon_proficiency.append(weapon)
					print("Weapon proficiency '%s' set to %d." % [weapon_name, original_value[weapon_name]])
				else:
					printerr("Weapon proficiency resource '%s' not found. Keeping as string." % weapon_name)
					processed_weapon_proficiency.append(weapon_name) # Keep original string if not found
			# Set the processed weapon proficiency array
			set(key, processed_weapon_proficiency)

		# --- General Handling for other keys ---
		else:
			# Determine the expected resource type based on the top-level key
			var expected_type_name = Cache.KEY_TO_RESOURCE_TYPE_MAP.get(key, "") # Returns "" if key not in map

			# Process the value recursively, passing the expected type
			var processed_value = _process_value_recursive(original_value, expected_type_name)

			# Set the processed value
			set(key, processed_value)

# --- Recursive Helper Function ---
func _process_value_recursive(value, expected_resource_type_name: String):
	if value is String:
		# Base case: Value is a string
		if not expected_resource_type_name.is_empty():
			# An expected type was passed, use it for lookup
			var resource = Cache.find_loaded_resource_by_name(value, expected_resource_type_name)
			if is_instance_valid(resource):
				return resource
			else:
				# Resource not found WITH expected type
				printerr("Resource '%s' (Expected Type: %s) not found in cache. Keeping as string." % [value, expected_resource_type_name])
				return value # Return original string
		else:
			return value

	elif value is Array:
		# Recursive case: Value is an array
		var processed_array = []
		for item in value:
			# Process each item recursively, passing down the SAME expected type
			processed_array.append(_process_value_recursive(item, expected_resource_type_name))
		return processed_array

	elif value is Dictionary:
		# Recursive case: Dictionary (other than equipped_items which is handled above)
		# Processes VALUES recursively, passing down the same expected type.
		# Processes KEYS as potential generic resources (string keys only).
		var processed_dict = {}
		for item_key in value.keys():
			var item_value = value[item_key]
			var processed_key = item_key # Assume key stays the same initially

			# --- Process Key (Optional - only if keys can be resource names) ---
			# Typically, keys in nested dicts aren't resource names unless specifically designed.
			# If you NEED to process keys, uncomment and adapt this block.
			# if item_key is String:
			# 	var key_resource = Cache.find_loaded_resource_by_name(item_key) # Generic key lookup
			# 	if is_instance_valid(key_resource):
			# 		processed_key = key_resource
			# 	# else: keep original string key

			# --- Process Value ---
			# Pass down the same expected_resource_type_name for the value's context
			var processed_item_value = _process_value_recursive(item_value, expected_resource_type_name)

			processed_dict[processed_key] = processed_item_value # Use original key, processed value

		return processed_dict

	else:
		# Base case: Value is not a String, Array, or Dictionary
		return value # Return the value unchanged
# You'll need a way to determine the primary casting modifier for DCs, etc.
func get_primary_casting_modifier() -> int:
	return 0 # Default or error case
