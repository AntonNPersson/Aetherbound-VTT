# gdscript-lint: disable=unused-variable, class-name-casing - Adjust as needed

extends Node

# Assume ResourceConst, TraitResource, PerkResource, etc. are loaded scripts or class_names
# Assume ExternalUtility and ErrorUtility exist and are updated for Godot 4 APIs (using % format strings).

# ===================== RESOURCE CORE FUNCTIONS =====================
func _ready():
	# Example using class_name: TraitResource is the direct class reference
	process_json_definitions("user://Addons/Base/Traits/Traits.json", "res://Content/traits/",
							 ResourceConst.TRAIT_JSON_KEYS, ResourceConst.TRAIT_JSON_TYPES, TraitResource, "", [])
	print("Trait resources created successfully.")

	# Example using load():
	# var perk_script = load("res://path/to/PerkResource.gd")
	# process_json_definitions("user://Addons/Base/Perks/", "res://Content/Perks/",
	#						 ResourceConst.PERK_JSON_KEYS, ResourceConst.PERK_JSON_TYPES, perk_script, "parse", ["traits"])

	# create_resources()


func create_resources():
	# --- Ensure you pass the correct Script object or ClassName reference ---
	process_json_definitions("user://Addons/Base/Traits/traits.json", "res://Content/Traits/",
							 ResourceConst.TRAIT_JSON_KEYS, ResourceConst.TRAIT_JSON_TYPES, TraitResource, "", [])

	# Example using load():
	var perk_script = load("res://path/to/PerkResource.gd") # Make sure path is correct
	process_json_definitions("user://Addons/Base/Perks/", "res://Content/Perks/",
							 ResourceConst.PERK_JSON_KEYS, ResourceConst.PERK_JSON_TYPES, perk_script, "parse", ["traits"])

	# ... rest of your calls ...


# ===================== JSON PARSING FUNCTIONS =====================

# Process JSON definitions.
# Args: ...
#		resource_type: Variant - Should be a loaded Script object or a direct GDScript class reference (e.g., MyResource)
#		...
# Inside your script...

# ===================== JSON PARSING FUNCTIONS =====================

# Process JSON definitions. Includes detailed logging for skips/failures.
func process_json_definitions(input_path: String, output_dir_path: String, required_keys: Array, required_types: Array, resource_type: Variant,
								parser_method_name: String, parser_method_args: Array) -> void:

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
		if not script_filename.is_empty():
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

		if typeof(parse_result) == TYPE_ARRAY:
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

	# Pass the name_prefix down
	var resource_instance: Resource = parse_resource(json_data, resource_script, required_keys, required_types, parser_method_name, parser_method_args, name_prefix) # ADDED name_prefix

	if resource_instance == null:
		# Error logged in parse_resource
		return false

	var save_err := ResourceSaver.save(resource_instance, output_file_path)
	if save_err != Error.OK:
		# Use % formatting
		ErrorUtility.log_error("Failed to save resource to '%s'. Error code: %s" % [output_file_path, save_err])
		return false

	# print("Successfully created: " + output_file_path) # Optional success message
	return true

# (parse_resource remains the same, using % formatting)

func parse_resource(json_data: Dictionary, resource_script: Script, required_keys: Array, required_types: Array, parser_method_name: String, parser_method_args: Array, name_prefix: String) -> Resource: # ADDED name_prefix arg

	# --- 1. Validation ---
	# Assuming ExternalUtility.ensure_json_type_and_keys is compatible
	if not ExternalUtility.ensure_json_type_and_keys(json_data, required_keys, required_types):
		# Use % formatting and str() for dictionary snippet
		ErrorUtility.log_error("JSON data failed validation (keys/types). Data: %s..." % str(json_data).substr(0, 200))
		return null

	# --- 2. Pre-processing ---
	var processed_json := json_data.duplicate(true)
	if not parser_method_name.is_empty():
		var method := StringName(parser_method_name)
		if has_method(method):
			var args = [processed_json] + parser_method_args
			var result: Variant = callv(method, args)
			if typeof(result) == TYPE_DICTIONARY:
				processed_json = result
			else:
				# Use % formatting
				ErrorUtility.log_error("Parser method '%s' did not return a Dictionary. Returned type: %s" % [parser_method_name, typeof(result)])
				return null
		else:
			# Use % formatting
			ErrorUtility.log_error("Parser method '%s' not found." % parser_method_name)
			return null

	# --- 3. Resource Instantiation & Initialization ---
	# Check if script is valid *before* calling new()
	if not is_instance_valid(resource_script) or not resource_script.can_instantiate():
		# Use % formatting
		ErrorUtility.log_error("Cannot instantiate invalid or non-instantiable script: %s" % resource_script.resource_path if resource_script else "null")
		return null

	var resource_instance: Variant = resource_script.new()

	if not resource_instance is Resource:
		 # Use % formatting
		ErrorUtility.log_error("Failed to instantiate Resource from script: %s" % resource_script.resource_path)
		 # If new() failed, resource_instance might be null or some error object
		return null

	# --- Set properties using set() ---
	for key in processed_json:
		var value = processed_json[key]
		var target_property = key # Default

		# --- !!! DYNAMIC KEY MAPPING LOGIC (uses passed prefix) !!! ---
		if key == "name" and not name_prefix.is_empty():
			target_property = name_prefix + "_name" # e.g., t_name, p_name
		# ----------------------------------------------------------

		# Debug print (optional)
		# print("Mapping JSON key '%s' to property '%s'" % [key, target_property])

		resource_instance.set(target_property, value) # Godot errors if property 'target_property' doesn't exist

	# --- 4. Post-Initialization (Optional) ---

	# --- 5. Return ---
	return resource_instance