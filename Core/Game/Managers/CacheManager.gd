extends Node
var data: Dictionary = {}
@onready var menu_3k: PackedScene = preload("res://UI/Instances/menu_ui_3k.tscn")
@onready var menu: PackedScene = preload("res://UI/Instances/menu_ui.tscn")
@onready var ability_group: ResourceGroup = preload("res://Core/Resource Groups/Abilities group.tres")
@onready var trait_group: ResourceGroup = preload("res://Core/Resource Groups/Traits group.tres")
@onready var item_group: ResourceGroup = preload("res://Core/Resource Groups/Items group.tres")
@onready var spell_group: ResourceGroup = preload("res://Core/Resource Groups/Spells group.tres")

var _current_group_name := ""
var _scenes_to_load := []
var _loaded_scenes := {}
var _current_load_index := 0
var _is_loading := false

var loaded_abilities: Dictionary = {}
var loaded_traits: Dictionary = {}
var loaded_items: Dictionary = {}
var loaded_spells: Dictionary = {}

func _ready() -> void:
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/", true)
	for file in files:
		var map_name = file.get_file().get_basename()
		data[map_name] = ExternalUtility.process_dd2vtt_file("user://Assets/Maps/" + map_name + ".dd2vtt")

	load_scenes_from_directory("res://Characters/NPCs/", false, "NPCs")
	_populate_resource_dict(ability_group.load_all(), loaded_abilities, "a_name")
	_populate_resource_dict(trait_group.load_all(), loaded_traits, "t_name")
	_populate_resource_dict(item_group.load_all(), loaded_items, "i_name")
	_populate_resource_dict(spell_group.load_all(), loaded_spells, "s_name")


## Helper to populate dictionaries with name as key
func _populate_resource_dict(resource_array: Array, target_dict: Dictionary, name_property: String):
	for res in resource_array:
		if not res or not res.has(name_property):
			printerr("Skipping resource missing name property '%s': %s" % [name_property, res])
			continue
		var res_name = res.get(name_property)
		if target_dict.has(res_name):
			push_warning("Duplicate resource name '%s' found for property '%s'. Overwriting." % [res_name, name_property])
		target_dict[res_name] = res

func _find_resource_by_name(resource_name: String, resource_type: String) -> Resource:
	match resource_type:
		"AbilityResource":
			if loaded_abilities.has(resource_name): return loaded_abilities[resource_name]
		"TraitResource":
			if loaded_traits.has(resource_name): return loaded_traits[resource_name]
		"ItemResource": # Or handle WeaponResource/ArmorResource specifically if needed
			if loaded_items.has(resource_name): return loaded_items[resource_name]
		"SpellResource":
			if loaded_spells.has(resource_name): return loaded_spells[resource_name]
		# --- ADD CASES FOR ALL OTHER RESOURCE TYPES YOU NEED TO LOOK UP ---
		# "FeatResource":
		#     if loaded_feats.has(resource_name): return loaded_feats[resource_name]
		# "ConditionResource":
		#     if loaded_conditions.has(resource_name): return loaded_conditions[resource_name]
		# etc...
		_:
			printerr("Attempted to find resource of unknown or unhandled type: ", resource_type)

	# If not found in the specific dictionary
	printerr("Resource not found in loaded dictionary: Name='%s', Type='%s'" % [resource_name, resource_type])
	return null

# --- Helper function to load arrays of resources by name (Unchanged) ---
## It relies on _find_resource_by_name implemented in CacheManager.
## [br]
## Modifies the array directly on the target object.
func _load_resource_array(target_object: Object, property_name: String, loaded_data: Variant, resource_type: String, default_value: Array) -> void:
	if not target_object:
		printerr("Target object is null for resource array property '%s'" % property_name)
		return

	# Get the existing array property instance from the target object
	var target_array = target_object.get(property_name)

	# Verify that the property on the target object is indeed an Array
	if not target_array is Array:
		printerr("Property '%s' on target is not an Array. Cannot load resource data." % property_name)
		# Optionally set to default if possible
		# target_object.set(property_name, default_value.duplicate())
		return

	# Check if the loaded data is valid (an Array)
	if not loaded_data is Array:
		printerr("Invalid loaded data for resource array '%s' (expected Array), using default. Got: %s" % [property_name, typeof(loaded_data)])
		# Set the target property to a copy of the default value
		target_object.set(property_name, default_value.duplicate())
		return

	# --- Perform the loading ---
	target_array.clear() # Modify the existing array in place
	var item_index = 0
	for resource_name in loaded_data:
		# Ensure the item from JSON is actually a string name before looking it up
		if not resource_name is String:
			printerr("Expected string resource name in loaded data for '%s' at index %d, but got %s. Value: %s" % [property_name, item_index, typeof(resource_name), resource_name])
			item_index += 1
			continue # Skip non-string items

		# Look up the resource using the existing helper
		var found_resource = _find_resource_by_name(resource_name, resource_type)

		# If found, append it to the target array
		if found_resource:
			# Optional: Add a check here to ensure the found resource is of the expected type,
			# if _find_resource_by_name doesn't guarantee it.
			# Example:
			# var expected_script = load("res://path/to/" + resource_type + ".gd") # Or use class_name
			# if found_resource extends expected_script:
			#    target_array.append(found_resource)
			# else:
			#    printerr("Found resource '%s' is not of expected type '%s'." % [resource_name, resource_type])
			target_array.append(found_resource)
		else:
			# Warning/Error already printed by _find_resource_by_name
			pass # Resource not found, skip appending
		item_index += 1

	# No need to call target_object.set() again, as we modified the target_array directly.

func upload(load_node: Node, hide: bool = true) -> void:
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/")
	for file in files:
		var map_name = file.get_file().get_basename()
		await Net.send_dd2vtt_request("user://Assets/Maps/" + map_name + ".dd2vtt")
	if hide:
		load_node.hide()

func get_menu() -> Node:
	if Settings.window_settings["width"] >= 3000:
		return Settings.custom_windows["Menu3K"]
	else:
		return Settings.custom_windows["Menu"]

func get_message_box() -> Node:
	if Settings.window_settings["width"] >= 3000:
		return Settings.custom_windows["MessageBox3K"]
	else:
		return Settings.custom_windows["MessageBox"]

# Start loading scenes from a directory
func load_scenes_from_directory(folder_path: String, recursive: bool = false, group_name: String = "") -> void:
	_current_group_name = group_name
	_scenes_to_load = _get_scene_paths_in_folder(folder_path, recursive)
	_loaded_scenes = {}
	_current_load_index = 0
	_is_loading = true
	
# Process loading one scene per frame
func _process(delta: float) -> void:
	if not _is_loading or _scenes_to_load.size() == 0:
		return
	
	if _current_load_index < _scenes_to_load.size():
		var scene_path = _scenes_to_load[_current_load_index]
		var scene = load(scene_path)

		if scene is PackedScene:
			if not _loaded_scenes.has(_current_group_name):
				_loaded_scenes[_current_group_name] = []
			_loaded_scenes[_current_group_name].append(scene)
			print(scene)
		else:
			printerr("Failed to load scene: ", scene_path)
		
		_current_load_index += 1
	else:
		_is_loading = false
		print(_loaded_scenes)

# Helper function to get all scene file paths in a folder
func _get_scene_paths_in_folder(folder_path: String, recursive: bool = false) -> Array:
	var scene_paths = []
	var folders_to_scan = [folder_path] # Start with the initial folder
	var current_scan_index = 0

	# Ensure the initial path has a trailing slash for consistency if needed later,
	# although list_directory might handle it. Let's keep it for our recursion logic.
	if not folder_path.ends_with("/"):
		folders_to_scan[0] = folder_path + "/"

	printerr("Scanning folder(s) using ResourceLoader.list_directory starting with:", folders_to_scan[0])

	while current_scan_index < folders_to_scan.size():
		var current_folder = folders_to_scan[current_scan_index]
		current_scan_index += 1 # Move to next folder in the queue

		printerr("ResourceLoader scanning:", current_folder)
		var entries = ResourceLoader.list_directory(current_folder)

		if entries.is_empty():
			# It's possible ResourceLoader.list_directory returns empty if the path
			# isn't found or doesn't contain recognized resources.
			# Check if the path itself exists if needed for more detailed errors.
			if not ResourceLoader.exists(current_folder, ""): # Check if dir path is known
				printerr("Warning: Directory path not found or not included in export:", current_folder)
			continue # Move to the next folder in the queue

		printerr("ResourceLoader found entries in '", current_folder, "': ", entries)

		for entry in entries:
			var full_path = current_folder + entry

			# IMPORTANT: Check if the entry is a directory or a file.
			# ResourceLoader.list_directory doesn't tell us directly.
			# We can use ResourceLoader.exists(path, type_hint)
			# An empty type hint checks if the path exists at all.
			# Checking for "PackedScene" checks if it's specifically loadable as that.
			# A simple check is if it contains '.' - directories usually don't.
			# A more robust way might be needed if you have files without extensions.

			# Heuristic: Check if it ends like a file we want or lacks a common file extension '.'
			# This isn't foolproof.
			var is_likely_file = entry.contains(".") # Basic check

			if not is_likely_file or entry.ends_with("/"): # Treat entries ending with '/' as dirs
				# Check if it's potentially a directory that ResourceLoader recognizes
				# Note: ResourceLoader.exists(dir_path) might return true even for dirs
				if recursive:
					printerr("Found potential subdirectory:", full_path)
					# Ensure trailing slash and add to scan queue
					var dir_to_scan = full_path
					if not dir_to_scan.ends_with("/"):
						dir_to_scan += "/"
					if not folders_to_scan.has(dir_to_scan): # Avoid re-scanning
						folders_to_scan.append(dir_to_scan)

			elif entry.ends_with(".tscn"):
				# Since list_directory returns original names and handles remaps internally (expected),
				# we only need to check for .tscn.
				printerr("Adding scene path:", full_path)
				scene_paths.append(full_path)

			# We probably don't need the .remap check here, as ResourceLoader should handle it.

	if scene_paths.is_empty():
		printerr("Warning: Scan completed, but no '.tscn' files were found starting from:", folder_path)

	return scene_paths

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_scenes_to_load.clear()
		_loaded_scenes.clear()
		loaded_abilities.clear()
		loaded_traits.clear()
		loaded_items.clear()
		loaded_spells.clear()
