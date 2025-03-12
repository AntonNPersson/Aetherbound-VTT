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