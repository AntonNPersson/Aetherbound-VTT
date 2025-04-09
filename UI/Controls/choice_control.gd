extends Control
var first_option_name: String = ""
var second_option_name: String = ""

var first_option_callable: Callable
var second_option_callable: Callable

func setup(first_name: String, second_name: String, first_callable: Callable, second_callable: Callable) -> void:
	first_option_name = first_name
	second_option_name = second_name
	first_option_callable = first_callable
	second_option_callable = second_callable
	get_child(0).grab_focus()
	%First.pressed.connect(_on_first_pressed)
	%Second.pressed.connect(_on_second_pressed)
	%First.text = first_option_name
	%Second.text = second_option_name

	call_deferred("reposition")

func _on_first_pressed() -> void:
	if first_option_callable:
		first_option_callable.call()
	queue_free()

func _on_second_pressed() -> void:
	if second_option_callable:
		second_option_callable.call()
	queue_free()

func reposition():
	# Use is_instance_valid for a more robust check
	var vp = get_viewport()
	if is_instance_valid(vp):
		var viewport_size : Vector2 = vp.get_visible_rect().size
		var control_size : Vector2 = get_child(0).size # Get the size of this Control node

		# Important check: Ensure the control has a valid size.
		# If size is (0,0), centering calculation won't work and might indicate
		# the control hasn't finished its layout process.
		if control_size.x <= 0 or control_size.y <= 0:
			printerr("SafetyMessage: Control size (", control_size, ") is invalid during reposition. Check layout/timing.")
			# You might want to try repositioning again later if size is zero
			# call_deferred("reposition")
			return

		# Calculate the top-left global position to center the control
		global_position = (viewport_size - control_size) / 2.0

		# print("SafetyMessage: Repositioned to center: ", global_position) # Optional: uncomment for debugging
	else:
		printerr("SafetyMessage: Could not get viewport for positioning.")
