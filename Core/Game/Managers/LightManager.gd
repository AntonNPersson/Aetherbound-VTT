class_name LightManager extends ColorRect
var light_texture = null
var map_manager = null

var cached_lights = []

func _ready():
	map_manager = get_parent().get_node("Managers/MapManager")

func _process(_delta: float) -> void:
	_update_shader_wall_data(self.material, get_parent().get_node("Managers/MapManager"))
	
func create_light_resource(lights, resolution) -> void:
	if light_texture == null:
		light_texture = _create_light_texture()
	size = map_manager.picture_size
	print("Creating light resources")

	var light_uv_coords = []
	var light_uv_radii = []
	var light_colors = []
	var light_brightness = []
	var light_intense = []
	var light_attenuation_strength = []

	cached_lights.clear()
	for child in get_children():
		child.queue_free()
	self.material.set_shader_parameter("hole_positions", light_uv_coords)
	self.material.set_shader_parameter("hole_radii", light_uv_radii)
	self.material.set_shader_parameter("hole_count", light_uv_coords.size())
	self.material.set_shader_parameter("hole_colors", light_colors)
	self.material.set_shader_parameter("light_texture", light_texture)
	self.material.set_shader_parameter("brightness", light_brightness)
	self.material.set_shader_parameter("intensity", light_intense)
	self.material.set_shader_parameter("attenuation_strength", light_attenuation_strength)

	for light in lights:
		var light2d = LightResource.new()
		light2d.light_position = Helper.convert_coords(Vector2(light.position.x, light.position.y), resolution)
		var color_hex = light.color

		light2d.light_color = Helper.hex_to_linear_color(color_hex)
		light2d.light_intensity = light.intensity
		light2d.light_radius = light.range * 300
		cached_lights.append(light2d)
		light2d.light_attenuation_strength = 0.7
		light2d.light_brightness = 1.4
		light2d.light_index = cached_lights.size() - 1
		light2d.light_shader = self.material
		light2d.light_manager = self

		light_uv_coords.append(light2d.light_position)
		light_uv_radii.append(light2d.light_radius)
		light_colors.append(light2d.light_color)
		light_intense.append(light2d.light_intensity)
		light_brightness.append(light2d.light_brightness)
		light_attenuation_strength.append(light2d.light_attenuation_strength)

		light2d.initialize_state()

	light_uv_coords = Helper.global_to_uv_position(light_uv_coords, self)
	light_uv_radii = Helper.global_to_uv_radius(light_uv_radii, self)

	_update_shader_wall_data(self.material, map_manager)

	self.material.set_shader_parameter("hole_positions", light_uv_coords)
	self.material.set_shader_parameter("hole_radii", light_uv_radii)
	self.material.set_shader_parameter("hole_count", light_uv_coords.size())
	self.material.set_shader_parameter("hole_colors", light_colors)
	self.material.set_shader_parameter("light_texture", light_texture)
	self.material.set_shader_parameter("brightness", light_brightness)
	self.material.set_shader_parameter("intensity", light_intense)
	self.material.set_shader_parameter("attenuation_strength", light_attenuation_strength)
	self.material.set_shader_parameter("debug_mode", false)
		
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
