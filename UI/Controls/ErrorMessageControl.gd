extends RichTextLabel

func _ready() -> void:
	Bus.send_error_message.connect(on_error_message)

func on_error_message(message: String) -> void:
	text = "[center][color=CRIMSON]" + message
	show()
	await get_tree().create_timer(2.0).timeout
	hide()
