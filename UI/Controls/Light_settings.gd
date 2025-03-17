extends Node

func connect_signals(light: Resource) -> void:
	var child = get_child(0)

	child.get_node("Radius").value = light.light_radius
	child.get_node("Color").color = light.light_color
	child.get_node("Intensity").value = light.light_intensity
	child.get_node("Brightness").value = light.light_brightness

	child.get_node("Radius").value_changed.connect(light.change_light_radius)
	child.get_node("Color").color_changed.connect(light.change_light_color)
	child.get_node("Intensity").value_changed.connect(light.change_light_intensity)
	child.get_node("Brightness").value_changed.connect(light.change_light_brightness)
	child.get_node("Apply").pressed.connect(light.apply_light_changes)
