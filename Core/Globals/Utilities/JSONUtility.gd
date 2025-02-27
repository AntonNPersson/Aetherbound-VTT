# JSON Utility #
extends Node

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
func check_json_keys(parsed_json: Dictionary, required_keys: Array) -> bool:
	for key in required_keys:
		if not parsed_json.has(key):
			ErrorUtility.log_error("Missing key " + key + " in JSON file")
			return false
	return true