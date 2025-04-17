class_name TemplateResource extends Resource
@export var name: String = "Template Name"
@export var description: String = "Template Description"
@export var type: GameConst.MonsterTemplateType = GameConst.MonsterTemplateType.WEAK

func get_resource_name() -> String:
	return name

func get_dictionary() -> Dictionary:
	return Helper.clean_dictionary({
		"Name": name,
		"Description": description
	})

func apply_template(monster: MonsterSheet) -> void:
	if not monster:
		print("Monster is null, cannot apply template.")
		return
	
	if GameConst.has_any_template_in_name(monster.get_unit_name()):
		ErrorUtility.print_error("Monster already has a template applied.")
		return

	var adjustments = get_template_adjustments(type)
	if adjustments.is_empty():
		print("No adjustments found for template type: ", type)
		return # Or apply no changes

	# --- Get Modifiers ---
	var level_mod = adjustments.get("level", 0)
	var ac_mod = adjustments.get("ac", 0)
	var attack_mod = adjustments.get("attack", 0)
	var damage_mod = adjustments.get("damage", 0)
	var perception_mod = adjustments.get("perception", 0)
	var saves_mod = adjustments.get("saves", 0)
	var skills_mod = adjustments.get("skills", 0)

	# --- Get Level-Based Adjustments (Based on ORIGINAL level) ---
	var original_level = monster.get_unit_level()
	var level_based_mods = _get_level_based_adjustments(adjustments, original_level)
	var hp_mod = level_based_mods.get("hp", 0)
	var sp_mod = level_based_mods.get("sp", 0)
	var aep_mod = level_based_mods.get("aep", 0)

	# --- Apply Adjustments ---
	# Important: Apply level adjustment LAST if other adjustments depend on the original level
	# Or store original level first as done above.
	monster.set_unit_name(monster.get_unit_name() + " (" + GameConst.get_template_type_as_string(type) + ")", true) # Append template name to monster name

	# Apply HP/SP/AEP (consider minimums, e.g., HP shouldn't go below 1)
	monster.set_unit_max_hit_points(max(1, monster.get_unit_max_hit_points() + hp_mod))
	monster.set_unit_max_stamina_points(max(0, monster.get_unit_max_stamina_points() + sp_mod)) # Assuming SP/AEP can be 0
	monster.set_unit_max_aether_points(max(0, monster.get_unit_max_aether_points() + aep_mod))

	# Apply flat modifiers
	monster.set_unit_base_armor_class(monster.get_unit_base_armor_class() + ac_mod)
	monster.set_unit_perception_modifier(monster.perception_modifier + perception_mod)

	# Apply saving throw modifiers (apply to all saves)
	monster.set_unit_might_saving_throw(monster.get_unit_might_saving_throw() + saves_mod)
	monster.set_unit_agility_saving_throw(monster.get_unit_agility_saving_throw() + saves_mod)
	monster.set_unit_endurance_saving_throw(monster.get_unit_endurance_saving_throw() + saves_mod)
	monster.set_unit_intelligence_saving_throw(monster.get_unit_intelligence_saving_throw() + saves_mod)
	monster.set_unit_insight_saving_throw(monster.get_unit_insight_saving_throw() + saves_mod)
	monster.set_unit_charisma_saving_throw(monster.get_unit_charisma_saving_throw() + saves_mod)

	# Apply attack modifiers
	# Ensure get_attacks() returns the actual attack objects/resources
	var attacks = monster.get_attacks()
	if attacks is Array: # Check if it's an array
		for attack in attacks:
			# Check if attack has the expected methods
			if attack.has_method("adjust_attack_bonus") and attack.has_method("adjust_damage"):
				attack.adjust_attack_bonus(attack_mod)
				attack.adjust_damage(damage_mod)
			else:
				push_warning("Attack object lacks expected adjustment methods.")
	else:
		push_warning("monster.get_attacks() did not return an Array.")


	# Apply skill modifiers
	# Assuming get_skills() returns a Dictionary like {"Acrobatics": 10, "Stealth": 8}
	var skills = monster.get_skills()
	if skills is Dictionary:
		for skill_name in skills.keys():
			# Directly modify if it's safe, or use a setter if available
			# Make sure skill values are integers or floats as expected
			if typeof(skills[skill_name]) == TYPE_INT or typeof(skills[skill_name]) == TYPE_FLOAT:
				if skills[skill_name] <= 0:
					continue # Skip this skill
				skills[skill_name] += skills_mod
			else:
				push_warning("Skill value for %s is not a number." % skill_name)
		# If direct modification isn't safe, you might need a method like:
		# monster.set_skills(skills)
	else:
		push_warning("monster.get_skills() did not return a Dictionary.")

	var abilities = monster.get_abilities()
	if abilities is Array:
		for ability in abilities:
			# Assuming each ability has a method to adjust its DC
			if ability.has_method("adjust_dc"):
				ability.adjust_dc(adjustments.get("dc", 0))
				ability.adjust_damage_string(damage_mod)
			else:
				push_warning("Ability object lacks expected adjustment methods.")
	else:
		push_warning("monster.get_abilities() did not return an Array.")


	# Apply level adjustment last
	monster.set_unit_level(monster.get_unit_level() + level_mod) 

func get_template_adjustments(template_type: GameConst.MonsterTemplateType) -> Dictionary:
	match template_type:
		GameConst.MonsterTemplateType.WEAK:
			return {
				"level": -1,
				"ac": -2,
				"attack": -2,
				"damage": -2,
				"perception": -2,
				"saves": -2,
				"skills": -2,
				"dc": -2,
				"hp_sp_aep_by_level": { # Use lower bound of level range as key
					1: {"hp": -10, "sp": -5, "aep": -5},   # Level 1-2
					3: {"hp": -15, "sp": -8, "aep": -10},  # Level 3-5
					6: {"hp": -20, "sp": -10, "aep": -15}, # Level 6-20
					21: {"hp": -30, "sp": -15, "aep": -20},# Level 21-24
					25: {"hp": -50, "sp": -25, "aep": -30} # Level 25+ (or your highest bracket)
				}
			}
		GameConst.MonsterTemplateType.ELITE:
			return {
				"level": 1,
				"ac": 2,
				"attack": 2,
				"damage": 2, # Note: PF2e damage adjustment needs care (see below)
				"perception": 2,
				"saves": 2,
				"skills": 2,
				"dc": 2,
				"hp_sp_aep_by_level": { # Use lower bound of level range as key
					1: {"hp": 10, "sp": 5, "aep": 5},    # Level 1 (or base for level 1 becoming 2)
					2: {"hp": 15, "sp": 8, "aep": 10},   # Level 2-4 becoming 3-5
					5: {"hp": 20, "sp": 10, "aep": 15},  # Level 5-19 becoming 6-20
					20: {"hp": 30, "sp": 15, "aep": 20},  # Level 20+ becoming 21+
					25: {"hp": 50, "sp": 25, "aep": 30} # Level 25+ (or your highest bracket)
					# Adjust these thresholds based on the *original* level triggering the HP gain
				}
			}
		_: # Default case / No template
			return {}

# Helper function to get the correct HP/SP/AEP adjustments based on level
func _get_level_based_adjustments(adj_dict: Dictionary, monster_level: int) -> Dictionary:
	var result = {"hp": 0, "sp": 0, "aep": 0}
	if not adj_dict.has("hp_sp_aep_by_level"):
		return result

	var level_brackets = adj_dict["hp_sp_aep_by_level"]
	var sorted_levels = level_brackets.keys()
	# Sort descending to find the highest applicable bracket first
	sorted_levels.sort_custom(func(a, b): return a > b)

	for level_threshold in sorted_levels:
		if monster_level >= level_threshold:
			result = level_brackets[level_threshold]
			break # Found the correct bracket

	return result
