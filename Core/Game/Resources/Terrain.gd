class_name TerrainTrigger extends Trigger
var cost_multiplier = 2.0
var terrain_texture = preload("res://Assets/Textures/icons/terrain-icon.png")
var tm = null

func _init(pos: Vector2, trigger_manager: Node) -> void:
	trigger_position = pos
	trigger_type = "Terrain"
	trigger_description = "A terrain trigger, multiplying the cost of the movement over this tile."
	tm = trigger_manager

	if !Net.is_host():
		return
	var sprite = Sprite2D.new()
	sprite.texture = terrain_texture
	sprite.z_index = 2
	sprite.global_position = trigger_manager.map_manager.convert_to_tilemap_global_pos(trigger_position)
	sprite.scale = Vector2(0.2, 0.2)
	sprite.add_to_group("Terrain_sprites")
	trigger_manager.add_child(sprite)
	trigger_sprite = sprite

func execute(player: Node):
	pass

func inspect() -> String:
	return trigger_description

func change_cost_multiplier(value: float) -> void:
	cost_multiplier = value
	tm.map_manager.update_trigger_data_for_peers.rpc(trigger_position, {"cost_multiplier": value})

func update_state(data: Dictionary) -> void:
	if "cost_multiplier" in data:
		cost_multiplier = data["cost_multiplier"]