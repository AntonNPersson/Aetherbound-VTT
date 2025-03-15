class_name PanelManager extends Node

# Reference to parent MapManager for necessary data
var map_manager: MapManager

func _init(manager: MapManager) -> void:
	map_manager = manager

# Placeholder function for future implementation
func do_nothing() -> void:
	pass

# Create the settings panel for the player
func create_settings_panel(player_id: int) -> void:
	var context = load("res://UI/Instances/context_settings_menu.tscn").instantiate()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.initialize(map_manager.get_parent().get_node("GMManager"), 
			get_viewport().get_mouse_position(), player_id)
	print("Settings panel created")

# Create the context panel for the player
func create_base_context_panel() -> context_panel:
	var context = context_panel.new()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.create_panel(get_viewport().get_mouse_position(), Vector2(0,0))
	context.add_button("Inspect", do_nothing)
	return context

# Create the token context panel specific for the host
func create_host_context_panel(selected_token, selected_tile) -> void:
	if !Net.is_host():
		return
		
	var context = create_base_context_panel()
	
	# Check for portal at position
	if map_manager.is_portal_at_position(selected_tile):
		var door = map_manager.get_portal_at_position(selected_tile)
		if door.is_open:
			context.add_button("Close", door.close_portal)
		else:
			context.add_button("Open", door.open_portal)
	
	context.add_button("Move", selected_token.move_token)
	
	if selected_token.is_in_group("players"):
		var id = selected_token.name.to_int()
		context.add_button("Change", func(): map_manager.emit_open_map_changer.bind(id))
	
	if !selected_token.is_hidden:
		context.add_button("Hide", selected_token.hide_token)
	else:
		context.add_button("Show", selected_token.show_token)
	
	if !selected_token.is_possesed:
		context.add_button("Possess", selected_token.show_line_of_sight)
	else:
		context.add_button("Unpossess", selected_token.hide_line_of_sight)
		
	context.add_button("Ping", do_nothing)
	context.add_button("Settings", create_settings_panel.bind(selected_token.name.to_int()))

# Create the token context panel specific for the peer
# Args: Node2D - The token to add
# Returns: None
func create_peer_context_panel(selected, selected_tile) -> void:
	if Net.is_host():
		return
	var context = create_base_context_panel()
	if map_manager.is_portal_at_position(selected_tile):
		var door = map_manager.get_portal_at_position(selected_tile)
		if door.is_open:
			context.add_button("Close", door.close_portal)
		else:
			context.add_button("Open", door.open_portal)
	if selected.is_in_group("players"):
		context.add_button("Message", do_nothing)
	context.add_button("Ping", do_nothing)
	context.add_button("Settings", do_nothing)

# Create the portal context panel specific for the player
func create_portal_context_panel(selected, selected_token, selected_tile) -> void:
	if Net.is_host():
		return

	if selected_token != null and selected_tile == selected_token.global_position:
			return
	
	var context = create_base_context_panel()
	var selected_port = map_manager.get_portal_at_position(selected)
	
	if selected_port:
		var portal_node = selected_port.parent
		var portal_holder = portal_node.get_node("PortalHolder")
		var valid_positions = portal_holder.get_meta("tile_positions")
		
		var player_token = map_manager.get_player_token(multiplayer.get_unique_id())
		var player_tile_pos = map_manager.convert_to_tilemap_pos(player_token.global_position)
		
		if player_tile_pos in valid_positions:
			if selected_port.is_open:
				context.add_button("Close", selected_port.close_portal)
			else:
				context.add_button("Open", selected_port.open_portal)

# Create the host portal context panel
func create_host_portal_context_panel(selected) -> void:
	if !Net.is_host():
		return
	var context = create_base_context_panel()
	var selected_port = map_manager.get_portal_at_position(selected)

	if selected_port:
		if selected_port.is_open:
			context.add_button("Close", selected_port.close_portal)
		else:
			context.add_button("Open", selected_port.open_portal)