extends Control

# --- @onready Variables (UI Node References) ---
@onready var character_attributes = %Attributes
@onready var character_information = %Information
@onready var left_bar = %LeftSideBar
@onready var statistics = %Statistics
@onready var skills = %Skills
@onready var inventory = %Inventory
@onready var formulas = %Formulas
@onready var perception = %Perception

# -- Cache specific controls --
@onready var character_name_control = character_information.get_node("NameContainer").get_node("Value")
@onready var character_level_control = character_information.get_node("LevelContainer").get_node("Value")
@onready var character_species_control = character_information.get_node("SpeciesContainer").get_node("Value")
@onready var character_archetype_control = character_information.get_node("ArchetypeContainer").get_node("Value")
@onready var character_height_control = character_information.get_node("HeightContainer").get_node("Value")
@onready var character_weight_control = character_information.get_node("WeightContainer").get_node("Value")
@onready var character_age_control = character_information.get_node("AgeContainer").get_node("Value")

@onready var character_might_control = character_attributes.get_node("Attributes Container").get_node("Might Frame").get_node("Value")
@onready var character_agility_control = character_attributes.get_node("Attributes Container").get_node("Agility Frame").get_node("Value")
@onready var character_intellect_control = character_attributes.get_node("Attributes Container").get_node("Cognition Frame").get_node("Value")
@onready var character_insight_control = character_attributes.get_node("Attributes Container").get_node("Insight Frame").get_node("Value")
@onready var character_endurance_control = character_attributes.get_node("Attributes Container").get_node("Endurance Frame").get_node("Value")
@onready var character_charisma_control = character_attributes.get_node("Attributes Container").get_node("Charisma Frame").get_node("Value")
@onready var character_perception_control = perception.get_node("PerceptionContainer").get_node("Value")
@onready var character_class_dc_control = perception.get_node("DCContainer").get_node("Value")

@onready var character_might_button = character_attributes.get_node("Attributes Container").get_node("Might Frame").get_node("Might")
@onready var character_agility_button = character_attributes.get_node("Attributes Container").get_node("Agility Frame").get_node("Agility")
@onready var character_intellect_button = character_attributes.get_node("Attributes Container").get_node("Cognition Frame").get_node("Cognition")
@onready var character_insight_button = character_attributes.get_node("Attributes Container").get_node("Insight Frame").get_node("Insight")
@onready var character_endurance_button = character_attributes.get_node("Attributes Container").get_node("Endurance Frame").get_node("Endurance")
@onready var character_charisma_button = character_attributes.get_node("Attributes Container").get_node("Charisma Frame").get_node("Charisma")
@onready var character_perception_button = perception.get_node("Perception")

@onready var character_traits_control = left_bar.get_node("Traits").get_node("ScrollContainer").get_node("VBoxContainer")
@onready var character_tenets_control = left_bar.get_node("Tenets").get_node("ScrollContainer").get_node("VBoxContainer")
@onready var character_taboos_control = left_bar.get_node("Taboos").get_node("ScrollContainer").get_node("VBoxContainer")
@onready var character_languages_control = left_bar.get_node("Languages").get_node("ScrollContainer").get_node("VBoxContainer")

@onready var character_statistics_list = statistics.get_node("Statistics").get_node("Container")
@onready var character_skills_and_proficiencies_list = skills.get_node("Skills").get_node("Container")
@onready var character_inventory_and_perks_list = inventory.get_node("Inventory").get_node("Container")
@onready var character_formulas_and_spellbook_list = formulas.get_node("Formulas").get_node("Container")

var character_id: String = ""
var character_sheet: CharacterSheet = null
var dice: DiceManager = null

var _potential_single_click_label: Label = null
var _potential_single_click_data = null

# --- Godot Virtual Methods ---
func _ready() -> void:
	dice = DiceManager.new()

func _process(delta: float) -> void:
	if !visible: 
		global_position = Vector2(-9999999, -9999999)
	else:
		Bus.set_pause_busy(true)

# --- Public Interface ---
func _initialize_character_panel(p_character_sheet: CharacterSheet, p_character_id: String) -> void:
	character_sheet = p_character_sheet
	character_id = p_character_id

	if !is_instance_valid(character_sheet):
		printerr("Error: Character sheet is not valid.")
		return

	_update_character_panel()

# --- Core Update & UI Logic ---
func _update_character_panel() -> void:
	if not is_instance_valid(character_sheet):
		printerr("Error: Character sheet is not valid.")
		return

	var allow_hiding = !Settings.gameplay_settings["show_empty_values_on_character_sheet"]

	# --- Set Authority ---
	if multiplayer.get_unique_id() != character_id.to_int():
		character_might_button.disabled = true
		character_agility_button.disabled = true
		character_intellect_button.disabled = true
		character_insight_button.disabled = true
		character_endurance_button.disabled = true
		character_charisma_button.disabled = true
		character_perception_button.disabled = true

	# --- Update Character Information ---
	character_name_control.text = _get_value("get_unit_name")
	character_level_control.text = _get_value("get_unit_level")
	character_species_control.text = _get_value("get_unit_species_name")
	character_archetype_control.text = _get_value("get_unit_class_name")
	character_height_control.text = _get_value("get_unit_height") + " ft"
	character_weight_control.text = _get_value("get_unit_weight") + " lbs"
	character_age_control.text = _get_value("get_unit_age") + " years"

	# --- Update Character Attributes ---
	character_might_control.text = _get_value("get_unit_might_modifier", true) + " (" + _get_value("get_unit_might_saving_throw") + ")"
	character_agility_control.text = _get_value("get_unit_agility_modifier", true) + " (" + _get_value("get_unit_agility_saving_throw") + ")"
	character_intellect_control.text = _get_value("get_unit_intelligence_modifier", true) + " (" + _get_value("get_unit_intelligence_saving_throw") + ")"
	character_insight_control.text = _get_value("get_unit_insight_modifier", true) + " (" + _get_value("get_unit_insight_saving_throw") + ")"
	character_endurance_control.text = _get_value("get_unit_endurance_modifier", true) + " (" + _get_value("get_unit_endurance_saving_throw") + ")"
	character_charisma_control.text = _get_value("get_unit_charisma_modifier", true) + " (" + _get_value("get_unit_charisma_saving_throw") + ")"
	character_perception_control.text = _get_value("get_unit_perception_modifier", true)

	# --- Update Character Traits ---
	update_container(character_traits_control, character_sheet.get_unit_traits(), [], true, true, true) # Clickable resources
	update_container(character_tenets_control, )

func update_container(container: Control, data: Array, prefix: Array = [], is_resource: bool = true, connect_signal: bool = true, is_clickable: bool = false, allow_hiding: bool = false) -> void:
	clear_container(container)
	var is_prefix_empty = prefix.is_empty()
	var prefix_index = 0

	if not is_prefix_empty and data.size() != prefix.size():
		printerr("Data and prefix arrays must be of the same size for container: ", container.name)
		return

	for item_data in data:
		var label = Label.new()
		var display_text = ""
		var meta_data_for_click = item_data # Default meta is the item itself (e.g., Resource)

		# Determine display text and potential meta override
		if is_prefix_empty:
			if is_resource and item_data is Resource and item_data.has_method("get_resource_name"):
				display_text = item_data.get_resource_name().capitalize()
			else:
				# Convert numbers nicely, handle potential nulls
				if typeof(item_data) == TYPE_FLOAT: item_data = int(item_data)
				display_text = str(item_data).capitalize() if item_data != null else "N/A"
		else:
			var current_prefix = prefix[prefix_index]
			# For lists with prefixes (Skills, Senses, Speed), the clickable item is the prefix string
			meta_data_for_click = current_prefix

			# Skip display if hiding and value is zero/invalid
			if allow_hiding:
				var skip = false
				if typeof(item_data) == TYPE_INT or typeof(item_data) == TYPE_FLOAT:
					if item_data <= 0: skip = true
				elif typeof(item_data) == TYPE_STRING:
					if item_data.is_empty() or item_data == "0": skip = true # Handle zero strings too?
				elif item_data == null:
					skip = true

				if skip:
					prefix_index += 1
					label.queue_free() # Don't keep the unused label
					continue # Skip adding this item

			# Format display text: "Prefix: Value"
			var value_text = ""
			if is_resource and item_data is Resource and item_data.has_method("get_resource_name"):
				value_text = item_data.get_resource_name().capitalize()
			else:
				if typeof(item_data) == TYPE_FLOAT: item_data = int(item_data)
				value_text = str(item_data).capitalize() if item_data != null else "N/A"

			# Use helper for complex prefix formatting if needed, otherwise simple capitalization
			var formatted_prefix = Helper.separate_string_with_regex(current_prefix)[0].capitalize() if Helper else current_prefix.capitalize()
			display_text = formatted_prefix + ": " + value_text

		label.text = display_text
		label.set_meta("item_data", meta_data_for_click) # Store data needed for click/hover

		# Standard label setup
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.mouse_filter = Control.MOUSE_FILTER_STOP

		# Connect signals if requested
		if connect_signal:
			label.gui_input.connect(_on_label_gui_input.bind(label))

		if is_clickable:
			# Connect hover signals using the same meta data
			label.mouse_entered.connect(_on_label_mouse_entered.bind(label, meta_data_for_click))
			label.mouse_exited.connect(_on_label_mouse_exited.bind(label, meta_data_for_click))

		container.add_child(label)
		if not is_prefix_empty:
			prefix_index += 1

func _on_label_gui_input(event: InputEvent, label: Label) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		var item_data = label.get_meta("item_data") # Retrieve the stored data

		if item_data == null: return # Should not happen if meta is set correctly

		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_handle_single_click(label, item_data) # Handle inspect / roll / edit

		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed and Net.is_host():
			# Create context menu (GM only)
			if get_tree().get_nodes_in_group("Panels").size() > 0: return # Avoid overlap

			var context = context_panel.new() # Assumes context_panel is available globally or preloaded
			get_tree().get_root().get_node("Root/GameUI").add_child(context) # Adjust path if needed
			context.create_panel(get_viewport().get_mouse_position(), Vector2.ZERO)

			# Populate context menu based on item_data type
			if item_data is TraitResource:
				context.add_button("Inspect", WindowFactory.create_resource_inspector.bind(item_data.get_dictionary()))

func _on_button_gui_input(event: InputEvent, extra: String): # extra comes from signal connection
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed and multiplayer.get_unique_id() == character_id.to_int():
			if get_tree().get_nodes_in_group("Panels").size() > 0: return # Avoid overlap

			var context = context_panel.new()
			get_tree().get_root().get_node("Root/GameUI").add_child(context)
			context.create_panel(get_viewport().get_mouse_position(), Vector2.ZERO)

			# Add roll options based on the 'extra' string identifier
			if extra == "Perception":
				context.add_button("Roll", _roll_dice.bind("Modifier", "get_unit_perception_modifier", "Perception"))
				context.add_button("Roll DC", _roll_dice.bind("DC", "get_unit_perception_modifier", "Perception", int(_get_value("get_unit_perception_modifier")) + 10))
				context.add_button("Custom Roll", _custom_roll.bind("Modifier", "get_unit_perception_modifier", "Perception", int(_get_value("get_unit_perception_modifier"))))
			else: # Assumes Attributes (Might, Agility, etc.)
				var lower_extra = extra.to_lower()
				context.add_button("Roll Check", _roll_dice.bind("Modifier", "get_unit_" + lower_extra + "_modifier", extra))
				context.add_button("Roll Saving", _roll_dice.bind("Saving Throw", "get_unit_" + lower_extra + "_saving_throw", extra))
				context.add_button("Add Modifier", _custom_roll.bind("Modifier", "get_unit_" + lower_extra + "_modifier", extra, int(_get_value("get_unit_" + lower_extra + "_modifier"))))
				context.add_button("Add Saving", _custom_roll.bind("Saving Throw", "get_unit_" + lower_extra + "_saving_throw", extra, int(_get_value("get_unit_" + lower_extra + "_saving_throw"))))
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and multiplayer.get_unique_id() == character_id.to_int():
			_roll_dice("Modifier", "get_unit_" + extra.to_lower() + "_modifier", extra) # Default to rolling the modifier


func _handle_single_click(_label_node: Label, data):
	Audio._on_button_pressed() # Play sound

	if data is Resource:
		print("Resource clicked: ", data.get_resource_name() if data.has_method("get_resource_name") else data.resource_path)
		WindowFactory.create_resource_inspector(data.get_dictionary())

func _on_label_mouse_entered(label: Label, data):
	label.add_theme_color_override("font_color", Color(0.812, 0.608, 0.463, 1))
	Audio._on_button_hover()
	# Start hover timer logic
	# _hover_timer.start() # Only uncomment if _handle_hover has actual logic
	_potential_single_click_label = label
	_potential_single_click_data = data

# Called when the mouse exits a label in a list container
func _on_label_mouse_exited(label: Label, _data):
	label.remove_theme_color_override("font_color")
	# Clear hover tracking if the mouse exited the label we were tracking
	if _potential_single_click_label == label:
		_potential_single_click_label = null
		_potential_single_click_data = null

# --- Helpers ---
# Performs a standard dice roll using a modifier from the sheet
func _roll_dice(type: String, modifier_name: String, attribute_name: String, direct_value: int = 0) -> void:
	var value_str = _get_value(modifier_name) if direct_value == 0 else str(direct_value)
	var modifier = 0
	if value_str.is_valid_int():
		modifier = int(value_str)
	else:
		printerr("Invalid modifier '%s' for %s roll." % [value_str, attribute_name])
		return # Don't roll if modifier is invalid

	var additional_info = "Check" if type == "Modifier" else "Saving Throw"
	if type == "DC": additional_info = "DC"

	var roll = dice.standard_roll(modifier) # Assumes DiceManager handles the d20 + modifier
	Bus.send_roll_to_all.emit(character_sheet.get_unit_name(), "rolls a", attribute_name.capitalize() + " " + additional_info, roll, "", "")

func _custom_roll(type: String, modifier_name: String, attribute_name: String, direct_value: int = 0) -> void:
	ensure_single_instance("ChangePanel") # Reuse changer panel for input

	var panel = load("res://UI/Instances/sheet_changer_panel.tscn").instantiate()
	add_child(panel)
	# panel.get_child(0).container_name = "Roll Modifier" # Set title if supported
	panel.add_to_group("ChangePanel")

	var base_modifier = direct_value # Use the provided base value

	panel.callable = func(added_value):
		var modifier_to_add = 0
		if str(added_value).is_valid_int():
			modifier_to_add = int(added_value)
		else:
			printerr("Invalid integer input for custom roll modifier: ", added_value)

		var final_modifier = base_modifier + modifier_to_add
		var roll = dice.standard_roll(final_modifier)
		var additional_info = "Check" if type == "Modifier" else "Saving Throw"
		if type == "DC": additional_info = "DC"

		Bus.send_roll_to_all.emit(character_sheet.get_unit_name(), "rolls a", attribute_name.capitalize() + " " + additional_info, roll, "", "")

	if panel.has_method("_initialize"):
		panel._initialize()

func _get_value(method_name: String, add_plus: bool = false) -> String:
	if is_instance_valid(character_sheet) and character_sheet.has_method(method_name):
		var value = character_sheet.call(method_name)

		# Format numbers, adding '+' sign if requested and positive
		if value is float or value is int:
			if add_plus and value >= 0: # Only add plus if value is non-negative
				return "+" + str(value)
			else:
				return str(value)
		elif value == null:
			return "" # Represent null as empty string for display
		else:
			return str(value) # Convert other types (like bool, string) to string
	else:
		# printerr("MonsterSheet does not have method: ", method_name) # Reduce log spam
		return "N/A" # Return placeholder if method doesn't exist

# Removes all children from a container node
func clear_container(container: Control) -> void:
	if not is_instance_valid(container): return
	var children = container.get_children()
	for child in children:
		container.remove_child(child)
		child.queue_free()

# Ensures only one instance of a node type (identified by group) exists as a child of this panel
func ensure_single_instance(type: String) -> void: # type is group name
	# This searches the *entire scene tree* for the group, not just children of this node.
	# If panels should only be children here, adjust the search logic.
	if get_tree().get_nodes_in_group(type).size() > 0:
		for panel in get_tree().get_nodes_in_group(type):
			# Check if it's actually a child of this specific sheet panel before removing?
			# Or assume any panel in this group globally should be removed?
			# Current logic removes any node in the group anywhere in the tree.
			if is_instance_valid(panel) and panel.is_inside_tree():
				panel.queue_free()
