extends Node2D
# ===================== MAP MANAGER =====================
# Manages the map, and the players in the game
# ======================================================

#Public Variables
@export var picture_size: Vector2 = Vector2(6300, 4200)
@export var tile_size: Vector2 = Vector2(300, 300)
@export var tilemap: TileMap = null
@export var illumination: Node = null
@export var nav: NavigationRegion2D = null

var tilemap_data: Dictionary = {}

# Tilemap variables
var line_walls: Node2D = null
var portals: Node2D = null
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
var map_data: Dictionary = {0 : {"tokens": [], "name": Settings.prologue_map, "bytes": null}}

# ===================== SIGNALS =====================

signal map_initialized()

# ===================== CORE FUNCTIONS =====================

# initialize the map for local player/server
# Args: None
# Returns: None

func _ready() -> void:
	line_walls = Node2D.new()
	line_walls.name = "Line Walls"
	line_walls.visible = true
	add_child(line_walls)

	portals = Node2D.new()
	portals.name = "Portals"
	portals.visible = true
	add_child(portals)

	if tilemap == null:
		tilemap = get_parent().get_parent().get_node("TileMap")

	if Net.is_host():
		await create_local_map(Settings.prologue_map)
		Net.map_loaded.rpc(Settings.prologue_map)
		map_initialized.emit()
	else:
		Net.map_sent.connect(initialize_map)

@rpc("any_peer", "call_local", "reliable")
func add_data(index: int, map_name: String, tokens: Array) -> void:
	map_data[index] = {"tokens": tokens, "name": map_name}

@rpc("any_peer", "call_local", "reliable")
func add_data_array(indices: Array, map_names: Array, tokens: Array) -> void:
	for i in range(indices.size()):
		if tokens[i].find("players") != -1:
			tokens[i].clear()
			tokens[i].append_array(get_tree().get_nodes_in_group("players"))
			
			current_map = indices[i]
		map_data[indices[i]] = {"tokens": tokens[i], "name": map_names[i]}

# Initialize the map for all peers except host
# Args: None
# Returns: None
func initialize_map(map_name: String) -> void:
	await get_tree().create_timer(1.0).timeout
	await create_map(map_name)

func _draw():
	draw_selected_tile()

# Create a local map
# Args: String - The name of the map
# Returns: None
func create_local_map(map_name: String) -> void:
	var full_path = "user://Assets/Maps/" + map_name + ".dd2vtt"
	if !Net.has_map(map_name):
		await Net.send_dd2vtt_request(full_path)
		Net.add_map(map_name)
	if !tilemap_data.has(map_name):
		var data = ExternalUtility.process_dd2vtt_file(full_path)
		tilemap_data[map_name] = data
	clear_map()
	create_tilemap(ExternalUtility.convert_Base64_to_texture(tilemap_data[map_name].image))
	create_walls(tilemap_data[map_name].line_of_sight, tilemap_data[map_name].resolution)
	create_collision(line_walls)
	create_portals(tilemap_data[map_name].portals, tilemap_data[map_name].resolution)
	create_collision(portals)

# Create a map
# Args: String - The name of the map
# Returns: None
@rpc("any_peer", "call_remote", "reliable")
func create_map(map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	if !Net.has_map(map_name):
		await Net.get_dd2vtt_request(map_name)
	clear_map()
	create_tilemap(Net.maps[map_name]["image"])
	create_walls(Net.maps[map_name]["line_of_sight"], Net.maps[map_name]["resolution"])
	create_collision(line_walls)
	create_portals(Net.maps[map_name]["portals"], Net.maps[map_name]["resolution"])
	create_collision(portals)


# ===================== MAP FUNCTIONS =================
func create_tilemap(texture: Texture2D) -> void:
	var atlas_resource = create_tileset_resource(texture)
	add_resource_to_tileset(atlas_resource)
	place_tiles()
	create_astar_from_array(path_array)

func clear_map():
	tilemap.clear()
	remove_resource_from_tileset()
	for wall in line_walls.get_children():
		wall.queue_free()
	for portal in portals.get_children():
		portal.queue_free()
	astar.clear()
	path_array.clear()

func create_walls(walls: Array, resolution) -> void:
	for blocker in walls:
		var points = dict2vector2array(blocker, resolution)
		var line = Line2D.new()
		line.points = points
		line_walls.add_child(line)

func create_collision(walls_node: Node) -> void:
	for line in walls_node.get_children():
		if line is Line2D and line.points.size() >= 2:
			var static_body = StaticBody2D.new()
			static_body.name = "StaticBody2D"
			static_body.collision_layer = 2
			static_body.collision_mask = 1
			line.add_child(static_body)
			
			for j in range(line.points.size() - 1):
				var collision_shape = CollisionShape2D.new()
				var rect = RectangleShape2D.new()
				
				# Position at midpoint
				var start = line.points[j]
				var end = line.points[j + 1]
				collision_shape.global_position = (start + end) / 2
				
				# Rotate to match line direction
				collision_shape.rotation = start.direction_to(end).angle()
				
				# Set size (length of segment, thickness)
				var length = start.distance_to(end)
				rect.extents = Vector2(length / 2, 5)  # 10 pixels thick
				
				collision_shape.shape = rect
				static_body.add_child(collision_shape)

func create_portals(portalss: Array, resolution) -> void:
	for portal in portalss:
		var points = dict2vector2array(portal.bounds, resolution)
		var line = Line2D.new()
		line.points = points
		portals.add_child(line)

# Move the player to a tile, currently checks for out of bounds but need to implement collision (should be gathered from the tilemap custom data on the tile)
# Args: Node2D - The player that will be moved
#       Vector2 - The global position of the tile
# Returns: None
func move_to_tile(player: Node2D, global_pos: Vector2) -> void:
	var map_pos = convert_to_tilemap_pos(global_pos)

	if !is_inside_tilemap(map_pos):
		return

	player.global_position = convert_to_global_pos(map_pos)
	queue_redraw()

# Get the distance from start position to end position, converted to feet (one tile is 5 feet)
# Args: Vector2 - The start position
#       Vector2 - The end position
# Returns: int - The distance in feet
func get_distance_to(start: Vector2, end: Vector2) -> int:
	var map_start = convert_to_tilemap_pos(start)
	var map_end = convert_to_tilemap_pos(end)

	var path = astar.get_point_path(path_array.find(map_start), path_array.find(map_end))
	return (path.size() - 1) * 5

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

# Check if a tile is selected
# Args: Vector2 - The global position of the tile
# Returns: bool - If the tile is selected
func is_tile_selected(global_pos: Vector2) -> bool:
	var tile_pos = convert_to_tilemap_global_pos(global_pos)
	return selected_tile == tile_pos

func is_selected_tile_player() -> bool:
	var token = get_token_at_position(selected_tile)
	if token == null:
		return false
	return token.is_in_group("players")

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

func is_global_inside_tilemap(global_pos: Vector2) -> bool:
	var map_pos = convert_to_tilemap_pos(global_pos)
	return is_inside_tilemap(map_pos)

func get_tilemap_start_pos() -> Vector2:
	return convert_to_global_pos(Vector2(0, 0)) - tile_size/2

func get_tilemap_end_pos() -> Vector2:
	return convert_to_global_pos(Vector2(map_width, map_height)) + tile_size/2

func get_tilemap_view_distance() -> int:
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

func change_players_token_map(from: int, to: int) -> void:
	for token in range(map_data[from]["tokens"].size()):
		var current_token = map_data[from]["tokens"][token]
		map_data[to]["tokens"].append(current_token)
		map_data[from]["tokens"].remove_at(token)

func get_player_tokens_map() -> int:
	return current_map

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
func set_current_map(index: int) -> void:
	change_players_token_map(get_player_tokens_map(), index)
	if !Net.is_host():
		show_only_tokens_on_map(index)
	else:
		show_only_tokens_on_map(current_local_map)
	current_map = index
	queue_redraw()

func set_current_local_map(index: int) -> void:
	current_local_map = index
	show_only_tokens_on_map(index)
	queue_redraw()

func get_map_index_from_name(_name: String) -> int:
	for index in map_data.keys():
		if map_data[index]["name"] == _name:
			return index
	return 0

# Check if the current map is the same as the index
# Args: int - The index of the map
# Returns: bool - If the current map is the same as the index
func is_current_map(index: int) -> bool:
	return current_map == index

func is_current_local_map(index: int) -> bool:
	return current_local_map == index

# ===================== INPUT FUNCTIONS =====================

# For testing purposes
# Args: None
# Returns: None
func do_nothing() -> void:
	pass

func create_base_context_panel() -> context_panel:
	var context = context_panel.new()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.create_panel(get_viewport().get_mouse_position(), Vector2(0,0))
	context.add_button("Inspect", do_nothing)
	return context

func create_host_context_panel(selected) -> void:
	if !Net.is_host():
		return
	var context = create_base_context_panel()
	context.add_button("Move", selected.move_token)
	if !selected.is_hidden:
		context.add_button("Hide", selected.hide_token)
	else:
		context.add_button("Show", selected.show_token)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if selected_token != null:
				create_host_context_panel(selected_token)

# ===================== HELPER FUNCTIONS =====================

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
	illumination.size = picture_size

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
	for x in range(map_width):
		for y in range(map_height):
			var map_pos = convert_to_tilemap_pos(Vector2(x * tile_size.x, y * tile_size.y))
			tilemap.set_cell(0, map_pos, 0, Vector2i(x, y))
			path_array.append(map_pos)

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

func convert_coords(vect: Vector2, resolution: Dictionary)->Vector2:
	return Vector2(vect.x*resolution.pixels_per_grid, vect.y*resolution.pixels_per_grid)

func dict2vector2array(dict_array:Array,resolution:Dictionary):
	@warning_ignore("unassigned_variable")
	var array: PackedVector2Array
	for x in dict_array:
		array.append(convert_coords(Vector2(x.x,x.y),resolution))
	return array

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
