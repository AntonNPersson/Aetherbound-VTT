extends Node

func connect_signals(player: Node) -> void:
	var child = get_child(0)
	child.get_node("Message").grab_focus()
	child.get_node("Send").pressed.connect(func(): Bus.send_whisper_message.emit(player.name.to_int(), child.get_node("Message").text); queue_free())
	child.get_node("Message").gui_input.connect(func(event): if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and not event.shift_pressed: child.get_node("Send").emit_signal("pressed"))
