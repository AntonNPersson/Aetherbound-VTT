extends Node
# ===================== UTILITY SINGLETON ===============================
# A singleton that contains utility functions for the game
# =======================================================================

# ===================== DIRECTORY UTILITY FUNCTIONS =====================
# Get the last directory in a path
func get_last_dir(dir: String) -> String:
	var words = dir.split("/", false)
	return words[words.size() - 1]

# Ensure directory exists, make it if it doesn't
func ensure_directory(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir:
		ErrorUtility.log_warning("Directory does not exist, creating: " + path)
		DirAccess.make_dir_recursive_absolute(path)

func check_if_directory_exists(path: String) -> bool:
	var dir = DirAccess.open(path)
	if not dir:
		return false
	return true

# ===================== FILE UTILITY FUNCTIONS =====================

# Create a .tres file from a resource
func create_tres_file(file_path: String, resource: Resource) -> void:
	var error = ResourceSaver.save(resource, file_path)
	if error != OK:
		push_error("Error saving resource to file " + file_path + " with error code " + str(error))

# check if file exists
func check_if_file_exists(file_path: String) -> bool:
	return FileAccess.file_exists(file_path)

func get_reference_to_file(file_path: String) -> Resource:
	if not check_if_file_exists(file_path):
		push_error("File does not exist: " + file_path)
		return null
	return ResourceLoader.load(file_path)

func get_file_by_name(file_name: String, dir_path: String) -> Resource:
	var file_path = dir_path + file_name
	return get_reference_to_file(file_path)

func get_external_texture(file_path: String) -> Texture2D:
	var image = Image.new()
	image.load(file_path)
	
	var image_texture = ImageTexture.new()
	image_texture.set_image(image)
	return image_texture

func get_external_texture_from_data(data: Variant) -> Texture2D:
	var image_raw = Marshalls.base64_to_raw(data.image)
	var image = Image.new()
	image.load_jpg_from_buffer(image_raw)
	var texture = ImageTexture.create_from_image(image)
	return texture

# ===================== JSON UTILITY FUNCTIONS =====================

# Load all JSON files in a directory, make them lowercase and call a method with the parsed JSON
func get_jsons_from_dir(dir_path: String) -> Array:
	ensure_directory(dir_path)
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