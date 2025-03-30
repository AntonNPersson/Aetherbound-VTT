class_name PanelManager extends Node

# Reference to parent MapManager for necessary data
var map_manager: MapManager

func _init(manager: MapManager) -> void:
	map_manager = manager
	Bus.create_base_context_panel.connect(create_base_context_panel)
	Bus.create_sidebar_context_panel.connect(create_sidebar_context_panel)
	Bus.create_sidebar_combat_context_panel.connect(create_sidebar_combat_context_panel)
	Bus.create_sidebar_resource_panel.connect(create_sidebar_resource_context_panel)

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

func create_terrain_settings_panel(terrain: TerrainTrigger) -> void:
	var context = load("res://UI/Instances/terrain_settings_panel.tscn").instantiate()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.global_position = get_viewport().get_mouse_position() - Vector2(context.get_child(0).size.x/2, context.get_child(0).size.y/2)
	context.connect_signals(terrain)

func create_settings_settings_panel(setting: SettingsTrigger) -> void:
	var context = load("res://UI/Instances/settings_settings_panel.tscn").instantiate()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.global_position = get_viewport().get_mouse_position() - Vector2(context.get_child(0).size.x/2, context.get_child(0).size.y/2)
	context.connect_signals(setting)

func create_message_settings_panel(message: MessageTrigger) -> void:
	var context = load("res://UI/Instances/message_settings_panel.tscn").instantiate()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.global_position = get_viewport().get_mouse_position() - Vector2(context.get_child(0).size.x/2, context.get_child(0).size.y/2)
	context.connect_signals(message)

func create_whisper_panel(player: Node) -> void:
	if player.name.to_int() == multiplayer.get_unique_id():
		return

	var context = load("res://UI/Instances/whisper_panel.tscn").instantiate()
	get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
	context.global_position = get_viewport().get_mouse_position() - Vector2(context.get_child(0).size.x/2, context.get_child(0).size.y/2)
	context.connect_signals(player)

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

func create_sidebar_context_panel(object: Variant) -> void:
	var context = create_base_context_panel(object)
	if object.is_in_group("players"):
		context.add_button("Message", create_whisper_panel.bind(object))
	
	if Net.is_host():
		if object.is_hidden:
			context.add_button("Show", object.show_token)
		else:
			context.add_button("Hide", object.hide_token)
		
		if object.is_possesed:
			context.add_button("Unpossess", object.hide_line_of_sight)
		else:
			context.add_button("Possess", object.show_line_of_sight)

func create_sidebar_combat_context_panel(objects: Array) -> void:
	if Net.is_host():
		var context = context_panel.new()
		get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
		context.create_panel(get_viewport().get_mouse_position(), Vector2(0,0))
		context.add_button("Engage", func(): Bus.start_combat.emit(objects))

func create_sidebar_resource_context_panel(resource: Variant) -> void:
	if Net.is_host():
		var context = context_panel.new()
		get_tree().get_root().get_node("Root").get_node("GameUI").add_child(context)
		context.create_panel(get_viewport().get_mouse_position(), Vector2(0,0))
		context.add_button("Delete",func(): Bus.delete_resource_content.emit(resource))

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
		context.add_button("Message", create_whisper_panel.bind(selected_token))
	
	if !selected_token.is_hidden:
		context.add_button("Hide", selected_token.hide_token)
	else:
		context.add_button("Show", selected_token.show_token)
	
	if !selected_token.is_possesed:
		context.add_button("Possess", selected_token.show_line_of_sight)
	else:
		context.add_button("Unpossess", selected_token.hide_line_of_sight)
		
	context.add_button("Ping", func(): map_manager.trigger_ping.rpc(selected_tile))
	if selected_token.is_in_group("players"):
		context.add_button("Settings", create_settings_panel.bind(selected_token.name.to_int()))
	else:
		context.add_button("Settings", do_nothing)
	
	if selected_token.is_in_group("npc"):
		context.add_button("Save", selected_token._save)

# Create the token context panel specific for the peer
# Args: Node2D - The token to add
# Returns: None
func create_peer_context_panel(selected, selected_tile) -> void:
	if Net.is_host():
		return
	var context = create_base_context_panel(null)
	if selected.is_in_group("players"):
		context.add_button("Message", create_whisper_panel.bind(selected))
	context.add_button("Ping", func(): map_manager.trigger_ping.rpc(selected_tile))
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
		if selected_port.is_locked:
			context.add_button("Unlock", selected_port.unlock_portal)
		else:
			context.add_button("Lock", selected_port.lock_portal)
		if selected_port.is_hidden:
			context.add_button("Show", selected_port.show_portal)
		else:
			context.add_button("Hide", selected_port.hide_portal)

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

func create_host_trigger_context_panel(selected) -> void:
	if !Net.is_host():
		return
	var selected_trigger = map_manager.get_trigger_at_position(selected)
	var context = create_base_context_panel(selected_trigger)

	if selected_trigger:
		if selected_trigger.trigger_type == "Settings":
			context.add_button("Settings", create_settings_settings_panel.bind(selected_trigger))
		elif selected_trigger.trigger_type == "Terrain":
			context.add_button("Settings", create_terrain_settings_panel.bind(selected_trigger))
		elif selected_trigger.trigger_type == "Message":
			context.add_button("Settings", create_message_settings_panel.bind(selected_trigger))

func create_selected_tile_context_panel(selected_tile) -> void:
	var context = create_base_context_panel(null)
	context.add_button("Ping", func(): map_manager.trigger_ping.rpc(selected_tile))
