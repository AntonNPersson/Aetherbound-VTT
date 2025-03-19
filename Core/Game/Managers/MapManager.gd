class_name MapManager extends Node2D
# ===================== MAP MANAGER =====================
# Manages the map, and the players in the game
# ======================================================

#Public Variables
@export var picture_size: Vector2 = Vector2(6300, 4200)
@export var tile_size: Vector2 = Vector2(300, 300)
@export var tilemap: TileMap = null
@export var illumination: Node = null
@export var nav: NavigationRegion2D = null
@export var light_texture: Texture = null

var tilemap_data: Dictionary = {}

# Tilemap variables
var line_walls: Node2D = null
var line_walls_2: Node2D = null
var current_line_walls: Node2D = null
var portals: Node2D = null
var lights: Node2D = null
var map_width: int = 100
var map_height: int = 100
var selected_tile: Vector2 = Vector2(0, 0)
var selected_token: Node = null
var pause_tilemap_input: bool = false

# Pathfinding variables
var astar = AStar2D.new()
var path_array: Array = []

# Map variables
var current_local_map: int = 0
var current_map: int = 0
var is_changing_map = false
var map_data: Dictionary = {0 : {"tokens": [], "name": Settings.prologue_map}}
var light_data: Array = []
var portal_data: Array = []

# Drawing variables
var is_drawing: bool = false
var distance_path: Array = []

# Managers
var cm: CollisionManager = null
var pm: PortalManager = null
var lm: LightManager = null
var pam: PanelManager = null
var sm: SpawnManager = null

# ===================== SIGNALS =====================

signal map_initialized()
signal map_changed(map_index, local, player_ids)
signal map_data_changed()
signal map_created()
signal map_cleared()
signal open_map_changer(player_id)
signal data_added()

# ===================== CORE FUNCTIONS =====================

# initialize the map for local player/server
# Args: None
# Returns: None

func _ready() -> void:
	_initialize_components()
	_auto_scale_tilemap()
	add_to_group("Map")

	if Net.is_host():
		await create_local_map(Settings.prologue_map)
		current_local_map = Settings.prologue_index
		Net.map_loaded.rpc(Settings.prologue_map)
		map_initialized.emit()
	else:
		Net.map_sent.connect(initialize_map)

func _initialize_components():
	# For some reason I have problems with @export variables, when using the exported version of the game, so I have to set them manually
	line_walls = Node2D.new()
	line_walls.name = "Line Walls"
	line_walls.visible = true
	line_walls_2 = Node2D.new()
	line_walls_2.name = "Line Walls 2"
	line_walls_2.visible = true
	add_child(line_walls_2)
	add_child(line_walls)
	portals = Node2D.new()
	portals.name = "Portals"
	portals.visible = true
	add_child(portals)
	lights = Node2D.new()
	lights.name = "Lights"
	lights.visible = true
	add_child(lights)

	cm = CollisionManager.new()
	add_child(cm)
	pm = PortalManager.new()
	add_child(pm)
	pam = PanelManager.new(self)
	add_child(pam)
	lm = get_parent().get_parent().get_node("Lights")
	current_line_walls = line_walls
	sm = SpawnManager.new()
	sm.map_manager = self
	add_child(sm)

func _auto_scale_tilemap():
	if tilemap == null:
		tilemap = get_parent().get_parent().get_node("TileMap")
	tile_size = Helper.scale_tile_size(tile_size)
	tilemap.tile_set.tile_size = tile_size

# Initialize the map for all peers except host
# Args: None
# Returns: None
func initialize_map(map_name: String) -> void:
	await create_map(map_name)
	map_changed.emit(get_map_index_from_name(map_name), false, [])

func _draw():
	if is_drawing:
		draw_tile_array(distance_path, Color(1, 1, 1, 0.3))
	else:
		draw_selected_tile()

# Create a local map, how do i make this more efficient? Probably saving the tilemap and walls and portals and lights and just switching between them instead of creating them every time or just find a way to do this outside of the ga
# Args: String - The name of the map
# Returns: None
func create_local_map(map_name: String):
	is_changing_map = true
	if !Net.has_map(map_name):
		Net.add_map(map_name)
	if !tilemap_data.has(map_name):
		var data = Cache.data[map_name]
		tilemap_data[map_name] = data
	clear_map()
	await map_cleared
	create_tilemap(ExternalUtility.convert_Base64_to_texture(tilemap_data[map_name].image))
	await _create_map_components(map_name, tilemap_data)
	is_changing_map = false

# Create a map
# Args: String - The name of the map
# Returns: None
@rpc("any_peer", "call_remote", "reliable")
func create_map(map_name: String):
	map_name = map_name.replace(" ", "_")
	if !Net.has_map(map_name):
		await Net.get_dd2vtt_request(map_name)
	clear_map()
	await map_cleared
	create_tilemap(Net.maps[map_name]["image"])
	await _create_map_components(map_name, Net.maps)

	var players = get_tree().get_nodes_in_group("players")
	if sm.cached_spawns.size() > 0 and sm.cached_spawns.has(map_name):
		for spawn in sm.cached_spawns[map_name]:
				var random_spawn = sm.cached_spawns[map_name][randi() % sm.cached_spawns[map_name].size()]
				for player in players:
					move_to_tile(player, random_spawn.spawn_position)
					break
	else:
		for player in players:
			move_to_tile(player, picture_size/2)
			break
	emit_map_created.rpc_id(1)

func _create_map_components(map_name: String, data: Dictionary) -> void:
	create_walls(data[map_name]["line_of_sight"], data[map_name]["resolution"])
	await cm.create_wall_collision(line_walls)
	await pm.create_portals(data[map_name]["portals"], data[map_name]["resolution"], map_name)
	await cm.create_wall_collision(portals)
	lm.create_light_resource(data[map_name]["lights"], data[map_name]["resolution"], map_name)
	if data[map_name].has("spawns"):
		sm.create_spawns(data[map_name]["spawns"], map_name)
	else:
		data[map_name]["spawns"] = []
		sm.create_spawns(data[map_name]["spawns"], map_name)
	for p in get_all_portals():
		p.initialize_state()
	map_data_changed.emit()

# ===================== MAP CREATION FUNCTIONS =================
# Add data to the map
# Args: int - The index of the map
#       String - The name of the map
#       Array - The tokens on the map
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func add_data(index: int, map_name: String, tokens: Array) -> void:
	map_data[index] = {"tokens": tokens, "name": map_name}

# Add multiple map datas at the same time
# Args: Array - The indices of the maps
#       Array - The names of the maps
#       Array - The tokens on the maps
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func add_data_array(indices: Array, map_names: Array, tokens: Array) -> void:
	for i in range(indices.size()):
		if tokens[i].find("players") != -1:
			tokens[i].clear()
			tokens[i].append_array(get_tree().get_nodes_in_group("players"))
			
			current_map = indices[i]
		map_data[indices[i]] = {"tokens": tokens[i], "name": map_names[i]}
	data_added.emit()

@rpc("any_peer", "call_local", "reliable")
func add_spawn_data(map_name: String, pos: Vector2) -> void:
	sm.add_spawn(pos, map_name)

@rpc("any_peer", "call_local", "reliable")
func remove_spawn_data(map_name: String, pos: Vector2) -> void:
	sm.remove_spawn(pos, map_name)

@rpc("any_peer", "call_local", "reliable")
func add_light_data(map_name: String, light: Variant) -> void:
	lm.add_light(light, map_name)

@rpc("any_peer", "call_local", "reliable")
func emit_map_created() -> void:
	map_created.emit()

# Clear the map, i need to change this to hiding the map instead of clearing it
# Args: None
# Returns: None
func clear_map() -> void:
	tilemap.clear()
	remove_resource_from_tileset()
	for wall in line_walls.get_children():
		wall.queue_free()
	for p in portals.get_children():
		p.queue_free()
	astar.clear()
	path_array.clear()
	await get_tree().process_frame
	await get_tree().process_frame
	map_cleared.emit()

# Create the tilemap
# Args: Texture2D - The texture to create the tilemap from, need to fix so the tilemap is stored so that i can just switch between them
# Returns: None
func create_tilemap(texture: Texture2D) -> void:
	var atlas_resource = create_tileset_resource(texture)
	add_resource_to_tileset(atlas_resource)
	place_tiles()
	create_astar_from_array(path_array)

# Create the walls
# Args: Array - The array of walls
# Returns: None
func create_walls(walls: Array, resolution) -> void:
	for blocker in walls:
		var points = Helper.dict2vector2array(blocker, resolution)
		var line = Line2D.new()
		line.points = points
		line_walls.add_child(line)

# Create the astar from an array, currently connects all points in the array, need to implement custom connections when collision is implemented
# Args: Array - The array of points
# Returns: None
func create_astar_from_array(arr: Array):
	for i in range(arr.size()):
		astar.add_point(i, arr[i], 5)

	var directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
					  Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1)]

	for i in range(arr.size()):
		var current_pos = arr[i]

		for dir in directions:
			var neighbor_pos = current_pos + dir
			if arr.find(neighbor_pos) != -1:
				astar.connect_points(i, arr.find(neighbor_pos), true)

# ===================== TILEMAP FUNCTIONS =====================

# Move the player to a tile, currently checks for out of bounds but need to implement collision (should be gathered from the tilemap custom data on the tile)
# Args: Node2D - The player that will be moved
#       Vector2 - The global position of the tile
# Returns: None
func move_to_tile(player: Node2D, global_pos: Vector2) -> void:
	var map_pos = convert_to_tilemap_pos(global_pos)

	if !is_inside_tilemap(map_pos):
		return

	player.global_position = convert_to_global_pos(map_pos)
	map_data_changed.emit()
	queue_redraw()

# Get the distance from start position to end position, converted to feet (one tile is 5 feet)
# Args: Vector2 - The start position
#       Vector2 - The end position
# Returns: int - The distance in feet
func get_distance_to(start: Vector2, end: Vector2, is_draw: bool = false) -> int:
	var map_start = convert_to_tilemap_pos(start)
	var map_end = convert_to_tilemap_pos(end)

	var path = astar.get_point_path(path_array.find(map_start), path_array.find(map_end))

	if is_draw:
		distance_path.clear()
		for p in range(path.size()):
			distance_path.append(convert_to_global_pos(path[p]))
		queue_redraw()

		var total_cost = 0
		var diagonal_counter = 0
	
		for i in range(1, path.size()):
			var prev_point = path[i-1]
			var current_point = path[i]
		
		# Check if movement is diagonal
			var is_diagonal = prev_point.x != current_point.x and prev_point.y != current_point.y
		
			if is_diagonal:
				diagonal_counter += 1
				if diagonal_counter % 2 == 1:
				# First, third, fifth, etc. diagonal - normal cost
					total_cost += 5
				else:
				# Second, fourth, sixth, etc. diagonal - double cost
					total_cost += 10
			else:
			# Non-diagonal movement - normal cost
				total_cost += 5
		return total_cost

	return (path.size() - 1) * 5

# Select a tile on the map
# Args: Vector2 - The global position of the tile
# Returns: None
func select_tile(global_pos: Vector2):
	var tile_pos = convert_to_tilemap_pos(global_pos)
	if !is_inside_tilemap(tile_pos) or pause_tilemap_input:
		return

	selected_tile = convert_to_global_pos(tile_pos)

	if is_selected_tile_token():
		selected_token = get_token_at_position(selected_tile)
	else:
		selected_token = null

	queue_redraw()

func get_mouse_position() -> Vector2:
	return get_global_mouse_position()

# Check if a tile is selected
# Args: Vector2 - The global position of the tile
# Returns: bool - If the tile is selected
func is_tile_selected(global_pos: Vector2) -> bool:
	var tile_pos = convert_to_tilemap_global_pos(global_pos)
	return selected_tile == tile_pos

# Check if a tile is selected and is a player
# Args: Vector2 - The global position of the tile
# Returns: bool - If the tile is selected and is a player
func is_selected_tile_player() -> bool:
	var token = get_token_at_position(selected_tile)
	if token == null:
		return false
	return token.is_in_group("players")

# Check if a tile is selected and is a token
# Args: Vector2 - The global position of the tile
# Returns: bool - If the tile is selected and is a token
func is_selected_tile_token() -> bool:
	var token = get_token_at_position(selected_tile)
	if token == null:
		return false
	return token.is_in_group("token")

# Check if a position is inside the tilemap
# Args: Vector2 - The position to check
# Returns: bool - If the position is inside the tilemap
func is_inside_tilemap(map_pos: Vector2) -> bool:
	return map_pos.x >= 0 and map_pos.x < map_width and map_pos.y >= 0 and map_pos.y < map_height

# Check if a global position is inside the tilemap
# Args: Vector2 - The global position to check
# Returns: bool - If the global position is inside the tilemap
func is_global_inside_tilemap(global_pos: Vector2) -> bool:
	var map_pos = convert_to_tilemap_pos(global_pos)
	return is_inside_tilemap(map_pos)

# Get the start position of the tilemap, in global coords
# Args: None
# Returns: Vector2 - The start position of the tilemap
func get_tilemap_start_pos() -> Vector2:
	return convert_to_global_pos(Vector2(0, 0)) - tile_size/2

# Get the end position of the tilemap, in global coords
# Args: None
# Returns: Vector2 - The end position of the tilemap
func get_tilemap_end_pos() -> Vector2:
	return convert_to_global_pos(Vector2(map_width, map_height)) + tile_size/2

# Get the view distance of the tilemap
# Args: None
# Returns: int - The view distance of the tilemap
func get_tilemap_view_distance() -> int:
	@warning_ignore("narrowing_conversion")
	return get_tilemap_start_pos().distance_to(get_tilemap_end_pos())

# Get the token at a position, need to implement a better way to get the token, currently just checks the global position and needs the token to be in the token group
# Args: Vector2 - The position to check
# Returns: Node2D - The token at the position
func get_token_at_position(global_pos: Vector2) -> Node2D:
	var unit = null
	for child in get_tree().get_nodes_in_group("token"):
		if child.visible == false:
			continue
		if child.global_position == global_pos:
			unit = child
			break
	return unit

# Get the portal at a position
# Args: Vector2 - The position to check
# Returns: Node2D - The portal at the position
func get_portal_at_position(tile_pos: Vector2) -> Variant:
	var all_portals = get_tree().get_nodes_in_group("portals")
	
	for line in all_portals:
		var portal_holder = line.get_node("PortalHolder")
		var valid_positions = portal_holder.get_meta("tile_positions")
		
		# Check if the given tile position matches any of the valid positions
		for pos in valid_positions:
			if convert_to_global_pos(pos) == tile_pos:
				return portal_holder.get_meta("portal_resource")
	
	return null

# Get the tilemap position from a global position
# Args: Vector2 - The global position to convert
# Returns: Vector2 - The tilemap position
func get_all_portals() -> Array:
	var all_portals = get_tree().get_nodes_in_group("portals")

	var portalss = []
	for line in all_portals:
		var portal_holder = line.get_node("PortalHolder")
		portalss.append(portal_holder.get_meta("portal_resource"))
	return portalss

# Get the all the portals inherent positions at a position
# Args: Vector2 - The position to check
# Returns: Array - The portal at the position
func get_portal_at_position_tile_pos() -> Variant:
	var all_portals = get_tree().get_nodes_in_group("portals")
	
	for line in all_portals:
		var portal_holder = line.get_node("PortalHolder")
		return portal_holder.get_meta("tile_positions")
	
	return null

# Check if a portal is at a position
# Args: Vector2 - The position to check
# Returns: bool - If the portal is at the position
func is_portal_at_position(tile_pos: Vector2) -> bool:
	var all_portals = get_tree().get_nodes_in_group("portals")
	
	for line in all_portals:
		var portal_holder = line.get_node("PortalHolder")
		var valid_positions = portal_holder.get_meta("tile_positions")
		
		# Check if the given tile position matches any of the valid positions
		for pos in valid_positions:
			if convert_to_global_pos(pos) == tile_pos:
				return true
	
	return false

func is_light_at_position(tile_pos: Vector2) -> bool:
	for light in lm.cached_lights[get_map_name_from_index(current_local_map)]:
		if convert_to_tilemap_global_pos(light.light_position) == tile_pos:
			return true
	return false

func get_light_at_position(tile_pos: Vector2) -> Variant:
	for light in lm.cached_lights[get_map_name_from_index(current_local_map)]:
		if convert_to_tilemap_global_pos(light.light_position) == tile_pos:
			return light
	return null

# Get the token at a position, need to implement a better way to get the token, currently just checks the global position and needs the token to be in the token group
# Args: Vector2 - The position to check
# Returns: Node2D - The token at the position
func get_all_tokens(index: int) -> Array:
	return map_data[index]["tokens"]

# Hide all tokens on the map with the index
# Args: Node2D - The token to add
# Returns: None
func hide_all_tokens(index: int) -> void:
	for token in map_data[index]["tokens"]:
		token.hide()

# Show all tokens on the map with the index
# Args: Node2D - The token to add
# Returns: None
func show_all_tokens(index: int) -> void:
	for token in map_data[index]["tokens"]:
		token.show()

# Change what map the player tokens are on
# Args: int - The index of the map to change from
#       int - The index of the map to change to
# Returns: None
func change_players_token_map(from: int, to: int) -> void:
	for token in range(map_data[from]["tokens"].size()):
		var current_token = map_data[from]["tokens"][token]
		map_data[to]["tokens"].append(current_token)
		map_data[from]["tokens"].remove_at(token)

# Change what map the player token is on
# Args: int - The index of the map to change from
#       int - The index of the map to change to
#       int - The player id
# Returns: None
func change_player_token_map(from: int, to: int, player_id: int) -> void:
	var player = get_player_token(player_id)
	for token in range(map_data[from]["tokens"].size()):
		var current_token = map_data[from]["tokens"][token]
		if current_token == player:
			map_data[to]["tokens"].append(current_token)
			map_data[from]["tokens"].remove_at(token)
			break

# Get the map the players are currently on
# Args: None
# Returns: int - The index of the map
func get_player_tokens_map() -> int:
	return current_map

func get_specific_player_tokens_map(player_id: int) -> int:
	var player = get_player_token(player_id)
	for index in map_data.keys():
		if map_data[index]["tokens"].find(player) != -1:
			return index
	return 0

# Show only the tokens on the map with the index
# Args: Node2D - The token to add
# Returns: None
func show_only_tokens_on_map(index: int) -> void:
	for i in range(map_data.size()):
		if i != index:
			hide_all_tokens(i)
		else:
			show_all_tokens(index)

# Check if a token is on the map
# Args: Node2D - The token to check
#       int - The index of the map
# Returns: None
func is_token_on_map(token: Variant, index: int) -> bool:
	return map_data[index]["tokens"].find(token) != -1

# Set the current map
# Args: int - The index of the map
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_current_map(index: int) -> void:
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		change_player_token_map(get_specific_player_tokens_map(player.name.to_int()), index, player.name.to_int())
		if sm.has_spawn(map_data[index]["name"]):
			var random_spawn = sm.get_random_spawn(map_data[index]["name"])
			move_to_tile(player, random_spawn)
		else:
			move_to_tile(player, picture_size/2)

	if !Net.is_host():
		show_only_tokens_on_map(index)
	else:
		show_only_tokens_on_map(current_local_map)
	current_map = index
	map_changed.emit(current_map, false, [])
	map_data_changed.emit()
	queue_redraw()

# Set the current local map, only for host
# Args: int - The index of the map
# Returns: None
func set_current_local_map(index: int) -> void:
	current_local_map = index
	show_only_tokens_on_map(index)
	map_changed.emit(current_local_map, true, [])
	queue_redraw()

# Set the player current map
# Args: int - The player id
#       int - The index of the map
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func set_player_current_map(player_id: int, index: int) -> void:
	change_player_token_map(get_specific_player_tokens_map(player_id), index, player_id)
	if sm.has_spawn(map_data[index]["name"]):
		var random_spawn = sm.get_random_spawn(map_data[index]["name"])
		move_to_tile(get_player_token(player_id), random_spawn)
	else:
		move_to_tile(get_player_token(player_id), picture_size/2)

	if !Net.is_host():
		show_only_tokens_on_map(index)
	else:
		show_only_tokens_on_map(current_local_map)
	map_changed.emit(index, false, [player_id])
	map_data_changed.emit()
	queue_redraw()

# get the map index from a map name
# Args: String - The name of the map
# Returns: int - The index of the map
func get_map_index_from_name(_name: String) -> int:
	for index in map_data.keys():
		if map_data[index]["name"] == _name:
			return index
	return 0

# get the map name from a map index
# Args: int - The index of the map
# Returns: String - The name of the map
func get_map_name_from_index(index: int) -> String:
	return map_data[index]["name"]

# Check if the current map is the same as the index
# Args: int - The index of the map
# Returns: bool - If the current map is the same as the index
func is_current_map(index: int) -> bool:
	return current_map == index

# Check if the current local map is the same as the index
# Args: int - The index of the map
# Returns: bool - If the current local map is the same as the index
func is_current_local_map(index: int) -> bool:
	return current_local_map == index

func update_player_vision(player_id: int) -> void:
	var player = get_player_token(player_id)
	player.update_line_of_sight()

# Get the player token based on the player id
# Args: int - The player id
# Returns: Node2D - The player token
func get_player_token(player_id: int) -> Node2D:
	for player in get_tree().get_nodes_in_group("players"):
		if player.name.to_int() == player_id:
			return player
	return null

# ===================== INPUT FUNCTIONS =====================

func _input(event):
	if pause_tilemap_input:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if selected_token != null:
				pam.create_host_context_panel(selected_token, selected_tile)
				pam.create_peer_context_panel(selected_token, selected_tile)
			if selected_tile != null and is_portal_at_position(selected_tile):
				if is_portal_at_position(selected_tile):
					pam.create_portal_context_panel(selected_tile, selected_token, selected_tile)
					pam.create_host_portal_context_panel(selected_tile)
				else:
					pam.create_base_context_panel(null)
			if selected_tile != null and is_light_at_position(selected_tile):
				pam.create_host_light_context_panel(selected_tile)
# ===================== SETTINGS FUNCTIONS =====================


# ===================== HELPER FUNCTIONS =====================

@rpc("any_peer", "call_remote", "reliable")
func update_portal_data(map_name, portal_index, state) -> void:
	if tilemap_data.has(map_name):
		tilemap_data[map_name].portals[portal_index].closed = !state
	
	#ExternalUtility.update_dd2vtt_file(map_name, tilemap_data[map_name]) this is example code, need to implement the actual function
@rpc("any_peer", "call_local", "reliable")
func update_portal_data_for_peers(port_position, state) -> void:
	var port = get_portal_at_position(convert_to_tilemap_global_pos(port_position))
	if port != null:
		if state:
			port.is_open = true
			port.parent.get_node("StaticBody2D").collision_layer = 4
		else:
			port.is_open = false
			port.parent.get_node("StaticBody2D").collision_layer = 2
		map_data_changed.emit()

@rpc("any_peer", "call_remote", "reliable")
func update_light_data_for_peers(light_index, updated_values) -> void:
	var light = lm.cached_lights[get_map_name_from_index(current_local_map)][light_index]
	light.update_state(updated_values)
	map_data_changed.emit()

# Pause the input for the tilemap
# Args: bool - If the input should be paused
# Returns: None
func pause_input(pause: bool) -> void:
	pause_tilemap_input = pause

# Set the picture size
# Args: Vector2 - The size of the picture
# Returns: None
func set_picture_size(size: Vector2) -> void:
	picture_size = size

# Set the map size
# Args: None
# Returns: None
func set_map_size():
	map_width = int(picture_size.x / tile_size.x)
	map_height = int(picture_size.y / tile_size.y)

# Convert a global position to a tilemap position
# Args: Vector2 - The global position
# Returns: Vector2 - The tilemap position
func convert_to_tilemap_pos(global_pos: Vector2) -> Vector2:
	var local_pos = to_local(global_pos)
	return tilemap.local_to_map(local_pos)

# Convert a tilemap position to a global position
# Args: Vector2 - The tilemap position
# Returns: Vector2 - The global position
func convert_to_global_pos(map_pos: Vector2) -> Vector2:
	var local_pos = tilemap.map_to_local(map_pos)
	return to_global(local_pos)

# Convert a global position to a tilemap global position
# Args: Vector2 - The global position
# Returns: Vector2 - The tilemap global position
func convert_to_tilemap_global_pos(global_pos: Vector2) -> Vector2:
	var map_pos = convert_to_tilemap_pos(global_pos)
	return convert_to_global_pos(map_pos)

# Place the tiles on the map
# Args: None
# Returns: None
func place_tiles() -> void:
	for x in range(map_width * 2):
		for y in range(map_height * 2):
			var map_pos = convert_to_tilemap_pos(Vector2(x * tile_size.x, y * tile_size.y))
			tilemap.set_cell(0, map_pos, 0, Vector2i(x, y))
			path_array.append(map_pos)
	tilemap.light_mask = 1

# Create the navigation polygon, FOR FUTURE AI IMPLEMENTATION
# Args: None
# Returns: None
func create_navigation_polygon() -> void:
	var nav_poly = NavigationPolygon.new()
	var poly_points = PackedVector2Array()

	nav_poly.cell_size = tile_size.x

	poly_points.append(Vector2(0, 0))
	poly_points.append(Vector2(0, picture_size.y))
	poly_points.append(Vector2(picture_size.x, picture_size.y))
	poly_points.append(Vector2(picture_size.x, 0))

	nav_poly.add_outline(poly_points)
	nav_poly.make_polygons_from_outlines()

	nav.navigation_polygon = nav_poly

# Create the tileset resource
# Args: String - The path to the texture
# Returns: TileSetAtlasSource - The atlas resource
func create_tileset_resource(texture: Texture2D) -> TileSetAtlasSource:
	var atlas_resource = TileSetAtlasSource.new()

	atlas_resource.texture = texture
	atlas_resource.texture_region_size = tile_size
	set_picture_size(atlas_resource.texture.get_size())
	set_map_size()

	for x in range(map_width):
		for y in range(map_height):
			atlas_resource.create_tile(Vector2i(x,y), Vector2i(1, 1))
	return atlas_resource

# Add the resource to the tileset
# Args: TileSetAtlasSource - The atlas resource
# Returns: None
func add_resource_to_tileset(atlas_resource: TileSetAtlasSource) -> void:
	tilemap.tile_set.add_source(atlas_resource, 0)

# Remove the resource from the tileset
# Args: None
# Returns: None
func remove_resource_from_tileset() -> void:
	if tilemap.tile_set.has_source(0):
		tilemap.tile_set.remove_source(0)

# Draw the selected tile
# Args: None
# Returns: None
func draw_selected_tile() -> void:
	var token = get_token_at_position(selected_tile)
	if token == null:
		draw_rect(Rect2(selected_tile - tile_size/2, tile_size), Color(1, 1, 1, 1), false, 5)
		return

	if token.is_in_group("players") and is_token_on_map(token, current_map):
		draw_rect(Rect2(selected_tile - tile_size/2, tile_size), Color(0, 1, 0, 1), false, 5)
	elif token.is_in_group("enemies") and is_token_on_map(token, current_map):
		draw_rect(Rect2(selected_tile - tile_size/2, tile_size), Color(1, 0, 0, 1), false, 5)
	else:
		draw_rect(Rect2(selected_tile - tile_size/2, tile_size), Color(1, 1, 1, 1), false, 5)

func draw_tile(tile_pos: Vector2, color: Color) -> void:
	draw_rect(Rect2(tile_pos - tile_size/2, tile_size), color, true)

func draw_tile_array(tile_pos: Array, color: Color) -> void:
	for tile in tile_pos:
		draw_tile(tile, color)

func save_map_file():
	for map_name in tilemap_data.keys():
		ExternalUtility.update_dd2vtt_file(map_name, tilemap_data[map_name])
