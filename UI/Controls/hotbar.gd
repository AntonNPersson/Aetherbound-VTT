extends Node

# --- UI Elements ---
@onready var hotbar = %Hotbar
@onready var strikes_button = hotbar.get_node("StrikesButton") # Assuming this toggles the strikes panel visibility
@onready var strikes_panel = %Strikes # Renamed for clarity
@onready var main_hand_button = strikes_panel.get_node("Container/Main") # Renamed for clarity
@onready var off_hand_button = strikes_panel.get_node("Container/Off") # Renamed for clarity

# --- State Variables ---
# Static Attack Data (Set once per weapon/attack type)
var _main_hand_attack: AttackResource = null
var _off_hand_attack: AttackResource = null

# Dynamic Context (Updated as game state changes)
var _current_character: Resource = null
var _current_target: Resource = null
var _current_distance_to_target: int = 0
var _current_in_combat: bool = false
var execute_parameters: Dictionary = {"Hit": 0,
										"Damage": 0,
										"versatile_type": -1,
										"map": 0} # This could be a more complex structure if needed
# Add other relevant context variables if needed

# --- Initialization ---
func _ready() -> void:
	# Connect signals ONCE
	if strikes_button:
		strikes_button.toggled.connect(_on_strikes_button_toggled)

	if main_hand_button:
		main_hand_button.pressed.connect(_on_main_hand_button_pressed)
		# Initially disable if no attack is set
		main_hand_button.disabled = true

	if off_hand_button:
		off_hand_button.pressed.connect(_on_off_hand_button_pressed)
		# Initially disable if no attack is set
		off_hand_button.disabled = true

	# Hide panels initially if desired
	if strikes_panel:
		strikes_panel.hide()

	Bus.equip_main_hand_attack.connect(set_main_hand_attack)
	Bus.equip_off_hand_attack.connect(set_off_hand_attack)


# --- Public API for Updating Context ---

# Call this when the equipped main-hand attack changes
func set_main_hand_attack(attack: AttackResource) -> void:
	_main_hand_attack = attack
	if is_instance_valid(main_hand_button):
		if is_instance_valid(attack):
			main_hand_button.text = attack.get_resource_name()
			main_hand_button.tooltip_text = str(attack.get_dictionary()) # Consider a nicer tooltip format
			main_hand_button.disabled = false # Enable if valid attack
		else:
			main_hand_button.text = "Main Hand" # Default text
			main_hand_button.tooltip_text = ""
			main_hand_button.disabled = true # Disable if no attack
	_update_button_states() # Check context validity

# Call this when the equipped off-hand attack changes
func set_off_hand_attack(attack: AttackResource) -> void:
	_off_hand_attack = attack
	if is_instance_valid(off_hand_button):
		if is_instance_valid(attack):
			off_hand_button.text = attack.get_resource_name()
			off_hand_button.tooltip_text = str(attack.get_dictionary()) # Consider a nicer tooltip format
			off_hand_button.disabled = false # Enable if valid attack
		else:
			off_hand_button.text = "Off Hand" # Default text
			off_hand_button.tooltip_text = ""
			off_hand_button.disabled = true # Disable if no attack
	_update_button_states() # Check context validity


# Call this WHENEVER the combat context changes (new target, movement, entering/exiting combat)
func update_strike_context(character: Resource, target: Resource, distance: int, in_combat: bool, execute_parameters: Dictionary) -> void:
	# Add validation if necessary
	_current_character = character
	_current_target = target
	_current_distance_to_target = distance
	_current_in_combat = in_combat
	self.execute_parameters = execute_parameters # Update context for execution

	# Update button enable/disable state based on new context
	_update_button_states()


# --- Internal Logic ---

# Update button disabled state based on current context
func _update_button_states() -> void:
	if is_instance_valid(main_hand_button) and is_instance_valid(_main_hand_attack):
		var can_attack_main = _can_execute_strike(_main_hand_attack)
		main_hand_button.disabled = not can_attack_main
		# You could change tooltip here too, e.g., add "Out of range"
		if not can_attack_main:
			main_hand_button.tooltip_text = _get_disabled_reason(_main_hand_attack)
		elif is_instance_valid(_main_hand_attack):
			main_hand_button.tooltip_text = str(_main_hand_attack.get_dictionary()) # Reset tooltip

	if is_instance_valid(off_hand_button) and is_instance_valid(_off_hand_attack):
		var can_attack_off = _can_execute_strike(_off_hand_attack)
		off_hand_button.disabled = not can_attack_off
		if not can_attack_off:
			off_hand_button.tooltip_text = _get_disabled_reason(_off_hand_attack)
		elif is_instance_valid(_off_hand_attack):
			off_hand_button.tooltip_text = str(_off_hand_attack.get_dictionary()) # Reset tooltip


# Helper to check if an attack is currently possible
func _can_execute_strike(attack: AttackResource) -> bool:
	if not is_instance_valid(attack): return false
	if not is_instance_valid(_current_character): return false # Need attacker
	if not is_instance_valid(_current_target): return false # Need target
	if not _current_in_combat: return false # Must be in combat
	if _current_distance_to_target > attack.range: return false # Must be in range
	# Add any other conditions (e.g., ammo, status effects)
	return true

# Helper to generate tooltip reason for disabled button
func _get_disabled_reason(attack: AttackResource) -> String:
	if not is_instance_valid(attack): return "No attack equipped"
	if not is_instance_valid(_current_character): return "Invalid character"
	if not is_instance_valid(_current_target): return "No target selected"
	if not _current_in_combat: return "Not in combat"
	if _current_distance_to_target > attack.range: return "Target out of range (%d / %d)" % [_current_distance_to_target, attack.range]
	return "Attack not possible" # Generic fallback


# --- Signal Handlers ---

func _on_strikes_button_toggled(toggled: bool) -> void:
	if is_instance_valid(strikes_panel):
		strikes_panel.visible = toggled
		# Maybe update context/button states when panel is shown?
		# if toggled:
		#     _update_button_states()


func _on_main_hand_button_pressed() -> void:
	# Execute using the currently stored context and attack resource
	if _can_execute_strike(_main_hand_attack):
		print("Executing Main Hand Strike!") # Debug
		if execute_parameters.has("hit") and execute_parameters.has("damage") and execute_parameters.has("versatile_type") and execute_parameters.has("map"): # Example check
			_execute_strike(_main_hand_attack)
		else:
			printerr("Missing execute parameters for main hand attack.")
			# Maybe open a dice roll dialog or get parameters?
	else:
		# This shouldn't happen if the button is correctly disabled, but good failsafe
		ErrorUtility.print_error("Cannot execute main hand strike: %s" % _get_disabled_reason(_main_hand_attack))


func _on_off_hand_button_pressed() -> void:
	# Execute using the currently stored context and attack resource
	if _can_execute_strike(_off_hand_attack):
		print("Executing Off Hand Strike!") # Debug
		if execute_parameters.has("hit") and execute_parameters.has("damage") and execute_parameters.has("versatile_type") and execute_parameters.has("map"): # Example check
			_execute_strike(_off_hand_attack)
		else:
			printerr("Missing execute parameters for off hand attack.")
	else:
		ErrorUtility.print_error("Cannot execute off hand strike: %s" % _get_disabled_reason(_off_hand_attack))


# --- Unified Execution Logic --- (Optional Refactor)

# Unified function to execute any strike, called by signal handlers
func _execute_strike(attack: AttackResource) -> void:
	# Basic validation (most checks done in _can_execute_strike before calling)
	if not is_instance_valid(attack) \
	or not is_instance_valid(_current_character) \
	or not is_instance_valid(_current_target):
		ErrorUtility.print_error("Invalid state during strike execution.")
		return

	# We already know we are in range and in combat due to _can_execute_strike check
	print("Executing %s on %s" % [attack.get_resource_name(), _current_target.name]) # Example debug

	# Call the attack resource's execution method
	# Assuming execute_parameters are complete at this point
	if execute_parameters.has("hit") and execute_parameters.has("damage") and execute_parameters.has("versatile_type") and execute_parameters.has("map"):
		attack.execute(_current_character, _current_target, execute_parameters)
	else:
		# This check might be redundant if already done in the caller
		printerr("Incomplete execute_parameters passed to _execute_strike.")
		return
