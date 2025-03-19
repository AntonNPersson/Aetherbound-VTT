class_name portal extends Resource
# ===================== PORTAL =====================
# A portal is a resource that contains information
# about a portal in the game. This includes the
# state, position and information about the portal.
# ==================================================
var parent: Node = null
var is_open: bool = false
var is_locked: bool = false
var is_hidden: bool = false
var map: Node = null
var map_position: Vector2 = Vector2(0, 0)
var map_name: String = ""
var portal_index: int = 0
var description: String = "You can open me!"
var image: Texture = preload("res://Assets/Textures/icons/door.png")
var portal_sprite = null

# ===================== CORE FUNCTIONS =====================
func initialize_state() -> void:
	if is_open:
		open_portal()
	else:
		close_portal()
	
	var sprite = Sprite2D.new()
	sprite.texture = image
	sprite.z_index = 2
	sprite.global_position = map_position
	sprite.scale = Vector2(0.3, 0.3)
	sprite.add_to_group("Portal_sprites")
	parent.add_child(sprite)
	portal_sprite = sprite

# Open the portal
# Args: None
# Returns: None
func open_portal() -> void:
	if !Net.is_host() and is_locked:
		return

	is_open = true
	parent.get_node("StaticBody2D").collision_layer = 4
	map.map_data_changed.emit()
	if !Net.is_host():
		map.update_portal_data.rpc_id(1, map_name, portal_index, true)
	map.update_portal_data_for_peers.rpc(map_position, true)

# Close the portal
# Args: None
# Returns: None
func close_portal() -> void:
	if !Net.is_host() and is_locked:
		return

	is_open = false
	parent.get_node("StaticBody2D").collision_layer = 2
	map.map_data_changed.emit()
	if !Net.is_host():
		map.update_portal_data.rpc_id(1, map_name, portal_index, false)
	map.update_portal_data_for_peers.rpc(map_position, false)

func inspect() -> String:
	return description
