@tool
extends Control

# ===================== DRAGGABLE RESIZABLE WINDOW =====================
# Base class for all draggable and resizable windows
#
# Private Variables

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
    rect_position = parent.get_position()
    rect_size = parent.get_size()
    child_text = get_child(0)
    child_button = get_child(1)

func _process(_delta) -> void:
    position.y = -size.y
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
# Start dragging the window
# Args: Vector2 - The position of the mouse
# Returns: None
func start_dragging() -> void:
    is_dragging = true
    rect_position = parent.get_position()
    drag_offset = get_global_mouse_position() - rect_position

# Stop dragging the window
# Args: None
# Returns: None
func stop_dragging() -> void:
    is_dragging = false

# Update the position of the window while dragging
# Args: Vector2 - The position of the mouse
# Returns: None
func update_dragging() -> void:
    if is_dragging:
        rect_position = get_global_mouse_position() - drag_offset
        parent.set_position(rect_position)
        clamp_position_inside_viewport()

# Clamp the position of the window inside the viewport
# Args: None
# Returns: None
func clamp_position_inside_viewport() -> void:
    var viewport = get_viewport_rect()
    var new_position = rect_position
    rect_size = parent.get_size()
    new_position.x = clamp(new_position.x, viewport.position.x + offset, viewport.size.x - rect_size.x - offset)
    new_position.y = clamp(new_position.y, viewport.position.y + offset, viewport.size.y - rect_size.y - offset)
    parent.set_position(new_position)

# ===================== GUI INPUT =====================
func _on_gui_input(event:InputEvent) -> void:
    if !is_draggable:
        return

    if event is InputEventMouseButton:
        if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
            start_dragging()
        elif !event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
            stop_dragging()
