extends Node
const SAFETY_MESSAGE_SCENE = preload("res://UI/Instances/safety_message.tscn")
const CHOICE_PANEL_SCENE = preload("res://UI/Instances/choice_control.tscn")

func create_safety_message(parent_node: Node, msg: String = "", safety_callable: Callable = func(): queue_free()) -> void:
	ensure_single_instance("SafetyMessage")
	# Store the data
	if !safety_callable and !safety_callable.is_valid():
		safety_callable = func(): queue_free() # Ensure a default valid callable

	# Add self to the passed parent *BEFORE* accessing children or positioning
	var message_instance = SAFETY_MESSAGE_SCENE.instantiate()
	message_instance.setup(msg, safety_callable)
	parent_node.add_child(message_instance)
	message_instance.add_to_group("SafetyMessage")

func create_choice_panel(parent_node: Node, first_option_name: String, second_option_name: String, first_option_callable: Callable, second_option_callable: Callable) -> void:
	ensure_single_instance("ChoicePanel")
	# Store the data
	if !first_option_callable and !first_option_callable.is_valid():
		first_option_callable = func(): queue_free() # Ensure a default valid callable
	if !second_option_callable and !second_option_callable.is_valid():
		second_option_callable = func(): queue_free() # Ensure a default valid callable

	# Add self to the passed parent *BEFORE* accessing children or positioning
	var choice_instance = CHOICE_PANEL_SCENE.instantiate()
	choice_instance.setup(first_option_name, second_option_name, first_option_callable, second_option_callable)
	parent_node.add_child(choice_instance)
	choice_instance.add_to_group("ChoicePanel")

func ensure_single_instance(type: String) -> void:
	if get_tree().get_nodes_in_group(type).size() > 0:
		for panel in get_tree().get_nodes_in_group(type):
			if panel.is_inside_tree():
				panel.queue_free()	
