class_name SpawnManager extends Node
var map_manager: Node
var cached_spawns: Dictionary = {}

func _ready() -> void:
	add_to_group("Savable")

func create_spawns(spawn_data: Array, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if Net.is_host():
		for key in cached_spawns:
			print("Setting ", key)
			for spawn in cached_spawns[key]:
				spawn.spawn_sprite.visible = (key == map_name)
				print("Setting spawn visibility for", key, "to", (key == map_name))
	
	if map_name in cached_spawns and !cached_spawns[map_name].is_empty():
		return
		
	cached_spawns[map_name] = []
	
	for spawn in spawn_data:
		var position: Vector2
		if spawn.position is Array and spawn.position.size() >= 2:
			position = Vector2(spawn.position[0], spawn.position[1])
		else:
			ErrorUtility.log_warning("Warning: Invalid spawn position data:", spawn.position)
			continue
		
		var spawn_resource = SpawnResource.new(position, self)
		
		cached_spawns[map_name].append(spawn_resource)
		

func remove_spawn(position: Vector2, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if map_name not in cached_spawns:
		return
	
	for i in range(cached_spawns[map_name].size()):
		if cached_spawns[map_name][i].spawn_position == position:
			if Net.is_host():
				cached_spawns[map_name][i].spawn_sprite.queue_free()
			cached_spawns[map_name].remove_at(i)
			break	

func add_spawn(position: Vector2, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if map_name not in cached_spawns:
		cached_spawns[map_name] = []
	
	var spawn_resource = SpawnResource.new(position, map_manager)
	cached_spawns[map_name].append(spawn_resource)

func has_spawn(map_name: String) -> bool:
	map_name = map_name.replace(" ", "_")
	return map_name in cached_spawns

func get_spawns(map_name: String) -> Array:
	map_name = map_name.replace(" ", "_")
	return cached_spawns.get(map_name, [])

func get_random_spawn(map_name: String) -> Vector2:
	map_name = map_name.replace(" ", "_")
	
	if map_name not in cached_spawns:
		return Vector2.ZERO
	
	var spawns = cached_spawns[map_name]
	if spawns.is_empty():
		return Vector2.ZERO
	
	var random_index = randi() % spawns.size()
	return spawns[random_index].spawn_position

func _save():
	for map_name in cached_spawns:
		var clean_map_name = map_name.replace("_", " ")
		
		var map_spawns = ExternalUtility.prepare_for_json(cached_spawns[map_name])
		
		if clean_map_name in map_manager.tilemap_data:
			map_manager.tilemap_data[clean_map_name]["spawns"] = map_spawns
	
