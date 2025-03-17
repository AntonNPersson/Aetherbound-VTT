class_name context_panel extends Control

# Reference resolution (assuming 1920x1080 as base)

var total_height: int = 0
var total_width: int = 0
var panel: Panel = null
var min_size: Vector2 = Vector2(75, 100)
var scale_factor: float = 1.0
var base_font_size: int = 12
var base_button_height: int = 25

func _ready():
	# Calculate scale factor on initialization
	_calculate_scale_factor()
	# Connect to window resize signal
	get_tree().get_root().size_changed.connect(_on_window_resize)

func _on_window_resize():
	_calculate_scale_factor()
	# Recalculate all UI elements
	_rebuild_panel()

func _calculate_scale_factor():
	var viewport_size = get_viewport_rect().size
	scale_factor = min(viewport_size.x / SettingConst.WINDOW_REFERENCE_WIDTH, viewport_size.y / SettingConst.WINDOW_REFERENCE_HEIGHT)
	# Ensure we have a minimum scale factor
	scale_factor = max(scale_factor, 0.5)

func _rebuild_panel():
	if panel:
		# Store current buttons and their callbacks
		var buttons = []
		for child in panel.get_children():
			if child is Button:
				buttons.append({"text": child.text, "callback": child.pressed.get_connections()[0]["callable"]})
		
		# Clear panel
		for child in panel.get_children():
			child.queue_free()
		
		# Reset height and width
		total_height = 0
		total_width = 0
		
		# Update panel size
		panel.size = min_size * scale_factor
		
		# Recreate buttons
		for button_data in buttons:
			add_button(button_data["text"], button_data["callback"])

func _process(delta):
	_update_size()

func create_panel(pos: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	if offset == Vector2.ZERO:
		offset = Vector2(min_size.x, min_size.y + (15 * scale_factor))  
   
	panel = Panel.new()
	panel.size = min_size * scale_factor
	
	var existing_panels = get_tree().get_nodes_in_group("Panels")
	
	var new_position = pos
	
	if existing_panels.size() > 0:
		var rightmost_edge = 0
		
		for existing_panel in existing_panels:
			var right_edge = existing_panel.global_position.x + existing_panel.size.x
			if right_edge > rightmost_edge:
				rightmost_edge = right_edge
		
		new_position.x = rightmost_edge + 40 * scale_factor
		
		new_position.y = pos.y
	
	panel.global_position = new_position
	panel.add_to_group("Panels")
	add_child(panel)

func add_button(text: String, callback: Callable) -> void:
	if panel == null:
		return
	
	var button = Button.new()
	button.add_theme_color_override("font_hover_color", Color(0.812, 0.608, 0.463))
	button.add_theme_font_size_override("font_size", int(base_font_size * scale_factor))
	button.text = text
	button.pressed.connect(func():
		callback.call()
		await get_tree().process_frame
		delete_button()
	)
	
	var scaled_button_height = int(base_button_height * scale_factor)
	button.size.y = scaled_button_height
	
	panel.add_child(button)
	
	button.size_flags_horizontal = Control.SIZE_FILL
	
	await get_tree().process_frame
	
	var button_width = (min_size.x + 20) * scale_factor  # Add padding and scale
	
	button.size.x = button_width
	
	button.position.x = 5 * scale_factor
	button.position.y = total_height + (5)
	
	total_height += scaled_button_height
	if total_width < button_width:
		total_width = button_width
		_update_size()

func _update_size() -> void:
	if panel == null:
		return
		
	if total_height + (5 * scale_factor) > panel.size.y:
		panel.size.y = total_height + (5 * scale_factor)
	
	if total_width + (10 * scale_factor) > panel.size.x:
		panel.size.x = total_width + (10 * scale_factor)
		for child in panel.get_children():
			child.position.x = 5 * scale_factor

func delete_button() -> void:
	queue_free()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			if panel != null and not panel.get_global_rect().has_point(get_global_mouse_position()):
				delete_button()
