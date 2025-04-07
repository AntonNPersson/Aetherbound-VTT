extends CharacterBody2D
# ===================== PLAYER CONTROLLER =====================
# Manages the player, works with the MultiplayerSynchronizer to manage the player
# Really need to make this a bit more modular
# (Vision/Shadow functions replaced with optimized versions)
# =============================================================

# Variables
@export var character_sheet: Resource = null
@export var map: Node = null
@export var combat: Node = null
@export var player_camera: Camera2D = null
@export var ray: RayCast2D = null # Kept for is_colliding() function
@export var global_shadow: ColorRect = null

# Movement Variables
var is_moving_sprite: bool = false
var is_paused: bool = false

# Mouse variables
var is_mouse_over: bool = false
var click_start_time = 0.0
const CLICK_THRESHOLD = 0.3

# State variables
var combat_mode: bool = false
var is_hidden: bool = false
var is_possesed: bool = false

# Vision variables
var visible_area: Polygon2D = null
var shadow_area: Node2D = null
var vision_color: Color = Color(1, 1, 1, 0)
var debug_rays: Array = [] # Keep as generic Array as per original
var is_debugging: bool = false
# var _previous_shadow_data = [] # Original was unused, commented out unless needed

# --- NEW: Variables for Optimized Vision ---
# Shadow Polygon Pooling
var shadow_polygon_pool: Array[Polygon2D] = []
var active_shadow_polygons: int = 0
const INITIAL_SHADOW_POOL_SIZE: int = 10 # Adjust as needed
const SHADOW_POOL_GROW_STEP: int = 5    # Adjust as needed

# Physics State Caching
var space_state: PhysicsDirectSpaceState2D
var physics_query: PhysicsRayQueryParameters2D # Reusable query object
# --- END NEW Variables ---


# ===================== CORE FUNCTIONS =====================
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Bus.send_tile_size.connect(_change_size)

	get_node("MultiplayerSynchronizer").set_multiplayer_authority(name.to_int())
	# Why the fuck do i need to instantiate a new ray when ive added it in the export variable on the editer?
	if ray == null:
		ray = RayCast2D.new()
		ray.enabled = true
		ray.collision_mask = 2 # Keep original mask for is_colliding()
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

	# --- NEW: Initialize Vision System ---
	# Pre-allocate shadow polygons
	_grow_shadow_pool(INITIAL_SHADOW_POOL_SIZE)
	# Initialize physics query object
	physics_query = PhysicsRayQueryParameters2D.create(Vector2.ZERO, Vector2.ZERO)
	physics_query.exclude = [get_rid()] # Exclude self by default
	# --- END NEW ---

# --- NEW: Added for Physics State Caching ---
func _physics_process(_delta: float) -> void:
	# Cache the space state once per physics frame
	space_state = get_world_2d().direct_space_state
# --- END NEW ---

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	if is_paused:
		return

	if Net.is_host():
		if is_possesed:
			# --- MODIFIED: Check space_state before calling ---
			if space_state:
				update_line_of_sight()
			# --- END MODIFIED ---

		moving_sprite()
		if Input.is_action_just_pressed("LEFT_CLICK"):
			var move_sprite = get_node_or_null("Move Sprite") # Keep _or_null
			# Check is_moving_sprite *before* RPC and queue_free
			if is_moving_sprite and is_instance_valid(move_sprite):
				move_to_tile.rpc(get_global_mouse_position())
				move_sprite.queue_free()
				get_node("Sprite2D").show()
				is_moving_sprite = false
			# If not moving sprite, maybe do something else or nothing

	if get_node("MultiplayerSynchronizer").is_multiplayer_authority():

		if combat_mode:
			pass
		else:
			exploration_process()

# Process for exploration mode
func exploration_process() -> void:
	player_input()
	moving_sprite()

# Process for combat mode
func combat_process() -> void:
	moving_sprite()

# ===================== INPUT FUNCTIONS =====================
# (Keep original functions exactly)
func player_input() -> void:
	if Input.is_action_just_pressed("UP"):
		move_to_tile_with_collision(Vector2(0, -map.tile_size.y))
	elif Input.is_action_just_pressed("DOWN"):
		move_to_tile_with_collision(Vector2(0, map.tile_size.y))
	elif Input.is_action_just_pressed("LEFT"):
		move_to_tile_with_collision(Vector2(-map.tile_size.x, 0))
	elif Input.is_action_just_pressed("RIGHT"):
		move_to_tile_with_collision(Vector2(map.tile_size.x, 0))

func _input(event):
	if !get_node("MultiplayerSynchronizer").is_multiplayer_authority():
		return
	movement(event, player_camera)

# ===================== MOVEMENT FUNCTIONS =====================
# (Keep original functions exactly)
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

@rpc("any_peer", "call_local", "reliable")
func move_to_tile(tile: Vector2) -> void:
	# Assuming MoveCommand and command_manager exist globally or are accessible
	var move_command = MoveCommand.new(self, tile, map)
	command_manager.execute_command(move_command)

	# --- MODIFIED: Check space_state ---
	if get_node("MultiplayerSynchronizer").is_multiplayer_authority() and is_possesed:
		if space_state: update_line_of_sight()
	# --- END MODIFIED ---


func move_to_tile_with_collision(direction: Vector2) -> void:
	if map.get_token_at_position(global_position + direction) != null:
		return

	if !is_colliding(direction): # Uses the original is_colliding func/ray
		var move_command = MoveCommand.new(self, global_position + direction, map)
		command_manager.execute_command(move_command)
		# --- MODIFIED: Check space_state ---
		if get_node("MultiplayerSynchronizer").is_multiplayer_authority() and is_possesed:
			if space_state: update_line_of_sight()
		# --- END MODIFIED ---

# ===================== GM FUNCTIONS =========================
# (Keep original functions exactly)
func hide_token() -> void:
	modulate.a = 0.5
	is_hidden = true
	set_token_visibility.rpc(false)

func show_token() -> void:
	modulate.a = 1.0 # Use 1.0 for float
	is_hidden = false
	set_token_visibility.rpc(true)

func show_line_of_sight() -> void:
	# Check nodes before accessing properties
	if is_instance_valid(visible_area): visible_area.visible = true
	if is_instance_valid(global_shadow): global_shadow.visible = true
	is_possesed = true
	# --- MODIFIED: Check space_state ---
	if space_state: update_line_of_sight()
	# --- END MODIFIED ---

# --- MODIFIED: hide_line_of_sight to use pooling ---
func hide_line_of_sight() -> void:
	if is_instance_valid(visible_area):
		visible_area.visible = false
		visible_area.polygon = PackedVector2Array([])

	if is_instance_valid(global_shadow):
		global_shadow.visible = false

	is_possesed = false

	# Deactivate pooled polygons instead of freeing children
	for i in range(active_shadow_polygons):
		if is_instance_valid(shadow_polygon_pool[i]): # Good practice here
			shadow_polygon_pool[i].visible = false
	active_shadow_polygons = 0
# --- END MODIFIED ---

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
func set_vision_color(color: Color, current_map: int, current_local_map: int) -> void:
	if current_local_map != current_map and !Net.is_host():
		return

	vision_color = color
	# Update polygon color immediately if it exists
	if is_instance_valid(visible_area):
		visible_area.color = vision_color

	# --- MODIFIED: Check space_state ---
	if get_node("MultiplayerSynchronizer").is_multiplayer_authority() and is_possesed:
		if space_state: update_line_of_sight()
	# --- END MODIFIED ---

# ===================== HELPER FUNCTIONS =====================
# (Keep original functions exactly, except update_line_of_sight call in stop_move_sprite)
func start_move_sprite(camera: Camera2D) -> void:
	if is_moving_sprite:
		return

	if is_mouse_over and map.is_tile_selected(global_position):
		if is_instance_valid(camera): camera.is_movement_enabled = false # Added validity check
		var sprite = get_node("Sprite2D")
		var new_sprite = sprite.duplicate()
		new_sprite.name = "Move Sprite"
		add_child(new_sprite)
		sprite.hide()
		is_moving_sprite = true

func stop_move_sprite(camera: Camera2D) -> void:
	var move_sprite = get_node_or_null("Move Sprite")
	if move_sprite == null or not is_moving_sprite: # Added check for is_moving_sprite
		# Ensure camera movement is re-enabled even if sprite wasn't found but maybe should have been
		if is_instance_valid(camera): camera.is_movement_enabled = true
		return

	is_moving_sprite = false
	move_sprite.queue_free()

	map.move_to_tile(self, get_global_mouse_position())

	# --- MODIFIED: Check space_state ---
	if get_node("MultiplayerSynchronizer").is_multiplayer_authority() and is_possesed:
		if space_state: update_line_of_sight()
	# --- END MODIFIED ---

	get_node("Sprite2D").show()
	if is_instance_valid(camera): camera.is_movement_enabled = true # Added validity check
	# Original await logic
	await get_tree().process_frame
	map.select_tile(global_position)

func moving_sprite() -> void:
	if is_moving_sprite:
		var _moving_sprite = get_node_or_null("Move Sprite")
		if _moving_sprite: # Keep validity check
			_moving_sprite.global_position = get_global_mouse_position()


# Check if the player is colliding with something using raycasts
# Args: Vector2 - The direction to check
# Returns: bool - If the player is colliding
func is_colliding(direction: Vector2) -> bool:
	# --- Scaling Adjustment ---
	# Ensure scale components are not zero to avoid division errors
	if scale.x == 0 or scale.y == 0:
		printerr("Collision check attempted with zero scale component!")
		return true # Treat as collision to prevent movement in error state

	# Adjust the local target_position to account for the parent's scale.
	# We want the ray's world length to be 'direction'.
	# Since world_length = local_length * scale, then local_length = world_length / scale.
	ray.target_position = direction / scale
	# --------------------------

	# Ensure ray node is positioned correctly relative to NPC origin in the editor (e.g., at (0,0) or slightly offset)
	# REMOVE THIS LINE if you were setting it manually: ray.global_position = global_position

	ray.force_raycast_update() # Get immediate result

	var collider = ray.get_collider()

	# Optional Debugging:
	# print("Checking Dir: ", direction, " | Scale: ", scale, " | Ray Local Target: ", ray.target_position, \
	#       " | Ray Global Pos: ", ray.global_position, " | Colliding: ", ray.is_colliding(), " | Collider: ", collider)

	if collider:
		var collider_parent = collider.get_parent()
		if is_instance_valid(collider_parent) and collider_parent.has_meta("type"):
			if collider_parent.get_meta("type") == "Phantom Wall":
				return false # Treat phantom walls as non-colliding for movement

	# Return true if colliding with anything *other* than a phantom wall
	return ray.is_colliding()
	
# (Keep original helper functions exactly)
func global_to_uv_position(global_pos: Array) -> Array:
	var local_positions = []
	var uv_positions = []
	if !is_instance_valid(global_shadow): return uv_positions # Added check

	for pos in global_pos:
		# Original logic used player's to_local
		local_positions.append(to_local(pos))

	for pos in local_positions:
		# Original calculation
		uv_positions.append((pos + global_shadow.size/2) / global_shadow.size)

	return uv_positions

func global_to_uv_radius(radius: Array) -> Array:
	var uv_radiuses = []
	if !is_instance_valid(global_shadow) or global_shadow.size == Vector2.ZERO: return uv_radiuses # Added check

	var size = global_shadow.size
	var max_size = max(size.x, size.y)
	if max_size == 0: return uv_radiuses # Avoid division by zero

	for r in radius:
		uv_radiuses.append(r / max_size)

	return uv_radiuses


# ===================== VISION FUNCTIONS (REPLACED) =====================

# --- NEW: Shadow Polygon Pooling Helpers ---
func _grow_shadow_pool(increase_by: int):
	for _i in range(increase_by):
		var shadow_poly = Polygon2D.new()
		# Set properties that don't change per frame
		# Use original Settings access pattern
		if Settings.map_settings.has("global_fog_color"):
			shadow_poly.color = Settings.map_settings["global_fog_color"]
		else:
			shadow_poly.color = Color.BLACK # Default fallback
		shadow_poly.antialiased = true
		shadow_poly.z_index = 10 # Ensure shadows render above visible area
		# Keep original outline setting logic
		shadow_poly.set("draw_polygon_outline", true)
		shadow_poly.visible = false # Start inactive
		shadow_polygon_pool.append(shadow_poly)
		# Add to shadow_area node created in _ready
		if is_instance_valid(shadow_area):
			shadow_area.add_child(shadow_poly)

func _get_shadow_polygon_from_pool() -> Polygon2D:
	if active_shadow_polygons >= shadow_polygon_pool.size():
		_grow_shadow_pool(SHADOW_POOL_GROW_STEP)

	# Check if pool didn't grow for some reason
	if active_shadow_polygons >= shadow_polygon_pool.size():
		printerr("Failed to grow shadow pool!")
		# Return a temporary new polygon or handle error
		var temp_poly = Polygon2D.new()
		# Configure temp_poly similarly to pooled ones if needed
		return temp_poly


	var poly: Polygon2D = shadow_polygon_pool[active_shadow_polygons]
	active_shadow_polygons += 1
	poly.visible = true # Activate it
	return poly
# --- END NEW Helpers ---

# (Keep original shader update functions exactly)
func update_shader_wall_data(_material) -> void:
	var wall_start_points = []
	var wall_end_points = []
	var wall_count = 0
	var max_walls = 500 # Keep original value

	# Keep original access pattern map.line_walls
	for line in map.line_walls.get_children():
		if line is Line2D:
			# Keep original meta check logic
			if line.has_meta("type"):
				if line.get_meta("type") == "Invisible Wall":
					continue
			var points = line.points
			var point_count = points.size() - 1
			if point_count <= 0 : continue # Avoid invalid range

			# Original limit calculation logic
			if wall_count + point_count > max_walls:
				point_count = max_walls - wall_count # This logic seems slightly off, maybe meant min()?

			# Corrected loop range and limit check
			var points_to_add = min(point_count, max_walls - wall_count)
			if points_to_add <= 0: break

			for i in range(points_to_add):
				# Original point access
				wall_start_points.append(line.to_global(points[i])) # Convert to global space
				wall_end_points.append(line.to_global(points[i + 1])) # Convert to global space

			wall_count += points_to_add

			if wall_count >= max_walls:
				break

	if wall_count < max_walls:
		# Keep original access pattern map.portals
		for p in map.portals.get_children():
			# Original logic for checking portal holder and resource
			if p.has_node("PortalHolder"):
				var portal_holder = p.get_node("PortalHolder") # Direct get_node
				if p is Line2D and portal_holder.has_meta("portal_resource") and \
				   !portal_holder.get_meta("portal_resource").is_open:

					var points = p.points
					var point_count = points.size() - 1 # Use original min() logic here
					var points_to_add = min(point_count, max_walls - wall_count)

					if points_to_add <= 0: continue # Skip if no points fit

					for i in range(points_to_add):
						# Original point access
						wall_start_points.append(p.to_global(points[i])) # Convert to global
						wall_end_points.append(p.to_global(points[i + 1])) # Convert to global

					wall_count += points_to_add

					if wall_count >= max_walls:
						break

	# Convert coordinates only once at the end
	# Uses the original global_to_uv_position function
	wall_start_points = global_to_uv_position(wall_start_points)
	wall_end_points = global_to_uv_position(wall_end_points)

	# Update shader parameters (original parameter names)
	_material.set_shader_parameter("wall_start_points", wall_start_points)
	_material.set_shader_parameter("wall_end_points", wall_end_points)
	_material.set_shader_parameter("wall_count", wall_count)


func global_shadows() -> void:
	# Keep original checks and access patterns (map.lm, Settings.map_settings)

	# Check cache size before proceeding
	if map.lm.cached_lights.size() < 1:
		return # Return early if no lights *in cache* (original first check)


	if Settings.map_settings["global_illumination"]:
		if is_instance_valid(global_shadow): global_shadow.visible = false
		return

	if !is_instance_valid(global_shadow): return # Need the node

	# Keep original setup logic
	global_shadow.size = Vector2(map.get_tilemap_view_distance() * 2, map.get_tilemap_view_distance() * 2)
	global_shadow.visible = true
	global_shadow.color = Settings.map_settings["global_fog_color"]
	global_shadow.z_index = 9
	global_shadow.global_position = global_position - global_shadow.size / 2.0 # Use float division

	# Keep original light data structure and access
	var light_data_positions = [global_position]
	var light_data_radii = [1400.0] # Keep original hardcoded value

	var map_index_name = map.get_map_name_from_index(map.current_map) # Original call
	if map.lm.cached_lights.has(map_index_name):
		# Iterate using original variable name 'lights' for each item
		for lights in map.lm.cached_lights[map_index_name]:
			# Assume 'lights' object has 'light_position' and 'light_radius' properties
			light_data_positions.append(lights.light_position)
			light_data_radii.append(lights.light_radius)

	# Use original helper functions for conversion
	var light_positions = global_to_uv_position(light_data_positions)
	var light_radii = global_to_uv_radius(light_data_radii)
	var light_count = light_data_positions.size()

	# Get material and update shader (keep original parameter names)
	var mat = global_shadow.material
	if mat is ShaderMaterial:
		update_shader_wall_data(mat) # Call original function
		mat.set_shader_parameter("hole_positions", light_positions)
		mat.set_shader_parameter("hole_radii", light_radii)
		mat.set_shader_parameter("hole_count", light_count)
		mat.set_shader_parameter("hole_color", Color(0, 0, 0, 0))
		mat.set_shader_parameter("debug_mode", false)
	# else: Fail silently or log error if material isn't a ShaderMaterial


# --- REPLACED: Line of Sight Update (Using PhysicsDirectSpaceState2D) ---
func update_line_of_sight() -> void:
	# Essential check kept
	if !space_state:
		printerr("Cannot update LOS: Physics space state not available.")
		return
	# Check visible_area exists
	if !is_instance_valid(visible_area):
		printerr("Cannot update LOS: VisibleArea Polygon2D not initialized.")
		return

	# --- Prepare ---
	var los_points = [] # Keep as generic Array like original
	var shadow_data = [] # Keep as generic Array like original
	var view_distance: float = map.get_tilemap_view_distance() # Use float, original call
	var ray_count: int = Settings.map_settings["global_vision_rays_count"] * 2 # Original access
	# Set color here as original did
	visible_area.color = vision_color
	debug_rays = [] # Reset debug rays (original used generic Array)

	var origin_global: Vector2 = global_position
	var angle_step: float = TAU / float(ray_count) if ray_count > 0 else 0.0
	var max_passes: int = 5 # Keep original pass limit for invisible walls

	# --- Configure Physics Query ---
	# Mask needs to hit BOTH visible and invisible walls for the pass-through logic
	# Adjust mask based on your layer setup (e.g., layer 1=visible, layer 2=invisible)
	physics_query.collision_mask = 2 # Example: Binary 0011 (Layers 1 and 2) - ** ADJUST AS NEEDED **
	physics_query.collide_with_areas = false
	physics_query.collide_with_bodies = true

	# --- Cast Rays ---
	for i in range(ray_count):
		var angle: float = i * angle_step
		# Original used Vector2.RIGHT reference
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)

		# --- Simulate Pass-Through Logic with Direct API ---
		var current_origin: Vector2 = origin_global
		var remaining_distance: float = view_distance
		var passes: int = 0
		# Default end point if no collisions
		var final_end_point: Vector2 = origin_global + direction * view_distance
		var hit_visible_wall_this_ray: bool = false # Renamed from original hit_visible_wall

		while passes < max_passes and remaining_distance > 0.1: # Keep original threshold
			physics_query.from = current_origin
			physics_query.to = current_origin + direction * remaining_distance

			var result: Dictionary = space_state.intersect_ray(physics_query)

			if result:
				var collision_point: Vector2 = result.position
				var collider = result.collider # Can be CollisionObject2D or RID

				# Check if it's an invisible wall (using original meta check logic)
				var is_invisible: bool = false
				if collider is CollisionObject2D:
					var collider_node : CollisionObject2D = collider
					var parent_node = collider_node.get_parent()
					# Keep exact original meta check logic
					if parent_node and parent_node.has_meta("type"):
						is_invisible = (parent_node.get_meta("type") == "Invisible Wall")

				if is_invisible:
					# Pass through: Adjust origin and remaining distance
					# Use original distance calculation method
					var distance_to_hit = current_origin.distance_to(collision_point)
					# Original offset logic
					current_origin = collision_point + direction * 0.1
					# Original remaining distance logic (problematic if dist_to_hit > remaining?)
					# Let's use a safer subtraction:
					remaining_distance = max(0.0, remaining_distance - (distance_to_hit + 0.1))
					passes += 1
					# Update potential end point in case this is the last pass
					final_end_point = current_origin + direction * remaining_distance

				else:
					# Hit a visible wall: Record collision and stop this ray's loop
					final_end_point = collision_point
					hit_visible_wall_this_ray = true # Mark visible hit

					# --- Store Shadow Data (using original calculation method) ---
					var relative_hit_point = final_end_point - origin_global
					# Calculate direction/angle once
					var dir_to_hit = relative_hit_point.normalized()
					var angle_to_hit = dir_to_hit.angle()

					# Use original dictionary structure
					shadow_data.append({
						"point": final_end_point, # Global position
						"direction": dir_to_hit,  # Normalized direction from player
						"angle": angle_to_hit    # Angle from player
					})
					# --- End Shadow Data ---

					# Store debug ray data (original calculation)
					debug_rays.append(relative_hit_point) # Add relative hit point

					break # Stop the while loop for this ray (hit visible wall)

			else:
				# No collision within remaining distance for this segment
				final_end_point = current_origin + direction * remaining_distance
				break # Stop the while loop for this ray
		# --- End Pass-Through Loop ---

		# Add the final point (relative to player) to the LOS polygon list
		var relative_end_point = final_end_point - origin_global
		los_points.append(relative_end_point)

		# Original didn't add debug rays if no wall was hit, replicating that:
		# (Debug rays are now added inside the visible hit block)

	# --- Update Visuals ---
	# Update the main visibility polygon (use PackedVector2Array like original)
	visible_area.polygon = PackedVector2Array(los_points)
	visible_area.z_index = 8 # Keep original z-index

	# Deactivate old shadow polygons (INSTEAD of queue_free)
	for i in range(active_shadow_polygons):
		if is_instance_valid(shadow_polygon_pool[i]):
			shadow_polygon_pool[i].visible = false
	active_shadow_polygons = 0 # Reset counter

	# Create new shadow regions using pooled polygons (call new function)
	create_shadow_regions(shadow_data, view_distance)

	# Call original global_shadows function
	global_shadows()

	# Call original queue_redraw
	queue_redraw()
# --- END REPLACED ---

# --- REPLACED: Shadow Region Creation (Uses Pooling) ---
func create_shadow_regions(shadow_data: Array, view_distance: float) -> void: # Use float for distance
	if shadow_data.size() < 2:
		return # Not enough points to form shadow edges

	# Sort by pre-calculated angle (known dictionary structure)
	shadow_data.sort_custom(func(a, b):
		# Use original wrapf range [0, TAU]
		return wrapf(a["angle"], 0.0, TAU) < wrapf(b["angle"], 0.0, TAU)
	)

	var shadow_regions = [] # Keep generic Array
	var current_region = [] # Keep generic Array
	# Add first point to start
	if shadow_data.size() > 0:
		current_region = [shadow_data[0]]
	else:
		return # Should not happen if size < 2 check passed, but safety

	# Use original Settings access pattern
	var base_ray_count: int = Settings.map_settings["global_vision_rays_count"]
	# Use original threshold calculation
	var angle_threshold: float = (TAU / float(base_ray_count)) * 1.5 if base_ray_count > 0 else PI

	# Group points into contiguous regions
	for i in range(1, shadow_data.size()):
		# Access known dictionary keys directly
		var prev_direction = shadow_data[i-1]["direction"]
		var curr_direction = shadow_data[i]["direction"]

		# Use original angle_to check
		var angle_diff: float = abs(prev_direction.angle_to(curr_direction))

		if angle_diff > angle_threshold:
			# Finish previous region, start new one
			shadow_regions.append(current_region)
			current_region = [shadow_data[i]]
		else:
			# Add to current region
			current_region.append(shadow_data[i])

	shadow_regions.append(current_region) # Add the last region

	# Check wrap-around case (merge last and first region if close)
	if shadow_regions.size() >= 2:
		# Original variable names and access
		var first_region = shadow_regions[0]
		var last_region = shadow_regions[-1] # Use -1 for last index

		# Check if regions have points before accessing
		if first_region.size() > 0 and last_region.size() > 0:
			var first_direction = first_region[0]["direction"]
			var last_direction = last_region[-1]["direction"] # Last point of last region

			# Use original angle_to check
			var wrap_diff: float = abs(last_direction.angle_to(first_direction))

			if wrap_diff <= angle_threshold:
				# Merge last region into first region (original order)
				var merged_region = last_region + first_region
				shadow_regions.pop_back() # Remove the last region
				shadow_regions[0] = merged_region # Update first region

	if shadow_regions.size() < 1:
		return

	# Create polygons for valid regions using the pool
	for region in shadow_regions:
		# Pass float distance
		setup_shadow_polygon_for_region(region, view_distance)
# --- END REPLACED ---

# --- REPLACED: Shadow Polygon Geometry Setup (Uses Pooling) ---
# This function replaces the old 'create_shadow_polygon'
func setup_shadow_polygon_for_region(shadow_region: Array, view_distance: float) -> void: # Use float distance
	# Original didn't have this check, but good practice for safety
	if shadow_region.size() < 1: return

	# Use known dictionary keys directly
	var first_collision_global: Vector2 = shadow_region[0]["point"]
	# Ensure region has enough points for last element access
	var last_collision_global: Vector2
	if shadow_region.size() > 0:
		last_collision_global = shadow_region[-1]["point"] # Last point
	else:
		# Should be unreachable due to outer checks, but handle defensively
		return

	# Calculate edge distance only if more than one point
	var edge_distance: float = 0.0
	if shadow_region.size() > 1:
		edge_distance = first_collision_global.distance_to(last_collision_global)

	# Original visual width check logic and value (changed from 20 to 1 in user code)
	var min_visual_width: float = 1.0 # Match user's last value
	# Apply check only if there's an edge to measure
	if shadow_region.size() > 1 and edge_distance < min_visual_width:
		return

	# Get a polygon from the pool
	var shadow_poly: Polygon2D = _get_shadow_polygon_from_pool()
	# If pool returned temporary/invalid, skip
	if !is_instance_valid(shadow_poly) or !shadow_poly.is_inside_tree():
		# Pool should handle errors, but double check
		active_shadow_polygons -=1 # Correct counter if pool failed
		printerr("Failed to get valid polygon from pool for shadow.")
		return


	# --- Build Polygon Points (Relative to Player) ---
	var shadow_points = [] # Keep generic Array
	var origin_global: Vector2 = global_position

	# 1. Add inner edge points (collision points relative to player)
	for point_data in shadow_region:
		# Use original subtraction, access known key
		shadow_points.append(point_data["point"] - origin_global)

	# 2. Add outer edge points (extended points relative to player)
	# Use original extension factor and offset logic
	var extension_factor: float = 1.05 # Original value
	var position_offset = global_position # Original variable name

	if shadow_region.size() > 0:
		# Extend last point (using original logic/variable names)
		var last_point = shadow_region[-1] # Original variable name
		# Use original rotation offset
		var last_dir: Vector2 = last_point["direction"].rotated(0.1)
		# Use original calculation and offset variable
		shadow_points.append((last_point["point"] + last_dir * view_distance * extension_factor) - position_offset)

		# Extend intermediate points (in reverse, using original logic)
		for i in range(shadow_region.size() - 2, -1, -1): # Original range was (size-2, 0, -1) - Needs correction
			# Corrected range: Iterate backwards from second-to-last down to 0
			var point = shadow_region[i] # Original variable name
			# Extend using original calculation
			shadow_points.append((point["point"] + point["direction"] * view_distance * extension_factor) - position_offset)


		# Extend first point (using original logic/variable names)
		# This is now implicitly handled by the loop ending at index 0 above.
		# The original code added this *explicitly* after the intermediate loop.
		# Let's match that original explicit addition:
		var first_point = shadow_region[0] # Original variable name
		# Use original rotation offset
		var first_dir: Vector2 = first_point["direction"].rotated(-0.1)
		# Use original calculation and offset variable
		shadow_points.append((first_point["point"] + first_dir * view_distance * extension_factor) - position_offset)

	# --- Assign points to the pooled polygon ---
	if shadow_points.size() > 2:
		# Use PackedVector2Array like original
		shadow_poly.polygon = PackedVector2Array(shadow_points)
		# Set properties on the pooled polygon (original values)
		shadow_poly.color = Settings.map_settings["global_fog_color"]
		shadow_poly.antialiased = true
		shadow_poly.z_index = 10
		shadow_poly.set("draw_polygon_outline", true) # Keep original setting
		# Visibility is already set true by _get_shadow_polygon_from_pool
	else:
		# Not enough points to form a polygon, hide this one
		shadow_poly.visible = false
		active_shadow_polygons -= 1 # Decrement counter as it wasn't used
# --- END REPLACED ---

func _change_size(tile_size: Vector2) -> void:
	if tile_size == Vector2.ZERO:
		return # Avoid division by zero

	if tile_size.x == 150:
		scale = Vector2(0.5, 0.5)
	elif tile_size.x == 300:
		scale = Vector2(1, 1)
	elif tile_size.x == 50:
		scale = Vector2(0.25, 0.25)
	

# Keep original _draw function
func _draw():
	if is_debugging:
		for point in debug_rays: # Assumes debug_rays contains Vector2 relative points
			draw_line(Vector2.ZERO, point, Color(1, 0, 0), 1.0) # Use Vector2.ZERO


# ===================== SIGNAL FUNCTIONS =====================
# (Keep original functions exactly)
func _on_mouse_exited() -> void:
	is_mouse_over = false

func _on_mouse_entered() -> void:
	is_mouse_over = true

# --- NEW: Helper for Angle Difference ---
static func angle_difference(angle1: float, angle2: float) -> float:
	# Returns the shortest angle between two angles in range [-PI, PI]
	return wrapf(angle1 - angle2 + PI, 0.0, TAU) - PI
# --- END NEW ---

# --- NEW: Add _exit_tree for cleanup ---
func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE:
		if is_instance_valid(visible_area):
			visible_area.queue_free()
			visible_area = null
		if is_instance_valid(shadow_area):
			shadow_area.queue_free() # This frees all children (pooled polygons) too
			shadow_area = null

		# Clear the pool array itself to release references
		shadow_polygon_pool.clear()
# --- END NEW ---
