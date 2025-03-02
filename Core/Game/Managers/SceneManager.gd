extends Node
# ===================== SCENE MANAGER =====================
# Manages the scenes in the game
# ========================================================

@export var player_scene: PackedScene = null
@export var camera_scene: PackedScene = null

@export var map_manager: Node = null

# ===================== CORE FUNCTIONS =====================
func _ready() -> void:
	if Net.is_host():
		initialize_ui()
		map_manager.initialize_local_map()

	map_manager.map_initialized.connect(initialize_ui)
	initialize_players()
	initialize_camera()

# ===================== HELPER FUNCTIONS =====================

# Initialize the players, and set the start position
# Args: None
# Returns: None
func initialize_players() -> void:
	var index = 0
	for player_id in Net.get_sorted_player_ids():
		var current_player = player_scene.instantiate()
		current_player.name = str(player_id)
		current_player.map = map_manager
		add_child(current_player)
		if player_id == 1 and !Settings.is_player:
			remove_gamemaster(current_player)
		else:
			map_manager.map_data[0]["tokens"].append(current_player)

		for spawn in get_tree().get_nodes_in_group("Player Spawn"):
			if spawn.name == str(index):
				current_player.global_position = spawn.global_position
		index += 1

# Initialize the camera, and set the current player
# Args: None
# Returns: None
func initialize_camera() -> void:
	var camera = camera_scene.instantiate()
	var local_player = get_node(str(multiplayer.get_unique_id()))
	add_child(camera)
	local_player.player_camera = camera
	camera.make_current()
	camera.global_position = local_player.global_position

func initialize_ui() -> void:
	get_tree().root.get_node("Root").get_node("Loading Screen").hide()
	get_tree().root.get_node("Root").get_node("GameUI").show()
	var sidebar = get_tree().root.get_node("Root").get_node("GameUI").get_node("Sidebar")
	sidebar.map_manager = map_manager
	sidebar._initialize()

func remove_gamemaster(token) -> void:
	token.hide()
	token.remove_from_group("token")
	token.remove_from_group("players")


# Hide the loading screen
# Args: None
# Returns: None
func hide_loading_screen() -> void:
	get_tree().root.get_node("Root").get_node("Loading Screen").hide()
