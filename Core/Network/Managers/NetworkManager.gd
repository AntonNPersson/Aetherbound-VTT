extends Node
# ===================== NETWORK MANAGER =======================
# All functions, variables and signals related to the network
# =============================================================

var http_request_lobby: HTTPRequest # Dedicated node for lobby server comms
var _current_lobby_request_url: String = ""
var current_game_list: Array = []  # Cache of games received from lobby
var hosted_game_id: String = ""    # Unique ID for OUR hosted game on the lobby server
var ping_timer: Timer              # Timer for hosts to ping the lobby

# ===================== LOBBY SIGNALS =======================
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected()
signal player_reconnected(peer_id, old_peer_id, uuid)
signal player_list_received(all_players)

signal game_list_updated(games_array)
signal connection_status_changed(status_message, is_error)
signal host_registered(success, message) # Signal for host registration status

# ===================== PLAYER VARIABLES ======================
# Variables
var players: Dictionary = {}
var player_info: Dictionary = {"name": "Default",
								"uuid": generate_uuid(),
								"version": GameConst.GAME_VERSION}

# ===================== SCENE VARIABLES/SIGNALS ===============
# Variables
var players_loaded: int = 0
var reconnect_attempts = 0
var max_reconnect_attempts = 10
var reconnect_delay = 2.0
var last_server_address = ""

var maps: Dictionary = {}
var latest_map: String = ""

# Signals
signal all_players_loaded()
signal player_connection_failed()
signal map_recieved()
signal map_sent(map_name: String)
signal all_maps_recieved()

# ===================== CORE FUNCTIONS ========================
func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	player_reconnected.connect(_on_player_reconnected)

	player_info["uuid"] = generate_uuid()

	http_request_lobby = HTTPRequest.new()
	http_request_lobby.name = "LobbyHTTPRequest" # Assign name for clarity
	add_child(http_request_lobby)
	http_request_lobby.request_completed.connect(_on_lobby_request_completed)

	ping_timer = Timer.new()
	ping_timer.name = "LobbyPingTimer"
	ping_timer.wait_time = 45.0 # Ping slightly less than half the timeout
	ping_timer.one_shot = false
	ping_timer.autostart = false
	ping_timer.timeout.connect(_send_ping_to_lobby)
	add_child(ping_timer)

	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null

func _process(_delta: float) -> void:
	# Monitor connection status
	if multiplayer.has_multiplayer_peer():
		var status = multiplayer.multiplayer_peer.get_connection_status()
		if status == MultiplayerPeer.CONNECTION_DISCONNECTED:
			ErrorUtility.log_warning("Detected disconnected peer that wasn't properly cleaned up")
			multiplayer.multiplayer_peer = null

# ===================== LOBBY FUNCTIONS =======================
# Join a game with the given address
# Args: String - The address of the server
# Returns: None
func join_game(address: String = "", host_port: int = 8081) -> void:
	if multiplayer.multiplayer_peer:
		emit_signal("connection_status_changed", "Already hosting or connected.", true)
		return
	
	print("Attempting to connect to %s:%d..." % [address, host_port])
	emit_signal("connection_status_changed", "Connecting to %s:%d..." % [address, host_port], false)

	last_server_address = address
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, host_port)

	if error:
		printerr("Error creating client: " + str(error))
		emit_signal("connection_status_changed", "Failed to initiate connection (Error %d)" % error, true)
		return

	multiplayer.multiplayer_peer = peer

# Create a game
# Args: None
# Returns: None
func create_game(game_name: String, max_players: int, version: String = "1.0", mode: String = "Standard", port: int = NetworkConst.PORT) -> void:
	if multiplayer.multiplayer_peer:
		emit_signal("connection_status_changed", "Already hosting or connected.", true)
		return

	print("Starting server on port %d..." % port)
	emit_signal("connection_status_changed", "Starting server...", false)

	var peer = ENetMultiplayerPeer.new()

	var listen_port = NetworkConst.PORT if NetworkConst.has_method("PORT") else port
	var max_conn = NetworkConst.MAX_CONNECTIONS if NetworkConst.has_method("MAX_CONNECTIONS") else max_players
	var error = peer.create_server(listen_port, max_conn)

	if error != OK:
		printerr("Failed to create server. Error: ", error)
		emit_signal("connection_status_changed", "Failed to create server (Port %d may be in use)" % listen_port, true)
		return

	print("Server created successfully. Registering with lobby...")
	emit_signal("connection_status_changed", "Server started. Registering...", false)

	multiplayer.multiplayer_peer = peer
	players[1] = player_info
	player_connected.emit(1, player_info) # Signal host 'connected' locally
	_register_with_lobby(game_name, listen_port, max_conn, version, mode)

func stop_hosting():
	if multiplayer.multiplayer_peer and multiplayer.is_server():
		print("Stopping host...")
		emit_signal("connection_status_changed", "Stopping host...", false)
		_unregister_from_lobby() # Tell lobby server (fire and forget mostly)
		ping_timer.stop()
		hosted_game_id = ""
		players.clear() # Clear player list
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		emit_signal("connection_status_changed", "Host stopped.", false)
	else:
		print("Not hosting, nothing to stop.")

func refresh_game_list():
	print("Requesting game list from: ", NetworkConst.IMAGE_URL)
	emit_signal("connection_status_changed", "Refreshing game list...", false)
	var url = NetworkConst.IMAGE_URL + "/lobby/list"
	_current_lobby_request_url = url

	if http_request_lobby.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request_lobby.cancel_request()
		print("Cancelled previous lobby request.")
	
	var error = http_request_lobby.request(url) # GET request
	if error != OK:
		printerr("HTTP Request error (List): ", error)
		emit_signal("connection_status_changed", "Failed to request game list (Error %d)" % error, true)
		current_game_list.clear()
		emit_signal("game_list_updated", current_game_list)

func disconnect_from_game():
	if multiplayer.multiplayer_peer and not multiplayer.is_server():
		print("Disconnecting...")
		emit_signal("connection_status_changed", "Disconnecting...", false)
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		players.clear() # Clear player list
		emit_signal("connection_status_changed", "Disconnected.", false)
	elif multiplayer.multiplayer_peer and multiplayer.is_server():
		print("Cannot disconnect, currently hosting. Call stop_hosting() instead.")
	else:
		print("Not connected.")

func generate_uuid() -> String:
	var uuid_path = "user://player_uuid.save"
	if FileAccess.file_exists(uuid_path):
		var file = FileAccess.open(uuid_path, FileAccess.READ)
		if file:
			var uuid = file.get_line().strip_edges()
			file.close()
			if not uuid.is_empty():
				return uuid
		else: print("Error opening existing UUID file.")

	# Generate a new UUID if file doesn't exist or is empty/corrupt
	randomize()
	var uuid = str(OS.get_unique_id()) + "_" + str(randi()) + str(Time.get_unix_time_from_system())
	var file = FileAccess.open(uuid_path, FileAccess.WRITE)
	if file:
		file.store_line(uuid)
		file.close()
		print("Generated and saved new UUID: ", uuid)
		return uuid
	else:
		printerr("Error saving new UUID file!")
		# Fallback to less persistent UUID for this session only
		return str(OS.get_unique_id()) + "_" + str(randi())

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
	# --- Executes on HOST ---
	if new_player_info["version"] != GameConst.GAME_VERSION:
		print("Client version mismatch: %s != %s" % [new_player_info["version"], GameConst.GAME_VERSION])
		return

	var new_player_id = multiplayer.get_remote_sender_id()
	if new_player_id == 1: # Should not happen if called via RPC from client
		printerr("Host received _register_player from itself?")
		return
	if players.has(new_player_id):
		print("Player %d already registered, updating info." % new_player_id)
	else:
		print("Registering new player: %d" % new_player_id)

	players[new_player_id] = new_player_info

	# 1. Emit signal locally on the HOST (for host UI/logic)
	#    Signature: (int, Dictionary)
	player_connected.emit(new_player_id, new_player_info)

	# 2. Send the complete current player list ONLY to the NEW player
	_send_full_player_list.rpc_id(new_player_id, players)

	# 3. Inform ALL OTHER existing players about the NEW player
	#    (Exclude the host (1) and the new player themselves)
	for peer_id in players:
		if peer_id != 1 and peer_id != new_player_id:
			_inform_peer_about_new_player.rpc_id(peer_id, new_player_id, new_player_info)

# When a player connects
# Args: int - The peer id of the player
# Returns: None
func _on_player_connected(peer_id: int) -> void:
	print("Peer connected: ", peer_id)
	# Client tells server about itself
	if not multiplayer.is_server():
		_register_player.rpc_id(1, player_info)

@rpc("authority", "reliable") # Run only on the target client (authority is host, rpc_id targets client)
func _send_full_player_list(all_players: Dictionary):
	# --- Executes on the NEW CLIENT ---
	print("Received initial player list: ", all_players)
	players = all_players # Update local list
	# Emit the NEW signal for UI that needs the full list initially
	player_list_received.emit(all_players)
	# Optionally, emit player_connected for self *after* getting the list
	if players.has(multiplayer.get_unique_id()):
		player_connected.emit(multiplayer.get_unique_id(), players[multiplayer.get_unique_id()])

@rpc("authority", "reliable") # Run only on the target client
func _inform_peer_about_new_player(new_peer_id: int, new_peer_info: Dictionary):
	# --- Executes on an EXISTING CLIENT ---
	if new_peer_id == multiplayer.get_unique_id(): return # Shouldn't happen, but safety check

	print("Received info about new player: %d" % new_peer_id)
	players[new_peer_id] = new_peer_info
	# Emit the standard player_connected signal for UI updates
	# Signature: (int, Dictionary)
	player_connected.emit(new_peer_id, new_peer_info)

# When a player disconnects
# Args: int - The peer id of the player
# Returns: None
func _on_player_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id)
	if players.has(peer_id):
		players.erase(peer_id)
	player_disconnected.emit(peer_id)
	# If host, update lobby server
	if multiplayer.is_server():
		_send_ping_to_lobby()

func _attempt_reconnect(old_players: Dictionary) -> void:
	# (Your existing reconnection logic - ensure last_server_address was set by join_game)
	if last_server_address.is_empty():
		print("Cannot reconnect: No previous server address known.")
		player_connection_failed.emit() # Use existing signal
		return

	reconnect_attempts = 0
	print("Attempting reconnection to: ", last_server_address)

	while reconnect_attempts < max_reconnect_attempts:
		reconnect_attempts += 1
		print("Reconnection attempt %d/%d" % [reconnect_attempts, max_reconnect_attempts])
		emit_signal("connection_status_changed", "Reconnection attempt %d/%d..." % [reconnect_attempts, max_reconnect_attempts], false)
		await get_tree().create_timer(reconnect_delay).timeout

		var peer = ENetMultiplayerPeer.new()
		var port = NetworkConst.PORT if NetworkConst.has("PORT") else 8081
		var error = peer.create_client(last_server_address, port)
		if error:
			print("Reconnect create_client error: ", error)
			continue

		multiplayer.multiplayer_peer = peer

		# Wait for connection or timeout using signals is generally better
		var connected = await get_tree().create_timer(5.0).timeout # Wait 5 sec
		multiplayer.connected_to_server.disconnect(_on_reconnect_timer_timeout) # Disconnect temp handler

		if connected: # Signal fired within timeout
			print("Reconnected successfully (attempt %d)." % reconnect_attempts)
			# Restore players immediately is risky, wait for server confirmation?
			# For now, let _on_connected_ok handle basic setup
			# Authenticate immediately
			authenticate_reconnection.rpc_id(1, player_info["uuid"], -1) # Send -1 as old_peer_id maybe? Need clear logic.
			emit_signal("connection_status_changed", "Reconnected!", false)
			return
		else: # Timeout occurred
			print("Reconnection attempt %d timed out." % reconnect_attempts)
			if multiplayer.multiplayer_peer: multiplayer.multiplayer_peer.close()
			multiplayer.multiplayer_peer = null

	# All attempts failed
	printerr("Failed to reconnect after %d attempts." % max_reconnect_attempts)
	players.clear() # Clear data only after all attempts fail
	emit_signal("connection_status_changed", "Reconnection failed.", true)
	player_connection_failed.emit() # Use existing signal

# Placeholder function for the timer timeout used in reconnect loop
func _on_reconnect_timer_timeout():
	# This function is only here so we can connect/disconnect the signal
	# during the await multiplayer.connected_to_server.timeout() call.
	pass

@rpc("authority", "reliable") # Changed from any_peer to authority (server only executes)
func authenticate_reconnection(uuid: String, old_peer_id: int) -> void:
	# Server handles authentication and remapping
	var new_peer_id = multiplayer.get_remote_sender_id()
	print("Server: Received reconnection auth from new ID %d (UUID: %s, OldID %d)" % [new_peer_id, uuid, old_peer_id])

	# Find player info by UUID in the CURRENT player list (old_peer_id might be invalid if they fully timed out)
	var found_old_id = -1
	for pid in players:
		if players[pid].get("uuid") == uuid:
			found_old_id = pid
			break

	if found_old_id != -1:
		print("Server: Remapping player %d (UUID %s) to new peer ID %d" % [found_old_id, uuid, new_peer_id])
		var player_data = players[found_old_id]
		players.erase(found_old_id)
		players[new_peer_id] = player_data

		# Update node authority if applicable
		var player_node = get_tree().get_root().find_child(str(found_old_id), true, false) # Example find
		if player_node:
			print("Server: Updating node authority for %d -> %d" % [found_old_id, new_peer_id])
			player_node.name = str(new_peer_id)
			player_node.set_multiplayer_authority(new_peer_id)

		# Emit signals to update others maybe? Or handle sync via game state
		player_reconnected.emit(new_peer_id, found_old_id, uuid) # Let local server logic know
		player_connected.emit(new_peer_id, player_data) # Treat as a connection for consistency?
	else:
		print("Server: Reconnecting player with UUID %s not found in current player list. Treating as new connection." % uuid)
		# Register as a completely new player if their old entry timed out
		_register_player(player_info) # Need player info from the client RPC ideally! Fix authenticate_reconnection signature?
		#authenticate_reconnection.rpc_id(1, Net.player_info["uuid"], old_peer_id) -> The client should send its player_info here too
		# Let's assume _register_player handles getting info from sender ID correctly

func _on_player_reconnected(peer_id: int, old_peer_id: int, uuid: String) -> void:
	# This signal is now mostly for server-side logic after auth
	if not multiplayer.is_server(): return
	print("Server logic reacting to player reconnected: %d (was %d)" % [peer_id, old_peer_id])
	# Potentially trigger game state resync for this player

# When the connection is successful
# Args: None
# Returns: None
func _on_connected_ok() -> void:
	# Called on CLIENT when connection succeeds
	print("Connected to server!")
	# Don't register self in players dict here, wait for server confirmation/RPCs
	emit_signal("connection_status_changed", "Connected to host!", false)
	# Client should now wait for game state/map info etc.

# When the connection fails
# Args: None
# Returns: None
func _on_connection_failed() -> void: # Renamed from _on_connected_fail
	# Called on CLIENT when connection fails initially
	printerr("Connection failed.")
	multiplayer.multiplayer_peer = null
	emit_signal("connection_status_changed", "Connection failed.", true)
	player_connection_failed.emit() # Emit existing signal

# When the server disconnects
# Args: None
# Returns: None
func _on_server_disconnected() -> void:
	# Called on CLIENT when connection is lost after establishing
	print("Disconnected from server.")
	emit_signal("connection_status_changed", "Disconnected from host.", true)
	var old_players = players.duplicate() # Save potential state
	multiplayer.multiplayer_peer = null
	players.clear() # Clear player list on disconnect
	server_disconnected.emit() # Emit existing signal

	# Start reconnection attempts
	_attempt_reconnect(old_players)

func _register_with_lobby(g_name, g_port, g_max_players, g_version, g_mode):
	var url = NetworkConst.IMAGE_URL + "/lobby/register"
	_current_lobby_request_url = url
	var body = {
		"name": g_name,
		"port": g_port,
		"players": 1, # Host counts as 1
		"max_players": g_max_players,
		"gameVersion": g_version,
		"gameMode": g_mode
	}
	var headers = ["Content-Type: application/json"]
	# Make sure request node is free
	if http_request_lobby.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request_lobby.cancel_request()
	var error = http_request_lobby.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		printerr("HTTP Request error (Register): ", error)
		emit_signal("host_registered", false, "Failed to send registration request (Error %d)" % error)

func _send_ping_to_lobby():
	if hosted_game_id == "" or not multiplayer.is_server():
		# Stop pinging if no longer hosting or not registered
		ping_timer.stop()
		return

	var url = NetworkConst.IMAGE_URL + "/lobby/ping"
	_current_lobby_request_url = url
	var current_player_count = players.size() # Use our tracked player count
	var body = {
		"gameId": hosted_game_id,
		"players": current_player_count
	}
	var headers = ["Content-Type: application/json"]
	# Send ping
	if http_request_lobby.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		# If busy, maybe skip this ping or queue? For now, skip.
		print("Lobby HTTPRequest busy, skipping ping.")
		return
	http_request_lobby.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))

func _unregister_from_lobby():
	if hosted_game_id == "": return
	ping_timer.stop() # Stop pinging

	print("Unregistering game ID %s from lobby..." % hosted_game_id)
	var url = NetworkConst.IMAGE_URL + "/lobby/unregister"
	_current_lobby_request_url = url
	var body = {"gameId": hosted_game_id}
	var headers = ["Content-Type: application/json"]
	# Make the request
	if http_request_lobby.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http_request_lobby.cancel_request()
	http_request_lobby.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	# Clear local ID immediately, don't wait for response on exit
	hosted_game_id = ""

func _on_lobby_request_completed(result, response_code, _headers, body):
	var requested_url = _current_lobby_request_url
	_current_lobby_request_url = "" # Clear after request
	print("Lobby request to %s completed. Result: %d, Code: %d" % [requested_url, result, response_code])

	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 400:
		printerr("Lobby request failed!")
		var error_msg = "Lobby Error %d" % response_code
		if response_code == 0: error_msg = "Cannot connect to lobby server" # Network error
		emit_signal("connection_status_changed", error_msg, true)
		printerr("  Body: ", body.get_string_from_utf8())
		if requested_url.ends_with("/lobby/register"):
			emit_signal("host_registered", false, "Lobby registration failed (%s)" % error_msg)
		elif requested_url.ends_with("/lobby/list"):
			current_game_list.clear()
			emit_signal("game_list_updated", current_game_list)
		return

	var json_response = JSON.parse_string(body.get_string_from_utf8())
	if json_response == null:
		printerr("Failed to parse JSON response from lobby: ", body.get_string_from_utf8())
		if requested_url.ends_with("/lobby/list"):
			current_game_list.clear()
			emit_signal("game_list_updated", current_game_list)
			emit_signal("connection_status_changed", "Error parsing game list", true)
		return

	if requested_url.ends_with("/lobby/register"):
		if json_response.has("gameId") and json_response.get("status") == "ok":
			hosted_game_id = json_response["gameId"]
			print("Successfully registered with lobby. Game ID: ", hosted_game_id)
			emit_signal("host_registered", true, "Registered with lobby!")
			ping_timer.start() # Start pinging
		else:
			printerr("Lobby registration response invalid: ", json_response)
			emit_signal("host_registered", false, "Lobby registration failed (Invalid Response)")

	elif requested_url.ends_with("/lobby/list"):
		if json_response is Array:
			current_game_list = json_response
			print("Received %d games from lobby." % current_game_list.size())
			emit_signal("game_list_updated", current_game_list)
			emit_signal("connection_status_changed", "Game list updated.", false)
		else:
			printerr("Lobby list response was not an Array: ", json_response)
			current_game_list.clear()
			emit_signal("game_list_updated", current_game_list)
			emit_signal("connection_status_changed", "Error parsing game list format", true)

	elif requested_url.ends_with("/lobby/ping"):
		if json_response.get("status") != "pong": print("Lobby ping response wasn't pong: ", json_response)

	elif requested_url.ends_with("/lobby/unregister"):
		if json_response.get("status") == "ok": print("Successfully unregistered from lobby.")
		else: print("Lobby unregister response wasn't ok: ", json_response)

# Show the loading screen to all peers
# Args: None
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func show_loading_screen() -> void:
	get_tree().root.get_node("Root").get_node("MenuUI").hide()
	get_tree().root.get_node("Root").get_node("Loading Screen").show()

@rpc("any_peer", "call_local", "reliable")
func hide_loading_screen() -> void:
	get_tree().root.get_node("Root").get_node("Loading Screen").hide()

# ===================== SCENE FUNCTIONS =======================
func get_game_list() -> Array:
	# Returns the list of games
	return current_game_list

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
func map_loaded(map_name: String = "Test") -> void:
	map_sent.emit(map_name)

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
func send_dd2vtt_request(dd2vtt_path: String) -> void:
	# Read .dd2vtt file as bytes
	var dd2vtt_file = FileAccess.open(dd2vtt_path, FileAccess.READ)
	if dd2vtt_file == null:
		ErrorUtility.log_error("Failed to open .dd2vtt file: " + dd2vtt_path)
		return
	var dd2vtt_data = dd2vtt_file.get_buffer(dd2vtt_file.get_length())
	dd2vtt_file.close()
	
	# Extract filename and clean it
	var dd2vtt_name = dd2vtt_path.get_file().get_basename().replace(" ", "_")
	
	# Set up multipart/form-data boundary and headers
	var boundary = "----GodotBoundary123456"
	var headers = [
		"Content-Type: multipart/form-data; boundary=" + boundary
	]
	
	# Construct the multipart body
	var body = "--" + boundary + "\r\n"
	body += 'Content-Disposition: form-data; name="dd2vtt"; filename="' + dd2vtt_name + '.dd2vtt"\r\n'
	body += "Content-Type: application/json\r\n\r\n"
	
	# Convert initial body part to bytes
	var body_bytes = body.to_utf8_buffer()
	
	# Append .dd2vtt data
	body_bytes += dd2vtt_data
	
	# Close the multipart request
	var end_body = "\r\n--" + boundary + "--\r\n"
	body_bytes += end_body.to_utf8_buffer()
	
	# Set up and send the HTTP request
	var http_request = HTTPRequest.new()
	get_tree().get_root().add_child(http_request)
	var error = http_request.request_raw(NetworkConst.IMAGE_URL + "/upload-dd2vtt/", headers, HTTPClient.METHOD_POST, body_bytes)
	
	# Handle response
	if error != OK:
		ErrorUtility.log_error("Error sending .dd2vtt request: " + str(error))
	else:
		ErrorUtility.log_info(".dd2vtt upload started.")
	
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
func get_dd2vtt_request(dd2vtt_name: String) -> void:
	var http_request = HTTPRequest.new()
	get_tree().get_root().add_child(http_request)
	http_request.request_completed.connect(_on_dd2vtt_request_completed)

	dd2vtt_name = dd2vtt_name.replace(" ", "_")
	var error = http_request.request(NetworkConst.IMAGE_URL + "/dd2vtt/" + dd2vtt_name + ".dd2vtt")
	
	maps[dd2vtt_name] = null
	latest_map = dd2vtt_name

	if error != OK:
		ErrorUtility.log_error("Error sending request: " + str(error))
	else:
		ErrorUtility.log_info(".dd2vtt request started.")

	await map_recieved

# When the request is completed
# Args: int - The result, int - The response code, Dictionary - The headers, PackedByteArray - The body
# Returns: None
func _on_request_completed(_result: int, response_code: int, _headers: Array, body) -> void:
	if response_code == 200:
		var image = Image.new()
		image.load_jpg_from_buffer(body)
		var texture = ImageTexture.create_from_image(image)
		maps[latest_map] = texture
		map_recieved.emit()
	else:
		ErrorUtility.log_error("Request failed with code: " + str(response_code))

func _on_dd2vtt_request_completed(_result: int, response_code: int, _headers: Array, body: PackedByteArray) -> void:
	if response_code == 200:
		# Parse the .dd2vtt file as JSON
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		if parse_result != OK:
			ErrorUtility.log_error("Failed to parse .dd2vtt JSON: " + json.get_error_message())
			map_recieved.emit()
			return
		
		var dd2vtt_data = json.get_data()
		if typeof(dd2vtt_data) != TYPE_DICTIONARY or not dd2vtt_data.has("image"):
			ErrorUtility.log_error("Invalid .dd2vtt format: Missing 'image' key")
			map_recieved.emit()
			return
		
		# Extract and decode the base64 image
		var base64_string = dd2vtt_data["image"]
		if base64_string.begins_with("data:image/png;base64,"):  # Strip data URL prefix if present
			base64_string = base64_string.split(",")[1]
		
		var image_raw = Marshalls.base64_to_raw(base64_string)
		if image_raw.is_empty():
			ErrorUtility.log_error("Failed to decode base64 image from .dd2vtt")
			map_recieved.emit()
			return
		
		# Create image from bytes
		var image = Image.new()
		var load_error = image.load_jpg_from_buffer(image_raw)
		if load_error != OK:
			ErrorUtility.log_error("Failed to load PNG from buffer: " + str(load_error))
			map_recieved.emit()
			return
		
		# Convert to texture
		var texture = ImageTexture.create_from_image(image)
		if texture == null:
			ErrorUtility.log_error("Failed to create texture from .dd2vtt image")
			map_recieved.emit()
			return
		
		# Store texture in maps
		maps[latest_map] = {"image": texture, "line_of_sight": dd2vtt_data["line_of_sight"], "portals": dd2vtt_data["portals"], "resolution": dd2vtt_data["resolution"], "lights": dd2vtt_data["lights"]}
		if dd2vtt_data.has("spawns"):
			maps[latest_map]["spawns"] = dd2vtt_data["spawns"]

		if dd2vtt_data.has("triggers"):
			maps[latest_map]["triggers"] = dd2vtt_data["triggers"]

		if dd2vtt_data.has("tokens"):
			maps[latest_map]["tokens"] = dd2vtt_data["tokens"]
		ErrorUtility.log_info("Successfully loaded .dd2vtt texture for " + latest_map)
		map_recieved.emit()
	else:
		ErrorUtility.log_error("Request failed with code: " + str(response_code))
		map_recieved.emit()


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

func get_host_id() -> int:
	return 1

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
	return multiplayer.get_unique_id() == 1

func get_host() -> int:
	return 1

# Get players ids
# Args: None
# Returns: Array - The player ids
func get_players_ids() -> Array:
	var player_ids = players.keys()
	var host_index = player_ids.find(1)
	if host_index != -1:
		player_ids.remove_at(host_index)
	return player_ids

func get_my_id() -> int:
	if multiplayer.has_multiplayer_peer():
		return multiplayer.get_unique_id()
	return 0

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

# CHANGE THIS TO THE EXIT BUTTON IN THE UI IN THE FUTURE
# Save the settings when the game is closed
# Args: None
# Returns: None
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# Graceful exit: Stop hosting/disconnect before quitting

		if multiplayer.has_multiplayer_peer():
			if multiplayer.is_server():
				stop_hosting()
			else:
				disconnect_from_game()
		# Allow some time for network messages potentially? Usually not needed.
		await get_tree().create_timer(0.1).timeout
