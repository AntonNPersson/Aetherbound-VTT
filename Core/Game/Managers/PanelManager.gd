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

func create_object_inspect_panel(text: String) -> void:
	var context = load("res://UI/Instances/object_inspect_panel.tscn").instantiate()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.get_child(0).get_node("Text").text = "[center]" + text + "[/center]"
	context.global_position = get_viewport().get_mouse_position() - Vector2(context.get_child(0).size.x/2, context.get_child(0).size.y/2)

func create_light_settings_panel(light: LightResource) -> void:
	var context = load("res://UI/Instances/light_settings_panel.tscn").instantiate()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.global_position = get_viewport().get_mouse_position() - Vector2(context.get_child(0).size.x/2, context.get_child(0).size.y/2)
	context.connect_signals(light)

# Create the context panel for all objects, need to make a seperate one for tokens
func create_base_context_panel(object: Variant) -> context_panel:
	var context = context_panel.new()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.create_panel(get_viewport().get_mouse_position(), Vector2(0,0))
	if object != null and object.has_method("inspect"):
		context.add_button("Inspect", create_object_inspect_panel.bind(object.inspect()))
	else:
		context.add_button("Inspect", do_nothing)
	return context

# Create the token context panel specific for the host
func create_host_context_panel(selected_token, selected_tile) -> void:
	if !Net.is_host():
		return
		
	var context = create_base_context_panel(null)
	
	context.add_button("Move", selected_token.move_token)
	
	if selected_token.is_in_group("players"):
		var id = selected_token.name.to_int()
		print("ID: " + str(id))
		context.add_button("Change", func(): map_manager.open_map_changer.emit(selected_token.name.to_int()))
	
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
	var context = create_base_context_panel(null)
	if selected.is_in_group("players"):
		context.add_button("Message", do_nothing)
	context.add_button("Ping", do_nothing)
	context.add_button("Settings", do_nothing)

# Create the portal context panel specific for the player
func create_portal_context_panel(selected, selected_token, selected_tile) -> void:
	if Net.is_host():
		return
	
	var selected_port = map_manager.get_portal_at_position(selected)
	var context = create_base_context_panel(selected_port)
	
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
	var selected_port = map_manager.get_portal_at_position(selected)
	var context = create_base_context_panel(selected_port)

	if selected_port:
		if selected_port.is_open:
			context.add_button("Close", selected_port.close_portal)
		else:
			context.add_button("Open", selected_port.open_portal)

func create_host_light_context_panel(selected) -> void:
	if !Net.is_host():
		return
	var selected_light = map_manager.get_light_at_position(selected)
	var context = create_base_context_panel(selected_light)

	if selected_light:
		if selected_light.light_is_visible:
			context.add_button("Off", selected_light.change_light_visibility.bind(false))
		else:
			context.add_button("On", selected_light.change_light_visibility.bind(true))
		context.add_button("Settings", create_light_settings_panel.bind(selected_light))
