extends Node
var data: Dictionary = {}
@onready var menu_3k: PackedScene = preload("res://UI/Instances/menu_ui_3k.tscn")
@onready var menu: PackedScene = preload("res://UI/Instances/menu_ui.tscn")

var _current_group_name := ""
var _scenes_to_load := []
var _loaded_scenes := {}
var _current_load_index := 0
var _is_loading := false

func _ready() -> void:
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/")
	for file in files:
		var map_name = file.get_file().get_basename()
		data[map_name] = ExternalUtility.process_dd2vtt_file("user://Assets/Maps/" + map_name + ".dd2vtt")

	load_scenes_from_directory("res://Characters/NPCs/", false, "NPCs")

func upload(load_node: Node) -> void:
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/")
	for file in files:
		var map_name = file.get_file().get_basename()
		await Net.send_dd2vtt_request("user://Assets/Maps/" + map_name + ".dd2vtt")
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
		
		_current_load_index += 1
	else:
		_is_loading = false
		print(_loaded_scenes)

# Helper function to get all scene file paths in a folder
func _get_scene_paths_in_folder(folder_path: String, recursive: bool = false) -> Array:
	var scene_paths = []
	
	if not folder_path.ends_with("/"):
		folder_path += "/"
	
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var current_path = folder_path + file_name
			
			if dir.current_is_dir() and recursive:
				var sub_paths = _get_scene_paths_in_folder(current_path + "/", recursive)
				scene_paths.append_array(sub_paths)
			
			elif file_name.ends_with(".tscn"):
				scene_paths.append(current_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return scene_paths
