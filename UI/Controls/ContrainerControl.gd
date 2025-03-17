@tool
extends Control

# ===================== CONTAINER CONTROLLER =====================
# Main script for keeping children within bounds of parent
#

# Private Variables
var parent_size : Vector2 = Vector2.ZERO
var drag_control : Control = null
var resize_controls : Array = []

# Public Variables
@export_category("Base Variables")
@export var container_name : String = ""
@export_enum("Free", "Hide") var closing_type : int = 0
@export_enum("Draggable", "Resizable", "Both", "None") var draggable_type : int = 0
@export_category("Top Bar Variables")
@export var is_bar_visible : bool = true
@export_subgroup("Close Button")
@export var is_close_button_visible: bool = true

# ===================== CORE FUNCTIONS =====================

func _ready() -> void:
	drag_control = get_node("drag_control")
	resize_controls.append(get_node("resize_control_right"))
	resize_controls.append(get_node("resize_control_left"))


	set_container_name(container_name)
	set_control_type(draggable_type)
	if !Engine.is_editor_hint():
		#update_scale()
		pass

func _process(_delta) -> void:
	set_container_name(container_name)
	update_children_size()
	set_draggable_visibility()

# ===================== HELPER FUNCTIONS =====================
# Update the size of the children to stay within the parent bounds
# Args: None
# Returns: None
func update_children_size() -> void:
	parent_size = get_size()
	var children := get_children().filter(func(c): return c is Control and not c.is_in_group("UI"))
	for child in children:
		if child == get_child(0):
			continue

		if child is Control:
			# Keep child within parent bounds
			child.size.x = min(child.size.x, parent_size.x)
			child.size.y = min(child.size.y, parent_size.y)

			# Ensure child position stays within bounds
			child.position.x = clamp(child.position.x, 0, parent_size.x - child.size.x)
			child.position.y = clamp(child.position.y, 0, parent_size.y - child.size.y)

		for other in children:
			if other == child or other == get_child(0):
				continue
			
			while child.get_global_rect().intersects(other.get_global_rect()):
				if child.position.x < other.position.x:
					child.position.x -= 1
				else:
					child.position.x += 1

				if child.position.y < other.position.y:
					child.position.y -= 1
				else:
					child.position.y += 1

# Update the scale of the container
# Args: None
# Returns: None
func update_scale() -> void:
	# Store original position
	var original_position = position
	var original_size = size

	# Get current project settings resolution
	var project_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var project_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var viewport_size = Vector2(project_width, project_height)
	
	# Calculate scale factor based on ratio to reference resolution
	var scale_factor = min(viewport_size.x / SettingConst.WINDOW_REFERENCE_WIDTH, 
						   viewport_size.y / SettingConst.WINDOW_REFERENCE_HEIGHT)
	
	# Ensure scale doesn't go below minimum value
	scale_factor = max(scale_factor, SettingConst.UI_MINIMUM_SCALE)
	
	# Apply scale to the current node
	scale = Vector2(scale_factor, scale_factor)
	
	# Calculate position offset to maintain proper alignment from center
	var position_offset = (original_size * (1.0 - scale_factor)) / 4.0
	
	# Update position to compensate for scaling
	position.x = original_position.x - position_offset.x

# Set the draggable property of the container
# Args: bool - The draggable property
# Returns: None
func set_draggable(is_draggable: bool) -> void:
	drag_control.is_draggable = is_draggable

# Set the resizable property of the container
# Args: bool - The resizable property
# Returns: None
func set_resizable(is_resizable: bool) -> void:
	for control in resize_controls:
		control.is_resizable = is_resizable

# Set the name of the container
# Args: String - The name of the container
# Returns: None
func set_container_name(_name : String) -> void:
	container_name = _name
	get_child(0).get_child(0).text = "[center]" + container_name + "[/center]"

# Set the control type of the container
# Args: int - The control type
# Returns: None
func set_control_type(type: int) -> void:
	match type:
		0:
			set_draggable(true)
			set_resizable(false)
		1:
			set_draggable(false)
			set_resizable(true)
		2:
			set_draggable(true)
			set_resizable(true)
		3:
			set_draggable(false)
			set_resizable(false)

# Set the visibility of the draggable control
# Args: None
# Returns: None
func set_draggable_visibility() -> void:
	drag_control.visible = is_bar_visible

# Close the container
# Args: None
# Returns: None
func close_container() -> void:
	match closing_type:
		0:
			if get_parent() != null:
				get_parent().queue_free()
			else:
				queue_free()
		1:
			hide()
