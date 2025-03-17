class_name MoveCommand extends Command
var token: CharacterBody2D
var tile: Vector2
var previous_position: Vector2
var map: Node
# Feature implementation
var move_cost: int = 1

func _init(tok: CharacterBody2D, t: Vector2, m: Node) -> void:
	self.token = tok
	self.tile = t
	self.map = m
	if self.token.is_in_group("players"):
		self.player_id = self.token.name.to_int()

func execute() -> void:
	self.previous_position = map.convert_to_tilemap_global_pos(self.token.global_position)
	map.move_to_tile(self.token, self.tile)

func undo() -> void:
	self.token.global_position = self.previous_position
