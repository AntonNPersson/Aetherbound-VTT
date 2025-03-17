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
@export var gm_manager: Node = null
@export var loading_icon: Node = null

# Private Variables
var current_content_name: String = "Activity"
var current_content: Control = null

var map_data: Dictionary = {}

var is_loading = false

# ===================== CORE FUNCTIONS =====================


# Called when the node enters the scene tree for the first time.
func _initialize():
	set_content_name(current_content_name)
	set_local_player_availability()

	if Net.is_host():
		create_settings_content()
		create_map_content()
		content.get_node("MapsContent").item_selected.connect(select_local_map)
		content.get_node("MapsContent").item_clicked.connect(on_specific_map_pressed)
		map_manager.open_map_changer.connect(show_map_names_in_context_menu)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if current_content != null:
		content.custom_minimum_size.y = current_content.size.y

	# Updating the settings content based on the global settings (current map)
	var lighting = content.get_node("SettingsContent").get_node("Lightning")
	var illumination = lighting.get_node("Illumination")
	var vision = lighting.get_node("Vision")

	if !Engine.is_editor_hint():
		illumination.get_node("Global Illumination").button_pressed = Settings.map_settings["global_illumination"]
		illumination.get_node("Global Color").get_node("ColorPicker").color = Settings.map_settings["global_illumination_color"]
		vision.get_node("Vision Color").get_node("ColorPicker").color = Settings.map_settings["global_vision_color"]
		vision.get_node("Vision Quality").get_node("Options").selected = Settings.RAY_COUNT_MAPPING.find(Settings.map_settings["global_vision_rays_count"])
		vision.get_node("Fog Color").get_node("ColorPicker").color = Settings.map_settings["global_fog_color"]

# Create the map content that is displayed in the sidebar from the user's maps folder, also sets the prologue map selected
# and sets the tokens for the map manager to use
# Args: None
# Returns: None
func create_map_content() -> void:
	content.get_node("MapsContent").clear()

	var maps_folder_path = "user://Assets/Maps"
	var map_names = ExternalUtility.get_all_files_in_dir(maps_folder_path)
	
	var names = []
	var token_arr = []
	var indices = []

	for map_name in map_names:
		var map_picture = ExternalUtility.get_external_texture_from_dd2vtt(maps_folder_path + "/" + map_name)
		var clean_map_name = map_name.replace(".dd2vtt", "")
		content.get_node("MapsContent").add_item(clean_map_name, map_picture)
		map_data[content.get_node("MapsContent").get_item_count() - 1] = {"path": maps_folder_path + "/" + map_name, "name": clean_map_name}
		clean_map_name = clean_map_name.replace(" ", "_")

		var tokens = []
		if clean_map_name == Settings.prologue_map.replace(" ", "_"):
			tokens.append("players")
		
		indices.append(content.get_node("MapsContent").get_item_count() - 1)
		names.append(clean_map_name)
		token_arr.append(tokens)

	map_manager.add_data_array.rpc(indices, names, token_arr)

func create_settings_content():
	var lighting = content.get_node("SettingsContent").get_node("Lightning")
	var illumination = lighting.get_node("Illumination")
	var vision = lighting.get_node("Vision")

	illumination.get_node("Global Illumination").toggled.connect(set_global_illumination)
	illumination.get_node("Global Color").get_node("ColorPicker").color_changed.connect(set_global_illumination_color)
	illumination.get_node("Global Presets").get_node("Options").item_selected.connect(set_global_illumination_color_preset)
	vision.get_node("Vision Color").get_node("ColorPicker").color_changed.connect(set_global_vision_color)
	vision.get_node("Vision Quality").get_node("Options").item_selected.connect(set_global_vision_rays_count)
	vision.get_node("Fog Color").get_node("ColorPicker").color_changed.connect(set_global_fog_color)
	vision.get_node("Fog Presets").get_node("Options").item_selected.connect(set_global_fog_color_preset)

# Select a map from the sidebar that will be displayed for the local player
# Args: int - The index of the map in the map_data dictionary
# Returns: None
func select_local_map(index: int) -> void:
	if is_loading:
		return

	if map_manager != null and !map_manager.is_current_local_map(index):
		loading_icon.visible = true
		is_loading = true
		await map_manager.create_local_map(map_data[index]["name"])
		map_manager.set_current_local_map(index)
		loading_icon.visible = false
		is_loading = false

func select_map(index: int) -> void:
	if map_manager != null and !map_manager.is_current_map(index) and !map_manager.is_changing_map:
		map_manager.create_map.rpc((map_data[index]["name"]))
		await map_manager.map_created
		map_manager.set_current_map(index)

func select_player_map(player_id: int, map_name: String) -> void:
	if map_manager != null and !map_manager.is_current_map(map_manager.get_map_index_from_name(map_name)):
		map_manager.create_map.rpc_id(player_id, map_name)
		await map_manager.map_created
		map_manager.set_player_current_map(player_id, map_manager.get_map_index_from_name(map_name))

func set_global_illumination(state: bool) -> void:
	var tokens = map_manager.get_all_tokens(map_manager.current_local_map)
	for token in tokens:
		gm_manager.set_global_illumination.rpc_id(token.name.to_int(), state)
	gm_manager.set_global_illumination(state)

func set_global_illumination_color(color: Color) -> void:
	var tokens = map_manager.get_all_tokens(map_manager.current_local_map)
	for token in tokens:
		gm_manager.set_global_illumination_color.rpc_id(token.name.to_int(), color)
	gm_manager.set_global_illumination_color(color)

func set_global_illumination_color_preset(index: int) -> void:
	var tokens = map_manager.get_all_tokens(map_manager.current_local_map)
	var preset = content.get_node("SettingsContent").get_node("Lightning").get_node("Illumination").get_node("Global Presets").get_node("Options").get_item_text(index)
	for token in tokens:
		gm_manager.set_global_illumination_color.rpc_id(token.name.to_int(), get_global_preset(preset))
	gm_manager.set_global_illumination_color(get_global_preset(preset))

func set_global_vision_color(color: Color) -> void:
	var tokens = map_manager.get_all_tokens(map_manager.current_local_map)
	for token in tokens:
		gm_manager.set_player_vision_color(token.name.to_int(), color)
	gm_manager.set_global_vision_color(color)

func set_global_vision_rays_count(index: int) -> void:
	var tokens = map_manager.get_all_tokens(map_manager.current_local_map)
	for token in tokens:
		gm_manager.set_global_vision_rays_count.rpc_id(token.name.to_int(), index)
	gm_manager.set_global_vision_rays_count(index)

func set_global_fog_color(color: Color) -> void:
	var tokens = map_manager.get_all_tokens(map_manager.current_local_map)
	for token in tokens:
		gm_manager.set_global_fog_color.rpc_id(token.name.to_int(), color)
	gm_manager.set_global_fog_color(color)

func set_global_fog_color_preset(index: int) -> void:
	var tokens = map_manager.get_all_tokens(map_manager.current_local_map)
	var preset = content.get_node("SettingsContent").get_node("Lightning").get_node("Vision").get_node("Fog Presets").get_node("Options").get_item_text(index)
	for token in tokens:
		gm_manager.set_global_fog_color.rpc_id(token.name.to_int(), get_global_preset(preset))
	gm_manager.set_global_fog_color(get_global_preset(preset))

# ===================== HELPER FUNCTIONS =====================

# Set the content name (Activity, Resources, Actors, Maps, Draw, Settings), this changes the content in the sidebar
# Args: String - The name of the content
# Returns: None
func set_content_name(na: String) -> void:
	current_content_name = na
	content_name.text = "[center]" + current_content_name + "[/center]"
	if content.has_node(current_content_name + "Content"):
		current_content = content.get_node(current_content_name + "Content")
	set_all_content_visibility()

# Set the visibility of all content in the sidebar, and only show the current content
# Args: None
# Returns: None
func set_all_content_visibility() -> void:
	for child in content.get_children():
		if child is Control:
			child.visible = false

	if current_content != null:
		current_content.visible = true

# Set the availability of the local player, if they are the host or not
# Args: None
# Returns: None
func set_local_player_availability() -> void:
	maps.disabled = !Net.is_host()
	settings.disabled = !Net.is_host()

func show_map_names_in_context_menu(player_id) -> void:
	print("Player ID: " + str(player_id))
	var context = context_panel.new()
	add_child(context)
	context.create_panel(get_viewport().get_mouse_position())
	for index in map_data.keys():
		context.add_button(map_data[index]["name"], select_player_map.bind(player_id, map_data[index]["name"]))

# ===================== INPUT FUNCTIONS =====================

# When the activity button is pressed
# Args: None
# Returns: None
func _on_activity_pressed() -> void:
	set_content_name("Activity")

# When the resources button is pressed
# Args: None
# Returns: None
func _on_resource_pressed() -> void:
	set_content_name("Resources")

# When the actors button is pressed
# Args: None
# Returns: None
func _on_actor_pressed() -> void:
	set_content_name("Actors")

# When the maps button is pressed
# Args: None
# Returns: None
func _on_map_pressed() -> void:
	set_content_name("Maps")

# When a specific map is right clicked, to open context menu
# Args: int - The index of the map in the map_data dictionary, Vector2 - The position of the mouse, int - The input index
# Returns: None
func on_specific_map_pressed(index: int, pos: Vector2, input_index: int) -> void:
	if input_index == MOUSE_BUTTON_RIGHT:
		var context = context_panel.new()
		add_child(context)
		context.create_panel(pos)
		context.add_button("Select", select_local_map.bind(index))
		context.add_button("Change", select_map.bind(index))


# When the draw button is pressed
# Args: None
# Returns: None
func _on_draw_pressed() -> void:
	set_content_name("Draw")

# When the settings button is pressed
# Args: None
# Returns: None
func _on_settings_pressed() -> void:
	set_content_name("Settings")

# When the sidebar is hovered over, pause the input for the map manager
# Args: None
# Returns: None
func _on_sidebar_mouse_entered() -> void:
	if map_manager != null:
		map_manager.pause_input(true)

# When the sidebar is hovered out, unpause the input for the map manager
# Args: None
# Returns: None
func _on_sidebar_mouse_exited() -> void:
	if map_manager != null:
		map_manager.pause_input(false)

func get_global_preset(preset: String) -> Color:
	if preset == "Night":
		return Color(0.15, 0.2, 0.35, 1.0)
	elif preset == "Day":
		return Color(1.0, 1.0, 1.0, 1.0)
	elif preset == "Dark":
		return Color(0.0, 0.0, 0.0, 1.0)
	elif preset == "Dim":
		return Color(0.0, 0.0, 0.0, 0.6)
	elif preset == "Bright":
		return Color(0.0, 0.0, 0.0, 0.2)
	else:
		return Color(1.0, 1.0, 1.0, 1.0)
