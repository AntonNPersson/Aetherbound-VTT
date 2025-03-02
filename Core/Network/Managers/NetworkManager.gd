extends Node
# ===================== NETWORK MANAGER =======================
# All functions, variables and signals related to the network
# =============================================================

# ===================== LOBBY VARIABLES =======================
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected()

# ===================== PLAYER VARIABLES ======================
# Variables
var players: Dictionary = {}
var player_info: Dictionary = {"name": "Default"}

# ===================== SCENE VARIABLES/SIGNALS ===============
# Variables
var players_loaded: int = 0

# Signals
signal all_players_loaded()
signal player_connection_failed()

# ===================== CORE FUNCTIONS ========================
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ===================== LOBBY FUNCTIONS =======================
# Join a game with the given address
# Args: String - The address of the server
# Returns: None
func join_game(address: String = "") -> void:
	if address.is_empty():
		address = NetworkConst.DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, NetworkConst.PORT)
	if error:
		ErrorUtility.log_error("Error: " + str(error))
		return
	multiplayer.multiplayer_peer = peer

# Create a game
# Args: None
# Returns: None
func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(NetworkConst.PORT, NetworkConst.MAX_CONNECTIONS)
	if error:
		ErrorUtility.log_error("Error: " + str(error))
		return
	ErrorUtility.log_info("Server successfully created!")
	multiplayer.multiplayer_peer = peer

	players[1] = Net.player_info
	player_connected.emit(1, Net.player_info)

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null

# Register a new player
# Args: Dictionary - The player information
# Returns: None
@rpc("any_peer", "reliable")
func _register_player(new_player_info: Dictionary) -> void:
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

# When a player connects
# Args: int - The peer id of the player
# Returns: None
func _on_player_connected(peer_id: int) -> void:
	_register_player.rpc_id(peer_id, Net.player_info)

# When a player disconnects
# Args: int - The peer id of the player
# Returns: None
func _on_player_disconnected(peer_id: int) -> void:
	players.erase(peer_id)
	player_disconnected.emit(peer_id)

# When the connection is successful
# Args: None
# Returns: None
func _on_connected_ok() -> void:
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = Net.player_info
	player_connected.emit(peer_id, Net.player_info)

# When the connection fails
# Args: None
# Returns: None
func _on_connected_fail() -> void:
	multiplayer.multiplayer_peer = null
	player_connection_failed.emit()

# When the server disconnects
# Args: None
# Returns: None
func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()

@rpc("any_peer", "call_local", "reliable")
func show_loading_screen() -> void:
	get_tree().root.get_node("Root").get_node("MenuUI").hide()
	get_tree().root.get_node("Root").get_node("Loading Screen").show()

# ===================== SCENE FUNCTIONS =======================
# Load the game scene
# Args: String - The path to the game scene
# Returns: None
func load_game(game_scene_path: String, root: Node) -> void:
	show_loading_screen.rpc()
	if multiplayer.is_server():
		change_level.call_deferred(game_scene_path, root)

# Notify the server that the player has loaded
# Args: None
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func player_loaded() -> void:
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == Net.players.size():
			all_players_loaded.emit()
			players_loaded = 0

func change_level(game_path: String, root: Node) -> void:
	var level = root.get_node("Game")
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()

	level.add_child(load(game_path).instantiate())

# ===================== DATA FUNCTIONS ========================
# Get player name
# Args: player_id - The player id
# Returns: String - The player name
func get_player_name(player_id: int) -> String:
	if players.has(player_id):
		return players[player_id]["name"]
	ErrorUtility.log_error("Player id ´" + str(player_id) + "´ not found!")
	return ""

# Get host name
# Args: None
# Returns: String - The host name
func get_host_name() -> String:
	if players.size() == 0 or !players.has(1):
		return "No Host"
	return players[1]["name"]

# Get player names
# Args: None
# Returns: Array - The player names
func get_player_names() -> Array:
	var names: Array = []
	for player_id in players.keys():
		if player_id == 1:
			continue
		names.append(players[player_id]["name"])
	return names

# Get if peer is host
# Args: None
# Returns: bool - If the peer is the host
func is_host() -> bool:
	return multiplayer.is_server()

func get_players_ids() -> Array:
	var player_ids = players.keys()
	var host_index = player_ids.find(1)
	if host_index != -1:
		player_ids.remove(host_index)
	return player_ids

# Get player count
# Args: None
# Returns: int - The player count
func get_player_count() -> int:
	return players.size()

func get_sorted_player_ids() -> Array:
	var player_ids = players.keys()
	player_ids.sort()
	return player_ids
