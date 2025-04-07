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
	token_data["sheet"] = token_resource.character_sheet
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
		printerr("Token data is missing 'sheet' information for initialization.")
		return MonsterSheet.new() # Return a default sheet

	var sheet_data: Dictionary = token_data["sheet"]

	# Optional: More robust type checking if needed
	# if sheet_data.get("resource_type") != "MonsterSheet" and ...

	var monster_sheet = MonsterSheet.new()

	# --- Load Base/Max Stats and Info ---
	# Basic Info
	monster_sheet.monster_name = sheet_data.get("monster_name", "Default Monster")
	monster_sheet.flavor_text = sheet_data.get("flavor_text", "")
	monster_sheet.description = sheet_data.get("description", "")
	monster_sheet.level = sheet_data.get("level", 0)
	monster_sheet.gender = sheet_data.get("gender", "Male")

	# Base Stats & Speeds
	monster_sheet.base_speed = sheet_data.get("base_speed", 30)
	monster_sheet.base_swim_speed = sheet_data.get("base_swim_speed", 0)
	monster_sheet.base_fly_speed = sheet_data.get("base_fly_speed", 0)
	monster_sheet.base_climb_speed = sheet_data.get("base_climb_speed", 0)
	monster_sheet.base_burrow_speed = sheet_data.get("base_burrow_speed", 0)
	monster_sheet.base_armor_class = sheet_data.get("base_armor_class", 10)

	# Attributes (Modifiers)
	monster_sheet.might_modifier = sheet_data.get("might_modifier", 10)
	monster_sheet.agility_modifier = sheet_data.get("agility_modifier", 10)
	monster_sheet.endurance_modifier = sheet_data.get("endurance_modifier", 10)
	monster_sheet.cognition_modifier = sheet_data.get("cognition_modifier", 10)
	monster_sheet.insight_modifier = sheet_data.get("insight_modifier", 10)
	monster_sheet.charisma_modifier = sheet_data.get("charisma_modifier", 10)

	# Stat Resources (Maximums)
	monster_sheet.max_hit_points = sheet_data.get("max_hit_points", 10)
	monster_sheet.max_temporary_hit_points = sheet_data.get("max_temporary_hit_points", 0)
	monster_sheet.max_actions = sheet_data.get("max_actions", 1)
	monster_sheet.max_bonus_actions = sheet_data.get("max_bonus_actions", 0)
	monster_sheet.max_reactions = sheet_data.get("max_reactions", 0)
	monster_sheet.max_aether_points = sheet_data.get("max_aether_points", 0)

	# Senses
	monster_sheet.perception_modifier = sheet_data.get("perception_modifier", 10)

	# --- Enum Conversion (Size) ---
	var size_string = sheet_data.get("size", "MEDIUM")
	if "MonsterSize" in GameConst:
		var size_keys = GameConst.MonsterSize.keys()
		if size_string in size_keys:
			monster_sheet.size = GameConst.MonsterSize[size_string]
		else:
			printerr("Unknown monster size string found: ", size_string)
			monster_sheet.size = GameConst.MonsterSize.MEDIUM
	else:
		printerr("GameConst.MonsterSize enum not found.")
		monster_sheet.size = GameConst.MonsterSize.MEDIUM # Default

	# --- Basic Array Loading ---
	Helper._load_basic_typed_array(monster_sheet, "languages", sheet_data.get("languages", []), TYPE_STRING, ["Common"])
	Helper._load_basic_typed_array(monster_sheet, "skills", sheet_data.get("skills", []), TYPE_STRING, [])

	# --- Simple Dictionary/Array Loading ---
	monster_sheet.equipped_items = sheet_data.get("equipped_items", {})
	monster_sheet.loot_table = sheet_data.get("loot_table", [])
	monster_sheet.talents = sheet_data.get("talents", [])
	monster_sheet.species = sheet_data.get("species", null)

	# --- Arrays of Enums Conversion (Defenses) ---
	if "DamageType" in GameConst and "Condition" in GameConst:
		var damage_type_keys = GameConst.DamageType.keys()
		var condition_keys = GameConst.Condition.keys()
		Helper._load_enum_array(monster_sheet, "damage_immunities", sheet_data.get("damage_immunities", []), GameConst.DamageType, damage_type_keys, [])
		Helper._load_enum_array(monster_sheet, "damage_resistances", sheet_data.get("damage_resistances", []), GameConst.DamageType, damage_type_keys, [])
		Helper._load_enum_array(monster_sheet, "damage_weaknesses", sheet_data.get("damage_weaknesses", []), GameConst.DamageType, damage_type_keys, [])
		Helper._load_enum_array(monster_sheet, "condition_immunities", sheet_data.get("condition_immunities", []), GameConst.Condition, condition_keys, [])
	else:
		printerr("GameConst missing DamageType or Condition enums.")

	# --- Arrays of Resources (Lookup Required) ---
	Cache._load_resource_array(monster_sheet, "abilities", sheet_data.get("abilities", []), "AbilityResource", [])
	Cache._load_resource_array(monster_sheet, "spells", sheet_data.get("spells", []), "SpellResource", [])
	Cache._load_resource_array(monster_sheet, "traits", sheet_data.get("traits", []), "TraitResource", [])

	# --- Load CURRENT State Variables ---
	monster_sheet.current_hit_points = sheet_data.get("current_hit_points", monster_sheet.max_hit_points) # Default to max if missing
	monster_sheet.current_temporary_hit_points = sheet_data.get("current_temporary_hit_points", 0)
	monster_sheet.current_aether_points = sheet_data.get("current_aether_points", monster_sheet.max_aether_points) # Default to max

	# Current Action Economy
	monster_sheet.current_actions_available = sheet_data.get("current_actions_available", monster_sheet.max_actions) # Default to max
	monster_sheet.current_bonus_actions_available = sheet_data.get("current_bonus_actions_available", monster_sheet.max_bonus_actions) # Default to max
	monster_sheet.current_reactions_available = sheet_data.get("current_reactions_available", monster_sheet.max_reactions) # Default to max

	# Current Derived Stats (Load saved value, assuming it was calculated correctly before saving)
	monster_sheet.current_armor_class = sheet_data.get("current_armor_class", monster_sheet.base_armor_class) # Default to base AC
	monster_sheet.current_speed = sheet_data.get("current_speed", monster_sheet.base_speed) # Default to base speed

	# Current Movement State (Enum Conversion)
	var move_state_string = sheet_data.get("current_movement_state", "LAND") # Default to LAND
	if "MovementState" in GameConst:
		var move_state_keys = GameConst.MovementState.keys()
		if move_state_string in move_state_keys:
			monster_sheet.current_movement_state = GameConst.MovementState[move_state_string]
		else:
			printerr("Unknown movement state string found: ", move_state_string)
			monster_sheet.current_movement_state = GameConst.MovementState.LAND
	else:
		printerr("GameConst.MovementState enum not found.")
		monster_sheet.current_movement_state = GameConst.MovementState.LAND # Default

	# If these contain complex data in the feature (Resources, nested Dictionaries), I need specific loading logic.
	monster_sheet.current_conditions = sheet_data.get("current_conditions", [])
	monster_sheet.active_effects = sheet_data.get("active_effects", [])

	# --- DO NOT RE-INITIALIZE RUNTIME STATE ---
	# monster_sheet.initialize_runtime_state() # to calculate base stats, etc.

	return monster_sheet

func _save():
	for map_name in cached_tokens:

		if cached_tokens[map_name].has("instance"):
			cached_tokens[map_name].erase("instance")
		var tokens = ExternalUtility.prepare_for_json(cached_tokens[map_name])

		map_name = map_name.replace("_", " ")
		if map_name in map_manager.tilemap_data:
			map_manager.tilemap_data[map_name]["tokens"] = tokens
	
