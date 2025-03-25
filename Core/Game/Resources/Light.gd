class_name LightResource extends Resource
# ===================== LIGHT =====================
var light_position = Vector2(0, 0)
var light_radius = 100
var light_color = Color(1, 1, 1, 1)
var light_intensity = 10
var light_texture = preload("res://Assets/Textures/icons/light-icon.png")
var light_attenuation_strength = 0.7
var light_brightness = 1.4
var light_index = 0
var light_shader = null
var light_manager = null
var light_is_visible = true
var light_description = "A light source, illuminating the area."
var light_sprite = null

var cached_values = {"position": light_position,
					 "radius": light_radius,
					 "color": light_color,
					"intensity": light_intensity,
					"attenuation_strength": light_attenuation_strength,
					"brightness": light_brightness}

# ===================== CORE FUNCTIONS =====================

func initialize_state() -> void:
	if !Net.is_host():
		return

	var sprite = Sprite2D.new()
	sprite.texture = light_texture
	sprite.z_index = 2
	sprite.global_position = light_manager.map_manager.convert_to_tilemap_global_pos(light_position)
	sprite.scale = Vector2(0.2, 0.2)
	sprite.add_to_group("Light_sprites")
	light_manager.add_child(sprite)
	light_sprite = sprite

func change_light_position(new_position: Vector2, update_shader: bool = true) -> void:
	var uv_pos = Helper.global_to_uv_position([new_position], light_manager)
	light_position = new_position
	if !update_shader:
		return

	_change_shader_parameter("hole_positions", uv_pos[0])

func change_light_radius(new_radius: float, update_shader: bool = true) -> void:
	var uv_radius = Helper.global_to_uv_radius([new_radius], light_manager)
	light_radius = new_radius
	if !update_shader:
		return

	_change_shader_parameter("hole_radii", uv_radius[0])

func change_light_color(new_color: Color, update_shader: bool = true) -> void:
	light_color = new_color
	if !update_shader:
		return

	_change_shader_parameter("hole_colors", new_color)

func change_light_intensity(new_intensity: float, update_shader: bool = true) -> void:
	light_intensity = new_intensity
	if !update_shader:
		return

	_change_shader_parameter("intensity", new_intensity)

func change_light_attenuation_strength(new_attenuation_strength: float, update_shader: bool = true) -> void:
	light_attenuation_strength = new_attenuation_strength
	if !update_shader:
		return

	_change_shader_parameter("attenuation_strength", new_attenuation_strength)

func change_light_brightness(new_brightness: float, update_shader: bool = true) -> void:
	light_brightness = new_brightness
	if !update_shader:
		return

	_change_shader_parameter("brightness", new_brightness)

func change_light_visibility(new_visibility: bool, update_shader: bool = true) -> void:
	light_is_visible = new_visibility
	if new_visibility:
		light_radius = cached_values["radius"]
		var uv_radius = Helper.global_to_uv_radius([light_radius], light_manager)
		if !update_shader:
			return

		_change_shader_parameter("hole_radii", uv_radius[0])
	else:
		cached_values = {"position": light_position,
						 "radius": light_radius,
						 "color": light_color,
						"intensity": light_intensity,
						"attenuation_strength": light_attenuation_strength,
						"brightness": light_brightness}
		if !update_shader:
			return

		_change_shader_parameter("hole_radii", 0)
		light_radius = 0
	if Net.is_host():
		apply_light_changes()

func apply_light_changes() -> void:
	var data_dict = {"position": light_position,
					 "radius": light_radius,
					 "color": light_color,
					"intensity": light_intensity,
					"attenuation_strength": light_attenuation_strength,
					"brightness": light_brightness}
	light_manager.map_manager.update_light_data_for_peers.rpc(light_index, data_dict)

func _change_shader_parameter(name: String, value: Variant) -> void:
	var new_variable = light_shader.get_shader_parameter(name) as Array
	new_variable[light_index] = value
	light_shader.set_shader_parameter(name, new_variable)

func inspect() -> String:
	return light_description

func update_state(updated_values: Dictionary, update_shader: bool = true) -> void:
	if Net.is_host():
		return

	if updated_values.has("position"):
		change_light_position(updated_values["position"], update_shader)
	if updated_values.has("radius"):
		change_light_radius(updated_values["radius"], update_shader)
	if updated_values.has("color"):
		change_light_color(updated_values["color"], update_shader)
	if updated_values.has("intensity"):
		change_light_intensity(updated_values["intensity"], update_shader)
	if updated_values.has("attenuation_strength"):
		change_light_attenuation_strength(updated_values["attenuation_strength"], update_shader)
	if updated_values.has("brightness"):
		change_light_brightness(updated_values["brightness"], update_shader)
