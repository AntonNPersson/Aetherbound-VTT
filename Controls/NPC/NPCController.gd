extends CharacterBody2D

@export var character_sheet: Resource = null
@export var ray: RayCast2D = null
var map: Node = null
var combat: bool = false
var id: int = 0

var is_possesed: bool = false
var is_hidden: bool = false
var is_moving_sprite: bool = false
var is_paused: bool = false

var is_mouse_over: bool = false

# CORE Functions
func _ready() -> void:
	print("NPC Controller Ready")
	print(get_node("Sprite2D").texture)
	get_node("MultiplayerSynchronizer").set_multiplayer_authority(Net.get_host())
	if ray == null:
		ray = get_node("RayCast2D")
		ray.enabled = true
		ray.collision_mask = 2

func _process(delta: float) -> void:
	if is_paused:
		return

	if combat:
		combat_process()
	else:
		exploration_process()

func combat_process() -> void:
	if is_possesed:
		npc_input()
	else:
		moving_sprite()

func exploration_process() -> void:
	if is_possesed:
		npc_input()
	else:
		moving_sprite()

# Input functions
func npc_input() -> void:
	if Input.is_action_just_pressed("UP"):
		move_to_tile_with_collision(Vector2(0, -map.tile_size.y))
	elif Input.is_action_just_pressed("DOWN"):
		move_to_tile_with_collision(Vector2(0, map.tile_size.y))
	elif Input.is_action_just_pressed("LEFT"):
		move_to_tile_with_collision(Vector2(-map.tile_size.x, 0))
	elif Input.is_action_just_pressed("RIGHT"):
		move_to_tile_with_collision(Vector2(map.tile_size.x, 0))

# Movement functions

# Move the player to a specific tile
# Args: Vector2 - The tile to move to
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func move_to_tile(tile: Vector2) -> void:
	var move_command = MoveCommand.new(self, tile, map)
	command_manager.execute_command(move_command)

# Move the player to a specific tile with collision
# Args: Vector2 - The direction to move
# Returns: None
func move_to_tile_with_collision(direction: Vector2) -> void:
	if !is_colliding(direction):
		if map.get_token_at_position(global_position + direction) != null:
			return
		var move_command = MoveCommand.new(self, global_position + direction, map)
		command_manager.execute_command(move_command)

# Hide the token
# Args: None
# Returns: None
func hide_token() -> void:
	modulate.a = 0.5
	is_hidden = true
	set_token_visibility.rpc(false)

# Show the token
# Args: None
# Returns: None
func show_token() -> void:
	modulate.a = 1
	is_hidden = false
	set_token_visibility.rpc(true)

func show_line_of_sight() -> void:
	is_possesed = true

func hide_line_of_sight() -> void:
	is_possesed = false

# Set the visibility of the token
# Args: bool - The visibility of the token
# Returns: None
@rpc("any_peer", "call_remote", "reliable")
func set_token_visibility(visibility: bool) -> void:
	visible = visibility

# Helper functions

# Start moving the sprite, for drag and drop (I should probably make a drag and drop system that i can use for other things)
# Stop moving the sprite, for drag and drop
# Args: None
# Returns: None
func stop_move_sprite(camera: Camera2D) -> void:
	var move_sprite = get_node_or_null("Move Sprite")
	if move_sprite == null:
		return

	is_moving_sprite = false
	move_sprite.queue_free()
	if map.get_token_at_position(get_global_mouse_position()) == null:
		map.move_to_tile(self, get_global_mouse_position())
	get_node("Sprite2D").show()
	camera.is_movement_enabled = true
	await get_tree().process_frame
	map.select_tile(global_position)

# Start moving the sprite, for drag and drop (I should probably make a drag and drop system that i can use for other things)
# Move the sprite to the mouse position
# Args: None
# Returns: None
func moving_sprite() -> void:
	if is_moving_sprite:
		var _moving_sprite = get_node_or_null("Move Sprite")
		if _moving_sprite:
			_moving_sprite.global_position = get_global_mouse_position()
			
	if Input.is_action_just_pressed("LEFT_CLICK"):
			if is_moving_sprite:
				move_to_tile.rpc(get_global_mouse_position())
				var move_sprite = get_node_or_null("Move Sprite")
				move_sprite.queue_free()
				get_node("Sprite2D").show()
				is_moving_sprite = false

# Check if the player is colliding with something using raycasts
# Args: Vector2 - The direction to check
# Returns: bool - If the player is colliding
func is_colliding(direction: Vector2) -> bool:
	ray.target_position = direction
	ray.global_position = global_position
	ray.force_raycast_update()
	var wall = ray.get_collider()
	if wall:
		if wall.get_parent().has_meta("type"):
			if wall.get_parent().get_meta("type") == "Phantom Wall":
				return false
	return ray.is_colliding()

@rpc("any_peer", "call_remote", "reliable")
func move_token() -> void:
	if is_moving_sprite:
		return

	var sprite = get_node("Sprite2D")
	var new_sprite = sprite.duplicate()
	new_sprite.name = "Move Sprite"
	add_child(new_sprite)
	sprite.hide()
	is_moving_sprite = true

# Start moving the sprite, for drag and drop (I should probably make a drag and drop system that i can use for other things)
# Args: None
# Returns: None
func start_move_sprite(camera: Camera2D) -> void:
	if is_moving_sprite:
		return

	if is_mouse_over and map.is_tile_selected(global_position):
		camera.is_movement_enabled = false
		var sprite = get_node("Sprite2D")
		var new_sprite = sprite.duplicate()
		new_sprite.name = "Move Sprite"
		add_child(new_sprite)
		sprite.hide()
		is_moving_sprite = true

func _save():
	var npc_data = {
		"texture": get_node("Sprite2D").texture.resource_path,
		"sheet": character_sheet
	}
	var json_ready = ExternalUtility.convert_to_json(npc_data)
	ExternalUtility.create_file("user://Assets/NPCs/" + character_sheet.get_unit_name() + ".json", json_ready)
	Bus.update_resource_content.emit()

# ===================== SIGNAL FUNCTIONS =====================
# Mouse entered signal
# Args: None
# Returns: None
func _on_mouse_exited() -> void:
	is_mouse_over = false

# Mouse exited signal
# Args: None
# Returns: None
func _on_mouse_entered() -> void:
	is_mouse_over = true
