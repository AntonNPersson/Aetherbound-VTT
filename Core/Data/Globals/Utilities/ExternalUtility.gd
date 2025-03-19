extends Node
# ===================== UTILITY SINGLETON ===============================
# A singleton that contains utility functions for the game
# =======================================================================
var map_chunks = []

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

# Check if directory exists
# Args: String - The directory path
# Returns: bool - If the directory exists
func check_if_directory_exists(path: String) -> bool:
	var dir = DirAccess.open(path)
	if not dir:
		return false
	return true

# ===================== FILE UTILITY FUNCTIONS =====================

# Create a .tres file from a resource
# Args: String - The file path, Resource - The resource to save
# Returns: None
func create_tres_file(file_path: String, resource: Resource) -> void:
	var error = ResourceSaver.save(resource, file_path)
	if error != OK:
		push_error("Error saving resource to file " + file_path + " with error code " + str(error))

# check if file exists
# Args: String - The file path
# Returns: bool - If the file exists
func check_if_file_exists(file_path: String) -> bool:
	return FileAccess.file_exists(file_path)

# Get a reference to a file
# Args: String - The file path
# Returns: Resource - The reference to the file
func get_reference_to_file(file_path: String) -> Resource:
	if not check_if_file_exists(file_path):
		push_error("File does not exist: " + file_path)
		return null
	return ResourceLoader.load(file_path)

# Get a file by name
# Args: String - The file name, String - The directory path
# Returns: Resource - The reference to the file
func get_file_by_name(file_name: String, dir_path: String) -> Resource:
	var file_path = dir_path + file_name
	return get_reference_to_file(file_path)

func get_file_name(file_path: String) -> String:
	var words = file_path.split("/", false)
	var word = words[words.size() - 1].split(".", false)
	return word[0]

func create_file(file_path: String, data: String) -> void:
	ensure_directory(file_path.get_base_dir())

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if !file:
		ErrorUtility.log_error("Error opening file " + file_path)
		return

	file.store_string(data)
	file.close()

# Get a texture from a file, this converts the image to a texture usable in Godot
# Args: String - The file path
# Returns: Texture2D - The texture
func get_external_texture(file_path: String) -> Texture2D:
	var image = get_external_image(file_path)
	
	var image_texture = ImageTexture.new()
	image_texture.set_image(image)
	return image_texture

# Get an image from a file
# Args: String - The file path
# Returns: Image - The image
func get_external_image(file_path: String) -> Image:
	var image = Image.new()
	var err = image.load(file_path)

	if err != OK:
		ErrorUtility.log_error("Error loading image: " + file_path)
		return image

	if !check_if_file_exists(file_path):
		ErrorUtility.log_error("File does not exist: " + file_path)
		return image

	return image

func get_external_texture_from_json(json_path: String) -> Texture2D:
	var json = get_json_file(json_path)
	var image_bytes = Marshalls.base64_to_raw(json["image"])
	var image = load_image_from_bytes(image_bytes)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func get_external_texture_from_dd2vtt(json_path: String) -> Texture2D:
	var json = process_dd2vtt_file(json_path)
	var image_bytes = Marshalls.base64_to_raw(json["image"])
	var image = load_image_from_bytes(image_bytes)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# Get a texture from a data object, will use later when vtt files are implemented
# Args: Variant - The data object
# Returns: Texture2D - The texture
func get_external_texture_from_data(data: Variant) -> Texture2D:
	var image_raw = Marshalls.base64_to_raw(data.image)
	var image = Image.new()
	image.load_jpg_from_buffer(image_raw)
	var texture = ImageTexture.create_from_image(image)
	return texture

# Convert an external image to bytes for more lightweight networking
# Args: String - The file path
# Returns: PackedByteArray - The image bytes
func convert_external_image_to_bytes(file_path: String) -> PackedByteArray:
	var image_bytes = get_external_image(file_path).save_jpg_to_buffer()

	return image_bytes

func convert_Base64_to_texture(base64: String) -> Texture2D:
	var image_bytes = Marshalls.base64_to_raw(base64)
	var image = load_image_from_bytes(image_bytes)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func break_bytes_into_chunks(bytes: PackedByteArray, chunk_size: int) -> Array:
	var chunks = []
	var chunk = []
	for i in range(bytes.size()):
		chunk.append(bytes[i])
		if chunk.size() == chunk_size:
			chunks.append(chunk)
			chunk = []
	if chunk.size() > 0:
		chunks.append(chunk)
	return chunks

func convert_jpg_to_base64(file_path: String) -> String:
	var image = get_external_image(file_path)
	var image_bytes = image.save_jpg_to_buffer()
	var image_base64 = Marshalls.raw_to_base64(image_bytes)
	return image_base64

# Load an image from bytes
# Args: PackedByteArray - The image bytes
# Returns: Image - The image
func load_image_from_bytes(image_bytes: PackedByteArray) -> Image:
	var image = Image.new()
	image.load_jpg_from_buffer(image_bytes)
	return image

# Load a texture from bytes, converts the image to a texture usable in Godot
# Args: PackedByteArray - The image bytes
# Returns: Texture2D - The texture
func load_texture_from_bytes(image_bytes: PackedByteArray) -> Texture2D:
	var image = load_image_from_bytes(image_bytes)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

# Get all files in a directory, useful for the sidebar to display all maps
# Args: String - The directory path
# Returns: Array - The files in the directory
func get_all_files_in_dir(dir_path: String) -> Array:
	ensure_directory(dir_path)
	var files = []
	var dir = DirAccess.open(dir_path)

	dir.list_dir_begin()
	var file_name = dir.get_next()

	if file_name == "":
		ErrorUtility.log_error("No files found in directory: " + dir_path)
		return []

	while file_name != "":
		files.append(file_name)
		file_name = dir.get_next()

	dir.list_dir_end()
	return files

# Get the first file in a directory
# Args: String - The directory path
# Returns: String - The first file in the directory
func get_first_file_in_dir(dir_path: String) -> String:
	ensure_directory(dir_path)
	var dir = DirAccess.open(dir_path)

	dir.list_dir_begin()
	var file_name = dir.get_next()
	if file_name == "":
		ErrorUtility.log_error("No files found in directory: " + dir_path)
		return ""

	dir.list_dir_end()
	return file_name

func update_dd2vtt_file(map_name: String, modified_data: Dictionary) -> void:
	# Convert the modified data dictionary to JSON string
	var json_string = JSON.stringify(modified_data, "\t")
	var file_path = "user://Assets/Maps/" + map_name + ".dd2vtt"
	
	# Open the file for writing (this will overwrite the existing file)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		printerr("Failed to open file for writing: ", file_path)
		return
	
	# Write the updated JSON data
	file.store_string(json_string)
	file.close()
	
	print("Successfully saved updated DD2VTT file to: ", file_path)


# ===================== JSON UTILITY FUNCTIONS =====================

# Load all JSON files in a directory, make them lowercase and call a method with the parsed JSON
# Args: String - The directory path, Callable - The method to call with the parsed JSON
# Returns: None
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

# Load one json file from a directory
# Args: String - The directory path
# Returns: Dictionary - The parsed JSON
func get_json_from_dir(dir_path: String) -> Dictionary:
	ensure_directory(dir_path)
	var json = {}

	var dir = DirAccess.open(dir_path)

	dir.list_dir_begin()
	var file_name = dir.get_next()

	if file_name == "":
		ErrorUtility.log_error("No files found in directory: " + dir_path)
		return {}

	while file_name != "":
		json = proccess_json_file(file_name, dir_path)
		file_name = dir.get_next()

	dir.list_dir_end()
	return json

# Load a JSON file
# Args: String - The file path
# Returns: Dictionary - The parsed JSON
func get_json_file(file_path: String, lowercase: bool = true) -> Dictionary:
	var json = {}

	if !file_path.ends_with(".json"):
		ErrorUtility.log_info("File is not a JSON file: " + file_path)
		return {}

	var dir_path = file_path.get_base_dir()
	var file_name = file_path.get_file()

	json = proccess_json_file(file_name, dir_path, lowercase)
	return json

# Load a JSON file from a DD2VTT file
# Args: String - The file path
# Returns: Dictionary - The parsed JSON
func process_dd2vtt_file(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)

	if !file:
		ErrorUtility.log_error("Error opening file " + file_path)
		return {}

	var json_data = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parsed_json = json.parse(json_data)
	if parsed_json != OK:
		ErrorUtility.log_error("Error parsing JSON file " + file_path)
		return {}

	var data = json.data
	return data

# Get an array of jsons inside a single json file
# Args: String - The file path
# Returns: Array - The parsed JSON
func get_seperate_json_from_file(json_path: String) -> Array:
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json_array = []

	if file:
		var json_data = file.get_as_text()

		json_array = JSON.parse_string(json_data)
	else:
		ErrorUtility.log_error("Error opening file " + json_path)
		return []
	return json_array

# Process a JSON file
# Args: String - The file name, String - The directory path
# Returns: Dictionary - The parsed JSON
func proccess_json_file(file_name: String, dir_path: String, lowercase: bool = true) -> Dictionary:
	if not file_name.ends_with(".json"):
		ErrorUtility.log_info("File is not a JSON file: " + file_name)
		return {}

	var file_path = dir_path + "/" + file_name

	var file = FileAccess.open(file_path, FileAccess.READ)

	if file:
		var json_str
		if lowercase:
			json_str = file.get_as_text().to_lower()
		else:
			json_str = file.get_as_text()

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

# Prepare a dictionary for JSON
# Args: Variant - The data
# Returns: Variant - The prepared data
func prepare_for_json(data: Variant) -> Variant:
	if data is Dictionary:
		var result = {}
		for key in data.keys():
			result[key] = prepare_for_json(data[key])
		return result
	elif data is Array:
		var result = []
		for item in data:
			result.append(prepare_for_json(item))
		return result
	elif data is Color:
		return [data.r, data.g, data.b, data.a]
	elif data is Vector2:
		return [data.x, data.y]
	elif data is SpawnResource:
		# Convert SpawnResource to a dictionary
		var result = {
			"position": prepare_for_json(data.spawn_position),
		}
		return result
	return data

# Convert a dictionary to JSON
# Args: Dictionary - The data
# Returns: String - The JSON
func convert_dict_to_json(data: Dictionary) -> String:
	var json_ready = prepare_for_json(data)
	var index_removed = {}

	for key in json_ready.keys():
		index_removed[json_ready[key]["name"]] = json_ready[key]["Settings"]

	return JSON.stringify(index_removed, " ")

func convert_to_json(data: Array) -> String:
	var json_ready = prepare_for_json(data)
	return JSON.stringify(json_ready, "\t")

# Save a JSON file
# Args: String - The file path, Dictionary - The data
# Returns: None
func save_json_file(file_path: String, data: Dictionary) -> void:
	var json_ready = convert_dict_to_json(data)
	create_file(file_path, json_ready)

# Check if json has required keys
# Args: Dictionary - The parsed JSON, Array - The required keys
# Returns: bool - If the JSON has the required keys
func ensure_json_keys(parsed_json: Dictionary, required_keys: Array) -> bool:
	for key in required_keys:
		if !parsed_json.has(key):
			ErrorUtility.log_error("Key " + key + " not found in JSON")
			return false
	return true

# Check if json has required types
# Args: Dictionary - The parsed JSON, Array - The required types, Array - The required keys
# Returns: bool - If the JSON has the required types
func ensure_json_types(parsed_json: Dictionary, required_types: Array, required_keys: Array) -> bool:
	for key in parsed_json.keys():
		if required_keys.has(key):
			var key_index = required_keys.find(key)
			if typeof(parsed_json[key]) != required_types[key_index]:
				ErrorUtility.log_error("Key " + key + " is not of type " + str(required_types[key_index]) + ", it is " + str(typeof(parsed_json[key])))
				return false
	return true

# Check if json has required keys and types
# Args: Dictionary - The parsed JSON, Array - The required keys, Array - The required types
# Returns: bool - If the JSON has the required keys and types
func ensure_json_type_and_keys(parsed_json: Dictionary, required_keys: Array, required_types: Array) -> bool:
	if !ensure_json_keys(parsed_json, required_keys):
		return false
	if !ensure_json_types(parsed_json, required_types, required_keys):
		return false
	return true

# Sort json values by key order
# Args: Dictionary - The parsed JSON, Array - The key order
# Returns: Array - The sorted values
func sort_json_dictionary_values(parsed_json: Dictionary, sort_structure: Array) -> Array:
	var sorted_values = []
	for key in sort_structure:
		if parsed_json.has(key):
			sorted_values.append(parsed_json[key])
		else:
			ErrorUtility.log_error("Key " + key + " not found in JSON")
	return sorted_values

# Replace a value in a JSON
# Args: Dictionary - The parsed JSON, String - The key, Variant - The value
# Returns: Dictionary - The updated JSON
func replace_json_value(parsed_json: Dictionary, key: String, value: Variant) -> Dictionary:
	if !parsed_json.has(key):
		ErrorUtility.log_error("Key " + key + " not found in JSON")
		return parsed_json
	parsed_json[key] = value
	return parsed_json

# Get values in a JSON
# Args: Dictionary - The parsed JSON, Array - The keys
# Returns: Array - The values
func get_values_in_json(parsed_json: Dictionary, keys: Array) -> Array:
	var values = []
	for key in keys:
		if parsed_json.has(key):
			values.append(parsed_json[key])
		else:
			ErrorUtility.log_error("Key " + key + " not found in JSON")
	return values
