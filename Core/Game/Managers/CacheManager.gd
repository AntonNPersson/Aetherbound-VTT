extends Node
var data: Dictionary = {}
@onready var menu_3k: PackedScene = preload("res://UI/Instances/menu_ui_3k.tscn")
@onready var menu: PackedScene = preload("res://UI/Instances/menu_ui.tscn")

func _ready() -> void:
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/")
	for file in files:
		var map_name = file.get_file().get_basename()
		data[map_name] = ExternalUtility.process_dd2vtt_file("user://Assets/Maps/" + map_name + ".dd2vtt")

func upload(load_node: Node) -> void:
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/")
	for file in files:
		var map_name = file.get_file().get_basename()
		await Net.send_dd2vtt_request("user://Assets/Maps/" + map_name + ".dd2vtt")
	load_node.hide()

func get_menu() -> Node:
	if Settings.window_settings["width"] >= 3000:
		var menu_instance = menu_3k.instantiate()
		menu_instance.visible = true
		return menu_instance
	else:
		print("Menu")
		var menu_instance = menu.instantiate()
		menu_instance.visible = true
		print(menu_instance)
		return menu_instance
