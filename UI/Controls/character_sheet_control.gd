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
@onready var character_hit_points_control = perception.get_node("HPContainer").get_node("Value")
@onready var character_armor_class_control = perception.get_node("ACContainer").get_node("Value")

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
@onready var character_skills_button = skills.get_node("HBoxContainer").get_node("Skills")
@onready var character_proficiencies_button = skills.get_node("HBoxContainer").get_node("Proficiencies")
@onready var character_inventory_button = inventory.get_node("HBoxContainer").get_node("Inventory")
@onready var character_perks_button = inventory.get_node("HBoxContainer").get_node("Perks")
@onready var character_formulas_button = formulas.get_node("HBoxContainer").get_node("Formulas")
@onready var character_spellbook_button = formulas.get_node("HBoxContainer").get_node("Spellbook")

@onready var character_skills_and_proficiencies_button_group = skills.get_node("HBoxContainer")
@onready var character_inventory_and_perks_button_group = inventory.get_node("HBoxContainer")
@onready var character_formulas_and_spellbook_button_group = formulas.get_node("HBoxContainer")

var character_id: String = ""
var character_sheet: CharacterSheet = null
var dice: DiceManager = null
var _potential_single_click_label: Label = null
var _potential_single_click_data = null
var _is_changing_panel = false

# --- Godot Virtual Methods ---
func _ready() -> void:
	dice = DiceManager.new()
	# Connect signals for buttons
	_connect_change_panel_signals(character_skills_and_proficiencies_button_group)
	_connect_change_panel_signals(character_inventory_and_perks_button_group)
	_connect_change_panel_signals(character_formulas_and_spellbook_button_group)
	_update_character_panel()

func _process(delta: float) -> void:
	if !visible: 
		global_position = Vector2(-9999999, -9999999)
	else:
		Bus.set_pause_busy(true)
		Bus.deselect_tile.emit()

# --- Public Interface ---
func _initialize_character_panel(p_character_sheet: CharacterSheet, p_character_id: String) -> void:
	character_sheet = p_character_sheet
	character_id = p_character_id

	if !is_instance_valid(character_sheet):
		printerr("Error: Character sheet is not valid.")
		return

	_update_character_panel()
	_change_panel(false, "Skills") # Default to Skills panel
	_change_panel(false, "Inventory") # Default to Inventory panel
	_change_panel(false, "Spellbook") # Default to Formulas panel

# --- Core Update & UI Logic ---
func _update_character_panel() -> void:
	if not is_instance_valid(character_sheet):
		printerr("Error: Character sheet is not valid.")
		return

	var allow_hiding = !Settings.gameplay_settings["show_empty_values_on_character_sheet"]
	character_sheet.recalculate_derived_stats()

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
	character_species_control.text = _get_value("get_unit_lineage_name")
	character_archetype_control.text = _get_value("get_unit_class_name")
	character_height_control.text = str(snapped(float(_get_value("get_unit_height")), 0.1)) + " ft"
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
	character_hit_points_control.text = _get_value("get_unit_current_hit_points") + "/" + _get_value("get_unit_max_hit_points") + " (" + _get_value("get_unit_max_temporary_hit_points") + ")"
	character_armor_class_control.text = _get_value("get_unit_base_armor_class") + " (" + _get_value("get_unit_shield_hardness") + ")"

	# --- Update Character Traits ---
	update_container(character_traits_control, character_sheet.get_unit_traits(), [], true, true, true) # Clickable resources
	update_container(character_tenets_control, [character_sheet.get_unit_tenets()], [], false, false, false) # Non-clickable
	update_container(character_taboos_control, [character_sheet.get_unit_taboos()], [], false, false, false) # Non-clickable
	update_container(character_languages_control, character_sheet.get_unit_languages(), [], false, false, false) # Non-clickable
	var stats = [_get_value("get_unit_current_stamina_points") + "/" + _get_value("get_unit_max_stamina_points"), _get_value("get_unit_current_aether_points") + "/" + _get_value("get_unit_max_aether_points"),
		 _get_value("get_unit_hit_modifier", true), _get_value("get_unit_damage_string"), _get_value("get_unit_size_as_string"), _get_value("get_unit_base_speed"), _get_value("get_unit_base_climb_speed"), _get_value("get_unit_base_swim_speed"), _get_value("get_unit_base_fly_speed"), _get_value("get_unit_base_burrow_speed"), _get_value("get_unit_current_mythic_points") + "/" + _get_value("get_unit_max_mythic_points"),
		_get_value("get_unit_current_hero_points") + "/" + _get_value("get_unit_max_hero_points")]
	update_container(character_statistics_list, stats, ["Stamina Points", "Aether Points", "Strike Modifier", "Strike Damage", "Size", "Land Speed", "Climb Speed", "Swim Speed", "Fly Speed", "Burrow Speed", "Mythic Points", "Hero Points"], false, false, false, allow_hiding) # Clickable resources

func update_container(container: Control, data: Array, prefix: Array = [], is_resource: bool = true, connect_signal: bool = true, is_clickable: bool = false, allow_hiding: bool = false, reverse_cliclable_prefix: bool = false, make_prefix_sufix: bool = false) -> void:
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
				if item_data is ItemResource:
					if character_sheet.has_method("is_item_equipped"):
						if character_sheet.is_item_equipped(item_data):
							display_text += " (E)"
			else:
				# Convert numbers nicely, handle potential nulls
				if typeof(item_data) == TYPE_FLOAT: item_data = int(item_data)
				display_text = str(item_data).capitalize() if item_data != null else "N/A"
		else:
			var current_prefix = prefix[prefix_index]
			# For lists with prefixes (Skills, Senses, Speed), the clickable item is the prefix string
			if not reverse_cliclable_prefix:
				meta_data_for_click = current_prefix

			# Skip display if hiding and value is zero/invalid
			if allow_hiding:
				var skip = false
				if typeof(item_data) == TYPE_INT or typeof(item_data) == TYPE_FLOAT:
					if item_data <= 0: skip = true
				elif typeof(item_data) == TYPE_STRING:
					if item_data.is_empty() or item_data == "0" or item_data == "0/0": skip = true # Handle zero strings too?
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
			if make_prefix_sufix:
				display_text = value_text + ": " + formatted_prefix
			else:
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
		print("Item data: ", item_data)
		if item_data == null: return # Should not happen if meta is set correctly

		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_handle_single_click(label, item_data) # Handle inspect / roll / edit

		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			# Create context menu (GM only)
			if get_tree().get_nodes_in_group("Panels").size() > 0: return # Avoid overlap

			var context = context_panel.new() # Assumes context_panel is available globally or preloaded
			get_tree().get_root().get_node("Root/GameUI").add_child(context) # Adjust path if needed
			context.create_panel(get_viewport().get_mouse_position(), Vector2.ZERO)

			# Populate context menu based on item_data type
			if item_data is Resource:
				context.add_button("Inspect", WindowFactory.create_resource_inspector.bind(item_data.get_dictionary()))

			if item_data is SkillResource:
				context.add_button("Roll", _roll_dice.bind("Modifier", "get_unit_" + item_data.get_resource_name().to_lower() + "_modifier", item_data.get_resource_name(), character_sheet.get_skill_modifier(item_data.get_resource_name())))
				context.add_button("Add Modifier", _custom_roll.bind("Modifier", "get_unit_" + item_data.get_resource_name().to_lower() + "_modifier", item_data.get_resource_name(), character_sheet.get_skill_modifier(item_data.get_resource_name())))
			elif item_data is ItemResource:
				# Need to improve this logic to check what item slot the item is in and so on, also need to make this an RPC call
				if character_sheet.has_method("is_item_equipped"):
					if character_sheet.is_item_equipped(item_data):
						context.add_button("Unequip", func(): character_sheet.unequip_item(item_data); _update_character_panel(); update_container(character_inventory_and_perks_list, character_sheet.get_unit_inventory(), [], true, true, true)) # Clickable resources
					else:
						context.add_button("Equip", func(): character_sheet.equip_item("main_hand", item_data); _update_character_panel(); update_container(character_inventory_and_perks_list, character_sheet.get_unit_inventory(), [], true, true, true)) # Clickable resources

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
				context.add_button("Add Modifier", _custom_roll.bind("Modifier", "get_unit_perception_modifier", "Perception", int(_get_value("get_unit_perception_modifier"))))
				context.add_button("Add DC", _custom_roll.bind("DC", "get_unit_perception_modifier", "Perception", int(_get_value("get_unit_perception_modifier")) + 10))
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

	if data is SkillResource:
		_roll_dice("Modifier", "", data.get_resource_name(), character_sheet.get_skill_modifier(data.get_resource_name()))
	elif data is Resource:
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

func _connect_change_panel_signals(button_container: HBoxContainer):
	# Clear existing panel
	for buttons in button_container.get_children():
		buttons.toggled.connect(_change_panel.bind(buttons.text))

func _change_panel(_toggled: bool, button_name: String):
	if _is_changing_panel: return # Prevent multiple clicks
	_is_changing_panel = true
	print("test")
	
	if button_name == "Skills":
		clear_container(character_skills_and_proficiencies_list)
		print("Skills")
		character_proficiencies_button.button_pressed = false
		character_skills_button.button_pressed = true
		var proficiency_values = []
		for skill in character_sheet.get_unit_skills():
			if skill.has_method("get_proficiency_rank_as_string"):
				proficiency_values.append(skill.get_proficiency_rank_as_string())
		update_container(character_skills_and_proficiencies_list, character_sheet.get_unit_skills(), proficiency_values, true, true, true, false, true, true) # Clickable resources
	elif button_name == "Profs":
		clear_container(character_skills_and_proficiencies_list)
		print("Proficiencies")
		character_skills_button.button_pressed = false
		character_proficiencies_button.button_pressed = true
		var proficiency_values = []
		for proficiency in character_sheet.get_unit_proficiencies():
			if proficiency.has_method("get_proficiency_as_string"):
				proficiency_values.append(proficiency.get_proficiency_as_string())
		update_container(character_skills_and_proficiencies_list, character_sheet.get_unit_proficiencies(), proficiency_values, true, true, true, false, true, true) # Clickable resources
	elif button_name == "Inventory":
		clear_container(character_inventory_and_perks_list)
		print("Inventory")
		character_perks_button.button_pressed = false
		character_inventory_button.button_pressed = true
		update_container(character_inventory_and_perks_list, character_sheet.get_unit_inventory(), [], true, true, true) # Clickable resources
	elif button_name == "Perks":
		clear_container(character_inventory_and_perks_list)
		print("Perks")
		character_inventory_button.button_pressed = false
		character_perks_button.button_pressed = true
		update_container(character_inventory_and_perks_list, character_sheet.get_unit_perks(), [], true, true, true) # Clickable resources
	elif button_name == "Formulas":
		clear_container(character_formulas_and_spellbook_list)
		print("Formulas")
		character_spellbook_button.button_pressed = false
		character_formulas_button.button_pressed = true
		update_container(character_formulas_and_spellbook_list, character_sheet.get_unit_formulas(), [], true, true, true) # Clickable resources
	elif button_name == "Spellbook":
		clear_container(character_formulas_and_spellbook_list)
		print("Spellbook")
		character_formulas_button.button_pressed = false
		character_spellbook_button.button_pressed = true
		update_container(character_formulas_and_spellbook_list, character_sheet.get_unit_spells_known(), [], true, true, true) # Clickable resources
	else:
		printerr("Unknown button name: ", button_name)
		return # Unknown button, do nothing
	
	# Reset the changing panel state
	_is_changing_panel = false

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
		elif value is Dictionary:
			var result = ""
			print("Value is a dictionary: ", value)
			if value.size() > 0:
				if value.has("dice_string"):
					result += value["dice_string"]
				if value.has("flat_bonus") and value["flat_bonus"] > 0:
					result += " + " + str(value["flat_bonus"])
				elif value["flat_bonus"] < 0:
					result += str(value["flat_bonus"]) # Show negative flat bonus as subtraction
				if value.has("damage_type"):
					result += " (" + GameConst.get_damage_type_as_string(value["damage_type"]) + ")"
			return result
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
