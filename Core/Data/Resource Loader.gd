extends Node

var monster_ability_type_mapping: Dictionary = {
	"proactive abilities": GameConst.MonsterAbilityCategory.PROACTIVE,
	"automatic_abilities": GameConst.MonsterAbilityCategory.AUTOMATIC
}

# ===================== RESOURCE CORE FUNCTIONS =====================
func _ready():
	await Cache.loading_complete
	create_ability_resources_from_monster_json(
		"user://Addons/Base/Monsters/monsters.json",
		"res://Content/Monsters/Abilities/",
		MonsterAbilityResource,
		monster_ability_type_mapping,
		ResourceConst.MONSTER_ABILITY_JSON_KEYS,
		ResourceConst.MONSTER_ABILITY_JSON_TYPES
	)

	create_attack_resources_from_monster_json("user://Addons/Base/Monsters/monsters.json",
		"res://Content/Monsters/Attacks/",
		MonsterAttackResource,
		"attacks",
		ResourceConst.MONSTER_ATTACK_JSON_KEYS,
		ResourceConst.MONSTER_ATTACK_JSON_TYPES)

	process_json_definitions("user://Addons/Base/Monsters/monsters.json", "res://Content/Monsters/",
							 ResourceConst.MONSTER_JSON_KEYS, ResourceConst.MONSTER_JSON_TYPES, MonsterSheet, "parse_monster_data", [], false)
	# create_resources()

	var armor_json_data = _load_json_get_array("user://Addons/Base/Items/armors.json", "armor")
	var weapon_json_data = _load_json_get_array("user://Addons/Base/Items/armors.json", "weapons")
	if not armor_json_data.is_empty():
		_process_definition_array(armor_json_data, "res://Content/Items/Armor/", # ADJUST PATH
										ResourceConst.ARMOR_JSON_KEYS, ResourceConst.ARMOR_JSON_TYPES, ArmorResource,
										"parse_armor_data", [], false, "user://Addons/Base/Items/armors.json") # Pass original path for logging
	if not weapon_json_data.is_empty():
		_process_definition_array(weapon_json_data, "res://Content/Items/Weapons/", # ADJUST PATH
										ResourceConst.WEAPON_JSON_KEYS, ResourceConst.WEAPON_JSON_TYPES, WeaponResource,
										"parse_weapon_data", [], false, "user://Addons/Base/Items/armors.json") # Pass original path for logging


func create_resources():
	process_json_definitions("user://Addons/Base/Traits/traits.json", "res://Content/Traits/",
							 ResourceConst.TRAIT_JSON_KEYS, ResourceConst.TRAIT_JSON_TYPES, TraitResource, "", [])
	var perk_script = load("res://path/to/PerkResource.gd") # Make sure path is correct
	process_json_definitions("user://Addons/Base/Perks/", "res://Content/Perks/",
							 ResourceConst.PERK_JSON_KEYS, ResourceConst.PERK_JSON_TYPES, perk_script, "parse", ["traits"])

# ===================== JSON PARSING FUNCTIONS =====================
# Process JSON definitions. Includes detailed logging for skips/failures.
func process_json_definitions(input_path: String, output_dir_path: String, required_keys: Array, required_types: Array, resource_type: Variant,
								parser_method_name: String, parser_method_args: Array, custom_prefix: bool = true) -> void:

	# --- Validate resource_type ---
	var actual_script: Script = null
	if resource_type is Script:
		actual_script = resource_type
	else:
		ErrorUtility.log_error("Invalid resource_type provided for input '%s'. Expected a loaded Script or GDScript class reference. Got type: %s" % [input_path, typeof(resource_type)])
		return

	if not is_instance_valid(actual_script) or not actual_script.can_instantiate():
		ErrorUtility.log_error("Provided resource_type Script is invalid or cannot be instantiated for input '%s'." % input_path)
		return

	# --- Determine the prefix ---
	var name_prefix: String = ""
	if is_instance_valid(actual_script) and not actual_script.resource_path.is_empty():
		var script_filename = actual_script.resource_path.get_file().get_basename()
		if not script_filename.is_empty() and custom_prefix:
			name_prefix = script_filename[0].to_lower()

	if name_prefix.is_empty():
		ErrorUtility.log_warning("Could not determine resource script filename to derive 'name' variable prefix for input '%s'. Name mapping might fail." % input_path)

	var json_definitions: Array = []
	var json_parser := JSON.new() # Create an instance

	# --- Case 1: Input path is a FILE ---
	if FileAccess.file_exists(input_path):
		var content: String = FileAccess.get_file_as_string(input_path)
		if FileAccess.get_open_error() != Error.OK:
			ErrorUtility.log_error("Failed to open or read JSON file: %s, Error code: %s" % [input_path, FileAccess.get_open_error()])
			return

		var error_code = json_parser.parse(content)
		if error_code != Error.OK:
			var error_line = json_parser.get_error_line()
			var error_message = json_parser.get_error_message()
			ErrorUtility.log_error("JSON Parse Error in file '%s': %s (Line: %d). Error Code: %d" % [input_path, error_message, error_line, error_code])
			return

		var parse_result: Variant = json_parser.get_data()

		if typeof(parse_result) == TYPE_DICTIONARY and parse_result.has("monsters"):
			var monster_array = parse_result["monsters"]
			if typeof(monster_array) == TYPE_ARRAY:
				json_definitions = monster_array # Use the inner array
			else:
				ErrorUtility.log_error("Expected an Array for the 'monsters' key in file '%s', got %s." % [input_path, typeof(monster_array)])
				return
		elif typeof(parse_result) == TYPE_ARRAY:
			json_definitions = parse_result
		elif typeof(parse_result) == TYPE_DICTIONARY:
			ErrorUtility.log_warning("JSON file '%s' contains a single object, not an array. Processing it as one definition." % input_path)
			json_definitions = [parse_result]
		else:
			ErrorUtility.log_error("Unexpected JSON root type in file '%s'. Expected Array or Dictionary, got %s." % [input_path, typeof(parse_result)])
			return

	# --- Case 2: Input path is a DIRECTORY ---
	elif DirAccess.dir_exists_absolute(input_path):
		var dir_access := DirAccess.open(input_path)
		if dir_access == null:
			ErrorUtility.log_error("Failed to open directory: %s. Error code: %s" % [input_path, DirAccess.get_open_error()])
			return

		dir_access.list_dir_begin()
		var file_name: String = dir_access.get_next()
		while not file_name.is_empty():
			if not dir_access.current_is_dir() and file_name.get_extension().to_lower() == "json":
				var full_file_path: String = input_path.path_join(file_name)
				var file_content: String = FileAccess.get_file_as_string(full_file_path)

				if FileAccess.get_open_error() != Error.OK:
					ErrorUtility.log_warning("Failed to open or read file '%s' in directory '%s'. Error code: %s" % [full_file_path, input_path, FileAccess.get_open_error()])
					file_name = dir_access.get_next()
					continue

				var file_error_code = json_parser.parse(file_content)
				if file_error_code != Error.OK:
					ErrorUtility.log_warning("JSON Parse Error in file '%s': %s (Line: %d). Error Code: %d" % [full_file_path, json_parser.get_error_message(), json_parser.get_error_line(), file_error_code])
				else:
					var file_parse_result: Variant = json_parser.get_data()
					if typeof(file_parse_result) == TYPE_DICTIONARY:
						json_definitions.append(file_parse_result)
					else:
						ErrorUtility.log_warning("Skipping file '%s' as its content is not a JSON Dictionary. Found type: %s" % [full_file_path, typeof(file_parse_result)])

			file_name = dir_access.get_next()
		# dir_access closes automatically

	else:
		ErrorUtility.log_error("Input path not found or invalid: %s" % input_path)
		return

	# --- Process all collected definitions ---
	if json_definitions.is_empty():
		ErrorUtility.log_warning("No valid JSON definitions found to process for input: %s" % input_path)
		return

	# Ensure output directory exists
	var create_err := DirAccess.make_dir_recursive_absolute(output_dir_path)
	if create_err != Error.OK and create_err != Error.ERR_ALREADY_EXISTS:
		ErrorUtility.log_error("Failed to create output directory: %s. Error code: %s" % [output_dir_path, create_err])
		return

	# --- Initialize counters and lists for detailed logging ---
	var count_success : int = 0
	var count_skipped : int = 0
	var count_failed : int = 0
	var skipped_items := [] # Array to store details of skipped items
	var failed_items := []  # Array to store details of failed items
	# -----------------------------------------------------------

	for index in range(json_definitions.size()):
		var json_data = json_definitions[index]
		var item_name_for_log = "Index %d" % index # Default identifier if name is missing/invalid

		if typeof(json_data) != TYPE_DICTIONARY:
			var reason = "Not a Dictionary"
			ErrorUtility.log_warning("Skipping item %s from '%s' because it's %s. Found type: %s" % [item_name_for_log, input_path, reason.to_lower(), typeof(json_data)])
			skipped_items.append({"id": item_name_for_log, "reason": reason})
			count_skipped += 1
			continue

		# Try to get name early for better logging, but handle potential errors
		var base_name_var: Variant = json_data.get("name", null) # Use .get() for safety
		var base_name : String = ""

		if base_name_var == null:
			var reason = "Missing 'name' key"
			ErrorUtility.log_warning("Skipping item %s from '%s' because it %s: %s" % [item_name_for_log, input_path, reason.to_lower(), str(json_data).substr(0,80)])
			skipped_items.append({"id": item_name_for_log, "reason": reason, "data_snippet": str(json_data).substr(0,50)})
			count_skipped += 1
			continue
		elif typeof(base_name_var) != TYPE_STRING:
			var reason = "'name' key is not a String"
			ErrorUtility.log_warning("Skipping item %s from '%s' because its %s: %s" % [item_name_for_log, input_path, reason.to_lower(), str(json_data).substr(0,80)])
			skipped_items.append({"id": item_name_for_log, "reason": reason, "data_snippet": str(json_data).substr(0,50)})
			count_skipped += 1
			continue
		else:
			base_name = base_name_var.strip_edges().to_lower()
			if not base_name.is_empty():
				item_name_for_log = "'%s'" % base_name # Use actual name in logs if valid

		if base_name.is_empty(): # Check after processing
			var reason = "'name' is empty after processing"
			ErrorUtility.log_warning("Skipping item %s from '%s' because its %s: %s" % [item_name_for_log, input_path, reason.to_lower(), str(json_data).substr(0,80)])
			skipped_items.append({"id": item_name_for_log, "reason": reason, "data_snippet": str(json_data).substr(0,50)})
			count_skipped += 1
			continue

		var output_file_path: String = output_dir_path.path_join(base_name + ".tres")

		if FileAccess.file_exists(output_file_path):
			var reason = "File already exists"
			# Optional: print("Skipping existing file for %s" % item_name_for_log)
			skipped_items.append({"id": item_name_for_log, "reason": reason, "path": output_file_path})
			count_skipped += 1
			continue

		# --- Attempt to parse and create ---
		var success: bool = parse_and_create_tres(parser_method_name, parser_method_args, json_data, output_file_path, required_keys, required_types, actual_script, name_prefix)

		if success:
			count_success += 1
		else:
			# Specific error should have been logged by parse_and_create_tres or parse_resource
			var reason = "Parse/Save Failed"
			failed_items.append({"id": item_name_for_log, "reason": reason, "path": output_file_path})
			count_failed += 1

	# --- Final Summary Logging ---
	print("--------------------------------------------------")
	print("Finished processing '%s'." % input_path)
	print("  Created: %d" % count_success)
	print("  Failed:  %d" % count_failed)
	print("  Skipped: %d" % count_skipped)
	print("--------------------------------------------------")

	# --- Detailed Failed Items Log ---
	if not failed_items.is_empty():
		printerr("-- Failed Items (%d) --" % failed_items.size()) # Use printerr for errors
		for item in failed_items:
			printerr("  - Item: %s, Reason: %s (Path Attempted: %s)" % [
					item.get("id", "N/A"),
					item.get("reason", "Unknown"),
					item.get("path", "N/A")
				])
		printerr("--------------------------------------------------") # Separate error section

	# --- Detailed Skipped Items Log ---
	if not skipped_items.is_empty():
		print("-- Skipped Items (%d) --" % skipped_items.size()) # Regular print for skips
		for item in skipped_items:
			var reason = item.get("reason", "Unknown")
			var identifier = item.get("id", "N/A")
			var details = ""
			if item.has("path"):
				details = "(Path: %s)" % item.get("path")
			elif item.has("data_snippet"):
				details = "(Data: %s...)" % item.get("data_snippet")

			print("  - Item: %s, Reason: %s %s" % [identifier, reason, details])
		print("--------------------------------------------------")


# ===================== CONTENT PARSE FUNCTIONS =====================
# (parse_multiple remains the same, using % formatting)

func parse_multiple(parsed_json: Dictionary, parsers_config: Array) -> Dictionary:
	var current_json := parsed_json.duplicate(true)
	for config_item in parsers_config:
		if typeof(config_item) == TYPE_STRING:
			var method_name := StringName(config_item)
			if has_method(method_name):
				current_json = call(method_name, current_json)
				if typeof(current_json) != TYPE_DICTIONARY:
					ErrorUtility.log_error("Parser method '%s' did not return a Dictionary." % method_name)
					return parsed_json
			else:
				ErrorUtility.log_error("Parser method '%s' not found." % method_name)
				return parsed_json
		elif typeof(config_item) == TYPE_DICTIONARY:
			for method_key in config_item:
				var method_name := StringName(method_key)
				var args_array: Array = config_item[method_key]
				if not args_array is Array:
					ErrorUtility.log_error("Arguments for parser method '%s' must be an Array." % method_name)
					return parsed_json
				var args = [current_json] + args_array
				if has_method(method_name):
					current_json = callv(method_name, args)
					if typeof(current_json) != TYPE_DICTIONARY:
						ErrorUtility.log_error("Parser method '%s' did not return a Dictionary." % method_name)
						return parsed_json
				else:
					ErrorUtility.log_error("Parser method '%s' not found." % method_name)
					return parsed_json
		elif typeof(config_item) == TYPE_ARRAY and not config_item.is_empty():
			for inner_config_item in config_item:
				current_json = parse_multiple(current_json, [inner_config_item])
				if typeof(current_json) != TYPE_DICTIONARY: return parsed_json
		else:
			ErrorUtility.log_error("Invalid parser config item type: %s. Should be String, Dictionary or Array." % typeof(config_item))
			return parsed_json
	return current_json

# ===================== RESOURCE LOADING FUNCTIONS =====================
# (get_resource remains the same)

func get_resource(dir_path: String, file_name: String) -> Resource:
	var file_path = dir_path.path_join(file_name.strip_edges().to_lower() + ".tres")
	if not ResourceLoader.exists(file_path):
		return null
	var res: Resource = ResourceLoader.load(file_path)
	if not res is Resource:
		return null
	return res

# (parse_and_create_tres remains the same, using % formatting)

func parse_and_create_tres(parser_method_name: String, parser_method_args: Array, json_data: Dictionary, output_file_path: String, required_keys: Array, required_types: Array, resource_script: Script, name_prefix: String) -> bool: # ADDED name_prefix arg
	print("Attempting to parse resource for JSON: ", str(json_data).substr(0, 100), "...")
	# Pass the name_prefix down
	var resource_instance: Resource = parse_resource(json_data, resource_script, required_keys, required_types, parser_method_name, parser_method_args, name_prefix) # ADDED name_prefix

	if resource_instance == null:
		# Error logged in parse_resource
		printerr("--> Parse failed, returning false.")
		return false
	else:
		print("--> Parse successful, resource instance created.")

	print("--> Attempting to save resource to: '%s'" % output_file_path)
	var save_err := ResourceSaver.save(resource_instance, output_file_path)
	if save_err != Error.OK:
		# Use % formatting
		ErrorUtility.log_error("Failed to save resource to '%s'. Error code: %s" % [output_file_path, save_err])
		return false

	# print("Successfully created: " + output_file_path) # Optional success message
	return true

# (parse_resource remains the same, using % formatting)

# Inside your resource creation script...

func parse_resource(json_data: Dictionary, resource_script: Script, required_keys: Array, required_types: Array, parser_method_name: String, parser_method_args: Array, name_prefix: String) -> Resource:

	# --- 1. Validation ---
	print("-----> Validating JSON keys/types...")
	if not ExternalUtility.ensure_json_type_and_keys(json_data, required_keys, required_types):
		ErrorUtility.log_error("JSON data failed validation (keys/types). Data: %s..." % str(json_data).substr(0, 200))
		return null
	print("-----> Validation OK.")

	# --- 2. Pre-processing ---
	var processed_json := json_data.duplicate(true)
	if not parser_method_name.is_empty():
		print("-----> Calling custom parser: '%s'" % parser_method_name)
		var method := StringName(parser_method_name)
		if has_method(method):
			var args = [processed_json] + parser_method_args
			var result: Variant = callv(method, args)
			if typeof(result) == TYPE_DICTIONARY:
				processed_json = result
				print("-----> Custom parser finished. Processed keys: ", processed_json.keys())
			else:
				ErrorUtility.log_error("Parser method '%s' did not return a Dictionary. Returned type: %s" % [parser_method_name, typeof(result)])
				return null
		else:
			ErrorUtility.log_error("Parser method '%s' not found." % parser_method_name)
			return null
	else:
		print("-----> No custom parser used. Using original JSON keys: %s" % processed_json.keys())


	# --- 3. Resource Instantiation ---
	print("-----> Instantiating resource from script: ", resource_script.resource_path if resource_script else "null")
	if not is_instance_valid(resource_script) or not resource_script.can_instantiate():
		ErrorUtility.log_error("Cannot instantiate invalid or non-instantiable script: %s" % resource_script.resource_path if resource_script else "null")
		return null

	var resource_instance: Variant = resource_script.new()

	if not resource_instance is Resource:
		ErrorUtility.log_error("Failed to instantiate Resource from script: %s" % resource_script.resource_path)
		return null
	print("-----> Instantiation successful.")

	# --- 4. Initialization using custom method ---
	# Check if the resource has the specific initialization method
	if resource_instance.has_method("initialize_from_dict"):
		print("-----> Calling initialize_from_dict...")
		resource_instance.initialize_from_dict(processed_json)
		print("-----> Finished calling initialize_from_dict.")
		# Optional: Verify values right after initialization
		print("-----> Verifying some values after init: Name='%s', Level=%s, Size=%s" % [
			resource_instance.get("monster_name"),
			resource_instance.get("level"),
			resource_instance.get("size") # Check the integer value
		])
	else:
		# --- Fallback: Original generic set() loop (might still warn/fail for some resources) ---
		# Keep this if you have other resource types that *do* work with set()
		# Or remove if all your resources will use an init method
		print("-----> WARNING: Resource %s lacks 'initialize_from_dict'. Falling back to generic set()..." % resource_script.resource_path)
		print("-----> Attempting to set properties using generic set()...")
		var properties_set_count = 0
		for key in processed_json:
			var value = processed_json[key]
			var target_property = key

			if key == "name" and not name_prefix.is_empty():
				target_property = name_prefix + "_name"

			print("-------> [Fallback] Setting '%s' with value: %s (Type: %s)" % [target_property, str(value).substr(0, 50), typeof(value)])
			resource_instance.set(target_property, value) # This will likely still produce warnings for MonsterSheet
			properties_set_count += 1
		print("-----> [Fallback] Finished setting properties. Attempted to set %d properties." % properties_set_count)

	# --- 5. Return ---
	return resource_instance

# Add this function to your resource creation script

# Custom parser specifically for the monster JSON structure
# Inside your resource creation script

# This function ONLY reshapes the JSON structure: renames keys and unpacks nested objects.
# It passes the raw values (strings, numbers, arrays of strings) through.
func parse_monster_data(json_data: Dictionary) -> Dictionary:
	print("-----> Reshaping JSON data for monster: ", json_data.get("name", "N/A"))
	# Duplicate the input dictionary to avoid modifying the original
	var new_data := json_data.duplicate(true)
	var raw_data: Dictionary = {}
	# Clean up the keys
	for key in new_data.keys():
		var value = new_data[key]
		var new_key = key.replace(" ", "_")
		raw_data[new_key] = value

	# --- Perform Renames and Unpacking ---

	# Rename simple keys
	if raw_data.has("name"):
		raw_data["monster_name"] = raw_data["name"] # Copy and remove original
		raw_data.erase("name") # Remove original
	if raw_data.has("flavorText"):
		raw_data["flavor_text"] = raw_data["flavorText"] # Copy and remove original
		raw_data.erase("flavorText") # Remove original
	if raw_data.has("lore"):
		raw_data["description"] = raw_data["lore"] # Copy and remove original
		raw_data.erase("lore") # Remove original
	if raw_data.has("HP"):
		raw_data["max_hit_points"] = raw_data["HP"] # Copy and remove original
		raw_data.erase("HP") # Remove original
	if raw_data.has("SP"):
		raw_data["max_stamina_points"] = raw_data["SP"] # Copy and remove original
		raw_data.erase("SP") # Remove original
	if raw_data.has("ÆP"):
		raw_data["max_aether_points"] = raw_data["ÆP"] # Copy and remove original
		raw_data.erase("ÆP") # Remove original

	# Unpack 'attributes'
	if raw_data.has("attributes") and typeof(raw_data["attributes"]) == TYPE_DICTIONARY:
		var attributes_data = raw_data["attributes"]
		raw_data["might_modifier"] = attributes_data.get("Mig", 0)
		raw_data["agility_modifier"] = attributes_data.get("Agi", 0)
		raw_data["endurance_modifier"] = attributes_data.get("End", 0)
		raw_data["intelligence_modifier"] = attributes_data.get("Int", 0)
		raw_data["insight_modifier"] = attributes_data.get("Ins", 0)
		raw_data["charisma_modifier"] = attributes_data.get("Cha", 0)
		raw_data.erase("attributes") # Remove the original nested dictionary

	# Unpack 'defenses'
	if raw_data.has("defenses") and typeof(raw_data["defenses"]) == TYPE_DICTIONARY:
		var defenses_data = raw_data["defenses"]
		raw_data["base_armor_class"] = defenses_data.get("AC", 10)
		raw_data["might_saving_throw"] = defenses_data.get("Mig_Save", 0)
		raw_data["agility_saving_throw"] = defenses_data.get("Agi_Save", 0)
		raw_data["endurance_saving_throw"] = defenses_data.get("End_Save", 0)
		raw_data["intelligence_saving_throw"] = defenses_data.get("Int_Save", 0)
		raw_data["insight_saving_throw"] = defenses_data.get("Ins_Save", 0)
		raw_data["charisma_saving_throw"] = defenses_data.get("Cha_Save", 0)
		# Copy the arrays of names directly
		raw_data["damage_immunities"] = defenses_data.get("immunities", [])
		raw_data["damage_resistances"] = defenses_data.get("resistances", [])
		raw_data["damage_weaknesses"] = defenses_data.get("weaknesses", [])
		raw_data["condition_immunities"] = defenses_data.get("condition_immunities", [])
		raw_data.erase("defenses") # Remove the original nested dictionary

	# Unpack 'perception'
	if raw_data.has("perception") and typeof(raw_data["perception"]) == TYPE_DICTIONARY:
		var perception_data = raw_data["perception"]
		raw_data["perception_modifier"] = perception_data.get("bonus", 0)
		raw_data["senses"] = perception_data.get("abilities", {}) # Copy senses dict directly
		raw_data.erase("perception") # Remove the original nested dictionary

	# Unpack 'movement'
	if raw_data.has("movement") and typeof(raw_data["movement"]) == TYPE_DICTIONARY:
		var movement_data = raw_data["movement"]
		raw_data["base_speed"] = movement_data.get("land_speed", 0)
		raw_data["base_climb_speed"] = movement_data.get("climb_speed", 0)
		raw_data["base_fly_speed"] = movement_data.get("fly_speed", 0)
		raw_data["base_swim_speed"] = movement_data.get("swim_speed", 0)
		raw_data["base_burrow_speed"] = movement_data.get("burrow_speed", 0)
		raw_data.erase("movement") # Remove the original nested dictionary

	# Convert 'skills' dictionary keys to an array
	if raw_data.has("skills") and typeof(raw_data["skills"]) == TYPE_DICTIONARY:
		raw_data["skills"] = raw_data["skills"]

	# Handle abilities, replacing with names for lookup later.
	if raw_data.has("proactive_abilities"):
		print("-----> Found proactive abilities: ", raw_data["proactive_abilities"])
		var proactive_abilities_names = []
		for ability in raw_data["proactive_abilities"]:
			if typeof(ability) == TYPE_DICTIONARY and ability.has("name"):
				proactive_abilities_names.append(ability["name"])
		raw_data["proactive_abilities"] = proactive_abilities_names
	if raw_data.has("automatic_abilities"):
		print("-----> Found automatic abilities: ", raw_data["automatic_abilities"])
		var automatic_abilities_names = []
		for ability in raw_data["automatic_abilities"]:
			if typeof(ability) == TYPE_DICTIONARY and ability.has("name"):
				automatic_abilities_names.append(ability["name"])
		raw_data["automatic_abilities"] = automatic_abilities_names
	if raw_data.has("attacks"):
		print("-----> Found attacks: ", raw_data["attacks"])
		var attack_names = []
		for attack in raw_data["attacks"]:
			if typeof(attack) == TYPE_DICTIONARY and attack.has("name"):
				attack_names.append(attack["name"])
		raw_data["attacks"] = attack_names

	# --- Call the central preparation function ---
	print("-----> Calling Cache.prepare_monster_sheet_data with reshaped raw data...")
	var prepared_data = Cache.prepare_monster_sheet_data(raw_data) # Pass the modified raw_data

	# --- Return the fully prepared data ---
	print("-----> Returning prepared data for initialization. Keys: ", prepared_data.keys())
	return prepared_data # Return the result from the Cache preparation function

# Add this function to your main resource creation script (the one with process_json_definitions)

# --- Function to Pre-create Ability Resources from Monster JSON ---

# Scans a monster JSON file, extracts unique ability definitions from specified keys,
# and creates .tres resources for them in a dedicated directory.
func create_ability_resources_from_monster_json(
		monster_json_path: String,          # Path to the main monster JSON (e.g., "user://.../monsters.json")
		base_ability_output_dir: String,    # The main output dir (e.g., "res://Content/Monsters/Abilities/")
		ability_resource_script: Variant,   # The Script or ClassName for abilities (e.g., MonsterAbilityResource class ref)
		ability_key_map: Dictionary,        # Dictionary mapping JSON keys to Category Enums: {"proactive abilities": CategoryEnum.PROACTIVE, ...}
		ability_required_keys: Array = [],  # Optional: Required keys within an ability's JSON definition
		ability_required_types: Array = []  # Optional: Required types for those keys
		# custom_prefix argument is less relevant here and removed for clarity
	) -> void:

	print("\n--- Starting Ability Resource Creation (Per Monster Folders) ---")
	print("Scanning Monster JSON: %s" % monster_json_path)
	print("Base Output Directory for Abilities: %s" % base_ability_output_dir)
	print("Ability Key Map: %s" % str(ability_key_map))

	# --- Validate Ability Resource Type ---
	# This variable will hold the actual Script or Class reference/name to use with .new()
	var actual_ability_script_ref: Variant = null
	if ability_resource_script is Script:
		actual_ability_script_ref = ability_resource_script
		if not actual_ability_script_ref.can_instantiate():
			ErrorUtility.log_error("Provided ability_resource_script Script cannot be instantiated: %s" % actual_ability_script_ref.resource_path)
			return
	elif ability_resource_script is GDScript: # Handle direct class reference (like MonsterAbilityResource)
		actual_ability_script_ref = ability_resource_script
		# Assume GDScript class references are always instantiable if they exist
	elif typeof(ability_resource_script) == TYPE_STRING and ClassDB.class_exists(ability_resource_script): # Handle class_name string
		# We'll use ClassDB.instantiate later if it's a string
		actual_ability_script_ref = ability_resource_script
		print("Note: Using ClassDB.instantiate for ability resource type '%s'." % actual_ability_script_ref)
	else:
		ErrorUtility.log_error("Invalid ability_resource_script provided. Expected valid Script, GDScript class reference, or registered ClassName string. Got: %s" % typeof(ability_resource_script))
		return

	# --- Read the main monster JSON file ---
	if not FileAccess.file_exists(monster_json_path):
		ErrorUtility.log_error("Monster JSON file not found: %s" % monster_json_path)
		return

	var content: String = FileAccess.get_file_as_string(monster_json_path)
	var file_err = FileAccess.get_open_error()
	if file_err != Error.OK:
		ErrorUtility.log_error("Failed to read monster JSON file '%s'. Error code: %s" % [monster_json_path, file_err])
		return

	# --- Parse the main JSON ---
	var json_parser := JSON.new()
	var parse_err_code = json_parser.parse(content)
	if parse_err_code != Error.OK:
		var err_line = json_parser.get_error_line()
		var err_msg = json_parser.get_error_message()
		ErrorUtility.log_error("JSON Parse Error in file '%s': %s (Line: %d). Error Code: %d" % [monster_json_path, err_msg, err_line, parse_err_code])
		return

	var parse_result: Variant = json_parser.get_data()
	var monster_array: Array = []

	# --- Extract the array of monster definitions ---
	if typeof(parse_result) == TYPE_DICTIONARY and parse_result.has("monsters"):
		if typeof(parse_result["monsters"]) == TYPE_ARRAY:
			monster_array = parse_result["monsters"]
		else:
			ErrorUtility.log_error("Expected an Array for 'monsters' key in '%s'." % monster_json_path)
			return
	elif typeof(parse_result) == TYPE_ARRAY:
		monster_array = parse_result # If the root is already the array
	else:
		ErrorUtility.log_error("Unexpected JSON root type in '%s'. Expected Array or Dictionary with 'monsters' key." % monster_json_path)
		return

	if monster_array.is_empty():
		ErrorUtility.log_warning("No monster definitions found in '%s'. No abilities to extract." % monster_json_path)
		return

	# --- Process Each Monster Individually ---
	var total_success = 0
	var total_skipped = 0
	var total_failed = 0

	print("Processing %d monster definitions..." % monster_array.size())
	for monster_index in range(monster_array.size()):
		var monster_data = monster_array[monster_index]

		if typeof(monster_data) != TYPE_DICTIONARY:
			ErrorUtility.log_warning("Skipping non-dictionary item at index %d in monster array." % monster_index)
			continue

		# --- Get Monster Name for Folder ---
		var monster_name_var = monster_data.get("name")
		if typeof(monster_name_var) != TYPE_STRING or monster_name_var.strip_edges().is_empty():
			ErrorUtility.log_warning("Skipping monster definition at index %d due to missing or invalid 'name'." % monster_index)
			continue # Skip this monster if it has no valid name

		var monster_name = monster_name_var.strip_edges()
		# Sanitize monster name for use as a folder name (lowercase, spaces to underscores, remove common invalid chars)
		# You might want a more robust sanitization function depending on possible names
		var monster_folder_name = monster_name.to_lower().replace(" ", "_").replace(":", "").replace("?", "").replace("/", "").replace("\\", "")

		print("\n[%d/%d] Processing Monster: '%s' (Folder: %s)" % [monster_index + 1, monster_array.size(), monster_name, monster_folder_name])

		# --- Define and Create Monster-Specific Output Directory ---
		var monster_ability_output_dir = base_ability_output_dir.path_join(monster_folder_name)
		var create_err := DirAccess.make_dir_recursive_absolute(monster_ability_output_dir)
		if create_err != Error.OK and create_err != Error.ERR_ALREADY_EXISTS:
			ErrorUtility.log_error("Failed to create directory '%s' for monster '%s'. Error: %s. Skipping abilities for this monster." % [monster_ability_output_dir, monster_name, create_err])
			continue # Skip processing abilities for this monster if folder fails

		# --- Process Abilities found under the mapped keys for THIS Monster ---
		for json_key in ability_key_map:
			var inferred_category = ability_key_map[json_key] # Get the category enum value

			if monster_data.has(json_key):
				var ability_list = monster_data[json_key]
				if typeof(ability_list) == TYPE_ARRAY:
					for ability_data in ability_list:
						if typeof(ability_data) != TYPE_DICTIONARY:
							ErrorUtility.log_warning("  Item under key '%s' in monster '%s' is not a Dictionary. Skipping." % [json_key, monster_name])
							total_failed += 1 # Count as failed
							continue

						var ability_name_var = ability_data.get("name")
						if typeof(ability_name_var) != TYPE_STRING or ability_name_var.strip_edges().is_empty():
							ErrorUtility.log_warning("  Found ability with missing/invalid name under key '%s' in monster '%s'." % [json_key, monster_name])
							total_failed += 1 # Count as failed
							continue

						var ability_name = ability_name_var.strip_edges()
						var ability_name_lower = ability_name.to_lower() # Use lowercase for filename consistency

						# --- Generate Final Output Path for this Ability ---
						# Ensure filename is also sanitized if needed, though less critical than folder names
						var ability_filename = ability_name_lower.replace(":", "").replace("?", "").replace("/", "").replace("\\", "") + ".tres"
						var output_file_path = monster_ability_output_dir.path_join(ability_filename)

						# --- Skip if this Specific Ability File Already Exists ---
						if FileAccess.file_exists(output_file_path):
							# print("  Skipping existing ability: %s" % output_file_path)
							total_skipped += 1
							continue

						# --- Optional Validation (if required keys/types provided) ---
						if not ability_required_keys.is_empty():
							# Assume ExternalUtility exists and is configured
							if not ExternalUtility.ensure_json_type_and_keys(ability_data, ability_required_keys, ability_required_types):
								ErrorUtility.log_error("  Ability data failed validation for '%s' in monster '%s'. Skipping." % [ability_name, monster_name])
								total_failed += 1
								continue

						# --- Instantiate ---
						var ability_instance: Resource = null
						var instantiation_failed = false
						if actual_ability_script_ref is Script or actual_ability_script_ref is GDScript:
							ability_instance = actual_ability_script_ref.new()
						elif typeof(actual_ability_script_ref) == TYPE_STRING: # Assumed to be ClassName string
							ability_instance = ClassDB.instantiate(actual_ability_script_ref)
							if ability_instance == null: # Check if instantiation failed
								ErrorUtility.log_error("  Failed to instantiate ability '%s' using ClassDB for type '%s'." % [ability_name, actual_ability_script_ref])
								instantiation_failed = true
						else:
							ErrorUtility.log_error("  Internal Error: Invalid actual_ability_script_ref type: %s" % typeof(actual_ability_script_ref))
							instantiation_failed = true

						if instantiation_failed or not ability_instance is Resource: # Check type just in case
							# Error already logged or will be if null
							if not instantiation_failed: ErrorUtility.log_error("  Instantiated object for ability '%s' is not a Resource." % ability_name)
							total_failed += 1
							continue

						# --- Initialize ---
						# Check if the instance *actually* has the method (important if using ClassDB)
						if not ability_instance.has_method("initialize_from_dict"):
							ErrorUtility.log_error("  MonsterAbilityResource script/class MUST have 'initialize_from_dict'. Cannot process '%s'." % ability_name)
							total_failed += 1
							continue # Skip this ability

						# Call the initializer method, passing BOTH data and category
						# We assume the instance is the correct type due to the check above, but cast for clarity.
						# Use call() for safety if type isn't guaranteed (e.g., with ClassDB)
						ability_instance.call("initialize_from_dict", ability_data, inferred_category)
						# Alternative if type is guaranteed:
						# (ability_instance as MonsterAbilityResource).initialize_from_dict(ability_data, inferred_category)


						# --- Ensure script is set (mainly needed if using ClassDB/instantiate) ---
						# Check if it's a Script object before accessing resource_path
						var required_script : Script = null
						if actual_ability_script_ref is Script:
							required_script = actual_ability_script_ref

						if not ability_instance.get_script() and required_script != null and required_script.has_source_code():
							print("  Setting script resource for instance of '%s'" % ability_name)
							ability_instance.set_script(required_script)


						# --- Save Resource ---
						print("    Creating: %s" % output_file_path)
						var save_err = ResourceSaver.save(ability_instance, output_file_path)

						if save_err == Error.OK:
							total_success += 1
						else:
							ErrorUtility.log_error("    Failed to save ability resource '%s' to '%s'. Error code: %s" % [ability_name, output_file_path, save_err])
							total_failed += 1

				elif ability_list != null: # Allow null, but warn if it's not an array or null
					ErrorUtility.log_warning("  Expected Array or null for key '%s' in monster '%s', but got %s." % [json_key, monster_name, typeof(ability_list)])

	# --- Final Summary ---
	print("\n--------------------------------------------------")
	print("Ability Resource Creation Summary (Per Monster Folders):")
	print("  Created: %d" % total_success)
	print("  Skipped (Already Exist): %d" % total_skipped)
	print("  Failed:  %d" % total_failed)
	print("--- Finished Ability Resource Creation ---")

func _process_definition_array(json_definitions: Array, output_dir_path: String, required_keys: Array, required_types: Array, resource_type: Variant,
								parser_method_name: String, parser_method_args: Array, custom_prefix: bool = true, source_path_for_log: String = "Direct Array") -> void:

	# --- Copied/Adapted logic from process_json_definitions ---
	var actual_script: Script = null
	if resource_type is Script:
		actual_script = resource_type
	elif resource_type is GDScript: # Allow class references
		if ClassDB.class_exists(str(resource_type)): # Check if it's a registered name
			if not actual_script:
				 # Fallback: Assume it's usable via .new() directly if script isn't found
				actual_script = resource_type # Keep the class reference
		else:
			ErrorUtility.log_error("Invalid GDScript class reference provided for '%s'. Class not found: %s" % [source_path_for_log, resource_type])
			return
	else:
		ErrorUtility.log_error("Invalid resource_type provided for '%s'. Expected a loaded Script or GDScript class reference. Got type: %s" % [source_path_for_log, typeof(resource_type)])
		return

	# Check instantiation possibility (slightly different check for class references)
	var can_instantiate = false
	if actual_script is Script:
		can_instantiate = actual_script.can_instantiate()
	elif actual_script is GDScript:
		can_instantiate = true # Assume GDScript class references can be instantiated
	if not can_instantiate:
		ErrorUtility.log_error("Provided resource_type Script/Class is invalid or cannot be instantiated for '%s'." % source_path_for_log)
		return

	# Determine prefix (Handle case where actual_script might be GDScript class ref without path)
	var name_prefix: String = ""
	if is_instance_valid(actual_script) and actual_script is Script and not actual_script.resource_path.is_empty() and custom_prefix:
		var script_filename = actual_script.resource_path.get_file().get_basename()
		if not script_filename.is_empty():
			name_prefix = script_filename[0].to_lower()

	if name_prefix.is_empty() and custom_prefix:
		ErrorUtility.log_warning("Could not determine resource script filename to derive 'name' variable prefix for '%s'. Name mapping might fail." % source_path_for_log)


	if json_definitions.is_empty():
		ErrorUtility.log_warning("No valid JSON definitions provided to process for '%s'" % source_path_for_log)
		return

	# Ensure output directory exists
	var create_err := DirAccess.make_dir_recursive_absolute(output_dir_path)
	if create_err != Error.OK and create_err != Error.ERR_ALREADY_EXISTS:
		ErrorUtility.log_error("Failed to create output directory: %s. Error code: %s" % [output_dir_path, create_err])
		return

	var count_success : int = 0
	var count_skipped : int = 0
	var count_failed : int = 0
	var skipped_items := []
	var failed_items := []

	for index in range(json_definitions.size()):
		var json_data = json_definitions[index]
		var item_name_for_log = "Index %d" % index

		if typeof(json_data) != TYPE_DICTIONARY:
			# ... (logging for non-dictionary items) ...
			skipped_items.append({"id": item_name_for_log, "reason": "Not a Dictionary"})
			count_skipped += 1
			continue

		var base_name_var: Variant = json_data.get("name", null)
		var base_name : String = ""

		if base_name_var == null or typeof(base_name_var) != TYPE_STRING:
			# ... (logging for missing/invalid name key) ...
			var reason = "Missing/Invalid 'name' key"
			skipped_items.append({"id": item_name_for_log, "reason": reason, "data_snippet": str(json_data).substr(0,50)})
			count_skipped += 1
			continue
		else:
			base_name = base_name_var.strip_edges().to_lower()
			if not base_name.is_empty():
				item_name_for_log = "'%s'" % base_name

		if base_name.is_empty():
			# ... (logging for empty name after processing) ...
			var reason = "'name' is empty after processing"
			skipped_items.append({"id": item_name_for_log, "reason": reason, "data_snippet": str(json_data).substr(0,50)})
			count_skipped += 1
			continue

		var output_file_path: String = output_dir_path.path_join(base_name + ".tres")

		if FileAccess.file_exists(output_file_path):
			# ... (logging for existing file) ...
			skipped_items.append({"id": item_name_for_log, "reason": "File already exists", "path": output_file_path})
			count_skipped += 1
			continue

		# Use parse_resource directly, assuming it's in the same script
		var resource_instance: Resource = parse_resource(json_data, actual_script, required_keys, required_types, parser_method_name, parser_method_args, name_prefix)

		if resource_instance == null:
			var reason = "Parse Failed"
			failed_items.append({"id": item_name_for_log, "reason": reason, "path": output_file_path})
			count_failed += 1
		else:
			# Save the successfully parsed resource
			var save_err := ResourceSaver.save(resource_instance, output_file_path)
			if save_err == Error.OK:
				count_success += 1
			else:
				ErrorUtility.log_error("Failed to save resource '%s' to '%s'. Error code: %s" % [item_name_for_log, output_file_path, save_err])
				var reason = "Save Failed (Error: %s)" % save_err
				failed_items.append({"id": item_name_for_log, "reason": reason, "path": output_file_path})
				count_failed += 1


	# --- Final Summary Logging ---
	print("--------------------------------------------------")
	print("Finished processing definition array from '%s'." % source_path_for_log)
	print("  Created: %d" % count_success)
	print("  Failed:  %d" % count_failed)
	print("  Skipped: %d" % count_skipped)
	print("--------------------------------------------------")

		# --- Detailed Failed Items Log ---
	if not failed_items.is_empty():
		printerr("-- Failed Items (%d) --" % failed_items.size()) # Use printerr for errors
		for item in failed_items:
			printerr("  - Item: %s, Reason: %s (Path Attempted: %s)" % [
					item.get("id", "N/A"),
					item.get("reason", "Unknown"),
					item.get("path", "N/A")
				])
		printerr("--------------------------------------------------") # Separate error section

func _load_json_get_array(file_path: String, array_key: String) -> Array:
	if not FileAccess.file_exists(file_path):
		ErrorUtility.log_error("JSON file not found: %s" % file_path)
		return []

	var content: String = FileAccess.get_file_as_string(file_path)
	var file_err = FileAccess.get_open_error()
	if file_err != Error.OK:
		ErrorUtility.log_error("Failed to read JSON file '%s'. Error code: %s" % [file_path, file_err])
		return []

	var json_parser := JSON.new()
	var parse_err_code = json_parser.parse(content)
	if parse_err_code != Error.OK:
		var err_line = json_parser.get_error_line()
		var err_msg = json_parser.get_error_message()
		ErrorUtility.log_error("JSON Parse Error in file '%s': %s (Line: %d). Error Code: %d" % [file_path, err_msg, err_line, parse_err_code])
		return []

	var parse_result: Variant = json_parser.get_data()

	if typeof(parse_result) == TYPE_DICTIONARY and parse_result.has(array_key):
		if typeof(parse_result[array_key]) == TYPE_ARRAY:
			return parse_result[array_key]
		else:
			ErrorUtility.log_error("Expected an Array for '%s' key in '%s'." % [array_key, file_path])
			return []
	else:
		ErrorUtility.log_error("JSON root in '%s' is not a Dictionary or lacks key '%s'." % [file_path, array_key])
		return []

# Place this function within your main resource creation script.
# Assumes MonsterAttackResource, ErrorUtility, ExternalUtility, and GameConst are accessible.

# Scans a monster JSON, creates a sub-folder for each monster in the output directory,
# and saves that monster's attacks as .tres resources within its specific folder.
func create_attack_resources_from_monster_json(
		monster_json_path: String,          # Path to the main monster JSON (e.g., "user://.../monsters.json")
		base_attack_output_dir: String,     # The main output dir for attacks (e.g., "res://Content/Monsters/Attacks/")
		attack_resource_script: Variant,    # The Script or ClassName for attacks (e.g., MonsterAttackResource class ref)
		attack_json_key: String = "attacks",# The key in monster JSON holding the attack array
		attack_required_keys: Array = [],   # Optional: Required keys within an attack's JSON definition
		attack_required_types: Array = []   # Optional: Required types for those keys
	) -> void:

	print("\n--- Starting Attack Resource Creation (Per Monster Folders) ---")
	print("Scanning Monster JSON: %s" % monster_json_path)
	print("Base Output Directory for Attacks: %s" % base_attack_output_dir)
	print("Attack JSON Key: '%s'" % attack_json_key)

	# --- Validate Attack Resource Type ---
	var actual_attack_script_ref: Variant = null
	if attack_resource_script is Script:
		actual_attack_script_ref = attack_resource_script
		if not actual_attack_script_ref.can_instantiate():
			ErrorUtility.log_error("Provided attack_resource_script Script cannot be instantiated: %s" % actual_attack_script_ref.resource_path)
			return
	elif attack_resource_script is GDScript: # Handle direct class reference
		actual_attack_script_ref = attack_resource_script
	elif typeof(attack_resource_script) == TYPE_STRING and ClassDB.class_exists(attack_resource_script): # Handle class_name string
		actual_attack_script_ref = attack_resource_script
		print("Note: Using ClassDB.instantiate for attack resource type '%s'." % actual_attack_script_ref)
	else:
		ErrorUtility.log_error("Invalid attack_resource_script provided. Expected valid Script, GDScript class reference, or registered ClassName string. Got: %s" % typeof(attack_resource_script))
		return

	# --- Read the main monster JSON file ---
	if not FileAccess.file_exists(monster_json_path):
		ErrorUtility.log_error("Monster JSON file not found: %s" % monster_json_path)
		return

	var content: String = FileAccess.get_file_as_string(monster_json_path)
	var file_err = FileAccess.get_open_error()
	if file_err != Error.OK:
		ErrorUtility.log_error("Failed to read monster JSON file '%s'. Error code: %s" % [monster_json_path, file_err])
		return

	# --- Parse the main JSON ---
	var json_parser := JSON.new()
	var parse_err_code = json_parser.parse(content)
	if parse_err_code != Error.OK:
		var err_line = json_parser.get_error_line()
		var err_msg = json_parser.get_error_message()
		ErrorUtility.log_error("JSON Parse Error in file '%s': %s (Line: %d). Error Code: %d" % [monster_json_path, err_msg, err_line, parse_err_code])
		return

	var parse_result: Variant = json_parser.get_data()
	var monster_array: Array = []

	# --- Extract the array of monster definitions ---
	if typeof(parse_result) == TYPE_DICTIONARY and parse_result.has("monsters"):
		if typeof(parse_result["monsters"]) == TYPE_ARRAY:
			monster_array = parse_result["monsters"]
		else:
			ErrorUtility.log_error("Expected an Array for 'monsters' key in '%s'." % monster_json_path)
			return
	elif typeof(parse_result) == TYPE_ARRAY:
		monster_array = parse_result # If the root is already the array
	else:
		ErrorUtility.log_error("Unexpected JSON root type in '%s'. Expected Array or Dictionary with 'monsters' key." % monster_json_path)
		return

	if monster_array.is_empty():
		ErrorUtility.log_warning("No monster definitions found in '%s'. No attacks to extract." % monster_json_path)
		return

	# --- Process Each Monster Individually ---
	var total_success = 0
	var total_skipped = 0
	var total_failed = 0

	print("Processing %d monster definitions for attacks..." % monster_array.size())
	for monster_index in range(monster_array.size()):
		var monster_data = monster_array[monster_index]

		if typeof(monster_data) != TYPE_DICTIONARY:
			ErrorUtility.log_warning("Skipping non-dictionary item at index %d in monster array." % monster_index)
			continue

		# --- Get Monster Name for Folder ---
		var monster_name_var = monster_data.get("name")
		if typeof(monster_name_var) != TYPE_STRING or monster_name_var.strip_edges().is_empty():
			ErrorUtility.log_warning("Skipping monster definition at index %d due to missing or invalid 'name'." % monster_index)
			continue # Skip this monster if it has no valid name

		var monster_name = monster_name_var.strip_edges()
		# Sanitize monster name for use as a folder name
		var monster_folder_name = monster_name.to_lower().replace(" ", "_").replace(":", "").replace("?", "").replace("/", "").replace("\\", "")

		print("\n[%d/%d] Processing Monster: '%s' (Attack Folder: %s)" % [monster_index + 1, monster_array.size(), monster_name, monster_folder_name])

		# --- Define and Create Monster-Specific Attack Output Directory ---
		var monster_attack_output_dir = base_attack_output_dir.path_join(monster_folder_name)
		var create_err := DirAccess.make_dir_recursive_absolute(monster_attack_output_dir)
		if create_err != Error.OK and create_err != Error.ERR_ALREADY_EXISTS:
			ErrorUtility.log_error("Failed to create directory '%s' for monster '%s' attacks. Error: %s. Skipping attacks for this monster." % [monster_attack_output_dir, monster_name, create_err])
			continue # Skip processing attacks for this monster if folder fails

		# --- Process Attacks found under the specified key for THIS Monster ---
		if monster_data.has(attack_json_key):
			var attack_list = monster_data[attack_json_key]
			if typeof(attack_list) == TYPE_ARRAY:
				for attack_data in attack_list:
					if typeof(attack_data) != TYPE_DICTIONARY:
						ErrorUtility.log_warning("  Item under key '%s' in monster '%s' is not a Dictionary. Skipping." % [attack_json_key, monster_name])
						total_failed += 1 # Count as failed
						continue

					var attack_name_var = attack_data.get("name")
					if typeof(attack_name_var) != TYPE_STRING or attack_name_var.strip_edges().is_empty():
						ErrorUtility.log_warning("  Found attack with missing/invalid name under key '%s' in monster '%s'." % [attack_json_key, monster_name])
						total_failed += 1 # Count as failed
						continue

					var attack_name = attack_name_var.strip_edges()
					var attack_name_lower = attack_name.to_lower() # Use lowercase for filename consistency

					# --- Generate Final Output Path for this Attack ---
					# Sanitize filename just in case
					var attack_filename = attack_name_lower.replace(":", "").replace("?", "").replace("/", "").replace("\\", "") + ".tres"
					var output_file_path = monster_attack_output_dir.path_join(attack_filename)

					# --- Skip if this Specific Attack File Already Exists ---
					if FileAccess.file_exists(output_file_path):
						# print("  Skipping existing attack: %s" % output_file_path)
						total_skipped += 1
						continue

					# --- Optional Validation (if required keys/types provided) ---
					if not attack_required_keys.is_empty():
						# Assume ExternalUtility exists and is configured
						if not ExternalUtility.ensure_json_type_and_keys(attack_data, attack_required_keys, attack_required_types):
							ErrorUtility.log_error("  Attack data failed validation for '%s' in monster '%s'. Skipping." % [attack_name, monster_name])
							total_failed += 1
							continue

					# --- Instantiate ---
					var attack_instance: Resource = null
					var instantiation_failed = false
					if actual_attack_script_ref is Script or actual_attack_script_ref is GDScript:
						attack_instance = actual_attack_script_ref.new()
					elif typeof(actual_attack_script_ref) == TYPE_STRING: # Assumed to be ClassName string
						attack_instance = ClassDB.instantiate(actual_attack_script_ref)
						if attack_instance == null: # Check if instantiation failed
							ErrorUtility.log_error("  Failed to instantiate attack '%s' using ClassDB for type '%s'." % [attack_name, actual_attack_script_ref])
							instantiation_failed = true
					else:
						ErrorUtility.log_error("  Internal Error: Invalid actual_attack_script_ref type: %s" % typeof(actual_attack_script_ref))
						instantiation_failed = true

					if instantiation_failed or not attack_instance is Resource: # Check type just in case
						if not instantiation_failed: ErrorUtility.log_error("  Instantiated object for attack '%s' is not a Resource." % attack_name)
						total_failed += 1
						continue

					# --- Initialize ---
					# Check if the instance *actually* has the method (important if using ClassDB)
					if not attack_instance.has_method("initialize_from_dict"):
						ErrorUtility.log_error("  MonsterAttackResource script/class MUST have 'initialize_from_dict'. Cannot process '%s'." % attack_name)
						total_failed += 1
						continue # Skip this attack

					# Call the initializer method - it handles attack_bonus internally
					attack_instance.call("initialize_from_dict", attack_data)

					# --- Ensure script is set (mainly needed if using ClassDB/instantiate) ---
					var required_script : Script = null
					if actual_attack_script_ref is Script:
						required_script = actual_attack_script_ref

					if not attack_instance.get_script() and required_script != null and required_script.has_source_code():
						print("  Setting script resource for instance of '%s'" % attack_name)
						attack_instance.set_script(required_script)

					# --- Save Resource ---
					print("    Creating: %s" % output_file_path)
					var save_err = ResourceSaver.save(attack_instance, output_file_path)

					if save_err == Error.OK:
						total_success += 1
					else:
						ErrorUtility.log_error("    Failed to save attack resource '%s' to '%s'. Error code: %s" % [attack_name, output_file_path, save_err])
						total_failed += 1

			elif attack_list != null: # Allow null, but warn if it's not an array or null
				ErrorUtility.log_warning("  Expected Array or null for key '%s' in monster '%s', but got %s." % [attack_json_key, monster_name, typeof(attack_list)])

	# --- Final Summary ---
	print("\n--------------------------------------------------")
	print("Attack Resource Creation Summary (Per Monster Folders):")
	print("  Created: %d" % total_success)
	print("  Skipped (Already Exist): %d" % total_skipped)
	print("  Failed:  %d" % total_failed)
	print("--- Finished Attack Resource Creation ---")

func parse_armor_data(json_data: Dictionary) -> Dictionary:
	# print("-----> Parsing armor data for: ", json_data.get("name", "N/A"))
	var prepared_data: Dictionary = {}

	# --- Base Item Properties ---
	prepared_data["name"] = json_data.get("name", "Unnamed Armor")
	prepared_data["description"] = json_data.get("Description", "No description available.")
	prepared_data["level"] = json_data.get("level", 0)
	prepared_data["rarity"] = json_data.get("rarity", "Common") # Assuming ItemResource uses 'rarity'
	# Price requires cleaning "gp", "sp" etc. (Implement Helper)
	prepared_data["price"] = Helper.parse_price_string(json_data.get("Price", "0 gp"))
	prepared_data["weight"] = json_data.get("Weight", 0.0) # Assuming ItemResource uses 'weight'
	# Traits need processing (Implement Helper or handle in ItemResource init)
	prepared_data["traits"] = json_data.get("Armor Traits", [])

	# --- Armor Specific Properties ---
	prepared_data["ac_bonus"] = json_data.get("AC_Bonus", 0)
	prepared_data["defense"] = json_data.get("Defense", "Unknown Armor Type")
	prepared_data["armor_group"] = json_data.get("Group", "Unknown Group")
	prepared_data["agi_cap"] = json_data.get("Agi_Cap", 99)
	prepared_data["might"] = json_data.get("Might", 0)

	# --- Penalties ---
	prepared_data["check_penalty"] = json_data.get("Check Penalty", 0)
	prepared_data["speed_penalty"] = json_data.get("Speed Penalty", 0)

	print("-----> Prepared armor data: ", prepared_data)
	return prepared_data

# Parser for individual weapon JSON objects
func parse_weapon_data(json_data: Dictionary) -> Dictionary:
	# print("-----> Parsing weapon data for: ", json_data.get("name", "N/A"))
	var prepared_data: Dictionary = {}

	var default_damage_array : Array = [["1d4", "BLUDGEONING"]] # Default damage array
	var default_damage_category: String = "Simple MELEE" # Default damage category
	var damage_string: String = json_data.get("Damage", default_damage_array)[0][0] # Assuming Damage is a list
	var damage_type: String = json_data.get("Damage", default_damage_array)[0][1] # Assuming Damage is a list
	var prepared_category_and_group: Array = _split_string(json_data.get("type", default_damage_category), " ")

	var weapon_prof_group: String = prepared_category_and_group[0] # First part is the group
	var damage_category: String = "MELEE"
	if prepared_category_and_group.size() > 1:
		damage_category = prepared_category_and_group[1] # Second part is the category
	else:
		damage_category = default_damage_category[1] # Fallback if no category found

	# --- Base Item Properties ---
	prepared_data["name"] = json_data.get("name", "Unnamed Weapon")
	prepared_data["description"] = json_data.get("Description", "No description available.")
	prepared_data["level"] = json_data.get("level", 0)
	prepared_data["rarity"] = json_data.get("rarity", "Common") # Assuming ItemResource uses 'rarity'
	prepared_data["price"] = Helper.parse_price_string(json_data.get("Price", "0 gp"))
	prepared_data["weight"] = json_data.get("Weight", 0.0)
	prepared_data["traits"] = json_data.get("Weapon Traits", []) # Assuming "Traits" key

	# --- Weapon Specific Properties (matching Resource variables) ---
	prepared_data["damage_string"] = damage_string # Use direct key if JSON matches
	prepared_data["damage bonus"] = json_data.get("damage_bonus", 0)
	prepared_data["hand requirement"] = json_data.get("Hands", 1)
	prepared_data["range"] = json_data.get("range", 5)

	# --- Properties needing conversion (handled in initialize_from_dict) ---
	# Pass strings directly, conversion happens in the resource script
	prepared_data["damage type"] = damage_type
	prepared_data["weapon group"] = json_data.get("Group", "BRAWLING")
	prepared_data["damage category"] = damage_category
	prepared_data["weapon proficiency category"] = weapon_prof_group

	print("-----> Prepared weapon data: ", prepared_data)
	return prepared_data

func _split_string(input_string: String, delimiter: String) -> Array:
	return input_string.split(delimiter)
