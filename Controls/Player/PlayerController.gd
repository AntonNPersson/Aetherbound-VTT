extends CharacterBody2D
# ===================== PLAYER CONTROLLER =====================
# Manages the player, works with the MultiplayerSynchronizer to manage the player
# =============================================================

# Variables
@export var character_sheet: Resource = null
@export var map: Node = null
@export var player_camera: Camera2D = null

# General Variables
var combat_mode: bool = false

# Movement Variables
var is_moving_sprite: bool = false

# Mouse variables
var is_mouse_over: bool = false

# ===================== CORE FUNCTIONS =====================
func _ready() -> void:
	get_node("MultiplayerSynchronizer").set_multiplayer_authority(str(name).to_int())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	if !get_node("MultiplayerSynchronizer").is_multiplayer_authority():
		return

	if combat_mode:
		pass
	else:
		exploration_process()

# Process for exploration mode
# Args: None
# Returns: None
func exploration_process() -> void:
	player_input()

	if is_moving_sprite:
		var moving_sprite = get_node_or_null("Move Sprite")
		if moving_sprite:
			moving_sprite.global_position = get_global_mouse_position()

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
	local_player_inputs(event)
	all_player_inputs(event)

# Local player input, only runs on the authority
# Args: InputEvent - The input event
# Returns: None
func local_player_inputs(event):
	if !get_node("MultiplayerSynchronizer").is_multiplayer_authority():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_mouse_over:
				start_move_sprite()
		elif event.button_index == MOUSE_BUTTON_LEFT and !event.pressed:
			stop_move_sprite()

# All player inputs, runs on all players
# Args: InputEvent - The input event
# Returns: None
func all_player_inputs(event):
	return


# ===================== HELPER FUNCTIONS =====================
# Start moving the sprite, for drag and drop
# Args: None
# Returns: None
func start_move_sprite():
	if is_moving_sprite:
		return

	player_camera.is_movement_enabled = false
	var sprite = get_node("Sprite2D")
	var new_sprite = sprite.duplicate()
	new_sprite.name = "Move Sprite"
	add_child(new_sprite)
	sprite.hide()
	is_moving_sprite = true

# Stop moving the sprite, for drag and drop
# Args: None
# Returns: None
func stop_move_sprite():
	var move_sprite = get_node_or_null("Move Sprite")
	if move_sprite == null:
		return

	is_moving_sprite = false
	move_sprite.queue_free()

	map.move_to_tile(self, get_global_mouse_position())
	get_node("Sprite2D").show()
	player_camera.is_movement_enabled = true

# ===================== SIGNAL FUNCTIONS =====================
# Mouse entered signal
# Args: None
# Returns: None
func _on_mouse_exited():
	is_mouse_over = false

# Mouse exited signal
# Args: None
# Returns: None
func _on_mouse_entered():
	is_mouse_over = true

