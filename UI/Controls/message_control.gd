extends Control
var original_position_y: float
var is_mouse_over = false
var message_level_map = {
	"warning": "gold",
	"danger": "crimson",
	"normal": "floralwhite",
	"whisper": "orchid"
}

var message_history: Dictionary = {}

func _ready() -> void:
	original_position_y = self.global_position.y
	var gm_node = Node.new()
	gm_node.name = "1"
	add_child(gm_node)
	
	# Set up key handling for TextEdit
	var message_node = get_node("Message")
	if message_node is TextEdit:
		message_node.gui_input.connect(_on_message_gui_input)
		# Connect to focus exit signal
		message_node.focus_exited.connect(_on_message_focus_exited)
	
	# Connect to input event to handle clicks outside TextEdit
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

	Bus.send_message_to_player.connect(send_message_to_player)
	Bus.send_message_to_all.connect(send_message_to_all)
	Bus.send_environment_message_to_player.connect(send_environment_message_to_player)
	Bus.send_environment_message_to_all.connect(send_environment_message_to_all)
	Bus.send_whisper_message.connect(send_whisper_message)

func _on_focus_changed(control: Control) -> void:
	# If focus moved to something other than our TextEdit
	if control != get_node("Message"):
		get_node("Message").deselect()

func _on_message_focus_exited() -> void:
	# When TextEdit loses focus
	get_node("Message").deselect()

func _on_message_gui_input(event: InputEvent) -> void:
	# Check for Enter key press without Shift (Shift+Enter typically adds a new line)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and not event.shift_pressed:
		# Consume the event to prevent adding a newline
		get_viewport().set_input_as_handled()
		send_message.rpc("normal", "", get_node("Message").text)

@rpc("any_peer", "call_local", "reliable")
func send_message(level: String, sender_name: String = "", message: String = "") -> void:
	var message_node = get_node("Message")
	var message_name = ""
	var message_color = message_level_map[level]
	var formatted_message = ""
	var sender_id = multiplayer.get_remote_sender_id()

	if sender_name == "":
		if Net.players.size() == 0:
			message_name = "[Local]: "
		else:
			message_name = "[url=" + str(sender_id) + "][" + Net.players[multiplayer.get_unique_id()]["name"] + "][/url]: "
	else:
		message_name = "[color=" + message_color + "]" + "[" + sender_name + "]: "
	
	# Get text based on node type
		
	if message.strip_edges().is_empty():
		return  # Don't send empty messages

	formatted_message = "[color=" + message_color + "]" + message_name + message + "[/color]\n"

	var new_text = RichTextLabel.new()
	new_text.bbcode_enabled = true
	new_text.text = formatted_message
	new_text.fit_content = true  # Godot 4.x
	new_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_text.custom_minimum_size.x = get_node("History").size.x
	
	var message_container = get_node("History").get_child(0)
	new_text.meta_clicked.connect(_on_sender_name_clicked)
	message_container.add_child(new_text)
	call_deferred("_scroll_to_bottom", get_node("History"))

	
	if sender_id == multiplayer.get_unique_id():
		message_node.text = ""
		# Set focus back to the message input
		message_node.grab_focus()

# Message sending

func send_message_to_player(player_id: int, message: String, level: String) -> void:
	send_message.rpc_id(player_id, level, "", message)

func send_message_to_all(message: String, level: String) -> void:
	send_message.rpc(level, "", message)

func send_environment_message_to_player(player_id: int, message: String, level: String) -> void:
	send_message.rpc_id(player_id, level, "Environment", message)

func send_environment_message_to_all(message: String, level: String) -> void:
	print("Sending environment message to all")
	send_message.rpc(level, "Environment", message)

func send_whisper_message(player_id: int, message: String) -> void:
	send_message("whisper", "", message)
	send_message.rpc_id(player_id, "whisper", "", message)

# Helper functions

func _scroll_to_bottom(scroll_container: ScrollContainer) -> void:
	# Wait one frame to ensure the layout is updated
	await get_tree().process_frame
	
	# Calculate the maximum scroll value
	var max_scroll = scroll_container.get_v_scroll_bar().max_value
	
	# Scroll to the bottom
	scroll_container.scroll_vertical = max_scroll

func _on_sender_name_clicked(meta: Variant) -> void:
	var sender_id = int(meta)

	if sender_id != 0 and sender_id != multiplayer.get_unique_id():
		# Open the whisper panel
		var whisper_panel = load("res://UI/Instances/whisper_panel.tscn").instantiate()
		get_tree().get_root().get_node("Root").get_node("GameUI").add_child(whisper_panel)
		whisper_panel.global_position = Vector2(Settings.window_settings["width"]/2, Settings.window_settings["height"]/2) - Vector2(whisper_panel.get_child(0).size.x/2, whisper_panel.get_child(0).size.y/2)
		var player_node
		if sender_id == 1:
			player_node = get_node("1")
		else:
			for player in get_tree().get_nodes_in_group("players"):
				if player.name.to_int() == sender_id:
					player_node = player
					print("Player found")
					break
		whisper_panel.connect_signals(player_node)
