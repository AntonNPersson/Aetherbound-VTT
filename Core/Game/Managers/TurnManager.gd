extends Node
var dice: DiceManager
var combatants_order: Dictionary = {}
var current_combatant_index: int = 0

func _ready() -> void:
	Bus.initialize_turn_order.connect(initialize_turn_order)
	Bus.end_turn.connect(end_turn)

func initialize_turn_order(combat_id: int, combatants: Array) -> void:
	# Initialize the turn order with the given combat ID and combatants
	# This function should be called when starting a new combat encounter
	# or when resetting the turn order for any reason.
	dice = DiceManager.new()
	combatants = _get_combantant_instances(combatants)

	combatants_order.clear()  # Clear any existing turn order
	current_combatant_index = 0  # Reset the current combatant
	combatants_order[combat_id] = []  # Initialize the combat ID entry

	for combatant in combatants:
		var roll = dice.roll("1d20 + " + str(combatant.character_sheet.perception_score))
		Bus.send_roll_to_all.emit(combatant.character_sheet.get_unit_name(), "rolls for", "Initiative", roll, "", "")
		combatants_order[combat_id].append({"combatant": combatant, "roll": roll["total"]})
	
	combatants_order[combat_id].sort_custom(
		func(a, b):
			if a["roll"] > b["roll"]:
				return true
			if a["roll"] < b["roll"]:
				return false

			var a_sheet = a["combatant"].character_sheet if a["combatant"].character_sheet else null
			var b_sheet = b["combatant"].character_sheet if b["combatant"].character_sheet else null

			var a_mod = a_sheet.get_agility_modifier() if a_sheet else 0
			var b_mod = b_sheet.get_agility_modifier() if b_sheet else 0
			if a_mod > b_mod:
				return true
			if a_mod < b_mod:
				return false

			return a["combatant"].name < b["combatant"].name
	)
	var combatants_instances = []
	for i in range(combatants_order[combat_id].size()):
		combatants_instances.append(combatants_order[combat_id][i]["combatant"].name)
	Bus.add_comtatants_to_tracker.emit(combatants_instances)
	start_turn(combat_id)  # Start the first turn after initializing

func _get_combantant_instances(combatants: Array) -> Array:
	var instances = []
	for combatant in combatants:
		for t in get_tree().get_nodes_in_group("token"):
			if combatant == t.name:
				instances.append(t)
	return instances

func end_turn(combat_id) -> void:
	# End the current combatant's turn and start the next one.
	if combatants_order.is_empty():
		print("Error: No combatants in turn order.")
		return

	# Deactivate the current combatant
	var current_combatant = combatants_order[combat_id][current_combatant_index]["combatant"]
	#current_combatant.deactivate() # Call a function to deactive the combatant, needs to be implemented in the combatant class

	# Increment the current combatant index, wrapping around to the beginning
	current_combatant_index = (current_combatant_index + 1) % combatants_order[combat_id].size()

	start_turn(combat_id)  # Start the next turn

func start_turn(combat_id) -> void:
	# Starts the turn of the current combatant.
	if combatants_order.is_empty():
		print("Error: No combatants in turn order.")
		return

	var current_combatant = combatants_order[combat_id][current_combatant_index]["combatant"]
	print("Starting turn for: ", current_combatant.name)
	#current_combatant.activate() # Call a function to active the combatant, needs to be implemented in the combatant class

	if current_combatant.has_meta("summoner"):
		# If the combatant is a summon, get its summoner
		current_combatant = current_combatant.get_meta("summoner")

	Bus.turn_started.emit(current_combatant.name)

	# Add any turn start effects or logic here (e.g., regenerating mana, etc.)

# Helper
func move_first_to_last(array: Array) -> void:
	if array.size() > 1:  # Only move if there's more than one element
		array.append(array.pop_front()) # pop front() removes the element, and returns it to append