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
const RAY_COUNT_MAPPING: Array[int] = [1024, 756, 512]
var map_settings = {
    "global_illumination": false,
    "global_illumination_color": Color(1, 1, 1, 0),
    "global_illumination_presets": ["Night", "Day"],
    "global_fog_color": Color(0, 0, 0, 1),
    "global_fog_presets": ["Dark", "Dim", "Bright"],
    "global_vision_rays_count": 512,
    "global_vision_color": Color(1, 1, 1, 0)
}

var default_map_settings = {
    "global_illumination": false,
    "global_illumination_color": Color(1, 1, 1, 0),
    "global_illumination_presets": ["Night", "Day"],
    "global_fog_color": Color(0, 0, 0, 1),
    "global_fog_presets": ["Dark", "Dim", "Bright"],
    "global_vision_rays_count": 512,
    "global_vision_color": Color(1, 1, 1, 0)
}

# ALL

