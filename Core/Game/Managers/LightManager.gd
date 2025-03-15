class_name LightManager extends Node
@onready var light_texture: Texture = preload("res://Assets/Textures/Lights/light.png")

func create_lights(lightss, resolution) -> Array:
	var lights = []

	for light in lightss:
		var light2d = PointLight2D.new()
		light2d.position = Helper.convert_coords(Vector2(light.position.x, light.position.y), resolution)
		light2d.texture = light_texture
		light2d.shadow_enabled = true
		light2d.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		light2d.shadow_filter_smooth = 2.0
		light2d.shadow_color = Color(0, 0, 0, 0.3)
		light2d.shadow_item_cull_mask = 3
		light2d.range_item_cull_mask = 1

		
		var color_hex = light.color
		if typeof(color_hex) == TYPE_STRING:
			if color_hex.length() == 8:
				var alpha_hex = color_hex.substr(0, 2)
				var red_hex = color_hex.substr(2, 2)
				var green_hex = color_hex.substr(4, 2)
				var blue_hex = color_hex.substr(6, 2)
				
				var alpha = ("0x" + alpha_hex).hex_to_int() / 255.0
				var red = ("0x" + red_hex).hex_to_int() / 255.0
				var green = ("0x" + green_hex).hex_to_int() / 255.0
				var blue = ("0x" + blue_hex).hex_to_int() / 255.0
				
				light2d.color = Color(red, green, blue, alpha)
			else:
				light2d.color = Color(color_hex)
		else:
			light2d.color = color_hex
		
		light2d.energy = light.intensity / 10
		
		var light_radius_in_pixels = light.range * 300
		
		var texture_size = light_texture.get_size().x
		var texture_radius = texture_size / 2
		
		light2d.texture_scale = light_radius_in_pixels / texture_radius

		var light_res = LightResource.new()
		light_res.light_position = light2d.position
		light_res.light_color = light2d.color
		light_res.light_intensity = light2d.energy
		light_res.light_radius = light_radius_in_pixels
		light_res.light_instance = light2d
		light2d.set_meta("LightHolder", light_res)
		light2d.add_to_group("lights")

		lights.append(light2d)
	return lights

func add_wall_occluders(line: Line2D) -> void:
	var points = line.points
	
	# Process each segment of the line
	for i in range(points.size() - 1):
		var start = points[i]
		var end = points[i + 1]
		
		# Create the occluder node
		var occluder = LightOccluder2D.new()
		var occluder_poly = OccluderPolygon2D.new()
		occluder.name = "Occluder"
		
		# Calculate segment properties
		var length = start.distance_to(end) / 2
		var width = 5.0  # Same width as your collision shapes
		var direction = (end - start).normalized()
		var angle = direction.angle()
		
		# Create polygon for occluder
		occluder_poly.polygon = PackedVector2Array([
			Vector2(-length, -width),  # Top-left
			Vector2(length, -width),   # Top-right
			Vector2(length, width),    # Bottom-right
			Vector2(-length, width)    # Bottom-left
		])
		
		# Apply occluder settings
		occluder.occluder = occluder_poly
		occluder.light_mask = 2  # Layer 2 for occluders
		
		# Position the occluder correctly
		line.add_child(occluder)
		occluder.position = (start + end) / 2
		occluder.rotation = angle
	
	# After adding all occluders, ensure the line itself doesn't receive light
	line.light_mask = 0  # Don't receive light

func create_light_resource() -> void:
	pass
