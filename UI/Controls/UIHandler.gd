extends Node

@export var base_resolution: Vector2 = Vector2(1920, 1080)
signal scale_factor_changed(scale_factor: Vector2)  # Signal to notify CanvasLayers

var scaling_enabled: bool = false  # Track if scaling is enabled

func _ready():
	scale_ui()
	get_tree().root.size_changed.connect(scale_ui) #Listen to root resizes

func _input(event: InputEvent) -> void:
	if event.is_action_released("toggle_scale"):
		scaling_enabled = !scaling_enabled
		scale_ui()  # Re-calculate and apply scaling

func scale_ui():
	# Get the root viewport size via the scene tree
	var viewport_size = get_tree().root.get_visible_rect().size
	var scale_factor = Vector2(viewport_size.x / base_resolution.x, viewport_size.y / base_resolution.y)
	var final_scale = min(scale_factor.x, scale_factor.y)

	# Emit the scale to all CanvasLayers
	if scaling_enabled:
		scale_factor_changed.emit(Vector2(final_scale, final_scale))
	else:
		# If scaling is disabled, emit a scale factor of 1 (no scaling)
		scale_factor_changed.emit(Vector2(1, 1))  # No scaling
