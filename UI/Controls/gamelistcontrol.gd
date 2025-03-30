extends Node

func _ready() -> void:
    add_item("testasdas", "test", "test", "test", 1234)

func add_item(game_name: String, game_players: String, game_version: String, ip: String, port: int) -> void:
    var item = load("res://UI/Instances/GameListItem.tscn" ).instantiate()
    get_child(0).get_child(0).get_child(0).add_child(item)
    item._initialize(game_name, game_players, game_version, ip, port)