extends Control

const KEY_COLOR = "cf9b76" # The hex color for keys
const SEPARATOR = "\n\n" # Separator between entries
const INDENT = " " # Indentation for values

# ===================== CHARACTER CREATOR CONTROL =====================
@onready var intro = %Introduction.get_node("Introduction")
@onready var background = %Background.get_node("Background")
@onready var basic_info = %Basic.get_node("Basic")
@onready var modifiers = %Modifiers.get_node("Modifiers")
@onready var shop = %Shop.get_node("Shop")
@onready var summary = %Summary.get_node("Summary")
@onready var buttons = %Buttons

# --- buttons ---
@onready var back_button = buttons.get_node("Back")
@onready var next_button = buttons.get_node("Next")

# --- options ---
@onready var species_options = background.get_node("SpeciesOptions")
@onready var lineage_options = background.get_node("LineageOptions")
@onready var affinity_options = background.get_node("AffinityOptions")

# --- descriptions ---
@onready var species_desc = background.get_node("SpeciesDesc")
@onready var lineage_desc = background.get_node("LineageDesc")
@onready var affinity_desc = background.get_node("AffinityDesc")

# --- species controls ---
@onready var species_hp = background.get_node("GridContainer").get_node("HP Value")
@onready var species_sp = background.get_node("GridContainer").get_node("SP Value")
@onready var species_size = background.get_node("GridContainer").get_node("Size Value")
@onready var species_speed = background.get_node("GridContainer").get_node("Speed Value")
@onready var species_languages = background.get_node("Languages Value")

# --- affinity controls ---
@onready var affinity_forced_attributes = background.get_node("GridContainer2").get_node("Forced Value")
@onready var affinity_free_attributes = background.get_node("GridContainer2").get_node("Free Value")
@onready var affinity_skills = background.get_node("GridContainer2").get_node("Skills Value")
@onready var affinity_perks = background.get_node("GridContainer2").get_node("Perks Value")

# --- Basic Info Controls ---
@onready var character_name = basic_info.get_node("Name Value")
@onready var character_gender = basic_info.get_node("Gender Value")
@onready var character_age = basic_info.get_node("Age Value")
@onready var character_height = basic_info.get_node("Height Value")
@onready var character_weight = basic_info.get_node("Weight Value")
@onready var character_tenets = basic_info.get_node("Tenets Value")
@onready var character_taboos = basic_info.get_node("Taboos Value")

# --- Modifiers ---
@onready var character_might_mod = modifiers.get_node("Attributes").get_node("Might Value")
@onready var character_agility_mod = modifiers.get_node("Attributes").get_node("Agility Value")
@onready var character_intelligence_mod = modifiers.get_node("Attributes").get_node("Intelligence Value")
@onready var character_endurance_mod = modifiers.get_node("Attributes").get_node("Endurance Value")
@onready var character_insight_mod = modifiers.get_node("Attributes").get_node("Insight Value")
@onready var character_charisma_mod = modifiers.get_node("Attributes").get_node("Charisma Value")
@onready var character_forced_attributes = modifiers.get_node("Attributes").get_node("Forced Value")
@onready var character_free_attributes = modifiers.get_node("Attributes").get_node("Free Value")
@onready var character_forced_attributes_desc = modifiers.get_node("Attributes").get_node("Forced Type")

# --- shop ---
@onready var shop_list = shop.get_node("HBoxContainer").get_node("Shop")
@onready var equipped_list = shop.get_node("HBoxContainer").get_node("Equipment")
@onready var copper_control = shop.get_node("Copper Value")
@onready var buy_button = shop.get_node("Buttons").get_node("Buy")
@onready var sell_button = shop.get_node("Buttons").get_node("Sell")

# --- Summary ---
@onready var summary_desc = summary.get_node("Summary Value")

var _control_order: Array = []
var _control_current_index: int = 0

var default_character_values: Dictionary = {}
var character_sheet: CharacterSheet = null

var _selected_species: SpecieResource = null
var _selected_affinity: AffinityResource = null
var _selected_lineage: LineageResource = null

var _total_attribute_boosts = 3
var _total_forced_attribute_boosts = 1
var _current_attribute_boosts = 0
var _current_forced_attribute_boosts = 0
var _current_forced_attribute_names: Array = []

var _initialized_modifiers = false

var _current_copper = 500
var _selected_item: ItemResource = null

func _ready() -> void:
	character_sheet = CharacterSheet.new()
	default_character_values = character_sheet.get_sheet_as_dictionary()
	_control_order = [intro, background, basic_info, modifiers, shop, summary]
	_connect_button_signals()
	call_deferred("_update_control")
	call_deferred("_initialize_background")
	_initialize_shop()
	default_character_values["gender"] = "Male"

# --- signal connections ---
func _connect_button_signals() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	species_options.item_selected.connect(_on_species_selected)
	affinity_options.item_selected.connect(_on_affinity_selected)
	lineage_options.item_selected.connect(_on_lineage_selected)
	character_name.text_changed.connect(func(text): default_character_values["character_name"] = text)
	character_gender.item_selected.connect(func(index): default_character_values["gender"] = character_gender.get_item_text(index))
	character_age.value_changed.connect(func(value): default_character_values["age"] = value)
	character_height.value_changed.connect(func(value): default_character_values["height"] = value)
	character_weight.value_changed.connect(func(value): default_character_values["weight"] = value)
	character_tenets.text_changed.connect(func(): default_character_values["tenets"] = character_tenets.text)
	character_taboos.text_changed.connect(func(): default_character_values["taboos"] = character_taboos.text)
	character_might_mod.value_changed.connect(func(value): _on_attribute_modified(value, "might", character_might_mod))
	character_agility_mod.value_changed.connect(func(value): _on_attribute_modified(value, "agility", character_agility_mod))
	character_intelligence_mod.value_changed.connect(func(value): _on_attribute_modified(value, "intelligence", character_intelligence_mod))
	character_endurance_mod.value_changed.connect(func(value): _on_attribute_modified(value, "endurance", character_endurance_mod))
	character_insight_mod.value_changed.connect(func(value): _on_attribute_modified(value, "insight", character_insight_mod))
	character_charisma_mod.value_changed.connect(func(value): _on_attribute_modified(value, "charisma", character_charisma_mod))
	shop_list.item_selected.connect(_on_item_selected)
	equipped_list.item_selected.connect(_on_item_selected_equip)
	shop_list.gui_input.connect(_on_item_right_clicked)
	equipped_list.gui_input.connect(_on_item_right_clicked)
	buy_button.pressed.connect(_on_buy_button_pressed)
	sell_button.pressed.connect(_on_sell_button_pressed)

# --- button actions ---
func _on_back_button_pressed() -> void:
	if _control_current_index > 0:
		_control_current_index -= 1
		_update_control()
		_update_character_sheet()
	else:
		push_warning("No previous control to go back to.")
		return

func _on_next_button_pressed() -> void:
	if _control_current_index < _control_order.size() - 1:
		if _control_current_index == 2:
			if character_name.text == "" or character_taboos.text == "" or character_tenets.text == "":
				ErrorUtility.print_error("Values cannot be empty.")
				return
		_control_current_index += 1
		_update_control()
		_update_character_sheet()
	else:
		push_warning("No next control to go to.")
		return

func _on_finish_button_pressed() -> void:
	if _control_current_index == _control_order.size() - 1:
		# Save character data or proceed to the next step
		push_warning("Character creation finished.")
		ExternalUtility.save_dict_to_json("user://Assets/CharacterSheets/" + default_character_values["character_name"] + ".json", default_character_values)
		self.queue_free()
		return
	else:
		push_warning("Cannot finish character creation yet.")
		return

func _on_species_selected(selected_index: int) -> void:
	if selected_index != -1:
		_selected_species = species_options.get_item_metadata(selected_index)
		_initialize_species(_selected_species)
		_update_character_sheet()
		lineage_options.clear()
		for lineage in _selected_species.get_lineages():
			print(lineage)
			lineage_options.add_item(lineage.get_resource_name())
			lineage_options.set_item_metadata(lineage_options.get_item_count() - 1, lineage)
		lineage_options.select(0)
		_on_lineage_selected(0)
		
func _on_affinity_selected(selected_index: int) -> void:
	if selected_index != -1:
		_selected_affinity = affinity_options.get_item_metadata(selected_index)
		_initialize_affinity(_selected_affinity)
		_update_character_sheet()

func _on_lineage_selected(selected_index: int) -> void:
	if selected_index != -1:
		_selected_lineage = lineage_options.get_item_metadata(selected_index)
		_initialize_lineage(_selected_lineage)
		_update_character_sheet()

func _on_item_selected(selected_index: int) -> void:
	if selected_index != -1:
		_selected_item = shop_list.get_item_metadata(selected_index)
		equipped_list.deselect_all()

func _on_item_selected_equip(selected_index: int) -> void:
	if selected_index != -1:
		_selected_item = equipped_list.get_item_metadata(selected_index)
		shop_list.deselect_all()

func _on_buy_button_pressed() -> void:
	if _selected_item == null:
		push_warning("No item selected to buy.")
		return

	if _current_copper < _selected_item.get_price_in_copper():
		push_warning("Not enough copper to buy the item.")
		return

	update_copper(-_selected_item.get_price_in_copper())
	shop_list.remove_item(shop_list.get_selected_items()[0])
	equipped_list.add_item(_selected_item.get_resource_name())
	equipped_list.set_item_metadata(equipped_list.get_item_count() - 1, _selected_item)
	_selected_item = null

func _on_sell_button_pressed() -> void:
	if _selected_item == null:
		push_warning("No item selected to sell.")
		return

	update_copper(_selected_item.get_price_in_copper())
	equipped_list.remove_item(equipped_list.get_selected_items()[0])
	shop_list.add_item(_selected_item.get_resource_name())
	shop_list.set_item_metadata(shop_list.get_item_count() - 1, _selected_item)
	_selected_item = null

func _on_item_right_clicked(event: InputEvent) -> void:
	if event.is_action_pressed("RIGHT_CLICK"):
			var item = _selected_item
			if item != null:
				if get_tree().get_nodes_in_group("Panels").size() > 0: return
				var context = context_panel.new()
				get_tree().get_root().get_node("Root").get_node("MenuUI").add_child(context)
				context.create_panel(get_viewport().get_mouse_position(), Vector2.ZERO)
				context.add_button("Inspect", func(): WindowFactory.create_resource_inspector(item.get_dictionary(), false))
				# Show item details in a popup or tooltip
		
func _on_attribute_modified(new_value: float, method_name: String, control: SpinBox) -> void:
	# 1. Get the previous value BEFORE making changes
	var old_value = default_character_values.get(method_name + "_modifier", 0) # Use get() for safety

	# Ensure values are integers for comparison and storage
	var new_value_int = int(new_value)
	var old_value_int = int(old_value)

	# Determine direction
	var increase = new_value_int > old_value_int
	var decrease = new_value_int < old_value_int

	# --- Handle DECREASE ---
	if decrease:
		# SpinBox min_value handles the lower cap check

		# Give back a boost (Simplest: always give back a free boost first)
		# More complex logic could track if a forced boost was used, but let's start simple.
		_current_attribute_boosts += 1

		# Update the stored value
		default_character_values[method_name + "_modifier"] = new_value_int

		# Update SpinBox prefix
		control.prefix = "+" if new_value_int > 0 else ""
		# Update UI labels showing boost counts
		_update_modifiers()
		# print("Decreased %s. Free boosts: %d" % [method_name, _current_attribute_boosts])
		return # Decrease handled

	# --- Handle INCREASE ---
	if increase:
		# SpinBox max_value handles the upper cap check

		var boost_spent = false
		var spent_forced = false # Track which type was spent

		# --- Try spending a FREE boost ---
		if _current_attribute_boosts > 0:
			_current_attribute_boosts -= 1
			boost_spent = true

		# --- If NO free boost, try spending a FORCED boost (if eligible) ---
			print(_current_forced_attribute_names)
		elif _current_forced_attribute_names.find(method_name.capitalize()) != -1: # Check eligibility
			if _current_forced_attribute_boosts > 0:
				_current_forced_attribute_boosts -= 1
				boost_spent = true
				spent_forced = true # Mark that a forced boost was used

		# --- Finalize based on whether a boost was successfully spent ---
		if boost_spent:
			# Update the stored value
			default_character_values[method_name + "_modifier"] = new_value_int
			# Update SpinBox prefix
			control.prefix = "+" if new_value_int > 0 else ""
			# Update UI labels showing boost counts
			_update_modifiers()
		else:
			# Increase failed - REVERT the SpinBox value
			push_warning("Cannot increase '%s': No applicable attribute boosts remaining." % method_name)
			control.set_block_signals(true) # Prevent infinite loop
			control.value = old_value_int   # Set value back without triggering signal
			control.set_block_signals(false)
			# No need to update prefix, as value was reverted

		return # Increase attempt handled (either succeeded or failed)

	# --- Handle NO CHANGE (value == old_value) ---
	# Ensure prefix is correct if value is 0 or positive/negative
	if new_value_int > 0:
		control.prefix = "+"
	else:
		control.prefix = ""
	_update_character_sheet()

# --- control updates ---
func _update_control() -> void:
	for control in _control_order:
		control.get_parent().visible = false
	_control_order[_control_current_index].get_parent().visible = true
	_update_character_sheet()
	_initialize_summary()
	if _control_current_index == 2:
		_initialize_basic_info()
	elif _control_current_index == 3 and not _initialized_modifiers:
		_initialized_modifiers = true
		_initialize_modifiers()
	# Update the buttons based on the current control
	if _control_current_index == 0:
		back_button.disabled = true
		next_button.disabled = false
		next_button.text = "Next"
		if next_button.pressed.is_connected(_on_finish_button_pressed):
			next_button.pressed.disconnect(_on_finish_button_pressed)
		if not next_button.pressed.is_connected(_on_next_button_pressed):
			next_button.pressed.connect(_on_next_button_pressed)
	elif _control_current_index == _control_order.size() - 1:
		back_button.disabled = false
		next_button.text = "Finish"
		if next_button.pressed.is_connected(_on_next_button_pressed):
			next_button.pressed.disconnect(_on_next_button_pressed)
		if not next_button.pressed.is_connected(_on_finish_button_pressed):
			next_button.pressed.connect(_on_finish_button_pressed)
	else:
		back_button.disabled = false
		next_button.disabled = false
		next_button.text = "Next"
		if next_button.pressed.is_connected(_on_finish_button_pressed):
			next_button.pressed.disconnect(_on_finish_button_pressed)
		if not next_button.pressed.is_connected(_on_next_button_pressed):
			next_button.pressed.connect(_on_next_button_pressed)

func _initialize_shop() -> void:
	shop_list.clear()
	equipped_list.clear()

	for armors in Cache.loaded_armors:
		var armor = Cache.loaded_armors[armors]
		if armor.get_price_in_copper() > _current_copper or armor.get_level() > 0:
			continue
		shop_list.add_item(armor.get_resource_name())
		shop_list.set_item_metadata(shop_list.get_item_count() - 1, armor)

	# add items and weapons to the shop
	for weapons in Cache.loaded_weapons:
		var weapon = Cache.loaded_weapons[weapons]
		if weapon.get_price_in_copper() > _current_copper or weapon.get_level() > 0:
			continue
		shop_list.add_item(weapon.get_resource_name())
		shop_list.set_item_metadata(shop_list.get_item_count() - 1, weapon)

func _initialize_summary() -> void:
	character_sheet.initialize_from_dict(default_character_values)
	character_sheet.initialize_runtime_state()
	var sheet_data: Dictionary = character_sheet.get_full_sheet_as_dictionary()

	var summary_text := "" # Use type inference

	# --- Keys to explicitly skip ---
	var keys_to_skip := [
		"current_hit_points", "current_temporary_hit_points",
		"current_aether_points", "current_stamina_points",
		"current_mythic_points", "current_hero_points",
		"current_actions_available", "current_bonus_actions_available",
		"current_reactions_available", "current_armor_class",
		"current_speed", "current_movement_state", "current_class_dc",
		"current_weight_carried", "current_conditions", "active_effects",
		"base_swim_speed", "base_fly_speed", "base_climb_speed",
		"base_burrow_speed", "max_actions", "max_bonus_actions", "max_reactions",
		"base_class_dc", "experience_points", "equipped_items", "base_ac", "main_strike_action", "off_hand_strike_action",
		# Add any other runtime state keys you want to exclude
	]

	# --- Define the desired order for key sections ---
	var ordered_keys := [
		"character_name",
		"character_class", # Renamed to "Class" below
		"archetype",
		"species",
		"affinity",
		"lineage",
		"level",
		"age",
		"gender",
		"height",
		"weight",
		"tenets",
		"taboos",
		"size", # Will use get_monster_size_as_string
		"base_speed", # Renamed to "Speed" below
		"max_hit_points",
		"max_aether_points", # Keep or remove as needed
		"max_stamina_points",# Keep or remove as needed
		"max_mythic_points", # Keep or remove as needed
		"max_hero_points",   # Keep or remove as needed
		"might_modifier", "agility_modifier", "endurance_modifier", # Add other stats/modifiers
		"intelligence_modifier", "insight_modifier", "charisma_modifier", "perception_modifier",
		"might_saving_throw", "agility_saving_throw", "endurance_saving_throw", # Add other saves
		"intelligence_saving_throw", "insight_saving_throw", "charisma_saving_throw",
		"base_armor_class", # Keep or remove as needed
		"max_carrying_capacity",
		"skills",
		"perks",
		"spells_known",
		"traits",
		"talents",
		"languages",
		"weapon_proficiency",
		"armor_proficiency",
		"extra_proficiencies",
		"inventory",
		"formulas",
		"current_currency", # Keep currency
		# Add any other keys you want in a specific order
	]

	var processed_keys = [] # Keep track of keys already added

	for key in ordered_keys:
		if sheet_data.has(key) and not key in keys_to_skip:
			if not summary_text.is_empty(): # Add separator before the next entry
				summary_text += SEPARATOR
			summary_text += format_entry(key, sheet_data[key])
			processed_keys.append(key)

	# Process Remaining Keys
	for key in sheet_data.keys():
		if not key in processed_keys and not key in keys_to_skip:
			if not summary_text.is_empty(): # Add separator before the next entry
				summary_text += SEPARATOR
			summary_text += format_entry(key, sheet_data[key])
			# No need to add to processed_keys here

	# --- Update the RichTextLabel ---
	if summary_desc:
		summary_desc.bbcode_enabled = true
		summary_desc.text = summary_text
		# Optional: Clear selection if needed after updating
		# summary_desc.deselect()
	else:
		printerr("Error: summary_desc RichTextLabel node not found or not assigned.")

	# Print raw text (BBCode won't render here) for debugging if needed
	# print("--- Generated Summary (Raw Text) ---")
	# print(summary_text)
	# print("------------------------------------")

	# Optional: Update default_character_values if needed elsewhere
	# default_character_values = sheet_data

func _initialize_basic_info() -> void:
	character_height.min_value = GameConst.get_height_constraints_from_size(_selected_species.get_size()).min
	character_height.max_value = GameConst.get_height_constraints_from_size(_selected_species.get_size()).max
	character_weight.min_value = GameConst.get_weight_constraints_from_size(_selected_species.get_size()).min
	character_weight.max_value = GameConst.get_weight_constraints_from_size(_selected_species.get_size()).max

func _initialize_background() -> void:
	for specie in Cache.loaded_species:
		species_options.add_item(Cache.loaded_species[specie].get_resource_name())
		species_options.set_item_metadata(species_options.get_item_count() - 1, Cache.loaded_species[specie])
	species_options.select(0)
	_on_species_selected(0)

	for affinity in Cache.loaded_affinities:
		affinity_options.add_item(Cache.loaded_affinities[affinity].get_resource_name())
		affinity_options.set_item_metadata(affinity_options.get_item_count() - 1, Cache.loaded_affinities[affinity])
	affinity_options.select(0)
	_on_affinity_selected(0)

func _initialize_species(specie: SpecieResource) -> void:
	if specie == null:
		return

	species_desc.text = specie.get_description()
	species_hp.text = str(specie.get_hit_points())
	species_sp.text = str(specie.get_stamina_points())
	species_size.text = specie.get_size_as_string()
	species_speed.text = str(specie.get_speed())
	species_languages.text = str(specie.get_base_languages())

func _initialize_lineage(lineage: LineageResource) -> void:
	if lineage == null:
		return

	lineage_desc.text = lineage.get_description()

func _initialize_affinity(affinity: AffinityResource) -> void:
	if affinity == null:
		return

	affinity_desc.text = affinity.get_description()
	affinity_forced_attributes.text = str(affinity.get_forced_attributes())
	affinity_free_attributes.text = "Any"
	affinity_skills.text = str(affinity.get_skill_names())
	affinity_perks.text = str(affinity.get_perk_names())

func _initialize_modifiers() -> void:
	character_forced_attributes_desc.text = str(_selected_affinity.get_forced_attributes()[0]) + " or " + str(_selected_affinity.get_forced_attributes()[1])
	_current_forced_attribute_names = _selected_affinity.get_forced_attributes()
	_total_attribute_boosts += _selected_affinity.get_free_attributes()

	_current_attribute_boosts = _total_attribute_boosts
	_current_forced_attribute_boosts = _total_forced_attribute_boosts

	character_forced_attributes.text = str(_current_forced_attribute_boosts) + " / " + str(_total_forced_attribute_boosts)
	character_free_attributes.text = str(_current_attribute_boosts) + " / " + str(_total_attribute_boosts)

func _update_modifiers() -> void:
	character_forced_attributes.text = str(_current_forced_attribute_boosts) + " / " + str(_total_forced_attribute_boosts)
	character_free_attributes.text = str(_current_attribute_boosts) + " / " + str(_total_attribute_boosts)

func _update_character_sheet() -> void:
	if _selected_species != null:
		default_character_values["species"] = _selected_species.get_resource_name()
		default_character_values["size"] = _selected_species.get_size()
		default_character_values["base_speed"] = _selected_species.get_speed()
		default_character_values["traits"] = _selected_species.get_trait_names()
		default_character_values["perks"] = _selected_species.get_perk_names()
	if _selected_affinity != null:
		default_character_values["affinity"] = _selected_affinity.get_resource_name()
		default_character_values["perks"] += _selected_affinity.get_perk_names()
		default_character_values["traits"] += _selected_affinity.get_trait_names()
		var all_skills = {}
		for skill in Cache.loaded_skills:
			all_skills[skill] = Cache.loaded_skills[skill].get_proficiency_rank()
			print(skill)

		for skill in _selected_affinity.get_skills():
			for i in all_skills.keys():
				if i == skill.get_resource_name():
					all_skills[i] = skill.get_proficiency_rank()

		default_character_values["skills"] = all_skills
	if _selected_lineage != null:
		default_character_values["lineage"] = _selected_lineage.get_resource_name()
		default_character_values["perks"] += _selected_lineage.get_perk_names()

	var weapon_proficiencies = {}
	for w in Cache.get_all_weapon_proficiencies():
		weapon_proficiencies[w.get_resource_name()] = w.get_proficiency()

	var armor_proficiencies = {}
	for a in Cache.get_all_armor_proficiencies():
		armor_proficiencies[a.get_resource_name()] = a.get_proficiency()

	default_character_values["weapon_proficiency"] = weapon_proficiencies
	default_character_values["armor_proficiency"] = armor_proficiencies
	default_character_values["current_currency"] = Helper.format_currency(_current_copper, "Copper")
	var equipped_items = []
	for item in equipped_list.item_count:
		var item_name = equipped_list.get_item_text(item)
		equipped_items.append(item_name)
	
	default_character_values["inventory"] = equipped_items
	print(default_character_values)
	character_sheet.initialize_from_dict(default_character_values)

func update_copper(value: int) -> void:
	_current_copper += value
	copper_control.text = str(_current_copper)
	call_deferred("_update_character_sheet")

# --- Helpers ---

func _trait_exists(trait_name: String) -> bool:
	for traitt in default_character_values["traits"]:
		if traitt.get_resource_name() == trait_name:
			return true
	return false

func _perk_exists(perk_name: String) -> bool:
	for perk in default_character_values["perks"]:
		if perk.get_resource_name() == perk_name:
			return true
	return false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		character_sheet.free()
func format_entry(key, value) -> String:
	var display_key = str(key)

	# --- Key Renaming & Formatting ---
	if key == "base_speed": display_key = "Speed"
	elif key == "character_class": display_key = "Class"
	# Add other renames...

	var colored_key = "[color=#cf9b76]" + display_key.capitalize().replace("_", " ") + ":[/color]"
	var formatted_value_part = "" # Just the value part, will add \n and indent later

	# --- Value Formatting ---
	if key == "skills" and value is Array:
		if value.is_empty():
			formatted_value_part = INDENT + "None"
		else:
			var items_str = ""
			for item in value:
				var name = ""
				var rank = ""
				if item is Resource and item.has_method("get_resource_name"):
					name = item.get_resource_name().capitalize()
					print(name)
					if item.has_method("get_proficiency_rank_as_string"):
						rank = ": " + str(item.get_proficiency_rank_as_string())
					else:
						print("Warning: Item does not have proficiency rank method.")
				else:
					name = _format_display_value(item) # Fallback for non-resource items

				items_str += INDENT + "- " + name + rank + "\n" # Indent each item
			formatted_value_part = items_str.strip_edges(false, true) # Remove only trailing newline
	elif key == "weapon_proficiency":
		if value.is_empty():
			formatted_value_part = INDENT + "None"
		else:
			var items_str = ""
			for item in value:
				var name = ""
				var rank = ""
				if item is Resource and item.has_method("get_resource_name"):
					name = item.get_resource_name().capitalize()
					print(name)
					if item.has_method("get_proficiency_as_string"):
						rank = ": " + str(item.get_proficiency_as_string())
					else:
						print("Warning: Item does not have proficiency rank method.")
				else:
					name = _format_display_value(item) # Fallback for non-resource items

				items_str += INDENT + "- " + name + rank + "\n" # Indent each item
			formatted_value_part = items_str.strip_edges(false, true) # Remove only trailing newline
	elif key == "armor_proficiency":
		if value.is_empty():
			formatted_value_part = INDENT + "None"
		else:
			var items_str = ""
			for item in value:
				var name = ""
				var rank = ""
				if item is Resource and item.has_method("get_resource_name"):
					name = item.get_resource_name().capitalize()
					print(name)
					if item.has_method("get_proficiency_as_string"):
						rank = ": " + str(item.get_proficiency_as_string())
					else:
						print("Warning: Item does not have proficiency rank method.")
				else:
					name = _format_display_value(item) # Fallback for non-resource items

				items_str += INDENT + "- " + name + rank + "\n" # Indent each item
			formatted_value_part = items_str.strip_edges(false, true) # Remove only trailing newline

	elif key == "character_name":
		formatted_value_part = INDENT + value.capitalize() # Add indent

	elif key == "might_modifier" or key == "agility_modifier" or key == "intelligence_modifier" or key == "endurance_modifier" or key == "insight_modifier" or key == "charisma_modifier":
		formatted_value_part = INDENT + "+" + str(value) # Add indent

	elif key == "max_hit_points" or key == "max_aether_points" or key == "max_stamina_points" or key == "max_mythic_points" or key == "max_hero_points":
		formatted_value_part = INDENT + str(value) # Add indent

	elif key == "current_hit_points" or key == "current_aether_points" or key == "current_stamina_points" or key == "current_mythic_points" or key == "current_hero_points":
		formatted_value_part = INDENT + str(value) # Add indent

	elif key == "level":
		formatted_value_part = INDENT + str(value) # Add indent

	elif key == "might_saving_throw" or key == "agility_saving_throw" or key == "intelligence_saving_throw" or key == "endurance_saving_throw" or key == "insight_saving_throw" or key == "charisma_saving_throw":
		formatted_value_part = INDENT + "+" + str(value) # Add indent

	elif key == "base_armor_class":
		formatted_value_part = INDENT + str(value) # Add indent

	elif key == "max_carrying_capacity":
		formatted_value_part = INDENT + str(value) # Add indent


	elif key == "height" and value is float:
		formatted_value_part = INDENT + ("%.1f" % value) # Add indent

	elif key == "size":
		formatted_value_part = INDENT + GameConst.get_monster_size_as_string(value) # Add indent

	elif key == "current_currency" and value is Dictionary:
		if value.is_empty():
			formatted_value_part = INDENT + "None"
		else:
			var currency_parts = []
			var currency_order = GameConst.CURRENCY_ORDER # Define the order of currency types
			for currency_type in currency_order:
				if value.has(currency_type):
					currency_parts.append(str(currency_type).capitalize() + ": " + str(value[currency_type]))
			for currency_type in value.keys():
				if not currency_type in currency_order and value.has(currency_type): # Check has() again
					currency_parts.append(str(currency_type).capitalize() + ": " + str(value[currency_type]))
			formatted_value_part = INDENT + ", ".join(currency_parts) # Add indent

	elif value is Dictionary:
		if value.is_empty():
			formatted_value_part = INDENT + "None"
		else:
			var items_str = ""
			for item_key in value.keys():
				var item_value_str = _format_display_value(value[item_key])
				items_str += INDENT + str(item_key).capitalize().replace("_", " ") + ": " + item_value_str + "\n" # Indent each item
			formatted_value_part = items_str.strip_edges(false, true) # Remove only trailing newline

	elif value is Array: # General Array (Perks, Traits, Languages etc.)
		if value.is_empty():
			formatted_value_part = INDENT + "None"
		else:
			var items_str = ""
			for item in value:
				items_str += INDENT + "- " + _format_display_value(item) + "\n" # Indent each item with '-'
			formatted_value_part = items_str.strip_edges(false, true) # Remove only trailing newline

	# --- Default Cases for single values (add indent) ---
	elif value is Resource and value.has_method("get_resource_name"):
		formatted_value_part = INDENT + value.get_resource_name().capitalize()
	elif value == null:
		formatted_value_part = INDENT + "None"
	elif value is int or value is float: # Handled height above, this is for others
		formatted_value_part = INDENT + str(value)
	elif value is String:
		print("String value: ", value)
		formatted_value_part = INDENT + (value.capitalize() if not value.is_empty() else "")
	else:
		formatted_value_part = INDENT + str(value).capitalize() # Default fallback

	# --- Combine Key and Value with Newline ---
	return colored_key + "\n" + formatted_value_part

func _format_display_value(item_value) -> String:
	if item_value is Resource and item_value.has_method("get_resource_name"):
		return item_value.get_resource_name().capitalize()
	elif item_value == null:
		return "None"
	elif item_value is float: # General float formatting (adjust precision if needed)
		return str(item_value) # Or specific formatting like "%.2f" % item_value
	elif item_value is int:
		return str(item_value)
	elif item_value is String:
		return item_value.capitalize() if not item_value.is_empty() else ""
	else:
		return str(item_value).capitalize() # Default fallback
