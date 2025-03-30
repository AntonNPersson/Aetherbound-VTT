extends Node
var dice: DiceManager
var combatants_order: Array = []
# Make it a dictionary so i can keep track of different combat sessions

func _ready() -> void:
	Bus.initialize_turn_order.connect(initialize_turn_order)

func initialize_turn_order(combat_id: int, combatants: Array) -> void:
	# Initialize the turn order with the given combat ID and combatants
	# This function should be called when starting a new combat encounter
	# or when resetting the turn order for any reason.
	dice = DiceManager.new()
	combatants = _get_combantant_instances(combatants)

	for combatant in combatants:
		var roll = dice.roll("1d20 + " + str(combatant.character_sheet.perception_score))
		Bus.send_roll_to_all.emit(combatant.character_sheet.get_unit_name(), "rolls for", "Initiative", roll, "", "")
		combatants_order.append({"combatant": combatant, "roll": roll["total"]})
	
	combatants_order.sort_custom(
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
	for i in range(combatants_order.size()):
		combatants_instances.append(combatants_order[i]["combatant"].name)
	Bus.add_comtatants_to_tracker.emit(combatants_instances)

func _get_combantant_instances(combatants: Array) -> Array:
	var instances = []
	for combatant in combatants:
		for t in get_tree().get_nodes_in_group("token"):
			if combatant == t.name:
				instances.append(t)
	return instances
