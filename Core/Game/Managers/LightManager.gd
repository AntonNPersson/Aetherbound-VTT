class_name LightManager extends Node
@onready var light_texture: Texture = preload("res://Assets/Textures/Lights/light.png")

func create_lights(lightss, resolution) -> Array:
	var lights = []

	for light in lightss:
		var light2d = PointLight2D.new()
		light2d.position = Helper.convert_coords(Vector2(light.position.x, light.position.y), resolution)
		light2d.texture = light_texture
		light2d.shadow_enabled = false
		
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
		
		light2d.energy = light.intensity / 4
		
		var light_radius_in_pixels = light.range * 300
		
		var texture_size = light_texture.get_size().x
		var texture_radius = texture_size / 2
		
		light2d.texture_scale = light_radius_in_pixels / texture_radius
		
		lights.append(light2d)
	return lights

func create_light_resource() -> void:
	pass