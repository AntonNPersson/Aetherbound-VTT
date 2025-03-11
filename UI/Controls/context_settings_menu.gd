extends Control
var current_selected: Button = null

# ===================== CORE FUNCTIONS =====================

func untoggle_children() -> void:
	for child in get_child(0).get_children():
		if child is Button:
			if child == current_selected:
				continue
			child.button_pressed = false

func _on_button_toggled(state: bool, button_name: String) -> void:
	if state:
		current_selected = get_child(0).get_node(button_name)
		untoggle_children()
	else:
		current_selected = null
		untoggle_children()