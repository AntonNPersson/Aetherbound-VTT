class_name LightManager extends ColorRect
var light_texture = null
var map_manager = null

var cached_lights = {}

func _ready():
	map_manager = get_parent().get_node("Managers/MapManager")
	add_to_group("Savable")

func _process(_delta: float) -> void:
	_update_shader_wall_data(self.material, get_parent().get_node("Managers/MapManager"))

func has_light(map_name: String) -> bool:
	return map_name.replace(" ", "_") in cached_lights

func get_lights(map_name: String) -> Array:
	return cached_lights.get(map_name.replace(" ", "_"), [])

func remove_light(light: LightResource, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if map_name not in cached_lights:
		return
	
	cached_lights[map_name][light.light_index].light_sprite.queue_free()
	cached_lights[map_name].remove_at(light.light_index)
	
	for i in range(light.light_index, cached_lights[map_name].size()):
		cached_lights[map_name][i].light_index = i
	
	if Net.is_host():
		for key in cached_lights:
			for l in cached_lights[key]:
				l.light_sprite.visible = (key == map_manager.get_map_name_from_index(map_manager.current_local_map))
	
	if map_name == map_manager.get_map_name_from_index(map_manager.current_local_map).replace(" ", "_"):
		update_shader_for_map(map_name)

func add_light(light_pos: Vector2, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if map_name not in cached_lights:
		cached_lights[map_name] = []
	
	var light = LightResource.new()
	light.light_position = light_pos
	light.light_color = Color(1, 1, 1, 1)
	light.light_intensity = 1
	light.light_radius = 0
	light.light_attenuation_strength = 0.7
	light.light_brightness = 1.4
	cached_lights[map_name].append(light)
	light.light_index = cached_lights[map_name].size() - 1
	light.light_manager = self
	light.light_shader = self.material
	light.initialize_state()
	light.light_sprite.visible = (map_name == map_manager.get_map_name_from_index(map_manager.current_local_map))
	
	# If this is the current map, update shader parameters
	if map_name == map_manager.get_map_name_from_index(map_manager.current_local_map):
		update_shader_for_map(map_name)

func create_light_resource(lights, resolution, map_name) -> void:
	map_name = map_name.replace(" ", "_")

	if map_name not in cached_lights:
		cached_lights[map_name] = []

		if light_texture == null:
			light_texture = _create_light_texture()
		size = map_manager.picture_size

		for light in lights:
			var light2d = LightResource.new()
			light2d.light_position = Helper.convert_coords(Vector2(light.position.x, light.position.y), resolution)
			light2d.light_color = Helper.hex_to_linear_color(light.color)
			light2d.light_intensity = light.intensity
			light2d.light_radius = light.range * 300
			light2d.light_attenuation_strength = 0.7
			light2d.light_brightness = 1.4
			
			cached_lights[map_name].append(light2d)
			light2d.light_index = cached_lights[map_name].size() - 1
			light2d.light_shader = self.material
			light2d.light_manager = self
			light2d.initialize_state()

		_update_shader_wall_data(self.material, map_manager)
		update_shader_for_map(map_name)

		
		if Net.is_host():
			for key in cached_lights:
				for light in cached_lights[key]:
					light.light_sprite.visible = (key == map_name)
	else:
		
		if Net.is_host():
			for key in cached_lights:
				for light in cached_lights[key]:
					light.light_sprite.visible = (key == map_name)
		
		_update_shader_wall_data(self.material, map_manager)
		update_shader_for_map(map_name)

func _create_light_texture() -> GradientTexture2D:
	var texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 1))
	gradient.add_point(0.8, Color(0.5, 0.5, 0.5, 0.5))
	gradient.add_point(1.0, Color(0, 0, 0, 0))
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.width = 256
	texture.height = 256
	return texture

func _update_shader_wall_data(_material, map) -> void:
	var wall_start_points = []
	var wall_end_points = []
	var wall_count = 0
	var max_walls = 500
	
	for line in map.line_walls.get_children():
		if line is Line2D:
			if line.has_meta("type"):
				if line.get_meta("type") == "Invisible Wall":
					continue

			var points = line.points
			var point_count = points.size() - 1
			
			if wall_count + point_count > max_walls:
				point_count = max_walls - wall_count
			
			for i in range(point_count):
				wall_start_points.append(points[i])
				wall_end_points.append(points[i + 1])
			
			wall_count += point_count
			
			if wall_count >= max_walls:
				break
	
	if wall_count < max_walls:
		for p in map.portals.get_children():
			if p.has_node("PortalHolder"):
				if p is Line2D and !p.get_node("PortalHolder").get_meta("portal_resource").is_open:
					var points = p.points
					var point_count = min(points.size() - 1, max_walls - wall_count)
					
					for i in range(point_count):
						wall_start_points.append(points[i])
						wall_end_points.append(points[i + 1])
					
					wall_count += point_count
					
					if wall_count >= max_walls:
						break
	
	wall_start_points = Helper.global_to_uv_position(wall_start_points, self)
	wall_end_points = Helper.global_to_uv_position(wall_end_points, self)
	
	_material.set_shader_parameter("wall_start_points", wall_start_points)
	_material.set_shader_parameter("wall_end_points", wall_end_points)
	_material.set_shader_parameter("wall_count", wall_count)

func convert_light_resource_to_ddd2vtt(light_resource: LightResource, resolution: Dictionary) -> Dictionary:
	var ddd2vtt_light = {}
	
	var original_position = Helper.inverse_convert_coords(light_resource.light_position, resolution)
	ddd2vtt_light["position"] = {
		"x": original_position.x,
		"y": original_position.y
	}
	
	ddd2vtt_light["color"] = Helper.linear_color_to_hex(light_resource.light_color)
	if light_resource.light_is_visible:
		ddd2vtt_light["range"] = light_resource.light_radius / 300.0
	else:
		ddd2vtt_light["range"] = light_resource.cached_values["radius"] / 300.0
	ddd2vtt_light["intensity"] = light_resource.light_intensity
	return ddd2vtt_light

func convert_all_light_resources_to_ddd2vtt(light_resources: Array, resolution: Dictionary) -> Array:
	var ddd2vtt_lights = []
	
	for light_resource in light_resources:
		var ddd2vtt_light = convert_light_resource_to_ddd2vtt(light_resource, resolution)
		ddd2vtt_lights.append(ddd2vtt_light)
	
	return ddd2vtt_lights

func update_shader_for_map(map_name: String) -> void:
	if map_name not in cached_lights:
		return
		
	var light_uv_coords = []
	var light_uv_radii = []
	var light_colors = []
	var light_brightness = []
	var light_intense = []
	var light_attenuation_strength = []
	
	for light in cached_lights[map_name]:
		light_uv_coords.append(light.light_position)
		light_uv_radii.append(light.light_radius)
		light_colors.append(light.light_color)
		light_intense.append(light.light_intensity)
		light_brightness.append(light.light_brightness)
		light_attenuation_strength.append(light.light_attenuation_strength)
	
	light_uv_coords = Helper.global_to_uv_position(light_uv_coords, self)
	light_uv_radii = Helper.global_to_uv_radius(light_uv_radii, self)
	
	self.material.set_shader_parameter("hole_positions", light_uv_coords)
	self.material.set_shader_parameter("hole_radii", light_uv_radii)
	self.material.set_shader_parameter("hole_count", light_uv_coords.size())
	self.material.set_shader_parameter("hole_colors", light_colors)
	self.material.set_shader_parameter("brightness", light_brightness)
	self.material.set_shader_parameter("intensity", light_intense)
	self.material.set_shader_parameter("attenuation_strength", light_attenuation_strength)


func _save():
	for map_name in cached_lights.keys():
		var clean_map_name = map_name.replace("_", " ")
		var map_lights = []  # Create a new array for each map
		
		for light in cached_lights[map_name]:
			map_lights.append(convert_light_resource_to_ddd2vtt(
				light, 
				map_manager.tilemap_data[clean_map_name]["resolution"]
			))
		
		# Save only this map's lights to this map's data
		map_manager.tilemap_data[clean_map_name]["lights"] = map_lights
