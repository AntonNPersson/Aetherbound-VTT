extends Control
var all_combatants = []
var owned_combatants = []
var combat_id = 0
var current_combatant = null

func _initialize(all, owned, id) -> void:
	Bus.add_comtatants_to_tracker.connect(func(comb, id): add_combatants.rpc(comb, id))
	Bus.turn_started.connect(func(current, id): _on_turn_started.rpc(current, id))
	Bus.remove_combat_tracker.connect(remove_combat_tracker)
	get_child(0).get_node("BotBar").get_node("Title").pressed.connect(func(): end_turn.rpc_id(1))
	%ExitCombat.disabled = !Net.is_host()
	%ExitCombat.pressed.connect(func(): WindowFactory.create_safety_message(self, "Are you sure you want to end combat?", end_combat.bind("Victory")))
	all_combatants = all
	owned_combatants = owned
	combat_id = id
	add_to_group("CombatTracker")

func next_round(rnd: int) -> void:
	get_child(0).get_node("Topbar").get_node("Title").text = "Round " + str(rnd)

@rpc("any_peer", "call_local", "reliable")
func add_combatants(combatants: Array, id: int) -> void:
	if combat_id != id:
		print("Combat ID mismatch. Expected: " + str(combat_id) + ", Received: " + str(id))
		return

	get_child(0).get_node("BotBar").get_node("Title").disabled = true
	get_child(0).get_node("ItemList").clear()
	combatants = _get_combantant_instances(combatants)
	for i in combatants:
		get_child(0).get_node("ItemList").add_item(i.character_sheet.get_unit_name(), i.get_node("Sprite2D").texture, false)

@rpc("any_peer", "call_local", "reliable")
func end_turn() -> void:
	print("Ending turn for combatant: " + current_combatant.name)
	print("Combat ID: " + str(combat_id))
	Bus.end_turn.emit(combat_id)

# Type is what type of end it is (Victory, Defeat, etc)
func end_combat(type: String) -> void:
	print("Ending combat with type: " + type)
	print("Combat ID: " + str(combat_id))
	Bus.end_combat.emit(combat_id, type)

@rpc("any_peer", "call_local", "reliable")
func _on_turn_started(current_comb: Variant, id: int) -> void:
	if combat_id != id:
		print("Combat ID mismatch. Expected: " + str(combat_id) + ", Received: " + str(id))
		return
		
	current_combatant = _get_combantant_instances([current_comb])[0]

	if current_combatant == null:
		print("Error: No combatant in turn order.")
		return
	
	if owned_combatants.size() == 0:
		print("Error: No owned combatants.")
		return

	if current_combatant in owned_combatants:
		print("Combatant is owned by player.")
		_set_end_turn_button_state(false)
	else:
		print("Combatant is not owned by player.")
		_set_end_turn_button_state(true)

func remove_combat_tracker(combat_id: int) -> void:
	print("Removing combat tracker")
	if combat_id != self.combat_id:
		return
	queue_free()

# Helper
func _get_combantant_instances(combatants: Array) -> Array:
	var instances = []
	for combatant in combatants:
		for t in get_tree().get_nodes_in_group("token"):
			if combatant == t.name:
				instances.append(t)
	return instances

func _set_end_turn_button_state(state: bool) -> void:
	get_child(0).get_node("BotBar").get_node("Title").disabled = state
