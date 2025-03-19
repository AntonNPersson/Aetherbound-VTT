extends Node


# Convert the coordinates to the resolution
# Args: Vector2 - The vector to convert
#       Dictionary - The resolution
# Returns: Vector2 - The converted vector
func convert_coords(vect: Vector2, resolution: Dictionary)-> Vector2:
	return Vector2(vect.x*resolution.pixels_per_grid, vect.y*resolution.pixels_per_grid)

func inverse_convert_coords(vect: Vector2, resolution: Dictionary) -> Vector2:
	return Vector2(vect.x / resolution.pixels_per_grid, vect.y / resolution.pixels_per_grid)

# Convert the dictionary array to a vector2 array
# Args: Array - The dictionary array
#       Dictionary - The resolution
# Returns: PackedVector2Array - The converted vector array
func dict2vector2array(dict_array:Array,resolution:Dictionary):
	@warning_ignore("unassigned_variable")
	var array: PackedVector2Array
	for x in dict_array:
		array.append(convert_coords(Vector2(x.x,x.y),resolution))
	return array

func scale_tile_size(tile_size: Vector2) -> Vector2:
	var screen_scale = 1.0
	
	screen_scale = DisplayServer.screen_get_scale()
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

# Convert global position to uv position for the shader on a ColorRect
# Args: Array - The global position
# Returns: Array - The uv position
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

# Convert global radius to uv radius for the shader on a ColorRect
# Args: Array - The global radius
# Returns: Array - The uv radius
func global_to_uv_radius(radius: Array, colorrect: ColorRect) -> Array:
	var uv_radiuses = []
	var max_size = max(colorrect.size.x, colorrect.size.y)
	
	for r in radius:
		uv_radiuses.append(r / max_size)
	
	return uv_radiuses

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

