extends Resource
class_name MonsterAttackResource
@export var attack_name: String = "Attack Name" # Renamed from 'name'
@export var type: GameConst.DamageCategory = GameConst.DamageCategory.MELEE
@export var ap_cost: int = 1
@export var attack_bonus: int = 0
@export var traits: Array = [] # Keep as String array
@export var damage_string: String = "" # Store the dice + bonus string
@export var damage_type: GameConst.DamageType = GameConst.DamageType.BLUDGEONING # Default
@export_multiline var effects_description: String = "" # Combined/first effect string
@export var extra_damage_string: String = "" # Extra damage string (if any)
@export var extra_damage_type: GameConst.DamageType = GameConst.DamageType.BLUDGEONING # Default for extra damage

func get_resource_name() -> String:
	return attack_name

func get_dictionary() -> Dictionary:
	print("Damage string: ", damage_string) # Debugging line
	return Helper.clean_dictionary({
		"name": attack_name,
		"AP Cost": ap_cost,
		"Damage": damage_string + " " + GameConst.get_damage_type_as_string(damage_type) + " " + GameConst.get_damage_category_as_string(type),
		"Effects": effects_description
	})

func get_damage_string() -> String:
	return damage_string

func get_damage_type() -> GameConst.DamageType:
	return damage_type

func get_cost() -> int:
	return ap_cost

func get_cost_type() -> GameConst.CostType:
	return GameConst.CostType.AP

func adjust_damage(damage: int) -> void:
	damage_string = Helper.adjust_damage_string(damage_string, damage)
	print("Adjusted damage string: ", damage_string) # Debugging line

func adjust_attack_bonus(attack_bonus: int) -> void:
	self.attack_bonus += attack_bonus

func execute(monster: Resource, target: Variant, hit_modifiers: int = 0, damage_modifiers: int = 0, map_count: int = 0) -> void:
	if !is_instance_valid(monster) or !is_instance_valid(target):
		ErrorUtility.print_error("Invalid monster or target.")
		return

	# 1. Determine MAP Penalty
	var map_penalty = 0
	var is_agile = "Agile" in traits # Check if the specific attack has the Agile trait
	map_penalty = Helper.calculate_multiple_attack_modifier(map_count, is_agile) # Assuming Helper has this method

	# 2. Calculate Total Attack Modifier
	# Monster attack modifier is pre-calculated! Just add situational mods and MAP.
	var total_hit_modifier = attack_bonus + hit_modifiers + map_penalty

	# 3. Roll Attack
	var dice = DiceManager.new() # Assuming DiceManager exists
	var hit_roll_result = dice.roll("1d20 + " + str(total_hit_modifier))
	var total_hit_roll = hit_roll_result["total"]

	# 4. Determine Outcome (vs Target AC) - Simplified Success/Failure
	var target_ac = 0
	if target and target.has_method("get_character_sheet") and target.get_character_sheet().has_method("get_unit_base_armor_class"):
		target_ac = target.get_character_sheet().get_unit_base_armor_class()
	else:
		printerr("Error: Target AC could not be determined.")
		# Potentially default to a value or just return, depending on desired behavior
		return

	var outcome = ""
	var success = false # Simplified boolean for success/failure

	if total_hit_roll >= target_ac:
		outcome = "success"
		success = true
	else:
		outcome = "failure"
		success = false

	# 5. Log Attack Roll Outcome
	# Assuming 'Bus' is your global event bus singleton
	var monster_name = monster.get_unit_name() if monster.has_method("get_unit_name") else "Monster"
	var target_name = target.get_character_sheet().get_unit_name() if target.has_method("get_character_sheet") and target.get_character_sheet().has_method("get_unit_name") else "Target"
	Bus.send_roll_to_all.emit(monster_name, "uses " + attack_name + " against", target_name, hit_roll_result, "vs " + str(target_ac) + " AC", outcome)

	# 6. Handle Damage (only on Success)
	if success:
		var total_damage = 0
		var damage_details = {} # For potentially complex logging/application

		# Roll base damage
		var base_damage_roll = dice.roll(damage_string)
		var base_damage_value = base_damage_roll["total"]

		# Roll extra damage if applicable
		var extra_damage_value = 0
		var extra_damage_roll = null
		if extra_damage_string:
			extra_damage_roll = dice.roll(extra_damage_string)
			extra_damage_value = extra_damage_roll["total"]

		# Calculate total damage: Rolled Damage + Flat Bonuses + Modifiers
		# NO critical hit doubling applied
		total_damage = base_damage_value + extra_damage_value + damage_modifiers

		# Prevent negative damage
		if total_damage < 0:
			total_damage = 0

		# 7. Log Damage Roll Outcome
		# Construct a meaningful damage summary string
		var damage_log_string = str(total_damage) + " total damage ("
		damage_log_string += str(base_damage_value) + " " + GameConst.get_damage_type_as_string(damage_type) # Assuming GameConst exists
		if extra_damage_value > 0: damage_log_string += " + " + str(extra_damage_value) + " " + GameConst.get_damage_type_as_string(extra_damage_type)
		if damage_modifiers > 0: damage_log_string += " + " + str(damage_modifiers) + " [mods]"
		damage_log_string += ")"

		# Need roll details for logging too
		var combined_rolls = {"base": base_damage_roll}
		if extra_damage_roll: combined_rolls["extra"] = extra_damage_roll

		Bus.send_roll_to_all.emit(monster_name, "deals damage to", target_name, combined_rolls, damage_log_string, outcome)

		# 8. Apply Damage
		# Ensure target name is correctly retrieved if using names as keys
		var target_node_name = target.name if target is Node else str(target) # Adjust based on how you reference targets
		Bus.apply_damage.emit(target_node_name, total_damage) # Send total numerical damage

	# 9. Handle Additional Effects (Optional - might be outside this function)
	# Trait effects like Grab, Trip, etc., might still trigger on a success
	# Check traits and emit other signals if needed
	# if "Grab" in traits and success: Bus.attempt_grapple.emit(monster, target)
	# ... etc ... This logic might belong elsewhere depending on complexity

# Initialization method
func initialize_from_dict(data: Dictionary):
	self.attack_name = data.get("name", "Unnamed Attack")
	self.ap_cost = data.get("AP_cost", 1) # Default to 1 AP
	self.attack_bonus = data.get("attack_bonus", 0)
	self.traits = Cache._load_resource_name_array(data.get("traits", []), "TraitResource")

	var type_string = data.get("type", "Melee").to_lower()
	# Example mapping (Should make add a helper function for this in GameConst)
	if type_string == "melee":
		self.type = GameConst.DamageCategory.MELEE
	elif type_string == "ranged":
		self.type = GameConst.DamageCategory.RANGED
	# Add other mappings as needed...
	else:
		printerr("Warning: Unknown attack type '%s' for attack '%s'. Defaulting to MELEE." % [type_string, self.attack_name])
		self.type = GameConst.DamageCategory.MELEE

	# Extract Damage String and Type from the 'damage' array
	var damage_array = data.get("damage", [])
	if typeof(damage_array) == TYPE_ARRAY and not damage_array.is_empty():
		var first_damage_entry = damage_array[0]
		if typeof(first_damage_entry) == TYPE_ARRAY and first_damage_entry.size() >= 2:
			self.damage_string = first_damage_entry[0] # e.g., "2d10+10"
			var damage_type_string = first_damage_entry[1].to_lower() # e.g., "piercing"

			# Map Damage Type (String to Enum) - Requires robust mapping
			# Example (Again, use a helper function ideally)
			if damage_type_string == "piercing": self.damage_type = GameConst.DamageType.PIERCING
			elif damage_type_string == "fire": self.damage_type = GameConst.DamageType.FIRE
			elif damage_type_string == "cold": self.damage_type = GameConst.DamageType.COLD
			elif damage_type_string == "acid": self.damage_type = GameConst.DamageType.ACID
			elif damage_type_string == "poison": self.damage_type = GameConst.DamageType.POISON
			elif damage_type_string == "psychic": self.damage_type = GameConst.DamageType.PSYCHIC
			elif damage_type_string == "radiant": self.damage_type = GameConst.DamageType.RADIANT
			elif damage_type_string == "necrotic": self.damage_type = GameConst.DamageType.NECROTIC
			elif damage_type_string == "thunder": self.damage_type = GameConst.DamageType.THUNDER
			elif damage_type_string == "slashing": self.damage_type = GameConst.DamageType.SLASHING
			elif damage_type_string == "bludgeoning": self.damage_type = GameConst.DamageType.BLUDGEONING
			# Add ALL other damage types...
			else:
				printerr("Warning: Unknown damage type '%s' for attack '%s'. Defaulting." % [damage_type_string, self.attack_name])
				# Keep default or handle error
		else:
			printerr("Warning: Unexpected format in 'damage' entry for attack '%s'. Expected [String, String]. Data: %s" % [self.attack_name, str(first_damage_entry)])
	else:
		printerr("Warning: Missing or invalid 'damage' array for attack '%s'." % self.attack_name)


	# Extract Effects Description
	var effects_array = data.get("effects", [])
	if typeof(effects_array) == TYPE_ARRAY and not effects_array.is_empty():
		# Combine effects or take the first one? Let's join them for now.
		self.effects_description = ", ".join(effects_array)
		# Or just take the first: self.effects_description = effects_array[0] if typeof(effects_array[0]) == TYPE_STRING else ""
	else:
		self.effects_description = "" # Ensure it's empty if no effects
