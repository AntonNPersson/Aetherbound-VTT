extends Control
var all_combatants = []
var owned_combatants = []
var combat_id = 0
var current_combatant = null

func _initialize(all, owned) -> void:
	Bus.add_comtatants_to_tracker.connect(func(comb): add_combatants.rpc(comb))
	all_combatants = all
	owned_combatants = owned
	add_to_group("CombatTracker")

func next_round(rnd: int) -> void:
	get_child(0).get_node("Topbar").get_node("Title").text = "Round " + str(rnd)

@rpc("any_peer", "call_local", "reliable")
func add_combatants(combatants: Array) -> void:
	combatants = _get_combantant_instances(combatants)
	for i in combatants:
		get_child(0).get_node("ItemList").add_item(i.character_sheet.get_unit_name(), i.get_node("Sprite2D").texture, false)

func end_turn() -> void:
	Bus.end_turn.emit(current_combatant)

# Type is what type of end it is (Victory, Defeat, etc)
func end_combat(type: String) -> void:
	Bus.end_combat.emit(combat_id, type)

func _get_combantant_instances(combatants: Array) -> Array:
	var instances = []
	for combatant in combatants:
		for t in get_tree().get_nodes_in_group("token"):
			if combatant == t.name:
				instances.append(t)
	return instances
