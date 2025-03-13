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
@export var global_shadow: ColorRect = null

# Movement Variables
var is_moving_sprite: bool = false

# Mouse variables
var is_mouse_over: bool = false
var click_start_time = 0.0
const CLICK_THRESHOLD = 0.3

# State variables
var combat_mode: bool = false
var is_hidden: bool = false
var is_possesed: bool = false

# vision variables
var visible_area: Polygon2D = null
var shadow_area: Node2D = null
var vision_color: Color = Color(1, 1, 1, 0)
var debug_rays: Array = []
var is_debugging: bool = false
var _previous_shadow_data = []

# ===================== CORE FUNCTIONS =====================
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("MultiplayerSynchronizer").set_multiplayer_authority(name.to_int())

	# Why the fuck do i need to instantiate a new ray when ive added it in the export variable on the editer? 
	if ray == null:
		ray = RayCast2D.new()
		ray.enabled = true
		ray.collision_mask = 2
		add_child(ray)

	# Why the fuck do i need to instantiate a new shadow material when ive added it in the editor? and only on exported game?
	if global_shadow == null:
		var shadow_material = ShaderMaterial.new()
		shadow_material.shader = load("res://Assets/Shaders/los_shader.gdshader")
		global_shadow = ColorRect.new()
		global_shadow.material = shadow_material
		global_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(global_shadow)
		
	visible_area = Polygon2D.new()
	visible_area.color = vision_color
	add_child(visible_area)

	shadow_area = Node2D.new()
	add_child(shadow_area)
	print("Player Controller Ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:

	if Net.is_host():
		if is_possesed:
			update_line_of_sight()
			pass
		moving_sprite()
		if Input.is_action_just_pressed("LEFT_CLICK"):
			if is_moving_sprite:
				move_to_tile.rpc(get_global_mouse_position())
				var move_sprite = get_node_or_null("Move Sprite")
				move_sprite.queue_free()
				get_node("Sprite2D").show()
				is_moving_sprite = false

	if get_node("MultiplayerSynchronizer").is_multiplayer_authority():

		if combat_mode:
			pass
		else:
			exploration_process()
			

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
		move_to_tile_with_collision(Vector2(0, -map.tile_size.y))
	elif Input.is_action_just_pressed("DOWN"):
		move_to_tile_with_collision(Vector2(0, map.tile_size.y))
	elif Input.is_action_just_pressed("LEFT"):
		move_to_tile_with_collision(Vector2(-map.tile_size.x, 0))
	elif Input.is_action_just_pressed("RIGHT"):
		move_to_tile_with_collision(Vector2(map.tile_size.x, 0))

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

# Move the player to a specific tile with collision
# Args: Vector2 - The direction to move
# Returns: None
func move_to_tile_with_collision(direction: Vector2) -> void:
	if !is_colliding(direction):
		map.move_to_tile(self, global_position + direction)
		update_line_of_sight()

# ===================== GM FUNCTIONS =========================

# Hide the token
# Args: None
# Returns: None
func hide_token() -> void:
	modulate.a = 0.5
	is_hidden = true
	set_token_visibility.rpc(false)

# Show the token
# Args: None
# Returns: None
func show_token() -> void:
	modulate.a = 1
	is_hidden = false
	set_token_visibility.rpc(true)

# Show the line of sight
# Args: None
# Returns: None
func show_line_of_sight() -> void:
	visible_area.visible = true
	global_shadow.visible = true
	is_possesed = true
	update_line_of_sight()

# Hide the line of sight
# Args: None
# Returns: None
func hide_line_of_sight() -> void:
	visible_area.visible = false
	is_possesed = false
	global_shadow.visible = false
	visible_area.polygon = PackedVector2Array([])
	for shadow in shadow_area.get_children():
		shadow.queue_free()

# Networking functions

# Set the visibility of the token
# Args: bool - The visibility of the token
# Returns: None
@rpc("any_peer", "call_remote", "reliable")
func set_token_visibility(visibility: bool) -> void:
	visible = visibility

# Move the token
# Args: None
# Returns: None
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

# Set the vision color
# Args: Color - The color, int - The current map, int - The current local map
# Returns: None
@rpc("any_peer", "call_remote", "reliable")
func set_vision_color(color: Color, current_map: int, current_local_map: int) -> void:
	if current_local_map != current_map and !Net.is_host():
		return

	vision_color = color
	update_line_of_sight()
	
# ===================== HELPER FUNCTIONS =====================
# Start moving the sprite, for drag and drop (I should probably make a drag and drop system that i can use for other things)
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

# Start moving the sprite, for drag and drop (I should probably make a drag and drop system that i can use for other things)
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
	update_line_of_sight()
	get_node("Sprite2D").show()
	camera.is_movement_enabled = true

# Start moving the sprite, for drag and drop (I should probably make a drag and drop system that i can use for other things)
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

# Convert global position to uv position of the global shadow texture
# Args: Array - The global position
# Returns: Array - The uv position
func global_to_uv_position(global_pos: Array) -> Array:
	var local_positions = []
	var uv_positions = []
	
	for pos in global_pos:
		local_positions.append(to_local(pos))
	
	for pos in local_positions:
		uv_positions.append((pos + global_shadow.size/2) / global_shadow.size)
	
	return uv_positions

# Convert global radius to uv radius of the global shadow texture
# Args: Array - The global radius
# Returns: Array - The uv radius
func global_to_uv_radius(radius: Array) -> Array:
	var uv_radiuses = []
	var size = global_shadow.size
	
	var max_size = max(size.x, size.y)
	
	for r in radius:
		uv_radiuses.append(r / max_size)
	
	return uv_radiuses

# ===================== VISION FUNCTIONS =====================

# Update the global illumination, using a shader to create shadows.
# Args: None
# Returns: None
func global_shadows() -> void:
	if !Settings.map_settings["global_illumination"]:
		global_shadow.size = Vector2(map.get_tilemap_view_distance() * 2, map.get_tilemap_view_distance() * 2)
		global_shadow.visible = true
		global_shadow.color = Settings.map_settings["global_fog_color"]
		global_shadow.z_index = 9

		global_shadow.global_position = global_position - global_shadow.size / 2

		var light_data_positions = [global_position]
		var light_data_radii = [1200]

		var light_positions = global_to_uv_position(light_data_positions)
		var light_radii = global_to_uv_radius(light_data_radii)
		var light_count = light_data_positions.size()

		global_shadow.material.set_shader_parameter("hole_positions", light_positions)
		global_shadow.material.set_shader_parameter("hole_radii", light_radii)
		global_shadow.material.set_shader_parameter("hole_count", light_count)
		global_shadow.material.set_shader_parameter("hole_color", Color(0, 0, 0, 0))
	else:
		global_shadow.visible = false
		

# Update the line of sight, creating polygons based on raycasts. Might need to change this to a shader depending on performance.
# Args: None
# Returns: None
func update_line_of_sight() -> void:
	var los_points = []
	var shadow_data = []
	var view_distance = map.get_tilemap_view_distance()
	var ray_count = Settings.map_settings["global_vision_rays_count"] *2
	visible_area.color = vision_color
	debug_rays = []
	
	var reference = Vector2.RIGHT
	
	for i in range(ray_count):
		var angle = i * (2 * PI / ray_count)
		var direction = reference.rotated(angle)
		
		ray.target_position = direction * view_distance
		ray.force_raycast_update()
		var point = global_position + direction * view_distance
		if ray.is_colliding():
			point = ray.get_collision_point()
			
			var collision_direction = (point - global_position).normalized()
			
			var collision_angle = collision_direction.angle()
			
			shadow_data.append({
				"point": point,
				"direction": collision_direction,
				"angle": collision_angle
			})
			debug_rays.append(point - global_position)
		los_points.append(point - global_position)
	
	visible_area.polygon = PackedVector2Array(los_points)
	visible_area.z_index = 8
	
	for shadow in shadow_area.get_children():
		shadow.queue_free()
	
	create_shadow_regions(shadow_data, view_distance)
	global_shadows()
	queue_redraw()

func _draw():
	if is_debugging:
		for point in debug_rays:
			draw_line(Vector2(0, 0), point, Color(1, 0, 0), 1)

# Create shadow regions based on the shadow data
# Args: Array - The shadow data, int - The view distance
# Returns: None
func create_shadow_regions(shadow_data: Array, view_distance: int) -> void:
	if shadow_data.size() < 2:
		return
	
	shadow_data.sort_custom(func(a, b): 
		return wrapf(a["angle"], 0, TAU) < wrapf(b["angle"], 0, TAU)
	)
	
	var shadow_regions = []
	var current_region = [shadow_data[0]]
	var ray_count = Settings.map_settings["global_vision_rays_count"]
	var angle_threshold = 2 * PI / ray_count * 1.5
	
	for i in range(1, shadow_data.size()):
		var prev_direction = shadow_data[i-1]["direction"]
		var curr_direction = shadow_data[i]["direction"]
		
		var angle_diff = abs(prev_direction.angle_to(curr_direction))
		
		if angle_diff > angle_threshold:
			shadow_regions.append(current_region)
			current_region = [shadow_data[i]]
		else:
			current_region.append(shadow_data[i])
	
	shadow_regions.append(current_region)
	
	if shadow_regions.size() >= 2:
		var first_region = shadow_regions[0]
		var last_region = shadow_regions[shadow_regions.size() - 1]
		
		var first_direction = first_region[0]["direction"]
		var last_direction = last_region[last_region.size() - 1]["direction"]
		
		var wrap_diff = abs(last_direction.angle_to(first_direction))
		
		if wrap_diff <= angle_threshold:
			var merged_region = last_region + first_region
			shadow_regions.pop_back()
			shadow_regions[0] = merged_region
	
	if shadow_regions.size() < 1:
		return
	
	for region in shadow_regions:
		create_shadow_polygon(region, view_distance)

# Create a shadow polygon based on the shadow region
# Args: Array - The shadow region, int - The view distance
# Returns: None
func create_shadow_polygon(shadow_region: Array, view_distance: int) -> void:
	var shadow_points = []
	
	for point in shadow_region:
		shadow_points.append(point["point"] - global_position)
	
	var extension_factor = 1.05  # 5% extension to help close gaps
	
	var last_point = shadow_region[shadow_region.size() - 1]
	var last_dir = last_point["direction"].rotated(0.1)  # Rotate slightly outward
	shadow_points.append((last_point["point"] + last_dir * view_distance * extension_factor) - global_position)
	
	for i in range(shadow_region.size() - 2, 0, -1):
		var point = shadow_region[i]
		shadow_points.append((point["point"] + point["direction"] * view_distance * extension_factor) - global_position)
	
	var first_point = shadow_region[0]
	var first_dir = first_point["direction"].rotated(-0.1)  # Rotate slightly outward
	shadow_points.append((first_point["point"] + first_dir * view_distance * extension_factor) - global_position)
	
	var shadow_poly = Polygon2D.new()
	shadow_poly.polygon = PackedVector2Array(shadow_points)
	shadow_poly.color = Settings.map_settings["global_fog_color"]
	shadow_poly.antialiased = true
	shadow_poly.z_index = 10
	shadow_poly.set("draw_polygon_outline", true)
	shadow_area.add_child(shadow_poly)



# will use later to prohibit the shadows from leaving the map (saving resources)
# Args: Vector2 - The start position, Vector2 - The direction, float - The maximum distance, Vector2 - The minimum map position, Vector2 - The maximum map position
# Returns: float - The bound ray to tilemap
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
