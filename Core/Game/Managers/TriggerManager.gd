class_name TriggerManager extends Node
var map_manager = null
var cached_triggers: Dictionary = {}

func _ready() -> void:
	add_to_group("Savable")

func create_trigger(trigger_data: Array, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if Net.is_host():
		for key in cached_triggers:
			for trigger in cached_triggers[key]:
				trigger.trigger_sprite.visible = (key == map_name)
	
	if map_name in cached_triggers and !cached_triggers[map_name].is_empty():
		return
		
	cached_triggers[map_name] = []
	
	for trigger in trigger_data:
		var trigger_resource = null
		var position: Vector2
		if trigger["position"] is Array and trigger.position.size() >= 2:
			position = Vector2(trigger.position[0], trigger.position[1])
		
		if trigger["type"] == "Terrain":
			trigger_resource = TerrainTrigger.new(position, self)
			trigger_resource.cost_multiplier = trigger.cost_multiplier
		elif trigger["type"] == "Settings":
			trigger_resource = SettingsTrigger.new(position, self)
			trigger_resource.global_illumination = trigger.global_illumination
			trigger_resource.global_illumination_color = Color(trigger.global_illumination_color[0], trigger.global_illumination_color[1], trigger.global_illumination_color[2], trigger.global_illumination_color[3])
			trigger_resource.global_fog_color = Color(trigger.global_fog_color[0], trigger.global_fog_color[1], trigger.global_fog_color[2], trigger.global_fog_color[3])
			trigger_resource.global_vision_color = Color(trigger.global_vision_color[0], trigger.global_vision_color[1], trigger.global_vision_color[2], trigger.global_vision_color[3])
		elif trigger["type"] == "Message":
			trigger_resource = MessageTrigger.new(position, self)
			trigger_resource.message = trigger.message
			trigger_resource.message_level = trigger.message_level
			trigger_resource.reciever = trigger.reciever
			trigger_resource.sender = trigger.sender
		
		if trigger_resource == null:
			ErrorUtility.log_warning("Warning: Invalid trigger data:" + str(trigger))
			continue
		cached_triggers[map_name].append(trigger_resource)

func add_trigger(trigger_type: String, position: Vector2, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if map_name not in cached_triggers:
		cached_triggers[map_name] = []
	
	var trigger_resource
	if trigger_type == "Terrain":
		trigger_resource = TerrainTrigger.new(position, self)
	elif trigger_type == "Settings":
		trigger_resource = SettingsTrigger.new(position, self)
	elif trigger_type == "Message":
		trigger_resource = MessageTrigger.new(position, self)
	
	cached_triggers[map_name].append(trigger_resource)

func remove_trigger(position: Vector2, map_name: String) -> void:
	map_name = map_name.replace(" ", "_")
	
	if map_name not in cached_triggers:
		return
	
	for i in range(cached_triggers[map_name].size()):
		if cached_triggers[map_name][i].trigger_position == position:
			if Net.is_host():
				cached_triggers[map_name][i].trigger_sprite.queue_free()
			cached_triggers[map_name].remove_at(i)
			break

func _save():
	for map_name in cached_triggers:
		var clean_map_name = map_name.replace("_", " ")
		
		var map_triggers = ExternalUtility.prepare_for_json(cached_triggers[map_name])
		
		if clean_map_name in map_manager.tilemap_data:
			map_manager.tilemap_data[clean_map_name]["triggers"] = map_triggers
