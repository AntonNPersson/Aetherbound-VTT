extends Node
const SAFETY_MESSAGE_SCENE = preload("res://UI/Instances/safety_message.tscn")

func create_safety_message(parent_node: Node, msg: String = "", safety_callable: Callable = func(): queue_free()) -> void:
	# Store the data
	if !safety_callable and !safety_callable.is_valid():
		safety_callable = func(): queue_free() # Ensure a default valid callable

	# Add self to the passed parent *BEFORE* accessing children or positioning
	var message_instance = SAFETY_MESSAGE_SCENE.instantiate()
	message_instance.setup(msg, safety_callable)
	parent_node.add_child(message_instance)
