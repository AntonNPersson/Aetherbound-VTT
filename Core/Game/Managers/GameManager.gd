extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	Net.player_loaded.rpc()
