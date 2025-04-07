extends Node
var dice: DiceManager
var combatants_order: Dictionary = {}
var current_combatant_index: Dictionary = {}

func _ready() -> void:
	Bus.initialize_turn_order.connect(initialize_turn_order)
	Bus.remove_combat_turns.connect(remove_combat)
	Bus.end_turn.connect(end_turn)

func initialize_turn_order(combat_id: int, combatants: Array) -> void:
	# Initialize the turn order with the given combat ID and combatants
	# This function should be called when starting a new combat encounter
	# or when resetting the turn order for any reason.
	print("Initializing turn order for combat ID: ", combat_id)

	dice = DiceManager.new()
	combatants = _get_combantant_instances(combatants)

	current_combatant_index[combat_id] = 0  # Reset the current combatant
	combatants_order[combat_id] = []  # Initialize the combat ID entry

	for combatant in combatants:
		var roll = dice.roll("1d20 + " + str(combatant.character_sheet.perception_modifier))
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

			var a_mod = a_sheet.get_unit_agility_modifier() if a_sheet else 0
			var b_mod = b_sheet.get_unit_agility_modifier() if b_sheet else 0
			if a_mod > b_mod:
				return true
			if a_mod < b_mod:
				return false

			return a["combatant"].name < b["combatant"].name
	)
	var combatants_instances = []
	for i in range(combatants_order[combat_id].size()):
		combatants_instances.append(combatants_order[combat_id][i]["combatant"].name)
	Bus.add_comtatants_to_tracker.emit(combatants_instances, combat_id)
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
	print("Ending turn for combatant: ", combatants_order[combat_id][current_combatant_index[combat_id]]["combatant"].name)
	print("Combat ID: ", combat_id)
	if combatants_order.is_empty():
		print("Error: No combatants in turn order.")
		return

	# Deactivate the current combatant
	var current_combatant = combatants_order[combat_id][current_combatant_index[combat_id]]["combatant"]
	#current_combatant.deactivate() # Call a function to deactive the combatant, needs to be implemented in the combatant class

	# Increment the current combatant index, wrapping around to the beginning
	current_combatant_index[combat_id] = (current_combatant_index[combat_id] + 1) % combatants_order[combat_id].size()

	var new_tracker_order = _get_reordered_combatants(combat_id)
	Bus.add_comtatants_to_tracker.emit(new_tracker_order, combat_id)

	start_turn(combat_id)  # Start the next turn

func start_turn(combat_id) -> void:
	# Starts the turn of the current combatant.
	if combatants_order.is_empty():
		print("Error: No combatants in turn order.")
		return

	var current_combatant = combatants_order[combat_id][current_combatant_index[combat_id]]["combatant"]
	print("Starting turn for: ", current_combatant.name)
	#current_combatant.activate() # Call a function to active the combatant, needs to be implemented in the combatant class

	if current_combatant.has_meta("summoner"):
		# If the combatant is a summon, get its summoner
		current_combatant = current_combatant.get_meta("summoner")

	Bus.turn_started.emit(current_combatant.name, combat_id)

	# Add any turn start effects or logic here (e.g., regenerating mana, etc.)

# Helper
func _get_reordered_combatants(combat_id) -> Array:
	"""
	Creates a new array of combatant nodes, ordered starting from the
	combatant whose turn is NEXT (based on current_combatant_index).
	Does NOT modify the internal combatants_order array or index.
	"""
	if not combatants_order.has(combat_id) or combatants_order[combat_id].is_empty():
		printerr("Error: Combat ID '%s' not found or empty in get_reordered_combatants_for_tracker." % combat_id)
		return [] # Return empty array on error

	var original_order_dicts : Array = combatants_order[combat_id]
	var count : int = original_order_dicts.size()

	# current_combatant_index NOW points to the combatant whose turn is starting
	var start_index : int = current_combatant_index[combat_id]

	if start_index < 0 or start_index >= count:
		printerr("Error: Invalid current_combatant_index (%d) for order size (%d)" % [start_index, count])
		return [] # Return empty array on error

	var reordered_combatants : Array = []
	reordered_combatants.resize(count) # Pre-allocate size for efficiency

	var added_count = 0
	# Loop from the next combatant to the end of the list
	for i in range(start_index, count):
		if original_order_dicts[i].has("combatant"):
			reordered_combatants[added_count] = original_order_dicts[i]["combatant"].name
			added_count += 1
		else:
			printerr("Missing 'combatant' key in entry at index: ", i)


	# Loop from the beginning of the list up to the next combatant
	for i in range(0, start_index):
		if original_order_dicts[i].has("combatant"):
			reordered_combatants[added_count] = original_order_dicts[i]["combatant"].name
			added_count += 1
		else:
			printerr("Missing 'combatant' key in entry at index: ", i)
	
	# If some entries were missing the "combatant" key, resize down
	if added_count != count:
		reordered_combatants.resize(added_count)

	return reordered_combatants

func remove_combat(combat_id) -> void:
	# Remove the combat ID from the combatants_order dictionary
	if combatants_order.has(combat_id):
		combatants_order.erase(combat_id)
		print("Combat ID %d removed from turn order." % combat_id)
	else:
		print("Combat ID %d not found in turn order." % combat_id)
	
	if current_combatant_index.has(combat_id):
		current_combatant_index.erase(combat_id)
		print("Combat ID %d removed from current combatant index." % combat_id)
	else:
		print("Combat ID %d not found in current combatant index." % combat_id)
