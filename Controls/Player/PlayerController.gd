extends CharacterBody2D
# ===================== PLAYER CONTROLLER =====================
# Manages the player, works with the MultiplayerSynchronizer to manage the player
# Really need to make this a bit more modular
# =============================================================

# Variables
@export var character_sheet: Resource = null
@export var map: Node = null
@export var combat: Node = null
@export var player_camera: Camera2D = null

# Movement Variables
var is_moving_sprite: bool = false

# Mouse variables
var is_mouse_over: bool = false
var click_start_time = 0.0
const CLICK_THRESHOLD = 0.3

# State variables
var combat_mode: bool = false
var is_hidden: bool = false

# ===================== CORE FUNCTIONS =====================
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_node("MultiplayerSynchronizer").set_multiplayer_authority(str(name).to_int())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	# If not the authority, return
	if get_node("MultiplayerSynchronizer").is_multiplayer_authority():
		if combat_mode:
			pass
		else:
			exploration_process()
	elif Net.is_host():
		moving_sprite()
		
		# Probably need to make this a bit better in the future
		if Input.is_action_just_pressed("LEFT_CLICK"):
			if is_moving_sprite:
				move_to_tile.rpc(get_global_mouse_position())
				var move_sprite = get_node_or_null("Move Sprite")
				move_sprite.queue_free()
				get_node("Sprite2D").show()
				is_moving_sprite = false
			

# Process for exploration mode
# Args: None
# Returns: None
func exploration_process() -> void:
	player_input()

	# For visual representation of the sprite moving
	moving_sprite()

# Process for combat mode
# Args: None
# Returns: None
func combat_process() -> void:
	pass

# ===================== INPUT FUNCTIONS =====================

# Player input
# Args: None
# Returns: None
func player_input() -> void:
	if Input.is_action_just_pressed("UP"):
		map.move_to_tile(self, global_position + Vector2(0, -300))
	elif Input.is_action_just_pressed("DOWN"):
		map.move_to_tile(self, global_position + Vector2(0, 300))
	elif Input.is_action_just_pressed("LEFT"):
		map.move_to_tile(self, global_position + Vector2(-300, 0))
	elif Input.is_action_just_pressed("RIGHT"):
		map.move_to_tile(self, global_position + Vector2(300, 0))

# Input function
# Args: InputEvent - The input event
# Returns: None
func _input(event):
	if !get_node("MultiplayerSynchronizer").is_multiplayer_authority():
		return
	movement(event, player_camera)

# ===================== MOVEMENT FUNCTIONS =====================
# Movement function, allows drag and drop movement
# Args: InputEvent - The input event, Camera2D - The camera
# Returns: None
func movement(event, camera: Camera2D) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			click_start_time = Time.get_ticks_msec() / 1000.0
			start_move_sprite(camera)

		elif event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			var click_duration = Time.get_ticks_msec() / 1000.0 - click_start_time
			if click_duration < CLICK_THRESHOLD:
				map.select_tile(get_global_mouse_position())

			stop_move_sprite(camera)

# Networking functions

# Move the player to a specific tile
# Args: Vector2 - The tile to move to
# Returns: None
@rpc("any_peer", "call_local", "reliable")
func move_to_tile(tile: Vector2) -> void:
	map.move_to_tile(self, tile)

# ===================== GM FUNCTIONS =========================

func hide_token() -> void:
	modulate.a = 0.5
	is_hidden = true
	set_token_visibility.rpc(false)
	
func show_token() -> void:
	modulate.a = 1
	is_hidden = false
	set_token_visibility.rpc(true)

# Networking functions

# Set the visibility of the token
# Args: bool - The visibility of the token
# Returns: None
@rpc("any_peer", "call_remote", "reliable")
func set_token_visibility(visibility: bool) -> void:
	if visibility:
		visible = true
	else:
		visible = false

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
	
# ===================== HELPER FUNCTIONS =====================
# Start moving the sprite, for drag and drop
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

# Stop moving the sprite, for drag and drop
# Args: None
# Returns: None
func stop_move_sprite(camera: Camera2D) -> void:
	var move_sprite = get_node_or_null("Move Sprite")
	if move_sprite == null:
		return

	is_moving_sprite = false
	move_sprite.queue_free()

	map.move_to_tile(self, get_global_mouse_position())
	get_node("Sprite2D").show()
	camera.is_movement_enabled = true

func moving_sprite() -> void:
	if is_moving_sprite:
		var moving_sprite = get_node_or_null("Move Sprite")
		if moving_sprite:
			moving_sprite.global_position = get_global_mouse_position()

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

