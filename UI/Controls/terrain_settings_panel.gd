extends Node

func connect_signals(terrain: Resource) -> void:
	var child = get_child(0)
	child.get_node("Multiplier").value = terrain.cost_multiplier
	child.get_node("Multiplier").value_changed.connect(terrain.change_cost_multiplier)
