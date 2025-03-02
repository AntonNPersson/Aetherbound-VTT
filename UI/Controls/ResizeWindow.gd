@tool
extends Control
@export var right = true

# ===================== REZIZE HEIGHT =====================
# Resize the height of the parent node

# Private Variables
var is_resizable : bool = true
var parent : Control = null
var parent_size : Vector2 = Vector2.ZERO
var children : Array = []
var is_holding : bool = false
var new_width : int = 0

# ===================== CORE FUNCTIONS =====================

func _ready() -> void:
	parent = get_parent()
	parent_size = parent.get_size()
	for child in parent.get_children():
		if child is Control and !child.is_in_group("UI"):
			children.append(child)

func _process(_delta) -> void:
	if !is_resizable:
		return
	update_parent_height()
	update_parent_width()

# ===================== HELPER FUNCTIONS =====================
# Update the height of the parent node
# Args: None
# Returns: None
func update_parent_height() -> void:
	position.y = parent.size.y - size.y

	if is_holding:
		var mouse_position = get_global_mouse_position()
		var new_height = mouse_position.y - parent.get_global_position().y
		new_height = max(new_height, 100)

		parent.size.y = new_height
		
		#for child in children:
			#if child is Control and child != parent.get_child(0):
				#child.size.y = new_height * (child.size.y / parent_size.y)
				#child.position.y = min(child.position.y, new_height - child.size.y)

	parent_size.y = parent.get_size().y

# Update the width of the parent node
# Args: None
# Returns: None
func update_parent_width() -> void:
	if right:
		position.x = parent.size.x - size.x
	else:
		position.x = 0

	if is_holding:
		var mouse_position = get_global_mouse_position()

		if right:
			new_width = mouse_position.x - parent.get_global_position().x
			new_width = max(new_width, 100)
		else:
			new_width = parent.get_global_position().x + parent_size.x - mouse_position.x
			new_width = max(new_width, 100)

			var new_parent_pos = parent.position.x + parent_size.x - new_width
			parent.set_position(Vector2(new_parent_pos, parent.position.y))

		parent.set_size(Vector2(new_width, parent_size.y))

		for child in children:
			if child is Control:
				child.size.x = new_width * (child.size.x / parent_size.x)
				child.position.x = min(child.position.x, new_width - child.size.x)

	parent_size.x = parent.get_size().x

# ===================== GUI INPUT =====================
func _on_gui_input(event:InputEvent) -> void:
	if !is_resizable:
		return

	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
			is_holding = true
		if !event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			is_holding = false