extends Camera2D

# ===================== CAMERA CONTROL =======================

# Variables
@export var zoom_speed: float = 0.1 # Change to a multiplicative factor (e.g., 10% change per scroll)
@export var zoom_min: float = 0.1
@export var zoom_max: float = 2.0
@export var background_fog: PackedScene = null

var is_movement_enabled: bool = true:
	get:
		return is_movement_enabled
	set(value):
		is_movement_enabled = value
var is_scrolling_enabled: bool = true

var is_dragging: bool = false
# Store positions relative to the viewport for better drag calculation
var drag_start_viewport_pos: Vector2 = Vector2.ZERO
var camera_start_position: Vector2 = Vector2.ZERO

# ===================== CORE FUNCTIONS =======================

func _unhandled_input(event):
	if event is InputEventMouseButton:
		# --- Zoom Handling (More standard approach) ---
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_out()

		# --- Drag Handling (Start/Stop) ---
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_movement_enabled:
				# Start dragging
				is_dragging = true
				# Record where the drag started in viewport coordinates
				drag_start_viewport_pos = get_viewport().get_mouse_position()
				# Record where the camera was when dragging started
				camera_start_position = global_position
			else:
				# Stop dragging
				is_dragging = false

	# Removed mouse motion from _unhandled_input

	# --- Spacebar Handling ---
	elif event is InputEventKey:
		# Consider using Input singleton for action checks if feasible
		if Input.is_action_just_pressed("SPACE"): # Assuming "SPACE" action is defined
			if !Net.is_host(): # Check if this logic is still needed here
				var player_pos = get_local_player_position()
				if player_pos != Vector2.ZERO: # Only move if player found
					global_position = player_pos


func _process(delta):
	# --- Apply Drag Movement (if dragging) ---
	if is_dragging and is_movement_enabled:
		# Get current mouse position in viewport coordinates
		var current_viewport_pos = get_viewport().get_mouse_position()

		# Calculate how far the mouse has moved on screen since drag started
		var screen_delta = drag_start_viewport_pos - current_viewport_pos

		# Convert the screen movement delta to world movement delta
		# Divide by zoom factor (use x or y, assumes uniform zoom)
		var world_delta = screen_delta / zoom.x

		# Calculate the new target camera position
		# Start position + how much the mouse has moved in world units
		global_position = camera_start_position + world_delta


# ===================== HELPER FUNCTIONS =====================

# Zoom in the camera (multiplicative zoom feels better)
func zoom_in() -> void:
	if is_scrolling_enabled:
		# zoom_speed is now a factor, e.g., 0.1 means 10% zoom change
		var zoom_factor = 1.0 - zoom_speed
		var target_zoom = zoom * zoom_factor
		zoom = target_zoom.clamp(Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))

# Zoom out the camera
func zoom_out() -> void:
	if is_scrolling_enabled:
		var zoom_factor = 1.0 + zoom_speed
		var target_zoom = zoom * zoom_factor
		zoom = target_zoom.clamp(Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))

# Get local player position (ensure it's robust)
func get_local_player_position() -> Vector2:
	# Cache group lookup slightly? Maybe not needed unless called very often.
	var players = get_tree().get_nodes_in_group("players")
	var local_id = multiplayer.get_unique_id()
	for player in players:
		# Safer check: Ensure player has 'name' property and it can be converted
		if player.has_meta("player_id") and player.get_meta("player_id") == local_id:
			return player.global_position
		# Fallback to name check if you use node names as IDs
		elif player.name.is_valid_int() and player.name.to_int() == local_id:
			return player.global_position

	push_warning("Local player node not found in group 'players'.")
	return Vector2.ZERO # Return zero if not found
