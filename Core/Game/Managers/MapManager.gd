class_name MapManager extends Node2D
# ===================== MAP MANAGER =====================
# Manages the map, and the players in the game
# TODO: Refactor this manager - monolithic due to time constraints
# MapDataService (Autoload or Node):
	#Responsibility: Loading, caching, and providing access to raw map data (like tilemap_data, Net.maps). Handles interactions with Cache, Net, ExternalUtility. Parses the dd2vtt format.
	#Functions Moved: Parts of create_local_map, create_map related to getting data, save_map_file.
	#State Moved: tilemap_data.
#MapStateService (Autoload or Node):
	#Responsibility: Tracking current_local_map, current_map. Managing the map_data dictionary (which should ideally store entity IDs or references, not necessarily the nodes themselves if those are managed elsewhere). Handles switching map logic.
	#Functions Moved: set_current_map, set_current_local_map, set_player_current_map, get_map_index_from_name, get_map_name_from_index, is_current_map, is_current_local_map, change_players_token_map, etc.
	#State Moved: current_local_map, current_map, map_data.
	#Signals: Would emit signals like map_changing(new_index), map_changed(index).
#TilemapController (Node, likely controlling the TileMap):
	#Responsibility: Directly managing the TileMap node. Setting tiles, managing TileSet resources, scaling.
	#Functions Moved: _auto_scale_tilemap, create_tileset_resource, add/remove_resource_to_tileset, place_tiles. clear_map (tilemap part).
	#State Moved: Reference to tilemap, tile_size.
#MapElementFactory / MapSyncManager (Node):
	#Responsibility: Receiving RPC calls to add/remove/update map elements. Delegates the actual work to the specialized managers (CM, PM, LM, SM, TM, TokM). Handles the logic for storing updates if a client doesn't have the map yet (apply_stored_data).
	#Functions Moved: All the add_*_data, remove_*_data, update_*_data_for_peers RPCs. _create_map_components (orchestration part). apply_stored_data.
	#State Moved: light_data, portal_data, trigger_data (the temporary storage). References to CM, PM, LM, SM, TM, TokM.
#MapCoordinateService (Autoload or helper script):
	#Responsibility: Purely coordinate conversions.
	#Functions Moved: convert_to_tilemap_pos, convert_to_global_pos, convert_to_tilemap_global_pos, get_closest_corner.
	#State Moved: Needs tile_size.
#PathfindingService (Node):
	#Responsibility: A* graph management, path calculation, distance calculation (including trigger costs).
	#Functions Moved: create_astar_from_array, get_distance_to.
	#State Moved: astar, path_array. Needs access to MapCoordinateService and potentially TriggerManager or MapEntityQueryService to check costs.
#MapOverlayDrawer (Node2D, sibling or child of MapManager/Tilemap):
	#Responsibility: All custom drawing logic.
	#Functions Moved: _draw, draw_selected_tile, draw_tile, draw_tile_array, add/clear_global_drawing (receiving data to draw). Handles trigger_ping drawing part.
	#State Moved: is_drawing, distance_path, kept_distance_path, ability_distance_path, kept_ability_distance_path, global_drawings, selected_ping_tile. Needs MapCoordinateService.
#MapInputHandler (Node):
	#Responsibility: Processing _input specifically for map interactions (like selecting tiles, requesting context menus). Should not contain the context menu creation logic itself (that belongs in PanelManager or a dedicated ContextMenuService).
	#Functions Moved: _input logic related to selecting tiles (select_tile) and detecting right-clicks on map elements. pause_input.
	#State Moved: pause_tilemap_input, selected_tile.
	#Interaction: Would likely call MapCoordinateService, MapEntityQueryService, and emit signals like tile_selected(tile_pos), context_menu_requested(global_pos, entity_at_pos).
#MapEntityQueryService (Node or Autoload):
	#Responsibility: Central point for querying what exists at a location.
	#Functions Moved: get_token_at_position, is_portal_at_position, get_portal_at_position, is_light_at_position, etc.
	#Interaction: Needs references to TokM, PM, LM, TM, SM to ask them about their elements. Needs MapCoordinateService.

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
var selected_tile: Vector2 = Vector2.ZERO
var selected_token: Node = null
var selected_tokens: Array
var selected_ping_tile: Vector2 = Vector2.ZERO
var pause_tilemap_input: bool = false :
	get:
		return pause_tilemap_input
	set(value):
		pause_tilemap_input = value
var is_initialized: bool = false

# Pathfinding variables
var astar = AStar2D.new()
var path_array: Array = []

# Map variables
var current_local_map: int = 0
var current_map: int = 0
var is_changing_map = false
var map_data: Dictionary = {0 : {"tokens": [], "name": Settings.prologue_map}}
var light_data: Dictionary = {0 : {}}
var portal_data: Dictionary = {0 : {}}
var trigger_data: Dictionary = {0 : {}}

# Drawing variables
var is_drawing: bool = false
var distance_path: Array = []
var kept_distance_path: Array = []
var ability_distance_path: Array = []
var kept_ability_distance_path: Dictionary = {}
var global_drawings = {}

# Managers
var cm: CollisionManager = null
var pm: PortalManager = null
var lm: LightManager = null
var pam: PanelManager = null
var sm: SpawnManager = null
var tm: TriggerManager = null
var tokm: TokenManager = null

# Ping variables
var ping_amount = 0
const PING_MAX_AMOUNT = 3
const PING_INTERVAL = 7.0
var ping_timer = 0.0

var game_paused = false
const TOKEN_PHYSICS_LAYER = 1
var space_state: PhysicsDirectSpaceState2D

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

func get_map_input():
	return !pause_tilemap_input

func _ready() -> void:
	_initialize_components()
	add_to_group("Map")
	Bus.pause_map_input.connect(pause_input)
	space_state = get_world_2d().direct_space_state
	if Net.is_host():
		await create_local_map(Settings.prologue_map)
		current_local_map = 0
		Net.map_loaded.rpc(Settings.prologue_map)
		await get_tree().process_frame
		map_initialized.emit()
	else:
		Net.map_sent.connect(initialize_map)

func _process(delta: float) -> void:
	if ping_timer < PING_INTERVAL:
		ping_timer += delta
	else:
		ping_timer = 0.0
		ping_amount = 0

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
	tm = TriggerManager.new()
	tm.map_manager = self
	add_child(tm)	
	tokm = TokenManager.new()
	tokm.map_manager = self
	add_child(tokm)

# Test scaling token sent tile size up or down depending on the result
# Test scaling final tile_size up or down depending on the result
# Helper.is_hdpi_scaling
# on 300x300 pixel per grid
# tile_size = Vector2(300, 300)
# tile_size sent to tokens = Vector2(300, 300)
# tilemap.sile_set.tile_size = Vector2(150,150)
# Doesnt scale at all
func _auto_scale_tilemap(image_resolution):
	if tilemap == null:
		tilemap = get_parent().get_parent().get_node("TileMap")
	tile_size = Vector2(image_resolution["pixels_per_grid"], image_resolution["pixels_per_grid"])
	print("Tilemap start tile size: ", tile_size)
	Bus.send_tile_size.emit(tile_size)
	tilemap.tile_set.tile_size = tile_size
	print("Tilemap end tile size: ", tilemap.tile_set.tile_size)
	print("Image resolution: ", image_resolution["pixels_per_grid"])

# Initialize the map for all peers except host
# Args: None
# Returns: None
func initialize_map(map_name: String) -> void:
	Net.show_loading_screen()
	await create_map(map_name)
	map_changed.emit(get_map_index_from_name(map_name), false, [])
	Net.hide_loading_screen()

func _draw():
	for key in global_drawings:
		if key != multiplayer.get_unique_id():
			draw_tile_array(global_drawings[key], Color(1, 1, 1, 0.3))

	draw_tile_array(kept_distance_path, Color(1, 1, 1, 0.3))
	draw_tile_array(ability_distance_path, Color(1, 1, 1, 0.3))
	for key in kept_ability_distance_path:
		draw_tile_array(kept_ability_distance_path[key]["path"], Color(1, 1, 1, 0.3))

	if is_drawing:
		draw_tile_array(distance_path, Color(1, 1, 1, 0.3))
	else:
		draw_selected_tile()

@rpc("any_peer", "call_local", "reliable")
func add_global_drawing(player_id: int, drawing: Variant, keep: bool = false) -> void:
	if !global_drawings.has(player_id):
		global_drawings[player_id] = []
		
	if drawing is Vector2:
		if not drawing in global_drawings[player_id]:
			global_drawings[player_id].append(drawing)
	elif drawing is Array:
		if keep:
			# Keep existing drawings and add only new unique ones
			for item in drawing:
				if not item in global_drawings[player_id]:
					global_drawings[player_id].append(item)
		else:
			# Replace with new array, ensuring all items are unique
			var unique_drawings = []
			for item in drawing:
				if not item in unique_drawings:
					unique_drawings.append(item)
			global_drawings[player_id] = unique_drawings
	queue_redraw()

@rpc("any_peer", "call_local", "reliable")
func clear_global_drawing(player_id: int) -> void:
	if global_drawings.has(player_id):
		global_drawings[player_id].clear()
	queue_redraw()

@rpc("any_peer", "call_local", "reliable")
func clear_all_global_drawing() -> void:
	global_drawings = {}
	queue_redraw()

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
	_auto_scale_tilemap(tilemap_data[map_name]["resolution"])
	create_tilemap(ExternalUtility.convert_Base64_to_texture(tilemap_data[map_name].image))
	await _create_map_components(map_name, tilemap_data)
	is_changing_map = false

# Create a map
# Args: String - The name of the map
# Returns: None
@rpc("any_peer", "call_remote", "reliable")
func create_map(map_name: String):
	Net.show_loading_screen()
	map_name = map_name.replace(" ", "_")
	if !Net.has_map(map_name):
		await Net.get_dd2vtt_request(map_name)
	clear_map()
	await map_cleared
	_auto_scale_tilemap(Net.maps[map_name]["resolution"])
	create_tilemap(Net.maps[map_name]["image"])
	await _create_map_components(map_name, Net.maps)

	var players = get_tree().get_nodes_in_group("players")
	if sm.cached_spawns.size() > 0 and sm.cached_spawns.has(map_name):
		for spawn in sm.cached_spawns[map_name]:
				var random_spawn = sm.cached_spawns[map_name][randi() % sm.cached_spawns[map_name].size()]
				for player in players:
					move_to_tile(player, random_spawn.spawn_position, false)
					break
	else:
		for player in players:
			move_to_tile(player, picture_size/2, false)
			break
	apply_stored_data(map_name)
	emit_map_created.rpc_id(1)
	Net.hide_loading_screen()

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
	if data[map_name].has("triggers"):
		tm.create_trigger(data[map_name]["triggers"], map_name)
	else:
		data[map_name]["triggers"] = []
		tm.create_trigger(data[map_name]["triggers"], map_name)
	if data[map_name].has("tokens"):
		tokm.create_tokens(data[map_name]["tokens"], map_name)
	else:
		data[map_name]["tokens"] = []
		tokm.create_tokens(data[map_name]["tokens"], map_name)
	for p in get_all_portals():
		p.initialize_state()
	map_data_changed.emit()

# When the gm switches to a map that has not been downloaded by the player I need to store the data and apply it when the player has downloaded the map 
# (only because I don´t have a efficient way to asynchronously download all the maps)
func apply_stored_data(map_name: String):
	if light_data.has(map_name):
		for l in light_data[map_name]:
			update_light_data_for_peers(l, light_data[map_name][l])
		light_data[map_name].clear()

	if portal_data.has(map_name):
		for p in portal_data[map_name]:
			update_portal_data_for_peers(p, portal_data[map_name][p])
		portal_data[map_name].clear()

	if trigger_data.has(map_name):
		for t in trigger_data[map_name]:
			update_trigger_data_for_peers(t, trigger_data[map_name][t])
		trigger_data[map_name].clear()

# ===================== MAP CREATION FUNCTIONS =================
# Add data to the map
# Args: int - The index of the map
#       String - The name of the map
#       Array - The tokens on the map
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func add_data(index: int, map_name: String, tokens: Array) -> void:
	if map_data.has(index):
		map_data[index]["tokens"].append_array(tokens)
	else:
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
		if !map_data.has(indices[i]):
			map_data[indices[i]] = {"tokens": tokens[i], "name": map_names[i].replace(" ", "_")}
		else:
			map_data[indices[i]]["tokens"].append_array(tokens[i])
			map_data[indices[i]]["name"] = map_names[i].replace(" ", "_")
	data_added.emit()

@rpc("any_peer", "call_local", "reliable")
func add_spawn_data(map_name: String, pos: Vector2) -> void:
	sm.add_spawn(pos, map_name)

@rpc("any_peer", "call_local", "reliable")
func remove_spawn_data(map_name: String, pos: Vector2) -> void:
	sm.remove_spawn(pos, map_name)

@rpc("any_peer", "call_local", "reliable")
func add_light_data(map_name: String, light: Vector2) -> void:
	lm.add_light(light, map_name)

@rpc("any_peer", "call_local", "reliable")
func remove_light_data(map_name: String, light: Variant) -> void:
	lm.remove_light(light, map_name)

@rpc("any_peer", "call_local", "reliable")
func add_trigger_data(map_name: String, trigger_type: String, pos: Vector2) -> void:
	tm.add_trigger(trigger_type, pos, map_name)

@rpc("any_peer", "call_local", "reliable")
func remove_trigger_data(map_name: String, pos: Vector2) -> void:
	tm.remove_trigger(pos, map_name)

@rpc("any_peer", "call_local", "reliable")
func add_wall_data(map_name: String, points: Array, type: String) -> void:
	cm.add_wall(points, map_name, type)

@rpc("any_peer", "call_local", "reliable")
func remove_wall_data(map_name: String, points: Array) -> void:
	cm.remove_wall(points, map_name)

@rpc("any_peer", "call_local", "reliable")
func add_token_data(map_name: String, token_data: Dictionary) -> void:
	tokm.add_token(token_data, map_name)

@rpc("any_peer", "call_local", "reliable")
func remove_token_data(map_name: String, token_name: String, token_position: Vector2) -> void:
	tokm.remove_token(token_name, token_position, map_name)

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
	for wall_segment in walls:
		# Extract points (all dictionaries with x,y coordinates)
		var points = Helper.dict2vector2array(wall_segment, resolution)
		var line = Line2D.new()
		line.points = points
		
		# Check each dictionary in the segment for a type field
		for item in wall_segment:
			if item.has("type"):
				line.set_meta("type", item["type"])
				break  # Found the type, no need to continue
				
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
func move_to_tile(player: Node2D, to: Vector2, is_triggering: bool = true) -> void:
	var map_pos = convert_to_tilemap_pos(to)
	var from_pos = convert_to_tilemap_pos(player.global_position)

	if !is_inside_tilemap(map_pos):
		return

	if is_triggering:
		var path = astar.get_point_path(path_array.find(from_pos), path_array.find(map_pos))
		
		# Skip the first position (starting position) to avoid re-triggering
		for i in range(1, path.size()):
			var current_pos = path[i]
			var global_pos = convert_to_global_pos(current_pos)
			
			# Check if this position has a trigger
			if is_trigger_at_position(global_pos):
				# If this is the first time stepping on this trigger in this movement
				# (wasn't the position we're coming from)
				if current_pos != from_pos:
					get_trigger_at_position(global_pos).execute(player)

	player.global_position = convert_to_global_pos(map_pos)
	map_data_changed.emit()
	queue_redraw()

# Get the distance from start position to end position, converted to feet (one tile is 5 feet)
# Args: Vector2 - The start position
#       Vector2 - The end position
# Returns: int - The distance in feet
func get_distance_to(start: Vector2, end: Vector2, is_draw: bool = false, is_global: bool = false, keep: bool = false, fixed_distance: int = 0) -> int:
	var map_start = convert_to_tilemap_pos(start)
	var map_end = convert_to_tilemap_pos(end)

	var path = astar.get_point_path(path_array.find(map_start), path_array.find(map_end))
	
	# Determine which path array to use based on fixed_distance
	var target_path_array = ability_distance_path if fixed_distance > 0 else distance_path

	if is_draw:
		# Clear the appropriate path array
		target_path_array.clear()
		
		# Always add the start point
		target_path_array.append(convert_to_global_pos(path[0]))
		
		var accumulated_distance = 0
		var diagonal_counter = 0
		var has_fixed_distance = fixed_distance > 0
		
		# Process each point in the path
		for i in range(1, path.size()):
			var prev_point = path[i-1]
			var current_point = path[i]
			var current_global_position = convert_to_global_pos(current_point)
			
			# Calculate the cost for this segment
			var base_cost = 5
			if is_trigger_at_position(current_global_position):
				var trigger = get_trigger_at_position(current_global_position)
				if trigger.trigger_type == "Terrain":
					base_cost = trigger.cost_multiplier * 5
			
			# Check if movement is diagonal
			var is_diagonal = prev_point.x != current_point.x and prev_point.y != current_point.y
			var segment_cost = 0
			
			if is_diagonal:
				diagonal_counter += 1
				if diagonal_counter % 2 == 1:
					# First, third, fifth, etc. diagonal - normal cost
					segment_cost = base_cost
				else:
					# Second, fourth, sixth, etc. diagonal - double cost
					segment_cost = base_cost * 2
			else:
				# Non-diagonal movement - normal cost
				segment_cost = base_cost
			
			# Check if adding this segment would exceed the fixed distance
			if has_fixed_distance and (accumulated_distance + segment_cost) > fixed_distance:
				# Don't add this point, we've reached our limit
				break
			
			# Add this cost to the accumulated distance
			accumulated_distance += segment_cost
			
			# Add this point to the path
			target_path_array.append(current_global_position)
		
		if is_global:
			add_global_drawing.rpc(multiplayer.get_unique_id(), target_path_array, keep)
		queue_redraw()
		
		return accumulated_distance
	
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

func deselect_tile():
	selected_tile = Vector2.ZERO
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
		if child.global_position == convert_to_tilemap_global_pos(global_pos):
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
	ErrorUtility.log_error("No portal found at position: " + str(tile_pos) + "MapManager.gd" + "get_portal_at_position")
	
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
	var map_index = current_local_map if Net.is_host() else current_map
	for light in lm.cached_lights[get_map_name_from_index(map_index)]:
		if convert_to_tilemap_global_pos(light.light_position) == convert_to_tilemap_global_pos(tile_pos):
			return true
	return false

func get_light_at_position(tile_pos: Vector2) -> Variant:
	var map_index = current_local_map if Net.is_host() else current_map
	for light in lm.cached_lights[get_map_name_from_index(map_index)]:
		if convert_to_tilemap_global_pos(light.light_position) == convert_to_tilemap_global_pos(tile_pos):
			return light
	ErrorUtility.log_error("No light found at position: " + str(tile_pos) + "MapManager.gd" + "get_light_at_position")
	return null

func is_trigger_at_position(tile_pos: Vector2) -> bool:
	var map_index = current_local_map if Net.is_host() else current_map
	for trigger in tm.cached_triggers[get_map_name_from_index(map_index)]:
		if convert_to_tilemap_global_pos(trigger.trigger_position) == convert_to_tilemap_global_pos(tile_pos):
			return true
	return false

func get_trigger_at_position(tile_pos: Vector2) -> Variant:
	var map_index = current_local_map if Net.is_host() else current_map
	for trigger in tm.cached_triggers[get_map_name_from_index(map_index)]:
		if convert_to_tilemap_global_pos(trigger.trigger_position) == convert_to_tilemap_global_pos(tile_pos):
			return trigger
	ErrorUtility.log_error("No trigger found at position: " + str(tile_pos) + "MapManager.gd" + "get_trigger_at_position")
	return null

func is_spawn_at_position(tile_pos: Vector2) -> bool:
	var map_index = current_local_map if Net.is_host() else current_map
	for spawn in sm.cached_spawns[get_map_name_from_index(map_index)]:
		if convert_to_tilemap_global_pos(spawn.spawn_position) == convert_to_tilemap_global_pos(tile_pos):
			return true
	return false

func get_spawn_at_position(tile_pos: Vector2) -> Variant:
	var map_index = current_local_map if Net.is_host() else current_map
	for spawn in sm.cached_spawns[get_map_name_from_index(map_index)]:
		if convert_to_tilemap_global_pos(spawn.spawn_position) == convert_to_tilemap_global_pos(tile_pos):
			return spawn
	ErrorUtility.log_error("No spawn found at position: " + str(tile_pos) + "MapManager.gd" + "get_spawn_at_position")
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
	remove_invalid_tokens(index)

	for token in map_data[index]["tokens"]:
		if !is_instance_valid(token) or token.is_queued_for_deletion() or token == null:
			continue
		token.hide()

# Show all tokens on the map with the index
# Args: Node2D - The token to add
# Returns: None
func show_all_tokens(index: int) -> void:
	remove_invalid_tokens(index)

	for token in map_data[index]["tokens"]:
		if !is_instance_valid(token) or token.is_queued_for_deletion() or token == null:
			continue
		token.show()

func add_token_to_map(token: Node2D, index: Variant) -> void:
	if index is String:
		index = get_map_index_from_name(index)

	print("Adding token to map: " + str(index))

	if map_data.has(index):
			map_data[index]["tokens"].append(token)
	else:
		map_data[index]["tokens"] = [token]

func check_if_tokens_are_valid(index: Variant) -> bool:
	if index is String:
		index = get_map_index_from_name(index)

	if map_data.has(index):
		for token in map_data[index]["tokens"]:
			if !is_instance_valid(token) or token.is_queued_for_deletion() or token == null:
				return false
	return true

func remove_invalid_tokens(index: Variant) -> void:
	if index is String:
		index = get_map_index_from_name(index)

	if map_data.has(index):
		for token in map_data[index]["tokens"]:
			if !is_instance_valid(token) or token.is_queued_for_deletion() or token == null:
				map_data[index]["tokens"].remove_at(map_data[index]["tokens"].find(token))

func remove_token_from_map(token: Node2D, index: Variant) -> void:
	if index is String:
		index = get_map_index_from_name(index)

	if map_data.has(index):
		map_data[index]["tokens"].remove_at(map_data[index]["tokens"].find(token))
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
func is_token_on_map(token: Variant, index: Variant) -> bool:
	if index is String:
		index = get_map_index_from_name(index)
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
			move_to_tile(player, random_spawn, false)
		else:
			move_to_tile(player, picture_size/2, false)

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
@rpc("any_peer", "call_local", "reliable")
func set_current_local_map(index: int) -> void:
	current_local_map = index
	if Net.is_host():
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
		move_to_tile(get_player_token(player_id), random_spawn, false)
	else:
		move_to_tile(get_player_token(player_id), picture_size/2, false)

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

func unpossess_all_tokens() -> void:
	for token in get_tree().get_nodes_in_group("token"):
		if "is_possesed" in token:
			token.is_possesed = false

func get_closest_corner(pos: Vector2) -> Vector2:
	var grid_pos = Vector2(
		floor(pos.x / tile_size.x),
		floor(pos.y / tile_size.y)
	)
	
	var corners = [
		Vector2(grid_pos.x * tile_size.x, grid_pos.y * tile_size.y),                    # Top-left
		Vector2((grid_pos.x + 1) * tile_size.x, grid_pos.y * tile_size.y),              # Top-right
		Vector2(grid_pos.x * tile_size.x, (grid_pos.y + 1) * tile_size.y),              # Bottom-left
		Vector2((grid_pos.x + 1) * tile_size.x, (grid_pos.y + 1) * tile_size.y)         # Bottom-right
	]
	
	var closest_corner = corners[0]
	var closest_distance = pos.distance_to(corners[0])
	
	for i in range(1, corners.size()):
		var distance = pos.distance_to(corners[i])
		if distance < closest_distance:
			closest_distance = distance
			closest_corner = corners[i]
	
	return to_global(closest_corner)

@rpc("any_peer", "call_local", "reliable")
func trigger_ping(selected: Vector2) -> void:
	if ping_amount >= PING_MAX_AMOUNT:
		return
	ping_amount += 1
	Audio.play_sfx_audio(load("res://Assets/Audio/SFX/Ping/ping-sound.mp3"))
	selected_ping_tile = selected
	queue_redraw()
	await get_tree().create_timer(0.8).timeout
	selected_ping_tile = Vector2.ZERO
	queue_redraw()

# ===================== INPUT FUNCTIONS =====================

func _input(event):
	if event is InputEventKey:
		if Net.is_host():
			if Input.is_action_just_pressed("SPACE"):
				pause_game.rpc(!game_paused)
			if Input.is_action_just_pressed("DELETE"):
				if selected_token != null:
					if selected_token.is_in_group("npc"):
						remove_token_data.rpc(get_map_name_from_index(current_local_map), selected_token.name, selected_token.global_position)
					else:
						ErrorUtility.print_error("Cannot remove a player token.")
			if Input.is_action_just_pressed("ui_cancel"):
				if selected_tokens.size() > 0:
					selected_tokens.clear()

	if pause_tilemap_input:
		return

	if event is InputEventMouseButton:
		# --- Right Mouse Button Pressed ---
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:

			# 1. Ignore clicks if a UI Panel is likely intercepting input
			#    (A more robust check might involve checking mouse filter on panels)
			if get_tree().get_nodes_in_group("Panels").size() > 0:
				print("Panel detected, ignoring right click for token selection.")
				return

			# 2. --- Check for Token under Mouse ---
			var clicked_token = null # Temp variable to store token found under mouse
			if not space_state:
				printerr("Space state not available for token check!")
			else:
				var mouse_pos = get_mouse_position() # Use event position for accuracy
				var query = PhysicsPointQueryParameters2D.new()
				query.position = mouse_pos
				# Set mask to ONLY check the token layer
				query.collision_mask = 1 # Bitmask for the token layer
				query.collide_with_areas = false # Assuming tokens aren't just Area2Ds
				query.collide_with_bodies = true

				var results: Array = space_state.intersect_point(query)

				# Find the first valid token collider in the results
				for result in results:
					var collider = result.get("collider")
					# Check if the collider is a valid node and belongs to the "tokens" group
					# (Adjust group name or use a class check if appropriate)
					if is_instance_valid(collider) and collider.is_in_group("token"):
						clicked_token = collider
						print("Right-clicked on token: ", clicked_token.name)
						break # Found a token, stop checking
					print(collider)

			selected_token = clicked_token # This sets it to the found token, or null if none found

			if is_instance_valid(selected_token):
				pam.create_host_context_panel(selected_token, selected_tile)
				pam.create_peer_context_panel(selected_token, selected_tile)
				print("Show context menu for selected token: ", selected_token.name)

			# Check tile-based context menus ONLY if no token menu was shown
			elif selected_tile != Vector2.ZERO:
				var anything_selected = false
				if is_portal_at_position(selected_tile):
					print("Show portal context menu for tile: ", selected_tile)
					pam.create_portal_context_panel(selected_tile, selected_token, selected_tile)
					pam.create_host_portal_context_panel(selected_tile)
					anything_selected = true
				if is_light_at_position(selected_tile):
					print("Show light context menu for tile: ", selected_tile)
					pam.create_host_light_context_panel(selected_tile)
					anything_selected = true
				if is_trigger_at_position(selected_tile):
					print("Show trigger context menu for tile: ", selected_tile)
					pam.create_host_trigger_context_panel(selected_tile)
					anything_selected = true
				if is_spawn_at_position(selected_tile):
					print("Show spawn context menu for tile: ", selected_tile)
					pam.create_base_context_panel(get_spawn_at_position(selected_tile))
					anything_selected = true

			# Fallback: Show basic tile context menu if nothing else was relevant
			# Condition: Click wasn't handled, tile is selected, NOT any special object, and NO token selected
				if !anything_selected:
					print("Show basic context menu for selected tile: ", selected_tile)
					pam.create_selected_tile_context_panel(selected_tile)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			pass

# ===================== SETTINGS FUNCTIONS =====================


# ===================== HELPER FUNCTIONS =====================

@rpc("any_peer", "call_remote", "reliable")
func update_portal_data(map_name, portal_index, state) -> void:
	if tilemap_data.has(map_name) and tilemap_data[map_name].portals.size() > portal_index:
		tilemap_data[map_name].portals[portal_index].closed = !state["open"]
		tilemap_data[map_name].portals[portal_index].locked = state["locked"]
		tilemap_data[map_name].portals[portal_index].hidden = state["hidden"]
	
	#ExternalUtility.update_dd2vtt_file(map_name, tilemap_data[map_name]) this is example code, need to implement the actual function
@rpc("any_peer", "call_local", "reliable")
func update_portal_data_for_peers(port_position, state) -> void:
	var port = get_portal_at_position(convert_to_tilemap_global_pos(port_position))
	if port != null:
		if state["open"]:
			port.open_portal(true)
		elif !state["open"]:
			port.close_portal(true)
		if state["locked"]:
			port.lock_portal(true)
		elif !state["locked"]:
			port.unlock_portal(true)
		if state["hidden"]:
			port.hide_portal(true)
		elif !state["hidden"]:
			port.show_portal(true)
		map_data_changed.emit()
	else:
		ErrorUtility.log_warning("Portal not found, storing data")
		if not current_map in portal_data:
			portal_data[current_map] = {}
		portal_data[current_map][port_position] = state

@rpc("any_peer", "call_remote", "reliable")
func update_light_data_for_peers(light_index, updated_values) -> void:
	if lm.cached_lights.has(get_map_name_from_index(current_local_map)) and lm.cached_lights[get_map_name_from_index(current_local_map)].size() > light_index:
		var light = lm.cached_lights[get_map_name_from_index(current_local_map)][light_index]
		var update_shader = true if current_local_map == current_map else false
		light.update_state(updated_values, update_shader)
		map_data_changed.emit()
	else:
		ErrorUtility.log_warning("Light not found, storing data")
		var map_name = get_map_name_from_index(current_local_map)
		if not map_name in light_data:
			light_data[map_name] = {}
		light_data[map_name][light_index] = updated_values
	Bus.update_shader_wall_data.emit()

@rpc("any_peer", "call_remote", "reliable")
func update_trigger_data_for_peers(trigger_pos, updated_values) -> void:
	var trigger = get_trigger_at_position(convert_to_tilemap_global_pos(trigger_pos))
	if trigger != null:
		trigger.update_state(updated_values)
		map_data_changed.emit()
	else:
		ErrorUtility.log_warning("Trigger not found, storing data")
		if not current_map in trigger_data:
			trigger_data[current_map] = {}
		trigger_data[current_map][trigger_pos] = updated_values

# Pause the input for the tilemap
# Args: bool - If the input should be paused
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func pause_input(pause: bool) -> void:
	pause_tilemap_input = pause

@rpc("authority", "call_local", "reliable")
func pause_game(visible: bool) -> void:
	get_tree().get_first_node_in_group("GameUI").get_node("GamePause").visible = visible
	pause_tilemap_input = visible
	for token in get_tree().get_nodes_in_group("token"):
		token.is_paused = visible
	game_paused = visible

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
	if selected_tokens.size() > 0:
		for t in selected_tokens:
			draw_rect(Rect2(convert_to_tilemap_global_pos(t.global_position) - tile_size/2, tile_size), Color.YELLOW, false, 5)

	if token == null:
		if selected_ping_tile != Vector2.ZERO:
			draw_rect(Rect2(selected_ping_tile - tile_size/2, tile_size), Color.REBECCA_PURPLE, false, 5)
			return
		elif selected_tile == Vector2.ZERO:
			return
		draw_rect(Rect2(selected_tile - tile_size/2, tile_size), Color(1, 1, 1, 1), false, 5)
		return

	if token.is_in_group("players") and is_token_on_map(token, current_map):
		draw_rect(Rect2(selected_tile - tile_size/2, tile_size), Color(0, 1, 0, 1), false, 5)
	elif token.is_in_group("enemies") and is_token_on_map(token, current_map):
		draw_rect(Rect2(selected_tile - tile_size/2, tile_size), Color(1, 0, 0, 1), false, 5)
	elif selected_tile == Vector2.ZERO:
		return
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
