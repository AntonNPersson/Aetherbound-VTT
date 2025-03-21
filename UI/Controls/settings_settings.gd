extends Node

func connect_signals(trigger: Resource) -> void:
	var child = get_child(0)

	child.get_node("Illumination").button_pressed = trigger.global_illumination
	child.get_node("Color").color = trigger.global_illumination_color
	child.get_node("Fog Color").color = trigger.global_fog_color
	child.get_node("Vision Color").color = trigger.global_vision_color

	child.get_node("Illumination").toggled.connect(trigger.change_global_illumination)
	child.get_node("Color").color_changed.connect(trigger.change_global_illumination_color)
	child.get_node("Fog Color").color_changed.connect(trigger.change_global_fog_color)
	child.get_node("Vision Color").color_changed.connect(trigger.change_global_vision_color)
