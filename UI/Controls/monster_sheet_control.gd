extends Control
@onready var monster_attributes: Control = $MainContainer/Attributes
@onready var monster_information: Control = $MainContainer/Information
@onready var monster_traits: Control = $MainContainer/Traits
@onready var monster_immunities: Control = $MainContainer/Immunities
@onready var monster_weaknesses: Control = $MainContainer/Weaknesses
@onready var monster_resistances: Control = $MainContainer/Resistances
@onready var monster_languages: Control = $MainContainer/Languages

# --- Cache specific controls ---
@onready var monster_name_control: Label = $MainContainer/Information/Name/ScrollContainer/Value 
@onready var monster_size_control: Label = $MainContainer/Information/Size/ScrollContainer/Value
@onready var monster_level_control: Label = $MainContainer/Information/Level/ScrollContainer/Value
@onready var monster_gender_control: Label = $MainContainer/Information/Gender/ScrollContainer/Value

@onready var monster_might_control: Label = $MainContainer/Attributes/AttributesContainer/MightFrame/Value 
@onready var monster_agility_control: Label = $MainContainer/Attributes/AttributesContainer/AgilityFrame/Value
@onready var monster_endurance_control: Label = $MainContainer/Attributes/AttributesContainer/EnduranceFrame/Value
@onready var monster_cognition_control: Label = $MainContainer/Attributes/AttributesContainer/CognitionFrame/Value
@onready var monster_insight_control: Label = $MainContainer/Attributes/AttributesContainer/InsightFrame/Value
@onready var monster_charisma_control: Label = $MainContainer/Attributes/AttributesContainer/CharismaFrame/Value

# --- Store monster data ---
var monster_id: String
var monster_sheet: Resource

func _process(delta: float) -> void:
	var panel_global_rect = get_child(0).get_global_rect()
	var mouse_pos = get_viewport().get_mouse_position()
	if panel_global_rect.has_point(mouse_pos):
		Bus.pause_map_input.emit(true)
	else:
		Bus.pause_map_input.emit(false)

func _initialize_monster_panel(p_monster_sheet: Resource, p_monster_id: String) -> void:
	# Use p_ prefix for parameters to avoid confusion with member variables
	self.monster_id = p_monster_id
	self.monster_sheet = p_monster_sheet

	# --- Now simply use the cached variables ---
	# Add checks to ensure the sheet has the data and nodes are valid
	if not is_instance_valid(monster_name_control):
		printerr("Monster Name control not found!")
		return # Or handle error

	if monster_sheet:
		_update_monster_panel()
	else:
		printerr("Invalid monster_sheet passed to _initialize_monster_panel")
		# Optionally clear the fields

	_update_monster_panel()

func _update_monster_panel() -> void:
	monster_name_control.text = _get_value("get_unit_name") # Use .get() for safety
	monster_size_control.text = _get_value("get_unit_size_name")
	monster_level_control.text = _get_value("get_unit_level")
	monster_gender_control.text = _get_value("get_unit_gender")

	monster_might_control.text = _get_value("get_unit_might_modifier")
	monster_agility_control.text = _get_value("get_unit_agility_modifier")
	monster_endurance_control.text = _get_value("get_unit_endurance_modifier")
	monster_cognition_control.text = _get_value("get_unit_cognition_modifier")
	monster_insight_control.text = _get_value("get_unit_insight_modifier")
	monster_charisma_control.text = _get_value("get_unit_charisma_modifier")

func _open_changer_panel(variable: String) -> void:
	var panel = load("res://UI/Instances/sheet_changer_panel.tscn").instantiate()
	panel.get_child(0).container_name = variable
	add_child(panel)

	match variable:
		"Name": panel.callable = func(name): _set_variable.rpc("set_unit_name", name, monster_id)
		"Size": panel.callable = func(size): _set_variable.rpc("set_unit_size_by_name", size, monster_id)
		"Level": panel.callable = func(level): _set_variable.rpc("set_unit_level", level, monster_id)
		"Gender": panel.callable = func(gender): _set_variable.rpc("set_unit_gender", gender, monster_id)
		"Might": panel.callable = func(might): _set_variable.rpc("set_unit_might_modifier", might, monster_id)
		"Agility": panel.callable = func(agility): _set_variable.rpc("set_unit_agility_modifier", agility, monster_id)
		"Endurance": panel.callable = func(endurance): _set_variable.rpc("set_unit_endurance_modifier", endurance, monster_id)
		"Cognition": panel.callable = func(cognition): _set_variable.rpc("set_unit_cognition_modifier", cognition, monster_id)
		"Insight": panel.callable = func(insight): _set_variable.rpc("set_unit_insight_modifier", insight, monster_id)
		"Charisma": panel.callable = func(charisma): _set_variable.rpc("set_unit_charisma_modifier", charisma, monster_id)

	panel._initialize()

@rpc("authority", "call_local", "reliable")
func _set_variable(method_name: String, value: String, id: String) -> void:
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		_use_method(method_name, value)
		_update_monster_panel()
	else:
		var monster = _get_monster_instance(id)
		if monster:
			_use_method(method_name, value)

func _get_monster_instance(id: String) -> Node:
	for token in get_tree().get_nodes_in_group("token"):
		if token.name == id:
			return token
	return null

func _use_method(method_name: String, value: String) -> void:
	if monster_sheet.has_method(method_name):
		monster_sheet.call(method_name, value)
	else:
		print("MonsterSheet does not have method: ", method_name)

func _get_value(method_name: String) -> String:
	if monster_sheet.has_method(method_name):
		return str(monster_sheet.call(method_name))
	else:
		print("MonsterSheet does not have method: ", method_name)
		return "N/A"

func _on_input(event: InputEvent, extra: String) -> void:
	if event.is_action_pressed("ui_cancel"):
		queue_free()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and Net.is_host():
			_open_changer_panel(extra)

func _exit_tree() -> void:
	Bus.pause_map_input.emit(false)
	
