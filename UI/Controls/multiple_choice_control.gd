extends Control

func setup(names: Array, callables: Array) -> void:
	if names.size() != callables.size():
		ErrorUtility.log_error("SafetyMessage: Names and callables array sizes do not match.")
		return

	for i in range(names.size()):
		var button = Button.new()
		button.text = names[i]
		button.pressed.connect(_on_callable_pressed.bind(callables[i]))
		get_child(0).get_node("Container").add_child(button)
	call_deferred("reposition")

func _on_callable_pressed(callable: Callable) -> void:
	if callable:
		callable.call()
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
