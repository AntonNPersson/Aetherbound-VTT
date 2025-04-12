class_name TokenManager extends Node
var cached_tokens: Dictionary = {}
var npc_instance: PackedScene = preload("res://Characters/NPCs/npc_token.tscn")
var token_spawner = null
var map_manager = null

func _ready() -> void:
	add_to_group("Savable")
	token_spawner = setup_token_spawner()

func update_tokens() -> void:
	for map in cached_tokens:
		for token in cached_tokens[map]:
			if map_manager.is_token_on_map(token["instance"], map):
				continue
			else:
				map_manager.add_token_to_map(token["instance"], map)

func create_tokens(token_data: Array, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if map_name in cached_tokens and !cached_tokens[map_name].is_empty():
		return
		
	cached_tokens[map_name] = []
	
	for token in token_data:
		if token_spawner.has_node(token["name"] + " " + str(token["id"])):
			continue
		
		if token["position"] is Array and token["position"].size() >= 2:
			token["position"] = Vector2(token["position"][0], token["position"][1])

		var token_resource = npc_instance.instantiate()
		token_resource.character_sheet = initialize_monster_sheet(token)
		token_resource.map = map_manager
		token_resource.get_node("Sprite2D").texture = load(token["texture"])
		token_resource.name = token["name"] + " " + str(token["id"])
		token_resource.global_position = token["position"]
		token_resource.id = token["id"]
		token["instance"] = token_resource
		cached_tokens[map_name].append(token)

		var map_index = map_manager.current_map if !Net.is_host() else map_manager.current_local_map
		if map_index != map_manager.get_map_index_from_name(map_name):
			token_resource.visible = false

		token_spawner.add_child(token_resource)
		map_manager.add_token_to_map(token_resource, map_name)
		Bus.send_tile_size.emit(map_manager.tile_size)

func remove_token(token_name: String, token_position: Vector2, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if map_name not in cached_tokens:
		return
	
	for i in range(cached_tokens[map_name].size()):
		if !is_instance_valid(cached_tokens[map_name][i]["instance"]):
				map_manager.get_token_at_position(token_position).queue_free()
				break
		if cached_tokens[map_name][i]["instance"].name == token_name and cached_tokens[map_name][i]["instance"].global_position == token_position:
			map_manager.remove_token_from_map(cached_tokens[map_name][i]["instance"], map_name)
			cached_tokens[map_name][i]["instance"].queue_free()
			cached_tokens[map_name].remove_at(i)
			break

func add_token(token_data: Dictionary, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	if map_name not in cached_tokens:
		cached_tokens[map_name] = []
	
	var token_resource = npc_instance.instantiate()
	token_resource.character_sheet = initialize_monster_sheet(token_data)
	token_resource.map = map_manager
	token_resource.get_node("Sprite2D").texture = load(token_data["texture"])
	token_resource.name = token_data["name"] + " " + str(token_data["id"])
	token_resource.id = token_data["id"]
	token_resource.global_position = token_data["position"]
	token_data["instance"] = token_resource
	cached_tokens[map_name].append(token_data)

	var map_index = map_manager.current_map if !Net.is_host() else map_manager.current_local_map
	if map_index != map_manager.get_map_index_from_name(map_name):
		token_resource.visible = false

	token_spawner.add_child(token_resource)
	map_manager.add_token_to_map(token_resource, map_name)
	Bus.send_tile_size.emit(map_manager.tile_size)

func setup_token_spawner():
	var spawner = MultiplayerSpawner.new()
	spawner.name = "TokenSpawner"
	spawner.spawn_path = NodePath(".")
	add_child(spawner)
	return spawner

# Assumes Helper and Cache scripts exist and function as intended.
# Assumes GameConst contains the necessary enums (MonsterSize, DamageType, Condition).

# Assumes Helper and Cache scripts exist and function as intended.
# Assumes GameConst contains the necessary enums (MonsterSize, DamageType, Condition, MovementState).

func initialize_monster_sheet(token_data: Dictionary) -> MonsterSheet:
	if not token_data.has("sheet"):
		printerr("Token data is missing 'sheet' information.")
		return MonsterSheet.new() # Return default

	var sheet_data: Dictionary = token_data["sheet"] # This is the RAW data

	# --- Call the central preparation function ---
	var prepared_data = Cache.prepare_monster_sheet_data(sheet_data)
	# -------------------------------------------

	# --- Create instance and initialize ---
	var monster_sheet = MonsterSheet.new()
	monster_sheet.initialize_from_dict(prepared_data)
	# ------------------------------------

	# --- Optional: Perform post-initialization actions ---
	# monster_sheet.initialize_runtime_state() # Maybe call this AFTERWARDS now?
	# monster_sheet.recalculate_derived_stats()

	return monster_sheet

func _save():
	for map_name in cached_tokens:
		for token in cached_tokens[map_name]:
			if !is_instance_valid(token["instance"]) or !token.has("instance"):
				continue
			token["sheet"] = ExternalUtility.prepare_for_json(token["instance"].character_sheet)
			token.erase("instance")

		var tokens = ExternalUtility.prepare_for_json(cached_tokens[map_name])

		map_name = map_name.replace("_", " ")
		if map_name in map_manager.tilemap_data:
			map_manager.tilemap_data[map_name]["tokens"] = tokens
	
