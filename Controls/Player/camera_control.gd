extends Camera2D

# ===================== CAMERA CONTROL =======================

# Variables
@export var zoom_speed: float = 0.03
@export var zoom_min: float = 0.1
@export var zoom_max: float = 2.0
@export var background_fog: PackedScene = null

var is_movement_enabled: bool = true
var is_dragging: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO

# ===================== CORE FUNCTIONS =======================
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if Input.is_action_just_released("SCROLL_UP"):
			zoom_in()
		elif Input.is_action_just_released("SCROLL_DOWN"):
			zoom_out()
		elif Input.is_action_just_pressed("LEFT_CLICK"):
			is_dragging = event.pressed
			last_mouse_position = get_global_mouse_position()
		elif Input.is_action_just_released("LEFT_CLICK"):
			is_dragging = false
		elif Input.is_action_just_pressed("SPACE"):
			global_position = get_local_player_position()
	elif event is InputEventMouseMotion and is_dragging and is_movement_enabled:
		var mouse_delta = last_mouse_position - get_global_mouse_position()
		global_position += mouse_delta
		last_mouse_position = get_global_mouse_position()

# ===================== HELPER FUNCTIONS =====================
# Zoom in the camera
# Args: None
# Returns: None
func zoom_in() -> void:
	zoom = (zoom + Vector2(zoom_speed, zoom_speed)).clamp(Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))

func zoom_out() -> void:
	zoom = (zoom - Vector2(zoom_speed, zoom_speed)).clamp(Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))

func get_local_player_position():
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.name.to_int() == multiplayer.get_unique_id():
			return player.global_position
	return Vector2.ZERO
