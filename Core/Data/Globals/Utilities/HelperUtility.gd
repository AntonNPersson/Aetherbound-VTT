extends Node


# Convert the coordinates to the resolution
# Args: Vector2 - The vector to convert
#       Dictionary - The resolution
# Returns: Vector2 - The converted vector
func convert_coords(vect: Vector2, resolution: Dictionary)->Vector2:
	return Vector2(vect.x*resolution.pixels_per_grid, vect.y*resolution.pixels_per_grid)

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
	var new_tile_size = tile_size * 0.5
	return new_tile_size
	var is_mac = OS.get_name() == "macOS"
	var screen_scale = 1.0
	
	if is_mac:
		screen_scale = DisplayServer.screen_get_scale()
		print("Mac detected with scale factor: ", screen_scale)
		
		if screen_scale > 1.0:
			# Scale the tile size inversely to the screen scale
			var scaled_size = tile_size / screen_scale
			print("Original tile size: ", tile_size)
			print("Scaled tile size: ", scaled_size)
			return scaled_size
	
	# Return original if no scaling needed
	return tile_size

func apply_hdpi_scaling(scale_factor, tilemap: Variant) -> void:
	tilemap.scale = Vector2(1.0/scale_factor, 1.0/scale_factor)
