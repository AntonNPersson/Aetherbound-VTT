@tool
extends Node
# ===================== SIDEBAR CONTROL =====================
# Manages the sidebar
# ==========================================================

# Public Variables
@export var activity: Control = null
@export var maps: Control = null
@export var actor: Control = null
@export var resource: Control = null
@export var draw: Control = null
@export var settings: Control = null
@export var content: Control = null
@export var content_name: Control = null
@export var map_manager: Node = null

# Private Variables
var current_content_name: String = "Activity"
var current_content: Control = null

var map_data: Dictionary = {}

# ===================== CORE FUNCTIONS =====================


# Called when the node enters the scene tree for the first time.
func _initialize():
	set_content_name(current_content_name)
	set_local_player_availability()
	create_map_content()

	content.get_node("MapsContent").item_selected.connect(select_local_map)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_content != null:
		content.custom_minimum_size.y = current_content.size.y

# Create the map content that is displayed in the sidebar from the user's maps folder
# Args: None
# Returns: None
func create_map_content() -> void:
	content.get_node("MapsContent").clear()

	var maps_folder_path = "user://Assets/Maps"
	var map_names = ExternalUtility.get_all_files_in_dir(maps_folder_path)
	for map_name in map_names:
		var map_picture = ExternalUtility.get_external_texture(maps_folder_path + "/" + map_name)
		var clean_map_name = map_name.replace(".jpg", "")
		content.get_node("MapsContent").add_item(clean_map_name, map_picture)
		map_data[str(content.get_node("MapsContent").get_item_count() - 1)] = {"path": maps_folder_path + "/" + map_name, "picture": map_picture, "name": clean_map_name}

# Select a map from the sidebar that will be displayed for the local player
# Args: int - The index of the map in the map_data dictionary
# Returns: None
func select_local_map(index: int) -> void:
	if map_manager != null:
		print("Selected map: " + map_data[str(index)]["path"])
		map_manager.create_local_map(map_data[str(index)]["path"])
		map_manager.set_current_map(index)
		map_manager.show_only_tokens_on_map(index)

# ===================== HELPER FUNCTIONS =====================

func set_content_name(na: String) -> void:
	current_content_name = na
	content_name.text = "[center]" + current_content_name + "[/center]"
	current_content = content.get_node(current_content_name + "Content")
	set_all_content_visibility()

func set_all_content_visibility() -> void:
	for child in content.get_children():
		if child is Control:
			child.visible = false

	if current_content != null:
		current_content.visible = true

func set_local_player_availability() -> void:
	maps.disabled = !Net.is_host()

# ===================== INPUT FUNCTIONS =====================

func _on_activity_pressed():
	set_content_name("Activity")

func _on_resource_pressed():
	set_content_name("Resources")

func _on_actor_pressed():
	set_content_name("Actors")

func _on_map_pressed():
	set_content_name("Maps")

func _on_draw_pressed():
	set_content_name("Draw")

func _on_settings_pressed():
	set_content_name("Settings")

func _on_sidebar_mouse_entered():
	if map_manager != null:
		map_manager.pause_input(true)

func _on_sidebar_mouse_exited():
	if map_manager != null:
		map_manager.pause_input(false)
