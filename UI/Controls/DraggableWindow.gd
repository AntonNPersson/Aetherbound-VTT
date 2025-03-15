@tool
extends Control

# ===================== DRAGGABLE RESIZABLE WINDOW =====================
# Base class for all draggable and resizable windows

var is_draggable : bool = true
var is_dragging : bool = false
var drag_offset : Vector2 = Vector2.ZERO
var rect_position : Vector2 = Vector2.ZERO
var rect_size : Vector2 = Vector2.ZERO
var offset : int = 5
var parent : Control = null
var child_text : Variant = null
var child_button : Variant = null

# ===================== CORE FUNCTIONS =====================
func _ready() -> void:
	parent = get_parent()
	rect_position = parent.position
	rect_size = parent.size
	child_text = get_child(0)
	child_button = get_child(1)

func _process(_delta) -> void:
	# Remove this line or understand its purpose - this is forcing the window to stay at the top
	# position.y = -size.y  # <-- This is likely causing your issue
	
	size.x = parent.size.x
	size.y = max(20, size.y)
	
	if !is_draggable:
		return
		
	child_text.position.x = (size.x - child_text.size.x) / 2
	child_text.position.y = (size.y - child_text.size.y) / 2 + 2
	child_button.position.x = size.x - child_button.size.x
	child_button.position.y = 0
	
	if not Engine.is_editor_hint():
		update_dragging()

# ===================== Helper FUNCTIONS =====================
func start_dragging() -> void:
	is_dragging = true
	rect_position = parent.position
	drag_offset = get_global_mouse_position() - rect_position

func stop_dragging() -> void:
	is_dragging = false

func update_dragging() -> void:
	if is_dragging:
		rect_position = get_global_mouse_position() - drag_offset
		parent.position = rect_position
		#clamp_position_inside_viewport()

func clamp_position_inside_viewport() -> void:
	var viewport_rect = get_viewport_rect()
	rect_size = parent.size
	
	# Calculate the actual viewport bounds in global coordinates
	var min_x = 0
	var min_y = 0
	var max_x = viewport_rect.size.x - rect_size.x
	var max_y = viewport_rect.size.y - rect_size.y
	
	# Clamp the position
	var new_position = Vector2(
		clamp(rect_position.x, min_x, max_x),
		clamp(rect_position.y, min_y, max_y)
	)
	
	# Update the parent's position and our tracking variable
	parent.position = new_position
	rect_position = new_position

# ===================== GUI INPUT =====================
func _on_gui_input(event:InputEvent) -> void:
	if !is_draggable:
		return
		
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			start_dragging()
		elif !event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			stop_dragging()
