class_name PortalManager extends Node

# Create the portals, i really need to find a way to make this more efficient because right now my potato computer is struggling and disconnects the client
# Args: Array - The array of portals
# Returns: None
func create_portals(portalss: Array, resolution, map_name: String) -> void:
	var batch_size = SettingConst.PORTAL_BATCH_SIZE  # Do I really need to implement batching because my computer is shit?
	var portals_processed = 0
   
	for portal_index in range(portalss.size()):
		var p = portalss[portal_index]
		var points = Helper.dict2vector2array(p.bounds, resolution)
		var line = Line2D.new()
	   
		var portal_resource = portal.new()
		portal_resource.is_open = !p.closed

		if p.has("hidden"):
			portal_resource.is_hidden = p.hidden
		
		if p.has("locked"):
			portal_resource.is_locked = p.locked
		
		portal_resource.map_name = map_name
		portal_resource.portal_index = portal_index
		portal_resource.map = get_parent()
		
		var portal_holder = Node2D.new()
		portal_holder.name = "PortalHolder"
		portal_holder.set_meta("portal_resource", portal_resource)
	   
		var is_horizontal = false
	   
		if points.size() >= 2:
			var start_global = line.to_global(points[0])
			var end_global = line.to_global(points[-1])
			var dx = abs(end_global.x - start_global.x)
			var dy = abs(end_global.y - start_global.y)
			is_horizontal = dx > dy
	   
		var middle_local = Vector2.ZERO
		for point in points:
			middle_local += point
		middle_local /= points.size()
	   
		var middle_global = line.to_global(middle_local)
		var primary_tile = get_parent().convert_to_tilemap_pos(middle_global)

		portal_resource.map_position = middle_global
	   
		var valid_tile_positions = [primary_tile]
	   
		if points.size() >= 2:
			if is_horizontal:
				var test_above = Vector2(middle_global.x, middle_global.y - 150)
				var test_below = Vector2(middle_global.x, middle_global.y + 150)
				var tile_above = get_parent().convert_to_tilemap_pos(test_above)
				var tile_below = get_parent().convert_to_tilemap_pos(test_below)
			   
				if tile_above != primary_tile:
					valid_tile_positions.append(tile_above)
			   
				if tile_below != primary_tile:
					valid_tile_positions.append(tile_below)
			   
			else:
				var test_left = Vector2(middle_global.x - 150, middle_global.y)
				var test_right = Vector2(middle_global.x + 150, middle_global.y)
				var tile_left = get_parent().convert_to_tilemap_pos(test_left)
				var tile_right = get_parent().convert_to_tilemap_pos(test_right)
			   
				if tile_left != primary_tile:
					valid_tile_positions.append(tile_left)
			   
				if tile_right != primary_tile:
					valid_tile_positions.append(tile_right)
		
		portal_holder.set_meta("tile_positions", valid_tile_positions)
		portal_resource.parent = line
	   
		line.add_child(portal_holder)
		line.points = points
		line.add_to_group("portals")
		get_parent().portals.add_child(line)
	   
		portals_processed += 1
		if portals_processed >= batch_size:
			portals_processed = 0
			await get_tree().process_frame
