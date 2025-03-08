class_name context_panel extends Control

var total_height: int = 0
var total_width: int = 0
var panel: Panel = null

var min_size: Vector2 = Vector2(75, 100)

# ===================== MINIPANEL CONTROLLER =====================
func _process(delta):
	update_size()

# Create a panel
# Args: pos: Vector2, offset: Vector2
# Returns: None
func create_panel(pos: Vector2, offset: Vector2 = Vector2(min_size.x, min_size.y - 15)) -> void:
	panel = Panel.new()
	panel.size = min_size
	panel.global_position = pos + offset
	add_child(panel)

# Add a button to the panel, automatically adjusts the size of the panel
# Args: text: String, callback: Callable
# Returns: None
func add_button(text: String, callback: Callable) -> void:
	if panel == null:
		return
	var button = Button.new()
	button.add_theme_color_override("font_hover_color", Color(0.812, 0.608, 0.463))
	button.add_theme_font_size_override("font_size", 12)
	button.text = text
	button.pressed.connect(func():
		callback.call()
		await get_tree().process_frame
		delete_button()
	)
	
	button.size.y = 25
	
	panel.add_child(button)
	
	button.size_flags_horizontal = Control.SIZE_FILL
	
	await get_tree().process_frame
	
	var min_size = button.get_minimum_size()
	var button_width = min_size.x + 20  # Add padding
	
	button.size.x = button_width
	
	button.position.x = 5
	button.position.y = total_height + 5
	
	total_height += 25
	if total_width < button_width:
		total_width = button_width
		update_size()

# Update the size of the panel
# Args: None
# Returns: None
func update_size() -> void:
	if total_height + 5 > panel.size.y:
		panel.size.y = total_height + 5
	if total_width + 10 > panel.size.x:
		panel.size.x = total_width + 10
		for child in panel.get_children():
			child.position.x = 5

# Delete the panel
# Args: None
# Returns: None
func delete_button() -> void:
	queue_free()


func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if panel != null and not panel.get_global_rect().has_point(get_global_mouse_position()):
				delete_button()
