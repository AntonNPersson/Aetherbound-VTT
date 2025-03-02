extends Node

# ===================== LOBBY CONTROLLS =====================
# Manages the lobby UI, works with the LobbyManager to manage the players

var sub_menu: Control = null
var menu: Variant = null

const CONNECTION_TIMEOUT = 5.0

# ===================== CORE FUNCTIONS =====================
func _ready() -> void:
	menu = get_node("MenuUI")
	sub_menu =	menu.get_node("Sub Menu")
	Net.player_connected.connect(set_player_names)
	Net.player_connection_failed.connect(connection_failed)
	menu.get_node("Menu").get_node("Host").pressed.connect(open_host_game)
	menu.get_node("Menu").get_node("Join").pressed.connect(open_join_game)
	menu.get_node("Menu").get_node("Exit").pressed.connect(exit_game)
	sub_menu.get_node("Start Button").pressed.connect(start_game)
	sub_menu.get_node("Configs").get_node("GMPlayer").toggled.connect(set_gm_player_state)
	Settings.prologue_map = ExternalUtility.get_first_file_in_dir("user://Assets/Maps").replace(".jpg", "")

func _process(_delta):
	if Net.get_player_count() >= 1 and Net.is_host():
		enable_start_game()
	else:
		disable_start_game()
# ===================== HELPER FUNCTIONS =====================
# Open the host game menu
# Args: None
# Returns: None
func open_host_game() -> void:
	print("Open Host Game")
	if sub_menu.container_name == "Host Game" and sub_menu.visible:
		sub_menu.visible = false
		return

	sub_menu.visible = true
	sub_menu.container_name = "Host Game"
	menu.get_node("Menu").get_node("Join").button_pressed = false
	sub_menu.get_node("Menu Name").text = "HOST GAME"
	sub_menu.get_node("Button").text = "HOST"

	for control in sub_menu.get_children():
		control.visible = false

	for control in get_tree().get_nodes_in_group("Host"):
		control.visible = true

	add_prologue_options()

	if sub_menu.get_node("Button").pressed.is_connected(join_game):
		sub_menu.get_node("Button").pressed.disconnect(join_game)

	if sub_menu.get_node("Button").pressed.is_connected(host_game):
		return
	sub_menu.get_node("Button").pressed.connect(host_game)

# Open the join game menu
# Args: None
# Returns: None
func open_join_game() -> void:
	if sub_menu.container_name == "Join Game" and sub_menu.visible:
		sub_menu.visible = false
		return

	sub_menu.visible = true
	sub_menu.container_name = "Join Game"
	menu.get_node("Menu").get_node("Host").button_pressed = false
	sub_menu.get_node("Menu Name").text = "JOIN GAME"
	sub_menu.get_node("Button").text = "JOIN"

	for control in sub_menu.get_children():
		control.visible = false

	for control in get_tree().get_nodes_in_group("Join"):
		control.visible = true

	if sub_menu.get_node("Button").pressed.is_connected(host_game):
		sub_menu.get_node("Button").pressed.disconnect(host_game)

	if sub_menu.get_node("Button").pressed.is_connected(join_game):
		return
	sub_menu.get_node("Button").pressed.connect(join_game)

# Open the join game menu
# Args: None
# Returns: None
func host_game() -> void:
	set_peer_name(sub_menu.get_node("Peer Name").get_node("Input").text)
	Net.create_game()
	set_button_state(false)

# Open the join game menu
# Args: None
# Returns: None
func join_game() -> void:
	set_peer_name(sub_menu.get_node("Peer Name").get_node("Input").text)
	Net.join_game()
	set_loading(true)
	set_button_state(false)

func connection_failed() -> void:
	print("Connection failed")
	set_loading(false)
	set_button_state(true)

# Start the game
# Args: None
# Returns: None
func start_game() -> void:
	Net.load_game("res://Scenes/Game.tscn", self)

# Exit the game
# Args: None
# Returns: None
func exit_game() -> void:
	get_tree().quit()

# Enable the start game button
# Args: None
# Returns: None
func enable_start_game() -> void:
	sub_menu.get_node("Start Button").disabled = false

# Disable the start game button
# Args: None
# Returns: None
func disable_start_game() -> void:
	sub_menu.get_node("Start Button").disabled = true

# Set the player names
# Args: Array - The player names
# Returns: None
func set_player_names(_player_id: int, _player_info: Dictionary) -> void:
	var player_names = ""
	for player in Net.get_player_names(): player_names += player + ", "
	menu.get_node("Info").text = "Host: " + Net.get_host_name() + "\nPlayers: " + player_names
	set_loading(false)

# Set the peer name
# Args: String - The peer name
# Returns: None
func set_peer_name(peer_name: String) -> void:
	Net.player_info["name"] = peer_name

# Set the loading state
# Args: bool - The loading state
# Returns: None
func set_loading(loading: bool) -> void:
	sub_menu.get_node("Loading").visible = loading

# Set the button state
# Args: bool - The button state
# Returns: None
func set_button_state(state: bool) -> void:
	sub_menu.get_node("Button").disabled = !state

func set_prologue_map(index: int) -> void:
	Settings.prologue_map = sub_menu.get_node("StartingMap").get_node("Maps").get_item_text(index)

func set_gm_player_state(enabled: bool) -> void:
	Settings.is_player = enabled

# Add the prologue options
# Args: None
# Returns: None
func add_prologue_options() -> void:
	sub_menu.get_node("StartingMap").get_node("Maps").clear()

	var maps_folder_path = "user://Assets/Maps"
	var map_names = ExternalUtility.get_all_files_in_dir(maps_folder_path)
	for map_name in map_names:
		var clean_map_name = map_name.replace(".jpg", "")
		sub_menu.get_node("StartingMap").get_node("Maps").add_item(clean_map_name)

	if sub_menu.get_node("StartingMap").get_node("Maps").item_selected.is_connected(set_prologue_map):
		return
	sub_menu.get_node("StartingMap").get_node("Maps").item_selected.connect(set_prologue_map)
