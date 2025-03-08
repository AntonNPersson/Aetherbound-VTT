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
var map_position: Vector2 = Vector2(0, 0)
var description: String = "You can open me!"

# ===================== CORE FUNCTIONS =====================
# Open the portal
# Args: None
# Returns: None
func open_portal() -> void:
	is_open = true
	parent.get_node("StaticBody2D").collision_layer = 4

# Close the portal
# Args: None
# Returns: None
func close_portal() -> void:
	is_open = false
	parent.get_node("StaticBody2D").collision_layer = 2