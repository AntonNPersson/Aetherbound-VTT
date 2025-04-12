extends Control
@onready var monster_attributes: Control = $MainContainer/Attributes
@onready var monster_information: Control = $MainContainer/Information

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

@onready var monster_traits_control: VBoxContainer = $MainContainer/LeftSideBar/Traits/ScrollContainer/VBoxContainer
@onready var monster_speed_control: VBoxContainer = $MainContainer/Extras/Speed/ScrollContainer/VBoxContainer
@onready var monster_senses_control: VBoxContainer = $MainContainer/Extras/Senses/ScrollContainer/VBoxContainer
@onready var monster_immunities_control: VBoxContainer = $MainContainer/LeftSideBar/Immunities/ScrollContainer/VBoxContainer
@onready var monster_resistances_control: VBoxContainer = $MainContainer/LeftSideBar/Resistances/ScrollContainer/VBoxContainer
@onready var monster_weaknesses_control: VBoxContainer = $MainContainer/LeftSideBar/Weaknesses/ScrollContainer/VBoxContainer
@onready var monster_languages_control: VBoxContainer = $MainContainer/LeftSideBar/Languages/ScrollContainer/VBoxContainer

@onready var monster_skills_control: VBoxContainer = $MainContainer/Skills2/Skills3/ScrollContainer/Skills


var _click_timer: Timer
var _potential_single_click_label: Label = null
var _potential_single_click_data = null

# --- Store monster data ---
var monster_id: String
var monster_sheet: Resource
var monster_non_instance: bool = false
var dice: DiceManager

func _ready() -> void:
	Bus.set_pause_busy(true)
	dice = DiceManager.new()
	_click_timer = Timer.new()
	_click_timer.one_shot = true
	_click_timer.wait_time = 0.4
	_click_timer.timeout.connect(_on_click_timer_timeout)
	add_child(_click_timer)

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

func _initialize_monster_panel(p_monster_sheet: Resource, p_monster_id: String, p_monster_not_instance: bool = false) -> void:
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

	monster_speed_control.get_node("Base").text = "Land: " + _get_value("get_unit_base_speed")
	monster_speed_control.get_node("Fly").text = "Fly: " + _get_value("get_unit_base_fly_speed")
	monster_speed_control.get_node("Swim").text = "Swim: " + _get_value("get_unit_base_swim_speed")
	monster_speed_control.get_node("Climb").text = "Climb: " + _get_value("get_unit_base_climb_speed")
	monster_speed_control.get_node("Burrow").text = "Burrow: " + _get_value("get_unit_base_burrow_speed")

	update_container(monster_traits_control, monster_sheet.get_traits(), [], true, true, true)
	update_container(monster_senses_control, monster_sheet.get_senses().values(), monster_sheet.get_senses().keys(), false)
	update_container(monster_immunities_control, monster_sheet.get_immunities())
	update_container(monster_resistances_control, monster_sheet.get_resistances())
	update_container(monster_weaknesses_control, monster_sheet.get_weaknesses())
	update_container(monster_languages_control, monster_sheet.get_languages(), [], false)
	update_container(monster_skills_control, monster_sheet.get_skills().values(), monster_sheet.get_skills().keys(), false, true, true)

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

	if type == "Perception":
		_roll_dice("Modifier", "get_unit_perception_modifier", "Perception")
		return

	WindowFactory.create_choice_panel(self, "Modifier", "Saving",
		_roll_dice.bind("Modifier", "get_unit_" + type + "_modifier", type),
		_roll_dice.bind("Saving Throw", "get_unit_" + type + "_saving_throw", type))

@rpc("authority", "call_local", "reliable")
func _set_variable(method_name: String, value: Variant, id: String) -> void:
	if multiplayer.get_remote_sender_id() == multiplayer.get_unique_id():
		_use_method(method_name, value)
		_update_monster_panel()
	else:
		if monster_non_instance:
			return

		var monster = _get_monster_instance(id)
		if monster:
			_use_method(method_name, value)

func _roll_dice(type: String, modifier_name: String, attribute_name: String, direct_value: int = 0) -> void:
	var value = _get_value(modifier_name) if direct_value == 0 else str(direct_value)
	var additional_info = "Check" if type == "Modifier" else "Saving Throw"
	var roll = dice.standard_roll(int(value))
	Bus.send_roll_to_all.emit(monster_sheet.get_unit_name(), "rolls a", attribute_name.capitalize() + " " + additional_info, roll, "", "")

func _get_monster_instance(id: String) -> Node:
	for token in get_tree().get_nodes_in_group("token"):
		if token.name == id:
			return token
	return null

func _use_method(method_name: String, value: Variant) -> void:
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

func add_resource(resource: Resource) -> void:
	if resource is TraitResource:
		_set_variable.rpc("add_trait", resource, monster_id)

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


func clear_container(container: Control) -> void:
	var children = container.get_children()
	for child in children:
		container.remove_child(child)
		child.queue_free()

func update_container(container: Control, data: Array, prefix: Array = [], is_resource: bool = true, connect_signal: bool = true, is_clickable: bool = false) -> void:
	clear_container(container)
	var is_prefix_empty = false
	var prefix_index = 0

	if data.size() != prefix.size():
		if prefix.is_empty():
			# If prefix is empty, we can proceed without any issues
			is_prefix_empty = true
			pass
		else:
			# If prefix is not empty, we need to ensure they match
			printerr("Data and prefix arrays must be of the same size")
			return

	for item_data in data:
		var label = Label.new()
		if is_prefix_empty:
			label.text = item_data.get_resource_name().capitalize() if is_resource else str(item_data).capitalize()
		else:
			label.text = prefix[prefix_index].capitalize() + ": " + item_data.get_resource_name().capitalize() if is_resource else prefix[prefix_index].capitalize() + ": " + str(item_data).capitalize()

		# --- Store the actual data with the label ---
		if is_resource:
			label.set_meta("item_data", item_data)
		elif !is_resource and !prefix.is_empty():
			label.set_meta("item_data", prefix[prefix_index])
		# ---------------------------------------------

		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.mouse_filter = Control.MOUSE_FILTER_STOP

		# --- Connect the gui_input signal ---
		if connect_signal:
			label.gui_input.connect(_on_label_gui_input.bind(label))

		if is_clickable:
			label.mouse_entered.connect(_on_label_mouse_entered.bind(label))
			label.mouse_exited.connect(_on_label_mouse_exited.bind(label))
		# -----------------------------------

		container.add_child(label)
		prefix_index += 1

func _handle_single_click(_label_node: Label, data):
	Audio._on_button_pressed()
	if data and data is Resource:
		WindowFactory.create_resource_inspector(data.get_dictionary())
	elif data and data is String:
		print("String data: ", data)
		var resource = Cache.find_loaded_resource_by_name(data)
		if resource:
			WindowFactory.create_choice_panel(self, "Inspect", "Roll",
				func(): WindowFactory.create_resource_inspector(resource.get_dictionary()),
				_roll_dice.bind("Modifier", "", data, monster_sheet.get_skill_modifier(data)))
		else:
			print("Resource not found in cache: ", data)
	print("Single click detected on label: ", data)

func _handle_double_click(_label_node: Label, data):
	if !Net.is_host():
		return
	Audio._on_button_pressed()
	if data and data is TraitResource:
		WindowFactory.create_safety_message(self, "Are you sure you want to remove this trait?", func(): _set_variable.rpc("remove_trait", data, monster_id))
	elif data and data is String:
		var resource = Cache.find_loaded_resource_by_name(data)
		_roll_dice("Modifier", "", data, monster_sheet.get_skill_modifier(data))

func _on_label_gui_input(event: InputEvent, label: Label):
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		# Check for Left Mouse Button Press
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			var item_data = label.get_meta("item_data") # Retrieve the data

			if mouse_event.double_click:
				# --- Double Click Detected ---
				_click_timer.stop() # Cancel any pending single click timeout
				_potential_single_click_label = null # Clear pending click info
				_potential_single_click_data = null
				_handle_double_click(label, item_data)
			else:
				# --- Potential Single Click ---
				# Store info and start timer to wait for a potential double click
				_potential_single_click_label = label
				_potential_single_click_data = item_data
				_click_timer.start()
				# Don't execute single click action yet!

func _on_label_mouse_entered(label: Label):
	label.add_theme_color_override("font_color", Color(0.812, 0.608, 0.463, 1))
	Audio._on_button_hover()

func _on_label_mouse_exited(label: Label):
	label.remove_theme_color_override("font_color")

func _on_click_timer_timeout():
	# Timer finished without a double click being detected
	# Check if the label we were tracking still exists
	if is_instance_valid(_potential_single_click_label):
		_handle_single_click(_potential_single_click_label, _potential_single_click_data) # Call your specific handler

	# Clear pending click info regardless
	_potential_single_click_label = null
	_potential_single_click_data = null

func _exit_tree() -> void:
	Bus.pause_map_input.emit(false)
	Bus.set_pause_busy(false)
	
