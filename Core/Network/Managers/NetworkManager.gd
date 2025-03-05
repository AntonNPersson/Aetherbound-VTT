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

var maps: Dictionary = {}
var latest_map: String = ""

# Signals
signal all_players_loaded()
signal player_connection_failed()
signal map_recieved()
signal map_sent()

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
func create_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(NetworkConst.PORT, NetworkConst.MAX_CONNECTIONS)
	if error:
		ErrorUtility.log_error("Error: " + str(error))
		return
	ErrorUtility.log_info("Server successfully created!")
	multiplayer.multiplayer_peer = peer

	players[1] = Net.player_info
	player_connected.emit(1, Net.player_info)

# Leave the game
# Args: None
# Returns: None
func remove_multiplayer_peer() -> void:
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

# Show the loading screen to all peers
# Args: None
# Returns: None
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

# Change the level, can be called to reload the level
# Args: String - The path to the game scene, Node - The root node
# Returns: None
func change_level(game_path: String, root: Node) -> void:
	var level = root.get_node("Game")
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()

	var game = load(game_path).instantiate()
	level.add_child(game)

# ===================== SIGNAL FUNCTIONS ======================
# Send a signal to all peers
# Args: String - The signal name
# Returns: None
@rpc("authority", "call_remote", "reliable")
func signal_to_peers(signal_name: String) -> void:
	emit_signal(signal_name)

# Send a signal to the server
# Args: String - The signal name
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func signal_to_server(signal_name: String) -> void:
	emit_signal(signal_name)

# Sent when the map has been loaded from the http request
# Args: None
# Returns: None
@rpc("authority", "call_local", "reliable")
func map_loaded() -> void:
	map_sent.emit()


# ===================== HTTP FUNCTIONS =========================
# Send a request to the server
# Args: String - The url, Dictionary - The data to send
# Returns: None
func send_image_request(image_path: String) -> void:
	var image_data = ExternalUtility.convert_external_image_to_bytes(image_path)
	var image_name = image_path.get_file().get_basename().replace(" ", "_")
	

	var boundary = "----GodotBoundary123456"
	var headers = [
		"Content-Type: multipart/form-data; boundary=" + boundary
	]

	var body = "--" + boundary + "\r\n"
	body += 'Content-Disposition: form-data; name="image"; filename="'+ image_name + '.jpg"\r\n'
	body += "Content-Type: image/jpeg\r\n\r\n"

	var body_bytes = body.to_utf8_buffer()

	body_bytes += image_data

	var end_body = "\r\n--" + boundary + "--\r\n"
	body_bytes += end_body.to_utf8_buffer()

	var http_request = HTTPRequest.new()
	get_tree().get_root().add_child(http_request)
	var error = http_request.request_raw(NetworkConst.IMAGE_URL + "/upload/", headers, HTTPClient.METHOD_POST, body_bytes)

	if error != OK:
		ErrorUtility.log_error("Error sending request: " + error)
	else:
		ErrorUtility.log_info("Image upload started.")

	await http_request.request_completed

# Send a JSON request to the server
# Args: String - The path to the JSON file
# Returns: None
func send_json_request(json_path: String) -> void:
	# Read JSON file as bytes
	var json_file = FileAccess.open(json_path, FileAccess.READ)
	if json_file == null:
		ErrorUtility.log_error("Failed to open JSON file: " + json_path)
		return
	var json_data = json_file.get_buffer(json_file.get_length())
	json_file.close()
	
	# Extract filename and clean it
	var json_name = json_path.get_file().get_basename().replace(" ", "_")
	
	# Set up multipart/form-data boundary and headers
	var boundary = "----GodotBoundary123456"
	var headers = [
		"Content-Type: multipart/form-data; boundary=" + boundary
	]
	
	# Construct the multipart body
	var body = "--" + boundary + "\r\n"
	body += 'Content-Disposition: form-data; name="json"; filename="' + json_name + '.json"\r\n'
	body += "Content-Type: application/json\r\n\r\n"
	
	# Convert initial body part to bytes
	var body_bytes = body.to_utf8_buffer()
	
	# Append JSON data
	body_bytes += json_data
	
	# Close the multipart request
	var end_body = "\r\n--" + boundary + "--\r\n"
	body_bytes += end_body.to_utf8_buffer()
	
	# Set up and send the HTTP request
	var http_request = HTTPRequest.new()
	get_tree().get_root().add_child(http_request)
	var error = http_request.request_raw(NetworkConst.IMAGE_URL + "/upload-json/", headers, HTTPClient.METHOD_POST, body_bytes)
	
	# Handle response
	if error != OK:
		ErrorUtility.log_error("Error sending JSON request: " + str(error))
	else:
		ErrorUtility.log_info("JSON upload started.")
	
	# Wait for request completion
	await http_request.request_completed

# Get an image from the server, then add it to the maps dictionary that can be used to load the image in the mapmanager
# Args: String - The image name
# Returns: None
func get_image_request(image_name: String) -> void:
	var http_request = HTTPRequest.new()
	get_tree().get_root().add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	image_name = image_name.replace(" ", "_")
	var error = http_request.request(NetworkConst.IMAGE_URL + "/Images/" + image_name + ".jpg")
	
	maps[image_name] = null
	latest_map = image_name

	if error != OK:
		ErrorUtility.log_error("Error sending request: " + error)
	else:
		ErrorUtility.log_info("Image upload started.")

	await map_recieved

# Get a JSON file from the server
# Args: String - The JSON file name
# Returns: None


# When the request is completed
# Args: int - The result, int - The response code, Dictionary - The headers, PackedByteArray - The body
# Returns: None
func _on_request_completed(result, response_code, headers, body) -> void:
	if response_code == 200:
		var image = Image.new()
		image.load_jpg_from_buffer(body)
		var texture = ImageTexture.create_from_image(image)
		maps[latest_map] = texture
		map_recieved.emit()
	else:
		ErrorUtility.log_error("Request failed with code: " + response_code)


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

# Get players ids
# Args: None
# Returns: Array - The player ids
func get_players_ids() -> Array:
	var player_ids = players.keys()
	var host_index = player_ids.find(1)
	if host_index != -1:
		player_ids.remove_at(host_index)
	return player_ids

# Get player count
# Args: None
# Returns: int - The player count
func get_player_count() -> int:
	return players.size()

# Get player info sorted in ascending order to create a consistent order (for example spawn order)
# Args: None
# Returns: Array - The sorted player ids
func get_sorted_player_ids() -> Array:
	var player_ids = players.keys()
	player_ids.sort()
	return player_ids

# check if the map has already been loaded
# Args: String - The map name
# Returns: bool - If the map has been loaded
func has_map(map_name: String) -> bool:
	return maps.has(map_name)

# Add a map to the maps dictionary, used to keep track of the maps that have been loaded from http requests
# Args: String - The map name
# Returns: None
func add_map(map_name: String) -> void:
	maps[map_name] = null

# Retrieve object from encoded object id
# Args: EncodedObjectAsID - The encoded object id
# Returns: Object - The object
func recieve_object(encoded: EncodedObjectAsID) -> Object:
	return instance_from_id(encoded.object_id)
