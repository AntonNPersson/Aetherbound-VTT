extends CanvasLayer
const DAMAGE_NUMBER_DURATION = 0.6
const DAMAGE_NUMBER_MOVE_AMOUNT = Vector2(0, -40)
const DAMAGE_NUMBER_FADE_DELAY = 0.1

const ANNOUNCEMENT_DEFAULT_DISPLAY_DURATION: float = 1.5
const ANNOUNCEMENT_DEFAULT_FADE_DURATION: float = 0.75
const ANNOUNCEMENT_BASE_FONT_SIZE_MODIFIER: float = 1.0

func _ready() -> void:
	Bus.send_combat_value.connect(func(value, pos, color): create_combat_value.rpc(value, pos, color))
	Bus.send_announcement.connect(func(text, color): create_screen_announcement.rpc(text, color))
	Bus.send_announcement_to_player.connect(func(player_id, text, color): create_screen_announcement.rpc_id(player_id, text, color))
	Bus.create_combat_tracker.connect(func(id, all, owned): create_combat_tracker.rpc_id(id, all, owned))
	Bus.delete_combat_tracker.connect(func(): delete_combat_tracker.rpc())

# --- Combat Value Creation Function ---
@rpc("any_peer", "call_local", "reliable")
func create_combat_value(damage_value: Variant, world_position: Vector2, color: Color) -> void:
	# --- Convert using the corrected function ---
	var damage_number := Label.new()
	damage_number.text = str(damage_value)
	damage_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# --- Set font size based on resolution ---
	var resolution = Settings.window_settings["resolution"]
	var base_font_size = 30  # Base font size for 1080p
	var font_size = base_font_size
	
	# Scale font based on resolution format (assuming resolution is Vector2 or string)
	if resolution is Vector2:
		# Scale based on height (y component)
		font_size = int((resolution.y / 1080.0) * base_font_size)
	elif resolution is String and "x" in resolution:
		# Parse string format like "1920x1080"
		var res_parts = resolution.split("x")
		if res_parts.size() == 2:
			var height = int(res_parts[1])
			font_size = int((height / 1080.0) * base_font_size)
	
	# Ensure font size is reasonable (not too small or too large)
	font_size = clamp(font_size, 12, 32)
	
	# Apply font size
	damage_number.add_theme_font_size_override("font_size", font_size)
	damage_number.add_theme_constant_override("outline_size", int(font_size / 8))  # Scale outline too
	damage_number.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	
	# --- Continue with your existing code ---
	damage_number.custom_minimum_size = Vector2(font_size * 3, font_size * 2)  # Scale minimum size with font
	damage_number.reset_size()
	
	damage_number.modulate = color
	damage_number.modulate.a = 1.0
	
	damage_number.global_position = world_position - damage_number.size / 2
	
	damage_number.add_to_group("DamageNumbers")
	get_parent().add_child(damage_number)
	
	# --- Animate with Tween ---
	var tween = create_tween().set_parallel(true)
	
	# Move upward
	tween.tween_property(damage_number, "global_position", 
		world_position + DAMAGE_NUMBER_MOVE_AMOUNT, DAMAGE_NUMBER_DURATION)\
		.set_ease(Tween.EASE_OUT)
	
	# Fade out
	tween.tween_property(damage_number, "modulate", 
		Color(color.r, color.g, color.b, 0.0), DAMAGE_NUMBER_DURATION - DAMAGE_NUMBER_FADE_DELAY)\
		.set_delay(DAMAGE_NUMBER_FADE_DELAY)\
		.set_ease(Tween.EASE_IN)
	
	# Queue free when done
	await tween.finished
	damage_number.queue_free()

## Creates large text centered on the screen that fades out.
## announcement_text: The text to display.
## color: The color of the text.
## display_duration: How long the text stays fully visible before fading.
## fade_duration: How long the fade-out animation takes.
## base_font_size_scale: Multiplier for the base font size (compared to combat text).
@rpc("any_peer", "call_local", "reliable")
func create_screen_announcement(
	announcement_text: String,
	color: Color,
	display_duration: float = ANNOUNCEMENT_DEFAULT_DISPLAY_DURATION,
	fade_duration: float = ANNOUNCEMENT_DEFAULT_FADE_DURATION,
	base_font_size_scale: float = ANNOUNCEMENT_BASE_FONT_SIZE_MODIFIER
) -> void:
	print("Creating screen announcement:", announcement_text, "with color:", color)
	# --- Create the Label ---
	var announcement_label := Label.new()
	announcement_label.text = str(announcement_text) # Ensure it's a string
	announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER # Center vertically too

	# --- Set LARGE font size based on resolution ---
	# Use the same base calculation as combat text, but scaled up significantly
	var resolution = Settings.window_settings["resolution"]
	var combat_base_font_size = 30 # Base size used in your original function
	var base_font_size = int(combat_base_font_size * base_font_size_scale) # Apply scale factor
	var font_size = base_font_size

	# Scale font based on resolution format (same logic as before)
	if resolution is Vector2:
		font_size = int((resolution.y / 1080.0) * base_font_size)
	elif resolution is String and "x" in resolution:
		var res_parts = resolution.split("x")
		if res_parts.size() == 2:
			var height = int(res_parts[1])
			font_size = int((height / 1080.0) * base_font_size)

	# --- Adjust clamping for LARGE text ---
	# Make min/max significantly larger than combat text
	font_size = clamp(font_size, 40, 150) # Adjust min/max as needed for announcement size

	# Apply font size and outline
	announcement_label.add_theme_font_size_override("font_size", font_size)
	# Optional: Make outline thicker for bigger text
	var outline_size = clamp(int(font_size / 8.0), 2, 10) # Ensure minimum thickness
	announcement_label.add_theme_constant_override("outline_size", outline_size)
	announcement_label.add_theme_color_override("font_outline_color", Color.BLACK) # Black outline usually works well

	# --- Set Color ---
	# Start fully opaque
	announcement_label.modulate = color
	announcement_label.modulate.a = 1.0

	add_child(announcement_label)

	# --- Position in Screen Center ---
	# Wait a frame for the node to be added and size calculated based on font/text
	await get_tree().process_frame

	var viewport_rect = get_viewport().get_visible_rect()
	var screen_center = viewport_rect.size / 2.0
	# Set position so the label's center aligns with the screen's center
	announcement_label.position = screen_center - announcement_label.size / 2.0
	announcement_label.position.y = screen_center.y - announcement_label.size.y

	# --- Animate with Tween ---
	var tween = create_tween()

	# No movement tween needed

	# Fade out after display_duration
	tween.tween_property(announcement_label, "modulate:a", 0.0, fade_duration)\
		.set_delay(display_duration)\
		.set_ease(Tween.EASE_IN) # Fade in ease usually looks good for disappearing

	# Queue free when done
	await tween.finished
	if is_instance_valid(announcement_label): # Good practice to check if node still exists
		announcement_label.queue_free()

@rpc("any_peer", "call_local", "reliable")
func create_combat_tracker(combatants: Array, owned_combatants: Array) -> void:
	print("Creating combat tracker with combatants:", combatants, "and owned combatants:", owned_combatants)
	var tracker = load("res://UI/Instances/combat_panel.tscn").instantiate()
	tracker._initialize(_get_combantant_instances(combatants), _get_combantant_instances(owned_combatants))
	tracker.global_position = get_viewport().get_visible_rect().size / 2 - tracker.size / 2
	add_child(tracker)

@rpc("any_peer", "call_local", "reliable")
func delete_combat_tracker() -> void:
	var tracker = get_node("CombatPanel")
	if tracker != null:
		tracker.queue_free()
	# Remove the tracker from the parent node
	remove_child(tracker)

func _get_combantant_instances(combatants: Array) -> Array:
	var instances = []
	for combatant in combatants:
		for t in get_tree().get_nodes_in_group("token"):
			if combatant == t.name:
				instances.append(t)
	return instances
