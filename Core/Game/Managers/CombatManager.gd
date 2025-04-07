extends Node

# Combat data tracking
var in_combat: Dictionary = {}
var next_combat_id: int = 0

func _ready() -> void:
	if !Net.is_host():
		return
	Bus.start_combat.connect(start_combat)
	Bus.end_combat.connect(end_combat)

func start_combat(tokens: Array) -> void:
	print("Combat has started!")
	
	# Setup combat instance
	var combat_id: int = next_combat_id
	next_combat_id += 1
	in_combat[combat_id] = {}
	
	# Track combatants
	var all_combatants: Array = []
	var owned_combatants: Dictionary = {}
	
	# Process each token
	for token in tokens:
		var owner_id: int
		# Set token as in combat
		token.combat = true
		
		# Determine owner based on token type
		if token.is_in_group("players"):
			owner_id = token.name.to_int()
			
		elif token.is_in_group("summons") and token.has_meta("summoner"):
			owner_id = token.get_meta("summoner").name.to_int()
			
		else:
			# Non-player, non-summon tokens are owned by host
			owner_id = Net.get_host_id()
		
		# Initialize combat tracking data if needed
		if owner_id not in in_combat[combat_id]:
			in_combat[combat_id][owner_id] = []
			owned_combatants[owner_id] = []
		
		# Add token to appropriate collections
		in_combat[combat_id][owner_id].append(token)
		
		# Handle different types of token ownership
		if token.is_in_group("summons") and token.has_meta("summoner"):
			owned_combatants[owner_id] = token.get_meta("summoner").name
		else:
			owned_combatants[owner_id].append(token.name)
			
			# Only send announcements for players and host-owned tokens
			Bus.send_announcement_to_player.emit(owner_id, "Combat has started!", Color.WHITE)
		
		# Add to the list of all combatants
		all_combatants.append(token.name)
	
	# Create combat trackers for all participants
	for participant_id in in_combat[combat_id]:
		Bus.create_combat_tracker.emit(
			participant_id,
			all_combatants,
			owned_combatants[participant_id],
			combat_id
		)

	print("Combatants in combat: ", in_combat[combat_id])
	print("Combat ID: ", combat_id)	
	Bus.initialize_turn_order.emit(combat_id, all_combatants)

func end_combat(combat_id: int, type: String) -> void:
	print("Combat has ended!")
	
	# Prepare message based on outcome
	var message: String = "Victory!" if type == "Victory" else "Defeat!"
	var color: Color = Color.GREEN if type == "Victory" else Color.CRIMSON
	
	# Notify the host
	Bus.send_announcement_to_player.emit(1, message, color)
	
	# Notify all player participants
	for participant_id in in_combat[combat_id]:
		if participant_id != Net.get_host_id():  # Skip host as we already notified them
			Bus.send_announcement_to_player.emit(participant_id, message, color)
	
	for token in in_combat[combat_id].values():
		for combatant in token:
			combatant.combat = false  # Reset combat status for all tokens

	# Remove this combat from tracking
	in_combat.erase(combat_id)
	# Notify all combat trackers to remove themselves
	Bus.remove_combat_turns.emit(combat_id)
	remove_combat_trackers.rpc(combat_id)

@rpc("authority", "call_local", "reliable")
func remove_combat_trackers(combat_id) -> void:
	Bus.remove_combat_tracker.emit(combat_id)
