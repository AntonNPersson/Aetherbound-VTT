# Manages loading of scenes, resources (simplified to only Traits), and map data.
# Provides centralized access to loaded assets.

extends Node

# --- Data & UI References ---
var data: Dictionary = {} # Holds map data (dd2vtt)
# PackedScene references preloaded for immediate UI use if needed
@onready var menu_3k: PackedScene = preload("res://UI/Instances/menu_ui_3k.tscn")
@onready var menu: PackedScene = preload("res://UI/Instances/menu_ui.tscn")
# Assume Settings and Net nodes/singletons exist elsewhere
# Assume ExternalUtility and ErrorUtility singletons exist and are Godot 4 compatible

# --- Scene Loading State ---
var _current_scene_group_name := ""
var _scenes_to_load: Array[String] = [] # Paths
var _loaded_scenes: Dictionary = {} # group_name -> [PackedScene]
var _current_scene_load_index := 0
var _is_loading_scenes := false

# --- Resource Loading State ---
# Array of dictionaries: {"path": String, "target_dict": Dictionary, "name_prop": String}
var _resources_to_load: Array[Dictionary] = []
var _current_resource_load_index := 0
var _is_loading_resources := false
var _total_resources_to_load := 0
var _resource_load_requests := {}

# --- Resource Dictionaries (Simplified) ---
var loaded_traits: Dictionary = {} # ONLY Trait resources

# --- Constants for Resource Name Properties (Simplified) ---
const TRAIT_NAME_PROP = "t_name" # MUST match the @export var name in TraitResource.gd


# ==================== INITIALIZATION ====================

func _ready() -> void:
	print("CacheManager: Initializing...")

	# --- Load Map Data (RESTORED ORIGINAL LOGIC) ---
	# Uses user's original ExternalUtility call and path reconstruction
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/", true) # Assuming this returns what the original loop expected
	for file in files: # Assuming 'file' has get_file() and get_basename() methods
		# Original logic check: Ensure 'file' is not null and has the expected methods before calling them
		if file:
			var map_name = file.get_file().get_basename()
			if not map_name.is_empty():
				var map_file_path = "user://Assets/Maps/" + map_name + ".dd2vtt"
				# Optional: Check if this reconstructed path actually exists before processing
				# if FileAccess.file_exists(map_file_path):
				data[map_name] = ExternalUtility.process_dd2vtt_file(map_file_path)
				# else:
				#     ErrorUtility.log_warning("Reconstructed map path not found: %s" % map_file_path)
			else:
				ErrorUtility.log_warning("Empty map name derived from file object: %s" % str(file))
		else:
			ErrorUtility.log_warning("Unexpected item returned by get_all_files_in_dir: %s" % str(file))
	print("CacheManager: Map data loading attempted.")
	# -----------------------------------------------------

	# --- Start Scene Loading (Async) ---
	# Example: Load NPC scenes into the "NPCs" group
	load_scenes_from_directory_async("res://Characters/NPCs/", false, "NPCs")

	# --- Start Resource Loading (Async - ONLY TRAITS) ---
	print("--- Starting Asynchronous Resource Loading ---")
	load_resources_from_directory_async("res://Content/Traits/", false, loaded_traits, TRAIT_NAME_PROP, [".tres"])
	print("--- Resource Loading Initiated (will proceed in background) ---")


# ==================== RESOURCE/SCENE ACCESS ====================

# Find a loaded resource (Simplified to only Traits)
func _find_resource_by_name(resource_name: String, resource_type: String) -> Resource:
	var lookup_key = resource_name # Or resource_name.to_lower() if keys are stored lowercase

	# Only handle TraitResource requests in this simplified version
	if resource_type == "TraitResource":
		if loaded_traits.has(lookup_key):
			return loaded_traits[lookup_key]
		else:
			# print("Trait resource not found in loaded dictionary: Name='%s'" % resource_name) # Less verbose
			return null
	else:
		ErrorUtility.log_warning("Attempted to find resource type '%s', but only TraitResource is handled." % resource_type)
		return null


# Load/populate an array property on an object with resources looked up by name
# Note: This relies on _find_resource_by_name, which now only finds Traits.
func _load_resource_array(target_object: Object, property_name: String, loaded_data: Variant, resource_type: String, default_value: Array) -> void:
	if not target_object: return
	var target_array = target_object.get(property_name)
	if not target_array is Array: return
	if not loaded_data is Array:
		target_object.set(property_name, default_value.duplicate())
		return

	target_array.clear()
	var item_index = 0
	for resource_name in loaded_data:
		if not resource_name is String:
			ErrorUtility.log_warning("Expected string resource name in loaded data for '%s' at index %d, but got %s." % [property_name, item_index, typeof(resource_name)])
			item_index += 1
			continue

		# Will only find the resource if resource_type == "TraitResource"
		var found_resource = _find_resource_by_name(resource_name, resource_type)
		if found_resource:
			target_array.append(found_resource)
		# else: # Warning handled by _find_resource_by_name if type mismatch or not found
		item_index += 1


# Get loaded scenes for a specific group
func get_loaded_scenes(group_name: String) -> Array[PackedScene]:
	if _loaded_scenes.has(group_name):
		return _loaded_scenes[group_name]
	else:
		# ErrorUtility.log_warning("No loaded scenes found for group: '%s'" % group_name)
		return []


# Check if all loading (scenes and resources) is complete
func is_loading_complete() -> bool:
	return not _is_loading_scenes and not _is_loading_resources


# ==================== DATA UPLOAD (Restored) ====================

# Example function for uploading map data
func upload(load_node: Node, hide: bool = true) -> void:
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/", true)
	for file in files:
		if file and file.has_method("get_file") and file.get_file() and file.get_file().has_method("get_basename"):
			var map_name = file.get_file().get_basename()
			if not map_name.is_empty():
				var map_file_path = "user://Assets/Maps/" + map_name + ".dd2vtt"
				await Net.send_dd2vtt_request(map_file_path) # Assumes Net exists
			else:
				ErrorUtility.log_warning("Upload: Empty map name derived from file object: %s" % str(file))
		else:
			ErrorUtility.log_warning("Upload: Unexpected item returned by get_all_files_in_dir: %s" % str(file))

	if hide:
		if is_instance_valid(load_node):
			load_node.hide()
		else:
			ErrorUtility.log_warning("Upload: load_node is not valid, cannot hide.")


# ==================== UI HELPERS ====================

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


# ==================== ASYNC LOADING FUNCTIONS ====================

# --- Scene Loading ---
func load_scenes_from_directory_async(folder_path: String, recursive: bool = false, group_name: String = "") -> void:
	_current_scene_group_name = group_name
	_scenes_to_load = _get_file_paths_in_folder(folder_path, recursive, [".tscn"])
	_loaded_scenes[group_name] = []
	_current_scene_load_index = 0
	_is_loading_scenes = not _scenes_to_load.is_empty()
	if _is_loading_scenes:
		print("Starting async scene load for group '%s' (%d scenes)" % [group_name, _scenes_to_load.size()])
		set_process(true)
	# else:
		ErrorUtility.log_warning("No '.tscn' files found to load for group '%s' starting from: %s" % [group_name, folder_path])


# --- Resource Loading ---
func load_resources_from_directory_async(folder_path: String, recursive: bool, target_dictionary: Dictionary, name_property: String, extensions: Array[String]) -> void:
	print("Queueing async resource load from '%s' (Recursive: %s, Name Prop: '%s', Exts: %s)" % [folder_path, recursive, name_property, extensions])

	var resource_paths: Array[String] = _get_file_paths_in_folder(folder_path, recursive, extensions)

	if resource_paths.is_empty():
		ErrorUtility.log_warning("No resources with extensions %s found in '%s' to queue." % [extensions, folder_path])
		return

	var initial_queue_size = _resources_to_load.size()
	for path in resource_paths:
		_resources_to_load.append({
			"path": path,
			"target_dict": target_dictionary,
			"name_prop": name_property
		})
		var error = ResourceLoader.load_threaded_request(path)
		if error != Error.OK:
			printerr("Failed to start threaded load request for: %s. Error: %s" % [path, error])
			_resource_load_requests[path] = ResourceLoader.THREAD_LOAD_FAILED

	var num_queued = resource_paths.size()
	_total_resources_to_load += num_queued

	if num_queued > 0:
		_is_loading_resources = true
		set_process(true)


# ==================== PROCESS LOOP (Handles Loading) ====================

func _process(delta: float) -> void:
	var still_loading_scenes = false
	var still_loading_resources = false

	# --- Process Scene Loading ---
	if _is_loading_scenes:
		if _current_scene_load_index < _scenes_to_load.size():
			var scene_path = _scenes_to_load[_current_scene_load_index]
			var scene = load(scene_path) # Sync load per frame
			if scene is PackedScene:
				if not _loaded_scenes.has(_current_scene_group_name):
					_loaded_scenes[_current_scene_group_name] = []
				_loaded_scenes[_current_scene_group_name].append(scene)
			_current_scene_load_index += 1
			still_loading_scenes = true
		else:
			print("Async scene loading complete for group '%s'." % _current_scene_group_name)
			_is_loading_scenes = false
			_scenes_to_load.clear()
			_current_scene_load_index = 0
			_current_scene_group_name = ""

	# --- Process Resource Loading ---
	if _is_loading_resources:
		if _current_resource_load_index < _resources_to_load.size():
			var load_info: Dictionary = _resources_to_load[_current_resource_load_index]
			var path: String = load_info["path"]
			var target_dict: Dictionary = load_info["target_dict"]
			var name_prop: String = load_info["name_prop"]
			var status = ResourceLoader.load_threaded_get_status(path, _resource_load_requests.get(path, []))
			var processed_this_frame = false

			match status:
				ResourceLoader.THREAD_LOAD_IN_PROGRESS:
					still_loading_resources = true
				ResourceLoader.THREAD_LOAD_LOADED:
					var res: Resource = ResourceLoader.load_threaded_get(path)
					if res is Resource and name_prop in res:
						var res_name_var: Variant = res.get(name_prop)
						if typeof(res_name_var) == TYPE_STRING and not res_name_var.is_empty():
							var res_name: String = res_name_var
							# Apply necessary key formatting (e.g., lowercase) if needed
							# res_name = res_name_var.to_lower()
							if target_dict.has(res_name):
								ErrorUtility.log_warning("Duplicate resource name '%s' loaded (Path: %s). Overwriting." % [res_name, path])
							target_dict[res_name] = res
						# else: Handle invalid name value
					# else: Handle missing name prop or wrong type
					processed_this_frame = true
					_resource_load_requests.erase(path)
				ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
					printerr("Threaded resource load failed for path: %s, Status: %s" % [path, status])
					processed_this_frame = true
					_resource_load_requests.erase(path)
				_:
					still_loading_resources = true

			if processed_this_frame:
				_current_resource_load_index += 1

			if _current_resource_load_index < _resources_to_load.size():
				still_loading_resources = true
		else:
			print("Asynchronous resource loading complete (%d total queued)." % _total_resources_to_load)
			_is_loading_resources = false
			_resources_to_load.clear()
			_current_resource_load_index = 0
			_total_resources_to_load = 0
			_resource_load_requests.clear()

	# --- Disable _process ---
	if not still_loading_scenes and not still_loading_resources:
		if not _is_loading_scenes and not _is_loading_resources: # Check flags again after processing
			set_process(false)
			print("CacheManager: _process disabled - all loading complete.")


# ==================== HELPER FUNCTIONS ====================

# --- Generic Directory Scanner (Using ResourceLoader) ---
func _get_file_paths_in_folder(folder_path: String, recursive: bool, extensions: Array[String]) -> Array[String]:
	var file_paths: Array[String] = []
	var folders_to_scan: Array[String] = [folder_path]
	var scanned_folders: PackedStringArray = []
	var lower_extensions: Array[String] = []
	for ext in extensions: lower_extensions.append(ext.to_lower())

	while not folders_to_scan.is_empty():
		var current_folder: String = folders_to_scan.pop_front()
		if not current_folder.ends_with("/"): current_folder += "/"
		if scanned_folders.has(current_folder): continue
		scanned_folders.append(current_folder)

		var entries: PackedStringArray = ResourceLoader.list_directory(current_folder)
		if entries.is_empty(): continue

		for entry_name in entries:
			if entry_name == "." or entry_name == "..": continue
			var full_path = current_folder + entry_name
			var is_directory_guess = entry_name.ends_with("/") or not entry_name.contains(".")
			if is_directory_guess:
				if recursive and ResourceLoader.exists(full_path):
					folders_to_scan.append(full_path)
			else:
				var file_ext = "." + entry_name.get_extension().to_lower()
				if lower_extensions.has(file_ext):
					file_paths.append(full_path)
	return file_paths


# ==================== CLEANUP ====================

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("CacheManager: Cleaning up on close request...")
		set_process(false)
		# Clear scene loading state
		_is_loading_scenes = false
		_scenes_to_load.clear()
		_loaded_scenes.clear()
		_current_scene_load_index = 0
		_current_scene_group_name = ""
		# Clear resource loading state
		_is_loading_resources = false
		_resources_to_load.clear()
		_resource_load_requests.clear()
		_current_resource_load_index = 0
		_total_resources_to_load = 0
		# Clear resource dictionaries (ONLY TRAITS)
		loaded_traits.clear()
		print("CacheManager: Cleanup complete.")
