extends Node2D
# ===================== MAP MANAGER =====================
# Manages the map, and the players in the game
# ======================================================

#Variables
@export var picture_size: Vector2 = Vector2(6300, 4200)
@export var tile_size: Vector2 = Vector2(300, 300)
@export var tilemap: TileMap = null
@export var nav: NavigationRegion2D = null

var map_width: int = 100
var map_height: int = 100

var astar = AStar2D.new()
var path_array: Array = []

# ===================== CORE FUNCTIONS =====================

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_map("user://Assets/Maps/Test Map.jpg")
	create_astar_from_array(path_array)

# Create the map
# Args: String - The path to the texture that will be used for the map
# Returns: None
func create_map(texture_path: String) -> void:
	var atlas_resource = create_tileset_resource(texture_path)
	add_resource_to_tileset(atlas_resource)
	place_tiles()

# ===================== MOVEMENT FUNCTIONS =================
# Move the player to a tile, currently checks for out of bounds but need to implement collision (should be gathered from the tilemap custom data on the tile)
# Args: Node2D - The player that will be moved
#       Vector2 - The global position of the tile
# Returns: None
func move_to_tile(player: Node2D, global_pos: Vector2) -> void:
	var map_pos = convert_to_tilemap_pos(global_pos)

	if map_pos.x < 0 or map_pos.x >= map_width or map_pos.y < 0 or map_pos.y >= map_height:
		return

	player.global_position = convert_to_global_pos(map_pos)

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

# ===================== HELPER FUNCTIONS =====================

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

func convert_to_global_pos(map_pos: Vector2) -> Vector2:
	var local_pos = tilemap.map_to_local(map_pos)
	return to_global(local_pos)

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

func create_tileset_resource(path: String) -> TileSetAtlasSource:
	var atlas_resource = TileSetAtlasSource.new()

	atlas_resource.texture = ExternalUtility.get_external_texture(path)
	atlas_resource.texture_region_size = tile_size
	set_picture_size(atlas_resource.texture.get_size())
	set_map_size()

	for x in range(map_width):
		for y in range(map_height):
			atlas_resource.create_tile(Vector2i(x,y), Vector2i(1, 1))
	return atlas_resource

func add_resource_to_tileset(atlas_resource: TileSetAtlasSource) -> void:
	tilemap.tile_set.add_source(atlas_resource)