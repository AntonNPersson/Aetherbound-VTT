extends Control
# ===================== DRAW MENU =====================
# The draw menu is a menu that allows the player to
# draw on the map. This is useful for planning out
# strategies, or just having fun.
# ====================================================
# Public variables
@export var map: Node = null

# Controls
var distance_ruler: Control = null
var emanation_ruler: Control = null
var burst_ruler: Control = null
var cone_ruler: Control = null
var camera: Node = null
var text_input: Label = null

# Helper variables
var is_initialized: bool = false
var is_measuring_distance: bool = false
var is_measuring_emanation: bool = false
var is_measuring_burst: bool = false
var is_measuring_cone: bool = false
var currently_measuring: bool = false
var measuring_tiles: Array = []
var emanation_center: Vector2 = Vector2.ZERO
var burst_center: Vector2 = Vector2.ZERO
var cone_origin: Vector2 = Vector2.ZERO
var cone_direction: Vector2 = Vector2.ZERO

# Extra
var cone_type = "Round"

var distance_keep: bool = false
var emanation_keep: bool = false
var burst_keep: bool = false
var cone_keep: bool = false

# ===================== CORE FUNCTIONS =====================

# Called when the ui is initialize in the scenemanager
func _initialize():
	distance_ruler = get_child(0).get_node("Distance")
	distance_ruler.toggled.connect(toggle_distance_ruler)
	emanation_ruler = get_child(0).get_node("Emanation")
	emanation_ruler.toggled.connect(toggle_emanation_tool)
	burst_ruler = get_child(0).get_node("Burst")
	burst_ruler.toggled.connect(toggle_burst_tool)
	cone_ruler = get_child(0).get_node("Cone")
	cone_ruler.toggled.connect(toggle_cone_tool)

	camera = get_tree().get_nodes_in_group("camera")[0]
	text_input = Label.new()
	text_input.hide()
	add_child(text_input)
	is_initialized = true

func _process(delta):
	# Only process if the ui is initialized
	if is_initialized:
		# If the player is measuring distance, to show feet in the ui and draw the path
		if currently_measuring and is_measuring_distance and map.is_global_inside_tilemap(map.get_mouse_position()):
			text_input.text = str(map.get_distance_to(measuring_tiles[0], map.get_mouse_position(), true)) + "Feet"
			text_input.global_position = get_global_mouse_position() - Vector2(0, 20)
			text_input.show()
		elif currently_measuring and is_measuring_emanation and map.is_global_inside_tilemap(map.get_mouse_position()):
			var current_pos = map.get_mouse_position()
			var tile_distance = map.get_distance_to(emanation_center, current_pos)

			calculate_emanation_tiles(emanation_center, tile_distance)
			map.distance_path = measuring_tiles
			map.queue_redraw()

			text_input.text = str(tile_distance) + "Feet"
			text_input.global_position = get_global_mouse_position() - Vector2(0, 20)
			text_input.show()
		elif currently_measuring and is_measuring_burst and map.is_global_inside_tilemap(map.get_mouse_position()):
			var current_pos = map.get_mouse_position()
			var tile_distance = map.get_distance_to(burst_center, current_pos)

			calculate_burst_tiles(burst_center, tile_distance)
			map.distance_path = measuring_tiles
			map.queue_redraw()

			text_input.text = str(tile_distance) + " Feet"
			text_input.global_position = get_global_mouse_position() - Vector2(0, 20)
			text_input.show()
		elif currently_measuring and is_measuring_cone and map.is_global_inside_tilemap(map.get_mouse_position()):
			var current_pos = map.get_mouse_position()
			var length = map.get_distance_to(cone_origin, current_pos)

			cone_direction = (current_pos - cone_origin).normalized()
			calculate_cone_tiles(cone_origin, cone_direction, length, cone_type)

			map.distance_path = measuring_tiles
			map.queue_redraw()

			text_input.text = str(length) + " Feet"
			text_input.global_position = get_global_mouse_position() - Vector2(0, 20)
			text_input.show()
		else:
			text_input.hide()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# If the player is measuring distance, add the start tile to the measuring array
			if is_measuring_distance and map.is_global_inside_tilemap(map.get_mouse_position()):
				measuring_tiles.append(map.get_mouse_position())
				currently_measuring = true
			elif is_measuring_emanation and map.is_global_inside_tilemap(map.get_mouse_position()):
				emanation_center = map.get_mouse_position()
				measuring_tiles.append(map.get_mouse_position())
				currently_measuring = true
			elif is_measuring_burst and map.is_global_inside_tilemap(map.get_mouse_position()):
				burst_center = map.get_mouse_position()
				measuring_tiles.append(burst_center)
				currently_measuring = true
			elif is_measuring_cone and map.is_global_inside_tilemap(map.get_mouse_position()):
				cone_origin = map.get_mouse_position()
				measuring_tiles.clear()
				measuring_tiles.append(cone_origin)
				currently_measuring = true
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			# If the player is measuring distance, add the end tile to the measuring array, and draw the entire path
			if is_measuring_distance and map.is_global_inside_tilemap(map.get_mouse_position()):
				measuring_tiles.append(map.get_mouse_position())
				if !distance_keep:
					map.queue_redraw()
				
				measuring_tiles.clear()
				currently_measuring = false
			elif is_measuring_emanation and map.is_global_inside_tilemap(map.get_mouse_position()) and currently_measuring:
				var final_pos = map.get_mouse_position()
				var final_radius = map.get_distance_to(emanation_center, final_pos)
				calculate_emanation_tiles(emanation_center, final_radius)
				
				map.distance_path = measuring_tiles

				if !emanation_keep:
					map.queue_redraw()
				
				measuring_tiles.clear()
				currently_measuring = false
			elif is_measuring_burst and map.is_global_inside_tilemap(map.get_mouse_position()) and currently_measuring:
				var final_pos = map.get_mouse_position()
				var final_radius = map.get_distance_to(burst_center, final_pos)
				
				calculate_burst_tiles(burst_center, final_radius)
				
				map.distance_path = measuring_tiles

				if !burst_keep:
					map.queue_redraw()
				
				measuring_tiles.clear()
				currently_measuring = false
			elif is_measuring_cone and map.is_global_inside_tilemap(map.get_mouse_position()) and currently_measuring:
				var final_pos = map.get_mouse_position()
				var final_length = map.get_distance_to(cone_origin, final_pos)
				var final_direction = (final_pos - cone_origin).normalized()

				calculate_cone_tiles(cone_origin, final_direction, final_length, cone_type)
				map.distance_path = measuring_tiles
				if !cone_keep:
					map.queue_redraw()

				measuring_tiles.clear()
				currently_measuring = false

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_measuring_cone:
				var context = create_base_context_menu()
				if cone_keep:
					context.add_button("Lose", func(): cone_keep = false)
				else:
					context.add_button("Keep", func(): cone_keep = true)
				if cone_type == "Round":
					context.add_button("Default", func(): cone_type = "Default")
				else:
					context.add_button("Round", func(): cone_type = "Round")
			elif is_measuring_burst:
				var context = create_base_context_menu()
				if burst_keep:
					context.add_button("Lose", func(): burst_keep = false)
				else:
					context.add_button("Keep", func(): burst_keep = true)
			elif is_measuring_emanation:
				var context = create_base_context_menu()
				if emanation_keep:
					context.add_button("Lose", func(): emanation_keep = false)
				else:
					context.add_button("Keep", func(): emanation_keep = true)
			elif is_measuring_distance:
				var context = create_base_context_menu()
				if distance_keep:
					context.add_button("Lose", func(): distance_keep = false)
				else:
					context.add_button("Keep", func(): distance_keep = true)

# ===================== INPUT FUNCTIONS =====================
# Toggle the distance ruler, when you press the button
# Args: is_toggled: bool
# Returns: None
func toggle_distance_ruler(is_toggled: bool) -> void:
	is_measuring_distance = is_toggled
	
	if is_toggled:
		emanation_ruler.button_pressed = false
		is_measuring_emanation = false
		burst_ruler.button_pressed = false
		is_measuring_burst = false
		cone_ruler.button_pressed = false
		is_measuring_cone = false
	
	distance_ruler.button_pressed = is_toggled
	map.is_drawing = is_toggled
	map.pause_tilemap_input = is_toggled
	camera.is_movement_enabled = !is_toggled
	measuring_tiles.clear()
	map.distance_path.clear()

# Toggle the emanation tool
# Args: is_toggled: bool
# Returns: None
func toggle_emanation_tool(is_toggled: bool) -> void:
	is_measuring_emanation = is_toggled
	
	if is_toggled:
		distance_ruler.button_pressed = false
		is_measuring_distance = false
		burst_ruler.button_pressed = false
		is_measuring_burst = false
		cone_ruler.button_pressed = false
		is_measuring_cone = false
	
	emanation_ruler.button_pressed = is_toggled
	map.is_drawing = is_toggled  # Reuse is_drawing flag to trigger drawing
	map.pause_tilemap_input = is_toggled
	camera.is_movement_enabled = !is_toggled
	measuring_tiles.clear()
	map.distance_path.clear()

# Toggle the burst tool
# Args: is_toggled: bool
# Returns: None
func toggle_burst_tool(is_toggled: bool) -> void:
	is_measuring_burst = is_toggled
	
	if is_toggled:
		distance_ruler.button_pressed = false
		is_measuring_distance = false
		emanation_ruler.button_pressed = false
		is_measuring_emanation = false
		cone_ruler.button_pressed = false
		is_measuring_cone = false
	
	burst_ruler.button_pressed = is_toggled
	map.is_drawing = is_toggled
	map.pause_tilemap_input = is_toggled
	camera.is_movement_enabled = !is_toggled
	measuring_tiles.clear()
	map.distance_path.clear()

# Toggle the cone tool
# Args: is_toggled: bool
# Returns: None
func toggle_cone_tool(is_toggled: bool) -> void:
	is_measuring_cone = is_toggled
	
	if is_toggled:
		distance_ruler.button_pressed = false
		is_measuring_distance = false
		emanation_ruler.button_pressed = false
		is_measuring_emanation = false
		burst_ruler.button_pressed = false
		is_measuring_burst = false
	
	cone_ruler.button_pressed = is_toggled
	map.is_drawing = is_toggled
	map.pause_tilemap_input = is_toggled
	camera.is_movement_enabled = !is_toggled
	measuring_tiles.clear()
	map.distance_path.clear()

func create_base_context_menu() -> context_panel:
	var context = context_panel.new()
	add_child(context)
	context.create_panel(get_viewport().get_mouse_position(), Vector2(0,0))
	return context

# ===================== HELPER FUNCTIONS =====================
# Calculate the tiles for the emanation tool
# Args: center: Vector2, radius_feet: float
# Returns: None
func calculate_emanation_tiles(center: Vector2, radius_feet: float) -> void:
	measuring_tiles.clear()
	
	var center_tile = map.convert_to_tilemap_pos(center)
	var radius_tiles = radius_feet / 5.0  # Convert feet to tiles
	
	if abs(radius_tiles - 1.0) < 0.1:  # Checking if it's close to exactly 1 tile radius (5 feet)
		for x in range(center_tile.x - 1, center_tile.x + 2):
			for y in range(center_tile.y - 1, center_tile.y + 2):
				if x >= 0 and x < map.map_width and y >= 0 and y < map.map_height:
					measuring_tiles.append(map.convert_to_global_pos(Vector2(x, y)))
		return
	
	if radius_tiles < 1.0:
		measuring_tiles.append(map.convert_to_global_pos(center_tile))
		return
	
	var max_distance = ceil(radius_tiles)
	var start_x = center_tile.x - max_distance
	var end_x = center_tile.x + max_distance
	var start_y = center_tile.y - max_distance
	var end_y = center_tile.y + max_distance
	
	start_x = max(0, start_x)
	end_x = min(map.map_width - 1, end_x)
	start_y = max(0, start_y)
	end_y = min(map.map_height - 1, end_y)
	
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var dx = abs(x - center_tile.x)
			var dy = abs(y - center_tile.y)
			
			if dx == max_distance and dy == max_distance:
				continue
				
			measuring_tiles.append(map.convert_to_global_pos(Vector2(x, y)))

# Calculate the tiles for the burst tool
# Args: center: Vector2, radius_feet: float
# Returns: None
func calculate_burst_tiles(center: Vector2, radius_feet: float) -> void:
	measuring_tiles.clear()
	
	var center_tile = map.convert_to_tilemap_pos(center)
	var radius_tiles = radius_feet / 5.0  # Convert feet to tiles
	
	if radius_tiles < 0.6:  # Less than 5 feet
		measuring_tiles.append(map.convert_to_global_pos(center_tile))
		return
	
	var max_distance = ceil(radius_tiles)
	var start_x = center_tile.x - max_distance
	var end_x = center_tile.x + max_distance
	var start_y = center_tile.y - max_distance
	var end_y = center_tile.y + max_distance
	
	start_x = max(0, start_x)
	end_x = min(map.map_width - 1, end_x)
	start_y = max(0, start_y)
	end_y = min(map.map_height - 1, end_y)
	
	for x in range(start_x, end_x + 1):
		for y in range(start_y, end_y + 1):
			var dx = x - center_tile.x
			var dy = y - center_tile.y
			
			var manhattan_distance = abs(dx) + abs(dy)
			
			var euclidean_distance = sqrt(dx * dx + dy * dy)
			
			var weight = 0.7
			var blended_distance = euclidean_distance * weight + manhattan_distance * (1 - weight) / 2
			
			if blended_distance <= radius_tiles:
				measuring_tiles.append(map.convert_to_global_pos(Vector2(x, y)))

# Calculate the tiles for the cone tool
# Args: origin: Vector2, direction: Vector2, length_feet: float
# Returns: None
func calculate_cone_tiles(origin: Vector2, direction: Vector2, length_feet: float, type: String) -> void:
	measuring_tiles.clear()
	
	var origin_tile = map.convert_to_tilemap_pos(origin)
	measuring_tiles.append(map.convert_to_global_pos(origin_tile))
	
	var length_tiles = length_feet / 5.0  # Convert feet to tiles
	
	var angle = atan2(direction.y, direction.x)
	
	if angle < 0:
		angle += 2 * PI
	
	var is_diagonal = false
	
	for card_angle in [0, PI/2, PI, 3*PI/2]:
		if abs(angle - card_angle) < 0.3 or abs(angle - card_angle) > 2*PI - 0.3:
			is_diagonal = false
			break
	
	for diag_angle in [PI/4, 3*PI/4, 5*PI/4, 7*PI/4]:
		if abs(angle - diag_angle) < 0.3:
			is_diagonal = true
			break
	
	if type == "Default":
		if is_diagonal:
			calculate_non_round_diagonal_cone(origin_tile, direction, length_tiles)
		else:
			calculate_non_round_cardinal_cone(origin_tile, direction, length_tiles)
	else:
		if is_diagonal:
			calculate_diagonal_cone(origin_tile, direction, length_tiles)
		else:  # Cardinal or other direction
			calculate_cardinal_cone(origin_tile, direction, length_tiles)

# Calculate the tiles for the diagonal cone
# Args: origin: Vector2, direction: Vector2, length: float
# Returns: None
func calculate_diagonal_cone(origin: Vector2, direction: Vector2, length: float) -> void:
	var dir_x = 1 if direction.x >= 0 else -1
	var dir_y = 1 if direction.y >= 0 else -1
	
	var origin_global = map.convert_to_global_pos(origin)
	measuring_tiles.append(origin_global)
	
	var max_distance = ceil(length)
	
	for y in range(0, max_distance + 1):
		var max_x = max_distance - y
		
		var curve_adjustment = 0
		
		if y > 0 and y < max_distance:
			var normalized_y = float(y) / max_distance
			
			var curve_factor = 1.0 - 4.0 * pow(normalized_y - 0.5, 2)
			
			curve_adjustment = int(max_x * 0.2 * curve_factor)
		
		var adjusted_max_x = max_x + curve_adjustment
		
		for x in range(0, adjusted_max_x + 1):
			var pos = Vector2(origin.x + x * dir_x, origin.y + y * dir_y)
			
			if map.is_inside_tilemap(pos):
				measuring_tiles.append(map.convert_to_global_pos(pos))
	
	for x in range(0, max_distance + 1):
		var max_y = max_distance - x
		
		var curve_adjustment = 0
		
		if x > 0 and x < max_distance:
			var normalized_x = float(x) / max_distance
			
			var curve_factor = 1.0 - 4.0 * pow(normalized_x - 0.5, 2)
			
			curve_adjustment = int(max_y * 0.2 * curve_factor)
		
		var adjusted_max_y = max_y + curve_adjustment
		
		for y in range(0, adjusted_max_y + 1):
			var pos = Vector2(origin.x + x * dir_x, origin.y + y * dir_y)
			
			if map.is_inside_tilemap(pos):
				measuring_tiles.append(map.convert_to_global_pos(pos))
	
	var unique_tiles = []
	for tile in measuring_tiles:
		if not unique_tiles.has(tile):
			unique_tiles.append(tile)
	
	measuring_tiles = unique_tiles

# Calculate the tiles for the cardinal cone
# Args: origin: Vector2, direction: Vector2, length: float
# Returns: None
func calculate_cardinal_cone(origin: Vector2, direction: Vector2, length: float) -> void:
	var primary_dir
	var secondary_dir
	
	if abs(direction.x) > abs(direction.y):
		primary_dir = Vector2(sign(direction.x), 0)
		secondary_dir = Vector2(0, 1)  # Width expands vertically
	else:
		primary_dir = Vector2(0, sign(direction.y))
		secondary_dir = Vector2(1, 0)  # Width expands horizontally
	
	var origin_global = map.convert_to_global_pos(origin)
	measuring_tiles.append(origin_global)
	
	var max_distance = ceil(length)
	
	if max_distance >= 1:
		var first_pos = origin + primary_dir
		var first_side1 = first_pos + secondary_dir
		var first_side2 = first_pos - secondary_dir
		
		if map.is_inside_tilemap(first_pos):
			measuring_tiles.append(map.convert_to_global_pos(first_pos))
		
		if map.is_inside_tilemap(first_side1):
			measuring_tiles.append(map.convert_to_global_pos(first_side1))
			
		if map.is_inside_tilemap(first_side2):
			measuring_tiles.append(map.convert_to_global_pos(first_side2))
	
	var width_ratio = 16.0 / 12.0  # Approximately 1.33
	var max_width = ceil(length * width_ratio)
	
	if int(max_width) % 2 != 0:
		max_width += 1
	
	for dist in range(2, max_distance + 1):
		var current_pos = origin + primary_dir * dist
		
		var normalized_dist = float(dist) / max_distance
		var width = 0
		
		if normalized_dist <= 0.7:  # Expansion phase (0-70% of length)
			width = max_width * (normalized_dist / 0.7)
		else:  # Contraction phase (70-100% of length)
			var contraction_factor = (normalized_dist - 0.7) / 0.3  # How far into contraction phase
			width = max_width * (1 - contraction_factor)
		
		width = max(2, floor(width))
		if int(width) % 2 != 0:
			width -= 1
		
		var half_width = int(width) / 2
		
		if map.is_inside_tilemap(current_pos):
			measuring_tiles.append(map.convert_to_global_pos(current_pos))
		
		for w in range(1, half_width + 1):  # Start from 1 to avoid duplicating center
			var left_pos = current_pos + secondary_dir * w
			var right_pos = current_pos - secondary_dir * w
			
			if map.is_inside_tilemap(left_pos):
				measuring_tiles.append(map.convert_to_global_pos(left_pos))
			
			if map.is_inside_tilemap(right_pos):
				measuring_tiles.append(map.convert_to_global_pos(right_pos))

# Cardinal cone function that produces a typical 90° cone shape
func calculate_non_round_cardinal_cone(origin: Vector2, direction: Vector2, length: float) -> void:
	# Determine the primary direction
	var primary_dir
	var secondary_dir
	
	if abs(direction.x) > abs(direction.y):
		# Horizontal primary
		primary_dir = Vector2(sign(direction.x), 0)
		secondary_dir = Vector2(0, 1)  # Width expands vertically
	else:
		# Vertical primary
		primary_dir = Vector2(0, sign(direction.y))
		secondary_dir = Vector2(1, 0)  # Width expands horizontally
	
	# Add origin tile first
	var origin_global = map.convert_to_global_pos(origin)
	measuring_tiles.append(origin_global)
	
	var max_distance = ceil(length)
	
	# Calculate the angle of the cone (90 degrees, or PI/2 radians)
	var cone_angle_rad = PI / 2
	
	# For each distance from the origin
	for dist in range(1, max_distance + 1):
		var current_pos = origin + primary_dir * dist
		
		# Calculate width at this distance (tan(angle/2) * distance * 2)
		# For a 90° cone, width = distance * 2
		var width = dist * 2
		
		# Add the center tile
		if map.is_inside_tilemap(current_pos):
			measuring_tiles.append(map.convert_to_global_pos(current_pos))
		
		# Add tiles to the left and right of center
		for w in range(1, dist + 1):
			var left_pos = current_pos + secondary_dir * w
			var right_pos = current_pos - secondary_dir * w
			
			if map.is_inside_tilemap(left_pos):
				measuring_tiles.append(map.convert_to_global_pos(left_pos))
			
			if map.is_inside_tilemap(right_pos):
				measuring_tiles.append(map.convert_to_global_pos(right_pos))

func calculate_non_round_diagonal_cone(origin: Vector2, direction: Vector2, length: float) -> void:
	# Determine the primary directions
	var dir_x = 1 if direction.x >= 0 else -1
	var dir_y = 1 if direction.y >= 0 else -1
	
	# Add origin tile first
	var origin_global = map.convert_to_global_pos(origin)
	measuring_tiles.append(origin_global)
	
	var max_distance = ceil(length)
	
	# For diagonal cones, we measure using a diamond pattern
	# This creates a 90° spread from the diagonal line
	for dist in range(1, max_distance + 1):
		# Check all tiles at Manhattan distance = dist
		for step in range(0, dist + 1):
			var x_offset = step
			var y_offset = dist - step
			
			# The main diagonal line
			var pos = Vector2(origin.x + x_offset * dir_x, origin.y + y_offset * dir_y)
			if map.is_inside_tilemap(pos):
				measuring_tiles.append(map.convert_to_global_pos(pos))
			
			# Calculate the perpendicular spread at this point
			# For each step along the main diagonal, we spread perpendicular to it
			var max_spread = min(x_offset, y_offset)
			
			for spread in range(1, max_spread + 1):
				# Spread in both perpendicular directions
				var pos1 = Vector2(origin.x + (x_offset + spread) * dir_x, origin.y + (y_offset - spread) * dir_y)
				var pos2 = Vector2(origin.x + (x_offset - spread) * dir_x, origin.y + (y_offset + spread) * dir_y)
				
				if map.is_inside_tilemap(pos1):
					measuring_tiles.append(map.convert_to_global_pos(pos1))
				
				if map.is_inside_tilemap(pos2):
					measuring_tiles.append(map.convert_to_global_pos(pos2))
	
	# Remove duplicates
	var unique_tiles = []
	for tile in measuring_tiles:
		if not unique_tiles.has(tile):
			unique_tiles.append(tile)
	
	measuring_tiles = unique_tiles