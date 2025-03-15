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
var line_ruler: Control = null
var circle_ruler: Control = null
var rectangle_ruler: Control = null
var arc_ruler: Control = null
var camera: Node = null
var text_input: Label = null

# Helper variables
var is_initialized: bool = false
var currently_measuring: bool = false
var measuring_tiles: Array = []
var modern_measuring_tiles: Array = []
var total_measured_distance: float = 0
var current_measured_distance: float = 0
var emanation_center: Vector2 = Vector2.ZERO
var burst_center: Vector2 = Vector2.ZERO
var cone_origin: Vector2 = Vector2.ZERO
var cone_direction: Vector2 = Vector2.ZERO
var circle_radius: float = 0
var arc_direction: float = 0
var arc_length: float = 0
var arc_angle: float = 90

# Extra
var cone_type = "Round"

var is_measuring: Dictionary = {
	"distance": false,
	"emanation": false,
	"burst": false,
	"cone": false,
	"line": false,
	"circle": false,
	"rectangle": false,
	"arc": false
}

var keep: Dictionary = {
	"distance": false,
	"emanation": false,
	"burst": false,
	"cone": false,
	"line": false,
	"circle": false,
	"rectangle": false,
	"arc": false
}

var button_map: Dictionary = {
}

var tooltip: Dictionary = {
	"distance": "Measure the distance between two tiles, additional settings by right clicking anywhere on the map.",
	"emanation": "Measure the distance of an emanation in tiles, additional settings by right clicking anywhere on the map.",
	"burst": "Measure the distance of a burst in tiles, additional settings by right clicking anywhere on the map.",
	"cone": "Measure the distance of a cone in tiles, additional settings by right clicking anywhere on the map.",
	"line": "Measure the distance from one point to another, irrelevant of tiles, additional settings by right clicking anywhere on the map.",
	"circle": "Measure the distance of a circle, irrelevant of tiles, additional settings by right clicking anywhere on the map.",
	"rectangle": "Measure the distance of a rectangle, irrelevant of tiles, additional settings by right clicking anywhere on the map.",
	"arc": "Measure the distance of a cone, irrelevant of tiles, additional settings by right clicking anywhere on the map."
}
# ===================== CORE FUNCTIONS =====================

# Called when the ui is initialize in the scenemanager
func _initialize():
	distance_ruler = get_child(0).get_node("Distance")
	distance_ruler.toggled.connect(_toggle_distance_ruler)
	emanation_ruler = get_child(0).get_node("Emanation")
	emanation_ruler.toggled.connect(_toggle_emanation_tool)
	burst_ruler = get_child(0).get_node("Burst")
	burst_ruler.toggled.connect(_toggle_burst_tool)
	cone_ruler = get_child(0).get_node("Cone")
	cone_ruler.toggled.connect(_toggle_cone_tool)
	line_ruler = get_child(0).get_node("Line")
	line_ruler.toggled.connect(_toggle_line_tool)
	circle_ruler = get_child(0).get_node("Circle")
	circle_ruler.toggled.connect(_toggle_circle_tool)
	rectangle_ruler = get_child(0).get_node("Rectangle")
	rectangle_ruler.toggled.connect(_toggle_rectangle_tool)
	arc_ruler = get_child(0).get_node("Arc")
	arc_ruler.toggled.connect(_toggle_arc_tool)

	camera = get_tree().get_nodes_in_group("camera")[0]
	text_input = Label.new()
	text_input.hide()
	add_child(text_input)
	is_initialized = true

	button_map = {
		"distance": distance_ruler,
		"emanation": emanation_ruler,
		"burst": burst_ruler,
		"cone": cone_ruler,
		"line": line_ruler,
		"circle": circle_ruler,
		"rectangle": rectangle_ruler,
		"arc": arc_ruler
	}

	for key in button_map.keys():
		button_map[key].tooltip_text = tooltip[key]

func _draw():
	if is_measuring["line"] and currently_measuring:
		draw_line(modern_measuring_tiles[0], get_global_mouse_position(), Color(1, 1, 1, 0.3), 2)
	elif is_measuring["circle"] and currently_measuring:
		draw_arc(modern_measuring_tiles[0], circle_radius, 0, TAU, 32, Color(1, 1, 1, 0.3), 2)
	elif is_measuring["rectangle"] and currently_measuring:
		var center = modern_measuring_tiles[0]
		var current = get_global_mouse_position()
		var offset_x = abs(current.x - center.x)
		var offset_y = abs(current.y - center.y)
		var rect_pos = Vector2(center.x - offset_x, center.y - offset_y)
		var rect_size = Vector2(offset_x * 2, offset_y * 2)
		draw_rect(Rect2(rect_pos, rect_size), Color(1, 1, 1, 0.3), false, 2)
	elif is_measuring["arc"] and currently_measuring:
		_draw_cone(modern_measuring_tiles[0], arc_angle, arc_direction, arc_length)

func _process(delta):
	# Only process if the ui is initialized
	if is_initialized:
		# If the player is measuring distance, to show feet in the ui and draw the path
		if _check_if_measuring("distance"):
			_set_text(str(map.get_distance_to(measuring_tiles[0], map.get_mouse_position(), true)))

		elif _check_if_measuring("emanation"):
			var current_pos = map.get_mouse_position()
			var tile_distance = map.get_distance_to(emanation_center, current_pos)

			_update_advanced_draw(_calculate_emanation_tiles.bind(emanation_center, tile_distance), str(tile_distance))

		elif _check_if_measuring("burst"):
			var current_pos = map.get_mouse_position()
			var tile_distance = map.get_distance_to(burst_center, current_pos)

			_update_advanced_draw(_calculate_burst_tiles.bind(burst_center, tile_distance), str(tile_distance))

		elif _check_if_measuring("cone"):
			var current_pos = map.get_mouse_position()
			var length = map.get_distance_to(cone_origin, current_pos)

			cone_direction = (current_pos - cone_origin).normalized()
			_update_advanced_draw(_calculate_cone_tiles.bind(cone_origin, cone_direction, length, cone_type), str(length))

		elif _check_if_measuring("line"):
			_set_text(str(_calculate_distance_from_points(measuring_tiles[0], map.get_mouse_position())))
			queue_redraw()

		elif _check_if_measuring("circle"):
			_set_text(str(abs(max(0,_calculate_distance_from_points(measuring_tiles[0], map.get_mouse_position()) - 2))))
			circle_radius = modern_measuring_tiles[0].distance_to(get_global_mouse_position())
			queue_redraw()

		elif _check_if_measuring("rectangle"):
			_set_text(str(abs(max(0,_calculate_distance_from_points(measuring_tiles[0], map.get_mouse_position()) - 2))))
			queue_redraw()

		elif _check_if_measuring("arc"):
			_set_text(str(abs(max(0,_calculate_distance_from_points(measuring_tiles[0], map.get_mouse_position()) - 2))))
			var current_pos = get_global_mouse_position()
			var direction = (current_pos - modern_measuring_tiles[0])
			arc_length = direction.length()
			arc_direction = direction.angle()
			queue_redraw()
		else:
			text_input.hide()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# If the player is measuring distance, add the start tile to the measuring array
			if is_measuring["distance"] and map.is_global_inside_tilemap(map.get_mouse_position()):
				# If modern approach chosen append local canvas position
				# Start measuring, setting the start tile and the flag
				_start_measuring(map.get_mouse_position())

			elif is_measuring["emanation"] and map.is_global_inside_tilemap(map.get_mouse_position()):
				emanation_center = map.get_mouse_position()
				# Start measuring, setting the start tile and the flag
				_start_measuring(emanation_center)

			elif is_measuring["burst"] and map.is_global_inside_tilemap(map.get_mouse_position()):
				burst_center = map.get_mouse_position()
				# Start measuring, setting the start tile and the flag
				_start_measuring(burst_center)

			elif is_measuring["cone"] and map.is_global_inside_tilemap(map.get_mouse_position()):
				cone_origin = map.get_mouse_position()
				# Start measuring, setting the start tile and the flag
				_start_measuring(cone_origin)

			elif is_measuring["line"] and map.is_global_inside_tilemap(map.get_mouse_position()):
				modern_measuring_tiles.append(get_global_mouse_position())
				_start_measuring(map.get_mouse_position())

			elif is_measuring["circle"] and map.is_global_inside_tilemap(map.get_mouse_position()):
				modern_measuring_tiles.append(get_global_mouse_position())
				circle_radius = 0
				_start_measuring(map.get_mouse_position())

			elif is_measuring["rectangle"] and map.is_global_inside_tilemap(map.get_mouse_position()):
				modern_measuring_tiles.append(get_global_mouse_position())
				_start_measuring(map.get_mouse_position())

			elif is_measuring["arc"] and map.is_global_inside_tilemap(map.get_mouse_position()):
				# Start measuring, setting the start tile and the flag
				modern_measuring_tiles.append(get_global_mouse_position())
				var direction = (get_global_mouse_position() - modern_measuring_tiles[0]).normalized()
				arc_length = direction.length()
				arc_direction = direction.angle()
				_start_measuring(map.get_mouse_position())

		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			# If the player is measuring distance, add the end tile to the measuring array, and draw the entire path
			if _check_if_measuring("distance"):
				measuring_tiles.append(map.get_mouse_position())
				# If the player doesnt want to keep the path, clear the path
				if !keep["distance"]:
					_clear_draw()
				# Stop measuring, clearing the measuring array and the flag
				_stop_measuring()

			elif _check_if_measuring("emanation"):
				var final_pos = map.get_mouse_position()
				var final_radius = map.get_distance_to(emanation_center, final_pos)
				_stop_advanced_draw("emanation", _calculate_emanation_tiles.bind(emanation_center, final_radius))

			elif _check_if_measuring("burst"):
				var final_pos = map.get_mouse_position()
				var final_radius = map.get_distance_to(burst_center, final_pos)
				_stop_advanced_draw("burst", _calculate_burst_tiles.bind(burst_center, final_radius))

			elif _check_if_measuring("cone"):
				var final_pos = map.get_mouse_position()
				var final_length = map.get_distance_to(cone_origin, final_pos)
				var final_direction = (final_pos - cone_origin).normalized()
				_stop_advanced_draw("cone", _calculate_cone_tiles.bind(cone_origin, final_direction, final_length, cone_type))
			elif _check_if_measuring("line"):
				modern_measuring_tiles.append(get_global_mouse_position())
				if !keep["line"]:
					_clear_draw()

				_stop_measuring()
			elif _check_if_measuring("circle"):
				modern_measuring_tiles.append(get_global_mouse_position())
				if !keep["circle"]:
					_clear_draw()

				_stop_measuring()

			elif _check_if_measuring("rectangle"):
				modern_measuring_tiles.append(get_global_mouse_position())
				if !keep["rectangle"]:
					_clear_draw()

				_stop_measuring()

			elif _check_if_measuring("arc"):
				modern_measuring_tiles.append(get_global_mouse_position())
				if !keep["arc"]:
					_clear_draw()

				_stop_measuring()

		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Find which tool is active
			var active_tool = ""
			for tool_name in is_measuring.keys():
				if is_measuring[tool_name]:
					active_tool = tool_name
					break
			
			if active_tool != "":
				var context = _create_base_context_menu()
				
				# Add Keep/Loose option for all tools
				if keep[active_tool]:
					context.add_button("Loose", func(): 
						keep[active_tool] = false
						total_measured_distance = 0
					)
				else:
					context.add_button("Keep", func(): 
						keep[active_tool] = true
						total_measured_distance = 0
					)
				
				# Add special options for specific tools
				if active_tool == "cone":
					if cone_type == "Round":
						context.add_button("Default", func(): 
							cone_type = "Default"
							total_measured_distance = 0
						)
					else:
						context.add_button("Round", func(): 
							cone_type = "Round"
							total_measured_distance = 0
						)
				elif active_tool == "arc":
					if arc_angle == 90:
						context.add_button("45", func(): 
							arc_angle = 45
							total_measured_distance = 0
						)
					elif arc_angle == 45:
						context.add_button("120", func(): 
							arc_angle = 120
							total_measured_distance = 0
						)
					else:
						context.add_button("90", func(): 
							arc_angle = 90
							total_measured_distance = 0
						)

# ===================== TOGGLE FUNCTIONS =====================
# Toggle the rulers, when you press the button
# Args: is_toggled: bool
# Returns: None
func _toggle_distance_ruler(is_toggled: bool) -> void:
	_toggle_button("distance", is_toggled)

func _toggle_emanation_tool(is_toggled: bool) -> void:
	_toggle_button("emanation", is_toggled)

func _toggle_burst_tool(is_toggled: bool) -> void:
	_toggle_button("burst", is_toggled)

func _toggle_cone_tool(is_toggled: bool) -> void:
	_toggle_button("cone", is_toggled)

func _toggle_line_tool(is_toggled: bool) -> void:
	print("line")
	_toggle_button("line", is_toggled)

func _toggle_circle_tool(is_toggled: bool) -> void:
	print("circle")
	_toggle_button("circle", is_toggled)

func _toggle_rectangle_tool(is_toggled: bool) -> void:
	_toggle_button("rectangle", is_toggled)

func _toggle_arc_tool(is_toggled: bool) -> void:
	_toggle_button("arc", is_toggled)

func _create_base_context_menu() -> context_panel:
	var context = context_panel.new()
	add_child(context)
	context.create_panel(get_viewport().get_mouse_position(), Vector2(0,0))
	return context

# ===================== HELPER FUNCTIONS =====================

# Option 1: Block signals temporarily
func _toggle_button(type: String, state: bool) -> void:
	for key in button_map.keys():
		button_map[key].set_block_signals(true)
		if key != type:
			button_map[key].button_pressed = false
		else:
			button_map[key].button_pressed = state
		button_map[key].set_block_signals(false)
	
	for key in is_measuring.keys():
		if key != type:
			is_measuring[key] = false
		else:
			is_measuring[key] = state
			
	_setup_drawing(state)

func _setup_drawing(state: bool) -> void:
	map.is_drawing = state
	map.pause_tilemap_input = state
	camera.is_movement_enabled = !state
	measuring_tiles.clear()
	map.distance_path.clear()

# Calculate the tiles for the emanation tool
# Args: center: Vector2, radius_feet: float
# Returns: None
func _check_if_measuring(type: String) -> bool:
	return is_measuring[type] and map.is_global_inside_tilemap(map.get_mouse_position()) and currently_measuring

func _update_advanced_draw(calculation: Callable, input: String) -> void:
	_set_distance_path(measuring_tiles, calculation)
	_clear_draw()
	_set_text(input)

func _stop_advanced_draw(type: String, calculation: Callable) -> void:
	_set_distance_path(measuring_tiles, calculation)
	if !keep[type]:
		_clear_draw()
	_stop_measuring()
	print(map.distance_path)


func _set_distance_path(path: Array, calculations: Callable) -> void:
	calculations.call()
	map.distance_path = path

func _set_text(input: String) -> void:
	text_input.text = str(input.to_float() + total_measured_distance)  + " Feet"
	text_input.global_position = get_global_mouse_position() - Vector2(0, 20)
	text_input.show()
	for key in is_measuring.keys():
		if is_measuring[key]:
			if keep[key]:
				current_measured_distance = input.to_float()

func _clear_draw() -> void:
	queue_redraw()
	map.queue_redraw()

func _stop_measuring() -> void:
	measuring_tiles.clear()
	modern_measuring_tiles.clear()
	map.distance_path.clear()
	currently_measuring = false
	total_measured_distance += current_measured_distance

func _start_measuring(start: Vector2) -> void:
	current_measured_distance = 0
	measuring_tiles.append(start)
	currently_measuring = true

func _draw_cone(center: Vector2, angle: float, direction: float, length: float):
	var half_angle = deg_to_rad(angle) / 2
	var start_angle = direction - half_angle
	var end_angle = direction + half_angle

	var start_point = center + Vector2(cos(start_angle), sin(start_angle)) * length
	var end_point = center + Vector2(cos(end_angle), sin(end_angle)) * length

	print(start_point, end_point)
	print("center: ", center)

	draw_line(center, start_point, Color(1, 1, 1, 0.3), 2)
	draw_line(center, end_point, Color(1, 1, 1, 0.3), 2)

	draw_arc(center, length, start_angle, end_angle, int(max(12, half_angle * 2 * 20)), Color(1, 1, 1, 0.3), 2)

func _calculate_distance_from_points(start: Vector2, end: Vector2) -> float:
	return round((start.distance_to(end)/300) * 5)

func _calculate_emanation_tiles(center: Vector2, radius_feet: float) -> void:
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
func _calculate_burst_tiles(center: Vector2, radius_feet: float) -> void:
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
func _calculate_cone_tiles(origin: Vector2, direction: Vector2, length_feet: float, type: String) -> void:
	measuring_tiles.clear()
	map.distance_path.clear()
	
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
			_calculate_non_round_diagonal_cone(origin_tile, direction, length_tiles)
		else:
			_calculate_non_round_cardinal_cone(origin_tile, direction, length_tiles)
	else:
		if is_diagonal:
			_calculate_diagonal_cone(origin_tile, direction, length_tiles)
		else:  # Cardinal or other direction
			_calculate_cardinal_cone(origin_tile, direction, length_tiles)

# Calculate the tiles for the diagonal cone
# Args: origin: Vector2, direction: Vector2, length: float
# Returns: None
func _calculate_diagonal_cone(origin: Vector2, direction: Vector2, length: float) -> void:
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
func _calculate_cardinal_cone(origin: Vector2, direction: Vector2, length: float) -> void:
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
func _calculate_non_round_cardinal_cone(origin: Vector2, direction: Vector2, length: float) -> void:
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
	
	for dist in range(1, max_distance + 1):
		var current_pos = origin + primary_dir * dist
		
		if map.is_inside_tilemap(current_pos):
			measuring_tiles.append(map.convert_to_global_pos(current_pos))
		
		for w in range(1, dist + 1):
			var left_pos = current_pos + secondary_dir * w
			var right_pos = current_pos - secondary_dir * w
			
			if map.is_inside_tilemap(left_pos):
				measuring_tiles.append(map.convert_to_global_pos(left_pos))
			
			if map.is_inside_tilemap(right_pos):
				measuring_tiles.append(map.convert_to_global_pos(right_pos))

func _calculate_non_round_diagonal_cone(origin: Vector2, direction: Vector2, length: float) -> void:
	var dir_x = 1 if direction.x >= 0 else -1
	var dir_y = 1 if direction.y >= 0 else -1
	
	var origin_global = map.convert_to_global_pos(origin)
	measuring_tiles.append(origin_global)
	
	var max_distance = ceil(length)
	
	for dist in range(1, max_distance + 1):
		for step in range(0, dist + 1):
			var x_offset = step
			var y_offset = dist - step
			
			var pos = Vector2(origin.x + x_offset * dir_x, origin.y + y_offset * dir_y)
			if map.is_inside_tilemap(pos):
				measuring_tiles.append(map.convert_to_global_pos(pos))
			
			var max_spread = min(x_offset, y_offset)
			
			for spread in range(1, max_spread + 1):
				var pos1 = Vector2(origin.x + (x_offset + spread) * dir_x, origin.y + (y_offset - spread) * dir_y)
				var pos2 = Vector2(origin.x + (x_offset - spread) * dir_x, origin.y + (y_offset + spread) * dir_y)
				
				if map.is_inside_tilemap(pos1):
					measuring_tiles.append(map.convert_to_global_pos(pos1))
				
				if map.is_inside_tilemap(pos2):
					measuring_tiles.append(map.convert_to_global_pos(pos2))
	
	var unique_tiles = []
	for tile in measuring_tiles:
		if not unique_tiles.has(tile):
			unique_tiles.append(tile)
	
	measuring_tiles = unique_tiles
