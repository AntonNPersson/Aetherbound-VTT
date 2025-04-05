extends Control
var callable: Callable

func _initialize() -> void:
	global_position = get_viewport().get_mouse_position() + Vector2(-get_child(0).size.x/2, -get_child(0).size.y)
	get_child(0).get_node("Message").grab_focus()
	if callable:
		get_child(0).get_node("Send").pressed.connect(_on_send_pressed)
		get_child(0).get_node("Message").gui_input.connect(func(event): if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER and not event.shift_pressed: get_child(0).get_node("Send").emit_signal("pressed"))

func _on_send_pressed() -> void:
	if callable:
		callable.call(get_child(0).get_node("Message").text)
		queue_free()
