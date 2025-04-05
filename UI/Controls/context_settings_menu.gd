class_name settings_context_panel extends Control

var settings_manager: Node = null
var current_selected: Button = null
var player_id: int = 1

# ===================== CORE FUNCTIONS =====================
func initialize(sm: Node, pos: Vector2, id: int = 1) -> void:
	settings_manager = sm
	global_position = pos
	player_id = id

	if !Net.is_host():
		for child in get_tree().get_nodes_in_group("Non_host"):
			child.hide()

func _untoggle_children() -> void:
	for child in get_child(0).get_node("Button Container").get_children():
		if child != current_selected:
			child.button_pressed = false
			_hide_children(child)
			print("Untoggling button: ", child.name)

func _show_children(button: Button) -> void:
	button.get_child(0).show()

func _hide_children(button: Button) -> void:
	button.get_child(0).hide()

func _on_button_toggled(state: bool, button_name: String) -> void:
	var button = get_child(0).get_node("Button Container").get_node(button_name)
	current_selected = button
	_untoggle_children()
	
	# If turning on a button
	if state:
		# Set as current selection
		# Ensure all other buttons are off
		_show_children(button)
	
	# If turning off the current selection
	elif !state and button == current_selected:
		# Only allow deselection if explicitly clicking the current button
		# Prevent automatic deselection when selecting another button
		button.button_pressed = true

func _set_global_illumination(is_toggled: bool) -> void:
	settings_manager.set_global_illumination.rpc_id(player_id, is_toggled)

func _set_global_illumination_color(color: Color) -> void:
	settings_manager.set_global_illumination_color.rpc_id(player_id, color)

func _set_global_fog_color(color: Color) -> void:
	settings_manager.set_global_fog_color.rpc_id(player_id, color)

func _set_global_vision_ray_count(count: int) -> void:
	settings_manager.set_global_vision_rays_count.rpc_id(player_id, count)

func _set_global_vision_color(color: Color) -> void:
	settings_manager.set_player_vision_color(player_id, color)
