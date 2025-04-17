extends Control

# --- @onready Variables (UI Node References) ---
@onready var monster_attributes: Control = $MainContainer/Attributes
@onready var monster_information: Control = $MainContainer/Information

# -- Cache specific controls --
@onready var monster_name_control: Label = $MainContainer/Information/NameContainer/Value
@onready var monster_size_control: Label = $MainContainer/Information/SizeContainer/Value
@onready var monster_level_control: Label = $MainContainer/Information/LevelContainer/Value
@onready var monster_gender_control: Label = $MainContainer/Information/GenderContainer/Value
@onready var monster_ac_control: Label = $MainContainer/Information/ACContainer/Value
@onready var monster_hp_control: Label = $MainContainer/Information/HPContainer/Value
@onready var monster_perception_control: Label = $MainContainer/Information/PerceptionContainer/Value

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
@onready var monster_parts_control: VBoxContainer = $MainContainer/Skills2/Skills3/ScrollContainer2/Parts
@onready var monster_abilities_control: VBoxContainer = $MainContainer/Lists/Lists/ScrollContainer/Abilities
@onready var monster_attacks_control: VBoxContainer = $MainContainer/Lists/Lists/ScrollContainer2/Attacks

@onready var monster_skills_button: Button = $MainContainer/List2/Skills
@onready var monster_parts_button: Button = $MainContainer/List2/Parts
@onready var monster_abilities_button: Button = $MainContainer/List/Abilities
@onready var monster_attacks_button: Button = $MainContainer/List/Attacks

# --- Member Variables ---
# -- State & Data --
var monster_id: String
var monster_sheet: Resource
var dice: DiceManager
var speed_dict = {
		"Land": 0,
		"Fly": 0,
		"Swim": 0,
		"Climb": 0,
		"Burrow": 0
	}

# -- Internal Helpers --
var _click_timer: Timer
var _hover_timer: Timer
var _potential_single_click_label: Label = null
var _potential_single_click_data = null
var _is_changing_panel: bool = false

# --- Godot Virtual Methods ---

func _ready() -> void:
	dice = DiceManager.new()
	_click_timer = Timer.new()
	_click_timer.one_shot = true
	_click_timer.wait_time = 0.0 # Effectively disables double-click detection logic
	_click_timer.timeout.connect(_on_click_timer_timeout)
	add_child(_click_timer)

	_hover_timer = Timer.new()
	_hover_timer.one_shot = true
	_hover_timer.wait_time = 0.5
	_hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(_hover_timer)

	# Note: Button toggled signals (_change_panel) and input signals (_on_input, _on_label_gui_input, _on_button_gui_input)
	# are likely connected in the Godot Editor inspector.

func _process(delta: float) -> void:
	if !visible:
		global_position = Vector2(-9999999, 999999999999) # Move off-screen when hidden
	else:
		Bus.set_pause_busy(true)
		
# --- Public Interface ---

func _initialize_monster_panel(p_monster_sheet: Resource, p_monster_id: String) -> void:
	# Use p_ prefix for parameters to avoid confusion with member variables
	self.monster_id = p_monster_id
	self.monster_sheet = p_monster_sheet

	# Add checks to ensure the sheet is valid before proceeding
	if not is_instance_valid(monster_sheet):
		printerr("Invalid monster_sheet passed to _initialize_monster_panel for ID: ", p_monster_id)
		# Optionally clear the fields or hide the panel
		return

	# Update the panel with the new data
	_update_monster_panel()

# Called externally (e.g., from context menu) to add a resource via RPC
func add_resource(_resource: String) -> void: # Parameter is resource *name*
	var resource = Cache.find_loaded_resource_by_name(_resource)
	if resource:
		# Determine method based on resource type
		var method_to_call = ""
		if resource is TraitResource:
			method_to_call = "add_trait"
		elif resource is TemplateResource:
			# Note: Original code had "add_template" call here directly, but it should likely go via RPC like traits
			# Keeping original logic for now, but this might need adjustment based on add_template's implementation
			# If add_template itself handles RPCs or is host-only, this is fine.
			# If it needs to affect a specific monster instance via ID, use set_resource_to_peer.rpc
			method_to_call = "add_template" # Assuming add_template exists on sheet

		if not method_to_call.is_empty():
			# Use RPC to target the correct monster instance on the host/authority
			set_resource_to_peer.rpc(method_to_call, _resource, monster_id)
		else:
			printerr("Unknown resource type to add: ", _resource)

		# Update the local panel immediately for the GM
		# Client updates will happen when their data syncs after the RPC executes
		if Net.is_host():
			_update_monster_panel()

	else:
		printerr("Could not find loaded resource by name: ", _resource)


# --- Core Update & UI Logic ---

func _update_monster_panel() -> void:
	if not is_instance_valid(monster_sheet):
		printerr("Cannot update panel, monster_sheet is invalid.")
		# Optionally clear fields
		return
	
	if !Net.is_host():
		monster_might_control.get_parent().get_node("Might").disabled = true
		monster_agility_control.get_parent().get_node("Agility").disabled = true
		monster_endurance_control.get_parent().get_node("Endurance").disabled = true
		monster_cognition_control.get_parent().get_node("Cognition").disabled = true
		monster_insight_control.get_parent().get_node("Insight").disabled = true
		monster_charisma_control.get_parent().get_node("Charisma").disabled = true

	var allow_hiding = !Settings.gameplay_settings["show_empty_values_on_character_sheet"]

	# Update basic info labels
	monster_name_control.text = _get_value("get_unit_name")
	monster_size_control.text = _get_value("get_unit_size_name")
	monster_level_control.text = _get_value("get_unit_level")
	monster_gender_control.text = _get_value("get_unit_gender")
	monster_ac_control.text = _get_value("get_unit_base_armor_class")
	monster_hp_control.text = _get_value("get_unit_max_hit_points") + "(" + _get_value("get_unit_temporary_hit_points") + ")"
	monster_perception_control.text = _get_value("get_unit_perception_modifier", true)

	# Update attribute labels
	monster_might_control.text = _get_value("get_unit_might_modifier", true) + "(" + _get_value("get_unit_might_saving_throw", true) + ")"
	monster_agility_control.text = _get_value("get_unit_agility_modifier", true) + "(" + _get_value("get_unit_agility_saving_throw", true) + ")"
	monster_endurance_control.text = _get_value("get_unit_endurance_modifier", true) + "(" + _get_value("get_unit_endurance_saving_throw", true) + ")"
	monster_cognition_control.text = _get_value("get_unit_intelligence_modifier", true) + "(" + _get_value("get_unit_intelligence_saving_throw", true) + ")"
	monster_insight_control.text = _get_value("get_unit_insight_modifier", true) + "(" + _get_value("get_unit_insight_saving_throw", true) + ")"
	monster_charisma_control.text = _get_value("get_unit_charisma_modifier", true) + "(" + _get_value("get_unit_charisma_saving_throw", true) + ")"

	# Update speed dictionary before populating container
	speed_dict = {
		"Land": _get_value("get_unit_base_speed"),
		"Fly": _get_value("get_unit_base_fly_speed"),
		"Swim": _get_value("get_unit_base_swim_speed"),
		"Climb": _get_value("get_unit_base_climb_speed"),
		"Burrow": _get_value("get_unit_base_burrow_speed")
	}

	# Update list containers
	update_container(monster_traits_control, monster_sheet.get_traits(), [], true, true, true) # Clickable resources
	update_container(monster_senses_control, monster_sheet.get_senses().values(), monster_sheet.get_senses().keys(), false, true, true) # Clickable strings (keys)
	update_container(monster_immunities_control, monster_sheet.get_immunities()) # Not specified if clickable, assume basic text
	update_container(monster_resistances_control, monster_sheet.get_resistances()) # ditto
	update_container(monster_weaknesses_control, monster_sheet.get_weaknesses()) # ditto
	update_container(monster_languages_control, monster_sheet.get_languages(), [], false, false, false, allow_hiding) # Not clickable
	update_container(monster_skills_control, monster_sheet.get_skills().values(), monster_sheet.get_skills().keys(), false, true, true, allow_hiding) # Clickable strings (keys)
	update_container(monster_speed_control, speed_dict.values(), speed_dict.keys(), false, true, true, allow_hiding) # Clickable strings (keys)
	update_container(monster_abilities_control, monster_sheet.get_abilities(), [], true, true, true) # Clickable resources
	update_container(monster_attacks_control, monster_sheet.get_attacks(), [], true, true, true) # Clickable resources

	# Conditionally hide sections if allow_hiding is true and the section is empty
	if allow_hiding:
		print("Allow hiding is enabled") # Debug print
		# Hide parent container if the source data array is empty
		monster_traits_control.get_parent().get_parent().visible = monster_sheet.get_traits().size() > 0
		monster_senses_control.get_parent().get_parent().visible = monster_sheet.get_senses().size() > 0
		monster_immunities_control.get_parent().get_parent().visible = monster_sheet.get_immunities().size() > 0
		monster_resistances_control.get_parent().get_parent().visible = monster_sheet.get_resistances().size() > 0
		monster_weaknesses_control.get_parent().get_parent().visible = monster_sheet.get_weaknesses().size() > 0
		monster_languages_control.get_parent().get_parent().visible = monster_sheet.get_languages().size() > 0
		# Note: Skills, Speed, Abilities, Attacks visibility might need similar logic if they can be empty

# Populates a VBoxContainer with labels based on data array
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

# Switches visibility between tabbed panels
func _change_panel(toggled: bool, type: String):
	if _is_changing_panel or not toggled:
		return # Prevent recursion and only act on toggle ON

	_is_changing_panel = true

	# Determine which pair of buttons/panels to manage
	var is_skills_parts = (type == "Skills" or type == "Parts")
	var button1 = monster_skills_button if is_skills_parts else monster_abilities_button
	var button2 = monster_parts_button if is_skills_parts else monster_attacks_button
	var panel1 = monster_skills_control.get_parent() if is_skills_parts else monster_abilities_control.get_parent() # Assuming parent is ScrollContainer
	var panel2 = monster_parts_control.get_parent() if is_skills_parts else monster_attacks_control.get_parent()

	# Set button states and panel visibility
	if type == "Skills" or type == "Abilities":
		button1.button_pressed = true
		button2.button_pressed = false
		panel1.visible = true
		panel2.visible = false
	elif type == "Parts" or type == "Attacks":
		button1.button_pressed = false
		button2.button_pressed = true
		panel1.visible = false
		panel2.visible = true

	_is_changing_panel = false

# --- Input Handling & Actions ---

# Handles left/right clicks on the main panel or specific clickable areas if connected
func _on_input(event: InputEvent, extra: String) -> void: # extra comes from signal connection in editor
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and Net.is_host():
			# Handle Modifier/Saving choice panels for attributes
			match extra:
				"HP":
					WindowFactory.create_choice_panel(self, "Normal", "Temporary", _open_changer_panel.bind("HP"), _open_changer_panel.bind("TempHP"))
					return # Handled
				"Might", "Agility", "Endurance", "Cognition", "Insight", "Charisma":
					WindowFactory.create_choice_panel(self, "Modifier", "Saving", _open_changer_panel.bind(extra), _open_changer_panel.bind(extra + "Saving"))
					return # Handled
				_:
					# Default action for other bound controls (e.g., Name, Level, Perception)
					_open_changer_panel(extra)

# Handles left/right clicks on labels within list containers
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
				context.add_button("Remove", func():
					var callback = func(): set_resource_to_peer.rpc("remove_trait", item_data.get_resource_name(), monster_id)
					WindowFactory.create_safety_message(self, "Are you sure you want to remove this trait?", callback))
			elif item_data is String: # Handles Skills, Senses, Speed prefixes
				var new_data = Helper.separate_string_with_regex(item_data) if Helper else [item_data]
				var base_name = new_data[0].capitalize()
				var resource = Cache.find_loaded_resource_by_name(base_name)
				var precision = new_data[1] if new_data.size() > 1 else ""

				if resource: # Found a matching resource (Skill, Sense, Speed)
					if precision != "" and resource.has_method("set_precision_by_string"):
						resource.set_precision_by_string(precision) # Update local resource if needed for inspect

					context.add_button("Inspect", WindowFactory.create_resource_inspector.bind(resource.get_dictionary()))

					if resource is SpeedResource or resource is SenseResource:
						context.add_button("Edit", _open_changer_panel.bind(base_name))
					elif monster_sheet.has_method("get_skill_modifier"): # Assume it's a Skill
						context.add_button("Roll", _roll_dice.bind("Modifier", "", base_name, monster_sheet.get_skill_modifier(base_name)))
						context.add_button("Modified Roll", _custom_roll.bind("Modifier", "", base_name, monster_sheet.get_skill_modifier(base_name)))
				else:
					printerr("Context menu: Resource not found in cache for string: ", base_name)
					context.add_button("Error", func(): pass) # Indicate failure
			elif item_data is Resource: # Handle generic Abilities, Attacks etc.
				context.add_button("Inspect", WindowFactory.create_resource_inspector.bind(item_data.get_dictionary()))
				# Add Remove/Edit options if applicable for these resource types
			else:
				# Fallback for unknown data types
				context.add_button("Debug Info", func(): print("Context menu for unknown data: ", item_data))


# Handles right-clicks on specific buttons/areas bound in the editor (like Perception header)
func _on_button_gui_input(event: InputEvent, extra: String): # extra comes from signal connection
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed and Net.is_host():
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
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and Net.is_host():
			_roll_dice("Modifier", "get_unit_" + extra.to_lower() + "_modifier", extra) # Default to rolling the modifier


# Opens the generic panel for changing a single value via RPC
func _open_changer_panel(variable: String) -> void:
	if !Net.is_host(): return

	ensure_single_instance("ChangePanel") # Ensure only one changer is open

	var panel = load("res://UI/Instances/sheet_changer_panel.tscn").instantiate()
	# panel.get_child(0).container_name = variable # Set title if panel supports it
	add_child(panel)
	panel.add_to_group("ChangePanel")

	# Configure the panel's callback based on the variable being changed
	var method_name = ""
	var use_multiple = false
	var args = [] # For methods needing fixed preceding arguments (like set_skill_modifier)

	match variable:
		"Name": method_name = "set_unit_name"
		"Size": method_name = "set_unit_size_by_name"
		"Level": method_name = "set_unit_level"
		"Gender": method_name = "set_unit_gender"
		"AC": method_name = "set_unit_base_armor_class"
		"HP": method_name = "set_unit_max_hit_points"
		"Perception": method_name = "set_unit_perception_modifier"
		"TempHP": method_name = "set_unit_temporary_hit_points"
		"Might": method_name = "set_unit_might_modifier"
		"MightSaving": method_name = "set_unit_might_saving_throw"
		"Agility": method_name = "set_unit_agility_modifier"
		"AgilitySaving": method_name = "set_unit_agility_saving_throw"
		"Endurance": method_name = "set_unit_endurance_modifier"
		"EnduranceSaving": method_name = "set_unit_endurance_saving_throw"
		"Cognition": method_name = "set_unit_intelligence_modifier"
		"CognitionSaving": method_name = "set_unit_intelligence_saving_throw"
		"Insight": method_name = "set_unit_insight_modifier"
		"InsightSaving": method_name = "set_unit_insight_saving_throw"
		"Charisma": method_name = "set_unit_charisma_modifier"
		"CharismaSaving": method_name = "set_unit_charisma_saving_throw"
		# Skills
		"Acrobatics","Alchemy","Arcana","Athletics","Crafting","Deception","Diplomacy", \
		"Empathy","Enchanting","Intimidation","Lore","Medicine","Nature","Occultism", \
		"Performance","Religion","Society","Stealth","Survival","Thievery":
			method_name = "set_skill_modifier"
			use_multiple = true
			args = [variable] # The skill name is the first argument
		# Speeds
		"Land": method_name = "set_unit_base_speed"
		"Fly": method_name = "set_unit_base_fly_speed"
		"Swim": method_name = "set_unit_base_swim_speed"
		"Climb": method_name = "set_unit_base_climb_speed"
		"Burrow": method_name = "set_unit_base_burrow_speed"
		# Senses (assuming precision is passed as the value)
		"Darkvision", "Low-light vision", "Echolocation", "Hearing", "Scent":
			method_name = "set_sense"
			use_multiple = true
			args = [variable.to_lower()] # Sense name (lowercase) is first argument
		_:
			printerr("Invalid variable name for changer panel: ", variable)
			panel.queue_free() # Clean up unused panel
			return

	# Set the callback for the changer panel instance
	panel.callable = func(value):
		var final_value = value
		# Attempt basic type conversion for numbers, default to string if invalid
		if variable in ["Level", "AC", "HP", "Perception", "TempHP", \
						"Might", "MightSaving", "Agility", "AgilitySaving", \
						"Endurance", "EnduranceSaving", "Cognition", "CognitionSaving", \
						"Insight", "InsightSaving", "Charisma", "CharismaSaving", \
						"Acrobatics","Alchemy","Arcana","Athletics","Crafting","Deception","Diplomacy", \
						"Empathy","Enchanting","Intimidation","Lore","Medicine","Nature","Occultism", \
						"Performance","Religion","Society","Stealth","Survival","Thievery", \
						"Land", "Fly", "Swim", "Climb", "Burrow"]:
			if str(value).is_valid_int():
				final_value = int(value)
			else:
				printerr("Invalid integer input '%s' for variable '%s'. Sending as string." % [value, variable])
				final_value = str(value) # Send as string if not valid int

		# Call the RPC with appropriate arguments
		if use_multiple:
			var final_args = args + [final_value]
			_set_variable.rpc(method_name, final_args, monster_id, true)
		else:
			_set_variable.rpc(method_name, final_value, monster_id, false)

	# Initialize the panel (assuming it makes itself visible)
	if panel.has_method("_initialize"):
		panel._initialize()


# Opens panel for custom roll modifier input
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

		Bus.send_roll_to_all.emit(monster_sheet.get_unit_name(), "rolls a", attribute_name.capitalize() + " " + additional_info, roll, "", "")

	if panel.has_method("_initialize"):
		panel._initialize()

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
	Bus.send_roll_to_all.emit(monster_sheet.get_unit_name(), "rolls a", attribute_name.capitalize() + " " + additional_info, roll, "", "")

# Handles the actual click action after potential delay/double-click check
func _handle_single_click(_label_node: Label, data):
	Audio._on_button_pressed() # Play sound

	if data is Resource:
		print("Resource clicked: ", data.get_resource_name() if data.has_method("get_resource_name") else data.resource_path)
		WindowFactory.create_resource_inspector(data.get_dictionary())
	elif data is String and Net.is_host():
		# Handle clicks on Skill/Sense/Speed prefixes
		var parts = Helper.separate_string_with_regex(data) if Helper else [data]
		var base_name = parts[0].capitalize()
		var precision = parts[1] if parts.size() > 1 else ""
		var resource = Cache.find_loaded_resource_by_name(base_name)

		if resource and (resource is SpeedResource or resource is SenseResource):
			# Open editor for Speed/Sense
			_open_changer_panel(base_name)
		elif resource and monster_sheet.has_method("get_skill_modifier"):
			# Roll skill check
			var modifier = monster_sheet.get_skill_modifier(base_name)
			_roll_dice("Modifier", "", base_name, modifier)
		else:
			print("Single click on string '%s' did not match an editable/rollable item." % data)
	else:
		print("Single click detected on label with unknown data type: ", data)


# Placeholder for hover actions (e.g., showing tooltips)
func _handle_hover(_label_node: Label, data):
	# Called by _on_hover_timer_timeout
	# Implement tooltip logic here if needed, using 'data'
	pass


# --- Networking (RPC Methods) ---

# RPC called by GM to update a variable on the correct monster instance
@rpc("authority", "call_local", "reliable") # Run on host, call locally too for GM feedback
func _set_variable(method_name: String, value: Variant, id: String, multiple: bool = false) -> void:
	# This RPC is intended to be called BY the GM/Host, targeting the authoritative instance.
	# Clients should NOT call this directly.
	# The `monster_non_instance` check seems misplaced here if it's host-invoked.
	# The core logic should find the monster by ID and apply the change.

	var monster = _get_monster_instance(id)
	if is_instance_valid(monster):
		if monster.has_method("get_character_sheet") and is_instance_valid(monster.get_character_sheet()):
			var target_sheet = monster.get_character_sheet() # Get the sheet of the specific monster instance
			if target_sheet.has_method(method_name):
				print("RPC: Applying %s(%s) to monster %s" % [method_name, str(value), id])
				if multiple and value is Array:
					target_sheet.callv(method_name, value)
				elif not multiple:
					target_sheet.call(method_name, value)
				else:
					printerr("RPC argument mismatch for %s: multiple=%s, value type=%s" % [method_name, multiple, typeof(value)])

				# If the caller is the host AND this panel matches the ID, update locally
				if Net.is_host() and self.monster_id == id:
					_update_monster_panel() # Update host's panel view
			else:
				printerr("RPC Error: Monster %s sheet does not have method: %s" % [id, method_name])
		else:
			printerr("RPC Error: Monster %s does not have a valid character_sheet." % id)
	else:
		# This case might occur if the monster was removed between the GM action and RPC execution
		printerr("RPC Error: Monster instance %s not found." % id)


# RPC called by GM to add/remove resources (like traits) on the correct monster instance
@rpc("authority", "call_local", "reliable") # Run on host, call locally too for GM feedback
func set_resource_to_peer(method_name: String, resource_name: String, id: String) -> void:
	# Similar to _set_variable, this targets the specific monster instance via ID.
	var monster = _get_monster_instance(id)
	if is_instance_valid(monster):
		if monster.has_method("get_character_sheet") and is_instance_valid(monster.get_character_sheet()):
			var target_sheet = monster.get_character_sheet()
			var resource = Cache.find_loaded_resource_by_name(resource_name)

			if not is_instance_valid(resource):
				printerr("RPC Error: Resource '%s' not found in cache for monster %s." % [resource_name, id])
				return

			if target_sheet.has_method(method_name):
				print("RPC: Applying %s(%s) to monster %s" % [method_name, resource_name, id])
				target_sheet.call(method_name, resource) # Assuming methods like add_trait take the Resource object

				# Update local panel if it's the host viewing the affected monster
				if Net.is_host() or self.monster_id == id:
					_update_monster_panel()
			else:
				printerr("RPC Error: Monster %s sheet does not have method: %s" % [id, method_name])
		else:
			printerr("RPC Error: Monster %s does not have a valid character_sheet." % id)
	else:
		printerr("RPC Error: Monster instance %s not found when setting resource." % id)


# --- Signal Callbacks ---

# Called when the mouse enters a label in a list container
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
	# Stop hover timer logic
	_hover_timer.stop()
	# Clear hover tracking if the mouse exited the label we were tracking
	if _potential_single_click_label == label:
		_potential_single_click_label = null
		_potential_single_click_data = null

# Called if the click timer finishes (used for double-click detection, currently disabled)
func _on_click_timer_timeout():
	# If wait_time > 0, this indicates a single click completed without a second click following.
	# Since wait_time is 0.0, this fires immediately after _click_timer.start(),
	# potentially *before* the intended single click action if not handled carefully.
	# With current setup (_handle_single_click on press), this is likely redundant unless re-enabling double-click.
	# if is_instance_valid(_potential_single_click_label):
		# _handle_single_click(_potential_single_click_label, _potential_single_click_data)

	_potential_single_click_label = null
	_potential_single_click_data = null

# Called if the hover timer finishes
func _on_hover_timer_timeout():
	# Check if the label we were potentially hovering over is still valid
	if is_instance_valid(_potential_single_click_label):
		_handle_hover(_potential_single_click_label, _potential_single_click_data)

	# Clear pending info after hover action (or timeout)
	_potential_single_click_label = null
	_potential_single_click_data = null


# --- Utility Methods ---

# Finds the monster node instance in the scene tree by its unique ID (name)
func _get_monster_instance(id: String) -> Node:
	# Assumes monster instances are nodes directly in the "token" group
	# Adjust group name or search logic if structure is different
	for token in get_tree().get_nodes_in_group("token"):
		if is_instance_valid(token) and token.name == id:
			return token
	return null # Return null if not found

# Safely calls a method by name on the monster_sheet if it exists
func _use_method(method_name: String, value: Variant) -> void:
	if is_instance_valid(monster_sheet) and monster_sheet.has_method(method_name):
		monster_sheet.call(method_name, value)
	else:
		printerr("MonsterSheet does not have method: ", method_name)

# Safely calls a method by name with multiple arguments on the monster_sheet
func _use_method_multiple(method_name: String, values: Array) -> void:
	if is_instance_valid(monster_sheet) and monster_sheet.has_method(method_name):
		monster_sheet.callv(method_name, values)
	else:
		printerr("MonsterSheet does not have method: ", method_name)

# Safely gets a value from the monster_sheet by calling a method, with formatting
func _get_value(method_name: String, add_plus: bool = false) -> String:
	if is_instance_valid(monster_sheet) and monster_sheet.has_method(method_name):
		var value = monster_sheet.call(method_name)

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
