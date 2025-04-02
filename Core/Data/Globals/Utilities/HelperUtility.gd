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
	print("Scale 1: ", DisplayServer.screen_get_scale(0))
	print("Scale 2: ", DisplayServer.screen_get_scale(1))
	print("Scale 3: ", DisplayServer.screen_get_scale(2))
	print("Mac detected with scale factor: ", screen_scale)
		
	if screen_scale > 1.0:
		# Scale the tile size inversely to the screen scale
		var scaled_size = tile_size / screen_scale
		print("Original tile size: ", tile_size)
		print("Scaled tile size: ", scaled_size)
		return scaled_size
	
	# Return original if no scaling needed
	return tile_size / screen_scale

func apply_hdpi_scaling(scale_factor, tilemap: Variant) -> void:
	tilemap.scale = Vector2(1.0/scale_factor, 1.0/scale_factor)

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
