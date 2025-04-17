extends Node
const SAFETY_MESSAGE_SCENE = preload("res://UI/Instances/safety_message.tscn")
const CHOICE_PANEL_SCENE = preload("res://UI/Instances/choice_control.tscn")
const MULTIPLE_CHOICE_SCENE = preload("res://UI/Instances/multiple_choice_control.tscn")
const MONSTER_SHEET_SCENE = preload("res://UI/Instances/monster sheet.tscn")
const RESOURCE_INSPECTOR_SCENE = preload("res://UI/Instances/resource_inspector.tscn")

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

func create_multiple_choice_panel(parent_node: Node, names: Array, callables: Array) -> void:
	ensure_single_instance("MultipleChoicePanel")
	# Store the data
	if names.size() != callables.size():
		ErrorUtility.log_error("SafetyMessage: Names and callables array sizes do not match.")
		return

	for i in range(names.size()):
		if !callables[i] and !callables[i].is_valid():
			callables[i] = func(): queue_free() # Ensure a default valid callable

	# Add self to the passed parent *BEFORE* accessing children or positioning
	var multiple_choice_instance = MULTIPLE_CHOICE_SCENE.instantiate()
	multiple_choice_instance.setup(names, callables)
	parent_node.add_child(multiple_choice_instance)
	multiple_choice_instance.add_to_group("MultipleChoicePanel")

func create_monster_sheet(character_sheet: Resource, name: String) -> void:
	if get_tree().get_root().get_node("Root").get_node("GameUI").get_node("CharacterSheet").visible:
		get_tree().get_root().get_node("Root").get_node("GameUI").get_node("CharacterSheet").visible = false

	var monster_sheet_instance = get_tree().get_root().get_node("Root").get_node("GameUI").get_node("Sheet")
	monster_sheet_instance._initialize_monster_panel(character_sheet, name)
	monster_sheet_instance.show()
	monster_sheet_instance.global_position = get_viewport().size/2 + Vector2i(-monster_sheet_instance.get_child(0).size.x/2, -monster_sheet_instance.get_child(0).size.y/2)
	monster_sheet_instance.add_to_group("MonsterSheet")
	Bus.pause_map_input.emit(true)
	Bus.set_pause_busy(true)

func create_character_sheet(character_sheet: Resource, name: String, non_instance: bool = false) -> void:
	if get_tree().get_root().get_node("Root").get_node("GameUI").get_node("Sheet").visible:
		get_tree().get_root().get_node("Root").get_node("GameUI").get_node("Sheet").visible = false

	var character_sheet_instance = get_tree().get_root().get_node("Root").get_node("GameUI").get_node("CharacterSheet")
	character_sheet_instance._initialize_character_panel(character_sheet, name)
	character_sheet_instance.show()
	character_sheet_instance.global_position = get_viewport().size/2 + Vector2i(-character_sheet_instance.get_child(0).size.x/2, -character_sheet_instance.get_child(0).size.y/2)
	character_sheet_instance.add_to_group("CharacterSheet")
	Bus.pause_map_input.emit(true)
	Bus.set_pause_busy(true)

func create_resource_inspector(variables: Dictionary) -> void:
	ensure_single_instance("ResourceInspector")
	var resource_inspector_instance = RESOURCE_INSPECTOR_SCENE.instantiate()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(resource_inspector_instance)
	resource_inspector_instance._initialize(variables)
	resource_inspector_instance.global_position = get_viewport().size/2 + Vector2i(-resource_inspector_instance.get_child(0).size.x/2, -resource_inspector_instance.get_child(0).size.y)
	resource_inspector_instance.add_to_group("ResourceInspector")

func ensure_single_instance(type: String) -> void:
	if get_tree().get_nodes_in_group(type).size() > 0:
		for panel in get_tree().get_nodes_in_group(type):
			if panel.is_inside_tree():
				panel.queue_free()	
