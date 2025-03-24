class_name SettingsTrigger extends Trigger
var global_illumination = false
var global_illumination_color = Color(1, 1, 1, 1)
var global_fog_color = Color(0, 0, 0, 1)
var global_vision_color = Color(1, 1, 1, 0)
var settings_texture = preload("res://Assets/Textures/icons/settings-icon.png")
var tm = null

func _init(pos: Vector2, trigger_manager: Node) -> void:
	trigger_position = pos
	trigger_type = "Settings"
	trigger_description = "A settings trigger, changing the settings of the game for the player when stepped on."
	tm = trigger_manager
	global_illumination = Settings.map_settings["global_illumination"]
	global_illumination_color = Settings.map_settings["global_illumination_color"]
	global_fog_color = Settings.map_settings["global_fog_color"]
	global_vision_color = Settings.map_settings["global_vision_color"]

	if !Net.is_host():
		return
	var sprite = Sprite2D.new()
	sprite.texture = settings_texture
	sprite.z_index = 2
	sprite.global_position = trigger_manager.map_manager.convert_to_tilemap_global_pos(trigger_position)
	sprite.scale = Vector2(0.2, 0.2)
	sprite.add_to_group("Trigger_sprites")
	trigger_manager.add_child(sprite)
	trigger_sprite = sprite

func execute(player: Node):
	Settings.map_settings["global_illumination"] = global_illumination
	Settings.map_settings["global_illumination_color"] = global_illumination_color
	Settings.map_settings["global_fog_color"] = global_fog_color
	Settings.map_settings["global_vision_color"] = global_vision_color
	Bus.apply_map_settings_to_player.emit(player.name.to_int(), Settings.map_settings)

func inspect() -> String:
	return trigger_description

func change_global_illumination(value: bool) -> void:
	global_illumination = value
	tm.map_manager.update_trigger_data_for_peers.rpc(trigger_position, {"global_illumination": value})

func change_global_illumination_color(value: Color) -> void:
	global_illumination_color = value
	tm.map_manager.update_trigger_data_for_peers.rpc(trigger_position, {"global_illumination_color": value})

func change_global_fog_color(value: Color) -> void:
	global_fog_color = value
	tm.map_manager.update_trigger_data_for_peers.rpc(trigger_position, {"global_fog_color": value})

func change_global_vision_color(value: Color) -> void:
	global_vision_color = value
	tm.map_manager.update_trigger_data_for_peers.rpc(trigger_position, {"global_vision_color": value})

func update_state(data: Dictionary) -> void:
	if "global_illumination" in data:
		global_illumination = data["global_illumination"]
	if "global_illumination_color" in data:
		global_illumination_color = data["global_illumination_color"]
	if "global_fog_color" in data:
		global_fog_color = data["global_fog_color"]
	if "global_vision_color" in data:	
		global_vision_color = data["global_vision_color"]
