extends Node

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