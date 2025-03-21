class_name MessageTrigger extends Trigger
var message: String = "This is a message."
var message_level: String = "normal"
var reciever: String = "all"
var sender: String = "environmental"
var message_texture = preload("res://Assets/Textures/icons/message-icon.png")
var one_shot: bool = false
var tm = null

func _init(pos: Vector2, trigger_manager: Node) -> void:
	trigger_position = pos
	trigger_type = "Message"
	trigger_description = "A message trigger, sending a message to a reciever when stepped on."
	tm = trigger_manager

	if !Net.is_host():
		return
	var sprite = Sprite2D.new()
	sprite.texture = message_texture
	sprite.z_index = 2
	sprite.global_position = trigger_manager.map_manager.convert_to_tilemap_global_pos(trigger_position)
	sprite.scale = Vector2(0.2, 0.2)
	sprite.add_to_group("Message_sprites")
	trigger_manager.add_child(sprite)
	trigger_sprite = sprite

func execute(player: Node):
	if sender == "Environment":
		if reciever == "all":
			Bus.send_environment_message_to_all.emit(message, message_level)
		elif reciever == "player":
			Bus.send_environment_message_to_player.emit(player.name.to_int(), message, message_level)
		elif reciever == "GM":
			Bus.send_environment_message_to_player.emit(1, message, message_level)
	elif sender == "GM":
		if reciever == "all":
			Bus.send_message_to_all.emit(message, message_level)
		elif reciever == "player":
			Bus.send_message_to_player.emit(player.name.to_int(), message, message_level)
		elif reciever == "GM":
			Bus.send_message_to_player.emit(1, message, message_level)

	if one_shot:
		tm.map_manager.remove_trigger_data.rpc(tm.map_manager.get_map_name_from_index(tm.map_manager.current_map), trigger_position)

	print("Message sent:", message, message_level, reciever, sender)

func inspect() -> String:
	return trigger_description

func change_message(value: String) -> void:
	message = value
	tm.map_manager.update_trigger_data_for_peers.rpc(trigger_position, {"message": value})

func change_message_level(value: String) -> void:
	message_level = value
	tm.map_manager.update_trigger_data_for_peers.rpc(trigger_position, {"message_level": value})

func change_reciever(value: String) -> void:
	reciever = value
	tm.map_manager.update_trigger_data_for_peers.rpc(trigger_position, {"reciever": value})

func change_sender(value: String) -> void:
	sender = value
	tm.map_manager.update_trigger_data_for_peers.rpc(trigger_position, {"sender": value})

func change_one_shot(value: bool) -> void:
	one_shot = value
	tm.map_manager.update_trigger_data_for_peers.rpc(trigger_position, {"one_shot": value})

func update_state(data: Dictionary) -> void:
	if "message" in data:
		message = data["message"]
	if "message_level" in data:
		message_level = data["message_level"]
	if "reciever" in data:
		reciever = data["reciever"]
	if "sender" in data:
		sender = data["sender"]
	if "one_shot" in data:
		one_shot = data["one_shot"]
