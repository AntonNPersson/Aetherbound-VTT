extends Node


## Convert the coordinates to the resolution [br]
## Args:[br] Vector2 - The vector to convert [br]
##       Dictionary - The resolution [br]
## Returns:[br] Vector2 - The converted vector [br]
func convert_coords(vect: Vector2, resolution: Dictionary)-> Vector2:
	return Vector2(vect.x*resolution.pixels_per_grid, vect.y*resolution.pixels_per_grid)

## Convert the coordinates to the resolution [br]
## Args: [br] Vector2 - The vector to convert [br]
##       Dictionary - The resolution [br]
## Returns: [br] Vector2 - The converted vector [br]
func inverse_convert_coords(vect: Vector2, resolution: Dictionary) -> Vector2:
	return Vector2(vect.x / resolution.pixels_per_grid, vect.y / resolution.pixels_per_grid)

## Convert the dictionary array to a vector2 array [br]
## Args:[br] Array - The dictionary array [br]
##       Dictionary - The resolution [br]
## Returns:[br] PackedVector2Array - The converted vector array [br]
func dict2vector2array(dict_array:Array,resolution:Dictionary):
	@warning_ignore("unassigned_variable")
	var array: PackedVector2Array
	for x in dict_array:
		if x.has("type"):
			continue
		array.append(convert_coords(Vector2(x.x,x.y),resolution))
	return array

func scale_tile_size(tile_size: Vector2) -> Vector2:
	var screen_scale = 1.0
	
	screen_scale = DisplayServer.screen_get_scale()
		
	if screen_scale > 1.0:
		# Scale the tile size inversely to the screen scale
		var scaled_size = tile_size / screen_scale
		print("Original tile size before hidpi: ", tile_size)
		print("Scaled tile size after hidpi: ", scaled_size)
		return scaled_size
	
	# Return original if no scaling needed
	return tile_size / screen_scale

func apply_hdpi_scaling(scale_factor, tilemap: Variant) -> void:
	tilemap.scale = Vector2(1.0/scale_factor, 1.0/scale_factor)

func is_hpdi_scaling_enabled() -> bool:
	# Check if HDPI scaling is enabled
	return DisplayServer.screen_get_scale() > 1.0

## Convert global position to uv position for the shader on a ColorRect [br]
## Args:[br] Array - The global position [br]
## Returns:[br] Array - The uv position
func global_to_uv_position(global_pos: Array, colorrect: ColorRect) -> Array:
	var uv_positions = []
	var rect_global_pos = colorrect.global_position
	
	for pos in global_pos:
		# Convert global position to local position relative to the ColorRect
		var local_pos = pos - rect_global_pos
		
		# Convert to UV coordinates (0-1 range)
		var uv = Vector2(
			local_pos.x / colorrect.size.x,
			local_pos.y / colorrect.size.y
		)
		
		uv_positions.append(uv)
	
	return uv_positions

## Convert global radius to uv radius for the shader on a ColorRect [br]
## Args:[br] Array - The global radius [br]
## Returns:[br] Array - The uv radius
func global_to_uv_radius(radius: Array, colorrect: ColorRect) -> Array:
	var uv_radiuses = []
	var max_size = max(colorrect.size.x, colorrect.size.y)
	
	for r in radius:
		uv_radiuses.append(r / max_size)
	
	return uv_radiuses

## Convert a hex color string to a linear Color object [br]
## Args:[br] String - The hex color string [br]
## Returns:[br] Color - The linear Color object [br]
## Note: The hex string should be in the format "AARRGGBB" or "RRGGBB"
func hex_to_linear_color(color_hex: String) -> Color:
	if typeof(color_hex) != TYPE_STRING:
		return color_hex
		
	if color_hex.length() == 8:
		var alpha_hex = color_hex.substr(0, 2)
		var red_hex = color_hex.substr(2, 2)
		var green_hex = color_hex.substr(4, 2)
		var blue_hex = color_hex.substr(6, 2)
		
		var alpha = ("0x" + alpha_hex).hex_to_int() / 255.0
		var red = ("0x" + red_hex).hex_to_int() / 255.0
		var green = ("0x" + green_hex).hex_to_int() / 255.0
		var blue = ("0x" + blue_hex).hex_to_int() / 255.0
		
		# Convert from sRGB to linear color space
		red = pow(red, 2.2)
		green = pow(green, 2.2)
		blue = pow(blue, 2.2)
		
		return Color(red, green, blue, alpha)
	else:
		return Color(color_hex)

## Convert a linear Color object to a hex color string [br]
## Args:[br] Color - The linear Color object [br]
## Returns:[br] String - The hex color string [br]
## Note: The output string will be in the format "AARRGGBB"
func linear_color_to_hex(color: Color) -> String:
	if typeof(color) != TYPE_COLOR:
		return str(color)
	
	var red_srgb = pow(color.r, 1.0/2.2)
	var green_srgb = pow(color.g, 1.0/2.2)
	var blue_srgb = pow(color.b, 1.0/2.2)
	
	var alpha_int = int(color.a * 255)
	var red_int = int(red_srgb * 255)
	var green_int = int(green_srgb * 255)
	var blue_int = int(blue_srgb * 255)
	
	return "%02X%02X%02X%02X" % [alpha_int, red_int, green_int, blue_int]

## Generate a unique ID [br]
## Returns:[br] int - The unique ID [br]
## Note: This is a simple random number generator and may not be suitable for all use cases.
func generate_unique_id() -> int:
	return randi() % 1000000

## Convert a global position to a canvas position [br]
## Args:[br] Vector2 - The global position [br]
## Returns:[br] Vector2 - The canvas position [br]
## Note: This function uses the viewport's canvas transform to convert the position.
func convert_to_canvas_position(global_pos: Vector2) -> Vector2:
	var viewport = get_viewport()
	var global_to_canvas_transform = viewport.get_canvas_transform().affine_inverse()
	return global_to_canvas_transform * global_pos

	
##Loads data into a typed array property meant for Enums, converting from strings.
##Modifies the array on target_object directly.[br]
##Args: [br]
	##target_object: The object instance (e.g., MonsterSheet) to modify. [br]
	##property_name: The string name of the array property on the target_object. [br]
	##loaded_data: The data loaded from JSON, expected to be an Array of Strings. [br]
	##enum_type: The Enum dictionary itself (e.g., MonsterSheet.DamageType). [br]
	##enum_keys: The pre-fetched keys of the enum_type dictionary (optimization). [br]
	##default_value: An array to use if loaded_data is invalid or property is missing.
func _load_enum_array(target_object: Object, property_name: String, loaded_data: Variant, enum_type: Dictionary, enum_keys: Array, default_value: Array) -> void:
	if not target_object:
		printerr("Target object is null for enum array property '%s'" % property_name)
		return

	# Get the existing array property instance from the target object
	var target_array = target_object.get(property_name)

	# Verify that the property on the target object is indeed an Array
	if not target_array is Array:
		printerr("Property '%s' on target is not an Array. Cannot load enum data." % property_name)
		# Optionally set to default if possible
		# target_object.set(property_name, default_value.duplicate())
		return

	# Check if the loaded data is valid (an Array)
	if not loaded_data is Array:
		printerr("Invalid loaded data for enum array '%s' (expected Array), using default. Got: %s" % [property_name, typeof(loaded_data)])
		# Set the target property to a copy of the default value
		target_object.set(property_name, default_value.duplicate())
		return

	# --- Perform the loading ---
	target_array.clear() # Modify the existing array in place
	var item_index = 0
	for enum_string in loaded_data:
		# Ensure the item from JSON is actually a string before looking it up
		if not enum_string is String:
			printerr("Expected string enum name in loaded data for '%s' at index %d, but got %s. Value: %s" % [property_name, item_index, typeof(enum_string), enum_string])
			item_index += 1
			continue # Skip non-string items

		# Check if the string is a valid key for the enum
		if enum_string in enum_keys:
			target_array.append(enum_type[enum_string]) # Append the actual enum value
		else:
			# Log error for unknown enum string
			printerr("Unknown enum string '%s' found in loaded data for '%s' at index %d." % [enum_string, property_name, item_index])
			# Decide: skip, append a default, or raise a more critical error? Skipping for now.
		item_index += 1

	# No need to call target_object.set() again, as we modified the target_array directly.

	
	##Loads data into a typed array property meant for basic Godot types, since godot is finicky with this.
	##Args:
	##	target_object: The object instance (e.g., MonsterSheet) to modify.
	##	property_name: The string name of the array property on the target_object.
	##	loaded_data: The data loaded from JSON, expected to be an Array.
	##	expected_godot_type: The Godot TYPE_* constant (e.g., TYPE_STRING, TYPE_INT).
	##	default_value: An array to use if loaded_data is invalid or property is missing.
func _load_basic_typed_array(target_object: Object, property_name: String, loaded_data: Variant, expected_godot_type: int, default_value: Array):
	if not target_object:
		printerr("Target object is null for property '%s'" % property_name)
		return

	# Ensure the property exists on the target object
	if not target_object.has_method("get") or not target_object.has_method("set"):
		printerr("Target object does not support get/set for property '%s'" % property_name)
		# Cannot reliably check property existence without assuming base Object methods
		# or specific class knowledge. Proceed cautiously or add more specific checks.
		# For Resources, this should generally be fine.
		pass

	# Get the existing array property instance from the target object
	var target_array = target_object.get(property_name)

	# Verify that the property on the target object is indeed an Array
	if not target_array is Array:
		printerr("Property '%s' on target is not an Array. Cannot load data." % property_name)
		# Optionally set to default if possible, but risky if schema changed.
		# target_object.set(property_name, default_value.duplicate())
		return

	# Check if the loaded data is valid (an Array)
	if not loaded_data is Array:
		printerr("Invalid loaded data for '%s' (expected Array), using default. Got: %s" % [property_name, typeof(loaded_data)])
		# Set the target property to a copy of the default value
		target_object.set(property_name, default_value.duplicate())
		return

	# --- Perform the loading ---
	target_array.clear() # Modify the existing array in place
	var item_index = 0
	for item in loaded_data:
		if typeof(item) == expected_godot_type:
			target_array.append(item)
		else:
			# Log error for type mismatch within the loaded array
			printerr("Invalid element type in loaded data for '%s' at index %d. Expected type %d, got type %d. Value: %s" % [property_name, item_index, expected_godot_type, typeof(item), item])
			# Skip appending this invalid item
		item_index += 1

	# No need to call target_object.set() again, as we modified the target_array directly.
func update_common_key_values(target_dict: Dictionary, source_dict: Dictionary) -> Dictionary:
	target_dict = target_dict.duplicate()
	# --- 1. Input Validation ---
	if not target_dict is Dictionary:
		printerr("Update Common Keys Error: target_dict is not a valid Dictionary.")
		return target_dict
	if not source_dict is Dictionary:
		printerr("Update Common Keys Error: source_dict is not a valid Dictionary.")
		return target_dict
	# No need to check for empty dicts, the loop handles it.

	# --- 2. Iterate through SOURCE keys ---
	for key in source_dict:
		# --- 3. Check if the EXACT SAME key exists in TARGET ---
		if target_dict.has(key):
			# --- 4. Update TARGET's value ---
			if source_dict[key] is float:
				target_dict[key] = int(source_dict[key])
			else:
				target_dict[key] = source_dict[key]
	return target_dict

## Function to separate a string like "name (qualifier)" into ["name", "qualifier"]
## using regular expressions.[br]
## Returns an array with two elements on success. [br]
## Returns an array with the original string as the single element on failure.
func separate_string_with_regex(input_string: String) -> Array:
	# Regex pattern:
	# ^       - Start of string
	# (.+?)   - Capture group 1: One or more characters, non-greedy (the name)
	# \s*     - Zero or more whitespace characters
	# \(      - Literal opening parenthesis
	# (.+?)   - Capture group 2: One or more characters, non-greedy (the content)
	# \)      - Literal closing parenthesis
	# \s*     - Zero or more whitespace characters
	# $       - End of string
	var regex = RegEx.new()

	# Use raw string literal (@"") in Godot 4 for better readability
	# var pattern = @"^(.+?)\s*\((.+?)\)\s*$"
	# For Godot 3.x, escape backslashes:
	var pattern = "^(.+?)\\s*\\((.+?)\\)\\s*$"

	var error = regex.compile(pattern)
	if error != OK:
		printerr("RegEx compilation failed: ", error)
		return [input_string] # Return original on regex error

	var match = regex.search(input_string)

	if match:
		# Successfully matched the pattern
		var part1 = match.get_string(1).strip_edges() # Group 1 is the name
		var part2 = match.get_string(2).strip_edges() # Group 2 is the qualifier
		return [part1, part2]
	else:
		# Pattern did not match, return the original string in an array
		# Or you could return an empty array: return []
		# Or return ["", ""] - depends on how you want to handle failure
		print("String format did not match regex: ", input_string)
		return [input_string.strip_edges()] # Return cleaned original

# --- Example Usage ---
func _ready():
	var test_string1 = "echolocation (precise)"
	var result1 = separate_string_with_regex(test_string1)
	print("Input: '", test_string1, "' -> Result: ", result1)
	# Expected Output: Input: 'echolocation (precise)' -> Result: [echolocation, precise]

	var test_string2 = " Darkvision   (imprecise)  " # With extra spaces
	var result2 = separate_string_with_regex(test_string2)
	print("Input: '", test_string2, "' -> Result: ", result2)
	# Expected Output: Input: ' Darkvision   (imprecise)  ' -> Result: [Darkvision, imprecise]

	var test_string3 = "Normal Vision" # No parenthesis part
	var result3 = separate_string_with_regex(test_string3)
	print("Input: '", test_string3, "' -> Result: ", result3)
	# Expected Output: Input: 'Normal Vision' -> Result: [Normal Vision] (or whatever fallback you chose)

	var test_string4 = "Hearing (imprecise range 30ft)" # More complex content
	var result4 = separate_string_with_regex(test_string4)
	print("Input: '", test_string4, "' -> Result: ", result4)
	# Expected Output: Input: 'Hearing (imprecise range 30ft)' -> Result: [Hearing, imprecise range 30ft]

func _split_and_clean(text: String) -> PackedStringArray:
	var raw_split: PackedStringArray = text.split(" ", false)
	return raw_split

# Helper function to join a PackedStringArray with a separator
func _join_packed_string_array(arr: PackedStringArray, separator: String) -> String:
	if arr.is_empty():
		return ""
	
	var result: String = arr[0]
	for i in range(1, arr.size()):
		result += separator + arr[i]
	return result

# Function to merge parts of s1 into s2 based on shared words
func merge_strings_conditionally_packed(s1: String, s2: String) -> String:
	# 1. Split both strings into arrays of words (and remove empty entries)
	var words1: PackedStringArray = _split_and_clean(s1)
	var words2: PackedStringArray = _split_and_clean(s2)

	# Handle empty input strings gracefully
	if words1.is_empty():
		return s2 # Nothing to potentially add from s1
	if words2.is_empty():
		# If s2 is empty, there can be no common word, so return s2 (which is empty)
		# Or, you might decide you want to add s1 if s2 is empty?
		# Based on the "only if one word matches" rule, returning empty s2 is correct.
		return s2

	# 2. Check if there's at least one common word
	var has_common_word: bool = false
	for word1 in words1:
		if words2.has(word1): # .has() IS available on PackedStringArray
			has_common_word = true
			break # Found a common word, no need to check further

	# 3. If no common word was found, return the original second string
	if not has_common_word:
		return s2

	# 4. If a common word was found, find words in s1 that are NOT in s2
	var words_to_add: PackedStringArray = []
	for word1 in words1:
		if not words2.has(word1):
			# Avoid adding duplicates if s1 had them (e.g., "darkvision precise precise")
			if not words_to_add.has(word1):
				words_to_add.append(word1)

	# 5. If there are words to add, append them to s2
	if not words_to_add.is_empty():
		var added_string: String = _join_packed_string_array(words_to_add, " ") # Use helper to join
		
		# Combine, ensuring a space is added only if s2 wasn't empty initially
		if s2.strip_edges().length() > 0: # Check original s2 length after stripping whitespace
			return s2 + " " + added_string
		else:
			 # If s2 was effectively empty, just return the added words
			return added_string
	else:
		# No new words to add, return the original s2
		return s2

func does_any_key_contain_string(dict: Dictionary, substring: String) -> String:
	# Ensure the substring isn't empty if you don't want it to match everything
	if substring.is_empty():
		printerr("Warning: Checking for an empty substring might not be intended.")
		# Decide behavior: return false, true, or keep going? Let's return false.
		return substring 

	for key in dict.keys():
		# Important: Ensure the key is actually a string before calling string methods
		if typeof(key) == TYPE_STRING:
			if key.contains(substring):
				return key # Found a key containing the substring
	
	# If the loop finishes without finding a match
	return substring

func clean_dictionary(dict: Dictionary) -> Dictionary:
	var cleaned_dict: Dictionary = {}
	for key in dict.keys():
		var value = dict[key]

		var is_empty = false
		if value is String and value.is_empty():
			is_empty = true
		elif value is String and value.strip_edges() == "0":
			is_empty = true
		elif value is Array and value.size() == 0:
			is_empty = true
		elif value is int and value == 0:
			is_empty = true
		elif value is float and value == 0.0:
			is_empty = true
		elif value is Dictionary and value.is_empty():
			is_empty = true
		elif value == null:
			is_empty = true
		if not is_empty:
			cleaned_dict[key] = value
		else:
			print("Key '%s' with value '%s' was removed from the dictionary." % [key, str(value)])
	return cleaned_dict

func add_plus_to_value(value: int) -> String:
	if value > 0:
		return "+" + str(value)
	else:
		return str(value)

func adjust_damage_string(damage_string: String, modifier_change: int) -> String:
	# If change is zero, no need to do anything
	if modifier_change == 0:
		return damage_string

	# Regex to capture:
	# Group 1: The dice part (e.g., "2d6") OR a base flat number (e.g., "15")
	# Group 2: (Optional) The entire modifier part (e.g., "+ 10", "- 2")
	# Group 3: (Optional) The sign ("+" or "-")
	# Group 4: (Optional) The modifier value ("10", "2")
	var regex = RegEx.new()
	# Pattern breakdown: (Same as before)
	# ^(\\d+d\\d+|\\d+)\s*(([+-])\s*(\\d+))?$
	var pattern = "^(\\d+d\\d+|\\d+)\\s*(([+-])\\s*(\\d+))?$"
	var err = regex.compile(pattern)
	if err != OK:
		printerr("Failed to compile regex for damage string parsing.")
		return damage_string # Return original on regex error

	var result = regex.search(damage_string.strip_edges()) # Use strip_edges for robustness

	if not result:
		# If the string doesn't match the pattern, try parsing as a plain integer
		if damage_string.is_valid_int():
			var base_damage = damage_string.to_int()
			# Apply the change, ensuring flat damage doesn't go below 0 *if reducing*
			var adjusted_damage = base_damage - modifier_change
			if modifier_change > 0: # Only clamp if reducing
				adjusted_damage = max(0, adjusted_damage)
			return str(adjusted_damage)
		else:
			push_warning("Could not parse damage string: ", damage_string)
			return damage_string

	# --- Extract parts from the regex match ---
	var base_part: String = result.get_string(1)
	var modifier_sign: String = result.get_string(3) if result.get_string(3) != null else ""
	var modifier_value_str: String = result.get_string(4) if result.get_string(4) != null else "0"

	var initial_flat_modifier: int = 0
	if modifier_sign == "+":
		initial_flat_modifier = modifier_value_str.to_int()
	elif modifier_sign == "-":
		initial_flat_modifier = -modifier_value_str.to_int()

	var dice_part: String = ""
	var base_flat_damage: int = 0
	var is_dice_base: bool = "d" in base_part

	if is_dice_base:
		dice_part = base_part
	else:
		# The base part itself is a flat number
		base_flat_damage = base_part.to_int()

	# --- Calculate the new flat modifier ---
	var new_flat_modifier = base_flat_damage + initial_flat_modifier + modifier_change

	# --- Construct the new damage string ---
	if is_dice_base:
		# Result will include the dice part
		if new_flat_modifier > 0:
			return "%s + %d" % [dice_part, new_flat_modifier]
		elif new_flat_modifier < 0:
			return "%s - %d" % [dice_part, abs(new_flat_modifier)]
		else:
			# Modifier is exactly zero, return only the dice part
			return dice_part
	else:
		# Result is purely a flat number
		# Clamp to 0 only if we were reducing (modifier_change > 0)
		var final_flat_damage = new_flat_modifier
		if modifier_change > 0 and final_flat_damage < 0:
			final_flat_damage = 0
		# If we were increasing (modifier_change < 0), allow results below zero
		# depending on game rules. Here, we'll allow negatives if increasing.
		# If you *never* want negative flat damage, use: final_flat_damage = max(0, final_flat_damage)

		return str(final_flat_damage)

func calculate_multiple_attack_modifier(attack_number: int, is_agile: bool = false) -> int: return attack_number * -5 if !is_agile else attack_number * -4