extends Node

# ===================== USER VARIABLES =======================
# User settings VARIABLES

# Window/Viewport VARIABLES
var window_width = 1920
var window_height = 1080
var window_resolution = Vector2(window_width, window_height)

# ===================== GM VARIABLES =========================
# Lobby 
var is_player = false
var prologue_map = ""

# GM
var global_illumination = false
var global_illumination_color = Color(1, 1, 1, 1)
var global_vision_color = Color(1, 1, 1, 0)
var global_vision_rays_count = 128
var global_fog_color = Color(0, 0, 0, 1)
