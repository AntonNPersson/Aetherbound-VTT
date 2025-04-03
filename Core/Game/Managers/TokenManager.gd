class_name TokenManager extends Node
var cached_tokens: Dictionary = {}
var npc_instance: PackedScene = preload("res://Characters/NPCs/npc_token.tscn")
var token_spawner = null
var map_manager = null
# NEED TO ADD LATER A WAY TO SAVE THE CHARACTER SHEET DATA, AS IN ITS CURRENT HEALTH, ETC

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

func initialize_monster_sheet(token_data: Dictionary) -> MonsterSheet:
	if not token_data.has("sheet"):
		printerr("Token data is missing 'sheet' information.")
		return MonsterSheet.new() # Cannot create sheet without data

	var sheet_data: Dictionary = token_data["sheet"]

	if sheet_data.get("resource_type") != "MonsterSheet":
		printerr("Sheet data is not of type 'MonsterSheet'. Found: %s" % sheet_data.get("resource_type", "N/A"))
		printerr("Initializing a new MonsterSheet with default values.")
		return MonsterSheet.new()

	var monster_sheet = MonsterSheet.new()

	# --- Direct Property Assignments ---
	monster_sheet.monster_name = sheet_data.get("monster_name", "")
	monster_sheet.description = sheet_data.get("description", "")
	monster_sheet.level = sheet_data.get("level", 1)
	monster_sheet.speed = sheet_data.get("speed", 30)
	monster_sheet.armor_class = sheet_data.get("armor_class", 10)
	monster_sheet.might_score = sheet_data.get("might_score", 10)
	monster_sheet.agility_score = sheet_data.get("agility_score", 10)
	monster_sheet.endurance_score = sheet_data.get("endurance_score", 10)
	monster_sheet.intelligence_score = sheet_data.get("intelligence_score", 10)
	monster_sheet.wisdom_score = sheet_data.get("wisdom_score", 10)
	monster_sheet.charisma_score = sheet_data.get("charisma_score", 10)
	monster_sheet.health_points = sheet_data.get("health_points", 10)
	monster_sheet.action_points = sheet_data.get("action_points", 1)
	monster_sheet.aether_points = sheet_data.get("aether_points", 0)
	monster_sheet.perception_score = sheet_data.get("perception_score", 0)


	Helper._load_basic_typed_array(monster_sheet, "languages", sheet_data.get("languages"), TYPE_STRING, ["Common"])
	Helper._load_basic_typed_array(monster_sheet, "skills_proficiency", sheet_data.get("skills_proficiency"), TYPE_STRING, [])

	# --- Enum Conversion ---
	var size_string = sheet_data.get("size", "MEDIUM")
	# Find the enum value corresponding to the string key
	var size_keys = GameConst.MonsterSize.keys() # Assuming enum defined in MonsterSheet
	if size_string in size_keys:
		monster_sheet.size = GameConst.MonsterSize[size_string]
	else:
		printerr("Unknown monster size string found in JSON: ", size_string)
		monster_sheet.size = GameConst.MonsterSize.MEDIUM # Default fallback

	# --- Arrays of Enums Conversion (Example: Damage Types/Conditions) ---
	# Assuming they were saved as strings in JSON. Adjust Enum names as needed.
	var damage_type_keys = GameConst.DamageType.keys()
	var condition_keys = GameConst.Condition.keys()

	Helper._load_enum_array(monster_sheet, "damage_immunities", sheet_data.get("damage_immunities", []), GameConst.DamageType, damage_type_keys, [])
	Helper._load_enum_array(monster_sheet, "damage_resistances", sheet_data.get("damage_resistances", []), GameConst.DamageType, damage_type_keys, [])
	Helper._load_enum_array(monster_sheet, "damage_weaknesses", sheet_data.get("damage_weaknesses", []), GameConst.DamageType, damage_type_keys, [])
	Helper._load_enum_array(monster_sheet, "condition_immunities", sheet_data.get("condition_immunities", []), GameConst.Condition, condition_keys, [])


	# --- Arrays of Resources (Lookup Required) ---
	Cache._load_resource_array(monster_sheet, "abilities", sheet_data.get("abilities", []), "AbilityResource", [])
	Cache._load_resource_array(monster_sheet, "possible_items", sheet_data.get("possible_items", []), "ItemResource", [])
	Cache._load_resource_array(monster_sheet, "spells", sheet_data.get("spells", []), "SpellResource", [])
	Cache._load_resource_array(monster_sheet, "traits", sheet_data.get("traits", []), "TraitResource", [])

	return monster_sheet

func _save():
	for map_name in cached_tokens:

		if cached_tokens[map_name].has("instance"):
			cached_tokens[map_name].erase("instance")
		var tokens = ExternalUtility.prepare_for_json(cached_tokens[map_name])

		map_name = map_name.replace("_", " ")
		if map_name in map_manager.tilemap_data:
			map_manager.tilemap_data[map_name]["tokens"] = tokens
	
