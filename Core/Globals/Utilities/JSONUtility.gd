# JSON Utility #
extends Node

# ===================== JSON UTILITY FUNCTIONS =====================

# Load all JSON files in a directory, make them lowercase and call a method with the parsed JSON
func get_jsons_from_dir(dir_path: String) -> Array:
	DirUtility.ensure_directory(dir_path)
	var json_array = []

	var dir = DirAccess.open(dir_path)

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		json_array.append(proccess_json_file(file_name, dir_path))
		file_name = dir.get_next()

	dir.list_dir_end()
	return json_array

# Process a JSON file
func proccess_json_file(file_name: String, dir_path: String) -> Dictionary:
	if not file_name.ends_with(".json"):
		ErrorUtility.log_info("File is not a JSON file: " + file_name)
		return {}

	var file_path = dir_path + file_name

	var file = FileAccess.open(file_path, FileAccess.READ)

	if file:
		var json_str = file.get_as_text().to_lower()
		var parsed_json = JSON.parse_string(json_str)

		if parsed_json:
			return parsed_json
		else:
			ErrorUtility.log_error("Error parsing JSON file " + file_path)
			
		file.close()
	else:
		ErrorUtility.log_error("Error opening file " + file_path)
		return {}
	return {}

# Check if json has required keys
func ensure_json_keys(parsed_json: Dictionary, required_keys: Array) -> bool:
	for key in required_keys:
		if !parsed_json.has(key):
			ErrorUtility.log_error("Key " + key + " not found in JSON")
			return false
	return true

# Check if json has required types
func ensure_json_types(parsed_json: Dictionary, required_types: Array, required_keys: Array) -> bool:
	for key in parsed_json.keys():
		if required_keys.has(key):
			var key_index = required_keys.find(key)
			if typeof(parsed_json[key]) != required_types[key_index]:
				ErrorUtility.log_error("Key " + key + " is not of type " + str(required_types[key_index]) + ", it is " + str(typeof(parsed_json[key])))
				return false
	return true

# Check if json has required keys and types
func ensure_json_type_and_keys(parsed_json: Dictionary, required_keys: Array, required_types: Array) -> bool:
	if !ensure_json_keys(parsed_json, required_keys):
		return false
	if !ensure_json_types(parsed_json, required_types, required_keys):
		return false
	return true

# Sort json values by key order
func sort_json_dictionary_values(parsed_json: Dictionary, sort_structure: Array) -> Array:
	var sorted_values = []
	for key in sort_structure:
		if parsed_json.has(key):
			sorted_values.append(parsed_json[key])
		else:
			ErrorUtility.log_error("Key " + key + " not found in JSON")
	return sorted_values

# Replace a value in a JSON
func replace_json_value(parsed_json: Dictionary, key: String, value: Variant) -> Dictionary:
	if !parsed_json.has(key):
		ErrorUtility.log_error("Key " + key + " not found in JSON")
		return parsed_json
	parsed_json[key] = value
	return parsed_json

func get_values_in_json(parsed_json: Dictionary, keys: Array) -> Array:
	var values = []
	for key in keys:
		if parsed_json.has(key):
			values.append(parsed_json[key])
		else:
			ErrorUtility.log_error("Key " + key + " not found in JSON")
	return values