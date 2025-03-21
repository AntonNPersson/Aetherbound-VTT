extends Node2D

# ===================== GM MANAGER =====================
# Manages the game master, and the settings that 
# the gm can control for the game. I might need to change
# how this works in the future, like adding unique ids
# to the map settings saved, that corresponds with a
# unique id for a specific map.
# ======================================================
var map_settings: Dictionary = {}
var current_local_map: int = 0
var current_map: int = 0

var player_current_maps: Dictionary = {}

@export var global_light: Node = null
@export var players_parent: Node = null
@export var map: Node = null


# ===================== CORE FUNCTIONS =====================
func _ready():
	if Net.is_host():
		map.map_changed.connect(change_map_settings)
		map.data_added.connect(_load)
		self.add_to_group("Savable")
		current_local_map = Settings.prologue_index
		current_map = Settings.prologue_index

	Bus.apply_map_settings_to_player.connect(apply_map_settings_to_player)

# Change the map settings
# Args: map_index: int, local: bool
# Returns: None
func change_map_settings(map_index: int, local: bool, player_ids: Array) -> void:

	if local:
		save_map_settings()
		current_local_map = map_index
		set_local_map.rpc(map_index)
	elif player_ids.size() <= 0:
		current_map = map_index
		set_current_map.rpc(map_index)
	else:
		for id in player_ids:
			player_current_maps[id] = map_index
			set_player_current_map.rpc(id, map_index)

	var settings
	if map_settings_has_name(map.get_map_name_from_index(map_index)):
		settings = map_settings[map_index]["Settings"]
	else:
		settings = Settings.default_map_settings
	
	if local:
		apply_local_map_settings(settings)
	elif player_ids.size() <= 0:
		for token in get_all_player_tokens():
			if map.is_token_on_map(token, current_map):
				apply_map_settings_to_player(token.name.to_int(), settings)
	else:
		for id in player_ids:
			if map.is_token_on_map(get_player_token(id), player_current_maps[id]):
				apply_map_settings_to_player(id, settings)

# ===================== HELPER FUNCTIONS =====================

# Apply the local map settings
# Args: settings: Dictionary
# Returns: None
func apply_local_map_settings(settings: Dictionary) -> void:
	set_global_illumination(settings["global_illumination"])
	set_global_illumination_color(settings["global_illumination_color"])
	set_global_fog_color(settings["global_fog_color"])
	set_global_vision_rays_count(Settings.RAY_COUNT_MAPPING.find(settings["global_vision_rays_count"]))
	set_global_vision_color(settings["global_vision_color"])

func apply_map_settings_to_player(player_id: int, settings: Dictionary) -> void:
	if settings.has("global_illumination"):
		set_global_illumination.rpc_id(player_id, settings["global_illumination"])
	if settings.has("global_illumination_color"):
		set_global_illumination_color.rpc_id(player_id, settings["global_illumination_color"])
	if settings.has("global_fog_color"):
		set_global_fog_color.rpc_id(player_id, settings["global_fog_color"])
	if settings.has("global_vision_rays_count"):
		set_global_vision_rays_count.rpc_id(player_id, Settings.RAY_COUNT_MAPPING.find(settings["global_vision_rays_count"]))
	set_player_vision_color(player_id, settings["global_vision_color"])

# Save the map settings in the dictionary, if it doesnt exist, check for _save files and load them, if not, create a new one
# Args: None
# Returns: None
func save_map_settings() -> void: 
	if map_settings_has_name(map.get_map_name_from_index(current_local_map)):
		map_settings[current_local_map]["Settings"] = Settings.map_settings.duplicate()
	else:
		map_settings[current_local_map] = {"name": map.get_map_name_from_index(current_local_map), "Settings": Settings.map_settings.duplicate()}


# ===================== RPC FUNCTIONS =====================
# Set the global illumination of specific scene
# Args: enabled: bool
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_global_illumination(enabled: bool) -> void:

	Settings.map_settings["global_illumination"] = enabled

	if !Net.is_host():
		set_players_line_of_sight(!enabled)
		update_players_line_of_sight()
	else:
		save_map_settings()

# Set the global fog of specific scene
# Args: enabled: bool
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_global_illumination_color(color: Color) -> void:

	Settings.map_settings["global_illumination_color"] = color
	global_light.material.set_shader_parameter("background_tint", color)

	if !Net.is_host():
		update_players_line_of_sight()
	else:
		save_map_settings()

# Set the global fog of specific scene
# Args: enabled: bool
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_global_fog_color(color: Color) -> void:

	Settings.map_settings["global_fog_color"] = color

	if !Net.is_host():
		update_players_line_of_sight()
	else:
		save_map_settings()

# Set the global vision of specific scene
# Args: enabled: bool
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_global_vision_rays_count(count: int) -> void:

	Settings.map_settings["global_vision_rays_count"] = Settings.RAY_COUNT_MAPPING[count]

	if !Net.is_host():
		update_players_line_of_sight()
	else:
		save_map_settings()

# Set the local map
# Args: index: int
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_local_map(index: int) -> void:
	current_local_map = index

# Set the current map
# Args: index: int
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_current_map(index: int) -> void:
	current_map = index

@rpc("any_peer", "call_local", "reliable")
func set_player_current_map(player_id: int, index: int) -> void:
	player_current_maps[player_id] = index

# Set the global vision of specific scene
# Args: enabled: bool
# Returns: None
func set_global_vision_color(color: Color) -> void:
	Settings.map_settings["global_vision_color"] = color
	for player in get_all_player_tokens():
		player.set_vision_color.rpc_id(player.name.to_int(), color, current_map, current_local_map)

func set_player_vision_color(player_id: int, color: Color) -> void:
	if player_current_maps.size() > 0:
		get_player_token(player_id).set_vision_color.rpc_id(player_id, color, player_current_maps[player_id], current_local_map)

# ===================== PLAYER FUNCTIONS =====================
# Players

# Get the player token by player id
# Args: player_id: int
# Returns: Node2D
func get_player_token(player_id: int) -> Node2D:
	return players_parent.get_node(str(player_id))

# Get all player tokens
# Args: None
# Returns: Array
func get_all_player_tokens() -> Array:
	var all_players = []
	for player_id in Net.get_players_ids():
		all_players.append(get_player_token(player_id))
	return all_players

# Update the players line of sight
# Args: None
# Returns: None
func update_players_line_of_sight():
	for player in get_all_player_tokens():
		player.update_line_of_sight()

# Set the players line of sight
# Args: enabled: bool
# Returns: None
func set_players_line_of_sight(enabled: bool):
	for player in get_all_player_tokens():
		if enabled:
			player.show_line_of_sight()
		else:
			player.hide_line_of_sight()

# Check if the map settings has the name
# Args: map_name: String
# Returns: bool
func map_settings_has_name(map_name: String) -> bool:
	for key in map_settings.keys():
		if map_settings[key]["name"] == map_name:
			return true
	return false

# ===================== SETTINGS FUNCTIONS =====================
# Save the settings for the map, this is saved to a json file only on the host
# Args: None
# Returns: None
func _save(): 
	save_map_settings()
	ExternalUtility.save_json_file("user://Settings/MapSettings.json", map_settings)

# Load the settings for the map, this is from json file that is saved
# Args: map_name: String
# Returns: bool
func _load() -> void:
	var loaded_settings = _process_settings(ExternalUtility.get_json_file("user://Settings/MapSettings.json", false))
	for key in loaded_settings.keys():
		map_settings[map.get_map_index_from_name(key)] = {"name": key, "Settings": loaded_settings[key]}

	_load_for_peers.rpc(map_settings)

	apply_local_map_settings(map_settings[current_local_map]["Settings"])
	for id in Net.get_players_ids():
		apply_map_settings_to_player(id, map_settings[current_local_map]["Settings"])

@rpc("any_peer", "call_remote", "reliable")
func _load_for_peers(map_sett: Dictionary) -> void:
	map_settings = map_sett

# Process the settings, turning them into the correct types
# Args: settings: Dictionary
# Returns: Dictionary
func _process_settings(settings: Dictionary) -> Dictionary:
	var processed_settings = {}

	for key in settings.keys():
		processed_settings[key] = settings[key]
		for sub_key in settings[key].keys():
			if sub_key == "global_illumination_color" or sub_key == "global_fog_color" or sub_key == "global_vision_color":
				processed_settings[key][sub_key] = Color(settings[key][sub_key][0], settings[key][sub_key][1], settings[key][sub_key][2], settings[key][sub_key][3])
			elif sub_key == "global_vision_rays_count":
				processed_settings[key][sub_key] = int(settings[key][sub_key])

	return processed_settings
