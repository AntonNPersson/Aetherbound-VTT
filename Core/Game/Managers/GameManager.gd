extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	print("Hello, World!")
	Net.player_loaded.rpc_id(1)
