class_name CollisionManager extends Node2D
var cached_walls = {}
var map_manager = null

func _ready() -> void:
	add_to_group("Savable")
	map_manager = get_parent()

func add_wall(points: Array, map_name: String, type: String) -> void:
	if not map_name in cached_walls:
		cached_walls[map_name] = []
	
	var line = Line2D.new()
	line.add_to_group(type)
	line.points = points
	cached_walls[map_name].append(line)

	if !Net.is_host():
		line.default_color = Color(0, 0, 0, 0)

	var line_instance = Line2D.new()
	line_instance.points = points
	if !Net.is_host():
		line_instance.default_color = Color(0, 0, 0, 0)
	line.set_meta("type", type)
	line_instance.set_meta("type", type)

	var map_index = map_manager.current_local_map if Net.is_host() else map_manager.current_map
	if map_name == map_manager.get_map_name_from_index(map_index):
		create_line_collision(line_instance, map_manager.get_node("Line Walls"))
		print("Creating line collision")

func remove_wall(points: Array, map_name: String) -> void:
	# Convert input array to PackedVector2Array for consistent comparison
	var packed_points = PackedVector2Array(points)
	
	# Remove from cache
	for i in range(cached_walls[map_name].size()):
		var line = cached_walls[map_name][i]
		if line.points == packed_points:
			line.queue_free()
			cached_walls[map_name].remove_at(i)
			
			# Also remove from current scene if we're on this map
			if map_name == map_manager.get_map_name_from_index(map_manager.current_local_map):
				var walls_node = map_manager.get_node("Line Walls")
				remove_wall_from_scene(packed_points, walls_node)
			
			break

func create_wall_collision(walls_node: Node) -> void:
	var batch_size = SettingConst.COLLISION_BATCH_SIZE
	var shapes_processed = 0

	var map_index = map_manager.current_local_map if Net.is_host() else map_manager.current_map
	if map_manager.get_map_name_from_index(map_index) in cached_walls:
		for line in cached_walls[map_manager.get_map_name_from_index(map_index)]:
			var line_instance = Line2D.new()
			line_instance.points = line.points.duplicate()
			line_instance.width = line.width
			line_instance.default_color = line.default_color
			line_instance.add_to_group(line.get_groups()[0])  # Assuming only one group
			
			# Add to walls node
			walls_node.add_child(line_instance)
   
	var static_bodies = []
	for line in walls_node.get_children():
		if line is Line2D and line.points.size() >= 2:
			var static_body = StaticBody2D.new()
			static_body.name = "StaticBody2D"
			static_body.collision_layer = 2
			static_body.collision_mask = 1
			line.add_child(static_body)
			if !Net.is_host():
				line.default_color = Color(0, 0, 0, 0)
			line.add_to_group("Walls")
			static_body.input_pickable = true
			static_bodies.append({"body": static_body, "points": line.points.duplicate()})
			
	for body_data in static_bodies:
		var static_body = body_data.body
		var points = body_data.points
		var points_size = points.size()
	   
		for j in range(points_size - 1):
			var collision_shape = CollisionShape2D.new()
			var rect = RectangleShape2D.new()
		   
			var start = points[j]
			var end = points[j + 1]
			
			collision_shape.shape = rect
			
			rect.extents = Vector2(start.distance_to(end) / 2, 5)
			
			static_body.add_child(collision_shape)
			
			collision_shape.global_position = (start + end) / 2
			collision_shape.rotation = start.direction_to(end).angle()
		   
			shapes_processed += 1
			
			if shapes_processed >= batch_size:
				shapes_processed = 0
				await get_tree().process_frame

func create_line_collision(line: Line2D, walls_node: Node) -> void:
	# Add the line to the walls node
	walls_node.add_child(line)
	
	# Create collision for just this line
	var batch_size = SettingConst.COLLISION_BATCH_SIZE
	var shapes_processed = 0
	
	
	# Create static body for this line
	if line.points.size() >= 2:
		var static_body = StaticBody2D.new()
		static_body.name = "StaticBody2D"
		static_body.collision_layer = 2
		static_body.collision_mask = 1
		line.add_child(static_body)
		line.add_to_group("Walls")
		
		if !Net.is_host():
			line.default_color = Color(0, 0, 0, 0)
		
		# Create collision shapes for each segment
		var points = line.points
		var points_size = points.size()
		static_body.input_pickable = true
		for j in range(points_size - 1):
			var collision_shape = CollisionShape2D.new()
			var rect = RectangleShape2D.new()
			
			var start = points[j]
			var end = points[j + 1]
			
			collision_shape.shape = rect
			rect.extents = Vector2(start.distance_to(end) / 2, 5)
			
			static_body.add_child(collision_shape)
			
			collision_shape.global_position = (start + end) / 2
			collision_shape.rotation = start.direction_to(end).angle()
			
			shapes_processed += 1
			
			if shapes_processed >= batch_size:
				shapes_processed = 0
				await get_tree().process_frame

func remove_wall_from_scene(points: PackedVector2Array, walls_node: Node) -> void:
	# Look through all children of the walls node
	for child in walls_node.get_children():
		if child is Line2D:
			# Direct comparison with PackedVector2Array
			if child.points == points:
				walls_node.remove_child(child)
				child.queue_free()
				return

func _save():
	for map_name in cached_walls.keys():
		var clean_map_name = map_name.replace("_", " ")
		
		# Skip if map doesn't exist in tilemap_data
		if clean_map_name not in map_manager.tilemap_data:
			continue
			
		# Get existing line_of_sight data or create empty array
		if "line_of_sight" not in map_manager.tilemap_data[clean_map_name]:
			map_manager.tilemap_data[clean_map_name]["line_of_sight"] = []
		
		var existing_line_of_sight = map_manager.tilemap_data[clean_map_name]["line_of_sight"]
		var resolution = map_manager.tilemap_data[clean_map_name]["resolution"]
		
		# Convert walls to proper format and append to existing data
		for line in cached_walls[map_name]:
			if line is Line2D and line.points.size() >= 2:
				# For each segment in the line
				for i in range(line.points.size() - 1):
					var start_point = line.points[i]
					var end_point = line.points[i + 1]
					
					# Convert positions to the correct format
					var converted_start = Helper.inverse_convert_coords(start_point, resolution)
					var converted_end = Helper.inverse_convert_coords(end_point, resolution)
					
					# Create segment in required format
					var segment = [
						{"x": converted_start.x, "y": converted_start.y},
						{"x": converted_end.x, "y": converted_end.y}
					]

					if line.has_meta("type"):
						segment.append({"type": line.get_meta("type")})
					
					# Append to the existing line_of_sight array
					existing_line_of_sight.append(segment)
		map_manager.tilemap_data[clean_map_name]["line_of_sight"] = existing_line_of_sight
