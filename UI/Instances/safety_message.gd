class_name SafetyMessage extends Control

var message: String
var callable_method: Callable

const SAFETY_MESSAGE_SCENE = preload("res://UI/Instances/safety_message.tscn")

func setup(msg: String = "", safety_callable: Callable = func(): queue_free()):
	# Store the data
	message = msg
	if safety_callable and safety_callable.is_valid():
		callable_method = safety_callable
	else:
		callable_method = func(): queue_free() # Ensure a default valid callable

func _ready():
	# Now that it's in the tree, children are accessible
	if not is_node_ready():
		await ready # Ensure node and children are ready

	%Text.text = message # Or use find_child("Text") if not using unique names
	var accept_button = find_child("Accept", true, false) # Assuming %Accept works
	var decline_button = find_child("Decline", true, false) # Assuming %Decline works

	if accept_button:
		accept_button.pressed.connect(callable_method)
	else:
		printerr("SafetyMessage: Accept button not found!")

	if decline_button:
		decline_button.pressed.connect(queue_free)
	else:
		printerr("SafetyMessage: Decline button not found!")

	# Position after being added and children are ready (size is calculated)
	# Using call_deferred ensures layout calculations might have happened
	call_deferred("reposition")

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
