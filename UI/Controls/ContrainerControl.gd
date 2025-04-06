@tool
extends Control

# ===================== CONTAINER CONTROLLER =====================
# Main script for keeping children within bounds of parent
# Optimized to run updates only when necessary. (Using Godot 4 Property Syntax)

# Private Variables
var _parent_size : Vector2 = Vector2.ZERO # Internal tracking, updated by _on_resized
var _drag_control : Control = null
var _resize_controls : Array = []
var _close_button : Button = null # Cache the node

# Keep track of signal connection status
var _is_viewport_connected : bool = false

# Public Variables
@export_category("Base Variables")

# container_name with setter
@export var container_name : String = "":
	set(value):
		if container_name == value:
			return # No change
		container_name = value
		if is_inside_tree(): # Avoid errors if called before _ready/tree entry
			_update_container_name_label()
	# No custom getter needed, defaults to returning the variable value

@export_enum("Free", "Hide") var closing_type : int = 0

# draggable_type with setter
@export_enum("Draggable", "Resizable", "Both", "None") var draggable_type : int = 0:
	set(value):
		# Basic type check (optional but good practice)
		if typeof(value) != TYPE_INT:
			push_warning("draggable_type expects an integer.")
			return
		if draggable_type == value:
			return # No change
		draggable_type = value
		if is_inside_tree():
			_update_control_type()

@export_category("Top Bar Variables")

# is_bar_visible with setter
@export var is_bar_visible : bool = true:
	set(value):
		if typeof(value) != TYPE_BOOL:
			push_warning("is_bar_visible expects a boolean.")
			return
		if is_bar_visible == value:
			return # No change
		is_bar_visible = value
		if is_inside_tree():
			_update_draggable_visibility()

@export_subgroup("Close Button")

# is_close_button_visible with setter
@export var is_close_button_visible: bool = true:
	set(value):
		if typeof(value) != TYPE_BOOL:
			push_warning("is_close_button_visible expects a boolean.")
			return
		if is_close_button_visible == value:
			return # No change
		is_close_button_visible = value
		if is_inside_tree():
			_update_close_button_visibility()


# ===================== CORE FUNCTIONS =====================

func _enter_tree() -> void:
	# Connect viewport signal here, more robust than _ready if node is removed/re-added
	if !Engine.is_editor_hint() and !_is_viewport_connected:
		# Use call_deferred to avoid potential issues during tree setup
		call_deferred("_connect_viewport_signal")

	# Initial setup that requires the node to be in the tree
	_get_node_references()
	_update_container_name_label()
	_update_control_type()
	_update_draggable_visibility()
	_update_close_button_visibility()

	# Connect to own resize signal - safe here as node is entering tree
	if !resized.is_connected(_on_resized):
		resized.connect(_on_resized)


func _exit_tree() -> void:
	# Disconnect signals to prevent memory leaks/errors
	if resized.is_connected(_on_resized):
		resized.disconnect(_on_resized)

	if !Engine.is_editor_hint() and _is_viewport_connected:
		if get_viewport().size_changed.is_connected(_on_viewport_size_changed):
			get_viewport().size_changed.disconnect(_on_viewport_size_changed)
		_is_viewport_connected = false

func _connect_viewport_signal():
	# Separate function for call_deferred
	if get_viewport(): # Ensure viewport is valid
		get_viewport().size_changed.connect(_on_viewport_size_changed)
		_is_viewport_connected = true
	else:
		push_warning("Could not connect viewport signal: Viewport not available.")


func _ready() -> void:
	# _ready() is still useful for setup that doesn't strictly require
	# being in the tree *immediately*, or for things done once after _enter_tree
	# Node refs are now fetched in _enter_tree to be available for setters earlier

	# Perform initial size/scale updates after nodes are referenced and ready
	_parent_size = size
	_update_children_size() # Initial clamp
	_update_container_name_label()

	#if !Engine.is_editor_hint():
		# Delay scale update slightly to ensure layout/size is finalized
		#call_deferred("update_scale")


# Remove or comment out _process if nothing else needs it
func _process(_delta) -> void:
	_update_container_name_label()

# --- Signal Callbacks ---

func _on_resized() -> void:
	# Triggered when this Control's size changes
	# Check if size actually changed if performance is critical here
	if _parent_size != size:
		_parent_size = size
		_update_children_size()

func _on_viewport_size_changed() -> void:
	# Triggered when the viewport (window) resizes
	pass
	#if !Engine.is_editor_hint():
		#update_scale()

# ===================== NODE REFERENCES =====================
func _get_node_references():
	# Moved node fetching here, called from _enter_tree
	# Use get_node_or_null for safety
	_drag_control = get_node_or_null("drag_control")
	var right_resize = get_node_or_null("resize_control_right")
	var left_resize = get_node_or_null("resize_control_left")
	_resize_controls.clear() # Clear in case _enter_tree runs again
	if right_resize: _resize_controls.append(right_resize)
	if left_resize: _resize_controls.append(left_resize)

	if _drag_control:
		_close_button = _drag_control.get_node_or_null("Button")
	else:
		push_warning("Node 'drag_control' not found.")

	if !_close_button and _drag_control:
		push_warning("Node 'drag_control/Button' not found.")

# ===================== HELPER FUNCTIONS (Update logic) =====================

func _update_children_size() -> void:
	# (Keep the implementation from the previous correct version)
	# ... (rest of the _update_children_size function) ...
	var children := get_children().filter(func(c): return c is Control and not c.is_in_group("UI"))
	for child in children:
		if _drag_control and child == _drag_control: # Check against cached node
			continue
		# Also skip resize controls if they are direct children
		if _resize_controls.has(child):
			continue

		if child is Control:
			var dirty = false # Flag to check if position/size actually changed

			# Keep child within parent bounds
			var original_child_size = child.size
			# Use max(0, size) to prevent negative sizes if parent is tiny
			var new_parent_size_x = max(0.0, _parent_size.x)
			var new_parent_size_y = max(0.0, _parent_size.y)
			var new_child_size = Vector2(min(child.size.x, new_parent_size_x), min(child.size.y, new_parent_size_y))
			if new_child_size != original_child_size:
				child.size = new_child_size
				dirty = true

			# Ensure child position stays within bounds
			var original_child_pos = child.position
			# Clamp uses the potentially *new* size calculated above
			# Ensure max clamp value isn't negative if size > parent_size
			var max_x = max(0.0, new_parent_size_x - child.size.x)
			var max_y = max(0.0, new_parent_size_y - child.size.y)
			var new_child_pos = Vector2(clamp(child.position.x, 0, max_x),
										 clamp(child.position.y, 0, max_y))
			if new_child_pos != original_child_pos:
				child.position = new_child_pos
				dirty = true

			# --- Overlap Check ---
			if dirty: # Optimization: Only check overlaps if the child was moved/resized by clamping
				for other in children:
					# Skip self, drag_control, resize controls
					if other == child or (_drag_control and other == _drag_control) or _resize_controls.has(other):
						continue

					var iter_count = 0
					var max_iter = 20
					while child.get_global_rect().intersects(other.get_global_rect()) and iter_count < max_iter:
						var move_dir = (child.global_position - other.global_position).normalized()
						# Handle zero vector case if positions are identical
						if move_dir == Vector2.ZERO:
							move_dir = Vector2.RIGHT # Default move direction

						child.position += move_dir * 1.0 # Adjust step size if needed

						# Re-clamp after moving due to overlap
						max_x = max(0.0, new_parent_size_x - child.size.x)
						max_y = max(0.0, new_parent_size_y - child.size.y)
						child.position.x = clamp(child.position.x, 0, max_x)
						child.position.y = clamp(child.position.y, 0, max_y)
						iter_count += 1


# Update the scale of the container
func update_scale() -> void:
	# (Keep the implementation from the previous correct version, ensure SettingConst exists or use ProjectSettings)
	# ... (rest of the update_scale function) ...
	# Store original position and size *before* scaling
	var original_position = position
	var current_size = size # Use the current size

	# Get current project settings resolution
	# Ensure viewport is valid before getting size
	if not is_inside_tree() or not get_viewport():
		return # Cannot get viewport size yet

	var viewport_size = get_viewport().size

	# --- Use Project Settings for constants ---
	var ref_width = ProjectSettings.get_setting("display/window/size/viewport_width", 1920) # Use actual viewport width as default ref
	var ref_height = ProjectSettings.get_setting("display/window/size/viewport_height", 1080)
	var min_scale = ProjectSettings.get_setting("user/ui_minimum_scale", 0.5) # Example custom setting

	if ProjectSettings.has_setting("user/window_reference_width"): # Allow override
		ref_width = ProjectSettings.get_setting("user/window_reference_width")
	if ProjectSettings.has_setting("user/window_reference_height"): # Allow override
		ref_height = ProjectSettings.get_setting("user/window_reference_height")
	# ---

	if ref_width <= 0 or ref_height <= 0:
		push_warning("Reference width/height is zero or negative, cannot calculate scale.")
		return

	var scale_factor = min(viewport_size.x / float(ref_width),
						   viewport_size.y / float(ref_height))

	# Ensure scale doesn't go below minimum value
	scale_factor = max(scale_factor, min_scale)

	# Apply scale to the current node
	scale = Vector2(scale_factor, scale_factor)

	# --- Adjust Position based on Pivot Offset ---
	# Get the actual pivot offset being used by the control
	var pivot = pivot_offset
	# Calculate the position adjustment needed to keep the pivot point stationary
	var pos_adjust = pivot * (1.0 - scale_factor)
	# Apply adjustment relative to the original position
	position = original_position + pos_adjust

	# Ensure the scaled control stays within viewport bounds (optional)
	# var scaled_size = current_size * scale
	# position.x = clamp(position.x, 0, viewport_size.x - scaled_size.x)
	# position.y = clamp(position.y, 0, viewport_size.y - scaled_size.y)



# Set the draggable property of the container
func _set_draggable(is_draggable: bool) -> void:
	if _drag_control and _drag_control.has_meta("is_draggable"): # Example: Check if property exists via meta or specific class
		_drag_control.set("is_draggable", is_draggable)
	elif _drag_control:
		# If it's a built-in property, just set it, otherwise maybe log a warning
		# Assuming 'drag_control' is a custom scene with an 'is_draggable' script variable
		if _drag_control.has_method("set_is_draggable"): # Check for setter method
			_drag_control.call("set_is_draggable", is_draggable)
		elif "is_draggable" in _drag_control: # Check if property exists
			_drag_control.set("is_draggable", is_draggable)


# Set the resizable property of the container
func _set_resizable(is_resizable: bool) -> void:
	for control in _resize_controls:
		if control and control.has_meta("is_resizable"): # Example check
			control.set("is_resizable", is_resizable)
		elif control:
			# Similar check as _set_draggable
			if control.has_method("set_is_resizable"):
				control.call("set_is_resizable", is_resizable)
			elif "is_resizable" in control:
				control.set("is_resizable", is_resizable)


# Update the text of the container name label
func _update_container_name_label() -> void:
	var label : RichTextLabel = get_node_or_null("drag_control/RichTextLabel") as RichTextLabel # Use 'as' for type hint
	if label:
		label.text = "[center]" + container_name + "[/center]"
	# else:
		# push_warning("Node 'drag_control/Label' not found or not a Label.")


# Set the control type based on the draggable_type enum
func _update_control_type() -> void:
	match draggable_type:
		0: # Draggable
			_set_draggable(true)
			_set_resizable(false)
		1: # Resizable
			_set_draggable(false)
			_set_resizable(true)
		2: # Both
			_set_draggable(true)
			_set_resizable(true)
		3: # None
			_set_draggable(false)
			_set_resizable(false)

# Set the visibility of the draggable control bar
func _update_draggable_visibility() -> void:
	if _drag_control:
		_drag_control.visible = is_bar_visible

# Set the visibility of the close button
func _update_close_button_visibility() -> void:
	if _close_button: # Use cached node
		_close_button.visible = is_close_button_visible

# Close the container
func close_container() -> void:
	var parent_node = get_parent()
	match closing_type:
		0: # Free
			if parent_node != null:
				parent_node.queue_free()
			else:
				queue_free()
		1: # Hide
			if parent_node != null:
				parent_node.hide()
			else:
				hide()
