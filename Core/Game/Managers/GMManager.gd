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

@export var global_light: Node = null
@export var players_parent: Node = null
@export var map: Node = null


# ===================== CORE FUNCTIONS =====================
func _ready():
    if Net.is_host():
        map.map_initialized.connect(initialize)
        map.map_changed.connect(change_map_settings)

# Initialize the map
# Args: None
# Returns: None
func initialize():
    change_map_settings(0, false)

# Change the map settings
# Args: map_index: int, local: bool
# Returns: None
func change_map_settings(map_index: int, local: bool) -> void:
    save_map_settings()

    if local:    
        current_local_map = map_index
        set_local_map.rpc(map_index)
    else:
        current_map = map_index
        set_current_map.rpc(map_index)

    var settings
    if map_settings_has_name(map.get_map_name_from_index(current_local_map)):
        settings = map_settings[current_local_map]["Settings"]
    else:
        settings = Settings.default_map_settings
    
    if local:
        apply_local_map_settings(settings)
    else:
        apply_map_settings(settings)

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

# Apply the map settings
# Args: settings: Dictionary
# Returns: None
func apply_map_settings(settings: Dictionary) -> void:
    set_global_illumination.rpc(settings["global_illumination"])
    set_global_illumination_color.rpc(settings["global_illumination_color"])
    set_global_fog_color.rpc(settings["global_fog_color"])
    set_global_vision_rays_count.rpc(Settings.RAY_COUNT_MAPPING.find(settings["global_vision_rays_count"]))
    set_global_vision_color(settings["global_vision_color"])

# Save the map settings in the dictionary, if it doesnt exist, check for save files and load them, if not, create a new one
# Args: None
# Returns: None
func save_map_settings() -> void: 
    if map_settings_has_name(map.get_map_name_from_index(current_local_map)):
        map_settings[current_local_map]["Settings"] = Settings.map_settings.duplicate()
    else:
        if !loads(map.get_map_name_from_index(current_local_map)):
            map_settings[current_local_map] = {
                "name": map.get_map_name_from_index(current_local_map),
                "Settings": Settings.map_settings.duplicate()
            }


# ===================== RPC FUNCTIONS =====================
# Set the global illumination of specific scene
# Args: enabled: bool
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_global_illumination(enabled: bool) -> void:
    if current_local_map != current_map and !Net.is_host():
        return

    Settings.map_settings["global_illumination"] = enabled
    global_light.visible = enabled

    if !Net.is_host():
        set_players_line_of_sight(!enabled)

# Set the global fog of specific scene
# Args: enabled: bool
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_global_illumination_color(color: Color) -> void:
    if current_local_map != current_map and !Net.is_host():
        return

    Settings.map_settings["global_illumination_color"] = color
    global_light.color = color

    if !Net.is_host():
        update_players_line_of_sight()

# Set the global fog of specific scene
# Args: enabled: bool
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_global_fog_color(color: Color) -> void:
    if current_local_map != current_map and !Net.is_host():
        return

    Settings.map_settings["global_fog_color"] = color

    if !Net.is_host():
        update_players_line_of_sight()

# Set the global vision of specific scene
# Args: enabled: bool
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_global_vision_rays_count(count: int) -> void:
    if current_local_map != current_map and !Net.is_host():
        return

    Settings.map_settings["global_vision_rays_count"] = Settings.RAY_COUNT_MAPPING[count]

    if !Net.is_host():
        update_players_line_of_sight()

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

# Set the global vision of specific scene
# Args: enabled: bool
# Returns: None
func set_global_vision_color(color: Color) -> void:
    Settings.map_settings["global_vision_color"] = color
    for player in get_all_player_tokens():
        player.set_vision_color.rpc_id(player.name.to_int(), color, current_map, current_local_map)

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
func save(): 
    ExternalUtility.save_json_file("user://Settings/MapSettings.json", map_settings)

# Load the settings for the map, this is from json file that is saved
# Args: map_name: String
# Returns: bool
func loads(map_name: String) -> bool:
    var loaded_settings = process_settings(ExternalUtility.get_json_file("user://Settings/MapSettings.json", false))
    for key in loaded_settings.keys():
        print(key)
        if key == map_name:
            map_settings[map.get_map_index_from_name(map_name)] = {"name": key, "Settings": loaded_settings[key]}
            print("Loaded settings for map: " + key)
            return true
    return false

# Process the settings, turning them into the correct types
# Args: settings: Dictionary
# Returns: Dictionary
func process_settings(settings: Dictionary) -> Dictionary:
    var processed_settings = {}

    for key in settings.keys():
        processed_settings[key] = settings[key]
        for sub_key in settings[key].keys():
            if sub_key == "global_illumination_color" or sub_key == "global_fog_color" or sub_key == "global_vision_color":
                processed_settings[key][sub_key] = Color(settings[key][sub_key][0], settings[key][sub_key][1], settings[key][sub_key][2], settings[key][sub_key][3])
            elif sub_key == "global_vision_rays_count":
                processed_settings[key][sub_key] = int(settings[key][sub_key])

    return processed_settings

# CHANGE THIS TO THE EXIT BUTTON IN THE UI IN THE FUTURE
# Save the settings when the game is closed
# Args: None
# Returns: None
func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        save()
        get_tree().quit()