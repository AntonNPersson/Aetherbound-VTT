class_name SpawnResource extends Resource
var spawn_position : Vector2
var spawn_texture : Texture = preload("res://Assets/Textures/icons/spawn-icon.png")
var spawn_sprite : Sprite2D
var spawn_description = "A spawn point, where the player will spawn. If there are several spawn points, the player will spawn at a random one."

func _init(pos: Vector2, parent: Node) -> void:
	spawn_position = pos
	if !Net.is_host():
		return

	var sprite = Sprite2D.new()
	sprite.texture = spawn_texture
	sprite.z_index = 2
	sprite.global_position = pos
	sprite.scale = Vector2(0.2, 0.2)
	sprite.add_to_group("Spawn_sprites")
	spawn_sprite = sprite
	parent.add_child(sprite)
	print("SpawnResource created at", pos)

func inspect() -> String:
	return spawn_description