class_name GameListItem extends Control

@export var game_name: String
@export var game_players: String
@export var game_version: String
@export var saved_ip: String
@export var saved_port: int

func _initialize(game_name_text: String = "Name", game_players_text: String = "Players", game_version_text: String = GameConst.GAME_VERSION, ip: String = "127.0.0.1", port: int = 8080) -> void:
	get_child(0).get_child(0).add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	get_child(0).get_child(1).add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	get_child(0).get_child(2).add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))

	game_name = game_name_text
	game_players = game_players_text
	game_version = game_version_text
	saved_ip = ip
	saved_port = port

	get_child(0).get_child(0).text = game_name
	get_child(0).get_child(1).text = game_players
	get_child(0).get_child(2).text = game_version

func select_item() -> Dictionary:
	self.color = Color(0.8, 0.8, 0.8, 0.4)

	var selected_game = {
		"name": game_name,
		"players": game_players,
		"version": game_version,
		"ip": saved_ip,
		"port": saved_port
	}
	return selected_game

func deselect_item() -> void:
	self.color = Color(0.8, 0.8, 0.8, 0.0)

func _on_Item_pressed() -> void:
	var selected_game = select_item()
	Bus.select_lobby.emit(selected_game)

func _on_item_gui_input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_Item_pressed()
