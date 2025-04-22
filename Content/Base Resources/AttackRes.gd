class_name AttackResource extends Resource
@export var name: String = "Unarmed Strike"
@export var description: String = "A basic unarmed attack."
@export var traits: Array = [Cache.find_loaded_resource_by_name("unarmed"), "TraitResource"]
@export var damage_string: String = "1d4"
@export var damage_type: GameConst.DamageType = GameConst.DamageType.BLUDGEONING
@export var damage_category: GameConst.DamageCategory = GameConst.DamageCategory.UNARMED
@export var damage_bonus: int = 0
@export var range: int = 5
@export var weapon: WeaponResource = null

func get_dictionary() -> Dictionary:
	return {
		"name": name,
		"description": description,
		"traits": traits,
		"damage_string": damage_string,
		"damage_type": GameConst.get_damage_type_as_string(damage_type),
		"damage_category": GameConst.get_damage_category_as_string(damage_category),
		"damage_bonus": damage_bonus,
		"range": range
	}

func get_resource_name() -> String:
	return name

func apply_weapon(weapon: WeaponResource) -> void:
	if !is_instance_valid(weapon):
		ErrorUtility.log_error("Invalid weapon resource.")
		return

	if weapon.has_method("get_damage_string"): damage_string = weapon.get_damage_string()
	if weapon.has_method("get_damage_type"): damage_type = weapon.get_damage_type()
	if weapon.has_method("get_damage_category"): damage_category = weapon.get_damage_category()
	if weapon.has_method("get_damage_bonus"): damage_bonus = weapon.get_damage_bonus()
	if weapon.has_method("get_range"): range = weapon.get_range()
	if weapon.has_method("get_traits"): traits = weapon.get_traits()
	if weapon != null: self.weapon = weapon

	for category in weapon.get_damage_category():
		if category == GameConst.DamageCategory.MELEE: name = "Melee Strike"
		elif category == GameConst.DamageCategory.RANGED: name = "Ranged Strike"
		elif category == GameConst.DamageCategory.NATURAL: name = "Natural Strike"
		elif category == GameConst.DamageCategory.UNARMED: name = "Unarmed Strike"
		else:
			printerr("Error: Unknown damage category.")
			name = "Unarmed Strike"

func reset_weapon() -> void:
	# Reset to default values
	name = "Unarmed Strike"
	description = "A basic unarmed attack."
	traits = [Cache.find_loaded_resource_by_name("unarmed"), "TraitResource"]
	damage_string = "1d4"
	damage_type = GameConst.DamageType.BLUDGEONING
	damage_category = GameConst.DamageCategory.UNARMED
	damage_bonus = 0
	range = 5
	weapon = null

func calculate_attack_modifier(character: Resource, map: int = 0, situational_hit_mods: int = 0) -> int:
	if not is_instance_valid(character):
		printerr("Cannot calculate attack modifier: Invalid character.")
		return -99 # Return an unlikely value to indicate error

	var attribute_mod: int = 0
	var proficiency_mod: int = 0
	var item_mod: int = 0 # From potency runes

	var use_finesse: bool = false
	var is_agile: bool = false
	var is_thrown: bool = false
	# var is_ranged: bool = false # Add if handling non-thrown ranged

	# --- Determine Relevant Traits ---
	for t in traits:
		if not is_instance_valid(t): continue
		var trait_name = t.get_resource_name().to_lower()
		match trait_name:
			"finesse":
				use_finesse = true
			"agile":
				is_agile = true
			"thrown":
				is_thrown = true
			# "ranged": is_ranged = true # Example

	# --- Determine Attribute Modifier ---
	var agi = character.get_unit_agility_modifier() if character.has_method("get_unit_agility_modifier") else 0
	var might = character.get_unit_might_modifier() if character.has_method("get_unit_might_modifier") else 0

	if is_thrown:
		# Thrown uses Strength unless Finesse applies (and Dex is higher)
		attribute_mod = might
		if use_finesse and agi > might:
			attribute_mod = agi
	# elif is_ranged: # Non-thrown ranged uses Dexterity
	#	 attribute_mod = agi
	elif use_finesse:
		# Melee Finesse uses higher of Strength or Dexterity
		attribute_mod = max(agi, might)
	else:
		# Default Melee uses Strength
		attribute_mod = might

	# --- Determine Proficiency Modifier ---
	var prof_category = GameConst.DamageCategory.UNARMED # Default
	if weapon != null and weapon.has_method("get_weapon_proficiency_category"):
		prof_category = weapon.get_weapon_proficiency_category()
	# else: Use default unarmed category

	if character.has_method("get_weapon_ proficiency_modifier"):
		proficiency_mod = character.get_weapon_proficiency_modifier(prof_category)
	else:
		printerr("Character missing 'get_weapon_proficiency_modifier'.")

	# --- Determine Item Modifier (Potency Rune) ---
	# Placeholder - Add logic to get potency bonus from weapon resource
	# if weapon != null and weapon.has_method("get_potency_bonus"):
	#	 item_mod = weapon.get_potency_bonus()

	# --- Calculate MAP ---
	var map_mod = Helper.calculate_multiple_attack_modifier(map, is_agile)
	# --- Sum Modifiers ---
	var total_modifier = attribute_mod + proficiency_mod + item_mod + situational_hit_mods + map_mod
	return total_modifier

func calculate_damage_details(character: Resource, situational_damage_mods: int = 0) -> Dictionary:
	if not is_instance_valid(character):
		printerr("Cannot calculate damage details: Invalid character.")
		return {"dice_string": "1d4", "flat_bonus": 0, "damage_type": GameConst.DamageType.BLUDGEONING}

	# Get base values from this AttackResource
	var base_dice = damage_string
	var base_flat_bonus = damage_bonus
	var base_damage_type = damage_type

	# --- Add Attribute Modifier to Damage (Common for Melee) ---
	# Adjust this logic based on PF2e rules (Str for melee, maybe propulsive/etc for ranged)
	var attribute_damage_bonus = 0
	#if damage_category == GameConst.DamageCategory.MELEE or damage_category == GameConst.DamageCategory.UNARMED:
		#if character.has_method("get_unit_might_modifier"):
			#attribute_damage_bonus = character.get_unit_might_modifier()
			# Ensure Str mod doesn't make damage negative if it's low, unless intended
			# attribute_damage_bonus = max(0, attribute_damage_bonus) # Optional: Prevent negative damage from low Str

	# --- Add Striking Rune Effects (Placeholder) ---
	# You would modify base_dice here based on striking runes on the weapon
	# if weapon != null and weapon.has_method("get_striking_dice_count"):
	#	 var dice_count = weapon.get_striking_dice_count() # e.g., returns 1, 2, 3
	#	 if dice_count > 1:
	#		 base_dice = str(dice_count) + base_dice.substr(1) # Basic example: "1d8" -> "2d8"

	# --- Add Other Damage Property Runes (Placeholder) ---
	# Add flat bonuses from runes like Flaming, Frost, etc.
	# var property_rune_bonus = 0
	# if weapon != null and weapon.has_method("get_property_rune_bonus"):
	#	 property_rune_bonus = weapon.get_property_rune_bonus()


	# --- Sum Flat Bonuses ---
	var total_flat_bonus = base_flat_bonus + attribute_damage_bonus + situational_damage_mods # + property_rune_bonus

	return {
		"dice_string": base_dice,
		"flat_bonus": total_flat_bonus,
		"damage_type": base_damage_type
	}

func execute(character: Resource, target: Variant, execution_paremeters: Dictionary = {}) -> void:
	if not is_instance_valid(character) or not is_instance_valid(target):
		ErrorUtility.print_error("Invalid character or target.")
		return
	
	# --- Get parameters ---
	var hit_modifiers = execution_paremeters.get("hit", 0)
	var damage_modifiers = execution_paremeters.get("damage", 0)
	var chosen_versatile_damage_type = execution_paremeters.get("versatile_type", -1)
	var map = execution_paremeters.get("map", 0)

	# --- Get Attack Modifier ---
	var total_attack_mod = calculate_attack_modifier(character, map, hit_modifiers)
	if total_attack_mod == -99: return # Exit if calculation failed

	# --- Roll for Hit ---
	var dice = DiceManager.new()
	var hit_roll = dice.roll("1d20 + " + str(total_attack_mod))

	# --- Determine Hit Success & Outcome (Add Crit Logic Here) ---
	var target_ac = 0
	var target_sheet = target.get_character_sheet() if target != null and target.has_method("get_character_sheet") else null
	if target_sheet != null and target_sheet.has_method("get_unit_base_armor_class"): # TODO: Use actual AC
		target_ac = target_sheet.get_unit_base_armor_class()
	else:
		printerr("Invalid target AC.")
		return # Or handle attack vs AC 0?

	var hit_success = hit_roll["total"] >= target_ac
	# TODO: Implement Critical Success (>= AC + 10 or Nat 20) & Critical Failure (Nat 1)
	var is_critical_hit = false # Placeholder
	var outcome = "success" if hit_success else "failure" # Update with crit info

	# --- Report Hit Roll ---
	var vs_text = "vs " + str(target_ac) + " AC"
	var target_name = target_sheet.get_unit_name() if target_sheet else "Unknown Target"
	Bus.send_roll_to_all.emit(character.get_unit_name(), "rolls hit against", target_name, hit_roll, vs_text, outcome)

	# --- Handle Damage ---
	if hit_success:
		# --- Determine Final Damage Type (Handling Versatile) ---
		var final_damage_type = damage_type # Default type from AttackResource
		for t in traits: # Check traits again specifically for versatile choice logic
			if is_instance_valid(t) and t.t_name.to_lower() == "versatile":
				var versatile_option_code = t.parameters["damage_type"]
				if not versatile_option_code.is_empty():
					if chosen_versatile_damage_type != -1:
						final_damage_type = chosen_versatile_damage_type
						print("Using pre-chosen Versatile damage type: ", GameConst.get_damage_type_as_string(final_damage_type))

		# --- Get Damage Details ---
		var damage_details = calculate_damage_details(character, damage_modifiers)

		# --- Roll Damage Dice ---
		var damage_dice_roll = dice.roll(damage_details.dice_string)
		var rolled_damage = damage_dice_roll["total"]

		# --- Apply Critical Hit Damage (Placeholder) ---
		if is_critical_hit:
			rolled_damage *= 2 # Double the dice roll result for crit
			# Add critical specialization effects here later

		# --- Calculate Total Damage ---
		var total_damage = rolled_damage + damage_details.flat_bonus

		# --- Report and Apply Damage ---
		var damage_type_string = GameConst.get_damage_type_as_string(final_damage_type)
		var damage_report_text = "for " + str(total_damage) + " " + damage_type_string + " damage"
		Bus.send_roll_to_all.emit(character.get_unit_name(), "rolls damage against", target_name, damage_dice_roll, damage_report_text, outcome)

		# Apply damage (consider damage type for resistances later)
		Bus.apply_damage.emit(target.name, total_damage, final_damage_type)
		Bus.send_environment_message_to_all.emit(character.get_unit_name() + " uses " + name + " on " + target_name, "normal")
