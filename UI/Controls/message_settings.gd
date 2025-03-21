extends Node

func connect_signals(message: Resource) -> void:
	var child = get_child(0)
	child.get_node("Message").text = message.message
	child.get_node("Level").select(get_item_index_from_text(child.get_node("Level"), message.message_level))
	child.get_node("Reciever").select(get_item_index_from_text(child.get_node("Reciever"), message.reciever))
	child.get_node("Sender").select(get_item_index_from_text(child.get_node("Sender"), message.sender))
	child.get_node("One Shot").button_pressed = message.one_shot

	child.get_node("Message").text_changed.connect(message.change_message)
	child.get_node("Level").item_selected.connect(func(index): message.change_message_level(child.get_node("Level").get_item_text(index)))
	child.get_node("Reciever").item_selected.connect(func(index): message.change_reciever(child.get_node("Reciever").get_item_text(index)))
	child.get_node("Sender").item_selected.connect(func(index): message.change_sender(child.get_node("Sender").get_item_text(index)))
	child.get_node("One Shot").toggled.connect(message.change_one_shot)


func get_item_index_from_text(option_button: OptionButton, text: String) -> int:
	# Loop through all items in the OptionButton
	for i in range(option_button.item_count):
		if option_button.get_item_text(i) == text:
			return i
	
	# Return -1 if no matching item is found
	return -1
