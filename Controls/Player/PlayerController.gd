extends CharacterBody2D
# ===================== PLAYER CONTROLLER =====================
# Manages the player, works with the MultiplayerSynchronizer to manage the player
# Really need to make this a bit more modular
# =============================================================

# Variables
@export var character_sheet: Resource = null
@export var map: Node = null
@export var combat: Node = null
@export var player_camera: Camera2D = null
@export var ray: RayCast2D = null

# Movement Variables
var is_moving_sprite: bool = false

# Mouse variables
var is_mouse_over: bool = false
var click_start_time = 0.0
const CLICK_THRESHOLD = 0.3

# State variables
var combat_mode: bool = false
var is_hidden: bool = false

# vision variables
var visible_area: Polygon2D = null
var shadow_area: Node2D = null
var vision_color: Color = Color(1, 1, 1, 0)

# ===================== CORE FUNCTIONS =====================
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("MultiplayerSynchronizer").set_multiplayer_authority(str(name).to_int())

	visible_area = Polygon2D.new()
	visible_area.color = vision_color
	add_child(visible_area)

	shadow_area = Node2D.new()
	add_child(shadow_area)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	if get_node("MultiplayerSynchronizer").is_multiplayer_authority():

		if combat_mode:
			pass
		else:
			exploration_process()
	elif Net.is_host():
		moving_sprite()
		
		# Probably need to make this a bit better in the future
		if Input.is_action_just_pressed("LEFT_CLICK"):
			if is_moving_sprite:
				move_to_tile.rpc(get_global_mouse_position())
				var move_sprite = get_node_or_null("Move Sprite")
				move_sprite.queue_free()
				get_node("Sprite2D").show()
				is_moving_sprite = false
			

# Process for exploration mode
# Args: None
# Returns: None
func exploration_process() -> void:
	player_input()

	# For visual representation of the sprite moving
	moving_sprite()

# Process for combat mode
# Args: None
# Returns: None
func combat_process() -> void:
	pass

# ===================== INPUT FUNCTIONS =====================

# Player input
# Args: None
# Returns: None
func player_input() -> void:
	if Input.is_action_just_pressed("UP"):
		move_to_tile_with_collision(Vector2(0, -300))
	elif Input.is_action_just_pressed("DOWN"):
		move_to_tile_with_collision(Vector2(0, 300))
		update_line_of_sight()
	elif Input.is_action_just_pressed("LEFT"):
		move_to_tile_with_collision(Vector2(-300, 0))
	elif Input.is_action_just_pressed("RIGHT"):
		move_to_tile_with_collision(Vector2(300, 0))

# Input function
# Args: InputEvent - The input event
# Returns: None
func _input(event):
	if !get_node("MultiplayerSynchronizer").is_multiplayer_authority():
		return
	movement(event, player_camera)

# ===================== MOVEMENT FUNCTIONS =====================
# Movement function, allows drag and drop movement
# Args: InputEvent - The input event, Camera2D - The camera
# Returns: None
func movement(event, camera: Camera2D) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			click_start_time = Time.get_ticks_msec() / 1000.0
			start_move_sprite(camera)

		elif event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			var click_duration = Time.get_ticks_msec() / 1000.0 - click_start_time
			if click_duration < CLICK_THRESHOLD:
				map.select_tile(get_global_mouse_position())

			stop_move_sprite(camera)

# Networking functions

# Move the player to a specific tile
# Args: Vector2 - The tile to move to
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func move_to_tile(tile: Vector2) -> void:
	map.move_to_tile(self, tile)

	if get_node("MultiplayerSynchronizer").is_multiplayer_authority():
		update_line_of_sight()

func move_to_tile_with_collision(direction: Vector2) -> void:
	if !is_colliding(direction):
		map.move_to_tile(self, global_position + direction)
		update_line_of_sight()

# ===================== GM FUNCTIONS =========================

func hide_token() -> void:
	modulate.a = 0.5
	is_hidden = true
	set_token_visibility.rpc(false)
	
func show_token() -> void:
	modulate.a = 1
	is_hidden = false
	set_token_visibility.rpc(true)

func show_line_of_sight() -> void:
	visible_area.visible = true
	update_line_of_sight()

func hide_line_of_sight() -> void:
	visible_area.visible = false
	visible_area.polygon = PackedVector2Array([])
	for shadow in shadow_area.get_children():
		shadow.queue_free()
	update_line_of_sight()

# Networking functions

# Set the visibility of the token
# Args: bool - The visibility of the token
# Returns: None
@rpc("any_peer", "call_remote", "reliable")
func set_token_visibility(visibility: bool) -> void:
	visible = visibility

@rpc("any_peer", "call_remote", "reliable")
func move_token() -> void:
	if is_moving_sprite:
		return

	var sprite = get_node("Sprite2D")
	var new_sprite = sprite.duplicate()
	new_sprite.name = "Move Sprite"
	add_child(new_sprite)
	sprite.hide()
	is_moving_sprite = true

@rpc("any_peer", "call_remote", "reliable")
func set_vision_color(color: Color) -> void:
	vision_color = color
	update_line_of_sight()
	
# ===================== HELPER FUNCTIONS =====================
# Start moving the sprite, for drag and drop
# Args: None
# Returns: None
func start_move_sprite(camera: Camera2D) -> void:
	if is_moving_sprite:
		return

	if is_mouse_over and map.is_tile_selected(global_position):
		camera.is_movement_enabled = false
		var sprite = get_node("Sprite2D")
		var new_sprite = sprite.duplicate()
		new_sprite.name = "Move Sprite"
		add_child(new_sprite)
		sprite.hide()
		is_moving_sprite = true

# Stop moving the sprite, for drag and drop
# Args: None
# Returns: None
func stop_move_sprite(camera: Camera2D) -> void:
	var move_sprite = get_node_or_null("Move Sprite")
	if move_sprite == null:
		return

	is_moving_sprite = false
	move_sprite.queue_free()

	map.move_to_tile(self, get_global_mouse_position())
	get_node("Sprite2D").show()
	camera.is_movement_enabled = true

# Move the sprite to the mouse position
# Args: None
# Returns: None
func moving_sprite() -> void:
	if is_moving_sprite:
		var _moving_sprite = get_node_or_null("Move Sprite")
		if _moving_sprite:
			_moving_sprite.global_position = get_global_mouse_position()

# Check if the player is colliding with something using raycasts
# Args: Vector2 - The direction to check
# Returns: bool - If the player is colliding
func is_colliding(direction: Vector2) -> bool:
	ray.target_position = direction
	ray.global_position = global_position
	ray.force_raycast_update()
	return ray.is_colliding()

# Update the line of sight, creating polygons based on raycasts. Might need to change this to a shader depending on performance.
# Args: None
# Returns: None
func update_line_of_sight() -> void:
	if Settings.global_illumination:
		return

	var los_points = []
	var view_distance = 8000 # Player's vision distance
	var ray_count = Settings.global_vision_rays_count
	visible_area.color = vision_color

	for i in range(ray_count):
		var angle = i * (2 * PI / ray_count)
		var direction = Vector2(cos(angle), sin(angle))

		ray.global_position = global_position
		ray.target_position = direction * view_distance
		ray.force_raycast_update()

		
		var point = global_position + direction * view_distance
		if ray.is_colliding():
			point = ray.get_collision_point()
		
		los_points.append(point - global_position)  # Relative to player
	
	# Update visible area polygon
	visible_area.polygon = PackedVector2Array(los_points)
	
	for shadow in shadow_area.get_children():
		shadow.queue_free()
	create_shadows(los_points, view_distance)

func create_shadows(los_points: Array, view_distance: int) -> void:
	var fog_poly = Polygon2D.new()
	fog_poly.color = Settings.global_fog_color
	fog_poly.polygon = PackedVector2Array(los_points)
	fog_poly.invert_border = view_distance  # Invert to make LOS area a hole
	fog_poly.invert_enabled = true
	fog_poly.antialiased = true
	shadow_area.add_child(fog_poly)

# will use later
func bound_ray_to_tilemap(start_pos: Vector2, direction: Vector2, max_dist: float, map_min: Vector2, map_max: Vector2) -> float:
	var intersections = []
	var normalized_dir = direction.normalized()
	
	if normalized_dir.x < 0:
		var t = (map_min.x - start_pos.x) / normalized_dir.x
		var y = start_pos.y + normalized_dir.y * t
		if y >= map_min.y and y <= map_max.y and t > 0:
			intersections.append(t)
	
	if normalized_dir.x > 0:
		var t = (map_max.x - start_pos.x) / normalized_dir.x
		var y = start_pos.y + normalized_dir.y * t
		if y >= map_min.y and y <= map_max.y and t > 0:
			intersections.append(t)
	
	if normalized_dir.y < 0:
		var t = (map_min.y - start_pos.y) / normalized_dir.y
		var x = start_pos.x + normalized_dir.x * t
		if x >= map_min.x and x <= map_max.x and t > 0:
			intersections.append(t)
	
	if normalized_dir.y > 0:
		var t = (map_max.y - start_pos.y) / normalized_dir.y
		var x = start_pos.x + normalized_dir.x * t
		if x >= map_min.x and x <= map_max.x and t > 0:
			intersections.append(t)
	
	var min_t = max_dist
	for t in intersections:
		if t > 0 and t < min_t:
			min_t = t
	
	return min_t

# ===================== SIGNAL FUNCTIONS =====================
# Mouse entered signal
# Args: None
# Returns: None
func _on_mouse_exited() -> void:
	is_mouse_over = false

# Mouse exited signal
# Args: None
# Returns: None
func _on_mouse_entered() -> void:
	is_mouse_over = true

