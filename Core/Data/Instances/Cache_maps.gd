extends Node
var data: Dictionary = {}

func upload(load_node: Node) -> void:
	var files = ExternalUtility.get_all_files_in_dir("user://Assets/Maps/")
	await get_tree().create_timer(1, false).timeout
	for file in files:
		var map_name = file.get_file().get_basename()
		data[map_name] = ExternalUtility.process_dd2vtt_file("user://Assets/Maps/" + map_name + ".dd2vtt")
		await Net.send_dd2vtt_request("user://Assets/Maps/" + map_name + ".dd2vtt")
	load_node.hide()