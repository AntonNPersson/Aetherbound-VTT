extends CharacterBody2D
# ===================== PLAYER CONTROLLER =====================
# Manages the player, works with the MultiplayerSynchronizer to manage the player
# =============================================================

# Variables
@export var character_sheet: Resource = null
@export var player_camera: Camera2D = null

# ===================== CORE FUNCTIONS =====================
func _ready():
	get_node("MultiplayerSynchronizer").set_multiplayer_authority(str(name).to_int())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !get_node("MultiplayerSynchronizer").is_multiplayer_authority():
		return

	var velocity = Vector2.ZERO
	if Input.is_action_pressed("UP"):
		velocity.y -= 1

	velocity = velocity.normalized()

	global_position += velocity * 10 * delta

