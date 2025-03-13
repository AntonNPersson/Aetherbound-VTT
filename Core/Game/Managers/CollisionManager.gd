class_name CollisionManager extends Node2D

func create_wall_collision(walls_node: Node) -> void:
	var batch_size = SettingConst.COLLISION_BATCH_SIZE
	var shapes_processed = 0
   
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
