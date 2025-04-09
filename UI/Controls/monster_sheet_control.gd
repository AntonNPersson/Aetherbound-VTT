extends Control
@onready var monster_attributes: Control = $MainContainer/Attributes
@onready var monster_information: Control = $MainContainer/Information
@onready var monster_traits: Control = $MainContainer/Traits
@onready var monster_immunities: Control = $MainContainer/Immunities
@onready var monster_weaknesses: Control = $MainContainer/Weaknesses
@onready var monster_resistances: Control = $MainContainer/Resistances
@onready var monster_languages: Control = $MainContainer/Languages

# --- Cache specific controls ---
@onready var monster_name_control: Label = $MainContainer/Information/NameContainer/Value 
@onready var monster_size_control: Label = $MainContainer/Information/SizeContainer/Value
@onready var monster_level_control: Label = $MainContainer/Information/LevelContainer/Value
@onready var monster_gender_control: Label = $MainContainer/Information/GenderContainer/Value
@onready var monster_ac_control: Label = $MainContainer/Information/ACContainer/Value
@onready var monster_hp_control: Label = $MainContainer/Information/HPContainer/Value
@onready var monster_perception_control: Label = $MainContainer/Information/PerceptionContainer/Value
@onready var monster_base_speed_control: Label = $MainContainer/Extras/Speed/ScrollContainer/VBoxContainer/Base
@onready var monster_fly_speed_control: Label = $MainContainer/Extras/Speed/ScrollContainer/VBoxContainer/Fly
@onready var monster_swim_speed_control: Label = $MainContainer/Extras/Speed/ScrollContainer/VBoxContainer/Swim
@onready var monster_climb_speed_control: Label = $MainContainer/Extras/Speed/ScrollContainer/VBoxContainer/Climb
@onready var monster_burrow_speed_control: Label = $MainContainer/Extras/Speed/ScrollContainer/VBoxContainer/Burrow

@onready var monster_might_control: Label = $MainContainer/Attributes/AttributesContainer/MightFrame/Value 
@onready var monster_agility_control: Label = $MainContainer/Attributes/AttributesContainer/AgilityFrame/Value
@onready var monster_endurance_control: Label = $MainContainer/Attributes/AttributesContainer/EnduranceFrame/Value
@onready var monster_cognition_control: Label = $MainContainer/Attributes/AttributesContainer/CognitionFrame/Value
@onready var monster_insight_control: Label = $MainContainer/Attributes/AttributesContainer/InsightFrame/Value
@onready var monster_charisma_control: Label = $MainContainer/Attributes/AttributesContainer/CharismaFrame/Value

# --- Store monster data ---
var monster_id: String
var monster_sheet: Resource
var dice: DiceManager

func _ready() -> void:
	Bus.set_pause_busy(true)
	dice = DiceManager.new()

func _process(delta: float) -> void:
	var panel_global_rect = get_child(0).get_global_rect()
	var mouse_pos = get_viewport().get_mouse_position()
	if panel_global_rect.has_point(mouse_pos):
		Bus.pause_map_input.emit(true)
	else:
		Bus.pause_map_input.emit(false)

	if Input.is_action_just_pressed("ui_cancel"):
		Bus.pause_map_input.emit(false)
		Bus.set_pause_busy(false)
		queue_free()

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
	monster_ac_control.text = _get_value("get_unit_base_armor_class")
	monster_hp_control.text = _get_value("get_unit_max_hit_points") + "(" + _get_value("get_unit_temporary_hit_points") + ")"
	monster_perception_control.text = _get_value("get_unit_perception_modifier")

	monster_might_control.text = _get_value("get_unit_might_modifier") + "(" + _get_value("get_unit_might_saving_throw") + ")"
	monster_agility_control.text = _get_value("get_unit_agility_modifier") + "(" + _get_value("get_unit_agility_saving_throw") + ")"
	monster_endurance_control.text = _get_value("get_unit_endurance_modifier") + "(" + _get_value("get_unit_endurance_saving_throw") + ")"
	monster_cognition_control.text = _get_value("get_unit_intelligence_modifier") + "(" + _get_value("get_unit_intelligence_saving_throw") + ")"
	monster_insight_control.text = _get_value("get_unit_insight_modifier") + "(" + _get_value("get_unit_insight_saving_throw") + ")"
	monster_charisma_control.text = _get_value("get_unit_charisma_modifier") + "(" + _get_value("get_unit_charisma_saving_throw") + ")"

func _open_changer_panel(variable: String) -> void:
	if !Net.is_host():
		return

	ensure_single_instance("ChangePanel")

	var panel = load("res://UI/Instances/sheet_changer_panel.tscn").instantiate()
	panel.get_child(0).container_name = variable
	add_child(panel)
	panel.add_to_group("ChangePanel")

	match variable:
		"Name": panel.callable = func(name): _set_variable.rpc("set_unit_name", name, monster_id)
		"Size": panel.callable = func(size): _set_variable.rpc("set_unit_size_by_name", size, monster_id)
		"Level": panel.callable = func(level): _set_variable.rpc("set_unit_level", level, monster_id)
		"Gender": panel.callable = func(gender): _set_variable.rpc("set_unit_gender", gender, monster_id)
		"AC": panel.callable = func(ac): _set_variable.rpc("set_unit_base_armor_class", ac, monster_id)
		"HP": panel.callable = func(hp): _set_variable.rpc("set_unit_max_hit_points", hp, monster_id)
		"Perception": panel.callable = func(perception): _set_variable.rpc("set_unit_perception_modifier", perception, monster_id)
		"TempHP": panel.callable = func(hp): _set_variable.rpc("set_unit_temporary_hit_points", hp, monster_id)
		"Might": panel.callable = func(might): _set_variable.rpc("set_unit_might_modifier", might, monster_id)
		"MightSaving": panel.callable = func(might): _set_variable.rpc("set_unit_might_saving_throw", might, monster_id)
		"Agility": panel.callable = func(agility): _set_variable.rpc("set_unit_agility_modifier", agility, monster_id)
		"AgilitySaving": panel.callable = func(agility): _set_variable.rpc("set_unit_agility_saving_throw", agility, monster_id)
		"Endurance": panel.callable = func(endurance): _set_variable.rpc("set_unit_endurance_modifier", endurance, monster_id)
		"EnduranceSaving": panel.callable = func(endurance): _set_variable.rpc("set_unit_endurance_saving_throw", endurance, monster_id)
		"Cognition": panel.callable = func(cognition): _set_variable.rpc("set_unit_intelligence_modifier", cognition, monster_id)
		"CognitionSaving": panel.callable = func(cognition): _set_variable.rpc("set_unit_intelligence_saving_throw", cognition, monster_id)
		"Insight": panel.callable = func(insight): _set_variable.rpc("set_unit_insight_modifier", insight, monster_id)
		"InsightSaving": panel.callable = func(insight): _set_variable.rpc("set_unit_insight_saving_throw", insight, monster_id)
		"Charisma": panel.callable = func(charisma): _set_variable.rpc("set_unit_charisma_modifier", charisma, monster_id)
		"CharismaSaving": panel.callable = func(charisma): _set_variable.rpc("set_unit_charisma_saving_throw", charisma, monster_id)

	panel._initialize()

func _open_roll_dice(type: String):
	if !Net.is_host():
		return

	WindowFactory.create_choice_panel(self, "Modifier", "Saving",
		_roll_dice.bind("Modifier", "get_unit_" + type + "_modifier", type),
		_roll_dice.bind("Saving Throw", "get_unit_" + type + "_saving_throw", type))

@rpc("authority", "call_local", "reliable")
func _set_variable(method_name: String, value: String, id: String) -> void:
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		_use_method(method_name, value)
		_update_monster_panel()
	else:
		var monster = _get_monster_instance(id)
		if monster:
			_use_method(method_name, value)

func _roll_dice(type: String, modifier_name: String, attribute_name: String) -> void:
	var value = _get_value(modifier_name)
	var additional_info = "Check" if type == "Modifier" else "Saving Throw"
	var roll = dice.standard_roll(int(value))
	Bus.send_roll_to_all.emit(monster_sheet.get_unit_name(), "rolls a", attribute_name.capitalize() + " " + additional_info, roll, "", "")

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
			if extra == "HP":
				WindowFactory.create_choice_panel(self, "Normal", "Temporary", _open_changer_panel.bind("HP"), _open_changer_panel.bind("TempHP"))
				return
			elif extra == "Might":
				WindowFactory.create_choice_panel(self, "Modifier", "Saving", _open_changer_panel.bind("Might"), _open_changer_panel.bind("MightSaving"))
				return
			elif extra == "Agility":
				WindowFactory.create_choice_panel(self, "Modifier", "Saving", _open_changer_panel.bind("Agility"), _open_changer_panel.bind("AgilitySaving"))
				return
			elif extra == "Endurance":
				WindowFactory.create_choice_panel(self, "Modifier", "Saving", _open_changer_panel.bind("Endurance"), _open_changer_panel.bind("EnduranceSaving"))
				return
			elif extra == "Cognition":
				WindowFactory.create_choice_panel(self, "Modifier", "Saving", _open_changer_panel.bind("Cognition"), _open_changer_panel.bind("CognitionSaving"))
				return
			elif extra == "Insight":
				WindowFactory.create_choice_panel(self, "Modifier", "Saving", _open_changer_panel.bind("Insight"), _open_changer_panel.bind("InsightSaving"))
				return
			elif extra == "Charisma":
				WindowFactory.create_choice_panel(self, "Modifier", "Saving", _open_changer_panel.bind("Charisma"), _open_changer_panel.bind("CharismaSaving"))
				return
			else:
				_open_changer_panel(extra)

func ensure_single_instance(type: String) -> void:
	if get_tree().get_nodes_in_group(type).size() > 0:
		for panel in get_tree().get_nodes_in_group(type):
			if panel.is_inside_tree():
				panel.queue_free()	

func _exit_tree() -> void:
	Bus.pause_map_input.emit(false)
	Bus.set_pause_busy(false)
	
