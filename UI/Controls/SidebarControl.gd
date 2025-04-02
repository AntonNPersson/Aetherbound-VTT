@tool
extends Node
# ===================== SIDEBAR CONTROL =====================
# Manages the sidebar
# TODO: Refactor this input handler - monolithic due to time constraints
# SidebarUIManager: Handles switching content panels (set_content_name, _on_activity_pressed, etc.).
# CreationToolManager: Manages the is_creating state and activates/deactivates the input handlers for creating objects.
# SettingsController: Connects UI elements in the settings panel to functions that send RPCs (could potentially live within the settings panel scene itself).
# ActivityLogController: Handles receiving create_dice_activity RPCs and adding items to the log UI.
# MapListController/ResourceListController: Handle populating and interacting with those specific lists.
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
@onready var activity_context_scene = preload("res://UI/Instances/Activity.tscn")
@onready var activity_container = content.get_node("ActivityContent")
@onready var sidebar_node: Control = get_child(0)

# Private Variables
var current_content_name: String = "Activity"
var current_content: Control = null

var map_data: Dictionary = {}

var is_loading = false
var is_mouse_over = false
var is_initialized = false

# Quick access variables
var lighting = null
var illumination = null
var vision = null
var layers = null
var world_elements = null
var triggers = null
var npcs = null
var actor_tokens = null

var selected_actors = []
var previous_actor_size = 0
var current_actor_context = null

# Creation variables
var is_creating = {
	"Light": false,
	"Wall": false,
	"Invisible Wall": false,
	"Phantom Wall": false,
	"Spawn": false,
	"Message": false,
	"Terrain": false,
	"Settings": false,
	"Condition": false,
	"Sound": false,
}
var is_currently_creating = false
var wall_data = {}
var selected_wall = []

var npc_token = null
var selected_token_data = {}

var shift_action_started = false

# ===================== CORE FUNCTIONS =====================


# Called when the node enters the scene tree for the first time.
func _initialize():
	set_content_name(current_content_name)
	set_local_player_availability()
	Bus.send_roll_to_all.connect(func(sender: String, info: String, target: String, roll: Dictionary, defending_roll: String, result: String): create_dice_activity.rpc(sender, info, target, roll, defending_roll, result))
	Bus.send_roll_to_self.connect(func(sender: String, info: String, target: String, roll: Dictionary, defending_roll: String, result: String): create_dice_activity(sender, info, target, roll, defending_roll, result))
	Bus.send_roll_to_gm.connect(func(sender: String, info: String, target: String, roll: Dictionary, defending_roll: String, result: String): create_dice_activity.rpc_id(1, sender, info, target, roll, defending_roll, result))
	create_activity_content()
	actor_tokens = content.get_node("ActorsContent").get_node("Tokens")
	create_actors_content()

	if Net.is_host():
		lighting = content.get_node("SettingsContent").get_node("Lightning")
		illumination = lighting.get_node("Illumination")
		vision = lighting.get_node("Vision")
		layers = lighting.get_node("Layers")
		world_elements = content.get_node("DrawContent").get_node("World Elements")
		triggers = content.get_node("DrawContent").get_node("Triggers")
		npcs = content.get_node("ResourcesContent").get_node("NPCs")
		npc_token = Cache._loaded_scenes["NPCs"][0]
		create_settings_content()
		create_map_content()
		content.get_node("MapsContent").item_selected.connect(select_local_map)
		content.get_node("MapsContent").item_clicked.connect(on_specific_map_pressed)
		map_manager.open_map_changer.connect(show_map_names_in_context_menu)
		create_draw_content()
		create_resource_content()
		Bus.update_resource_content.connect(create_resource_content)
		Bus.delete_resource_content.connect(delete_resource_content)
		Bus.remove_token.connect(remove_token)
	is_initialized = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !is_initialized:
		return

	var map_index = map_manager.current_local_map if Net.is_host() else map_manager.current_map
	fill_actors_content(map_index)

	if current_content != null:
		content.custom_minimum_size.y = current_content.size.y

	# under here is update for gm
	if !Net.is_host():
		return
	# Updating the settings content based on the global settings (current map)
	if !Engine.is_editor_hint():
		illumination.get_node("Global Illumination").button_pressed = Settings.map_settings["global_illumination"]
		illumination.get_node("Global Color").get_node("ColorPicker").color = Settings.map_settings["global_illumination_color"]
		vision.get_node("Vision Color").get_node("ColorPicker").color = Settings.map_settings["global_vision_color"]
		vision.get_node("Vision Quality").get_node("Options").selected = Settings.RAY_COUNT_MAPPING.find(Settings.map_settings["global_vision_rays_count"])
		vision.get_node("Fog Color").get_node("ColorPicker").color = Settings.map_settings["global_fog_color"]

	if layers.get_node("Walls").button_pressed:
		for wall in get_tree().get_nodes_in_group("Walls"):
			wall.default_color.a = 1
	else:
		for wall in get_tree().get_nodes_in_group("Walls"):
			wall.default_color.a = 0.0

	if layers.get_node("Lights").button_pressed:
		for light in get_tree().get_nodes_in_group("Light_sprites"):
			light.z_index = 2
	else:
		for light in get_tree().get_nodes_in_group("Light_sprites"):
			light.z_index = -1

	if layers.get_node("Spawns").button_pressed:
		for spawn in get_tree().get_nodes_in_group("Spawn_sprites"):
			spawn.z_index = 2
	else:
		for spawn in get_tree().get_nodes_in_group("Spawn_sprites"):
			spawn.z_index = -1

	if layers.get_node("Triggers").button_pressed:
		for trigger in get_tree().get_nodes_in_group("Trigger_sprites"):
			trigger.z_index = 2
	else:
		for trigger in get_tree().get_nodes_in_group("Trigger_sprites"):
			trigger.z_index = -1
	if not is_instance_valid(sidebar_node) or not sidebar_node.is_visible_in_tree():
		# If the sidebar disappears or becomes invalid, ensure input is unpaused if it was paused by us
		if is_mouse_over:
			is_mouse_over = false
			map_manager.pause_input(false)
		return # Skip the rest of the check

	if not is_instance_valid(map_manager):
		return

	# Get the sidebar's rectangle in global coordinates (accounts for scale etc.)
	var sidebar_global_rect: Rect2 = sidebar_node.get_global_rect()
	# Get the current mouse position in viewport coordinates
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	# Check if the mouse is currently inside the correct global rectangle
	var currently_over: bool = sidebar_global_rect.has_point(mouse_pos)

	# --- State Change Logic ---
	if currently_over:
		# Mouse is currently over the sidebar
		if not is_mouse_over:
			# It just entered
			is_mouse_over = true
			map_manager.pause_input(true)
			# print("DEBUG: Mouse entered sidebar, pausing map input.")
	else:
		# Mouse is currently *not* over the sidebar
		if is_mouse_over:
			# It just exited
			is_mouse_over = false
			map_manager.pause_input(false)
			# print("DEBUG: Mouse exited sidebar, unpausing map input.")

func _input(event: InputEvent) -> void:
	if is_mouse_over and event is InputEventMouseButton:
			Bus.untoggle_all_drawings.emit() # Untoggle all drawings
			if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				print("Right click")
				map_manager.deselect_tile()
				if selected_actors.size() == 1:
					Bus.create_sidebar_context_panel.emit(actor_tokens.get_item_metadata(selected_actors[0]))
				elif selected_actors.size() > 1:
					var actors = []
					for act in selected_actors:
						actors.append(actor_tokens.get_item_metadata(act))
					Bus.create_sidebar_combat_context_panel.emit(actors)
				elif selected_token_data.size() > 0:
					Bus.create_sidebar_resource_panel.emit(selected_token_data)
	if !Input.is_key_pressed(KEY_SHIFT):
		if shift_action_started:
			npcs.deselect_all()
			selected_token_data = {}
			_untoggle_all_draw_content()
			is_currently_creating = false
			shift_action_started = false

	if is_currently_creating and event is InputEventMouseButton:
		var tile_pos = map_manager.convert_to_tilemap_global_pos(map_manager.get_mouse_position())
		var map_name = map_manager.get_map_name_from_index(map_manager.current_local_map)
		map_manager.deselect_tile()
		if !map_manager.is_inside_tilemap(map_manager.convert_to_tilemap_pos(map_manager.get_mouse_position())):
			return
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if Input.is_key_pressed(KEY_SHIFT):
					shift_action_started = true

					if is_creating["Spawn"]:
						map_manager.add_spawn_data.rpc(map_name, tile_pos)
						return
					elif is_creating["Light"]:
						map_manager.add_light_data.rpc(map_name, tile_pos)
						return
					elif is_creating["Terrain"]:
						map_manager.add_trigger_data.rpc(map_name, "Terrain", tile_pos)
						return
					elif is_creating["Settings"]:
						map_manager.add_trigger_data.rpc(map_name, "Settings", tile_pos)
						return
					elif is_creating["Message"]:
						map_manager.add_trigger_data.rpc(map_name, "Message", tile_pos)
						return
					elif is_creating["Condition"]:
						map_manager.add_trigger_data.rpc(map_name, "Condition", tile_pos)
						return
					elif is_creating["Sound"]:
						map_manager.add_trigger_data.rpc(map_name, "Sound", tile_pos)
						return
					elif is_creating["Wall"]:
						add_wall_point(map_manager.get_mouse_position(), map_name, false)
						return
					elif is_creating["Invisible Wall"]:
						add_wall_point(map_manager.get_mouse_position(), map_name, false, "Invisible Wall")
						return
					elif is_creating["Phantom Wall"]:
						add_wall_point(map_manager.get_mouse_position(), map_name, false, "Phantom Wall")
						return
					elif selected_token_data.size() > 0:
						if _check_if_token_exist_on_position(tile_pos):
							ErrorUtility.print_error("Token already exists on this position")
							return
						selected_token_data["position"] = tile_pos
						print(selected_token_data["sheet"])
						selected_token_data["id"] = Helper.generate_unique_id()
						map_manager.add_token_data.rpc(map_name, selected_token_data)
						return
			else:
				if !Input.is_key_pressed(KEY_SHIFT):
					if is_creating["Spawn"]:
						map_manager.add_spawn_data.rpc(map_name, tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Light"]:
						map_manager.add_light_data.rpc(map_name, tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Terrain"]:
						map_manager.add_trigger_data.rpc(map_name, "Terrain", tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Settings"]:
						map_manager.add_trigger_data.rpc(map_name, "Settings", tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Message"]:
						map_manager.add_trigger_data.rpc(map_name, "Message", tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Condition"]:
						map_manager.add_trigger_data.rpc(map_name, "Condition", tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Sound"]:
						map_manager.add_trigger_data.rpc(map_name, "Sound", tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Wall"]:
						add_wall_point(map_manager.get_mouse_position(), map_name, true)
						return
					elif is_creating["Invisible Wall"]:
						add_wall_point(map_manager.get_mouse_position(), map_name, true, "Invisible Wall")
						return
					elif is_creating["Phantom Wall"]:
						add_wall_point(map_manager.get_mouse_position(), map_name, true, "Phantom Wall")
						return
					elif selected_token_data.size() > 0:
						if _check_if_token_exist_on_position(tile_pos):
							ErrorUtility.print_error("Token already exists on this position")
							return
						selected_token_data["position"] = tile_pos
						selected_token_data["id"] = Helper.generate_unique_id()
						map_manager.add_token_data.rpc(map_name, selected_token_data)
						selected_token_data = {}
						is_currently_creating = false
						npcs.deselect_all()
						return
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if Input.is_key_pressed(KEY_SHIFT):
					shift_action_started = true

					if is_creating["Spawn"]:
						map_manager.remove_spawn_data.rpc(map_name, tile_pos)
						return
					elif is_creating["Light"]:
						var light = map_manager.get_light_at_position(map_manager.get_mouse_position())
						if light != null:
							map_manager.remove_light_data.rpc(map_name, light.light_index)
							return
					elif is_creating["Terrain"]:
						map_manager.remove_trigger_data.rpc(map_name, tile_pos)
						return
					elif is_creating["Settings"]:
						map_manager.remove_trigger_data.rpc(map_name, tile_pos)
						return
					elif is_creating["Message"]:
						map_manager.remove_trigger_data.rpc(map_name, tile_pos)
						return
					elif is_creating["Condition"]:
						map_manager.remove_trigger_data.rpc(map_name, tile_pos)
						return
					elif is_creating["Sound"]:
						map_manager.remove_trigger_data.rpc(map_name, tile_pos)
						return
					elif is_creating["Wall"]:
						select_wall()
						if selected_wall.size() > 0:
							map_manager.remove_wall_data.rpc(map_name, selected_wall)
							selected_wall = []
							return
					elif is_creating["Invisible Wall"]:
						select_wall()
						if selected_wall.size() > 0:
							map_manager.remove_wall_data.rpc(map_name, selected_wall)
							selected_wall = []
							return
					elif is_creating["Phantom Wall"]:
						select_wall()
						if selected_wall.size() > 0:
							map_manager.remove_wall_data.rpc(map_name, selected_wall)
							selected_wall = []
							return
					elif selected_token_data.size() > 0:
						var token = map_manager.get_token_at_position(map_manager.get_mouse_position())
						if token == null:
							printerr("Token not found")
							return
						map_manager.remove_token_data.rpc(map_name, token.name, token.global_position)
				if !Input.is_key_pressed(KEY_SHIFT):
					if is_creating["Spawn"]:
						map_manager.remove_spawn_data.rpc(map_name, tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Light"]:
						var light = map_manager.get_light_at_position(map_manager.get_mouse_position())
						if light != null:
							map_manager.remove_light_data.rpc(map_name, light.light_index)
							disable_currently_creating()
							return
					elif is_creating["Terrain"]:
						map_manager.remove_trigger_data.rpc(map_name, tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Settings"]:
						map_manager.remove_trigger_data.rpc(map_name, tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Message"]:
						map_manager.remove_trigger_data.rpc(map_name, tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Condition"]:
						map_manager.remove_trigger_data.rpc(map_name, tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Sound"]:
						map_manager.remove_trigger_data.rpc(map_name, tile_pos)
						disable_currently_creating()
						return
					elif is_creating["Wall"]:
						select_wall()
						if selected_wall.size() > 0:
							map_manager.remove_wall_data.rpc(map_name, selected_wall)
							selected_wall = []
							disable_currently_creating()
							return
					elif is_creating["Invisible Wall"]:
						select_wall()
						if selected_wall.size() > 0:
							map_manager.remove_wall_data.rpc(map_name, selected_wall)
							selected_wall = []
							disable_currently_creating()
							return
					elif is_creating["Phantom Wall"]:
						select_wall()
						if selected_wall.size() > 0:
							map_manager.remove_wall_data.rpc(map_name, selected_wall)
							selected_wall = []
							disable_currently_creating()
							return
					elif selected_token_data.size() > 0:
						var token = map_manager.get_token_at_position(map_manager.get_mouse_position())
						if token == null:
							printerr("Token not found")
							return
						map_manager.remove_token_data.rpc(map_name, token.name, token.global_position)
						selected_token_data = {}
						is_currently_creating = false
						npcs.deselect_all()
						return
# ===================== SETUP FUNCTIONS =====================

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
	illumination.get_node("Global Illumination").toggled.connect(set_global_illumination)
	illumination.get_node("Global Color").get_node("ColorPicker").color_changed.connect(set_global_illumination_color)
	illumination.get_node("Global Presets").get_node("Options").item_selected.connect(set_global_illumination_color_preset)
	vision.get_node("Vision Color").get_node("ColorPicker").color_changed.connect(set_global_vision_color)
	vision.get_node("Vision Quality").get_node("Options").item_selected.connect(set_global_vision_rays_count)
	vision.get_node("Fog Color").get_node("ColorPicker").color_changed.connect(set_global_fog_color)
	vision.get_node("Fog Presets").get_node("Options").item_selected.connect(set_global_fog_color_preset)
	layers.get_node("Lights").toggled.connect(func(toggled: bool): for l in get_tree().get_nodes_in_group("Light_sprites"): if toggled: l.z_index = 2 else: l.z_index = -1)
	layers.get_node("Spawns").toggled.connect(func(toggled: bool): for s in get_tree().get_nodes_in_group("Spawn_sprites"): if toggled: s.z_index = 2 else: s.z_index = -1)
	layers.get_node("Triggers").toggled.connect(func(toggled: bool): for s in get_tree().get_nodes_in_group("Trigger_sprites"): if toggled: s.z_index = 2 else: s.z_index = -1)
	layers.get_node("Walls").toggled.connect(func(toggled: bool): for s in get_tree().get_nodes_in_group("Walls"): if toggled: s.default_color.a = 1 else: s.default_color.a = 0.0)

func _untoggle_all_draw_content():
	for key in is_creating.keys():
		is_creating[key] = false
		if world_elements.has_node(key):
			world_elements.get_node(key).button_pressed = false
		if triggers.has_node(key):
			triggers.get_node(key).button_pressed = false

func create_draw_content():
	world_elements.get_node("Light").pressed.connect(create_light_resource)
	world_elements.get_node("Wall").pressed.connect(create_wall_resource)
	world_elements.get_node("Invisible Wall").pressed.connect(create_invisible_wall_resource)
	world_elements.get_node("Phantom Wall").pressed.connect(create_phantom_wall_resource)
	world_elements.get_node("Spawn").pressed.connect(create_spawn_resource)
	triggers.get_node("Message").pressed.connect(create_message_trigger)
	triggers.get_node("Terrain").pressed.connect(create_terrain_trigger)
	triggers.get_node("Settings").pressed.connect(create_settings_trigger)
	triggers.get_node("Condition").pressed.connect(create_condition_trigger)
	triggers.get_node("Sound").pressed.connect(create_sound_trigger)

# Change this to be based on the size of character sheet resource group size but using the same instance
func create_resource_content() -> void:
	npcs.clear()
	npcs.add_item("Base NPC", load("res://Assets/Tokens/Default/Default.webp"))
	npcs.set_item_metadata(0, {"sheet": null})
	npcs.item_selected.connect(select_token)
	for i in ExternalUtility.get_all_files_in_dir("user://Assets/NPCs/"):
		var file = ExternalUtility.get_json_file("user://Assets/NPCs/" + i, false)
		if file != null:
			npcs.add_item(file["sheet"].monster_name, load(file["texture"]))
			npcs.set_item_metadata(npcs.get_item_count() - 1, file["sheet"])

func delete_resource_content(resource: Variant) -> void:
	if resource.has("sheet"):
		ExternalUtility.delete_json_file("user://Assets/NPCs/", resource["sheet"].monster_name + ".json")
	create_resource_content()

func create_activity_content() -> void:
	content.get_node("ActivityContent").get_child(0).pressed.connect(clear_activities)

func fill_actors_content(index: int) -> void:
	var players = get_tree().get_nodes_in_group("players")
	var npcss = get_tree().get_nodes_in_group("npc")
	for player in players:
		if !map_manager.is_token_on_map(player, index):
			players.remove_at(players.find(player))

	for npc in npcss:
		if !map_manager.is_token_on_map(npc, index):
			npcss.remove_at(npcss.find(npc))

	var combined_size = players.size() + npcss.size()
	
	if previous_actor_size != combined_size:
		previous_actor_size = combined_size
		actor_tokens.clear()


		for player in players:
			actor_tokens.add_item(player.character_sheet.get_unit_name(), player.get_node("Sprite2D").texture)
			actor_tokens.set_item_metadata(actor_tokens.get_item_count() - 1, player)

		if Net.is_host():
			for npc in npcss:
				actor_tokens.add_item(npc.character_sheet.get_unit_name(), npc.get_node("Sprite2D").texture)
				actor_tokens.set_item_metadata(actor_tokens.get_item_count() - 1, npc)

func create_actors_content() -> void:
	actor_tokens.multi_selected.connect(_on_actor_selected)

func _on_actor_selected(index: int, state: bool) -> void:
	if state:
		selected_actors.append(index)
	else:
		selected_actors.remove_at(selected_actors.find(index))

# ===================== CORE FUNCTIONS =====================

# Select a map from the sidebar that will be displayed for the local player
# Args: int - The index of the map in the map_data dictionary
# Returns: None
func select_local_map(index: int) -> void:
	if is_loading:
		return

	if map_manager != null and !map_manager.is_current_local_map(index):
		Net.show_loading_screen()
		map_manager.set_current_local_map.rpc(index)
		await map_manager.create_local_map(map_data[index]["name"])
		Net.hide_loading_screen()
		content.get_node("MapsContent").deselect_all()

func select_map(index: int) -> void:
	if map_manager != null and !map_manager.is_current_map(index) and !map_manager.is_changing_map:
		map_manager.set_current_map.rpc(index)
		map_manager.create_map.rpc((map_data[index]["name"]))
		await map_manager.map_created
		content.get_node("MapsContent").deselect_all()

func select_player_map(player_id: int, index: int) -> void:
	if map_manager != null:
		map_manager.set_player_current_map.rpc(player_id, index)
		map_manager.create_map.rpc_id(player_id, (map_data[index]["name"]))
		await map_manager.map_created
		content.get_node("MapsContent").deselect_all()

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

func create_light_resource():
	set_currently_creating("Light")

func create_wall_resource():
	set_currently_creating("Wall")

func create_invisible_wall_resource():
	set_currently_creating("Invisible Wall")

func create_phantom_wall_resource():
	set_currently_creating("Phantom Wall")

func create_spawn_resource():
	set_currently_creating("Spawn")

func create_message_trigger():
	set_currently_creating("Message")

func create_terrain_trigger():
	set_currently_creating("Terrain")

func create_settings_trigger():
	set_currently_creating("Settings")

func create_condition_trigger():
	set_currently_creating("Condition")

func create_sound_trigger():
	set_currently_creating("Sound")

func add_wall_point(point: Vector2, map_name: String, disable: bool, type: String = "Normal Wall") -> void:
	if wall_data.has("start"):
		wall_data["end"] = map_manager.get_closest_corner(point)
		var wall_array = [wall_data["start"], wall_data["end"]]
		map_manager.add_wall_data.rpc(map_name, wall_array, type)
		wall_data = {}
		if disable:
			disable_currently_creating()
	else:
		wall_data["start"] = map_manager.get_closest_corner(point)

func select_wall() -> void:
	for wall in get_tree().get_nodes_in_group("Walls"):
		var line_rect = get_line2d_rect(wall, true).grow(5)
		if line_rect.has_point(map_manager.get_mouse_position()):
			if wall in selected_wall:
				print("Removing wall")
				selected_wall.remove_at(0)
			else:
				print("Adding wall")
				selected_wall.append_array(wall.points)
	print("Selected Walls: " + str(selected_wall))

func select_token(index: int) -> void:
	print("Selected Token: " + str(index))
	is_currently_creating = true
	selected_token_data = {"texture": npcs.get_item_icon(index).resource_path, "name":  npcs.get_item_text(index), "index": index}
	if npcs.get_item_metadata(index) != null:
		selected_token_data["sheet"] = npcs.get_item_metadata(index)

func remove_token(token_name: String, token_position: Vector2) -> void:
	var map_index = map_manager.current_local_map
	var map_name = map_manager.get_map_name_from_index(map_index)
	if map_manager != null:
		map_manager.remove_token_data.rpc(map_name, token_name, token_position)

@rpc("any_peer", "call_local", "reliable")
func create_dice_activity(
	sender: String,
	info: String,
	target_name: String,
	roll_data: Dictionary, # Pass the whole DiceManager result
	target_value_desc: String, # e.g., "vs AC 15" or "vs Roll 12"
	outcome: String
) -> void:
	if not activity_context_scene:
		printerr("create_dice_activity: activity_context_scene is not loaded!")
		return
	if not activity_container:
		printerr("create_dice_activity: activity_container node not found!")
		return
	if not roll_data or not roll_data.get("success", false):
		printerr("create_dice_activity: Invalid or failed roll_data received.")
		# Optionally create an error message entry here
		return

	var context = activity_context_scene.instantiate()

	# --- Populate the UI elements ---
	# Basic Info
	_set_context_text(context, "Name", sender)
	_set_context_text(context, "Information", info)
	_set_context_text(context, "TargetName", target_name)

	_set_context_text(context, "Formula", roll_data.get("formula", "N/A")) # Show the dice string used
	_set_context_text(context, "TotalRoll", str(roll_data.get("total", "?")) + " " + target_value_desc) # Show the final total

	var breakdown_text = _format_roll_details(roll_data)
	context.get_node("TotalRoll").tooltip_text = breakdown_text

	print("test")
	# Result/Outcome
	var result_node = context.get_node_or_null("Result")
	if result_node:
		result_node.text = outcome
		# Set color based on outcome - you might want more specific colors
		match outcome.to_lower():
			"success":
				result_node.modulate = Color.GREEN_YELLOW # Or Color(0, 1, 0)
			"critical hit", "critical success":
				result_node.modulate = Color.GOLD # Or a brighter green
			"failure":
				result_node.modulate = Color.CRIMSON # Or Color(1, 0, 0)
			"critical failure", "fumble":
				result_node.modulate = Color.DARK_RED # Or a darker red
			_: # Partial success, other states
				result_node.modulate = Color(1,1,1,1)
	else:
		printerr("create_dice_activity: Could not find 'Result' node in context.")

	activity_container.add_child(context)

func clear_activities() -> void:
	for a in range(1, content.get_node("ActivityContent").get_child_count()):
		content.get_node("ActivityContent").get_child(a).queue_free()


# ===================== HELPER FUNCTIONS =====================

## Helper to safely set text on a child node.
func _set_context_text(context_node, child_path: String, text: String) -> void:
	var node = context_node.get_node_or_null(child_path)
	if node and node.has_method("set_text"): # Check if it's a Label, RichTextLabel, etc.
		node.set_text(text)
	elif node and node.has_meta("text"): # Check for custom property maybe?
		node.set_meta("text", text)
	else:
		printerr("create_dice_activity: Could not find or set text for node '%s'." % child_path)

## Helper function to create a readable string breakdown of the roll terms.
func _format_roll_details(roll_data: Dictionary) -> String:
	if not roll_data or not roll_data.has("terms"):
		return ""

	var parts: PackedStringArray = []
	for term in roll_data.get("terms", []):
		var term_desc = term.get("description", "?")
		var term_val = term.get("value", 0)
		var term_rolls = term.get("rolls", [])

		var part_str = term_desc # Start with "+2d6" or "-5" etc.
		if not term_rolls.is_empty():
			# For dice terms, show the rolls that led to the value
			# Ensure the value shown here is the *base* value before sign multiplier
			# The DiceManager's 'value' already includes the sign, which might be confusing here.
			# Let's recalculate the sum of rolls for clarity in the breakdown.
			var rolls_sum = 0
			for r in term_rolls: rolls_sum += r
			part_str += " " + str(term_rolls).replace(" ","") # Compact "[5,3]"

		parts.append(part_str)

	# Join parts and add the total
	return " ".join(parts) + " = " + str(roll_data.get("total", "?"))

func get_line2d_rect(line: Line2D, use_global: bool = false) -> Rect2:
	# Make sure the line has points
	var point_count = line.points.size()  # Godot 4.x syntax
	if point_count == 0:
		print("Line has no points")
		return Rect2()
	
	# Consider line width (half extends on each side)
	var half_width = line.width / 2.0
	
	# Start with the first point
	var point = line.points[0]
	var min_pos = Vector2(point.x - half_width, point.y - half_width)
	var max_pos = Vector2(point.x + half_width, point.y + half_width)
	
	# Find min/max of all points
	for i in range(1, point_count):
		point = line.points[i]
		
		min_pos.x = min(min_pos.x, point.x - half_width)
		min_pos.y = min(min_pos.y, point.y - half_width)
		max_pos.x = max(max_pos.x, point.x + half_width)
		max_pos.y = max(max_pos.y, point.y + half_width)
	
	# Create the local rect
	var rect = Rect2(min_pos, max_pos - min_pos)
	
	# Convert to global coordinates if requested (Godot 4.x syntax)
	if use_global:
		var global_pos = line.global_transform * rect.position
		var global_end = line.global_transform * (rect.position + rect.size)
		return Rect2(global_pos, global_end - global_pos)
	
	return rect

# Set the content name (Activity, Resources, Actors, Maps, Draw, Settings), this changes the content in the sidebar
# Args: String - The name of the content
# Returns: None
func set_content_name(na: String) -> void:
	current_content_name = na
	content_name.text = "[center]" + current_content_name + "[/center]"
	if content.has_node(current_content_name + "Content"):
		current_content = content.get_node(current_content_name + "Content")
	set_all_content_visibility()
	disable_currently_creating()
	clear_currently_creating()

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
	draw.disabled = !Net.is_host()

func show_map_names_in_context_menu(player_id) -> void:
	print("Player ID: " + str(player_id))
	var context = context_panel.new()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.create_panel(map_manager.get_viewport().get_mouse_position())
	for index in map_data.keys():
		context.add_button(map_data[index]["name"], select_player_map.bind(player_id, index))

func set_currently_creating(type: String) -> void:
	for key in is_creating.keys():
		if key == type:
			continue
		var parent = world_elements if key in ["Light", "Wall", "Invisible Wall", "Phantom Wall", "Spawn"] else triggers
		is_creating[key] = false
		parent.get_node(key).button_pressed = false
	is_creating[type] = true
	is_currently_creating = true
	print("Creating: " + type)

func disable_currently_creating() -> void:
	for key in is_creating.keys():
		var parent = world_elements if key in ["Light", "Wall", "Invisible Wall", "Phantom Wall", "Spawn"] else triggers
		if parent == null:
			continue
		is_creating[key] = false
		parent.get_node(key).button_pressed = false
	is_currently_creating = false

func clear_currently_creating() -> void:
	selected_wall.clear()
	wall_data = {}
	selected_token_data = {}
	selected_actors.clear()
	if npcs != null:
		npcs.deselect_all()
	if actor_tokens != null:
		actor_tokens.deselect_all()

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
		if get_tree().get_nodes_in_group("Panels").size() > 0:
			return
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
	is_mouse_over = true
	if map_manager != null:
		map_manager.pause_input(true)

# When the sidebar is hovered out, unpause the input for the map manager
# Args: None
# Returns: None
func _on_sidebar_mouse_exited() -> void:
	is_mouse_over = false
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

func _check_if_token_exist_on_position(position: Vector2) -> bool:
	var token = map_manager.get_token_at_position(position)
	if token != null:
		return true
	return false
