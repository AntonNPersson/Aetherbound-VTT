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

var portal_opening_sound = preload("res://Assets/Audio/SFX/Door/door-opening.mp3")
var portal_closing_sound = preload("res://Assets/Audio/SFX/Door/door-closing.mp3")
var portal_locked_sound = preload("res://Assets/Audio/SFX/Door/door-locked.mp3")

# ===================== CORE FUNCTIONS =====================
func initialize_state() -> void:
	if is_open:
		open_portal(true)
	else:
		close_portal(true)

	if is_locked:
		lock_portal(true)
	else:
		unlock_portal(true)
	
	var sprite = Sprite2D.new()
	sprite.texture = image
	sprite.z_index = 2
	sprite.global_position = map_position
	sprite.scale = Vector2(0.3, 0.3)
	sprite.add_to_group("Portal_sprites")
	parent.add_child(sprite)
	portal_sprite = sprite

	if is_hidden:
		hide_portal(true)
	else:
		show_portal(true)

# Open the portal
# Args: None
# Returns: None
func open_portal(skip_updating: bool = false) -> void:
	if !Net.is_host() and is_locked:
		if !skip_updating:
			Audio.play_sfx_audio(portal_locked_sound)
		return

	is_open = true
	parent.get_node("StaticBody2D").collision_layer = 4
	map.map_data_changed.emit()
	update_data(skip_updating)
	if !skip_updating:
		Audio.play_sfx_audio(portal_opening_sound)
		Bus.update_shader_wall_data.emit()

# Close the portal
# Args: None
# Returns: None
func close_portal(skip_updating: bool = false) -> void:
	if !Net.is_host() and is_locked:
		if !skip_updating:
			Audio.play_sfx_audio(portal_locked_sound)
		return

	is_open = false
	parent.get_node("StaticBody2D").collision_layer = 2
	map.map_data_changed.emit()
	update_data(skip_updating)
	if !skip_updating:
		Audio.play_sfx_audio(portal_closing_sound)
		Bus.update_shader_wall_data.emit()

func lock_portal(skip_updating: bool = false) -> void:
	is_locked = true
	map.map_data_changed.emit()
	update_data(skip_updating)

func unlock_portal(skip_updating: bool = false) -> void:
	is_locked = false
	map.map_data_changed.emit()
	update_data(skip_updating)

func hide_portal(skip_updating: bool = false) -> void:
	is_hidden = true
	if !Net.is_host():
		if portal_sprite != null:
			portal_sprite.visible = false
	else:
		if portal_sprite != null:
			portal_sprite.modulate.a = 0.6
	map.map_data_changed.emit()
	update_data(skip_updating)

func show_portal(skip_updating: bool = false) -> void:
	is_hidden = false
	if !Net.is_host():
		if portal_sprite != null:
			portal_sprite.visible = true
	else:
		if portal_sprite != null:
			portal_sprite.modulate.a = 1
	map.map_data_changed.emit()
	update_data(skip_updating)

func update_data(skip_updating: bool = false) -> void:
	var state = {"open": is_open, "locked": is_locked, "hidden": is_hidden}

	if skip_updating:
		return

	if !Net.is_host():
		map.update_portal_data.rpc_id(1, map_name, portal_index, state)
	else:
		map.update_portal_data(map_name, portal_index, state)
	map.update_portal_data_for_peers.rpc(map_position, state)

func inspect() -> String:
	return description
