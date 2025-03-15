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
	for child in get_child(0).get_children():
		if child is Button and child != current_selected:
			child.button_pressed = false

func _show_children(button_name: String) -> void:
	for child in get_child(0).get_children():
		if child is Button and child.get_name() == button_name and child.is_in_group("Button_group"):
			for grandchild in child.get_children():
				grandchild.show()
		elif child is Button and child.get_name() != button_name and child.is_in_group("Button_group"):
			for grandchild in child.get_children():
				grandchild.hide()

func _on_button_toggled(state: bool, button_name: String) -> void:
	var button = get_child(0).get_node(button_name)
	
	# If turning on a button
	if state:
		# Set as current selection
		current_selected = button
		# Ensure all other buttons are off
		_show_children(button_name)
		_untoggle_children()
	
	# If turning off the current selection
	elif button == current_selected:
		# Only allow deselection if explicitly clicking the current button
		# Prevent automatic deselection when selecting another button
		current_selected = null

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
