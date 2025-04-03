class_name LightManager extends ColorRect
var light_texture = null
var map_manager = null

var cached_lights = {}
var new_lights = {}
var removed_lights = {}

# Shadow map system variables
var shadow_map_viewport: SubViewport
var shadow_map_renderer: ColorRect # ADD this line (or TextureRect)
var shadow_map_shader: ShaderMaterial
var blur_map_viewport: SubViewport
var shadow_map_dirty: bool = true

# Shadow map configuration
const SHADOW_MAP_WIDTH = 2880  # Angular resolution
const SHADOW_MAP_HEIGHT = 1000 # One row per light (max 100 lights)

func _ready():
	map_manager = get_parent().get_node("Managers/MapManager")
	Bus.update_shader_wall_data.connect(func(): 
		_update_shader_wall_data(self.material, map_manager)
		# Mark shadow map for update when walls change
		shadow_map_dirty = true
	)
	add_to_group("Savable")
	
	# Initialize shadow map system
	_setup_shadow_map()

# Set up the shadow map generation system
func _setup_shadow_map():
	# Create shadow map viewport
	shadow_map_viewport = SubViewport.new()
	shadow_map_viewport.size = Vector2(SHADOW_MAP_WIDTH, SHADOW_MAP_HEIGHT)
	# Correct enum access for your Godot version
	shadow_map_viewport.render_target_clear_mode = SubViewport.ClearMode.CLEAR_MODE_ONCE
	shadow_map_viewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ALWAYS
	# Set rendering options
	shadow_map_viewport.transparent_bg = false
	add_child(shadow_map_viewport)

	blur_map_viewport = SubViewport.new()
	blur_map_viewport.size = Vector2(SHADOW_MAP_WIDTH, SHADOW_MAP_HEIGHT)
	blur_map_viewport.render_target_clear_mode = SubViewport.ClearMode.CLEAR_MODE_ONCE
	blur_map_viewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_WHEN_VISIBLE
	blur_map_viewport.transparent_bg = false
	add_child(blur_map_viewport)
	
	# Create sprite with shadow map generator shader
	shadow_map_renderer = ColorRect.new()
	shadow_map_renderer.size = shadow_map_viewport.size
	shadow_map_shader = ShaderMaterial.new()
	shadow_map_shader.shader = load("res://Assets/Shaders/shadow_map.gdshader")
	shadow_map_renderer.material = shadow_map_shader # Apply shader HERE
	shadow_map_viewport.add_child(shadow_map_renderer)

	var blur_rect = TextureRect.new()
	blur_rect.texture = shadow_map_viewport.get_texture()
	blur_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	blur_rect.size = blur_map_viewport.size
	blur_map_viewport.add_child(blur_rect)

	var blur_shader = ShaderMaterial.new()
	blur_shader.shader = load("res://Assets/Shaders/post_processing.gdshader")
	blur_shader.set_shader_parameter("source_shadow_map", blur_rect.texture)
	blur_shader.set_shader_parameter("blur_amount", 10.5)
	blur_rect.material = blur_shader
	
	# Set the shadow map texture in the main shader
	self.material.set_shader_parameter("shadow_map", blur_map_viewport.get_texture())
	self.material.set_shader_parameter("use_shadow_map", true)

func _process(_delta):
	# Update shadow map when needed
	if shadow_map_dirty:
		update_shadow_map()
		shadow_map_dirty = false

func update_shadow_map():
	print("--- Updating Shadow Map ---") # Add a clear marker

	# Synchronize wall data between main shader and shadow map shader
	var wall_start_points = self.material.get_shader_parameter("wall_start_points")
	var wall_end_points = self.material.get_shader_parameter("wall_end_points")
	var wall_count = self.material.get_shader_parameter("wall_count")

	shadow_map_shader.set_shader_parameter("wall_start_points", wall_start_points)
	shadow_map_shader.set_shader_parameter("wall_end_points", wall_end_points)
	shadow_map_shader.set_shader_parameter("wall_count", wall_count)

	# Synchronize light data
	var light_positions = self.material.get_shader_parameter("hole_positions")
	var light_radii = self.material.get_shader_parameter("hole_radii")
	var light_count = self.material.get_shader_parameter("hole_count")

	if light_count > 0 and light_positions.size() > 0 and light_radii.size() > 0:
		if light_radii[0] <= 0.0:
			print("	*** WARNING: First light radius is zero or negative! ***")
	elif light_count > 0:
		print("	*** WARNING: Hole count > 0 but array sizes mismatch? ***")


	shadow_map_shader.set_shader_parameter("hole_positions", light_positions)
	shadow_map_shader.set_shader_parameter("hole_radii", light_radii)
	shadow_map_shader.set_shader_parameter("hole_count", light_count)

	# Force the viewport to update
	print("	Queueing Viewport Render...")
	shadow_map_viewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
	blur_map_viewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
	print("--- Shadow Map Update Complete ---")

func has_light(map_name: String) -> bool:
	return map_name.replace(" ", "_") in cached_lights

func get_lights(map_name: String) -> Array:
	return cached_lights.get(map_name.replace(" ", "_"), [])

func remove_light(light_index: int, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if map_name not in cached_lights:
		if map_name in new_lights:
			removed_lights[map_name].append(light_index)
		else:
			removed_lights[map_name] = [light_index]
		return
	
	if cached_lights[map_name][light_index].light_sprite != null:
		cached_lights[map_name][light_index].light_sprite.queue_free()
	cached_lights[map_name].remove_at(light_index)
	
	for i in range(light_index, cached_lights[map_name].size()):
		cached_lights[map_name][i].light_index = i
	
	if Net.is_host():
		for key in cached_lights:
			for l in cached_lights[key]:
				l.light_sprite.visible = (key == map_manager.get_map_name_from_index(map_manager.current_local_map))
	
	var map_index = map_manager.current_map if !Net.is_host() else map_manager.current_local_map
	
	if map_name == map_manager.get_map_name_from_index(map_index).replace(" ", "_"):
		update_shader_for_map(map_name)
		_update_shader_wall_data(self.material, get_parent().get_node("Managers/MapManager"))
		shadow_map_dirty = true  # Mark for shadow map update

func add_light(light_pos: Vector2, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if map_name not in cached_lights:
		if map_name in new_lights:
			new_lights[map_name].append(light_pos)
		else:
			new_lights[map_name] = [light_pos]
	else:
		var light = LightResource.new()
		light.light_position = light_pos
		light.light_color = Color(1, 1, 1, 1)
		light.light_intensity = 0.5
		light.light_radius = 0
		light.light_attenuation_strength = 0.5
		light.light_brightness = 0.4
		cached_lights[map_name].append(light)
		light.light_index = cached_lights[map_name].size() - 1
		light.light_manager = self
		light.light_shader = self.material
		light.initialize_state()
		if Net.is_host():
			light.light_sprite.visible = (map_name == map_manager.get_map_name_from_index(map_manager.current_local_map))
		
		var map_index = map_manager.current_map if !Net.is_host() else map_manager.current_local_map
		# If this is the current map, update shader parameters
		if map_name == map_manager.get_map_name_from_index(map_index):
			update_shader_for_map(map_name)
			_update_shader_wall_data(self.material, get_parent().get_node("Managers/MapManager"))
			shadow_map_dirty = true  # Mark shadow map for update

func create_light_resource(lights, resolution, map_name, update_shader = true) -> void:
	map_name = map_name.replace(" ", "_")
	size = map_manager.picture_size
	if map_name not in cached_lights:
		cached_lights[map_name] = []

		if light_texture == null:
			light_texture = _create_light_texture()

		for light in lights:
			var light2d = LightResource.new()
			light2d.light_position = Helper.convert_coords(Vector2(light.position.x, light.position.y), resolution)
			light2d.light_color = Helper.hex_to_linear_color(light.color)
			light2d.light_intensity = light.intensity / 2
			light2d.light_radius = light.range * map_manager.tile_size.x
			light2d.light_attenuation_strength = 1.0
			light2d.light_brightness = 0.4 
			
			cached_lights[map_name].append(light2d)
			light2d.light_index = cached_lights[map_name].size() - 1
			light2d.light_shader = self.material
			light2d.light_manager = self
			light2d.initialize_state()

		if map_name in new_lights:
			for light_pos in new_lights[map_name]:
				add_light(light_pos, map_name)
			new_lights.erase(map_name)

		if map_name in removed_lights:
			for light_index in removed_lights[map_name]:
				remove_light(light_index, map_name)
			removed_lights.erase(map_name)

		if update_shader:
			_update_shader_wall_data(self.material, map_manager)
			update_shader_for_map(map_name)
			shadow_map_dirty = true  # Mark shadow map for update

		
		if Net.is_host():
			for key in cached_lights:
				for light in cached_lights[key]:
					light.light_sprite.visible = (key == map_name)
	else:
		
		if Net.is_host():
			for key in cached_lights:
				for light in cached_lights[key]:
					light.light_sprite.visible = (key == map_name)
		
		if update_shader:
			_update_shader_wall_data(self.material, map_manager)
			update_shader_for_map(map_name)
			shadow_map_dirty = true  # Mark shadow map for update

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
	
	# Mark shadow map for update when walls change
	shadow_map_dirty = true

func convert_light_resource_to_ddd2vtt(light_resource: LightResource, resolution: Dictionary) -> Dictionary:
	var ddd2vtt_light = {}
	
	var original_position = Helper.inverse_convert_coords(light_resource.light_position, resolution)
	ddd2vtt_light["position"] = {
		"x": original_position.x,
		"y": original_position.y
	}
	
	ddd2vtt_light["color"] = Helper.linear_color_to_hex(light_resource.light_color)
	if light_resource.light_is_visible:
		ddd2vtt_light["range"] = light_resource.light_radius / map_manager.tile_size.x
	else:
		ddd2vtt_light["range"] = light_resource.cached_values["radius"] / map_manager.tile_size.x
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
	
	# Mark shadow map for update
	shadow_map_dirty = true

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
