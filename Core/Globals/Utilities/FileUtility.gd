# FILE UTILITY #
extends Node

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