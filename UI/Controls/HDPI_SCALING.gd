extends CanvasLayer

var scale_factor: Vector2 = Vector2(1, 1)  # Default to no scaling

func _ready():
	# Connect to the signal from UIManager
	var uimanager = find_uimanager()  # Helper function so you dont need to @onready.
	if uimanager:
		uimanager.scale_factor_changed.connect(_on_scale_factor_changed)
	else:
		printerr("UIManager not found!")

func _on_scale_factor_changed(new_scale_factor: Vector2):
	# Update the scale of this CanvasLayer
	scale_factor = new_scale_factor
	scale = scale_factor  # Apply the scale
	#Offset is handled by the anchor presets, no need to add more functionality.

func find_uimanager() -> Node:  # Helper function so you dont need to @onready.
	var nodes = get_tree().get_nodes_in_group("UIManager")
	if !nodes.is_empty():
		return nodes[0]
	else:
		return null
